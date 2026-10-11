return function(G)
  local companion = G.companion
  local settings = G.settings
  local M = { selectedIndex = 1 }
  for i, model in ipairs(G.MODELS) do
    if model.key == settings.selected then M.selectedIndex = i end
  end

  M.THEMES = {
    { key = "corpo", accent = { 0.88, 0.16, 0.14 }, bright = { 1.00, 0.35, 0.30 } },
    { key = "samurai", accent = { 0.96, 0.88, 0.05 }, bright = { 1.00, 0.95, 0.30 } },
    { key = "netrunner", accent = { 0.25, 0.85, 0.95 }, bright = { 0.55, 0.95, 1.00 } },
    { key = "militech", accent = { 0.30, 0.52, 0.90 }, bright = { 0.58, 0.74, 1.00 } },
    { key = "valentinos", accent = { 0.88, 0.66, 0.12 }, bright = { 1.00, 0.84, 0.40 } },
    { key = "maelstrom", accent = { 0.95, 0.38, 0.06 }, bright = { 1.00, 0.58, 0.28 } },
    { key = "voodoo", accent = { 0.18, 0.80, 0.45 }, bright = { 0.45, 1.00, 0.66 } },
    { key = "mox", accent = { 0.94, 0.28, 0.66 }, bright = { 1.00, 0.56, 0.82 } },
    { key = "arasaka", accent = { 0.70, 0.10, 0.20 }, bright = { 0.92, 0.35, 0.45 } },
    { key = "vanilla", accent = { 1.00, 0.38, 0.35 }, bright = { 0.37, 0.96, 1.00 } },
    { key = "default", accent = { 1, 1, 1 }, bright = { 1, 1, 1 } },
    { key = "slate", accent = { 0.99, 0.93, 0.04 }, bright = { 1.00, 0.97, 0.45 } },
  }

  function M.theme()
    for _, th in ipairs(M.THEMES) do
      if th.key == settings.theme then return th end
    end
    return M.THEMES[1]
  end

  function M.cycleTheme(step)
    local idx = 1
    for i, th in ipairs(M.THEMES) do
      if th.key == settings.theme then idx = i end
    end
    idx = ((idx - 1 + step) % #M.THEMES) + 1
    settings.theme = M.THEMES[idx].key
    G.saveSettings()
  end

  local function S(key) return G.STR[key] end

  M.SUBTABS = {
    drones = { { "tab_drones", "summon" }, { "presets", "preset_head" } },
    commands = { { "behavior", "sec_behavior" }, { "cmdhacks", "sec_hacks" } },
    upgrades = { { "tab_upgrades", "up_tree" }, { "firmware", "up_hw_head" } },
  }

  function M.chassisName(key)
    for _, ch in ipairs(G.CHASSIS) do
      if ch.key == key then return ch.name end
    end
    return key
  end

  function M.factionName(model)
    for _, ch in ipairs(G.CHASSIS) do
      if ch.key == model.chassis then
        for _, fac in ipairs(ch.factions) do
          if fac.key == model.faction then return fac.name end
        end
      end
    end
    return model.faction
  end

  function M.firstOf(chassisKey)
    for i, model in ipairs(G.MODELS) do
      if model.chassis == chassisKey then return i end
    end
    return 1
  end

  local PCT = { armor = true, damage = true, overload = true }

  function M.perkDesc(p, rank)
    local v = G.perks.valueAt(p, rank) or p.values[1]
    if PCT[p.key] then v = v * 100 end
    return string.format(S("pk_" .. p.key .. "_d"), v)
  end

  local function statText(label, value, bonus)
    if bonus and bonus > 0 then
      return string.format("%s x%.1f -> x%.1f (+%d%%)",
        label, value, value * (1.0 + bonus), bonus * 100)
    end
    return string.format("%s x%.1f", label, value)
  end

  function M.chassisOf(model)
    return G.chassisOf(model.chassis)
  end

  function M.descLines(model)
    local out = {}
    local ch = M.chassisOf(model)
    if not ch then return out end

    local bits = { ch.fly and S("d_flying") or S("d_ground") }
    if model.weapon or ch.weapon then
      table.insert(bits, string.format(S("d_weapon"), model.weapon or ch.weapon))
    end
    if ch.price and settings.immersive then
      table.insert(bits, string.format(S("sp_cost"), G.pointsOf(ch.key)))
      if companion.ownsShard(ch.key) then
        table.insert(bits, S("d_shard_owned"))
      else
        table.insert(bits, string.format(S("d_price"),
          tostring(ch.price):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")))
      end
    end
    table.insert(out, { kind = "dim", text = table.concat(bits, " - ") })

    if ch.static then
      table.insert(out, { kind = "warn", text = S("d_static") })
    end

    table.insert(out, { kind = "text", text = statText(S("d_toughness"),
      G.tuning.catalog(ch.key, "hp") * G.tuning.get("hp"), G.perks.value("armor")) })
    table.insert(out, { kind = "text", text = statText(S("d_damage"),
      G.tuning.catalog(ch.key, "dmg") * G.tuning.get("dmg"), G.perks.value("damage")) })

    local fam = ch.key:lower()
    local ab = G.abilities.ABILITIES[fam]
    if ab then
      local range = ab.range + (G.perks.value("range") or 0)
      local cd = math.max(3, math.floor(ab.cd * (1.0 - (G.perks.value("overload") or 0))))
      table.insert(out, { kind = "dim",
        text = string.format(S("d_ability_line"), S(ab.key), range, cd) })
    end

    local ps = G.abilities.PASSIVES[fam]
    if ps then
      local detail
      if ps.heal then
        detail = string.format(S("ps_octant_d"), ps.heal, ps.window)
      elseif ps.effect then
        detail = string.format(S("ps_wyvern_d"), ps.cd, ps.range)
      elseif ps.armor then
        detail = string.format(S("ps_griffin_d"), ps.armor * 100, ps.maxStacks)
      elseif ps.aura then
        detail = string.format(S("ps_bombus_d"), ps.aura, ps.radius)
      elseif ps.taunt then
        detail = string.format(S("ps_minotaur_d"), ps.taunt)
      else
        detail = string.format(S("ps_android_d"), ps.rally * 100, ps.after)
      end
      table.insert(out, { kind = "dim",
        text = string.format("%s: %s - %s", S("d_passive"), S(ps.key), detail) })
    end
    return out
  end

  local function chauffeurStatus(rows)
    local rec = G.chauffeur.currentDriver()
    if not rec then return S("ch_no_driver") end
    local name = rec
    for _, row in ipairs(rows) do
      if row.rec == rec then name = G.squad.displayName(row.rec, row.model) end
    end
    local run = G.chauffeur.run
    local state = S("ch_status_wheel")
    if run and run.mode == "drive" then state = S("ch_driving") elseif run and run.mode == "pickup" then state = S("ch_coming") end
    return name .. ": " .. state
  end
  M.chauffeurStatus = chauffeurStatus

  local CH_RIDE = {
    { "board", "ch_board", "board" }, { "pickup", "ch_pickup", "pickup" }, { "enter", "ch_enter", "enter" },
    { "drive", "ch_drive", "drive" }, { "release", "ch_release", "release" },
  }
  local CH_CAR = {
    { "radio", "ch_radio", "radio" }, { "radionext", "ch_radio_next", "radioNext" }, { "windows", "ch_windows", "windows" },
    { "doors", "ch_doors", "doors" }, { "attack", "ch_attack", "passengerAttack" },
  }
  M.CH_RIDE, M.CH_CAR = CH_RIDE, CH_CAR

  M.ACQUISITION = {
    { "immersive", "immersive", "immersive_hint", true },
    { "rigger", "rigger", "rigger_hint", true },
  }
  M.HACK_ENEMIES = {
    { "camHacks", "cam_hacks", "cam_hacks_hint" },
    { "androidHacks", "android_hacks", "android_hacks_hint" },
  }

  local BEHAVIOR_GROUPS = {
    { "grp_summon", {
      { "spawnBehind", "spawn_behind", "spawn_behind_hint" },
      { "spawnMuted", "spawn_muted", "spawn_muted_hint" },
    } },
    { "st_combat", {
      { "autoAbilities", "auto_abilities" },
      { "scanFocus", "scan_focus", "scan_focus_hint" },
      { "explosive", "explosive", "explosive_hint" },
      { "protectV", "protect_v", "protect_v_hint" },
      { "recon", "recon", "recon_hint" },
    } },
    { "grp_rules", {
      { "dronesImmortal", "drones_immortal", "drones_immortal_hint" },
      { "hijackBosses", "hijack_bosses", "hijack_bosses_hint" },
    } },
    { "sec_mobility", {
      { "matchFacing", "match_facing", "match_facing_hint" },
      { "stealthGhost", "stealth_ghost", "stealth_ghost_hint" },
    } },
    { "grp_androids", {
      { "autoHolster", "auto_holster", "auto_holster_hint" },
      { "androidLoot", "android_loot", "android_loot_hint" },
    } },
  }
  M.BEHAVIOR_GROUPS = BEHAVIOR_GROUPS

  function M.actToggle()
    if companion.hasActive() or companion.stashed then
      companion.stashed = nil
      companion.dismissAll()
    else
      companion.summon(M.selectedIndex)
    end
  end

  function M.actCycle()
    M.selectedIndex = M.selectedIndex % #G.MODELS + 1
    G.notify(string.format(S("selected"), G.MODELS[M.selectedIndex].name))
  end

  return M
end
