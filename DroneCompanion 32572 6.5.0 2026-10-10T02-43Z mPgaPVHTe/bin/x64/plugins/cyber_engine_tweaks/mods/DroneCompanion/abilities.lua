return function(G)
  local M = {
    cooldown = {},
    hpPrev = {},
    healLeft = {},
    stacks = {},
    plateIdle = {},
    passiveCd = {},
    rallyTicks = {},
    rallyOn = {},
  }

  local function applyTo(ent, effect)
    StatusEffectHelper.ApplyStatusEffect(ent, TweakDBID.new(effect))
  end

  local ABILITIES = {
    octant = {
      key = "ab_octant", cd = 25, range = 30,
      run = function(drone, threats)

        if #threats == 0 then return false end
        applyTo(threats[1].ent, "BaseStatusEffect.Blind")
        return true
      end,
    },
    wyvern = {
      key = "ab_wyvern", cd = 30, range = 40,
      run = function(drone, threats)
        if #threats == 0 then return false end
        for _, t in ipairs(threats) do applyTo(t.ent, "BaseStatusEffect.PingMarkStatusEffect") end
        return true
      end,
    },
    griffin = {
      key = "ab_griffin", cd = 30, range = 20,
      run = function(drone, threats)
        if #threats == 0 then return false end
        for _, t in ipairs(threats) do applyTo(t.ent, "BaseStatusEffect.EMP") end
        return true
      end,
    },
    bombus = {
      key = "ab_bombus", cd = 45, range = 40,
      run = function(drone, threats)

        if #threats == 0 then return false end
        for _, t in ipairs(threats) do applyTo(t.ent, "BaseStatusEffect.JamCommuniations") end
        return true
      end,
    },
    minotaur = {
      key = "ab_minotaur", cd = 20, range = 30,
      run = function(drone, threats)

        if #threats == 0 then return false end
        for _, t in ipairs(threats) do
          TargetTrackingExtension.InjectThreat(t.ent, drone)
        end
        return true
      end,
    },
  }

  M.ABILITIES = ABILITIES

  local function familyOf(key)
    if G.hijack and G.hijack.is(key) then
      local model = G.hijack.modelOf(key)
      key = model and model.chassis or ""
    end
    if key:find("Octant") then return "octant" end
    if key:find("Wyvern") then return "wyvern" end
    if key:find("Griffin") then return "griffin" end
    if key:find("Bombus") then return "bombus" end
    if key:find("Minotaur") then return "minotaur" end
    return nil
  end

  local function threatsNear(player, origin, range)
    local list = {}
    local ok = pcall(function()
      for _, t in ipairs(player:GetTargetTrackerComponent():GetHostileThreats(false)) do
        local ent = t.entity
        if not G.companion.isDown(ent) then
          local d = Vector4.Distance(origin, ent:GetWorldPosition())
          if d <= range then table.insert(list, { ent = ent, dist = d }) end
        end
      end
    end)
    if not ok then return {} end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
  end

  M.familyOf = familyOf

  local PASSIVES = {
    octant   = { key = "ps_octant",   heal = 4.0, window = 5 },
    wyvern   = { key = "ps_wyvern",   effect = "BaseStatusEffect.Blind", cd = 8, range = 25 },
    griffin  = { key = "ps_griffin",  armor = 0.20, maxStacks = 5, decay = 15 },
    bombus   = { key = "ps_bombus",   aura = 2.5, radius = 20 },
    minotaur = { key = "ps_minotaur", taunt = 20, cd = 4 },
    android  = { key = "ps_android",  rally = 0.15, after = 10 },
  }
  M.PASSIVES = PASSIVES

  function M.passiveOf(chassis)
    if chassis == nil then return nil end
    return PASSIVES[tostring(chassis):lower()]
  end

  local function healthOf(ent)
    local pct = 0
    pcall(function()
      pct = Game.GetStatPoolsSystem():GetStatPoolValue(ent:GetEntityID(), gamedataStatPoolType.Health)
    end)
    return pct
  end

  local function setHealth(ent, pct)
    pcall(function()
      Game.GetStatPoolsSystem():RequestSettingStatPoolValue(
        ent:GetEntityID(), gamedataStatPoolType.Health, pct, ent)
    end)
  end

  local function armorMult(ent, mult)
    return pcall(function()
      Game.GetStatsSystem():AddModifier(ent:GetEntityID(),
        RPGManager.CreateStatModifier(gamedataStatType.Armor,
          gameStatModifierType.Multiplier, mult))
    end)
  end

  local function dropPlating(ent, rec, p)
    local n = M.stacks[rec] or 0
    if n == 0 then return end
    local left = n
    for _ = 1, n do
      if armorMult(ent, 1.0 / (1.0 + p.armor)) then left = left - 1 end
    end
    if left > 0 then G.log("plating revert failed for " .. rec .. " (" .. left .. " left)") end
    M.stacks[rec] = left > 0 and left or nil
  end

  local function damageMult(ent, mult)
    return pcall(function()
      Game.GetStatsSystem():AddModifier(ent:GetEntityID(),
        RPGManager.CreateStatModifier(gamedataStatType.NPCDamage,
          gameStatModifierType.Multiplier, mult))
    end)
  end

  local function runPassive(row, p, inCombat, rows, threats)
    local hp = healthOf(row.ent)
    local prev = M.hpPrev[row.rec]
    local hurt = prev ~= nil and hp < prev - 0.01
    M.hpPrev[row.rec] = hp

    if p.heal then
      if hurt then M.healLeft[row.rec] = p.window end
      local left = M.healLeft[row.rec] or 0
      if left > 0 then
        M.healLeft[row.rec] = left - 1
        if hp > 0 and hp < 100.0 then
          setHealth(row.ent, math.min(100.0, hp + p.heal))
        end
      end
    end

    if p.armor then
      if hurt then
        M.plateIdle[row.rec] = p.decay
        local n = M.stacks[row.rec] or 0
        if n < p.maxStacks and armorMult(row.ent, 1.0 + p.armor) then
          M.stacks[row.rec] = n + 1
        end
      elseif (M.stacks[row.rec] or 0) > 0 then
        local idle = (M.plateIdle[row.rec] or 0) - 1
        M.plateIdle[row.rec] = idle
        if idle <= 0 then dropPlating(row.ent, row.rec, p) end
      end
    end

    if p.aura then
      local from = row.ent:GetWorldPosition()
      local healed = 0
      for _, other in ipairs(rows) do
        if other.rec ~= row.rec and IsDefined(other.ent) then
          local pct = healthOf(other.ent)
          if pct > 0 and pct < 100.0
            and Vector4.Distance(from, other.ent:GetWorldPosition()) <= p.radius then
            setHealth(other.ent, math.min(100.0, pct + p.aura))
            healed = healed + 1
          end
        end
      end
    end

    if p.taunt then
      local cd = (M.passiveCd[row.rec] or 0) - 1
      M.passiveCd[row.rec] = cd
      if hurt and cd <= 0 then
        local from = row.ent:GetWorldPosition()
        local pulled = 0
        for _, enemy in ipairs(threats) do
          if IsDefined(enemy) and Vector4.Distance(from, enemy:GetWorldPosition()) <= p.taunt then
            if pcall(function() TargetTrackingExtension.InjectThreat(enemy, row.ent) end) then
              pulled = pulled + 1
            end
          end
        end
        if pulled > 0 then
          M.passiveCd[row.rec] = p.cd
        end
      end
    end

    if p.rally then
      local ticks = inCombat and ((M.rallyTicks[row.rec] or 0) + 1) or 0
      M.rallyTicks[row.rec] = ticks
      local on = M.rallyOn[row.rec] == true
      if not on and ticks >= p.after then
        if damageMult(row.ent, 1.0 + p.rally) then
          M.rallyOn[row.rec] = true
        end
      elseif on and not inCombat then
        damageMult(row.ent, 1.0 / (1.0 + p.rally))
        M.rallyOn[row.rec] = nil
      end
    end

    if p.effect and inCombat then
      local cd = (M.passiveCd[row.rec] or 0) - 1
      M.passiveCd[row.rec] = cd
      if cd <= 0 then
        local target = G.companion.targetEnt[row.rec]
        if IsDefined(target) and not G.companion.isDown(target) then
          local d = Vector4.Distance(row.ent:GetWorldPosition(), target:GetWorldPosition())
          if d <= p.range and pcall(applyTo, target, p.effect) then
            M.passiveCd[row.rec] = p.cd
          end
        end
      end
    end
  end

  function M.passiveTick(rows, inCombat, passive, threats)
    local seen = {}
    for _, row in ipairs(rows) do
      seen[row.rec] = true
      local p = M.passiveOf(row.model and row.model.chassis)
      if p and not passive[row.rec] and IsDefined(row.ent) then
        pcall(runPassive, row, p, inCombat, rows, threats or {})
      end
    end
    for rec in pairs(M.hpPrev) do
      if not seen[rec] then
        M.hpPrev[rec], M.healLeft[rec] = nil, nil
        M.stacks[rec], M.plateIdle[rec], M.passiveCd[rec] = nil, nil, nil
        M.rallyTicks[rec], M.rallyOn[rec] = nil, nil
      end
    end
  end

  function M.runFamily(fam, ent, player)
    local ability = ABILITIES[fam]
    if not ability or not player then return false end
    local fired = false
    pcall(function()
      local threats = threatsNear(player, ent:GetWorldPosition(),
        ability.range + (G.perks.value("range") or 0) + G.tuning.get("range"))
      fired = ability.run(ent, threats, player)
    end)
    return fired
  end

  function M.tick(aliveByRec, player, inCombat, passive)
    for rec, left in pairs(M.cooldown) do
      if left > 0 then M.cooldown[rec] = left - 1 end
    end
    if not inCombat or not G.settings.autoAbilities then return end

    local fires, order = {}, {}
    for _, row in ipairs(aliveByRec) do
      local ability = ABILITIES[familyOf(row.rec)]
      if ability and not passive[row.rec] and (M.cooldown[row.rec] or 0) <= 0 then
        local fired = false
        pcall(function()
          local threats = threatsNear(player, row.ent:GetWorldPosition(),
            ability.range + (G.perks.value("range") or 0) + G.tuning.get("range"))
          fired = ability.run(row.ent, threats, player)
        end)
        if fired then
          M.cooldown[row.rec] = math.max(1, math.floor(
            ability.cd * (1.0 - (G.perks.value("overload") or 0)) * G.tuning.get("cooldown")))
          local label = string.format(G.STR.ability_used, row.model.name, G.STR[ability.key])
          if not fires[label] then order[#order + 1] = label end
          fires[label] = (fires[label] or 0) + 1
        end
      end
    end

    for _, label in ipairs(order) do
      local n = fires[label]
      G.notifyRare("ability", n > 1 and string.format("%s (x%d)", label, n) or label)
    end
  end

  function M.demo()
    assert(familyOf("DroneCompanion.OctantMilitech1") == "octant")
    assert(familyOf("DroneCompanion.AndroidNCPD1") == nil, "android has no family ability")

    assert(M.passiveOf("Octant").heal, "octant repairs itself when hurt")
    assert(M.passiveOf("Griffin").maxStacks == 5, "griffin plating caps")
    assert(M.passiveOf("Android").rally, "android has a passive without a chassis ability")
    assert(M.passiveOf("Cerberus") == nil, "chassis without passive stays nil")
    for fam, p in pairs(M.PASSIVES) do
      assert(p.key == "ps_" .. fam, "passive key must match its family: " .. fam)
    end

    local android = { rec = "DroneCompanion.AndroidNCPD1", model = { chassis = "Android" } }
    assert(M.passiveOf(android.model.chassis).rally,
      "passive comes from the chassis, not from the ability catalog")
    assert(familyOf(android.rec) == nil, "android still has no chassis ability")

    M.hpPrev = { ["DroneCompanion.OctantMilitech1"] = 50.0 }
    M.stacks = { ["DroneCompanion.OctantMilitech1"] = 3 }
    M.passiveTick({}, false, {})
    assert(next(M.hpPrev) == nil and next(M.stacks) == nil,
      "state of a drone that left the field is dropped")

    print("abilities demo ok")
    return true
  end

  return M
end
