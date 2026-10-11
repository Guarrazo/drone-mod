return function(G)
  local Cron = G.Cron
  local M = { names = {}, kills = {}, deaths = {}, presets = {}, presetNames = {}, SLOTS = 5,
    lastHp = {}, fireUntil = {} }

  local FILE = "squad_state.lua"

  local function sanitize(s)
    return tostring(s or ""):gsub('[%c"\\]', ""):sub(1, 24)
  end

  local function loadState()
    local f = io.open(FILE, "r")
    if not f then return false end
    local raw = f:read("*a") or ""
    f:close()
    local chunk = (loadstring or load)(raw)
    if not chunk then return false end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then return false end
    M.load(data)
    return true
  end

  function M.save()
    local names, presets = {}, {}
    for rec, name in pairs(M.names) do
      if not (G.hijack and G.hijack.is(rec)) then names[rec] = name end
    end
    for slot = 1, M.SLOTS do
      local p = M.presets[slot]
      if p then
        local entries = {}
        for _, e in ipairs(p) do
          entries[#entries + 1] = { key = e.key, stance = e.stance,
            weapon = e.weapon or "default", skin = e.skin }
        end
        presets[slot] = entries
      end
    end
    local presetNames = {}
    for slot = 1, M.SLOTS do presetNames[slot] = M.presetNames[slot] end
    return { names = names, presets = presets, presetNames = presetNames }
  end

  function M.load(data)
    if type(data) ~= "table" or (next(data.names or {}) == nil
      and next(data.presets or {}) == nil and next(data.presetNames or {}) == nil) then
      if M.pendingMigration then return end
      M.names, M.presets, M.presetNames = {}, {}, {}
      return
    end
    M.pendingMigration = nil
    M.names, M.presets, M.presetNames = {}, {}, {}
    if type(data.presetNames) == "table" then
      for slot = 1, M.SLOTS do
        if type(data.presetNames[slot]) == "string" then
          local clean = sanitize(data.presetNames[slot])
          if clean ~= "" then M.presetNames[slot] = clean end
        end
      end
    end
    if type(data.names) == "table" then
      for rec, name in pairs(data.names) do
        if type(rec) == "string" and type(name) == "string" then
          M.names[rec] = sanitize(name)
        end
      end
    end
    if type(data.presets) == "table" then
      for slot = 1, M.SLOTS do
        local p = data.presets[slot]
        if type(p) == "table" and #p > 0 then
          local entries = {}
          for _, e in ipairs(p) do
            if type(e) == "table" and type(e.key) == "string" then
              entries[#entries + 1] = { key = e.key,
                stance = tostring(e.stance or "combat"),
                weapon = tostring(e.weapon or "default"),
                skin = type(e.skin) == "string" and e.skin or nil }
            end
          end
          if #entries > 0 then M.presets[slot] = entries end
        end
      end
    end
  end

  local function migrate()
    if not loadState() then return end
    os.rename(FILE, FILE .. ".migrated")
    M.pendingMigration = true
    G.log("squad names/presets migrated from " .. FILE .. " to the save file")
  end
  migrate()

  local function instanceOf(rec, model)
    local prefix = G.TDB .. model.key
    if type(rec) ~= "string" or rec:sub(1, #prefix) ~= prefix then return nil end
    return tonumber(rec:sub(#prefix + 1))
  end

  local function activeOfModel(model)
    local n = 0
    if G.companion and G.companion.eachActive then
      G.companion.eachActive(function(_, _, m) if m and m.key == model.key then n = n + 1 end end)
    end
    return n
  end

  function M.displayName(rec, model)
    if M.names[rec] then return M.names[rec] end
    if not model then return rec end
    local n = not model.hijack and model.key and instanceOf(rec, model)
    if n and activeOfModel(model) > 1 then return model.name .. " " .. n end
    return model.name
  end

  function M.setName(rec, name)
    local clean = sanitize(name)
    M.names[rec] = clean ~= "" and clean or nil
  end

  function M.setPresetName(slot, name)
    local clean = sanitize(name):gsub("[|=]", "")
    M.presetNames[slot] = clean ~= "" and clean or nil
    if G.pushPhoneChoices then G.pushPhoneChoices() end
  end

  function M.presetLabel(slot)
    return M.presetNames[slot] or string.format(G.STR.preset_slot, slot)
  end

  function M.killsOf(rec)
    return M.kills[rec] or 0
  end

  M.RANKS = {
    { kills = 25, key = "rank_veteran", bonus = 0.05 },
    { kills = 75, key = "rank_elite", bonus = 0.10 },
    { kills = 200, key = "rank_legend", bonus = 0.15 },
  }

  function M.rankOf(rec)
    local kills = M.killsOf(rec)
    local found = nil
    for _, r in ipairs(M.RANKS) do
      if kills >= r.kills then found = r end
    end
    return found
  end

  function M.rankBonus(rec)
    local r = M.rankOf(rec)
    return r and r.bonus or 0
  end

  function M.deathsOf(rec)
    return M.deaths[rec] or 0
  end

  function M.onDeath(rec)
    M.deaths[rec] = (M.deaths[rec] or 0) + 1
    G.log(string.format("death %s total=%d kills=%d", rec, M.deaths[rec], M.killsOf(rec)))
  end

  function M.kdLabel(rec)
    local d = M.deathsOf(rec)
    if d == 0 then return nil end
    return string.format(G.STR.sq_kd, M.killsOf(rec) / d)
  end

  function M.underFire(rec, pct)
    local now = os.clock()
    local last = M.lastHp[rec]
    if last and pct < last - 0.5 then M.fireUntil[rec] = now + 3.0 end
    M.lastHp[rec] = pct
    return (M.fireUntil[rec] or 0) > now
  end

  function M.rankLabel(rec)
    local r = M.rankOf(rec)
    return r and G.STR[r.key] or nil
  end

  local function promote(row, before, after)
    local mult = (1 + after.bonus) / (1 + (before and before.bonus or 0))
    local ok, err = pcall(function()
      local ss = Game.GetStatsSystem()
      local id = row.ent:GetEntityID()
      ss:AddModifier(id, RPGManager.CreateStatModifier(gamedataStatType.Health,
        gameStatModifierType.Multiplier, mult))
      ss:AddModifier(id, RPGManager.CreateStatModifier(gamedataStatType.NPCDamage,
        gameStatModifierType.Multiplier, mult))
    end)
    G.log(string.format("rank up %s: %s kills=%d mult=%.3f ok=%s %s", row.rec, after.key,
      M.killsOf(row.rec), mult, tostring(ok), ok and "" or tostring(err)))
    G.notify(string.format(G.STR.rank_up, M.displayName(row.rec, row.model), G.STR[after.key]))
  end

  function M.onKill(drone)
    if not IsDefined(drone) then return end
    local rows = G.companion.aliveCache
    if not rows then return end
    local key = G.companion.entKey(drone)
    for _, row in ipairs(rows) do
      if IsDefined(row.ent) and G.companion.entKey(row.ent) == key then
        local before = M.rankOf(row.rec)
        M.kills[row.rec] = (M.kills[row.rec] or 0) + 1
        G.log(string.format("kill %s total=%d", row.rec, M.kills[row.rec]))
        local after = M.rankOf(row.rec)
        if after ~= before then promote(row, before, after) end
        return
      end
    end
  end

  local function chassisName(key)
    for _, ch in ipairs(G.CHASSIS) do
      if ch.key == key then return ch.name end
    end
    return key
  end

  local function modelByKey(key)
    for i, model in ipairs(G.MODELS) do
      if model.key == key then return model, i end
    end
    return nil
  end

  function M.presetSummary(slot)
    local p = M.presets[slot]
    if not p then return G.STR.preset_empty end
    local counts, order = {}, {}
    for _, e in ipairs(p) do
      local model = modelByKey(e.key)
      local label = model and chassisName(model.chassis) or e.key
      if not counts[label] then order[#order + 1] = label end
      counts[label] = (counts[label] or 0) + 1
    end
    local bits = {}
    for _, label in ipairs(order) do
      bits[#bits + 1] = counts[label] > 1
        and string.format("%dx %s", counts[label], label) or label
    end
    return table.concat(bits, ", ")
  end

  function M.savePreset(slot)
    local rows = G.companion.aliveCache
    if not rows or #rows == 0 then
      G.notify(G.STR.no_drone)
      return
    end
    local entries = {}
    for _, row in ipairs(rows) do
      entries[#entries + 1] = {
        key = row.model.key,
        stance = G.companion.stanceOf(row.rec),
        weapon = G.companion.weaponOf[row.rec] or "default",
        skin = G.skins.currentFor(row.rec),
      }
    end
    M.presets[slot] = entries
    if G.pushPhoneChoices then G.pushPhoneChoices() end
    G.notify(string.format(G.STR.preset_saved, M.presetLabel(slot), M.presetSummary(slot)))
  end

  M.auto = { recs = nil, calm = 0 }

  function M.autoSummonTick(inCombat, mounted)
    local a = M.auto
    local slot = G.settings.enabled ~= false and G.settings.autoSummon or 0
    if inCombat then
      a.calm = 0
      if slot > 0 and not a.recs and not mounted and M.presets[slot] and not G.companion.hasActive()
        and not G.companion.stashed and not G.companion.garage then
        a.recs = {}
        M.loadPreset(slot)
        Cron.After(4.0, function()
          if not a.recs then return end
          G.companion.eachActive(function(rec, _, model)
            if not model.hijack then a.recs[rec] = true end
          end)
        end)
      end
      return
    end
    if not a.recs then return end
    a.calm = a.calm + 1
    if a.calm < G.tuning.get("autodismiss") then return end
    local recs = a.recs
    a.recs = nil
    local out = {}
    G.companion.eachActive(function(rec) if recs[rec] then out[#out + 1] = rec end end)
    for _, rec in ipairs(out) do G.companion.dismiss(rec) end
  end

  function M.loadPreset(slot)
    local p = M.presets[slot]
    if not p then
      G.notify(string.format(G.STR.preset_none, M.presetLabel(slot)))
      return
    end
    if G.companion.stashed then
      G.notify(string.format(G.STR.hidden, #G.companion.stashed))
      return
    end
    G.companion.dismissAll(true)
    G.notify(string.format(G.STR.preset_loading, M.presetLabel(slot)))
    Cron.After(1.2, function()
      local used = {}
      local idx = 0
      for _, e in ipairs(p) do
        local model = modelByKey(e.key)
        if model then
          used[e.key] = (used[e.key] or 0) + 1
          if used[e.key] <= G.tuning.get("instances") then
            local rec = G.recordId(model, used[e.key])
            if G.settings.skins[rec] ~= e.skin then
              G.settings.skins[rec] = e.skin
              G.saveSettings()
            end
            G.companion.setStance(rec, e.stance)
            G.companion.weaponOf[rec] = e.weapon
            if G.companion.trySummon(model, rec, idx) then
              idx = idx + 1
            end
          end
        end
      end
    end)
  end

  function M.hudPayload()
    if not G.settings.hud or G.settings.enabled == false then return "" end
    local c = G.companion
    if c.stashed then return "" end
    local rows = {}
    for _, row in ipairs(c.aliveCache or {}) do rows[#rows + 1] = row end
    rows = G.arena.withFighters(rows)
    local wrecks = {}
    for rec in pairs(c.wreckUntil) do
      local ent = c.entityOf(rec)
      local model = G.modelOf(rec)
      if IsDefined(ent) and model then wrecks[#wrecks + 1] = { rec = rec, model = model } end
    end
    table.sort(wrecks, function(a, b) return a.rec < b.rec end)
    if #rows == 0 and #wrecks == 0 then return "" end
    local sps = Game.GetStatPoolsSystem()
    local lines = {}
    for _, w in ipairs(wrecks) do
      lines[#lines + 1] = table.concat({
        w.model.chassis:lower(),
        "0",
        M.displayName(w.rec, w.model),
        string.format(G.STR.hud_down, c.repairLeft(w.rec) or 0),
        "d",
      }, "\t")
    end
    for _, row in ipairs(rows) do
      if IsDefined(row.ent) then
        local pct = 0
        pcall(function()
          pct = sps:GetStatPoolValue(row.ent:GetEntityID(), "Health", true)
        end)
        local sub = G.STR["st_" .. c.stanceOf(row.rec)]
        local rank = M.rankLabel(row.rec)
        if rank then sub = sub .. " - " .. rank end
        if G.hacks.held[row.rec] then
          sub = sub .. " - " .. G.STR.held_row
        end
        local left = G.hacks.cooldownLeft(row.rec)
        if left then
          sub = sub .. string.format(" - %ds", left)
        end
        lines[#lines + 1] = table.concat({
          row.model.chassis:lower(),
          tostring(math.floor(pct + 0.5)),
          M.displayName(row.rec, row.model),
          sub,
          M.underFire(row.rec, pct) and "f" or "-",
        }, "\t")
      end
    end
    local shown = 8
    if #lines > shown then
      local hidden = #lines - (shown - 1)
      while #lines >= shown do table.remove(lines) end
      lines[#lines + 1] = table.concat({
        "", "-1", string.format(G.STR.hud_more, hidden), "",
      }, "\t")
    end
    return table.concat(lines, "\n")
  end

  function M.hudRefresh()
    local player = Game.GetPlayer()
    if not player then return end
    pcall(function() player:DCHudScale(G.settings.hudscale or 1.0) end)
    pcall(function() player:DCHudOffset(G.settings.hudx or 10.0, G.settings.hudy or 140.0) end)
    M.lastHud = nil
  end

  function M.hudTick()
    local player = Game.GetPlayer()
    if not player then return end
    local payload = M.hudPayload()
    if payload == M.lastHud then return end
    local pushed = false
    pcall(function() pushed = player:DCHudPush(payload) == true end)
    if pushed then
      M.lastHud = payload
      if not M.pushOk then
        M.pushOk = true
        pcall(function() player:DCHudScale(G.settings.hudscale or 1.0) end)
        pcall(function() player:DCHudOffset(G.settings.hudx or 10.0, G.settings.hudy or 140.0) end)
        G.log("hud push ok")
      end
    else
      M.pushFails = (M.pushFails or 0) + 1
      if M.pushFails == 10 then
        G.log("hud panel not ready after 10 pushes")
      end
    end
  end

  function M.demo()
    G.STR = G.STR or {}
    G.STR.preset_empty = "empty"
    G.CHASSIS = { { key = "Octant", name = "Octant" }, { key = "Minotaur", name = "Minotaur" } }
    G.MODELS = {
      { key = "OctantMilitech", chassis = "Octant", name = "Militech Octant" },
      { key = "MinotaurArasaka", chassis = "Minotaur", name = "Arasaka Minotaur" },
    }

    M.setName("DroneCompanion.OctantMilitech1", 'Ru"sty\\')
    assert(M.names["DroneCompanion.OctantMilitech1"] == "Rusty", "name sanitized")
    M.setName("DroneCompanion.OctantMilitech1", "")
    assert(M.names["DroneCompanion.OctantMilitech1"] == nil, "empty name clears")

    M.presets[1] = {
      { key = "OctantMilitech", stance = "combat" },
      { key = "OctantMilitech", stance = "combat" },
      { key = "MinotaurArasaka", stance = "passive" },
    }
    assert(M.presetSummary(1) == "2x Octant, Minotaur", "summary groups by chassis")
    assert(M.presetSummary(2) == "empty", "empty slot")

    M.kills = {}
    assert(M.killsOf("x") == 0, "kills default zero")
    os.remove(FILE)
    print("squad demo ok")
  end

  return M
end
