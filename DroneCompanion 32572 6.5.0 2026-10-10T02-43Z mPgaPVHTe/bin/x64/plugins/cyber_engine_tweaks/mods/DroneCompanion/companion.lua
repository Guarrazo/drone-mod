return function(G)
  local Cron = G.Cron
  local M = {
    stashed = nil,
    deadPending = {},
    regenDelay = 0,
    muted = {},
    muteApplied = {},
    passive = {},
    defensive = {},
    arena = {},
    arenaSince = {},
    lastTarget = {},
    targetEnt = {},
    lit = {},
    spawnGen = {},
    spawnTime = {},
    facePos = {},
    faceTries = {},
    faceHeld = {},
    mappin = {},
    dismissing = {},
    rescueAt = {},
    rescueTries = {},
  }

  local RESCUE_DIST = 15.0
  local RESCUE_MIN_TICKS = 3
  local RESCUE_COOLDOWN = 20.0
  local RESCUE_TRIES = 2

  local TARGET_SWAP = 0.6
  local TARGET_DROP = 40.0
  local LEASH_GRACE = 6.0
  local LEASH_MAX = 300.0

  local SE_MARKER = G.TDB .. "CompanionSE"
  local SE_PASSIVE = G.TDB .. "PassiveSE"
  local SE_ARENA = G.TDB .. "ArenaSE"
  local SE_DEFENSIVE = G.TDB .. "DefensiveSE"

  local function tdbid(s) return TweakDBID.new(s) end

  local function entKey(ent)
    local key
    pcall(function()
      local id = ent:GetEntityID()
      key = id.hash and tostring(id.hash) or tostring(id)
    end)
    return key or tostring(ent)
  end
  M.entKey = entKey

  local function isDown(ent)
    if not IsDefined(ent) then return true end
    local dead = false
    pcall(function() dead = ent:IsDead() end)
    if dead then return true end
    pcall(function()
      local hls = ent:GetHighLevelStateFromBlackboard()
      dead = hls == gamedataNPCHighLevelState.Unconscious
        or hls == gamedataNPCHighLevelState.Dead
    end)
    if dead then return true end
    pcall(function()
      dead = ScriptedPuppet.IsDefeated(ent) == true
    end)
    return dead
  end
  M.isDown = isDown

  local function downReason(ent)
    if not IsDefined(ent) then return "undefined" end
    local bits = {}
    pcall(function() bits[#bits + 1] = "dead=" .. tostring(ent:IsDead()) end)
    pcall(function() bits[#bits + 1] = "hls=" .. tostring(ent:GetHighLevelStateFromBlackboard()) end)
    pcall(function() bits[#bits + 1] = "defeated=" .. tostring(ScriptedPuppet.IsDefeated(ent)) end)
    pcall(function()
      bits[#bits + 1] = string.format("hp=%.0f", Game.GetStatPoolsSystem():GetStatPoolValue(
        ent:GetEntityID(), gamedataStatPoolType.Health))
    end)
    return table.concat(bits, " ")
  end
  M.downReason = downReason

  local function spawnedAt(recordStr)
    if G.hijack and G.hijack.is(recordStr) then
      local ent = G.hijack.entityOf(recordStr)
      return IsDefined(ent) and { ent } or {}
    end
    return Game.GetCompanionSystem():GetSpawnedEntities(tdbid(recordStr))
  end

  function M.logVerify(recordStr, tag)
    pcall(function()
      local list = spawnedAt(recordStr)
      local ent = list[1]
      if not IsDefined(ent) then
        G.log(string.format("verify %ss %s: entity gone", tag, recordStr))
      end
    end)
  end

  function M.isRegistered(recordStr)
    local list = spawnedAt(recordStr)
    if #list > 0 and IsDefined(list[1]) then
      M.applyCompanion(list[1], recordStr)
      return true
    end
    for _, row in ipairs(M.aliveCache or {}) do
      if row.rec == recordStr and IsDefined(row.ent) then return true end
    end
    return false
  end

  function M.entityOf(rec)
    local found
    M.eachActive(function(r, ent) if r == rec then found = ent end end)
    return found
  end

  function M.eachActive(fn)
    for _, model in ipairs(G.MODELS) do
      for i = 1, G.INSTANCES do
        local rec = G.recordId(model, i)
        local list = spawnedAt(rec)
        if #list > 0 and IsDefined(list[1]) and not (G.arena and G.arena.busy(rec)) then fn(rec, list[1], model) end
      end
    end
    if G.hijack then G.hijack.each(fn) end
  end

  local function applyPassiveState(puppet, passive)
    pcall(function()
      if passive then
        StatusEffectHelper.ApplyStatusEffect(puppet, tdbid(SE_PASSIVE))
      else
        StatusEffectHelper.RemoveStatusEffect(puppet, tdbid(SE_PASSIVE))
      end
      local senses = puppet:GetSensesComponent()
      if senses then senses:Toggle(not passive) end
    end)
  end

  local WHITE = { Red = 255, Green = 250, Blue = 235, Alpha = 255 }

  local function isWorldLight(comp)
    local cls = ""
    pcall(function() cls = tostring(comp:GetClassName()) end)
    return cls:find("gameLightComponent", 1, true) ~= nil
      or cls:find("vehicleLightComponent", 1, true) ~= nil
  end

  local function pushLight(ent, on)
    local found = false
    local comps = ent:GetComponents()
    for _, comp in ipairs(comps) do
      if isWorldLight(comp) and comp.SetIntensity ~= nil then

        local ok = pcall(function()
          if comp.ToggleLight ~= nil then comp:ToggleLight(on) else comp:Toggle(on) end
          if on then

            local curInt, curRad = 0.0, 0.0
            pcall(function()
              local cur = comp:GetCurrentSettings()
              curInt, curRad = cur.intensity or 0.0, cur.radius or 0.0
            end)
            if comp.SetStrength ~= nil then comp:SetStrength(400.0) end
            comp:SetIntensity(math.max(curInt, 1500.0))
            comp:SetRadius(math.max(curRad, 60.0))
            comp:SetColor(Color.new(WHITE))
          end
        end)
        if ok then found = true end
      end
    end

    pcall(function()
      local evt = NewObject("ToggleLightEvent")
      evt.toggle = on
      evt.loop = false
      ent:QueueEvent(evt)
    end)
    return found
  end

  function M.setLight(recordStr, on)
    M.lit[recordStr] = on or nil
    local list = spawnedAt(recordStr)
    if #list == 0 or not IsDefined(list[1]) then return true end
    local ok, found = pcall(pushLight, list[1], on)
    if not ok then
      G.log("light toggle failed: " .. tostring(found))
      return false
    end
    return found
  end

  function M.setPassive(recordStr, passive)
    M.passive[recordStr] = passive or nil
    local list = spawnedAt(recordStr)
    if #list > 0 and IsDefined(list[1]) then
      applyPassiveState(list[1], passive)
      if passive then

        pcall(function()
          local player = Game.GetPlayer()
          local role = AIFollowerRole.new()
          role.followerRef = Game.CreateEntityReference("#player", {})
          role.attitudeGroupName = CName.new("player")
          role:SetFollowTarget(player)
          AIHumanComponent.SetCurrentRole(list[1], role)
        end)
      end
    end
  end

  M.STANCES = { "combat", "defensive", "passive", "arena" }

  function M.stanceOf(rec)
    if M.arena[rec] then return "arena" end
    if M.passive[rec] then return "passive" end
    if M.defensive[rec] then return "defensive" end
    return "combat"
  end

  function M.setArena(rec, on)
    local was = M.arena[rec]
    M.arena[rec] = on or nil
    if was ~= M.arena[rec] then
      M.arenaSince[rec] = on and os.clock() or nil
      G.log(string.format("arena stance %s -> %s", rec, tostring(on == true)))
    end
    if not on then
      M.lastTarget[rec] = nil
      M.targetEnt[rec] = nil
      if G.arena.busy(rec) then
        G.arena.leave(rec, "withdraw")
        return
      end
    end
    local list = spawnedAt(rec)
    if #list == 0 or not IsDefined(list[1]) then return end
    local puppet = list[1]
    pcall(function()
      if on then
        StatusEffectHelper.ApplyStatusEffect(puppet, tdbid(SE_ARENA))
      else
        StatusEffectHelper.RemoveStatusEffect(puppet, tdbid(SE_ARENA))
      end
    end)
    if on then
      if G.orders and (G.orders.moving[rec] or (G.hacks and G.hacks.held[rec])) then
        pcall(function()
          G.orders.releaseOne({ rec = rec, ent = puppet, model = G.modelOf(rec) })
        end)
      end
      if G.arena.arenaCount() < 2 then G.notify(G.STR.arena_need_two) end
    end
  end

  function M.setStance(rec, stance)
    local model = G.modelOf(rec)
    if stance == "arena" and model and (model.static or model.hijack) then stance = "combat" end
    M.defensive[rec] = stance == "defensive" or nil
    local list = spawnedAt(rec)
    if #list > 0 and IsDefined(list[1]) then
      pcall(function()
        if M.defensive[rec] then
          StatusEffectHelper.ApplyStatusEffect(list[1], tdbid(SE_DEFENSIVE))
        else
          StatusEffectHelper.RemoveStatusEffect(list[1], tdbid(SE_DEFENSIVE))
        end
      end)
    end
    M.setPassive(rec, stance == "passive")
    M.setArena(rec, stance == "arena")
  end

  local REPAIR_WINDOW = 60.0
  M.wreckUntil = {}
  local REPAIR_ITEM = "Items.CommonMaterial1"

  function M.repairCost(model)
    if not G.settings.immersive then return 0 end
    return 10 * ((model and G.pointsOf(model.chassis)) or 1)
  end

  function M.repairLeft(rec)
    local until_ = M.wreckUntil[rec]
    if not until_ then return nil end
    return math.max(0, math.floor(until_ - os.clock() + 0.5))
  end

  function M.repair(rec)
    if not M.deadPending[rec] then return false end
    local model = G.modelOf(rec)
    local ent = spawnedAt(rec)[1]
    if not model or not IsDefined(ent) then return false end
    local player = Game.GetPlayer()
    local cost = M.repairCost(model)
    if cost > 0 then
      local ts = Game.GetTransactionSystem()
      local itemId = ItemID.FromTDBID(tdbid(REPAIR_ITEM))
      local have = 0
      pcall(function() have = ts:GetItemQuantity(player, itemId) end)
      if have < cost then
        G.log(string.format("repair %s refused: %d/%d components", rec, have, cost))
        G.notify(string.format(G.STR.repair_nomats, cost, have))
        return false
      end
      local removed = false
      pcall(function() removed = ts:RemoveItem(player, itemId, cost) end)
      G.log(string.format("repair %s: paid %d components removed=%s", rec, cost, tostring(removed)))
    end
    local saved = M.captureOne(rec)
    M.wreckUntil[rec] = nil
    M.dismiss(rec, true)
    Cron.After(1.0, function() M.respawn({ saved }) end)
    G.log("repair " .. rec .. ": respawn scheduled")
    G.notify(string.format(G.STR.repair_done, G.squad.displayName(rec, model)))
    return true
  end

  function M.cycleStanceAll(step)
    local first = nil
    local rows = {}
    M.eachActive(function(rec, ent, model)
      if not model.static and not isDown(ent) then
        rows[#rows + 1] = rec
        if not first then first = rec end
      end
    end)
    if not first then
      G.notify(G.STR.no_drone)
      return nil
    end
    local at = 1
    for i, st in ipairs(M.STANCES) do
      if st == M.stanceOf(first) then at = i end
    end
    at = at + step
    if at > 3 then at = 1 end
    if at < 1 then at = 3 end
    local stance = M.STANCES[at]
    for _, rec in ipairs(rows) do M.setStance(rec, stance) end
    G.log(string.format("stance all -> %s (%d drones)", stance, #rows))
    G.notify(string.format(G.STR.stance_all_set, G.STR["st_" .. stance], #rows))
    return stance
  end

  function M.cycleStance(rec, step)
    local model = G.modelOf(rec)
    local noArena = model and (model.static or model.hijack)
    local at = 1
    for i, s in ipairs(M.STANCES) do
      if s == M.stanceOf(rec) then at = i end
    end
    repeat
      at = at + (step or 1)
      if at < 1 then at = #M.STANCES end
      if at > #M.STANCES then at = 1 end
    until not (noArena and M.STANCES[at] == "arena")
    M.setStance(rec, M.STANCES[at])
    return M.STANCES[at]
  end

  function M.focusAll(target, keep)
    local n = 0
    for _, row in ipairs(M.aliveCache or {}) do
      if IsDefined(row.ent) and not M.passive[row.rec] and not row.model.static and (not keep or keep(row)) then
        local ok = pcall(function()
          TargetTrackingExtension.InjectThreat(row.ent, target)
        end)
        if ok then
          n = n + 1
          M.lastTarget[row.rec] = entKey(target)
          M.targetEnt[row.rec] = target
        end
      end
    end
    return n
  end

  function M.clearFocus()
    M.lastTarget = {}
    M.targetEnt = {}
  end

  function M.resetRole(puppet)
    local player = Game.GetPlayer()
    if not player or not IsDefined(puppet) then return end
    local role = AIFollowerRole.new()
    role.followerRef = Game.CreateEntityReference("#player", {})
    role.attitudeGroupName = CName.new("player")
    role:SetFollowTarget(player)
    AIHumanComponent.SetCurrentRole(puppet, role)
  end

  M.weaponOf = {}

  function M.applyWeapon(puppet, model, rec)
    if not model or model.chassis ~= "Android" then return end
    local item = G.records.loadoutItem(M.weaponOf[rec] or G.settings.loadout)
    if not item then return end
    Cron.After(1.0, function()
      if not IsDefined(puppet) or isDown(puppet) then return end
      local ts = Game.GetTransactionSystem()
      local id
      if not pcall(function() id = ItemID.FromTDBID(tdbid(item)) end) then return end
      local slot = tdbid("AttachmentSlots.WeaponRight")
      local removed, gave, slotted, purged = nil, nil, nil, 0
      pcall(function() removed = ts:RemoveItemFromSlot(puppet, slot, false, true) end)
      pcall(function()
        local _, list = ts:GetItemList(puppet)
        for _, it in ipairs(list or {}) do
          local ty = it:GetItemType().value
          if ty:sub(1, 4) == "Wea_" then
            local old = it:GetID()
            if ts:RemoveItem(puppet, old, it:GetQuantity()) then purged = purged + 1 end
          end
        end
      end)
      pcall(function() gave = ts:GiveItem(puppet, id, 1) end)
      pcall(function() slotted = ts:AddItemToSlot(puppet, slot, id) end)
      G.log(string.format("weapon equip %s: removed=%s purged=%d give=%s slot=%s", item,
        tostring(removed), purged, tostring(gave), tostring(slotted)))
    end)
  end

  function M.applyCompanion(puppet, recordStr)
    if Game.GetStatusEffectSystem():HasStatusEffect(puppet:GetEntityID(), tdbid(SE_MARKER)) then
      return
    end
    local player = Game.GetPlayer()
    if not player then return end

    StatusEffectHelper.ApplyStatusEffect(puppet, tdbid(SE_MARKER))
    pcall(function()
      local model = G.modelOf(recordStr)
      if model and model.chassis then
        StatusEffectHelper.ApplyStatusEffect(puppet,
          tdbid(G.TDB .. "Chassis" .. model.chassis .. "SE"))
      end
    end)

    local ok, err = pcall(function()
      local role = AIFollowerRole.new()
      role.followerRef = Game.CreateEntityReference("#player", {})
      role.attitudeGroupName = CName.new("player")
      role:SetFollowTarget(player)

      puppet:GetAttitudeAgent():SetAttitudeGroup(CName.new("player"))
      puppet:GetAttitudeAgent():SetAttitudeTowards(player:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
      puppet.isPlayerCompanionCached = true
      puppet.isPlayerCompanionCachedTimeStamp = 0

      AIHumanComponent.SetCurrentRole(puppet, role)
    end)
    if not ok then
      G.log("role setup FAILED for " .. tostring(puppet:GetRecordID()) .. ": " .. tostring(err))
      return
    end

    local okScale, errScale = pcall(function()
      puppet.NPCManager:ScaleToPlayer()
    end)
    if not okScale then
      G.log("ScaleToPlayer failed (non-fatal): " .. tostring(errScale))
    end

    local model = G.modelOf(recordStr)
    G.perks.applyToDrone(puppet, model, recordStr)
    M.applyImmortal(puppet, model)
    if recordStr and not (model and model.hijack) then
      if not M.weaponOf[recordStr] then M.weaponOf[recordStr] = G.settings.loadout end
      M.applyWeapon(puppet, model, recordStr)
    end

    local myId = tostring(puppet:GetEntityID())
    M.eachActive(function(_, other)
      if tostring(other:GetEntityID()) ~= myId and not other:IsDead() then
        pcall(function()
          puppet:GetAttitudeAgent():SetAttitudeTowards(other:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
          other:GetAttitudeAgent():SetAttitudeTowards(puppet:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
        end)
      end
    end)

    if recordStr and M.passive[recordStr] then
      applyPassiveState(puppet, true)
    end
    if recordStr and M.arena[recordStr] then
      pcall(function() StatusEffectHelper.ApplyStatusEffect(puppet, tdbid(SE_ARENA)) end)
    end
    if recordStr and M.defensive[recordStr] then
      pcall(function() StatusEffectHelper.ApplyStatusEffect(puppet, tdbid(SE_DEFENSIVE)) end)
    end
    if recordStr and M.lit[recordStr] then
      pcall(pushLight, puppet, true)
    end

  end

  local SGN_SUFFIXES = {
    "sgn_idle_beep", "sgn_combat_enter", "sgn_combat_exit",
    "sgn_combat_no_clear_shot", "sgn_combat_target_lost",
    "sgn_comply_target_complies", "sgn_investigate_initial_reaction",
    "sgn_investigate_look_for_intruder", "sgn_investigate_result_ignored",
    "sgn_reprimand_final_warning", "sgn_reprimand_holster_weapon",
    "sgn_reprimand_leave_area",
  }
  local FAMILY_EXTRAS = {
    octant  = { "engines_nozzle_mv_fast", "engines_nozzle_mv_long", "engines_nozzle_mv_slow" },
    wyvern  = { "vo", "investigate_scan_start", "investigate_scan_red_start" },
    griffin = {},
  }

  local MUTE_STOP, UNMUTE_PLAY, MUTE_TAGS, MOVE_STOP, DESPAWN_STOPS = {}, {}, {}, {}, {}
  local soundTablesBuilt = false

  local function ensureSoundTables()
    if soundTablesBuilt then return end
    soundTablesBuilt = true
    for fam, extras in pairs(FAMILY_EXTRAS) do
      local base = "dev_drone_" .. fam .. "_default_"
      table.insert(UNMUTE_PLAY, CName.new(base .. "engines_loop"))
      table.insert(MUTE_STOP, CName.new(base .. "engines_loop"))
      for _, s in ipairs(SGN_SUFFIXES) do table.insert(MUTE_STOP, CName.new(base .. s)) end
      for _, s in ipairs(extras) do table.insert(MUTE_STOP, CName.new(base .. s)) end
    end

    table.insert(MUTE_STOP, CName.new("dev_drone_octant_ow_bkg_scanning_drone"))

    MUTE_TAGS = { CName.new("drones"), CName.new("devices"), CName.new("signals") }

    for fam, extras in pairs(FAMILY_EXTRAS) do
      local base = "dev_drone_" .. fam .. "_default_"
      local stops = { CName.new(base .. "engines_loop") }
      for _, s in ipairs(extras) do table.insert(stops, CName.new(base .. s)) end
      MOVE_STOP[fam] = stops
    end
    table.insert(MOVE_STOP.octant, CName.new("dev_drone_octant_ow_bkg_scanning_drone"))

    DESPAWN_STOPS = {
      CName.new("drone_destroyed"), CName.new("drone_defeated"),
      CName.new("drone_disable"), CName.new("drone_enable"),
    }
  end

  local function stopTagged(ent)
    ensureSoundTables()
    for _, tag in ipairs(MUTE_TAGS) do
      local evt = AudioEvent.new()
      evt.eventType = audioEventActionType.StopTagged
      evt.eventName = tag
      ent:QueueEvent(evt)
    end
  end

  local function toggleSoundComponents(ent, on)
    local n = 0
    pcall(function()
      for _, comp in ipairs(ent:GetComponents()) do
        local cls = tostring(comp:GetClassName()):lower()
        if cls:find("audio") or cls:find("sound") then
          if pcall(function() comp:Toggle(on) end) then n = n + 1 end
        end
      end
    end)
    return n
  end

  local function pushMute(ent, mute)
    ensureSoundTables()
    if mute then
      for _, n in ipairs(MUTE_STOP) do GameObject.StopSoundEvent(ent, n) end
      stopTagged(ent)
    else
      for _, n in ipairs(UNMUTE_PLAY) do GameObject.PlaySound(ent, n) end
    end
    toggleSoundComponents(ent, not mute)
  end

  local NETLINK_SE = "BaseStatusEffect.SystemCollapse"
  local NETLINK_INT = 9
  local NETLINK_DELAY = 0.6

  local function netlinkRecall(ent)
    local fired = false
    pcall(function()
      local int = Game.GetStatsSystem():GetStatValue(
        Game.GetPlayer():GetEntityID(), "Intelligence")
      if (int or 0) < NETLINK_INT then return end
      StatusEffectHelper.ApplyStatusEffect(ent, tdbid(NETLINK_SE))
      fired = true
    end)
    return fired
  end

  local function teleportTo(ent, x, y, z)
    pcall(function()
      local cmd = NewObject("handle:AITeleportCommand")
      cmd.position = Vector4.new(x, y, z, 1.0)
      cmd.rotation = 0.0
      cmd.doNavTest = false
      ent:GetAIControllerComponent():SendCommand(cmd)
    end)
  end

  local function dropMappin(rec)
    if not M.mappin[rec] then return end
    pcall(function() Game.GetMappinSystem():UnregisterMappin(M.mappin[rec]) end)
    M.mappin[rec] = nil
  end

  local function attachMappin(rec, ent)
    if M.mappin[rec] then return end
    pcall(function()
      local data = MappinData.new()
      data.mappinType = TweakDBID.new("Mappins.DroneCompanionMappin")
      data.variant = gamedataMappinVariant.CPO_PingDoorVariant
      data.visibleThroughWalls = true
      M.mappin[rec] = Game.GetMappinSystem():RegisterMappinWithObject(
        data, ent, CName.new("roleMappin"), Vector3.new(0, 0, 0.5))
    end)
  end
  M.attachMappin = attachMappin
  M.dropMappin = dropMappin

  M.wreckMappin = {}

  local function dropWreckMappin(rec)
    if not M.wreckMappin[rec] then return end
    M.wreckMappin[rec] = nil
    pcall(function() Game.GetPlayer():DCUnmarkWreck(rec) end)
  end

  local function markWreck(rec, ent, model)
    dropWreckMappin(rec)
    if not G.settings.minimap then return end
    local ok, err = pcall(function()
      local p = ent:GetWorldPosition()
      local done = Game.GetPlayer():DCMarkWreck(rec, model.chassis:lower(), Vector4.new(p.x, p.y, p.z + 0.5, 1.0))
      if done then M.wreckMappin[rec] = true end
    end)
    G.log(string.format("wreck mappin %s ok=%s %s", rec, tostring(ok and M.wreckMappin[rec] == true), ok and "" or tostring(err)))
  end

  local function famOf(rec)
    if rec:find("Octant") then return "octant" end
    if rec:find("Wyvern") then return "wyvern" end
    if rec:find("Griffin") then return "griffin" end
    return nil
  end

  M.holstered = {}
  M.drawnSeen = {}
  M.keepDrawn = {}
  M.holsterTry = {}
  M.calmTicks = 0
  local AUTO_HOLSTER_TICKS = 6
  local HOLSTER_RETRY_TICKS = 3
  local HOLSTER_LOG_TRIES = 5

  function M.weaponDrawn(ent)
    local drawn = false
    pcall(function()
      local ts = Game.GetTransactionSystem()
      drawn = IsDefined(ts:GetItemInSlot(ent, tdbid("AttachmentSlots.WeaponRight")))
        or IsDefined(ts:GetItemInSlot(ent, tdbid("AttachmentSlots.WeaponLeft")))
    end)
    return drawn
  end

  function M.isHolstered(recordStr)
    return M.holstered[recordStr] == true
  end

  local function sendHolster(ent, on)
    return pcall(function()
      local cmd = NewObject("handle:AISwitchToPrimaryWeaponCommand")
      cmd.unEquip = on
      ent:GetAIControllerComponent():SendCommand(cmd)
    end)
  end

  function M.setHolstered(recordStr, on, manual)
    local ok = false
    M.eachActive(function(rec, ent)
      if rec == recordStr then ok = sendHolster(ent, on) end
    end)
    M.holstered[recordStr] = ok and on or nil
    M.keepDrawn[recordStr] = (ok and manual and not on) or nil
    M.holsterTry[recordStr] = { n = 0, wait = HOLSTER_RETRY_TICKS }
    G.log(string.format("holster cmd %s on=%s manual=%s ok=%s", recordStr, tostring(on), tostring(manual), tostring(ok)))
    return ok
  end

  M.retreat = {}
  local RETREAT_RECOVER = 20.0

  local function lowHpTick(aliveByRec, inCombat, piloted)
    local limit = G.tuning.get("lowhp")
    for _, row in ipairs(aliveByRec) do
      if not row.model.static and not row.model.hijack and row.rec ~= piloted and not M.arena[row.rec] then
        local pct = 100.0
        pcall(function()
          pct = Game.GetStatPoolsSystem():GetStatPoolValue(row.ent:GetEntityID(), "Health", true)
        end)
        local was = M.retreat[row.rec]
        if not was and limit > 0 and inCombat and pct < limit and not M.passive[row.rec] then
          M.retreat[row.rec] = M.stanceOf(row.rec)
          if G.orders then pcall(G.orders.releaseOne, row) end
          M.setStance(row.rec, "passive")
          pcall(StatusEffectHelper.ApplyStatusEffect, row.ent, tdbid(G.TDB .. "RetreatSE"))
          G.notify(string.format(G.STR.lowhp_retreat, G.squad.displayName(row.rec, row.model)))
        elseif was and (limit <= 0 or not inCombat or pct >= limit + RETREAT_RECOVER) then
          M.retreat[row.rec] = nil
          pcall(StatusEffectHelper.RemoveStatusEffect, row.ent, tdbid(G.TDB .. "RetreatSE"))
          if M.passive[row.rec] then M.setStance(row.rec, was) end
        end
      end
    end
  end

  local PROTECT_GAP = 4.0
  M.protectAt = -1000.0

  local function protectTick(inCombat)
    if not G.settings.protectV or not inCombat then
      M.protectKey = nil
      return
    end
    local attacker
    pcall(function() attacker = Game.GetPlayer():DCLastAttacker() end)
    if not IsDefined(attacker) or isDown(attacker) then return end
    local key = entKey(attacker)
    local now = os.clock()
    if key == M.protectKey or now - M.protectAt < PROTECT_GAP then return end
    M.protectKey = key
    M.protectAt = now
    local n = M.focusAll(attacker)
    G.log(string.format("protect focus: attacker %s, %d drones", key, n))
    if n > 0 then G.notifyRare("protect", string.format(G.STR.protect_msg, n)) end
  end

  local RECON_EVERY = 2
  M.reconIn = 0

  local function reconTick(aliveByRec)
    if not G.settings.recon then return end
    M.reconIn = M.reconIn - 1
    if M.reconIn > 0 then return end
    M.reconIn = RECON_EVERY
    local range = G.tuning.get("recon")
    for _, row in ipairs(aliveByRec) do
      if not row.model.static then
        pcall(function()
          local dPos = row.ent:GetWorldPosition()
          for _, t in ipairs(row.ent:GetTargetTrackerComponent():GetHostileThreats(true)) do
            local e = t.entity
            if IsDefined(e) and not isDown(e) and Vector4.Distance(dPos, e:GetWorldPosition()) <= range then
              GameObject.TagObject(e)
            end
          end
        end)
      end
    end
  end

  local MEDIC_COOLDOWN = 60.0
  local MEDIC_HEAL = 30.0
  M.medicAt = -1000.0

  local function medicTick(aliveByRec, player)
    local limit = G.tuning.get("medic")
    if limit <= 0 or os.clock() - M.medicAt < MEDIC_COOLDOWN then return end
    local bombus
    for _, row in ipairs(aliveByRec) do
      if row.model.chassis == "Bombus" then
        bombus = row
        break
      end
    end
    if not bombus then return end
    pcall(function()
      local sps = Game.GetStatPoolsSystem()
      local id = player:GetEntityID()
      local pct = sps:GetStatPoolValue(id, gamedataStatPoolType.Health, true)
      if pct <= 0 or pct >= limit then return end
      M.medicAt = os.clock()
      sps:RequestSettingStatPoolValue(id, gamedataStatPoolType.Health, math.min(100.0, pct + MEDIC_HEAL), player)
      G.notify(string.format(G.STR.medic_msg, G.squad.displayName(bombus.rec, bombus.model)))
    end)
  end

  local function holsterBusy(rec)
    return (G.chauffeur and (G.chauffeur.busy[rec] or G.chauffeur.crew[rec]))
      or (G.loot and G.loot.busyFor(rec))
      or (G.orders and G.orders.moving[rec])
      or (G.hacks and G.hacks.held[rec])
  end

  local function reconcileHolster(row)
    if row.model.hijack or holsterBusy(row.rec) then return end
    local fighting = false
    pcall(function()
      fighting = row.ent:GetHighLevelStateFromBlackboard() == gamedataNPCHighLevelState.Combat
    end)
    if fighting then return end
    local want = not M.holstered[row.rec]
    local try = M.holsterTry[row.rec]
    if not try then
      try = { n = 0, wait = HOLSTER_RETRY_TICKS }
      M.holsterTry[row.rec] = try
    end
    try.wait = try.wait - 1
    if M.weaponDrawn(row.ent) == want then
      try.n = 0
      return
    end
    if try.wait > 0 or try.n >= HOLSTER_LOG_TRIES then return end
    try.n = try.n + 1
    try.wait = HOLSTER_RETRY_TICKS
    G.log(string.format("holster retry %s want drawn=%s try=%d", row.rec, tostring(want), try.n))
    sendHolster(row.ent, not want)
  end

  function M.androidHolsterState()
    local any, holstered = false, false
    M.eachActive(function(rec, _, model)
      if model.chassis == "Android" and not model.hijack then
        any = true
        if M.holstered[rec] then holstered = true end
      end
    end)
    return any, holstered
  end

  function M.holsterAll(on)
    local n = 0
    M.eachActive(function(rec, _, model)
      if model.chassis == "Android" and not model.hijack and M.setHolstered(rec, on, true) then n = n + 1 end
    end)
    return n
  end

  function M.toggleHolsterAll()
    local any, holstered = M.androidHolsterState()
    if not any then
      G.notify(G.STR.no_android)
      return
    end
    M.holsterAll(not holstered)
  end

  function M.setMuted(recordStr, mute)
    M.muted[recordStr] = mute or nil
    local list = spawnedAt(recordStr)
    if #list > 0 and IsDefined(list[1]) then
      local ok, err = pcall(pushMute, list[1], mute)
      if ok then
        M.muteApplied[recordStr] = mute
      else
        G.log("mute failed: " .. tostring(err))
      end
    end
  end

  local SPAWN_COLS = 3

  local function spawnPosition(player, model, countOverride)
    local pos = player:GetWorldPosition()
    local fwd = player:GetWorldForward()
    if G.settings.spawnBehind then
      fwd = { x = -fwd.x, y = -fwd.y }
    end

    local count = countOverride
    if not count then
      count = 0
      M.eachActive(function() count = count + 1 end)
    end
    local heavy = not model.fly and (model.chassis == "Minotaur" or model.chassis == "Chimera"
      or model.chassis == "Cerberus")
    local step = heavy and 4.5 or 2.0
    local row = math.floor(count / SPAWN_COLS)
    local lateral = (count % SPAWN_COLS - 1) * step

    local ahead = (model.fly and 5.0 or 4.0) + row * step
    local zUp = model.fly and 1.0 or 0.1

    local ok, err = pcall(function()
      local from = Vector4.new(pos.x, pos.y, pos.z + 1.5, 1.0)
      local to = Vector4.new(pos.x + fwd.x * ahead, pos.y + fwd.y * ahead, pos.z + zUp + 1.5, 1.0)

      local hit, trace = Game.GetSpatialQueriesSystem()
        :SyncRaycastByCollisionGroup(from, to, "Static", true, false)
      if hit and trace then
        local dx = trace.position.x - from.x
        local dy = trace.position.y - from.y
        local dz = trace.position.z - from.z
        local d = math.sqrt(dx * dx + dy * dy + dz * dz) - 1.5

        if d < ahead then
          ahead = math.max(2.0, d) - row * step
          if model.fly then zUp = 1.5 end
        end
      end
    end)
    if not ok then G.log("spawn raycast failed: " .. tostring(err)) end

    local v3 = Vector3.new()
    v3.x = pos.x + fwd.x * ahead + fwd.y * lateral
    v3.y = pos.y + fwd.y * ahead - fwd.x * lateral
    v3.z = pos.z + zUp
    return v3
  end

  function M.spawnAt(recordStr, pos)
    local cs = Game.GetCompanionSystem()

    M.spawnGen[recordStr] = (M.spawnGen[recordStr] or 0) + 1
    M.spawnTime[recordStr] = os.clock()
    local gen = M.spawnGen[recordStr]
    local function stale() return M.spawnGen[recordStr] ~= gen end

    cs:DespawnSubcharacter(tdbid(recordStr))
    if G.skins then G.skins.prepareRecord(recordStr) end
    local model = G.modelOf(recordStr)
    if model and model.chassis == "Android" and not model.hijack then
      G.records.applyLoadoutRec(model, recordStr, M.weaponOf[recordStr] or G.settings.loadout)
    end
    cs:SpawnSubcharacterOnPosition(tdbid(recordStr), pos)
    M.dismissing[recordStr] = nil
    M.deadPending[recordStr] = nil
    if M.stuckTicks then M.stuckTicks[recordStr] = 0 end
    if M.lastPos then M.lastPos[recordStr] = nil end
    M.muteApplied[recordStr] = nil
    G.log(string.format("spawn request %s at (%.1f, %.1f, %.1f)", recordStr, pos.x, pos.y, pos.z))
    Cron.After(1.0, function()
      if stale() then return end
      local list = spawnedAt(recordStr)
      if #list > 0 and IsDefined(list[1]) then
        M.applyCompanion(list[1], recordStr)
        G.skins.apply(list[1], recordStr)
      end
    end)

    Cron.After(4.0, function()
      if stale() then
        G.log("spawn aborted (dismissed while spawning): " .. recordStr)
        return
      end
      if M.isRegistered(recordStr) then
        G.log("spawn ok: " .. recordStr)
        M.logVerify(recordStr, 4)
        Cron.After(16.0, function()
          if not stale() then M.logVerify(recordStr, 20) end
        end)
        return
      end
      local retryPos = pos
      pcall(function()
        local p = Game.GetPlayer():GetWorldPosition()
        retryPos = Vector3.new(p.x, p.y, p.z)
      end)
      G.log(string.format("spawn slow, retrying %s next to the player (%.1f, %.1f, %.1f)",
        recordStr, retryPos.x, retryPos.y, retryPos.z))
      cs:SpawnSubcharacterOnPosition(tdbid(recordStr), retryPos)
      Cron.After(3.0, function()
        if stale() then return end
        if M.isRegistered(recordStr) then
          G.log("spawn ok (retry): " .. recordStr)
        else
          G.log("spawn FAILED: " .. recordStr .. " (nothing registered after retry)")
          G.notify(G.STR.spawn_failed)
        end
      end)
    end)
  end

  function M.respawnInPlace(recordStr)
    local ent = M.entityOf(recordStr)
    if not IsDefined(ent) then return false end
    local p = ent:GetWorldPosition()
    local pos = Vector3.new()
    pos.x, pos.y, pos.z = p.x, p.y, p.z
    local hp
    pcall(function()
      hp = Game.GetStatPoolsSystem():GetStatPoolValue(ent:GetEntityID(), gamedataStatPoolType.Health)
    end)
    G.log(string.format("respawn in place %s hp=%s", recordStr, tostring(hp)))
    M.spawnAt(recordStr, pos)
    if hp and hp > 0 then
      Cron.After(1.5, function()
        local ents = spawnedAt(recordStr)
        if #ents > 0 and IsDefined(ents[1]) then
          Game.GetStatPoolsSystem():RequestSettingStatPoolValue(
            ents[1]:GetEntityID(), gamedataStatPoolType.Health, hp, ents[1])
        end
      end)
    end
    return true
  end

  function M.hasGatekeeper()
    local n = 0
    pcall(function()
      n = Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(),
        ItemID.FromTDBID(tdbid(G.TDB .. "RiggerGatekeeper")))
    end)
    return n > 0
  end

  function M.ownsShard(fam)
    local owns = false
    pcall(function()
      owns = Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(),
        ItemID.FromTDBID(tdbid(G.shardId(fam)))) > 0
    end)
    return owns
  end

  local IMMORTAL_SOURCE = "DroneCompanion"

  function M.applyImmortal(ent, model)
    if not ent or not IsDefined(ent) or not model or model.hijack then return end
    local want = G.settings.dronesImmortal == true
    local ok, err = pcall(function()
      local gms = Game.GetGodModeSystem()
      local id = ent:GetEntityID()
      local src = CName.new(IMMORTAL_SOURCE)
      if want then
        if not gms:HasGodMode(id, gameGodModeType.Invulnerable) then
          gms:AddGodMode(id, gameGodModeType.Invulnerable, src)
        end
      else
        while gms:GetGodModeCount(id, gameGodModeType.Invulnerable) > 0
          and gms:RemoveGodMode(id, gameGodModeType.Invulnerable, src) do end
      end
    end)
    if not ok then G.log("immortal: " .. tostring(err)) end
  end

  function M.applyImmortalAll()
    M.eachActive(function(_, ent, model) M.applyImmortal(ent, model) end)
  end

  function M.pointsPool()
    local pool = G.POINTS_BASE
    pcall(function()
      pool = pool + Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(),
        ItemID.FromTDBID(tdbid(G.capacityId())))
    end)
    if G.perks then pool = math.max(1, pool - G.perks.titleRank()) end
    return pool
  end

  function M.pointsUsed()
    local used = 0
    M.eachActive(function(_, _, model)
      used = used + G.pointsOf(model.chassis)
    end)
    return used + G.arena.pointsUsed()
  end

  function M.trySummon(model, rec, slot, skipShard)
    local player = Game.GetPlayer()
    if not player then return nil end
    if G.settings.rigger and not M.hasGatekeeper() then
      G.notify(G.STR.rigger_required)
      return nil
    end
    if G.settings.immersive then
      local fam = model.chassis
      if fam and not skipShard and not M.ownsShard(fam) then
        G.notify(string.format(G.STR.shard_required, model.name))
        return nil
      end
      local cost = G.pointsOf(fam)
      local free = M.pointsPool() - M.pointsUsed()
      if cost > free then
        G.notify(string.format(G.STR.sp_needed, model.name, cost, free))
        return nil
      end
    end
    if model.escort then M.passive[rec] = true end
    if G.settings.spawnMuted then M.muted[rec] = true end
    M.spawnAt(rec, spawnPosition(player, model, slot))
    G.notify(string.format(G.STR.summoning, model.name))
    return rec
  end

  function M.canDeploy(fam)
    local ch = G.chassisOf(fam)
    if not ch then return false, "" end
    if G.settings.rigger and not M.hasGatekeeper() then
      return false, G.STR.rigger_required
    end
    if G.settings.immersive then
      local cost = G.pointsOf(fam)
      local free = M.pointsPool() - M.pointsUsed()
      if cost > free then
        return false, string.format(G.STR.sp_needed, ch.name, cost, free)
      end
    end
    return true
  end

  function M.summon(modelIndex, skipShard, weaponKey)
    local model = G.MODELS[modelIndex]
    if not model or G.settings.enabled == false then return nil end
    for i = 1, G.tuning.get("instances") do
      local rec = G.recordId(model, i)
      if #spawnedAt(rec) == 0 and not G.arena.busy(rec) then
        if G.settings.skins[rec] ~= nil then
          G.settings.skins[rec] = nil
          G.saveSettings()
        end
        M.weaponOf[rec] = weaponKey
        M.holstered[rec] = nil
        M.keepDrawn[rec] = nil
        if G.menu and G.menu.forgetPicks then G.menu.forgetPicks(rec) end
        return M.trySummon(model, rec, nil, skipShard)
      end
    end
    G.notify(string.format(G.STR.all_deployed, model.name))
    return nil
  end

  function M.adoptHijacked(puppet, rec)
    M.spawnGen[rec] = (M.spawnGen[rec] or 0) + 1
    M.spawnTime[rec] = os.clock()
    M.passive[rec] = nil
    M.defensive[rec] = nil
    M.arena[rec] = nil
    M.lit[rec] = nil
    M.muted[rec] = nil
    M.deadPending[rec] = nil
    M.dismissing[rec] = nil
    M.applyCompanion(puppet, rec)
  end

  local function forgetHijacked(rec)
    if G.hacks then G.hacks.held[rec] = nil end
    dropMappin(rec)
    M.facePos[rec] = nil
    M.faceHeld[rec] = nil
    M.faceTries[rec] = nil
    M.lastTarget[rec] = nil
    M.targetEnt[rec] = nil
    M.passive[rec] = nil
    M.defensive[rec] = nil
    M.arena[rec] = nil
    M.lit[rec] = nil
    M.muted[rec] = nil
    M.weaponOf[rec] = nil
    M.holstered[rec] = nil
    M.keepDrawn[rec] = nil
    M.spawnGen[rec] = (M.spawnGen[rec] or 0) + 1
  end
  M.forgetHijacked = forgetHijacked

  function M.dismiss(recordStr, internal)
    if G.hijack and G.hijack.is(recordStr) then
      G.hijack.releaseOne(recordStr)
      return
    end
    if not internal and M.cancelRestore then M.cancelRestore() end
    M.wreckUntil[recordStr] = nil
    dropWreckMappin(recordStr)
    if G.arena and G.arena.busy(recordStr) then G.arena.leave(recordStr, "dismiss") end
    if G.hacks then G.hacks.held[recordStr] = nil end
    M.dismissing[recordStr] = true
    dropMappin(recordStr)
    M.facePos[recordStr] = nil
    M.faceHeld[recordStr] = nil
    M.faceTries[recordStr] = nil
    if M.andGrace then M.andGrace[recordStr] = nil end
    if G.chauffeur then G.chauffeur.forget(recordStr) end
    if G.netrunner then G.netrunner.forget(recordStr) end
    M.weaponOf[recordStr] = nil
    M.holstered[recordStr] = nil
    M.keepDrawn[recordStr] = nil
    M.spawnGen[recordStr] = (M.spawnGen[recordStr] or 0) + 1
    local gen = M.spawnGen[recordStr]
    local function superseded() return M.spawnGen[recordStr] ~= gen end
    local ent
    local list = spawnedAt(recordStr)
    if #list > 0 and IsDefined(list[1]) then ent = list[1] end

    local delay = 0.0
    if ent then
      local silent = G.settings.spawnMuted or M.muted[recordStr]
      if not silent and netlinkRecall(ent) then
        delay = NETLINK_DELAY
      end
      pcall(function() pushMute(ent, true) end)
    end

    Cron.After(delay, function()
      if superseded() then return end
      if ent and IsDefined(ent) then
        local p = ent:GetWorldPosition()
        teleportTo(ent, p.x, p.y, p.z - 300.0)
      end
      Cron.After(ent and 0.15 or 0.0, function()
        if superseded() then return end
        Game.GetCompanionSystem():DespawnSubcharacter(tdbid(recordStr))
        dropMappin(recordStr)
      end)
    end)

  end

  function M.dismissAll(silent)
    if M.cancelRestore then M.cancelRestore() end
    if G.arena then G.arena.abort(false) end
    M.garage = nil
    for _, model in ipairs(G.MODELS) do
      for i = 1, G.INSTANCES do
        M.dismiss(G.recordId(model, i), true)
      end
    end
    if G.hijack then G.hijack.releaseAll() end
    if not silent then G.notify(G.STR.dismissed) end
  end

  function M.hasActive()
    local found = false
    M.eachActive(function() found = true end)
    return found or G.arena.fighting()
  end

  function M.captureState()
    local list = {}
    M.eachActive(function(rec, ent, model)
      if not isDown(ent) and not model.hijack then
        table.insert(list, M.captureOne(rec, true))
      end
    end)
    for _, saved in ipairs(G.arena.captured()) do table.insert(list, saved) end
    return list
  end

  function M.captureAll()
    local list = M.captureState()
    for _, saved in ipairs(M.stashed or {}) do
      table.insert(list, saved)
    end
    for _, saved in ipairs(M.garage or {}) do
      table.insert(list, saved)
    end
    return list
  end

  function M.respawn(list, slotBase)
    local player = Game.GetPlayer()
    if not player or not list then return end
    for idx, saved in ipairs(list) do
      local model
      for _, m in ipairs(G.MODELS) do
        if saved.record:find(m.key, 1, true) then model = m break end
      end
      if model then
        M.muted[saved.record] = saved.muted or nil
        M.passive[saved.record] = saved.passive or nil
        M.defensive[saved.record] = saved.defensive or nil
        M.weaponOf[saved.record] = saved.weapon or nil
        M.lit[saved.record] = saved.lit or nil
        M.holstered[saved.record] = saved.holstered or nil
        M.keepDrawn[saved.record] = saved.keepDrawn or nil
        M.spawnAt(saved.record, spawnPosition(player, model, (slotBase or 0) + idx - 1))
        local hp = saved.hp
        if hp and hp > 0 then
          Cron.After(1.5, function()
            local ents = spawnedAt(saved.record)
            if #ents > 0 and IsDefined(ents[1]) then
              Game.GetStatPoolsSystem():RequestSettingStatPoolValue(
                ents[1]:GetEntityID(), gamedataStatPoolType.Health, hp, ents[1])
            end
          end)
        end
      end
    end
  end

  local function sceneTier()
    local tier = 0
    pcall(function()
      local defs = Game.GetAllBlackboardDefs()
      local bb = Game.GetBlackboardSystem():GetLocalInstanced(
        Game.GetPlayer():GetEntityID(), defs.PlayerStateMachine)
      tier = bb:GetInt(defs.PlayerStateMachine.SceneTier)
    end)
    return tier
  end


  local LIFT_SPREAD = 1.0
  local LIFT_LEAD = 30.0
  local LIFT_NEAR = 6.0

  function M.elevatorTick()
    local player = Game.GetPlayer()
    if not player then return end

    local viaDevice, deviceOk = false, true
    if not pcall(function() viaDevice = LiftDevice.IsPlayerInsideElevator() end) then
      deviceOk = false
    end

    local lift
    if viaDevice or not deviceOk then
      pcall(function()
        local defs = Game.GetAllBlackboardDefs()
        local bb = Game.GetBlackboardSystem():GetLocalInstanced(
          player:GetEntityID(), defs.PlayerStateMachine)
        lift = FromVariant(bb:GetVariant(defs.PlayerStateMachine.CurrentElevator))
      end)
    end

    local inLift = false
    if IsDefined(lift) then
      if deviceOk then
        inLift = viaDevice
      else
        local p, l = player:GetWorldPosition(), lift:GetWorldPosition()
        inLift = math.sqrt((p.x - l.x) ^ 2 + (p.y - l.y) ^ 2) <= LIFT_NEAR
      end
    end

    if not inLift then
      if M.liftZ then
        M.liftZ = nil
        if M.aliveCache then
          local p = player:GetWorldPosition()
          for _, row in ipairs(M.aliveCache) do
            if IsDefined(row.ent) then teleportTo(row.ent, p.x, p.y, p.z) end
          end
        end
      end
      return
    end

    if not M.aliveCache or #M.aliveCache == 0 then return end
    if sceneTier() > 1 then return end

    local pPos = player:GetWorldPosition()
    local lPos = lift:GetWorldPosition()

    local z = pPos.z
    if M.liftZ then z = z + (pPos.z - M.liftZ) * LIFT_LEAD end
    M.liftZ = pPos.z

    local idx = 0
    for _, row in ipairs(M.aliveCache) do
      if IsDefined(row.ent) and famOf(row.rec) ~= "minotaur" then
        teleportTo(row.ent, lPos.x + idx * LIFT_SPREAD, lPos.y, z)
        idx = idx + 1
      end
    end
  end

  function M.watchdogTick()
    local player = Game.GetPlayer()
    if not player or not G.GameSession.IsLoaded() then return end

    local shards = G.tuning.upCount("UpCombat") * 100
      + G.tuning.upCount("UpSupport") * 10 + G.tuning.upCount("UpUtility")
    local stockSig = G.records.stockSignature() .. shards
    if stockSig ~= M.lastStockSig then
      M.lastStockSig = stockSig
      G.records.refreshStocks()
      G.hacks.applyCooldowns()
    end

    local interior = false
    pcall(function() interior = IsEntityInInteriorArea(player) end)
    if interior ~= M.wasInterior then
      M.wasInterior = interior
      local range = Vector2.new()
      range.X = -1
      range.Y = interior and (G.perks.value("bond") or 0) or 100
      TweakDB:SetFlat(G.TDB .. "FollowerBelow100m.distance", range)
    end

    local mounted = Game.GetMountedVehicle(player) ~= nil
    local hidden = sceneTier() > 2
    if hidden then
      if not M.stashed then
        local state = M.captureState()
        if #state > 0 then
          M.stashed = state
          local park = M.garage
          M.dismissAll(true)
          M.garage = park
        end
      end
      return
    end
    if M.stashed then
      local state = M.stashed
      M.stashed = nil
      M.respawn(state)
      return
    end

    if mounted and not M.garage then
      local park = {}
      for _, saved in ipairs(M.captureState()) do
        local model = G.modelOf(saved.record)
        if model and not model.fly and model.chassis ~= "Android" then
          table.insert(park, saved)
        end
      end
      if #park > 0 then
        M.garage = park
        for _, saved in ipairs(park) do
          M.dismiss(saved.record, true)
        end
      end
    elseif not mounted and M.garage then
      local park = M.garage
      M.garage = nil
      M.respawn(park)
    end

    if M.wasMounted and not mounted then
      local pNow = player:GetWorldPosition()
      for i, row in ipairs(M.aliveCache or {}) do
        if row.model.fly and IsDefined(row.ent) and not isDown(row.ent) then
          local far = false
          pcall(function()
            far = Vector4.Distance(pNow, row.ent:GetWorldPosition()) > 50.0
          end)
          if far then
            local side = (i % 2 == 0) and 1 or -1
            teleportTo(row.ent, pNow.x + side * 3.0, pNow.y + 2.0, pNow.z + 4.0)
          end
        end
      end
    end
    M.wasMounted = mounted

    local alive = {}
    local aliveByRec = {}
    M.eachActive(function(rec, ent, model)
      if isDown(ent) then
        dropMappin(rec)
        if model.hijack then
          G.log("hijack down " .. rec .. ": " .. downReason(ent))
          G.hijack.lost(rec)
        elseif mounted and model.fly and not M.deadPending[rec] then
          M.deadPending[rec] = true
          G.log("vehicle: flying drone downed while driving, rebooting " .. rec)
          local saved = M.captureOne(rec)
          M.dismiss(rec, true)
          Cron.After(1.0, function() M.respawn({ saved }) end)
        elseif not M.deadPending[rec] and not M.dismissing[rec] then
          M.deadPending[rec] = true
          G.squad.onDeath(rec)
          M.wreckUntil[rec] = os.clock() + REPAIR_WINDOW
          markWreck(rec, ent, model)
          G.notify(string.format(G.STR.drone_destroyed_repair, model.name, REPAIR_WINDOW))
          G.log(string.format("wreck %s: repair window %ds, cost %d", rec, REPAIR_WINDOW, M.repairCost(model)))

          local gen = M.spawnGen[rec]
          Cron.After(REPAIR_WINDOW, function()
            if M.deadPending[rec] and M.spawnGen[rec] == gen then
              G.log("wreck expired: " .. rec)
              M.dismiss(rec, true)
            end
          end)
        end
      else
        M.applyCompanion(ent, rec)
        if not M.muted[rec] and M.muteApplied[rec] then
          if pcall(pushMute, ent, false) then M.muteApplied[rec] = false end
        end
        table.insert(alive, ent)
        table.insert(aliveByRec, { rec = rec, ent = ent, model = model })
      end
    end)

    M.aliveCache = aliveByRec

    local seCombat = tdbid(G.TDB .. "InCombatSE")
    local inCombat = player:IsInCombat()
    if G.squad then G.squad.autoSummonTick(inCombat, mounted) end
    local piloted = G.dronecam and G.dronecam.active
    pcall(G.orders.keepAnchors, aliveByRec, inCombat, piloted)
    for _, row in ipairs(aliveByRec) do
      if row.rec ~= piloted then
        pcall(function()
          if inCombat and not M.passive[row.rec] then
            StatusEffectHelper.ApplyStatusEffect(row.ent, seCombat)
          else
            StatusEffectHelper.RemoveStatusEffect(row.ent, seCombat)
          end
        end)
      end
    end

    for _, row in ipairs(aliveByRec) do
      if row.model.chassis == "Android" then
        local drawn = M.weaponDrawn(row.ent)
        if drawn ~= M.drawnSeen[row.rec] then
          M.drawnSeen[row.rec] = drawn
          G.log(string.format("weapon drawn=%s %s combat=%s holstered=%s keep=%s passive=%s", tostring(drawn), row.rec,
            tostring(inCombat), tostring(M.holstered[row.rec]), tostring(M.keepDrawn[row.rec]), tostring(M.passive[row.rec])))
        end
      end
    end

    M.calmTicks = inCombat and 0 or M.calmTicks + 1
    if G.settings.autoHolster and not inCombat and M.calmTicks >= AUTO_HOLSTER_TICKS then
      for _, row in ipairs(aliveByRec) do
        if row.model.chassis == "Android" and row.rec ~= piloted and not row.model.hijack
          and not M.holstered[row.rec] and not M.keepDrawn[row.rec] then
          M.setHolstered(row.rec, true)
        end
      end
    end
    if not inCombat and not mounted then
      for _, row in ipairs(aliveByRec) do
        if row.model.chassis == "Android" and row.rec ~= piloted then reconcileHolster(row) end
      end
    end
    lowHpTick(aliveByRec, inCombat, piloted)
    protectTick(inCombat)
    reconTick(aliveByRec)
    medicTick(aliveByRec, player)

    local threats = {}
    pcall(function()
      for _, t in ipairs(player:GetTargetTrackerComponent():GetHostileThreats(false)) do
        if not isDown(t.entity) and not G.arena.isFighterEnt(t.entity) then table.insert(threats, t.entity) end
      end
    end)

    M.nudgeIn = (M.nudgeIn or 0) - 1
    local refresh = M.nudgeIn <= 0
    if refresh then M.nudgeIn = 2 end
    for rec in pairs(M.arena) do
      if not G.arena.busy(rec) and not M.dismissing[rec] then
        local present = false
        for _, row in ipairs(aliveByRec) do
          if row.rec == rec then present = true end
        end
        if not present then M.setStance(rec, "combat") end
      end
    end
    G.arena.tick(aliveByRec, player)

    if #threats > 0 then
      for _, row in ipairs(aliveByRec) do
        if not M.passive[row.rec] and not row.model.static
          and (inCombat or not M.defensive[row.rec]) then
          pcall(function()
            local from = row.ent:GetWorldPosition()
            local best, bestDist
            for _, ent in ipairs(threats) do
              local d = Vector4.Distance(from, ent:GetWorldPosition())
              if not bestDist or d < bestDist then best, bestDist = ent, d end
            end

            local held = M.targetEnt[row.rec]
            if not isDown(held) then
              local heldDist = Vector4.Distance(from, held:GetWorldPosition())
              if heldDist <= TARGET_DROP and bestDist > heldDist * TARGET_SWAP then
                best, bestDist = held, heldDist
              end
            end

            if best then
              local id = entKey(best)
              local changed = M.lastTarget[row.rec] ~= id
              if refresh or changed then
                TargetTrackingExtension.InjectThreat(row.ent, best)
              end
              if changed then
                M.lastTarget[row.rec] = id
                M.targetEnt[row.rec] = best
              end
            end
          end)
        end
      end
    end

    local pPosLeash = player:GetWorldPosition()
    local leash = G.tuning.get("leash")
    local now = os.clock()
    for i, row in ipairs(aliveByRec) do
      local settled = (now - (M.spawnTime[row.rec] or 0)) > LEASH_GRACE
      local held = G.hacks and G.hacks.held[row.rec]
      local ordered = G.orders and G.orders.moving[row.rec]
      if IsDefined(row.ent) and settled and not held and not ordered
        and not mounted and not G.chauffeur.crew[row.rec]
        and (row.model.static or inCombat) then
        local d = Vector4.Distance(pPosLeash, row.ent:GetWorldPosition())
        if d > LEASH_MAX then
          M.leashSkipped = row.rec
        elseif d > leash then
          local side = (i % 2 == 0) and 1 or -1
          local off = side * (1.5 + math.ceil(i / 2) * 2.0)
          local fighting = false
          pcall(function()
            fighting = row.ent:GetHighLevelStateFromBlackboard() == gamedataNPCHighLevelState.Combat
          end)
          if not fighting then
            teleportTo(row.ent, pPosLeash.x + off, pPosLeash.y + off, pPosLeash.z)
          end
        end
      end
    end

    local wantFacing = G.settings.matchFacing and not mounted and not inCombat
    local pMoved = true
    if wantFacing then
      local pPos = player:GetWorldPosition()
      if M.playerFacePos then
        local dx, dy = pPos.x - M.playerFacePos.x, pPos.y - M.playerFacePos.y
        pMoved = dx * dx + dy * dy > 0.25
      end
      M.playerFacePos = { x = pPos.x, y = pPos.y }
    else
      M.playerFacePos = nil
    end
    if next(M.faceHeld) and (not wantFacing or pMoved) then
      for _, row in ipairs(aliveByRec) do
        if M.faceHeld[row.rec] then
          pcall(function()
            G.hacks.clearHold(row.rec, row.ent)
            if inCombat then return end
            local follow = AIFollowTargetCommand.new()
            follow.target = player
            follow.desiredDistance = 6.0
            follow.teleport = true
            AIComponent.SendCommand(row.ent, follow)
          end)
        end
      end
      M.faceHeld = {}
      M.faceTries = {}
    end
    if wantFacing and not pMoved then
      local pYaw = player:GetWorldYaw()
      local yawStable = true
      if M.playerFaceYaw then
        local yd = (pYaw - M.playerFaceYaw + 180.0) % 360.0 - 180.0
        if math.abs(yd) > 20.0 then
          M.faceTries = {}
          yawStable = false
        end
      end
      M.playerFaceYaw = pYaw
      for _, row in ipairs(aliveByRec) do
        local rec = row.rec
        if yawStable and not row.model.static and not row.model.fly
          and rec ~= piloted
          and not (G.hacks and G.hacks.held[rec] and not M.faceHeld[rec])
          and not (G.orders and G.orders.moving[rec])
          and not (G.loot and G.loot.busyFor(rec)) then
          pcall(function()
            if (os.clock() - (M.spawnTime[rec] or 0)) < 10.0 then return end
            if row.ent:GetHighLevelStateFromBlackboard() == gamedataNPCHighLevelState.Combat then return end
            local p = row.ent:GetWorldPosition()
            local last = M.facePos[rec]
            M.facePos[rec] = { x = p.x, y = p.y }
            if not last then return end
            local dx, dy = p.x - last.x, p.y - last.y
            if dx * dx + dy * dy > 0.25 then return end
            local diff = (row.ent:GetWorldYaw() - pYaw + 180.0) % 360.0 - 180.0
            local snapped = false
            if math.abs(diff) >= 25.0 then
              local tries = M.faceTries[rec] or 0
              if tries >= 4 then return end
              M.faceTries[rec] = tries + 1
              local cmd = NewObject("handle:AITeleportCommand")
              cmd.position = Vector4.new(p.x, p.y, p.z, 1.0)
              cmd.rotation = pYaw
              cmd.doNavTest = false
              row.ent:GetAIControllerComponent():SendCommand(cmd)
              snapped = true
              G.log(string.format("facing: %s try=%d diff=%.0f snap+hold", rec,
                tries + 1, diff))
            elseif M.faceHeld[rec] then
              return
            end
            M.faceHeld[rec] = true
            local gen = M.spawnGen[rec]
            Cron.After(snapped and 0.15 or 0.0, function()
              if M.faceHeld[rec] and M.spawnGen[rec] == gen
                and IsDefined(row.ent) and not isDown(row.ent) then
                G.hacks.setHold(rec, row.ent, true)
              end
            end)
          end)
        end
      end
    else
      M.playerFaceYaw = nil
    end

    for _, row in ipairs(aliveByRec) do
      if G.settings.minimap and not M.dismissing[row.rec] then
        attachMappin(row.rec, row.ent)
      else
        dropMappin(row.rec)
      end
    end

    G.abilities.passiveTick(aliveByRec, inCombat, M.passive, threats)
    G.abilities.tick(aliveByRec, player, inCombat, M.passive)

    if inCombat then
      M.regenDelay = G.perks.value("quickfix") or 3
    elseif M.regenDelay > 0 then
      M.regenDelay = M.regenDelay - 1
    else
      local sps = Game.GetStatPoolsSystem()
      for _, ent in ipairs(alive) do
        pcall(function()
          local id = ent:GetEntityID()
          local pct = sps:GetStatPoolValue(id, gamedataStatPoolType.Health)
          if pct > 0 and pct < 100.0 then
            sps:RequestSettingStatPoolValue(id, gamedataStatPoolType.Health,
              math.min(100.0, pct + (G.perks.value("repair") or 2.0)), ent)
          end
        end)
      end
    end

    local pGroup = CName.new("player")
    for i, ent in ipairs(alive) do
      pcall(function()
        local agent = ent:GetAttitudeAgent()
        if tostring(agent:GetAttitudeGroup()) ~= tostring(pGroup) then
          agent:SetAttitudeGroup(pGroup)
        end
        if GameObject.GetAttitudeTowards(ent, player) ~= EAIAttitude.AIA_Friendly then
          agent:SetAttitudeTowards(player:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
        end
        for j = i + 1, #alive do
          if GameObject.GetAttitudeTowards(ent, alive[j]) ~= EAIAttitude.AIA_Friendly then
            agent:SetAttitudeTowards(alive[j]:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
          end
        end
      end)
    end

    M.lastPos = M.lastPos or {}
    M.stuckTicks = M.stuckTicks or {}
    if not inCombat and not mounted then
      local pPos = player:GetWorldPosition()
      for _, row in ipairs(aliveByRec) do
        local anchored = M.arena[row.rec]
          or row.model.hijack
          or G.chauffeur.crew[row.rec]
          or (G.hacks and G.hacks.held[row.rec])
          or (G.orders and G.orders.moving[row.rec])
          or (G.dronecam and G.dronecam.active == row.rec)
          or (now - (M.spawnTime[row.rec] or 0)) <= LEASH_GRACE
        if anchored then
          M.stuckTicks[row.rec] = 0
          M.lastPos[row.rec] = nil
        else
        pcall(function()
          local dPos = row.ent:GetWorldPosition()
          local last = M.lastPos[row.rec]
          M.lastPos[row.rec] = { x = dPos.x, y = dPos.y, z = dPos.z }
          local moved = not last or (math.abs(dPos.x - last.x) + math.abs(dPos.y - last.y)
            + math.abs(dPos.z - last.z)) > 0.5

          if moved then M.rescueTries[row.rec] = nil end

          local stranded = false
          if not moved and Vector4.Distance(pPos, dPos) > RESCUE_DIST then
            stranded = IsEntityInInteriorArea(row.ent) ~= interior
          end
          M.stuckTicks[row.rec] = stranded and (M.stuckTicks[row.rec] or 0) + 1 or 0
          local need = math.max(RESCUE_MIN_TICKS, G.perks.value("rescue") or 4)
          local cooling = now - (M.rescueAt[row.rec] or 0) < RESCUE_COOLDOWN
          local tries = M.rescueTries[row.rec] or 0
          if M.stuckTicks[row.rec] >= need and not cooling and tries < RESCUE_TRIES then
            M.stuckTicks[row.rec] = 0
            M.rescueAt[row.rec] = now
            M.rescueTries[row.rec] = tries + 1
            G.log(string.format("rescue respawn (stuck behind geometry): %s try %d/%d dist %.1f",
              row.rec, tries + 1, RESCUE_TRIES, Vector4.Distance(pPos, dPos)))
            local saved = M.captureOne(row.rec, true)
            M.dismiss(row.rec, true)

            M.rescueSlot = ((M.rescueSlot or 0) + 1) % 6
            local slot = M.rescueSlot
            Cron.After(1.0, function() M.respawn({ saved }, slot) end)
          end
        end)
        end
      end
    end
  end

  local VEH_NEAR = 25.0
  local VEH_HARD = 70.0
  local VEH_LEAD = 0.6
  local ANDROID_GRACE_TICKS = 12

  local function captureOne(rec, withHp)
    local saved = {
      record = rec,
      muted = M.muted[rec] or nil,
      passive = M.passive[rec] or nil,
      defensive = M.defensive[rec] or nil,
      weapon = M.weaponOf[rec] or nil,
      lit = M.lit[rec] or nil,
      holstered = M.holstered[rec] or nil,
      keepDrawn = M.keepDrawn[rec] or nil,
    }
    if withHp then
      local ent = M.entityOf(rec)
      if IsDefined(ent) then
        pcall(function()
          saved.hp = Game.GetStatPoolsSystem():GetStatPoolValue(ent:GetEntityID(), gamedataStatPoolType.Health)
        end)
      end
    end
    return saved
  end
  M.captureOne = captureOne

  function M.swapOut(rec)
    local ent = M.entityOf(rec)
    if not IsDefined(ent) then return nil end
    local snap = { saved = captureOne(rec), hp = 100.0 }
    pcall(function()
      snap.hp = Game.GetStatPoolsSystem():GetStatPoolValue(ent:GetEntityID(), gamedataStatPoolType.Health, true)
    end)
    pcall(function()
      local p = ent:GetWorldPosition()
      snap.pos = Vector4.new(p.x, p.y, p.z, 1.0)
      snap.orient = ent:GetWorldOrientation()
      local app = ent:GetCurrentAppearanceName()
      if app ~= nil then snap.app = app end
    end)
    if not snap.pos then return nil end
    M.spawnGen[rec] = (M.spawnGen[rec] or 0) + 1
    M.dismissing[rec] = true
    dropMappin(rec)
    if G.hacks then G.hacks.held[rec] = nil end
    if G.netrunner then G.netrunner.forget(rec) end
    M.lastTarget[rec] = nil
    M.targetEnt[rec] = nil
    Game.GetCompanionSystem():DespawnSubcharacter(tdbid(rec))
    G.log(string.format("swap out %s hp=%.0f", rec, snap.hp))
    return snap
  end

  function M.swapIn(rec, pos, hp)
    local v3 = Vector3.new()
    v3.x, v3.y, v3.z = pos.x, pos.y, pos.z
    M.spawnAt(rec, v3)
    if not hp or hp <= 0 then return end
    local gen = M.spawnGen[rec]
    Cron.After(1.5, function()
      if M.spawnGen[rec] ~= gen then return end
      local ents = spawnedAt(rec)
      if #ents > 0 and IsDefined(ents[1]) then
        Game.GetStatPoolsSystem():RequestSettingStatPoolValue(
          ents[1]:GetEntityID(), gamedataStatPoolType.Health, hp, ents[1])
      end
    end)
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

  function M.vehicleTick()
    local player = Game.GetPlayer()
    if not player then
      M.vehPrev = nil
      return
    end
    local veh = Game.GetMountedVehicle(player)
    if not veh or not M.aliveCache then
      M.vehPrev = nil
      M.andGrace = nil
      G.chauffeur.passengerTick(nil)
      return
    end
    pcall(function()
      local vPos = veh:GetWorldPosition()
      local vel = { x = 0.0, y = 0.0 }
      if M.vehPrev then
        vel.x = (vPos.x - M.vehPrev.x) * 2.0
        vel.y = (vPos.y - M.vehPrev.y) * 2.0
      end
      M.vehPrev = { x = vPos.x, y = vPos.y }
      M.andGrace = M.andGrace or {}
      G.chauffeur.fixSeats(veh)
      G.chauffeur.passengerTick(veh)
      local idx = 0
      for _, row in ipairs(M.aliveCache) do
        if not IsDefined(row.ent) or isDown(row.ent) then
        elseif row.model.fly then
          idx = idx + 1
          local d = Vector4.Distance(vPos, row.ent:GetWorldPosition())
          local side = (idx % 2 == 0) and 1 or -1
          local fighting = false
          pcall(function()
            fighting = row.ent:GetHighLevelStateFromBlackboard() == gamedataNPCHighLevelState.Combat
          end)
          if fighting then
          elseif d > VEH_HARD then
            teleportTo(row.ent,
              vPos.x + vel.x * VEH_LEAD + side * 4.0,
              vPos.y + vel.y * VEH_LEAD,
              vPos.z + 5.0 + (idx % 3) * 1.5)
          elseif d > VEH_NEAR then
            teleportTo(row.ent,
              vPos.x + vel.x * VEH_LEAD + side * 3.0,
              vPos.y + vel.y * VEH_LEAD,
              vPos.z + 5.0 + (idx % 3) * 1.5)
          end
        elseif row.model.chassis == "Android" and not row.model.hijack then
          if G.chauffeur.crew[row.rec] then
            M.andGrace[row.rec] = nil
          elseif isSeated(row.ent) then
            M.andGrace[row.rec] = nil
          else
            G.chauffeur.autoSeat(row.rec, row.ent, veh)
            M.andGrace[row.rec] = (M.andGrace[row.rec] or 0) + 1
            if M.andGrace[row.rec] >= ANDROID_GRACE_TICKS then
              M.andGrace[row.rec] = nil
              M.garage = M.garage or {}
              table.insert(M.garage, captureOne(row.rec, true))
              M.dismiss(row.rec, true)
              G.log("vehicle: android has no seat, parked " .. row.rec)
            end
          end
        end
      end
    end)
  end

  function M.muteTick()
    if not next(M.muted) or not M.aliveCache then return end
    for _, row in ipairs(M.aliveCache) do
      if M.muted[row.rec] and IsDefined(row.ent) and not row.ent:IsDead() then
        pcall(pushMute, row.ent, true)
        M.muteApplied[row.rec] = true
      end
    end
  end

  function M.muteFrame()
    if not next(M.muted) or not M.aliveCache then return end
    for _, row in ipairs(M.aliveCache) do
      if M.muted[row.rec] and IsDefined(row.ent) and not row.ent:IsDead() then
        local fam = famOf(row.rec)
        pcall(function()
          ensureSoundTables()
          local fams = fam and { fam } or { "octant", "wyvern", "griffin" }
          for _, f in ipairs(fams) do
            for _, n in ipairs(MOVE_STOP[f]) do GameObject.StopSoundEvent(row.ent, n) end
          end
          stopTagged(row.ent)
        end)
      end
    end
  end

  local markerId, arenaId = nil, nil
  local function isOurs(obj)
    if markerId == nil then markerId, arenaId = tdbid(SE_MARKER), tdbid(SE_ARENA) end
    if obj == nil or obj.GetEntityID == nil then return false end
    local ses = Game.GetStatusEffectSystem()
    local id = obj:GetEntityID()
    return ses:HasStatusEffect(id, markerId) or ses:HasStatusEffect(id, arenaId)
  end

  function M.installHooks()
    Override("PreventionSystem", "ChangeAttitude", function(self, owner, target, desiredAttitude, wrapped)
      if isOurs(owner) and IsDefined(target) and target.IsPlayer and target:IsPlayer() then
        return
      end
      wrapped(owner, target, desiredAttitude)
    end)

    Override("AISubActionShootWithWeapon_Record_Implementation",
      "ShouldTrackTarget;gamePuppetAISubActionShootWithWeapon_RecordWeaponObject",
      function(owner, record, weapon, wrapped)
        if IsDefined(owner) and isOurs(owner) then
          if owner.GetNPCType and owner:GetNPCType() == gamedataNPCType.Mech then
            return true
          end
          return math.random(100) <= 70
        end
        return wrapped(owner, record, weapon)
      end)
  end

  return M
end
