return function(G)
  local M = { open = false, mode = "rows" }

  local STEP = {
    dmg = 0.1, hp = 0.1, catchup = 1.0, range = 5.0,
    cooldown = 0.05, instances = 1, leash = 5.0, nethack = 1.0, lowhp = 5.0, autodismiss = 5.0, recon = 5.0, medic = 5.0,
  }
  local FMT = {
    dmg = "x%.2f", hp = "x%.2f", catchup = "%.0f m", range = "+%.0f m",
    cooldown = "x%.2f", instances = "%d", leash = "%.0f m", nethack = "%.0f s",
    lowhp = "%.0f%%", autodismiss = "%.0f s", recon = "%.0f m", medic = "%.0f%%",
  }
  local TUNE_LABEL = {
    dmg = "tune_dmg", hp = "tune_hp", catchup = "tune_catchup", range = "tune_range",
    cooldown = "tune_cooldown", instances = "tune_instances", leash = "tune_leash",
    nethack = "tune_nethack", lowhp = "tune_lowhp",
    autodismiss = "tune_autodismiss", recon = "tune_recon", medic = "tune_medic",
  }

  local PHOTO_CHARS, PHOTO_ROWS = 40, 6
  local rows
  local ink
  local optionState
  local editing
  local picks = {}

  local function pickOf(id, current)
    local p = picks[id]
    if p then return p.value end
    return current
  end

  function M.forgetPicks(rec)
    picks["skin|" .. rec] = nil
    picks["gw|" .. rec] = nil
  end

  local function same(a, b)
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 1e-6 end
    return a == b
  end

  local function afterBar(value)
    return (tostring(value or ""):match("|(.*)$")) or value
  end

  local function inkPut(id, kind, label, value)
    if kind == "group" then
      ink.head(label)
    elseif kind == "head" or kind == "text" then
      ink.row("dim", "", "", label)
    elseif kind == "hp" then
      ink.row("dim", "", "", afterBar(value))
    elseif kind == "slider" or kind == "toggle" or kind == "choice" then
      local row = ink.row(kind == "slider" and "choice" or kind, id, label, afterBar(value))
      local cur, def = optionState(id)
      if def ~= nil then row.changed = not same(cur, def) end
      local tune = tostring(id or ""):match("^tune|(.+)$")
      if row.changed and tune and FMT[tune] then
        row.defText = string.format(FMT[tune], tune == "instances" and math.floor(def) or def)
      end
    elseif kind == "btn" or kind == "dim" or kind == "warn" then
      ink.row(kind, id, label, value)
    else
      ink.row("dim", "", label, value)
    end
  end

  local function put(id, kind, label, value, icon)
    if ink then return inkPut(id, kind, label, value) end
    rows[#rows + 1] = table.concat({ "R", id or "", kind, label or "", value or "", icon or "" }, "\t")
  end

  local function hint(text)
    if ink then
      local last = ink.rows[#ink.rows]
      if last and text and text ~= "" then last.info = text end
      return
    end
    if #rows > 0 and text and text ~= "" then rows[#rows] = rows[#rows] .. "\t" .. text end
  end

  local function f8Id(key)
    return key == "autoAbilities" and "auto" or key:lower()
  end

  local function toggleRows(list)
    for _, row in ipairs(list) do
      put(f8Id(row[1]), "toggle", G.STR[row[2]], G.settings[row[1]] and "1" or "0")
      if row[1] == "rigger" and not G.companion.hasGatekeeper() then
        hint(G.STR.rigger_missing)
      elseif row[3] then
        hint(G.STR[row[3]])
      end
    end
  end

  local function sliderValue(value, min, max, text)
    local frac = max > min and (value - min) / (max - min) or 0
    return string.format("%.3f|%s", math.max(0, math.min(1, frac)), text)
  end

  local function selModel()
    return G.MODELS[G.ui.selectedIndex]
  end

  local function loadoutLabel(key)
    return G.armory.label(key)
  end

  local function setLoadout(key)
    G.settings.loadout = key
    G.saveSettings()
    for _, model in ipairs(G.MODELS) do
      if model.chassis == "Android" then G.records.applyLoadout(model, G.settings.loadout) end
    end
  end

  local function cycleLoadout(step)
    local list = G.armory.options(true)
    local at = 1
    for i, key in ipairs(list) do
      if key == G.settings.loadout then at = i end
    end
    at = at + step
    if at < 1 then at = #list end
    if at > #list then at = 1 end
    setLoadout(list[at])
  end

  local function hpValue(ent)
    local id = ent:GetEntityID()
    local cur = Game.GetStatPoolsSystem():GetStatPoolValue(id, "Health", false)
    local max = Game.GetStatsSystem():GetStatValue(id, "Health")
    local frac = max > 0 and cur / max or 0
    return string.format("%.3f|%.0f / %.0f", frac, cur, max)
  end

  local function priceLabel(chassis)
    if not chassis.price or not G.settings.immersive then return "" end
    local pts = string.format(G.STR.sp_cost, G.pointsOf(chassis.key))
    if G.companion.ownsShard(chassis.key) then
      return pts .. " - " .. G.STR.d_shard_owned
    end
    return pts .. " - " .. string.format(G.STR.d_price,
      tostring(chassis.price):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", ""))
  end

  local function chassisOf(key)
    return G.chassisOf(key) or G.CHASSIS[1]
  end

  local function modelsOf(chassisKey)
    local list = {}
    for i, model in ipairs(G.MODELS) do
      if model.chassis == chassisKey then list[#list + 1] = i end
    end
    return list
  end

  local function cycleChassis(step)
    local sel = selModel()
    local at = 1
    for i, ch in ipairs(G.CHASSIS) do
      if ch.key == sel.chassis then at = i end
    end
    at = ((at - 1 + step) % #G.CHASSIS) + 1
    G.ui.selectedIndex = G.ui.firstOf(G.CHASSIS[at].key)
    G.saveSettings()
  end

  local function cycleFaction(step)
    local list = modelsOf(selModel().chassis)
    if #list < 2 then return end
    local at = 1
    for i, index in ipairs(list) do
      if index == G.ui.selectedIndex then at = i end
    end
    at = ((at - 1 + step) % #list) + 1
    G.ui.selectedIndex = list[at]
    G.saveSettings()
  end

  local function inkPresets()
    for slot = 1, G.squad.SLOTS do
      ink.head(G.squad.presetLabel(slot), nil, "preset" .. slot)
      put("pload|" .. slot, "btn", G.STR.preset_load, G.squad.presetSummary(slot))
      hint(G.STR.preset_hint)
      put("psave|" .. slot, "btn", G.STR.preset_save, "")
      hint(G.STR.preset_hint)
      if not G.inkmenu.pad then
        put("pn|" .. slot, "btn", G.STR.sq_name, G.squad.presetNames[slot] or "")
        hint(G.STR.name_hint)
        if editing == "pn|" .. slot then
          ink.search("pn|" .. slot, G.STR.sq_name, G.squad.presetNames[slot] or "", G.squad.presetLabel(slot))
        end
      end
    end
  end

  local function subSummon()
    local sel = selModel()
    local chassis = chassisOf(sel.chassis)
    local desc = G.ui.descLines(sel)
    local lines, rows = {}, 0
    for _, line in ipairs(desc) do
      local _, chars = line.text:gsub("[^\128-\191]", "")
      rows = rows + math.ceil(chars / PHOTO_CHARS)
      if line.kind ~= "warn" and rows <= PHOTO_ROWS then lines[#lines + 1] = line.text end
    end
    ink.photo = { part = sel.chassis:lower(), title = sel.name, lines = lines }
    put(nil, "group", G.STR.grp_model, "")
    put("chassis", "choice", G.STR.chassis, chassis.name)
    local warns = {}
    for _, line in ipairs(desc) do
      if line.kind == "warn" then warns[#warns + 1] = line.text end
    end
    warns[#warns + 1] = G.STR.chassis_hint
    hint(table.concat(warns, " "))
    put("faction", "choice", G.STR.faction, G.ui.factionName(sel))
    hint(G.STR.faction_hint)
    if G.skins.listFor(sel) then
      put("skin", "choice", G.STR.skin, G.skins.label(sel))
      hint(sel.paintByRecord and G.STR.skin_mech_hint or G.STR.skin_hint)
    end
    if sel.chassis == "Android" then
      put("loadout", "choice", G.STR.loadout, loadoutLabel(G.settings.loadout))
      hint(G.STR.loadout_hint)
      put("androidheads", "toggle", G.STR.android_heads, G.settings.androidHeads and "1" or "0")
      hint(G.STR.android_heads_hint)
    elseif sel.chassis == "Minotaur" then
      put("mecharmor", "toggle", G.STR.mech_armor, G.settings.mechArmor and "1" or "0")
      hint(G.STR.mech_armor_hint)
    end
    put(nil, "group", G.STR.grp_acquisition, "")
    toggleRows(G.ui.ACQUISITION)
    put(nil, "group", G.STR.grp_summon, "")
    put("sum|" .. G.ui.selectedIndex, "btn", G.STR.summon, priceLabel(chassis))
    if G.settings.immersive then
      hint(string.format(G.STR.sp_pool, G.companion.pointsUsed(), G.companion.pointsPool()))
      if not G.companion.ownsShard(sel.chassis) then
        put("giveshard", "btn", G.STR.give_shard, "")
        hint(string.format(G.STR.shard_missing, G.ui.chassisName(sel.chassis)))
      else
        put("takeshard", "btn", G.STR.take_shard, "")
        hint(G.STR.take_shard_hint)
      end
    else
      hint(G.STR.imm_free_hint)
    end
  end

  local function actionsHead()
    ink.head(G.STR.actionshdr, "actionshdr", "actions")
  end

  local function stanceLabel(rec)
    return G.STR["st_" .. G.companion.stanceOf(rec)]
  end

  local function statusLine(rec, model)
    local bits = {}
    bits[#bits + 1] = string.format(G.STR.card_damage, G.tuning.dmgFor(model))
    bits[#bits + 1] = string.format(G.STR.card_hpmult,
      G.tuning.hpFor(model) * (1.0 + (G.perks.value("armor") or 0.0)))
    bits[#bits + 1] = string.format(G.STR.card_armor, (G.perks.value("armor") or 0.0) * 100)
    if not model.static and not model.hijack then
      bits[#bits + 1] = G.armory.label(G.companion.weaponOf[rec] or G.settings.loadout)
    end
    bits[#bits + 1] = model.fly and G.STR.card_fly or G.STR.card_ground
    return table.concat(bits, " - ")
  end

  local function unitSummary(rec, ent, pct)
    local bits = { string.format("%.0f%%", pct), stanceLabel(rec) }
    if G.hacks.held[rec] then bits[#bits + 1] = G.STR.held_row end
    local player = Game.GetPlayer()
    if player and not ent:IsDead() then
      bits[#bits + 1] = string.format("%.0f m", Vector4.Distance(player:GetWorldPosition(), ent:GetWorldPosition()))
    end
    return table.concat(bits, " - ")
  end

  local HP_OK, HP_MID, HP_LOW = "0.247,0.749,0.416", "0.878,0.627,0.227", "0.851,0.290,0.290"

  local function unitDetail(rec, ent, model)
    local lines = { "HP " .. G.native.thousands((hpValue(ent):match("|(.*)$"))) }
    local rank = G.squad.rankLabel(rec)
    local left = G.hacks.cooldownLeft(rec)
    local status = rank or ""
    if left then status = status .. (status ~= "" and " - " or "") .. string.format(G.STR.hk_ready, left) end
    if status ~= "" then lines[#lines + 1] = status end
    local stats = string.format(G.STR.sq_kills, G.squad.killsOf(rec))
    if G.squad.deathsOf(rec) > 0 then
      stats = stats .. " - " .. string.format(G.STR.sq_deaths, G.squad.deathsOf(rec)) .. " - " .. G.squad.kdLabel(rec)
    end
    lines[#lines + 1] = stats
    lines[#lines + 1] = statusLine(rec, model)
    return table.concat(lines, "\194\182")
  end

  local chauffeurRows

  local function tabSquad()
    if not G.inkmenu.pad then
      if ink.detached == "tab_squad" then
        put("squadattach", "btn", G.STR.sq_attach, "")
        hint(G.STR.sq_attach_hint)
      else
        put("squadwin", "btn", G.STR.sq_detach, "")
        hint(G.STR.sq_detach_hint)
      end
    end
    if G.companion.stashed then
      put(nil, "text", string.format(G.STR.hidden, #G.companion.stashed), "")
      return
    end
    if G.companion.garage then
      put(nil, "dim", string.format(G.STR.hidden, #G.companion.garage), "")
    end
    local rows = {}
    G.companion.eachActive(function(rec, ent, model)
      rows[#rows + 1] = { rec = rec, ent = ent, model = model }
    end)
    rows = G.arena.withFighters(rows)
    if #rows == 0 then
      put(nil, "text", G.STR.no_drone, "")
      return
    end
    local seen = {}
    for _, row in ipairs(rows) do
      local rec, ent, model = row.rec, row.ent, row.model
      seen[rec] = true
      local head = ink.head(G.squad.displayName(rec, model), nil, rec)
      local first = #ink.rows
      local pct = 0
      pcall(function() pct = Game.GetStatPoolsSystem():GetStatPoolValue(ent:GetEntityID(), "Health", true) end)
      head.summary = ent:IsDead() and string.format(G.STR.destroyed_row, model.name) or unitSummary(rec, ent, pct)
      head.tint = (ent:IsDead() or pct < 30) and HP_LOW or (pct < 60 and HP_MID or HP_OK)
      do
        local left = G.companion.repairLeft(rec)
        if left and left > 0 and ent:IsDead() then
          put("rep|" .. rec, "btn", string.format(G.STR.repair_cost, G.companion.repairCost(model)),
            string.format(G.STR.repair_left, left))
        end
        put("st|" .. rec, "choice", G.STR.sq_stance, stanceLabel(rec))
        put("hold|" .. rec, "toggle", G.STR.sq_hold,
          G.hacks.held[rec] and "1" or "0")
        if model.chassis == "Android" and not model.hijack then
          put("hol|" .. rec, "toggle", G.STR.sq_holster,
            G.companion.isHolstered(rec) and "1" or "0")
          put("gw|" .. rec, "choice", G.STR.give_weapon,
            G.armory.label(pickOf("gw|" .. rec, G.companion.weaponOf[rec] or G.settings.loadout)))
          hint(G.STR.pick_apply_hint)
          local p = picks["gw|" .. rec]
          if p and p.value ~= (G.companion.weaponOf[rec] or G.settings.loadout) then
            put("gwok|" .. rec, "btn", G.STR.hint_apply, G.armory.label(p.value))
          end
        end
        if not model.hijack and G.skins.listFor(model) then
          put("skin|" .. rec, "choice", G.STR.skin,
            G.skins.labelFor(rec, pickOf("skin|" .. rec, G.settings.skins[rec])))
          hint(G.STR.pick_apply_hint)
          local p = picks["skin|" .. rec]
          if p and p.value ~= G.settings.skins[rec] then
            put("skinok|" .. rec, "btn", G.STR.hint_apply, G.skins.labelFor(rec, p.value))
          end
        end
        put("l|" .. rec, "toggle", G.STR.sq_light,
          G.companion.lit[rec] == true and "1" or "0")
        put("m|" .. rec, "toggle", G.STR.sq_mute,
          G.companion.muted[rec] == true and "1" or "0")
        if not model.hijack then
          put("cam|" .. rec, "btn",
            G.dronecam.active == rec and G.STR.sq_cam_exit or G.STR.sq_camera, "", "g:bond")
        end
        if not G.inkmenu.pad then
          put("nm|" .. rec, "btn", G.STR.sq_name, G.squad.names[rec] or "")
          hint(G.STR.name_hint)
          if editing == "nm|" .. rec then
            ink.search("nm|" .. rec, G.STR.sq_name, G.squad.names[rec] or "", model.name)
          end
        end
        put("x|" .. rec, "btn", model.hijack and G.STR.hijack_shutdown or G.STR.dismiss_one, "!")
      end
      local detail = unitDetail(rec, ent, model)
      local pic = model.chassis and model.chassis:lower() or nil
      head.info, head.pic = detail, pic
      for i = first + 1, #ink.rows do
        local row = ink.rows[i]
        row.info = (row.info and row.info ~= "") and (detail .. "\194\182" .. row.info) or detail
        row.pic = pic
      end
    end
    local anyAndroid, androids = false, {}
    for _, row in ipairs(rows) do
      if row.model.chassis == "Android" then
        anyAndroid = true
        if not row.model.hijack then androids[#androids + 1] = row end
      end
    end
    if anyAndroid then chauffeurRows(rows, androids) end
    actionsHead()
    put("regroup", "btn", G.STR.sq_regroup, "", "g:rescue")
    put("towp", "btn", G.STR.sq_to_wp, "")
    local anyAndroidAlive, anyHolstered = G.companion.androidHolsterState()
    if anyAndroidAlive then
      put("holsterall", "btn", anyHolstered and G.STR.sq_draw_all or G.STR.sq_holster_all, "")
    end
    if G.hijack.count() > 0 then
      put("hijackrel", "btn", string.format(G.STR.hijack_count, G.hijack.count())
        .. " - " .. G.STR.hijack_release, "")
    end
    put("dismissall", "btn", G.STR.dismiss_all, "!")
  end

  chauffeurRows = function(rows, androids)
    local status = G.ui.chauffeurStatus(rows)
    put(nil, "group", G.STR.sec_chauffeur, "")
    if #androids > 0 then
      for _, row in ipairs(androids) do
        put("seat|" .. row.rec, "choice", G.squad.displayName(row.rec, row.model), G.chauffeur.seatLabel(row.rec))
        hint(G.STR.ch_hint)
      end
    end
    put(nil, "group", G.STR.ch_grp_ride, "")
    for _, b in ipairs(G.ui.CH_RIDE) do
      put("ch" .. b[1], "btn", G.STR[b[2]], "")
      hint(status)
    end
    put(nil, "group", G.STR.ch_grp_car, "")
    for _, b in ipairs(G.ui.CH_CAR) do
      put("ch" .. b[1], "btn", G.STR[b[2]], "")
      hint(G.STR.ch_hint)
    end
  end

  local function subTree()
    for _, col in ipairs(G.perks.COLUMNS) do
      put(nil, "group", G.STR["col_" .. col], "")
      for _, perk in ipairs(G.perks.PERKS) do
        if perk.col == col then
          local rank, max = G.perks.rank(perk.key), #perk.values
          local eff = G.perks.effRank(perk.key)
          put("perk|" .. perk.key, "choice", G.STR["pk_" .. perk.key],
            string.format("%d/%d%s", rank, max,
              eff > rank and string.format(" (+%d)", eff - rank) or ""))
          hint(G.ui.perkDesc(perk, math.max(eff, 1)))
        end
      end
    end
    actionsHead()
    put("respec", "btn", G.STR.respec, "!")
    hint(string.format(G.STR.points, G.perks.available(), G.perks.total()) .. ". " .. G.STR.respec_hint)
  end

  local function subFirmware()
    put(nil, "group", G.STR.up_hw_head, "")
    put("give|UpCombat", "choice", G.STR.up_combat, string.format("x%d", G.tuning.upCount("UpCombat")))
    hint(G.STR.up_hw_hint)
    put("give|UpSupport", "choice", G.STR.up_armor, string.format("x%d", G.tuning.upCount("UpSupport")))
    hint(G.STR.up_hw_hint)
    put("give|UpUtility", "choice", G.STR.up_servo, string.format("x%d", G.tuning.upCount("UpUtility")))
    hint(G.STR.up_hw_hint)
  end

  local function subBehavior()
    for _, grp in ipairs(G.ui.BEHAVIOR_GROUPS) do
      put(nil, "group", G.STR[grp[1]], "")
      toggleRows(grp[2])
      if grp[1] == "st_combat" then
        local slot = G.settings.autoSummon or 0
        put("autosummon", "choice", G.STR.auto_summon, slot > 0 and G.squad.presetLabel(slot) or G.STR.off)
        hint(G.STR.auto_summon_hint)
      end
    end
  end

  local function hudToggles()
    put("hud", "toggle", G.STR.hud_toggle, G.settings.hud and "1" or "0")
    hint(G.STR.hud_hint)
    put("minimap", "toggle", G.STR.minimap_toggle, G.settings.minimap and "1" or "0")
    hint(G.STR.minimap_hint)
  end

  local function subHacks()
    put(nil, "group", G.STR.grp_hack_enemies, "")
    toggleRows(G.ui.HACK_ENEMIES)
    put(nil, "group", G.STR.grp_hack_drones, "")
    for _, hack in ipairs(G.hacks.HACKS) do
      put("hack|" .. hack.key, "toggle", G.STR[hack.str] or hack.key, G.hacks.isOn(hack.key) and "1" or "0")
      hint(string.format("%d RAM - %ds. %s", hack.cost, hack.cd, G.STR.hk_hint))
    end
  end

  local function scaleValue(key)
    local v = G.settings[key] or 1.0
    return sliderValue(v, G.UI_SCALE_MIN, G.UI_SCALE_MAX, string.format("%.2fx", v))
  end

  local function interfaceTheme()
    put("theme", "choice", G.STR.theme, G.STR["theme_" .. G.ui.theme().key])
    hint(G.STR.theme_hint)
    put("screenscale", "slider", G.STR.menusize, scaleValue("screenscale"))
    hint(G.STR.uiscale_hint)
  end

  local function interfaceHud()
    ink.head(G.STR.grp_squad_hud, "tab_squad", "sethud")
    hudToggles()
    put("hudscale", "slider", G.STR.hudscale, scaleValue("hudscale"))
    hint(G.STR.uiscale_hint)
    for _, key in ipairs({ "hudx", "hudy" }) do
      put(key, "slider", G.STR[key], string.format("%.0f", G.settings[key] or G.HUD_POS[key][3]))
      hint(G.STR.hudpos_hint)
    end
    put("lookprompt", "toggle", G.STR.look_prompt, G.settings.lookPrompt and "1" or "0")
    hint(G.STR.look_prompt_hint)
  end

  local INK_PARTS = { theme = interfaceTheme, hud = interfaceHud }

  function M.inkPart(N, name)
    ink = N
    local ok, err = pcall(INK_PARTS[name])
    ink = nil
    if not ok then error(err, 0) end
  end

  local TUNE_GROUPS = {
    { head = "sec_power", keys = { "dmg", "hp" } },
    { head = "sec_mobility", keys = { "catchup", "leash", "lowhp" } },
    { head = "sec_abilities", keys = { "range", "cooldown", "recon", "medic" } },
    { head = "sec_hacks", keys = { "nethack" } },
    { head = "tab_squad", keys = { "instances", "autodismiss" } },
  }

  local function tabTuning()
    put(nil, "dim", G.STR.tune_hint, "")
    for _, group in ipairs(TUNE_GROUPS) do
      put(nil, "group", G.STR[group.head], "")
      for _, key in ipairs(group.keys) do
        local value = G.tuning.get(key)
        local shown = key == "instances" and string.format(FMT[key], math.floor(value))
          or string.format(FMT[key], value)
        local lim = G.tuning.LIMITS[key]
        put("tune|" .. key, "slider", G.STR[TUNE_LABEL[key]], sliderValue(value, lim[1], lim[2], shown))
        if key == "lowhp" or key == "medic" then hint(G.STR.tune_zero_hint) end
        if key == "instances" and value > 3 then hint(G.STR.tune_crowd) end
      end
    end
    actionsHead()
    put("tunereset", "btn", G.STR.tune_reset, "")
  end

  local SUB_BUILDERS = {
    drones = { tab_drones = subSummon, presets = inkPresets },
    upgrades = { tab_upgrades = subTree, firmware = subFirmware },
    commands = { behavior = subBehavior, cmdhacks = subHacks },
  }

  local function subList(subId)
    local list = {}
    for i, sub in ipairs(G.ui.SUBTABS[subId]) do
      if SUB_BUILDERS[subId][sub[1]] then
        list[#list + 1] = { cet = i, key = sub[1], label = G.STR[sub[2]] }
      end
    end
    return list
  end

  local function giveItem(id, okText, count)
    if G.giveItem(id, count) then
      G.notify(okText)
    else
      G.notify(G.STR.give_fail)
    end
  end

  local function setScale(key, value)
    G.settings[key] = G.clampScale(value)
    G.saveSettings()
    if key == "hudscale" then G.squad.hudRefresh() end
  end

  local function setHudPos(key, value)
    G.settings[key] = G.clampHudPos(key, value)
    G.saveSettings()
    G.squad.hudRefresh()
  end

  local function toggleSetting(key)
    G.settings[key] = not G.settings[key]
    G.saveSettings()
  end

  local function droneAction(verb, rec)
    if verb == "st" then
      G.companion.cycleStance(rec, 1)
    elseif verb == "seat" then
      G.chauffeur.cycleSeat(rec, 1)
    elseif verb == "hold" then
      G.orders.toggleHold(rec)
    elseif verb == "cam" then
      if G.dronecam.active == rec then G.dronecam.stop() else G.dronecam.start(rec) end
    elseif verb == "l" then
      local lit = G.companion.lit[rec] == true
      if not G.companion.setLight(rec, not lit) then
        G.companion.lit[rec] = nil
        G.notify(G.STR.no_light:format(G.modelOf(rec) and G.modelOf(rec).name or rec))
      end
    elseif verb == "m" then
      G.companion.setMuted(rec, not (G.companion.muted[rec] == true))
    elseif verb == "hol" then
      G.companion.setHolstered(rec, not G.companion.isHolstered(rec), true)
    elseif verb == "x" then
      G.companion.dismiss(rec)
    elseif verb == "rep" then
      G.companion.repair(rec)
    end
  end

  local function select(id)
    local index = tonumber(id:match("^sum|(%d+)$"))
    if index then G.ui.selectedIndex = index end
  end

  local function activate(id)
    if id == "squadwin" or id == "squadattach" then
      G.inkmenu.detachSquad(id == "squadwin")
      return
    end
    if id == "pkgo" then
      local p = M.picker
      if p then
        local facKey = G.chassisOf(p.fam).factions[p.fac].key
        local armKey = p.opts[p.arm] or "default"
        M.closePicker()
        G.shard.craftConfirm(p.fam, facKey, armKey)
      end
      return
    elseif id == "pkx" then
      M.closePicker()
      return
    end
    if id == "dismissall" then
      G.companion.dismissAll()
    elseif id == "immersive" then
      toggleSetting("immersive")
    elseif id == "auto" then
      toggleSetting("autoAbilities")
    elseif id == "autoholster" then
      toggleSetting("autoHolster")
    elseif id == "protectv" then
      toggleSetting("protectV")
    elseif id == "recon" then
      toggleSetting("recon")
    elseif id == "lookprompt" then
      toggleSetting("lookPrompt")
    elseif id == "hijackbosses" then
      toggleSetting("hijackBosses")
    elseif id == "holsterall" then
      G.companion.toggleHolsterAll()
    elseif id == "mecharmor" then
      toggleSetting("mechArmor")
      G.records.applyMechArmor()
    elseif id == "androidheads" then
      toggleSetting("androidHeads")
      G.records.applyAndroidHeads()
    elseif id == "explosive" then
      toggleSetting("explosive")
    elseif id == "hud" then
      toggleSetting("hud")
    elseif id == "rigger" then
      toggleSetting("rigger")
    elseif id == "spawnbehind" then
      toggleSetting("spawnBehind")
    elseif id == "matchfacing" then
      toggleSetting("matchFacing")
    elseif id == "minimap" then
      toggleSetting("minimap")
    elseif id == "androidhacks" then
      toggleSetting("androidHacks")
    elseif id == "camhacks" then
      toggleSetting("camHacks")
    elseif id == "chassis" then
      cycleChassis(1)
    elseif id == "faction" then
      cycleFaction(1)
    elseif id == "skin" then
      G.skins.cycle(selModel(), 1)
    elseif id == "stealthghost" then
      toggleSetting("stealthGhost")
    elseif id == "scanfocus" then
      toggleSetting("scanFocus")
    elseif id == "androidloot" then
      toggleSetting("androidLoot")
    elseif id == "dronesimmortal" then
      toggleSetting("dronesImmortal")
      G.companion.applyImmortalAll()
    elseif id == "spawnmuted" then
      toggleSetting("spawnMuted")
    elseif id == "hijackrel" then
      G.hijack.releaseAll()
    elseif id == "respec" then
      G.perks.respec()
    elseif id == "tunereset" then
      G.tuning.reset()
    elseif id == "regroup" then
      G.orders.release()
    elseif id == "towp" then
      G.orders.toWaypoint()
    elseif id == "chboard" then
      G.chauffeur.board()
    elseif id == "chdrive" then
      G.chauffeur.drive()
    elseif id == "chpickup" then
      G.chauffeur.pickup()
    elseif id == "chrelease" then
      G.chauffeur.release()
    elseif id == "chradio" then
      G.chauffeur.radio()
    elseif id == "chradionext" then
      G.chauffeur.radioNext()
    elseif id == "chwindows" then
      G.chauffeur.windows()
    elseif id == "chdoors" then
      G.chauffeur.doors()
    elseif id == "chattack" then
      G.chauffeur.passengerAttack()
    elseif id == "chenter" then
      G.chauffeur.enter()
    elseif id == "giveshard" then
      giveItem(G.shardId(selModel().chassis), G.STR.give_shard_ok)
    elseif id == "takeshard" then
      G.notify(G.takeItem(G.shardId(selModel().chassis), 1) and G.STR.take_ok or G.STR.give_fail)
    elseif id == "screenscale" then
      setScale("screenscale", 1.0)
    elseif id == "hudscale" then
      setScale("hudscale", 1.0)
    elseif id == "hudx" or id == "hudy" then
      setHudPos(id, G.HUD_POS[id][3])
    else
      local verb, rest = id:match("^(%a+)|(.+)$")
      if verb == "give" then
        giveItem(G.TDB .. rest, G.STR.give_ok)
      elseif verb == "sum" then
        select(id)
        G.companion.summon(G.ui.selectedIndex)
      elseif verb == "pload" then
        G.squad.loadPreset(tonumber(rest) or 0)
      elseif verb == "psave" then
        G.squad.savePreset(tonumber(rest) or 0)
      elseif verb == "perk" then
        G.perks.buy(rest)
      elseif verb == "tune" then
        G.tuning.set(rest, G.tuning.DEFAULTS[rest])
      elseif verb == "skinok" then
        local p = picks["skin|" .. rest]
        picks["skin|" .. rest] = nil
        if p and p.value ~= G.settings.skins[rest] then G.skins.setFor(rest, p.value) end
      elseif verb == "gwok" then
        local p = picks["gw|" .. rest]
        picks["gw|" .. rest] = nil
        if p and p.value ~= (G.companion.weaponOf[rest] or G.settings.loadout) then G.armory.set(rest, p.value) end
      elseif verb == "hack" then
        G.hacks.setOn(rest, not G.hacks.isOn(rest))
      elseif verb then
        droneAction(verb, rest)
      end
    end
  end

  local function adjust(id, step)
    if M.picker then
      local p = M.picker
      if id == "pkfac" then
        local n = #G.chassisOf(p.fam).factions
        p.fac = (p.fac - 1 + step) % n + 1
      elseif id == "pkarm" then
        local n = #p.opts
        p.arm = (p.arm - 1 + step) % n + 1
      end
      return
    end
    if id == "chassis" then
      cycleChassis(step)
    elseif id == "faction" then
      cycleFaction(step)
    elseif id == "skin" then
      G.skins.cycle(selModel(), step)
    elseif id == "screenscale" or id == "hudscale" then
      setScale(id, (G.settings[id] or 1.0) + G.UI_SCALE_STEP * step * G.native.by())
    elseif id == "hudx" or id == "hudy" then
      setHudPos(id, (G.settings[id] or G.HUD_POS[id][3]) + 40.0 * step * G.native.by())
    elseif id == "loadout" then
      cycleLoadout(step)
    elseif id == "autosummon" then
      G.settings.autoSummon = ((G.settings.autoSummon or 0) + step) % (G.squad.SLOTS + 1)
      G.saveSettings()
    elseif id == "theme" then
      G.ui.cycleTheme(step)
    elseif id == "immersive" or id == "auto" or id == "explosive" or id == "hud"
      or id == "spawnbehind" or id == "matchfacing" or id == "minimap"
      or id == "rigger" or id == "androidhacks" or id == "mecharmor" or id == "camhacks"
      or id == "autoholster" or id == "stealthghost" or id == "scanfocus" or id == "androidloot"
      or id == "dronesimmortal" or id == "spawnmuted" or id == "protectv" or id == "recon" or id == "lookprompt"
      or id == "hijackbosses"
      or id == "androidheads" then
      activate(id)
    else
      local verb, key = id:match("^(%a+)|(.+)$")
      if verb == "tune" then
        G.tuning.set(key, G.tuning.get(key) + STEP[key] * step * G.native.by())
      elseif verb == "perk" then
        if step > 0 then G.perks.buy(key) else G.perks.refund(key) end
      elseif verb == "sum" then
        select(id)
      elseif verb == "st" then
        G.companion.cycleStance(key, step)
      elseif verb == "skin" then
        picks[id] = { value = G.skins.nextFor(key, pickOf(id, G.settings.skins[key]), step) }
      elseif verb == "seat" then
        G.chauffeur.cycleSeat(key, step)
      elseif verb == "gw" then
        picks[id] = { value = G.armory.nextKey(pickOf(id, G.companion.weaponOf[key] or G.settings.loadout), step) }
      elseif verb == "hack" then
        activate(id)
      elseif verb == "give" then
        local n = G.native.by()
        if step > 0 then
          giveItem(G.TDB .. key, G.STR.give_ok, n)
        else
          G.notify(G.takeItem(G.TDB .. key, n) and G.STR.take_ok or G.STR.give_fail)
        end
      end
    end
  end


  local COLKEY = { combat = "1", support = "2", utility = "3", title = "4" }
  local FWITEM = { combat = "UpCombat", support = "UpSupport", utility = "UpUtility" }

  function M.gridPayload()
    rows = {}
    local head = {
      "M\tgrid",
      "T\t" .. G.STR.tab_upgrades,
      "A\t0",
      "F\t",
      table.concat({ "H", G.STR.hint_apply, "", "", G.STR.hint_close }, "\t"),
      string.format("S\t%.2f", G.settings.screenscale or 1.0),
      string.format("C\t%.2f\t%.2f\t%.2f", G.ui.theme().accent[1], G.ui.theme().accent[2], G.ui.theme().accent[3]),
    }
    local ok, err = pcall(function()
      put(nil, "gridhead", "", table.concat({
        G.perks.available(), G.perks.total(),
        G.tuning.upCount("UpCombat") + G.tuning.upCount("UpSupport")
          + G.tuning.upCount("UpUtility") }, "|"))
      for _, col in ipairs(G.perks.COLUMNS) do
        local first = true
        for _, perk in ipairs(G.perks.PERKS) do
          if perk.col == col then
            local rank, max = G.perks.rank(perk.key), #perk.values
            local eff = G.perks.effRank(perk.key)
            local cur = rank > 0 and G.ui.perkDesc(perk, rank) or ""
            local nxt = rank < max and G.ui.perkDesc(perk, rank + 1) or ""
            local total = eff > rank and eff > 0
              and string.format(G.STR.eff_total, G.ui.perkDesc(perk, eff)) or ""
            put("perk|" .. perk.key, "cell", G.STR["pk_" .. perk.key],
              table.concat({ rank, max, eff, COLKEY[col],
                cur ~= "" and cur or "-", nxt ~= "" and nxt or "-",
                first and G.STR["col_" .. col] or "-",
                (first and FWITEM[col]) and G.tuning.upCount(FWITEM[col]) or "-",
                total ~= "" and total or "-" }, "|"))
            first = false
          end
        end
      end
      put("respec", "cell", G.STR.respec,
        table.concat({ 0, 0, 0, "3", G.STR.respec_hint, "-", "-", "-" }, "|"))
    end)
    if not ok then
      rows = {}
      put(nil, "warn", tostring(err), "")
    end
    return table.concat(head, "\n") .. "\n" .. table.concat(rows, "\n")
  end

  local function pickerPayload()
    local p = M.picker
    local ch = G.chassisOf(p.fam)
    rows = {}
    local head = {
      "T\t" .. ch.name,
      "M\tpicker",
      "A\t0",
      "F\t",
      table.concat({ "H", G.STR.hint_use, G.STR.hint_value, "", G.STR.hint_close }, "\t"),
      string.format("S\t%.2f", G.settings.screenscale or 1.0),
      string.format("C\t%.2f\t%.2f\t%.2f", G.ui.theme().accent[1], G.ui.theme().accent[2], G.ui.theme().accent[3]),
    }
    put(nil, "head", string.format(G.STR.pk_title, ch.name), "", p.fam:lower())
    put(nil, "dim", G.STR.pk_hint, "")
    put("pkfac", "choice", G.STR.faction, ch.factions[p.fac].name)
    if p.fam == "Android" then
      put("pkarm", "choice", G.STR.loadout, G.armory.label(p.opts[p.arm]))
    end
    put("pkgo", "btn", G.STR.pk_go, "*")
    put("pkx", "btn", G.STR.pk_cancel, "!")
    return table.concat(head, "\n") .. "\n" .. table.concat(rows, "\n")
  end

  function M.openPicker(fam)
    local ch = G.chassisOf(fam)
    local player = Game.GetPlayer()
    if not ch or not player then return end
    M.picker = { fam = fam, fac = 1, arm = 1, opts = G.armory.options(true) }
    M.mode = "picker"
    if M.open then
      M.push()
    else
      local ok, res = pcall(function() return player:DCToggleMenu(pickerPayload()) end)
      M.open = ok and res == true
      if not M.open then
        M.picker = nil
        M.mode = "rows"
      end
    end
  end

  function M.closePicker()
    M.picker = nil
    M.mode = "rows"
    if M.open then
      local player = Game.GetPlayer()
      if player then pcall(function() player:DCToggleMenu("") end) end
      M.open = false
    end
  end

  function M.toggleGrid()
    local player = Game.GetPlayer()
    if not player then return end
    M.mode = "grid"
    pcall(function() player:DCToggleMenu(M.gridPayload()) end)
  end

  function M.pushGrid()
    local player = Game.GetPlayer()
    if not player then return end
    pcall(function() player:DCPushState(M.gridPayload()) end)
  end

  local TOGGLE_KEY
  local function toggleKey(id)
    if not TOGGLE_KEY then
      TOGGLE_KEY = {}
      local keys = { "hud", "minimap", "mechArmor", "androidHeads", "lookPrompt" }
      for _, grp in ipairs(G.ui.BEHAVIOR_GROUPS) do
        for _, row in ipairs(grp[2]) do keys[#keys + 1] = row[1] end
      end
      for _, list in ipairs({ G.ui.ACQUISITION, G.ui.HACK_ENEMIES }) do
        for _, row in ipairs(list) do keys[#keys + 1] = row[1] end
      end
      for _, key in ipairs(keys) do TOGGLE_KEY[f8Id(key)] = key end
    end
    return TOGGLE_KEY[id]
  end

  local SETTING_OF = { theme = "theme", autosummon = "autoSummon", loadout = "loadout",
    screenscale = "screenscale", hudscale = "hudscale", hudx = "hudx", hudy = "hudy" }

  optionState = function(id)
    if type(id) ~= "string" then return nil end
    local tune = id:match("^tune|(.+)$")
    if tune then return G.tuning.get(tune), G.tuning.DEFAULTS[tune] end
    local hack = id:match("^hack|(.+)$")
    if hack then return G.hacks.isOn(hack), true end
    local key = toggleKey(id) or SETTING_OF[id]
    if not key then return nil end
    local cur = G.settings[key]
    if cur == nil then cur = G.DEFAULTS[key] end
    return cur, G.DEFAULTS[key]
  end

  M.optionState = function(id) return optionState(id) end

  function M.settingKey(id)
    if type(id) ~= "string" then return nil end
    if id:find("^tune|") or id:find("^hack|") then return id end
    return toggleKey(id) or SETTING_OF[id]
  end

  local function setValue(id, value)
    local tune = id:match("^tune|(.+)$")
    if tune then
      G.tuning.set(tune, value)
      return true
    end
    if id == "screenscale" or id == "hudscale" then
      setScale(id, value)
      return true
    end
    if id == "hudx" or id == "hudy" then
      setHudPos(id, value)
      return true
    end
    local item = id:match("^give|(.+)$")
    if not item then return false end
    local have = G.tuning.upCount(item)
    local want = math.min(math.max(0, math.floor(value + 0.5)), 9999)
    if want > have then
      giveItem(G.TDB .. item, G.STR.give_ok, want - have)
    elseif want < have then
      G.notify(G.takeItem(G.TDB .. item, have - want) and G.STR.take_ok or G.STR.give_fail)
    end
    return true
  end

  local armed = {}

  local function confirmed(id)
    if armed.id == id and os.clock() - (armed.at or 0) < 3.0 then
      armed = {}
      return true
    end
    armed = { id = id, at = os.clock() }
    return false
  end

  local function presetUid(id)
    return tonumber(tostring(id):match("^pre|u(%d+)$") or "")
  end

  local function presetLabels()
    local out = {}
    for _, o in ipairs(G.inkmenu.options) do
      local key = M.settingKey(o.row.id)
      if key and not out[key] then out[key] = o.row.label end
    end
    return function(k) return out[k] end
  end

  local function presetDelete(id)
    local uid = presetUid(id)
    if not uid then return end
    if confirmed("del|" .. id) then
      G.presets.delete(uid)
    else
      local p = G.presets.find(uid)
      G.hotkeys.toast((p and p.name or "") .. ": " .. G.STR.presetdelete .. "? " .. G.STR.pressagain, true)
    end
  end

  local function presetsTab(N)
    local labelOf = presetLabels()
    N.head(G.STR.presetstab, "tab_presets", "presets")
    for _, p in ipairs(G.settings.presets) do
      local id = "pre|u" .. p.uid
      local waiting = armed.id == id and os.clock() - (armed.at or 0) < 3.0
      N.row("btn", id, p.name, waiting and ("!" .. G.STR.pressagain) or G.STR.presetapply,
        G.presets.describe(p, labelOf) .. " " .. (G.inkmenu.pad and G.STR.presethintpad or G.STR.presethint)).rename = true
    end
    N.head(G.STR.presetnew, "presetnew", "presetnew")
    N.row("btn", "presave", G.STR.presetsave, "", G.STR.presetsavehint)
    N.row("btn", "prepaste", G.STR.presetpaste, "", G.STR.presetpastehint)
    if #G.settings.presets > 0 then
      N.head(G.STR.presetload, "tab_presets", "presetload")
      N.row("choice", "presetauto", G.STR.presetauto, G.presets.autoName() or G.STR.off, G.STR.presetautohint).changed =
        (G.settings.presetauto or 0) ~= 0
      for _, p in ipairs(G.settings.presets) do
        N.row("btn", "precopy|u" .. p.uid, p.name, G.STR.presetcopy, G.STR.presetcopyhint)
      end
    end
  end

  local function resetOption(id)
    local cur, def = optionState(id)
    if def == nil or same(cur, def) then return end
    local tune = id:match("^tune|(.+)$")
    if tune then
      G.tuning.set(tune, def)
    elseif id:find("^hack|") then
      G.hacks.setOn(id:sub(6), true)
    elseif toggleKey(id) or id == "screenscale" or id == "hudscale" or id == "hudx" or id == "hudy" then
      activate(id)
    elseif id == "loadout" then
      setLoadout(def)
    else
      G.settings[SETTING_OF[id]] = def
      G.saveSettings()
    end
  end

  local INK_TABS = {
    { key = "tab_drones", sub = "drones" },
    { key = "tab_squad", build = tabSquad },
    { key = "tab_upgrades", sub = "upgrades" },
    { key = "tab_commands", sub = "commands" },
    { key = "tab_tuning", build = tabTuning },
  }

  function M.registerInk(N)
    N.onMove = function() editing = nil end
    local search = N.state("tab_search")
    N.tab("tab_search", function() return G.STR.tab_search end, function()
      N.search("q", G.STR.opt_search, search.q or "", G.STR.opt_search_hint)
    end, { text = function(_, value) search.q = value end })
    N.tab("tab_active", function() return G.STR.tab_active end, function()
      local n = #G.inkmenu.active()
      if n > 0 then N.row("btn", "alloff", G.STR.activeoff, tostring(n), G.STR.activehint) end
    end, { act = function(id) if id == "alloff" then G.inkmenu.activeOff() end end })
    N.tab("tab_fav", function() return G.STR.favtab end, function() end, {})
    N.tab("tab_presets", function() return G.STR.presetstab end, function() presetsTab(N) end, {
      act = function(id)
        if id == "presave" then
          G.presets.save()
          return
        end
        if id == "prepaste" then
          G.inkmenu.paste(G.presets.import)
          return
        end
        if id == "presetauto" then
          G.presets.stepAuto(1)
          return
        end
        local copyUid = tonumber(tostring(id):match("^precopy|u(%d+)$") or "")
        if copyUid then
          G.presets.export(copyUid)
          return
        end
        local uid = presetUid(id)
        if not uid then return end
        if G.hotkeys.running or confirmed(id) then
          G.presets.apply(uid)
        else
          G.hotkeys.toast(G.STR.pressagain, true)
        end
      end,
      inc = function(id) if id == "presetauto" then G.presets.stepAuto(1) else presetDelete(id) end end,
      dec = function(id) if id == "presetauto" then G.presets.stepAuto(-1) else presetDelete(id) end end,
      reset = function(id)
        if id == "presetauto" then
          G.settings.presetauto = 0
          G.saveMenuData()
        end
      end,
      rename = function(id, text)
        local uid = presetUid(id)
        if uid then G.presets.rename(uid, text) end
      end,
    })
    local handlers = {
      act = function(id)
        if id:find("^nm|") or id:find("^pn|") then
          editing = editing ~= id and id or nil
        else
          activate(id)
        end
      end,
      text = function(id, value)
        local rec = id:match("^nm|(.+)$")
        local slot = tonumber(id:match("^pn|(%d+)$") or "")
        if rec then
          G.squad.setName(rec, value)
        elseif slot then
          G.squad.setPresetName(slot, value)
        end
      end,
      inc = function(id) adjust(id, 1) end,
      dec = function(id) adjust(id, -1) end,
      reset = resetOption,
      set = setValue,
    }
    M.inkHandlers = handlers
    for _, spec in ipairs(INK_TABS) do
      local subs
      if spec.sub then
        subs = function()
          local out = {}
          for _, sub in ipairs(subList(spec.sub)) do out[#out + 1] = sub.label end
          return out
        end
      end
      local function build()
        local fn = spec.build
        if spec.sub then
          local list = subList(spec.sub)
          local entry = list[N.sub(spec.key)] or list[1]
          fn = SUB_BUILDERS[spec.sub][entry.key]
        end
        ink = N
        local ok, err = pcall(fn)
        ink = nil
        if not ok then error(err, 0) end
      end
      N.tab(spec.key, function() return G.STR[spec.key] end, build, handlers, subs)
    end
  end

  function M.push()
    if not M.open then return end
    local player = Game.GetPlayer()
    if not player then return end
    local body
    if M.mode == "grid" then
      body = M.gridPayload()
    elseif M.mode == "picker" and M.picker then
      body = pickerPayload()
    end
    if body then pcall(function() player:DCPushState(body) end) end
  end

  function M.install()
    Observe("PlayerPuppet", "DCEmit", function(_, action)
      action = tostring(action)
      local verb, id = action:match("^(%a+):(.+)$")
      if verb == "act" or verb == "inc" or verb == "dec" then
        local now = os.clock()
        if M.lastAct == action and now - (M.lastActAt or 0) < 0.25 then
          return
        end
        M.lastAct, M.lastActAt = action, now
      end
      if verb == "open" then
        M.toggleGrid()
        return
      end
      if verb == "shard" then
        G.shard.summonByChassis(id)
        return
      end
      if verb == "menu" then
        M.open = id == "open"
        if not M.open then
          M.mode = "rows"
          M.picker = nil
        end
        return
      end
      if verb == "sel" then
        select(id)
      elseif verb == "act" then
        activate(id)
      elseif verb == "inc" then
        adjust(id, 1)
      elseif verb == "dec" then
        adjust(id, -1)
      else
        G.log("menu " .. action)
        return
      end
      M.push()
    end)
    G.Cron.Every(0.25, function() M.push() end)
  end

  return M
end
