return function(G)
  local Cron = G.Cron
  local M = { seat = {}, busy = {}, crew = {}, vehAI = {}, vehSeen = {} }

  local SEATS = { "auto", "seat_front_left", "seat_front_right",
    "seat_back_left", "seat_back_right" }
  local ARRIVE = 14.0
  local PICKUP_STOP = 9.0
  local DRIVE_TIMEOUT = 600.0

  local function slotLabel(slot)
    if slot == "auto" then return G.STR.ch_seat_auto end
    if slot == "seat_front_left" then return G.STR.ch_seat_driver end
    if slot == "seat_front_right" then return G.STR.ch_seat_front end
    if slot == "seat_back_left" then return G.STR.ch_seat_backl end
    return G.STR.ch_seat_backr
  end
  M.SEATS = SEATS
  M.slotLabel = slotLabel

  local function seatLabel(rec)
    return slotLabel(M.seat[rec] or "auto")
  end
  M.seatLabel = seatLabel

  function M.setSeat(rec, slot)
    M.seat[rec] = slot
  end

  local function hashOf(ent)
    return tostring(ent:GetEntityID().hash)
  end

  local function hasSlot(veh, slot)
    local ok, has = pcall(function()
      return Game["VehicleComponent::HasSlot;GameInstanceVehicleObjectCName"](
        veh, CName.new(slot))
    end)
    return ok and has == true
  end

  function M.cycleSeat(rec, step)
    local cur = M.seat[rec] or "auto"
    local idx = 1
    for i, s in ipairs(SEATS) do if s == cur then idx = i end end
    idx = (idx - 1 + (step or 1)) % #SEATS + 1
    M.seat[rec] = SEATS[idx]
  end

  local function isSeated(ent)
    local seated = false
    pcall(function()
      local info = Game.GetMountingFacility()
        :GetMountingInfoSingleWithIds(ent:GetEntityID())
      seated = EntityID.IsDefined(info.parentId)
    end)
    return seated
  end

  local function seatOf(ent)
    local slot = nil
    pcall(function()
      if ent.IsPlayer and ent:IsPlayer() then
        local s = ent:DCGetSeat()
        if s and s ~= "" then slot = s end
        return
      end
      local info = Game.GetMountingFacility()
        :GetMountingInfoSingleWithIds(ent:GetEntityID())
      if EntityID.IsDefined(info.parentId) then
        slot = tostring(info.slotId.id)
      end
    end)
    return slot
  end

  local function mountData(veh, slot, instant)
    local data = MountEventData.new()
    data.mountParentEntityId = veh:GetEntityID()
    data.isInstant = instant == true
    data.setEntityVisibleWhenMountFinish = true
    data.removePitchRollRotationOnDismount = false
    data.ignoreHLS = false
    data.mountEventOptions = NewObject("handle:gameMountEventOptions")
    data.mountEventOptions.silentUnmount = false
    data.mountEventOptions.entityID = veh:GetEntityID()
    data.mountEventOptions.alive = true
    data.mountEventOptions.occupiedByNeutral = true
    data.slotName = slot
    return data
  end

  local function sendMount(ent, veh, slot, instant)
    local cmd = NewObject("AIMountCommand")
    cmd.mountData = mountData(veh, slot, instant == true)
    cmd = cmd:Copy()
    ent:GetAIControllerComponent():SendCommand(cmd)
  end

  local function sendUnmount(ent, veh, slot)
    local cmd = NewObject("AIUnmountCommand")
    cmd.mountData = mountData(veh, slot or "seat_front_left", false)
    cmd = cmd:Copy()
    ent:GetAIControllerComponent():SendCommand(cmd)
  end

  local function setFollow(ent, on)
    pcall(function()
      if on then
        local player = Game.GetPlayer()
        local role = AIFollowerRole.new()
        role.followerRef = Game.CreateEntityReference("#player", {})
        role.attitudeGroupName = CName.new("player")
        role:SetFollowTarget(player)
        AIHumanComponent.SetCurrentRole(ent, role)
      else
        AIHumanComponent.SetCurrentRole(ent, AIRole.new())
      end
    end)
  end

  local function engineOn(veh, on)
    pcall(function()
      veh:TurnVehicleOn(on == true)
      veh:SetInteriorUIEnabled(on == true)
    end)
  end

  local function logCmdState(tag, cmd)
    Cron.After(2.0, function()
      pcall(function()
        G.log("chauffeur: " .. tag .. " state=" .. tostring(cmd.state))
      end)
    end)
  end

  local function mountPlayer(slot, veh)
    local player = Game.GetPlayer()
    local data = NewObject("handle:gameMountEventData")
    data.isInstant = false
    data.slotName = slot
    data.mountParentEntityId = veh:GetEntityID()
    data.entryAnimName = "forcedTransition"
    local slotID = NewObject("gamemountingMountingSlotId")
    slotID.id = slot
    local info = NewObject("gamemountingMountingInfo")
    info.childId = player:GetEntityID()
    info.parentId = veh:GetEntityID()
    info.slotId = slotID
    local request = NewObject("handle:gamemountingMountingRequest")
    request.lowLevelMountingInfo = info
    request.mountData = data
    Game.GetMountingFacility():Mount(request)
  end

  local function androidRows()
    local rows = {}
    G.companion.eachActive(function(rec, ent, model)
      if model.chassis == "Android" and not model.hijack and IsDefined(ent) and not ent:IsDead() then
        rows[#rows + 1] = { rec = rec, ent = ent, model = model }
      end
    end)
    return rows
  end

  local function lookVehicle(player)
    local veh = nil
    pcall(function()
      local target = Game.GetTargetingSystem():GetLookAtObject(player, false, false)
      if IsDefined(target) and target:IsA("vehicleObject") then veh = target end
    end)
    return veh
  end

  local function nearestVehicle(player)
    local best, bestDist, bestOwned = nil, 25.0, false
    local pPos = player:GetWorldPosition()
    for hash, veh in pairs(M.vehSeen) do
      if not IsDefined(veh) then
        M.vehSeen[hash] = nil
        M.vehAI[hash] = nil
      else
        pcall(function()
          local d = Vector4.Distance(pPos, veh:GetWorldPosition())
          local owned = false
          pcall(function() owned = veh:IsPlayerVehicle() == true end)
          if (owned and not bestOwned and d < 25.0)
            or (owned == bestOwned and d < bestDist) then
            best, bestDist, bestOwned = veh, d, owned
          end
        end)
      end
    end
    if best and not bestOwned and bestDist > 10.0 then return nil end
    return best
  end

  local function summonedVehicle(player)
    local veh = nil
    pcall(function()
      local v = player:GetQuickSlotsManager():GetVehicleObject()
      if IsDefined(v) and Vector4.Distance(player:GetWorldPosition(),
        v:GetWorldPosition()) < 40.0 then
        veh = v
      end
    end)
    return veh
  end

  local function currentDriver()
    for rec, veh in pairs(M.busy) do
      local found = nil
      G.companion.eachActive(function(r, ent)
        if r == rec and IsDefined(ent) and not ent:IsDead() then found = ent end
      end)
      if found and IsDefined(veh) then
        return rec, found, veh
      end
      M.busy[rec] = nil
    end
    return nil
  end
  M.currentDriver = currentDriver

  function M.forget(rec)
    M.crew[rec] = nil
    M.busy[rec] = nil
    if M.reseatAt then M.reseatAt[rec] = nil end
  end

  local function waypoint()
    local pos = nil
    pcall(function()
      local player = Game.GetPlayer()
      local wp = player and player:DCGetWaypoint() or nil
      if wp and wp.w > 0.5 then pos = wp end
    end)
    if pos and G.orders and G.orders.mark and G.orders.markPos then
      local mp = G.orders.markPos
      if math.abs(pos.x - mp.x) + math.abs(pos.y - mp.y) < 2.0 then return nil end
    end
    return pos
  end
  M.waypoint = waypoint

  local function stopRun(reason)
    local run = M.run
    M.run = nil
    if not run then return end
    pcall(function()
      local ai = M.vehAI[hashOf(run.veh)]
      if ai then ai:StopExecutingCommand(run.cmd, true) end
    end)
    pcall(function()
      if not pcall(function() run.veh:ForceBrakesUntilStoppedOrFor(3.0) end) then
        run.veh:ForceBrakesFor(3.0)
      end
    end)
    if run.ticker then Cron.Halt(run.ticker) end
    if reason then G.notify(reason) end
  end
  M.stopRun = stopRun

  local function startTicker(stopDist, target)
    local started = os.clock()
    M.run.ticker = Cron.Every(0.5, function(timer)
      local run = M.run
      if not run then Cron.Halt(timer) return end
      local rec = select(1, currentDriver())
      if not rec then
        Cron.Halt(timer)
        stopRun()
        return
      end
      local ok = pcall(function()
        local dest = target and target:GetWorldPosition() or run.dest
        local d = Vector4.Distance(run.veh:GetWorldPosition(), dest)
        if d < stopDist then
          Cron.Halt(timer)
          local wasPickup = run.mode == "pickup"
          local veh = run.veh
          stopRun(G.STR.ch_arrived)
          if wasPickup then M.autoEnterWatch(veh) end
        end
      end)
      if not ok or os.clock() - started > DRIVE_TIMEOUT then
        Cron.Halt(timer)
        stopRun()
      end
    end)
  end

  function M.board()
    local player = Game.GetPlayer()
    if not player then return end
    local veh, path = Game.GetMountedVehicle(player), "mounted"
    if not veh then veh, path = lookVehicle(player), "look" end
    if not veh then veh, path = summonedVehicle(player), "summon" end
    if not veh then veh, path = nearestVehicle(player), "near" end
    if not veh then
      local _, _, busyVeh = currentDriver()
      veh, path = busyVeh, "busy"
    end
    if not veh then G.notify(G.STR.ch_no_vehicle) return end
    G.log("chauffeur: board via " .. path)
    local rows = androidRows()
    if #rows == 0 then G.notify(G.STR.ch_no_android) return end

    local taken = {}
    local playerSeat = seatOf(player)
    if playerSeat then taken[playerSeat] = true end

    local reserve = playerSeat == nil and "seat_front_right" or nil
    local function freeSeat(skip)
      for _, s in ipairs({ "seat_back_left", "seat_back_right",
        "seat_front_right", "seat_front_left" }) do
        if s ~= skip and s ~= reserve and not taken[s] and hasSlot(veh, s) then
          return s
        end
      end
      return nil
    end

    local delay = 0.0
    for i, row in ipairs(rows) do
      local slot = M.seat[row.rec] or "auto"
      if slot == "auto" then
        slot = (i == 1) and "seat_front_left" or freeSeat(nil)
      end
      if slot and hasSlot(veh, slot) and not taken[slot] then
        if playerSeat == slot then
          local dest = freeSeat(slot)
          if not dest then G.notify(G.STR.ch_no_seat) return end
          taken[dest] = true
          pcall(mountPlayer, dest, veh)
          delay = 1.5
        end
        taken[slot] = true
        local ent = row.ent
        local rec = row.rec
        if delay > 0 then
          Cron.After(delay, function()
            if IsDefined(ent) then pcall(sendMount, ent, veh, slot) end
          end)
        else
          pcall(sendMount, ent, veh, slot)
        end
        M.crew[rec] = veh
        if slot == "seat_front_left" then
          M.busy[rec] = veh
        end
        local tries = 0
        Cron.Every(0.5, function(timer)
          tries = tries + 1
          if not M.crew[rec] or not IsDefined(ent) or tries > 40 then
            Cron.Halt(timer)
            return
          end
          if isSeated(ent) then
            if not M.busy[rec] then setFollow(ent, false) end
            Cron.Halt(timer)
          end
        end)
        G.log("chauffeur: mounting " .. rec .. " to " .. slot)
      end
    end
    if not next(M.busy) then
      G.notify(G.STR.ch_no_driver)
    else
      engineOn(veh, true)
      G.notify(G.STR.ch_boarded)
    end
    local checks = 0
    if M.boardRetry then Cron.Halt(M.boardRetry) end
    M.boardRetry = Cron.Every(4.0, function(timer)
      checks = checks + 1
      if checks > 5 or not next(M.crew) then
        Cron.Halt(timer)
        if M.boardRetry == timer.id then M.boardRetry = nil end
        return
      end
      for rec, v in pairs(M.crew) do
        G.companion.eachActive(function(r, ent)
          if r == rec and IsDefined(ent) and IsDefined(v) and not isSeated(ent) then
            pcall(sendMount, ent, v,
              M.busy[rec] and "seat_front_left" or (M.seat[rec] ~= "auto" and M.seat[rec] or nil)
              or "seat_back_left", true)
            G.log("chauffeur: board retry " .. r)
          end
        end)
      end
    end)
  end

  function M.enter()
    local player = Game.GetPlayer()
    if not player then return end
    if Game.GetMountedVehicle(player) then return end
    local _, _, veh = currentDriver()
    if not veh then
      for _, v in pairs(M.crew) do
        if IsDefined(v) then veh = v break end
      end
    end
    if not veh then G.notify(G.STR.ch_no_vehicle) return end
    local taken = {}
    G.companion.eachActive(function(_, ent)
      local sl = seatOf(ent)
      if sl then taken[sl] = true end
    end)
    for _, sname in ipairs({ "seat_front_right", "seat_back_left",
      "seat_back_right" }) do
      if not taken[sname] and hasSlot(veh, sname) then
        pcall(mountPlayer, sname, veh)
        return
      end
    end
    G.notify(G.STR.ch_no_seat)
  end

  function M.drive()
    local rec, _, veh = currentDriver()
    if not rec then G.notify(G.STR.ch_no_driver) return end
    local wp = waypoint()
    if not wp then G.notify(G.STR.ch_no_waypoint) return end
    stopRun()
    engineOn(veh, true)
    G.log("chauffeur: drive, vehAI=" .. tostring(M.vehAI[hashOf(veh)] ~= nil))
    local ok, err = pcall(function()
      local cmd = NewObject("handle:AIVehicleDriveToPointAutonomousCommand")
      pcall(function() cmd.targetPosition = Vector3.new(wp.x, wp.y, wp.z) end)
      pcall(function() cmd.driveDownTheRoadIndefinitely = false end)
      pcall(function() cmd.clearTrafficOnPath = true end)
      pcall(function() cmd.needDriver = true end)
      pcall(function() cmd.maxSpeed = 18.0 end)
      pcall(function() cmd.minimumDistanceToTarget = 10.0 end)
      cmd = cmd:Copy()
      local ev = NewObject("handle:AINPCCommandEvent")
      ev.command = cmd
      veh:QueueEvent(ev)
      M.run = { cmd = cmd, veh = veh, dest = wp, mode = "drive" }
    end)
    if not ok or not M.run then
      G.log("chauffeur: drive command failed: " .. tostring(err))
      G.notify(G.STR.ch_drive_fail)
      return
    end
    logCmdState("drive", M.run.cmd)
    startTicker(ARRIVE)
    G.notify(G.STR.ch_driving)
  end

  function M.pickup()
    local rec, _, veh = currentDriver()
    if not rec then G.notify(G.STR.ch_no_driver) return end
    local player = Game.GetPlayer()
    if Game.GetMountedVehicle(player) == veh then return end
    stopRun()
    engineOn(veh, true)
    G.log("chauffeur: pickup, vehAI=" .. tostring(M.vehAI[hashOf(veh)] ~= nil))
    local ok, err = pcall(function()
      local cmd = NewObject("handle:AIVehicleFollowCommand")
      cmd.target = player
      cmd.distanceMin = PICKUP_STOP
      cmd.stopWhenTargetReached = false
      cmd.needDriver = true
      cmd.useTraffic = false
      cmd.useKinematic = true
      cmd = cmd:Copy()
      local ev = NewObject("handle:AINPCCommandEvent")
      ev.command = cmd
      veh:QueueEvent(ev)
      M.run = { cmd = cmd, veh = veh, mode = "pickup" }
    end)
    if not ok or not M.run then
      G.log("chauffeur: pickup command failed: " .. tostring(err))
      G.notify(G.STR.ch_drive_fail)
      return
    end
    logCmdState("pickup", M.run.cmd)
    startTicker(PICKUP_STOP + 4.0, player)
    G.notify(G.STR.ch_coming)
  end

  function M.release()
    stopRun()
    local player = Game.GetPlayer()
    local vehs = {}
    for rec, veh in pairs(M.crew) do
      G.companion.eachActive(function(r, ent)
        if r == rec and IsDefined(ent) and IsDefined(veh) then
          G.log("chauffeur: release " .. r .. " seated=" .. tostring(isSeated(ent))
            .. " slot=" .. tostring(seatOf(ent)))
          local slot = seatOf(ent) or M.seat[rec]
          pcall(sendUnmount, ent, veh, slot)
          vehs[#vehs + 1] = veh
          Cron.After(2.0, function()
            if IsDefined(ent) then setFollow(ent, true) end
          end)
          Cron.After(4.5, function()
            if IsDefined(ent) and isSeated(ent) then
              G.log("chauffeur: unmount ignored for " .. r
                .. ", respawning beside player")
              local saved = G.companion.captureOne(r, true)
              G.companion.dismiss(r, true)
              Cron.After(0.6, function()
                G.companion.respawn({ saved })
              end)
            end
          end)
        end
      end)
      M.crew[rec] = nil
      M.busy[rec] = nil
    end
    local pveh = player and Game.GetMountedVehicle(player) or nil
    for _, veh in ipairs(vehs) do
      local same = false
      pcall(function() same = pveh ~= nil and hashOf(pveh) == hashOf(veh) end)
      if not same then engineOn(veh, false) end
    end
    G.notify(G.STR.ch_released)
  end

  M.autoTried = {}
  M.autoTriedAt = {}
  M.pendingSlot = {}

  function M.autoSeat(rec, ent, veh)
    local key = rec .. hashOf(veh)
    local now = os.clock()
    if M.autoTriedAt[key] and now - M.autoTriedAt[key] > 30 then
      M.autoTried[key] = nil
    end
    if (M.autoTried[key] or 0) >= 2 then return false end
    local taken = {}
    local player = Game.GetPlayer()
    if player then
      local ps = seatOf(player)
      if ps then taken[ps] = true end
    end
    G.companion.eachActive(function(_, other)
      if IsDefined(other) then
        local s = seatOf(other)
        if s then taken[s] = true end
      end
    end)
    for slot, at in pairs(M.pendingSlot) do
      if now - at < 5 then taken[slot] = true end
    end
    local want = M.seat[rec]
    local slot = nil
    if want and want ~= "auto" and want ~= "seat_front_left"
      and hasSlot(veh, want) and not taken[want] then
      slot = want
    else
      for _, s in ipairs({ "seat_back_left", "seat_back_right",
        "seat_front_right" }) do
        if hasSlot(veh, s) and not taken[s] then slot = s break end
      end
    end
    if not slot then return false end
    M.autoTried[key] = (M.autoTried[key] or 0) + 1
    M.autoTriedAt[key] = now
    M.pendingSlot[slot] = now
    pcall(sendMount, ent, veh, slot)
    G.log("chauffeur: auto-seat " .. rec .. " to " .. slot)
    return true
  end

  M.reseatAt = {}

  function M.fixSeats(veh)
    local now = os.clock()
    local used = {}
    pcall(function()
      local player = Game.GetPlayer()
      local ps = player and seatOf(player) or nil
      if ps then used[ps] = true end
    end)
    G.companion.eachActive(function(rec, ent, model)
      if model.chassis ~= "Android" or model.hijack or not IsDefined(ent) then return end
      local s = seatOf(ent)
      if not s then return end
      if not used[s] then
        used[s] = true
      else
        if now - (M.reseatAt[rec] or 0) < 5 then return end
        local free = nil
        for _, cand in ipairs({ "seat_back_left", "seat_back_right",
          "seat_front_right" }) do
          if cand ~= s and hasSlot(veh, cand) and not used[cand] then
            free = cand
            break
          end
        end
        if free then
          M.reseatAt[rec] = now
          used[free] = true
          pcall(sendMount, ent, veh, free, true)
          G.log("chauffeur: seat collision, moving " .. rec .. " to " .. free)
        end
      end
    end)
  end

  local PC_SE = "GameplayRestriction.VehicleCombat"

  function M.passengerTick(veh)
    local player = Game.GetPlayer()
    if not player then return end
    local want = false
    if veh then
      local vHash = hashOf(veh)
      for _, v in pairs(M.busy) do
        local ok, same = pcall(function() return hashOf(v) == vHash end)
        if ok and same then want = true end
      end
      if want and seatOf(player) == "seat_front_left" then want = false end
    end
    if not want and M.pcApplied then
      pcall(function() player:DCForceVehCombat(false) end)
      M.pcApplied = nil
      M.autoCombat = nil
      G.log("chauffeur: passenger combat off")
    end
    if want and not player:IsInCombat() then
      M.autoCombat = nil
    end
    if want and M.pcApplied == nil then
      M.pcApplied = true
    end
    if want and not M.autoCombat then
      local inCombat = false
      pcall(function() inCombat = player:IsInCombat() end)
      if inCombat then
        M.autoCombat = true
        M.passengerAttack()
        G.log("chauffeur: passenger combat auto-engaged")
      end
    end
  end

  function M.passengerAttack()
    local player = Game.GetPlayer()
    if not player then return end
    local veh = Game.GetMountedVehicle(player)
    if not veh then return end
    if seatOf(player) == "seat_front_left" then return end
    pcall(function() player:DCForceVehCombat(true) end)
    Cron.After(0.3, function()
      pcall(function()
        local req = NewObject("handle:EquipmentSystemWeaponManipulationRequest")
        req.owner = Game.GetPlayer()
        req.requestType = EquipmentManipulationAction.RequestLastUsedOrFirstAvailableWeapon
        Game.GetScriptableSystemsContainer()
          :Get(CName.new("EquipmentSystem")):QueueRequest(req)
      end)
    end)
    G.log("chauffeur: passenger attack requested")
  end

  M.camIdx = 0

  function M.cycleCamera()
    local player = Game.GetPlayer()
    if not player then return end
    local veh = Game.GetMountedVehicle(player)
    if not veh then return end
    local rec, _, bveh = currentDriver()
    if not rec then return end
    local ok, same = pcall(function() return hashOf(bveh) == hashOf(veh) end)
    if not ok or not same then return end
    local cams = { { 0, -8.0, 0.5 }, { 0, -12.0, 0.5 } }
    M.camIdx = (M.camIdx + 1) % (#cams + 1)
    if M.camIdx == 0 then
      M.camTick = false
      return
    end
    if not M.camTick then
      M.camTick = true
      Cron.Every(0.1, function(timer)
        local p = Game.GetPlayer()
        if not M.camTick or not p or not Game.GetMountedVehicle(p) then
          M.camTick = false
          M.camIdx = 0
          pcall(function()
            p:GetFPPCameraComponent():SetLocalPosition(Vector4.new(0, 0, 0, 1.0))
          end)
          Cron.Halt(timer)
          return
        end
        pcall(function()
          local c = cams[M.camIdx]
          local cam = p:GetFPPCameraComponent()
          cam:SetLocalPosition(Vector4.new(c[1], c[2], c[3], 1.0))
          cam.pitchMax = 80
          cam.pitchMin = -80
          cam.yawMaxRight = -360
          cam.yawMaxLeft = 360
        end)
      end)
    end
  end

  function M.autoEnterWatch(veh)
    local ticks = 0
    Cron.Every(0.5, function(timer)
      ticks = ticks + 1
      if ticks > 60 or not IsDefined(veh) then Cron.Halt(timer) return end
      local player = Game.GetPlayer()
      if not player then return end
      if Game.GetMountedVehicle(player) then Cron.Halt(timer) return end
      local d = 99.0
      pcall(function()
        d = Vector4.Distance(player:GetWorldPosition(), veh:GetWorldPosition())
      end)
      if d < 3.5 then
        Cron.Halt(timer)
        M.enter()
      end
    end)
  end

  function M.onAutodrive()
    local player = Game.GetPlayer()
    if not player then return end
    local veh = Game.GetMountedVehicle(player)
    if not veh then return end
    local rec, _, bveh = currentDriver()
    if not rec then return end
    local ok, same = pcall(function() return hashOf(bveh) == hashOf(veh) end)
    if not ok or not same then return end
    if M.run then
      stopRun(G.STR.ch_stopped)
    else
      M.drive()
    end
  end

  local function crewVehicle()
    local _, _, veh = currentDriver()
    if veh then return veh end
    local player = Game.GetPlayer()
    local mv = player and Game.GetMountedVehicle(player) or nil
    if mv then return mv end
    for _, v in pairs(M.crew) do
      if IsDefined(v) then return v end
    end
    return nil
  end

  function M.radio()
    local veh = crewVehicle()
    if not veh then return end
    pcall(function() veh:ToggleRadioReceiver(not veh:IsRadioReceiverActive()) end)
  end

  function M.radioNext()
    local veh = crewVehicle()
    if not veh then return end
    pcall(function() veh:NextRadioReceiverStation() end)
  end

  function M.windows()
    local veh = crewVehicle()
    if not veh then return end
    pcall(function()
      local ps = veh:GetVehiclePS()
      if tostring(ps:GetWindowState(1).value) == "Closed" then
        ps:OpenAllVehWindows()
      else
        ps:CloseAllVehWindows()
      end
    end)
  end

  function M.doors()
    local veh = crewVehicle()
    if not veh then return end
    pcall(function()
      local ps = veh:GetVehiclePS()
      if tostring(ps:GetDoorState(1).value) == "Closed" then
        ps:OpenAllRegularVehDoors(true)
      else
        ps:CloseAllVehDoors(true)
      end
    end)
  end

  function M.install()
    Observe("VehicleObject", "OnRequestComponents", function(self, ri)
      EntityRequestComponentsInterface.RequestComponent(ri, "AIComponent",
        "AIVehicleAgent", false)
    end)
    Observe("VehicleObject", "OnTakeControl", function(self, ri)
      pcall(function()
        local ai = EntityResolveComponentsInterface.GetComponent(ri, "AIComponent")
        local hash = hashOf(self)
        M.vehAI[hash] = ai
        M.vehSeen[hash] = self
      end)
    end)
  end

  return M
end
