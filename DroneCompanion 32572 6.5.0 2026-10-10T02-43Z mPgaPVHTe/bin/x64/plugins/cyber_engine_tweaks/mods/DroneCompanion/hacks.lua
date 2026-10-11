return function(G)
  local Cron = G.Cron
  local M = { held = {}, ready = false }

  local PREFIX = G.TDB .. "Hack"

  local HACKS = {
    { key = "Repair",   str = "hk_repair",   cost = 6, upload = 2.0, cd = 45,
      icon = "regeneration_icon",  caption = "ChoiceCaptionParts.Techie" },
    { key = "Hold",     str = "hk_hold",     cost = 1, upload = 0.5, cd = 0,
      icon = "wounded_disabled_icon", caption = "ChoiceCaptionParts.BackOutIcon" },
    { key = "Dismiss",  str = "hk_dismiss",  cost = 1, upload = 0.5, cd = 5,
      icon = "",                   caption = "ChoiceCaptionParts.LockedIcon" },
    { key = "Detonate", str = "hk_detonate", cost = 4, upload = 1.0, cd = 30,
      icon = "",                   caption = "ChoiceCaptionParts.GrenadeExplodeIcon" },
    { key = "Overclock", str = "hk_overclock", cost = 5, upload = 1.5, cd = 60,
      icon = "",                   caption = "ChoiceCaptionParts.HuntForPsychoIcon",
      buff = { stat = "NPCDamage", mult = 1.4, dur = 20 } },
    { key = "Fortify",  str = "hk_fortify",  cost = 5, upload = 1.5, cd = 60,
      icon = "",                   caption = "ChoiceCaptionParts.GlitchScreenBlindIcon",
      buff = { stat = "Armor", mult = 1.5, dur = 20 } },
    { key = "Zoom",     str = "hk_zoom",     cost = 4, upload = 1.0, cd = 60,
      icon = "",                   caption = "ChoiceCaptionParts.CameraTagSeenEnemiesIcon",
      buff = { stat = "Accuracy", add = 20, dur = 30 } },
    { key = "Cloak",    str = "hk_cloak",    cost = 5, upload = 1.5, cd = 90, mark = 20,
      icon = "",                   caption = "ChoiceCaptionParts.OpticalCamoIcon",
      buff = { stat = "Visibility", mult = 0.1, dur = 20 } },

    { key = "Octant",   str = "ab_octant",   fam = "octant",   cost = 3, upload = 1.0, cd = 25,
      icon = "second_wind",        caption = "ChoiceCaptionParts.GlitchScreenBlindIcon" },
    { key = "Wyvern",   str = "ab_wyvern",   fam = "wyvern",   cost = 3, upload = 1.0, cd = 30,
      icon = "",                   caption = "ChoiceCaptionParts.CameraTagSeenEnemiesIcon" },
    { key = "Griffin",  str = "ab_griffin",  fam = "griffin",  cost = 4, upload = 1.0, cd = 30,
      icon = "",                   caption = "ChoiceCaptionParts.HuntForPsychoIcon" },
    { key = "Bombus",   str = "ab_bombus",   fam = "bombus",   cost = 4, upload = 1.0, cd = 45,
      icon = "",                   caption = "ChoiceCaptionParts.GrenadeExplodeIcon" },
    { key = "Minotaur", str = "ab_minotaur", fam = "minotaur", cost = 3, upload = 1.0, cd = 20,
      icon = "",                   caption = "ChoiceCaptionParts.Techie" },
  }
  M.HACKS = HACKS
  M.markSeen = {}

  local UNIVERSAL = { "Repair", "Hold", "Dismiss", "Detonate", "Overclock", "Fortify", "Zoom", "Cloak" }

  local function actionId(hack) return PREFIX .. hack.key end
  local function seId(hack) return PREFIX .. hack.key .. "SE" end

  local function tdbid(s) return TweakDBID.new(s) end

  local function ensure(id, kind)
    if TweakDB:GetRecord(id) == nil then TweakDB:CreateRecord(id, kind) end
  end

  local function constantMod(id, modType, stat, value)
    ensure(id, "gamedataConstantStatModifier_Record")
    TweakDB:SetFlatNoUpdate(id .. ".modifierType", modType)
    TweakDB:SetFlatNoUpdate(id .. ".statType", stat)
    TweakDB:SetFlatNoUpdate(id .. ".value", value)
    TweakDB:Update(id)
  end

  local function durationGroup(id, seconds)
    ensure(id, "gamedataStatModifierGroup_Record")
    TweakDB:SetFlatNoUpdate(id .. ".statModsLimit", -1)
    constantMod(id .. "Stat", "Additive", "BaseStats.MaxDuration", seconds)
    TweakDB:SetFlat(id .. ".statModifiers", { id .. "Stat" })
  end

  local function clone(id, source)
    if TweakDB:GetRecord(id) ~= nil then return true end
    if TweakDB:GetRecord(source) == nil then
      G.log("hacks: source record missing: " .. source)
      return false
    end
    TweakDB:CloneRecord(id, source)
    return true
  end

  local BASE_ACTION = "QuickHack.PingHack"

  local function buildOwnCheck()
    local id = PREFIX .. "OwnCheck"
    if not clone(id, "QuickHack.SystemCollapseHackBase_inline0") then return nil end
    local checkType = TweakDB:GetFlat(id .. ".checkType")
    local invert = TweakDB:GetFlat(id .. ".invert")
    G.log(string.format("hacks: own check base checkType=%s invert=%s",
      tostring(checkType), tostring(invert)))
    TweakDB:SetFlatNoUpdate(id .. ".statusEffect", G.TDB .. "CompanionSE")
    if type(checkType) == "string" and checkType ~= "" then
      TweakDB:SetFlatNoUpdate(id .. ".checkType", "Contain")
    elseif type(invert) == "boolean" then
      TweakDB:SetFlatNoUpdate(id .. ".invert", not invert)
    else
      G.log("hacks: own check has no known flip flag, hijacked units get no quickhacks")
      return nil
    end
    TweakDB:Update(id)
    return id
  end

  local function inherited(flatPath, dropTag)
    local out = {}
    for _, v in ipairs(TweakDB:GetFlat(flatPath) or {}) do
      if not (dropTag and tostring(v):find(dropTag, 1, true)) then
        table.insert(out, v)
      end
    end
    return out
  end

  local function buildOne(hack)
    local id = actionId(hack)
    local se = seId(hack)

    if not clone(se, "BaseStatusEffect.SeeThroughWalls") then return false end
    durationGroup(se .. "Dur", hack.mark or 1.0)
    TweakDB:SetFlatNoUpdate(se .. ".duration", se .. "Dur")
    TweakDB:SetFlatNoUpdate(se .. ".gameplayTags", { "Buff", "Stealth", "Robot" })
    TweakDB:SetFlatNoUpdate(se .. ".VFX", {})
    TweakDB:SetFlatNoUpdate(se .. ".packages", {})
    TweakDB:SetFlat(se .. ".uiData", "")

    if not clone(id .. "Effect", "QuickHack.SystemCollapseLvl3Hack_inline0") then return false end
    TweakDB:SetFlat(id .. "Effect.statusEffect", se)

    if not clone(id .. "Cd", "BaseStatusEffect.SystemCollapseCooldown") then return false end
    durationGroup(id .. "CdDur", M.cooldownOf(hack))
    TweakDB:SetFlatNoUpdate(id .. "Cd.duration", id .. "CdDur")
    TweakDB:SetFlatNoUpdate(id .. "Cd.gameplayTags", { "Debuff" })
    TweakDB:SetFlat(id .. "Cd.uiData", "")

    if not clone(id .. "CdEffect", "QuickHack.SystemCollapseHackBase_inline4") then return false end
    TweakDB:SetFlat(id .. "CdEffect.statusEffect", id .. "Cd")
    if not clone(id .. "CdCheck", "QuickHack.SystemCollapseHackBase_inline0") then return false end
    TweakDB:SetFlat(id .. "CdCheck.statusEffect", id .. "Cd")

    ensure(id .. "Cost", "gamedataStatPoolCost_Record")
    constantMod(id .. "CostStat", "Additive", "BaseStats.Memory", hack.cost)
    TweakDB:SetFlatNoUpdate(id .. "Cost.costMods", { id .. "CostStat" })
    TweakDB:SetFlat(id .. "Cost.statPool", "BaseStatPools.Memory")

    constantMod(id .. "Upload", "Additive", "BaseStats.QuickHackUpload", hack.upload)

    if not clone(id .. "UI", "Interactions.PingHack") then return false end
    TweakDB:SetFlatNoUpdate(id .. "UI.action", "Choice1")
    local locKey = "Mod-DroneCompanion-Hack-" .. hack.key
    local okCaption = pcall(function()
      TweakDB:SetFlatNoUpdate(id .. "UI.caption", LocKey(locKey))
    end)
    if not okCaption then
      TweakDB:SetFlatNoUpdate(id .. "UI.caption", locKey)
      G.log("hacks: LocKey() refused " .. locKey .. ", wrote the key as text")
    end
    TweakDB:SetFlatNoUpdate(id .. "UI.captionIcon",
      TweakDB:GetRecord(hack.caption) and hack.caption or "ChoiceCaptionParts.GlitchScreenBlindIcon")
    TweakDB:Update(id .. "UI")

    local actionName = "DC" .. hack.key
    CName.add(actionName)

    if not clone(id, BASE_ACTION) then return false end

    local inst = inherited(BASE_ACTION .. ".instigatorPrereqs")
    table.insert(inst, id .. "CdCheck")
    local start = inherited(BASE_ACTION .. ".startEffects")
    table.insert(start, id .. "CdEffect")
    local done = inherited(BASE_ACTION .. ".completionEffects", "PingHack_inline")
    table.insert(done, id .. "Effect")
    local targetActive = inherited(BASE_ACTION .. ".targetActivePrereqs", "PingPrereq")
    table.insert(targetActive, id .. "CdCheck")
    if M.ownCheck then table.insert(targetActive, M.ownCheck) end

    local category = "HackCategory.ControlHack"
    if TweakDB:GetRecord(category) == nil then
      G.log("hacks: category missing, falling back to Covert: " .. category)
      category = "HackCategory.CovertHack"
    end

    TweakDB:SetFlatNoUpdate(id .. ".actionName", actionName)
    TweakDB:SetFlatNoUpdate(id .. ".hackCategory", category)
    TweakDB:SetFlatNoUpdate(id .. ".objectActionUI", id .. "UI")
    TweakDB:SetFlatNoUpdate(id .. ".costs", { id .. "Cost" })
    TweakDB:SetFlatNoUpdate(id .. ".activationTime", { id .. "Upload" })
    TweakDB:SetFlatNoUpdate(id .. ".instigatorPrereqs", inst)
    TweakDB:SetFlatNoUpdate(id .. ".targetActivePrereqs", targetActive)
    TweakDB:SetFlatNoUpdate(id .. ".startEffects", start)
    TweakDB:SetFlatNoUpdate(id .. ".completionEffects", done)
    TweakDB:SetFlatNoUpdate(id .. ".isQuickHack", true)
    TweakDB:Update(id)
    return true
  end

  function M.setup()
    M.ownCheck = buildOwnCheck()
    local built, failed = 0, {}
    for _, hack in ipairs(HACKS) do
      if buildOne(hack) then built = built + 1 else table.insert(failed, hack.key) end
    end
    M.ready = built > 0
    G.log(string.format("hacks: %d/%d records ready%s", built, #HACKS,
      #failed > 0 and (" - FAILED: " .. table.concat(failed, ", ")) or ""))
  end

  function M.cooldownOf(hack)
    local mult = G.tuning.get("cooldown") * (1.0 - (G.perks.value("overload") or 0.0))
    return math.max(hack.mark and (hack.mark + 1.0) or 3.0, hack.cd * mult)
  end

  function M.applyCooldowns()
    if not M.ready or TweakDB == nil then return end
    for _, hack in ipairs(HACKS) do
      local stat = actionId(hack) .. "CdDurStat"
      if TweakDB:GetRecord(stat) ~= nil then
        TweakDB:SetFlat(stat .. ".value", M.cooldownOf(hack), "Float")
      end
    end
  end

  M.vanillaActions = {}

  function M.attachToRecord(recordId, model)
    if not M.ready or not M.ownCheck or not recordId or recordId == "" then return 0 end
    local flat = recordId .. ".objectActions"
    if M.vanillaActions[flat] == nil then
      local list = TweakDB:GetFlat(flat)
      if list == nil then
        G.log("hacks: no objectActions on " .. recordId)
        return 0
      end
      local copy = {}
      for _, v in ipairs(list) do copy[#copy + 1] = v end
      M.vanillaActions[flat] = copy
    end
    local n = 0
    for _, action in ipairs(M.actionsFor(model)) do
      if G.records.appendToFlat(flat, action, false) then n = n + 1 end
    end
    M.refreshPlayerList()
    return n
  end

  function M.detachFromRecord(recordId)
    local flat = recordId .. ".objectActions"
    local saved = M.vanillaActions[flat]
    if not saved then return end
    TweakDB:SetFlat(flat, saved)
    M.vanillaActions[flat] = nil
  end

  function M.isOn(key)
    return not (G.settings and G.settings.hacksOff or {})[key]
  end

  function M.actionsFor(model)
    if not M.ready then return {} end
    local list = {}
    for _, key in ipairs(UNIVERSAL) do
      if not (model.static and key == "Hold") and M.isOn(key) then
        table.insert(list, PREFIX .. key)
      end
    end
    local fam = model.chassis
    for _, hack in ipairs(HACKS) do
      if hack.fam and hack.fam == fam:lower() and M.isOn(hack.key) then table.insert(list, actionId(hack)) end
    end
    return list
  end

  local function republish(flat, model, mine)
    local keep = {}
    for _, v in ipairs(TweakDB:GetFlat(flat) or {}) do
      if not mine[tostring(v)] then keep[#keep + 1] = v end
    end
    for _, action in ipairs(M.actionsFor(model)) do keep[#keep + 1] = action end
    TweakDB:SetFlat(flat, keep)
  end

  function M.setOn(key, on)
    G.settings.hacksOff = G.settings.hacksOff or {}
    G.settings.hacksOff[key] = (not on) or nil
    G.saveSettings()
    M.republishAll()
  end

  function M.republishAll()
    if not M.ready or TweakDB == nil then return end
    local mine = {}
    for _, hack in ipairs(HACKS) do
      mine[actionId(hack)] = true
      mine[tostring(TweakDBID.new(actionId(hack)))] = true
    end
    for _, model in ipairs(G.MODELS) do
      for i = 1, G.INSTANCES do
        local flat = G.recordId(model, i) .. ".objectActions"
        if TweakDB:GetFlat(flat) ~= nil then republish(flat, model, mine) end
      end
    end
    M.refreshPlayerList()
  end

  local function heal(ent)
    local sps = Game.GetStatPoolsSystem()
    local id = ent:GetEntityID()
    local before = sps:GetStatPoolValue(id, gamedataStatPoolType.Health)
    sps:RequestSettingStatPoolValue(id, gamedataStatPoolType.Health, 100.0, ent)
    return before
  end

  M.heldCmd = {}
  M.anchor = {}

  function M.anchorHere(rec, ent)
    pcall(function()
      local p = ent:GetWorldPosition()
      M.anchor[rec] = { x = p.x, y = p.y, z = p.z }
    end)
  end

  local function setHold(rec, ent, on)
    M.held[rec] = on or nil
    if not on then M.anchor[rec] = nil end
    local how = "flag"

    if on then
      pcall(function()
        local old = M.heldCmd[rec]
        if old then pcall(function() AIComponent.CancelCommand(ent, old) end) end
        local cmd = AIHoldPositionCommand.new()
        cmd.duration = -1.0
        M.heldCmd[rec] = cmd
        AIComponent.SendCommand(ent, cmd)
        how = "AIHoldPositionCommand"
      end)
    else
      local cmd = M.heldCmd[rec]
      M.heldCmd[rec] = nil
      local cancelled = cmd ~= nil and pcall(function() AIComponent.CancelCommand(ent, cmd) end)

      local player = Game.GetPlayer()
      local nudged = false
      if player and not player:IsInCombat() then
        nudged = pcall(function()
          local follow = AIFollowTargetCommand.new()
          follow.target = player
          follow.desiredDistance = 6.0
          follow.teleport = true
          AIComponent.SendCommand(ent, follow)
        end)
      end

      if not (G.modelOf(rec) or {}).fly then pcall(function() G.companion.resetRole(ent) end) end
      how = string.format("cancel=%s follow=%s role reset", tostring(cancelled), tostring(nudged))
    end

    G.log(string.format("hack Hold: %s -> %s (%s)", rec, tostring(on), how))
  end
  M.setHold = setHold

  function M.clearHold(rec, ent)
    local cmd = M.heldCmd[rec]
    M.heldCmd[rec] = nil
    M.held[rec] = nil
    M.anchor[rec] = nil
    if cmd then pcall(function() AIComponent.CancelCommand(ent, cmd) end) end
  end

  local function detonate(rec, ent, model)
    pcall(function()
      StatusEffectHelper.ApplyStatusEffect(ent, tdbid("BaseStatusEffect.SuicideWithWeapon"))
    end)
    G.log("hack Detonate: SuicideWithWeapon applied on " .. rec)
    Cron.After(5.0, function()
      if not IsDefined(ent) or G.companion.isDown(ent) then
        G.log("hack Detonate: " .. rec .. " died through the game routine")
        return
      end
      pcall(function()
        Game.GetStatPoolsSystem():RequestSettingStatPoolValue(
          ent:GetEntityID(), gamedataStatPoolType.Health, 0.0, ent)
      end)
      G.log("hack Detonate: fallback killed " .. rec .. " with no explosion (routine did not fire)")
    end)
  end

  local function onCooldown(ent, hack)
    local left = false
    pcall(function()
      left = Game.GetStatusEffectSystem():HasStatusEffect(
        ent:GetEntityID(), tdbid(actionId(hack) .. "Cd"))
    end)
    return left
  end

  local function pushMenu(ent)
    local done = {}
    if pcall(function() ent:EvaluateQuickhacksCount() end) then table.insert(done, "evaluate") end
    if pcall(function() ent:SendQuickhackCommands(true) end) then table.insert(done, "send") end
    return table.concat(done, "+")
  end

  local function refreshMenu(ent)
    local how = pushMenu(ent)
    Cron.After(0.15, function()
      if IsDefined(ent) then pushMenu(ent) end
    end)
  end

  M.cdUntil = {}

  function M.cooldownLeft(rec)
    local ends = M.cdUntil[rec]
    if not ends then return nil end
    local left = ends - os.clock()
    if left <= 0 then return nil end
    return math.ceil(left)
  end

  local function startCooldown(ent, hack, rec)
    pcall(function()
      StatusEffectHelper.ApplyStatusEffect(ent, tdbid(actionId(hack) .. "Cd"))
    end)
    if rec then
      local ends = os.clock() + M.cooldownOf(hack)
      if ends > (M.cdUntil[rec] or 0) then M.cdUntil[rec] = ends end
    end
    refreshMenu(ent)
  end

  local function run(hack, rec, ent, model)
    local player = Game.GetPlayer()
    if onCooldown(ent, hack) then
      pcall(function()
        Game.GetStatPoolsSystem():RequestChangingStatPoolValue(
          player:GetEntityID(), gamedataStatPoolType.Memory, hack.cost, player, false, false)
      end)
      G.log(string.format("hack %s refused on %s: on cooldown, %d RAM refunded",
        hack.key, rec, hack.cost))
      G.notify(string.format(G.STR.hk_cooling, model.name))
      return
    end
    if hack.key ~= "Dismiss" and hack.key ~= "Detonate" and hack.key ~= "Hold" then
      startCooldown(ent, hack, rec)
    end
    if hack.buff then
      local b = hack.buff
      local ok = G.perks.tempBuff(ent, b.stat, b.mult or b.add, b.dur, b.add ~= nil)
      G.log(string.format("hack %s on %s: %s %s%.2f for %ds%s",
        hack.key, rec, b.stat, b.add and "+" or "x", b.mult or b.add, b.dur,
        ok and "" or " FAILED"))
      G.notify(string.format(G.STR.ability_used, model.name, G.STR[hack.str]))
      return
    end

    if hack.fam then
      local hit = G.abilities.runFamily(hack.fam, ent, player)
      G.log(string.format("hack %s on %s: %s", hack.key, rec, hit and "targets hit" or "no target in range"))
      G.notify(string.format(G.STR.ability_used, model.name, G.STR[hack.str]))
      return
    end

    if hack.key == "Repair" then
      local before = heal(ent)
      G.log(string.format("hack Repair: %s %.0f%% -> 100%%", rec, before))
      G.notify(string.format(G.STR.hk_repaired, model.name))
    elseif hack.key == "Hold" then
      local on = not M.held[rec]
      if on then M.anchorHere(rec, ent) end
      setHold(rec, ent, on)
      G.notify(string.format(on and G.STR.hk_holding or G.STR.hk_following, model.name))
    elseif hack.key == "Dismiss" then
      G.log("hack Dismiss: " .. rec)
      G.companion.dismiss(rec)
    elseif hack.key == "Detonate" then
      G.notify(string.format(G.STR.hk_detonating, model.name))
      detonate(rec, ent, model)
    end
  end

  local function setHoldCaption(held)
    local key = "Mod-DroneCompanion-Hack-" .. (held and "Release" or "Hold")
    local ui = PREFIX .. "HoldUI"
    local ok = pcall(function()
      TweakDB:SetFlatNoUpdate(ui .. ".caption", LocKey(key))
      TweakDB:Update(ui)
    end)
    M.captionHeld = held
    G.log(string.format("hacks: hold caption -> %s (%s)", key, ok and "ok" or "FAILED"))
  end

  function M.refreshPlayerList()
    local mine = 0
    local ok = pcall(function()
      for _, entry in ipairs(RPGManager.GetPlayerQuickHackListWithQuality(Game.GetPlayer())) do
        local id = ""
        pcall(function() id = tostring(entry.actionRecord:GetID()) end)
        if id:find("DroneCompanion.Hack", 1, true) then mine = mine + 1 end
      end
    end)
    M.lastRefresh = mine
  end

  function M.tick()
    if not M.ready then return end
    local rows = G.companion.aliveCache
    if not rows then return end

    local alive = #rows
    local aliveSet = {}
    for _, row in ipairs(rows) do aliveSet[row.rec] = true end
    for rec in pairs(M.held) do
      if not aliveSet[rec] then
        M.held[rec] = nil
        M.heldCmd[rec] = nil
        M.anchor[rec] = nil
        G.log("hacks: hold flag pruned for gone drone " .. rec)
      end
    end
    local anyHeld = next(M.held) ~= nil
    if anyHeld ~= M.captionHeld then setHoldCaption(anyHeld) end

    M.refreshIn = (M.refreshIn or 0) - 1
    if alive > 0 and (alive ~= M.prevAlive or M.refreshIn <= 0) then
      M.refreshPlayerList()
      M.refreshIn = 60
    end
    M.prevAlive = alive
    local ses = Game.GetStatusEffectSystem()
    for _, row in ipairs(rows) do
      if IsDefined(row.ent) then
        local id = row.ent:GetEntityID()
        for _, hack in ipairs(HACKS) do
          if hack.fam == nil or hack.fam == row.model.chassis:lower() then
            local marked = false
            pcall(function()
              marked = ses:HasStatusEffect(id, tdbid(seId(hack)))
            end)
            local seenKey = row.rec .. "|" .. hack.key
            if marked and not M.markSeen[seenKey] then
              if hack.mark then
                M.markSeen[seenKey] = true
              else
                pcall(function()
                  StatusEffectHelper.RemoveStatusEffect(row.ent, tdbid(seId(hack)))
                end)
              end
              local ok, err = pcall(run, hack, row.rec, row.ent, row.model)
              if not ok then
                G.log(string.format("hack %s FAILED on %s: %s", hack.key, row.rec, tostring(err)))
              end
            elseif not marked then
              M.markSeen[seenKey] = nil
            end
          end
        end
      end
    end
  end

  function M.demo()
    M.ready = true
    local function has(list, id)
      for _, v in ipairs(list) do if v == id then return true end end
      return false
    end

    local octant = M.actionsFor({ chassis = "Octant" })
    assert(#octant == #UNIVERSAL + 1, "every universal hack + 1 chassis hack")
    assert(has(octant, PREFIX .. "Octant"), "chassis hack present")
    assert(not has(octant, PREFIX .. "Wyvern"), "other chassis hack absent")
    assert(has(octant, PREFIX .. "Overclock") and has(octant, PREFIX .. "Fortify"),
      "buff hacks are universal")

    local android = M.actionsFor({ chassis = "Android" })
    assert(#android == #UNIVERSAL, "chassis with no ability keeps only the universal hacks")

    local static = M.actionsFor({ chassis = "Chimera", static = true })
    assert(not has(static, PREFIX .. "Hold"), "static drone gets no Hold")
    assert(#static == #UNIVERSAL - 1, "static drone loses only Hold")

    M.ready = false
    assert(#M.actionsFor({ chassis = "Octant" }) == 0, "no records means no published action")
    print("hacks demo ok")
  end

  return M
end
