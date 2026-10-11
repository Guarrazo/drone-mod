return function(G)
  local Cron = G.Cron
  local M = { active = nil }

  local CAM_ENT = [[base\entities\cameras\simple_free_camera.ent]]
  local AHEAD = 0.6
  local EYE_TALL = 2.3
  local EYE_BIPED = 1.65
  local SPEED = 12.0
  local VSPEED = 6.0
  local STICK_YAW = 140.0
  local STICK_PITCH = 90.0
  local MOUSE_FACTOR = 45.0
  local PITCH_MAX = 80.0
  local SYNC_EVERY = 0.25
  local CAM_OFFSET = {
    Octant = { back = 2.2, up = 2.5 }, Bombus = { back = 1.5, up = 0.8 },
    Wyvern = { back = 2.5, up = 1.5 }, Griffin = { back = 3.0, up = 2.0 },
    Chimera = { back = 5.0, up = 2.5 },
  }
  local CAM_OFFSET_DEFAULT = { back = 2.0, up = 1.5 }
  local HIDE_BODY = false
  local GHOP = 8.0
  local GROUND_EVERY = 0.4
  local CAM_LERP = 12.0

  local RESTRICTIONS = {
    "GameplayRestriction.NoMovement",
    "GameplayRestriction.NoCameraControl",
    "GameplayRestriction.NoZooming",
    "GameplayRestriction.NoWeapons",
    "GameplayRestriction.NoDriving",
  }

  local P = {}
  local function resetPilot()
    P = { on = false, ground = false, wasMoving = false,
      yaw = 0, pitch = 0, moveX = 0, moveY = 0,
      kf = 0, kb = 0, kl = 0, kr = 0, up = 0, dn = 0,
      stickYaw = 0, stickPitch = 0, pos = nil, sync = 0 }
  end
  resetPilot()

  local function groundMove(ent, x, y, z)
    if not P.noSprint then
      local ok = false
      pcall(function() ok = G.orders.moveCmd(ent, x, y, z, moveMovementType.Sprint) end)
      if ok then return end
      P.noSprint = true
    end
    G.orders.moveCmd(ent, x, y, z)
  end

  local function restrict(on)
    pcall(function()
      local player = Game.GetPlayer()
      for _, se in ipairs(RESTRICTIONS) do
        if on then
          StatusEffectHelper.ApplyStatusEffect(player, TweakDBID.new(se))
        else
          StatusEffectHelper.RemoveStatusEffect(player, TweakDBID.new(se))
        end
      end
    end)
  end

  local CAMO_SE = {
    "BaseStatusEffect.OpticalCamoPlayerBuff",
    "BaseStatusEffect.OpticalCamo",
    "BaseStatusEffect.Cloaked",
    "BaseStatusEffect.Invisibility",
  }

  local B = { on = false }
  local BODY_NEAR = 25.0

  local GHOST = {
    { stat = "DetectionSpeedDecrease", kind = "Additive", value = 1.0 },
    { stat = "Visibility", kind = "Multiplier", value = 0.0 },
  }

  local function bodyGhost(on)
    local player = Game.GetPlayer()
    if not player then return end
    local stats = Game.GetStatsSystem()
    local id = player:GetEntityID()
    B.mods = B.mods or {}
    for i, g in ipairs(GHOST) do
      local ok, err = pcall(function()
        if B.mods[i] then
          stats:RemoveModifier(id, B.mods[i])
          B.mods[i] = nil
        end
        if on then
          B.mods[i] = RPGManager.CreateStatModifier(
            gamedataStatType[g.stat], gameStatModifierType[g.kind], g.value)
          stats:AddModifier(id, B.mods[i])
        end
      end)
      if not ok then G.log("ghost " .. g.stat .. " failed: " .. tostring(err)) end
    end
  end

  local function bodyCamo(on)
    local player = Game.GetPlayer()
    if not player then return end
    for _, se in ipairs(CAMO_SE) do
      pcall(function()
        if on then
          StatusEffectHelper.ApplyStatusEffect(player, TweakDBID.new(se))
        else
          StatusEffectHelper.RemoveStatusEffect(player, TweakDBID.new(se))
        end
      end)
    end
    bodyGhost(on)
  end

  local function bodySync(ent)
    if not B.on or not IsDefined(ent) then return end
    local player = Game.GetPlayer()
    if not player then return end
    local p = ent:GetWorldPosition()
    local target = Vector4.new(p.x, p.y, p.z - 1.5, 1.0)
    local grounded = false
    pcall(function()
      local from = Vector4.new(p.x, p.y, p.z + 0.5, 1.0)
      local to = Vector4.new(p.x, p.y, p.z - 300.0, 1.0)
      local hit, trace = Game.GetSpatialQueriesSystem()
        :SyncRaycastByCollisionGroup(from, to, "Static", true, false)
      if hit and trace then
        target = Vector4.new(trace.position.x, trace.position.y, trace.position.z + 0.3, 1.0)
        grounded = true
      end
    end)
    if not grounded and p.z - player:GetWorldPosition().z > 6.0 then return end
    if Vector4.Distance(player:GetWorldPosition(), target) < BODY_NEAR then return end
    local ok = pcall(function()
      Game.GetTeleportationFacility():Teleport(player, target,
        EulerAngles.new(0, 0, player:GetWorldYaw()))
    end)
    return ok
  end

  local function bodyRelease()
    if not B.on then return end
    B.on = false
    local player = Game.GetPlayer()
    if player and B.pos then
      pcall(function()
        Game.GetTeleportationFacility():Teleport(player, B.pos,
          EulerAngles.new(0, 0, B.yaw or 0))
      end)
    end
    B.pos = nil
    G.Cron.After(0.3, function() bodyCamo(false) end)
  end

  M.bodySync = bodySync

  local function droneRow(rec)
    for _, row in ipairs(G.companion.aliveCache or {}) do
      if row.rec == rec and IsDefined(row.ent) and not G.companion.isDown(row.ent) then
        return row
      end
    end
    return nil
  end

  local function eyeHeight(model)
    if model.fly then return 0.1 end
    if model.chassis == "Minotaur" or model.chassis == "Chimera"
      or model.chassis == "Cerberus" then
      return EYE_TALL
    end
    return EYE_BIPED
  end

  local function camDir()
    local ry, rp = math.rad(P.yaw), math.rad(P.pitch)
    local ch = math.cos(rp)
    return { x = -math.sin(ry) * ch, y = math.cos(ry) * ch, z = math.sin(rp) }
  end

  local function followPose(row)
    local ent = row.ent
    local p = ent:GetWorldPosition()
    local up = eyeHeight(row.model)
    local fwd = ent:GetWorldForward()
    return Vector4.new(p.x + fwd.x * AHEAD, p.y + fwd.y * AHEAD, p.z + up, 1.0),
      ent:GetWorldOrientation():ToEulerAngles()
  end

  local function camOffset(model)
    return CAM_OFFSET[model and model.chassis] or CAM_OFFSET_DEFAULT
  end

  local function bodyFromCam(model, x, y, z, yaw)
    local off = camOffset(model)
    local ry = math.rad(yaw)
    local hx, hy = -math.sin(ry), math.cos(ry)
    return x - hx * off.back, y - hy * off.back, z - off.up
  end

  local function hideBody(ent, on)
    if not HIDE_BODY or not IsDefined(ent) then return end
    local n, errs = 0, {}
    if on then M.savedMesh = {} end
    local ok, err = pcall(function()
      for _, comp in ipairs(ent:GetComponents()) do
        local cls = tostring(comp:GetClassName())
        if cls:find("MeshComponent", 1, true) then
          n = n + 1
          if on then
            local saved = {}
            pcall(function() saved.hide = comp.autoHideDistance end)
            pcall(function() saved.mask = comp.renderSceneLayerMask end)
            M.savedMesh[#M.savedMesh + 1] = { comp = comp, saved = saved }
            local ok1, e1 = pcall(function() comp.autoHideDistance = 0.01 end)
            if not ok1 then errs[#errs + 1] = "hide:" .. tostring(e1) end
            local ok2, e2 = pcall(function() comp.renderSceneLayerMask = 0 end)
            if not ok2 then errs[#errs + 1] = "mask:" .. tostring(e2) end
          end
        end
      end
      if not on then
        for _, row in ipairs(M.savedMesh or {}) do
          pcall(function() if row.saved.hide ~= nil then row.comp.autoHideDistance = row.saved.hide end end)
          pcall(function() if row.saved.mask ~= nil then row.comp.renderSceneLayerMask = row.saved.mask end end)
        end
        M.savedMesh = nil
      end
    end)
    local first = M.savedMesh and M.savedMesh[1] and M.savedMesh[1].saved or {}
    G.log(string.format("dronecam: hide body %s meshes=%d ok=%s %s | was hide=%s mask=%s | %s",
      tostring(on), n, tostring(ok), ok and "" or tostring(err), tostring(first.hide), tostring(first.mask),
      table.concat(errs, "; "):sub(1, 300)))
  end

  local function teleportDrone(ent, x, y, z, yaw)
    pcall(function()
      local cmd = NewObject("handle:AITeleportCommand")
      cmd.position = Vector4.new(x, y, z, 1.0)
      cmd.rotation = yaw
      cmd.doNavTest = false
      ent:GetAIControllerComponent():SendCommand(cmd)
    end)
  end

  M.pilotedOnce = {}

  function M.resetDrone(rec)
    local row = droneRow(rec)
    if not row then return end
    local saved
    pcall(function()
      saved = G.companion.captureOne(rec, true)
    end)
    G.companion.dismiss(rec, true)
    if saved then
      Cron.After(0.6, function() G.companion.respawn({ saved }) end)
    end
  end

  function M.start(rec)
    if M.active then M.stop() end
    local row = droneRow(rec)
    if not row then return end

    resetPilot()
    if row.model.fly then
      P.on = true
      local rot = row.ent:GetWorldOrientation():ToEulerAngles()
      P.yaw = rot.yaw
      P.pitch = 0
      local p = row.ent:GetWorldPosition()
      local fwd = row.ent:GetWorldForward()
      local off = camOffset(row.model)
      P.pos = { x = p.x + fwd.x * off.back, y = p.y + fwd.y * off.back, z = p.z + off.up }
      hideBody(row.ent, true)
      M.hiddenEnt = row.ent
      if G.orders then G.orders.moving[rec] = nil end
      G.hacks.setHold(rec, row.ent, true)
      M.pilotedOnce[rec] = true
    elseif not row.model.static then
      P.on = true
      P.ground = true
      P.sync = GROUND_EVERY
      local rot = row.ent:GetWorldOrientation():ToEulerAngles()
      P.yaw = rot.yaw
      P.pitch = 0
      if G.orders then G.orders.moving[rec] = nil end
      G.hacks.setHold(rec, row.ent, true)
    end

    local pos, rot
    if P.on and not P.ground then
      pos = Vector4.new(P.pos.x, P.pos.y, P.pos.z, 1.0)
      rot = EulerAngles.new(0, P.pitch, P.yaw)
    else
      pos, rot = followPose(row)
    end
    local transform = Game.GetPlayer():GetWorldTransform()
    transform:SetPosition(pos)
    local spawnedID
    local ok = pcall(function()
      spawnedID = exEntitySpawner.Spawn(CAM_ENT, transform, "")
    end)
    if not ok or not spawnedID then
      G.log("dronecam: camera spawn failed")
      return
    end

    M.active = rec
    M.entityID = spawnedID
    local tick = 0
    local finder
    finder = Cron.Every(0.1, function()
      tick = tick + 1
      if M.active ~= rec then
        Cron.Halt(finder)
        return
      end
      local cam = Game.FindEntityByID(spawnedID)
      if cam then
        Cron.Halt(finder)
        M.handle = cam
        M.component = cam:FindComponentByName("camera")
        if not M.component then
          G.log("dronecam: no camera component on entity")
          M.stop()
          return
        end
        restrict(true)
        if G.settings.camHacks then
          local player = Game.GetPlayer()
          B.on = true
          B.pos = player:GetWorldPosition()
          B.yaw = player:GetWorldYaw()
          bodyCamo(true)
        end
        pcall(function() M.component:Activate(0.4, false) end)
        G.notify(string.format(G.STR.cam_on, G.modelOf(rec) and G.modelOf(rec).name or rec))
        if P.on then
          G.notify(P.ground and G.STR.cam_pilot_ground or G.STR.cam_pilot)
        end
      elseif tick > 20 then
        Cron.Halt(finder)
        G.log("dronecam: camera entity never arrived")
        M.active = nil
      end
    end)
  end

  function M.stop()
    if not M.active then return end
    local rec = M.active
    local wasPilot = P.on
    local wasGround = P.ground
    if wasGround then
      local row = droneRow(rec)
      if row and not G.hacks.held[rec] then
        G.hacks.setHold(rec, row.ent, true)
      end
    end
    M.active = nil
    if M.hiddenEnt then
      hideBody(M.hiddenEnt, false)
      M.hiddenEnt = nil
    end
    bodyRelease()
    resetPilot()
    restrict(false)
    pcall(function()
      if M.component then M.component:Deactivate(0.4, false) end
    end)
    pcall(function()
      Game.GetPlayer():GetFPPCameraComponent():Activate()
    end)
    local handle = M.handle
    M.handle = nil
    M.component = nil
    Cron.After(0.5, function()
      pcall(function()
        if handle then handle:Dispose() end
      end)
    end)
    if wasPilot then
      G.notify(G.STR.cam_hold)
    else
      G.notify(G.STR.cam_off)
    end
  end

  function M.onAction(name, action, pressed, released, kind)
    if not M.active then return end
    if not P.on then return end
    local axis = kind == gameinputActionType.AXIS_CHANGE
    local rel = kind == gameinputActionType.RELATIVE_CHANGE
    local v = 0
    if axis or rel then
      pcall(function() v = ListenerAction.GetValue(action) end)
    end

    if name == "MoveY" and axis then P.moveY = v
    elseif name == "MoveX" and axis then P.moveX = v
    elseif name == "Forward" then P.kf = pressed and 1 or (released and 0 or P.kf)
    elseif name == "Back" then P.kb = pressed and 1 or (released and 0 or P.kb)
    elseif name == "Left" then P.kl = pressed and 1 or (released and 0 or P.kl)
    elseif name == "Right" then P.kr = pressed and 1 or (released and 0 or P.kr)
    elseif name == "Jump" then P.up = (pressed and 1) or (released and 0) or P.up
    elseif name == "ToggleCrouch" or name == "Dodge" or name == "Crouch" then
      P.dn = (pressed and 1) or (released and 0) or P.dn
    elseif name == "CameraMouseX" and rel then P.yaw = P.yaw - v / MOUSE_FACTOR
    elseif name == "CameraMouseY" and rel then
      P.pitch = math.max(-PITCH_MAX, math.min(PITCH_MAX, P.pitch + v / MOUSE_FACTOR))
    elseif name == "CameraX" and axis then P.stickYaw = v
    elseif name == "CameraY" and axis then P.stickPitch = v
    end
  end

  function M.frame(delta)
    if not M.active or not M.handle then return end
    local row = droneRow(M.active)
    if not row or G.companion.stashed then
      M.stop()
      return
    end
    M.bodyAt = (M.bodyAt or 0) + (delta or 0)
    if M.bodyAt >= 0.5 then
      M.bodyAt = 0
      bodySync(row.ent)
    end
    pcall(function()
      if P.on and P.ground and delta and delta > 0 then
        local dt = math.min(delta, 0.1)
        P.yaw = P.yaw - P.stickYaw * STICK_YAW * dt
        P.pitch = math.max(-PITCH_MAX,
          math.min(PITCH_MAX, P.pitch + P.stickPitch * STICK_PITCH * dt))

        local f = math.max(-1, math.min(1, P.moveY + P.kf - P.kb))
        local s = math.max(-1, math.min(1, P.moveX + P.kr - P.kl))
        local bp = row.ent:GetWorldPosition()
        P.sync = P.sync + dt
        if f ~= 0 or s ~= 0 then
          if not P.wasMoving then
            P.wasMoving = true
            P.sync = GROUND_EVERY
          end
          if P.sync >= GROUND_EVERY then
            P.sync = 0
            local ry = math.rad(P.yaw)
            local fx, fy = -math.sin(ry), math.cos(ry)
            local dx = fx * f + fy * s
            local dy = fy * f - fx * s
            local n = math.sqrt(dx * dx + dy * dy)
            if n > 0.01 then
              groundMove(row.ent, bp.x + dx / n * GHOP, bp.y + dy / n * GHOP, bp.z)
            end
          end
        elseif P.wasMoving then
          P.wasMoving = false
          G.hacks.setHold(M.active, row.ent, true)
        end

        local up = eyeHeight(row.model)
        local ry = math.rad(P.yaw)
        local hx, hy = -math.sin(ry), math.cos(ry)
        local tx = bp.x + hx * AHEAD
        local ty = bp.y + hy * AHEAD
        local tz = bp.z + up
        if not P.cam then
          P.cam = { x = tx, y = ty, z = tz }
        else
          local k = math.min(1, CAM_LERP * dt)
          P.cam.x = P.cam.x + (tx - P.cam.x) * k
          P.cam.y = P.cam.y + (ty - P.cam.y) * k
          P.cam.z = P.cam.z + (tz - P.cam.z) * k
        end
        Game.GetTeleportationFacility():Teleport(M.handle,
          Vector4.new(P.cam.x, P.cam.y, P.cam.z, 1.0),
          EulerAngles.new(0, P.pitch, P.yaw))
        return
      end
      if P.on and delta and delta > 0 then
        local dt = math.min(delta, 0.1)
        P.yaw = P.yaw - P.stickYaw * STICK_YAW * dt
        P.pitch = math.max(-PITCH_MAX,
          math.min(PITCH_MAX, P.pitch + P.stickPitch * STICK_PITCH * dt))

        local f = math.max(-1, math.min(1, P.moveY + P.kf - P.kb))
        local s = math.max(-1, math.min(1, P.moveX + P.kr - P.kl))
        local zi = P.up - P.dn
        if f ~= 0 or s ~= 0 or zi ~= 0 then
          local ry = math.rad(P.yaw)
          local fx, fy = -math.sin(ry), math.cos(ry)
          local nx = P.pos.x + (fx * f + fy * s) * SPEED * dt
          local ny = P.pos.y + (fy * f - fx * s) * SPEED * dt
          local nz = P.pos.z + zi * VSPEED * dt
          local blocked = false
          pcall(function()
            local sqs = Game.GetSpatialQueriesSystem()
            local a = Vector4.new(P.pos.x, P.pos.y, P.pos.z, 1.0)
            local b = Vector4.new(nx, ny, nz, 1.0)
            blocked = sqs:SyncRaycastByCollisionGroup(a, b, "Static", true, false) == true
            if blocked then return end
            local ax, ay, az = bodyFromCam(row.model, P.pos.x, P.pos.y, P.pos.z, P.yaw)
            local bx, by, bz = bodyFromCam(row.model, nx, ny, nz, P.yaw)
            blocked = sqs:SyncRaycastByCollisionGroup(Vector4.new(ax, ay, az, 1.0),
              Vector4.new(bx, by, bz, 1.0), "Static", true, false) == true
          end)
          if not blocked then
            P.pos.x, P.pos.y, P.pos.z = nx, ny, nz
          end
        end

        P.sync = P.sync + dt
        if P.sync >= SYNC_EVERY then
          P.sync = 0
          local lp = P.lastSync
          local moved = not lp or (math.abs(P.pos.x - lp.x) + math.abs(P.pos.y - lp.y)
            + math.abs(P.pos.z - lp.z)) > 0.5
          if moved then
            local bx, by, bz = bodyFromCam(row.model, P.pos.x, P.pos.y, P.pos.z, P.yaw)
            local before = row.ent:GetWorldPosition()
            local lag = Vector4.Distance(before, Vector4.new(bx, by, bz, 1.0))
            if lag > 6.0 then
              G.log(string.format("dronecam: body lag %.0f m behind target", lag))
            end
            teleportDrone(row.ent, bx, by, bz, P.yaw)
            P.lastSync = { x = P.pos.x, y = P.pos.y, z = P.pos.z }
            if not G.hacks.held[M.active] then
              G.hacks.setHold(M.active, row.ent, true)
            end
          end
        end

        Game.GetTeleportationFacility():Teleport(M.handle,
          Vector4.new(P.pos.x, P.pos.y, P.pos.z, 1.0),
          EulerAngles.new(0, P.pitch, P.yaw))
        return
      end
      local pos, rot = followPose(row)
      Game.GetTeleportationFacility():Teleport(M.handle, pos, rot)
    end)
  end

  return M
end
