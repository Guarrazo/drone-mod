return function(G)
  local Cron = G.Cron
  local M = { moving = {}, gen = {}, DEBUG = false }

  local RANGE = 60.0
  local ARRIVE = 3.0
  local HOP = 12.0
  local MOVE_TIMEOUT = 30.0
  local RETURN_DIST = 5.0
  local RETURN_COOLDOWN = 6.0

  local MARK_SECONDS = 6.0
  local WAYPOINT_MAX = 200.0

  function M.dropMark()
    if not M.mark then return end
    pcall(function() Game.GetMappinSystem():UnregisterMappin(M.mark) end)
    M.mark = nil
  end

  function M.markPoint(pos)
    M.dropMark()
    pcall(function()
      local data = MappinData.new()
      data.mappinType = TweakDBID.new("Mappins.DefaultStaticMappin")
      data.variant = gamedataMappinVariant.CustomPositionVariant
      data.visibleThroughWalls = true
      M.mark = Game.GetMappinSystem():RegisterMappin(data, pos)
      M.markPos = { x = pos.x, y = pos.y }
    end)
    if M.mark then
      G.Cron.After(MARK_SECONDS, function() M.dropMark() end)
    end
  end

  local function activeRows()
    local rows = {}
    G.companion.eachActive(function(rec, ent, model)
      if not G.companion.isDown(ent) then
        rows[#rows + 1] = { rec = rec, ent = ent, model = model }
      end
    end)
    return rows
  end

  local function lookTarget(player)
    local target
    pcall(function()
      target = Game.GetTargetingSystem():GetLookAtObject(player, true, false)
    end)
    if not IsDefined(target) then return nil end
    local valid = false
    pcall(function()
      if target:IsPlayer() or not target:IsNPC() then return end
      if target:GetAttitudeTowards(player) ~= EAIAttitude.AIA_Hostile then return end
      if Game.GetStatusEffectSystem():HasStatusEffect(
        target:GetEntityID(), TweakDBID.new(G.TDB .. "CompanionSE")) then return end
      if G.companion.isDown(target) then return end
      valid = true
    end)
    if valid then return target end
    return nil
  end

  local function aimPoint(player)
    local pos
    pcall(function()
      local v = Game.GetTargetingSystem():GetLookAtPosition(player, true, false)
      if v and not (v.x == 0 and v.y == 0 and v.z == 0) then
        pos = { x = v.x, y = v.y, z = v.z }
      end
    end)
    if not pos then
      if M.DEBUG then G.log("order-debug: aim no look-at position") end
      return nil
    end
    local p = player:GetWorldPosition()
    local dx, dy, dz = pos.x - p.x, pos.y - p.y, pos.z - p.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if M.DEBUG then
      G.log(string.format("order-debug: aim look-at (%.1f,%.1f,%.1f) dist %.1fm",
        pos.x, pos.y, pos.z, dist))
    end
    if dist > RANGE then return nil end
    return pos
  end

  local function teleport(ent, x, y, z)
    pcall(function()
      local cmd = NewObject("handle:AITeleportCommand")
      cmd.position = Vector4.new(x, y, z, 1.0)
      cmd.rotation = 0.0
      cmd.doNavTest = false
      ent:GetAIControllerComponent():SendCommand(cmd)
    end)
  end

  function M.moveCmd(ent, x, y, z, mtype)
    return pcall(function()
      local wp = NewObject("WorldPosition")
      WorldPosition.SetVector4(wp, Vector4.new(x, y, z, 1.0))
      local spec = NewObject("AIPositionSpec")
      AIPositionSpec.SetWorldPosition(spec, wp)
      local ok = false
      pcall(function() ok = AIPositionSpec.IsWorldPosition(spec) end)
      if not ok then spec.worldPosition = wp end
      local cmd = NewObject("handle:AIMoveToCommand")
      cmd.movementTarget = spec
      cmd.movementType = mtype or moveMovementType.Run
      cmd.desiredDistanceFromTarget = 1.0
      cmd.finishWhenDestinationReached = true
      ent:GetAIControllerComponent():SendCommand(cmd)
    end)
  end

  local function hopToward(ent, dest)
    local p = ent:GetWorldPosition()
    local dx, dy = dest.x - p.x, dest.y - p.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d <= HOP then return dest end
    local s = HOP / d
    return { x = p.x + dx * s, y = p.y + dy * s, z = p.z }
  end

  local function dist2d(ent, to)
    local p = ent:GetWorldPosition()
    local dx, dy = p.x - to.x, p.y - to.y
    return math.sqrt(dx * dx + dy * dy)
  end

  local function holdSoon(rec, ent, delay, gen)
    Cron.After(delay, function()
      if M.gen[rec] ~= gen then return end
      M.moving[rec] = nil
      if IsDefined(ent) and not G.companion.isDown(ent) then
        G.hacks.setHold(rec, ent, true)
      end
    end)
  end

  function M.sendTo(row, pos, idx)
    local rec, ent = row.rec, row.ent
    local gen = (M.gen[rec] or 0) + 1
    M.gen[rec] = gen
    G.hacks.clearHold(rec, ent)
    M.moving[rec] = true
    local side = (idx % 2 == 0) and 1 or -1
    local off = side * math.ceil(idx / 2) * 2.0
    local dest = { x = pos.x + off, y = pos.y - off * 0.3, z = pos.z }
    G.hacks.anchor[rec] = dest

    if M.DEBUG then
      local p = ent:GetWorldPosition()
      G.log(string.format("order-debug: %s %s at (%.1f,%.1f,%.1f) -> dest (%.1f,%.1f,%.1f)",
        rec, row.model.fly and "fly" or "ground", p.x, p.y, p.z, dest.x, dest.y, dest.z))
    end

    if row.model.fly then
      teleport(ent, dest.x, dest.y, dest.z + 2.5)
      holdSoon(rec, ent, 0.4, gen)
      return
    end

    local hop = hopToward(ent, dest)
    if not M.moveCmd(ent, hop.x, hop.y, hop.z) then
      G.log("order: AIMoveToCommand failed for " .. rec .. ", teleporting")
      teleport(ent, dest.x, dest.y, dest.z)
      holdSoon(rec, ent, 0.4, gen)
      return
    end

    local t0 = os.clock()
    local ticker
    ticker = Cron.Every(0.5, function()
      if M.gen[rec] ~= gen then
        Cron.Halt(ticker)
        return
      end
      if not IsDefined(ent) or G.companion.isDown(ent) or not M.moving[rec] then
        M.moving[rec] = nil
        Cron.Halt(ticker)
        return
      end
      local ok, err = pcall(function()
        if dist2d(ent, dest) < ARRIVE or os.clock() - t0 > MOVE_TIMEOUT then
          Cron.Halt(ticker)
          M.moving[rec] = nil
          if M.DEBUG then
            G.log(string.format("order-debug: %s done after %.1fs, %.1fm from dest",
              rec, os.clock() - t0, dist2d(ent, dest)))
          end
          G.hacks.setHold(rec, ent, true)
          return
        end
        if dist2d(ent, hop) < ARRIVE then
          hop = hopToward(ent, dest)
          M.moveCmd(ent, hop.x, hop.y, hop.z)
          if M.DEBUG then
            G.log(string.format("order-debug: %s next hop (%.1f,%.1f)", rec, hop.x, hop.y))
          end
        end
      end)
      if not ok then
        Cron.Halt(ticker)
        M.moving[rec] = nil
        G.log("order: move ticker error for " .. rec .. ": " .. tostring(err))
      end
    end)
  end

  local function taggedObjects()
    local out = {}
    pcall(function()
      local defs = Game.GetAllBlackboardDefs()
      local bb = Game.GetBlackboardSystem():Get(defs.TaggedObjectsList)
      local list = FromVariant(bb:GetVariant(defs.TaggedObjectsList.taggedObjectsList))
      if type(list) == "table" then
        for _, obj in ipairs(list) do out[#out + 1] = obj end
      end
    end)
    return out
  end

  local function hostileTo(player, obj)
    local hostile = false
    pcall(function()
      hostile = obj:GetAttitudeTowards(player) == EAIAttitude.AIA_Hostile
    end)
    return hostile
  end

  M.scanFocusKey = nil

  function M.scanTick()
    if not G.settings.scanFocus then return end
    local player = Game.GetPlayer()
    if not player then return end
    local inCombat = false
    pcall(function() inCombat = player:IsInCombat() end)
    if not inCombat then
      M.scanFocusKey = nil
      return
    end
    local rows = activeRows()
    if #rows == 0 then return end
    local best, bestDist = nil, 80.0
    local ppos = player:GetWorldPosition()
    for _, obj in ipairs(taggedObjects()) do
      if IsDefined(obj) and not obj:IsPlayer() and obj:IsNPC()
        and not G.companion.isDown(obj) and hostileTo(player, obj) then
        local d = Vector4.Distance(ppos, obj:GetWorldPosition())
        if d < bestDist then best, bestDist = obj, d end
      end
    end
    if not best then return end
    local key = G.companion.entKey(best)
    if key == M.scanFocusKey then return end
    M.scanFocusKey = key
    local n = G.companion.focusAll(best)
    G.log(string.format("scan focus: tagged target at %.0fm, %d drones", bestDist, n))
    if n > 0 then G.notifyRare("focus", string.format(G.STR.scan_focus_msg, n)) end
  end

  local function ofKind(kind)
    return function(row) return kind == nil or (kind == "fly") == (row.model.fly == true) end
  end

  function M.trigger(kind)
    if G.dronecam and G.dronecam.active then
      G.dronecam.stop()
      return
    end
    local player = Game.GetPlayer()
    if not player then return end
    local keep = ofKind(kind)
    local rows = {}
    for _, row in ipairs(activeRows()) do
      if keep(row) then rows[#rows + 1] = row end
    end
    local function tell(msg)
      G.notify(kind and (G.STR["order_" .. kind] .. ": " .. msg) or msg)
    end
    if #rows == 0 then
      tell(G.STR.no_drone)
      return
    end

    local target = lookTarget(player)
    if target then
      local n = G.companion.focusAll(target, keep)
      if n > 0 then
        tell(string.format(G.STR.order_focus, n))
      end
      return
    end

    local pos = aimPoint(player)
    if pos then
      M.markPoint(pos)
      local n = 0
      for _, row in ipairs(rows) do
        if not row.model.static then
          n = n + 1
          M.sendTo(row, pos, n)
        end
      end
      if n > 0 then
        tell(string.format(G.STR.order_move, n))
      end
      return
    end

    M.release(rows)
  end

  local function groundAt(pos)
    local z = pos.z
    pcall(function()
      local hit, trace = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(
        Vector4.new(pos.x, pos.y, pos.z + 30.0, 1.0), Vector4.new(pos.x, pos.y, pos.z - 60.0, 1.0), "Static", true, false)
      if hit and trace then z = trace.position.z end
    end)
    return { x = pos.x, y = pos.y, z = z }
  end

  function M.toWaypoint()
    local player = Game.GetPlayer()
    if not player then return end
    local rows = activeRows()
    if #rows == 0 then
      G.notify(G.STR.no_drone)
      return
    end
    local wp = G.chauffeur.waypoint()
    if not wp then
      G.notify(G.STR.ch_no_waypoint)
      return
    end
    local p = player:GetWorldPosition()
    local d = math.sqrt((wp.x - p.x) ^ 2 + (wp.y - p.y) ^ 2)
    if d > WAYPOINT_MAX then
      G.notify(string.format(G.STR.order_wp_far, d, WAYPOINT_MAX))
      return
    end
    local pos = groundAt(wp)
    local n = 0
    for _, row in ipairs(rows) do
      if not row.model.static then
        n = n + 1
        M.sendTo(row, pos, n)
      end
    end
    if n > 0 then G.notify(string.format(G.STR.order_wp, n)) end
  end

  function M.releaseOne(row)
    M.gen[row.rec] = (M.gen[row.rec] or 0) + 1
    M.moving[row.rec] = nil
    if G.dronecam and G.dronecam.pilotedOnce[row.rec] then
      G.dronecam.pilotedOnce[row.rec] = nil
      G.dronecam.resetDrone(row.rec)
    elseif G.hacks.held[row.rec] then
      G.hacks.setHold(row.rec, row.ent, false)
    end
  end

  function M.toggleHold(rec)
    for _, row in ipairs(activeRows()) do
      if row.rec == rec then
        if G.hacks.held[rec] then
          M.releaseOne(row)
        else
          M.gen[rec] = (M.gen[rec] or 0) + 1
          M.moving[rec] = nil
          G.hacks.anchorHere(rec, row.ent)
          G.hacks.setHold(rec, row.ent, true)
        end
        return
      end
    end
  end

  M.lastReturn = {}

  function M.keepAnchors(rows, inCombat, piloted)
    if inCombat then
      M.combatSeen = true
      return
    end
    local afterCombat = M.combatSeen
    M.combatSeen = nil
    local now = os.clock()
    for _, row in ipairs(rows) do
      local rec = row.rec
      local anchor = G.hacks.anchor[rec]
      if anchor and G.hacks.held[rec] and not M.moving[rec] and rec ~= piloted
        and not row.model.static and now - (M.lastReturn[rec] or 0) > RETURN_COOLDOWN then
        local ok, drift = pcall(dist2d, row.ent, anchor)
        if ok then
          if drift > RETURN_DIST then
            M.lastReturn[rec] = now
            G.log(string.format("order: %s drifted %.1fm from anchor, returning", rec, drift))
            M.sendTo(row, anchor, 0)
          elseif afterCombat then
            M.lastReturn[rec] = now
            G.hacks.setHold(rec, row.ent, true)
          end
        end
      end
    end
  end

  function M.release(rows)
    rows = rows or activeRows()
    for _, row in ipairs(rows) do
      M.releaseOne(row)
    end
    G.companion.clearFocus()
    G.notify(G.STR.order_release)
  end

  return M
end
