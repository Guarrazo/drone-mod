return function(G)
  local settings, STR = G.settings, G.STR
  local P = {}
  local SKIP = { enabled = true, notify = true, menubg = true, menukey = true, padcombo = true, padopen = true,
    squadwin = true, descbox = true, langpick = true, screenscale = true, theme = true, hud = true,
    minimap = true, hudscale = true, hudx = true, hudy = true, lookPrompt = true, keyhints = true, statusind = true,
    indpos = true, pausemenu = true, pausenotice = true, vibrate = true, presetauto = true }

  local function copy(tbl)
    local out = {}
    for k, v in pairs(tbl or {}) do out[k] = v end
    return out
  end

  local function keys()
    local out = {}
    for k in pairs(G.DEFAULTS) do
      if not SKIP[k] then out[#out + 1] = k end
    end
    table.sort(out)
    return out
  end

  function P.find(uid)
    for i, p in ipairs(settings.presets) do
      if p.uid == uid then return p, i end
    end
  end

  function P.save()
    local used, uid = {}, 1
    for _, p in ipairs(settings.presets) do
      used[p.name] = true
      uid = math.max(uid, (p.uid or 0) + 1)
    end
    local n = #settings.presets + 1
    while used[STR.preset .. " " .. n] do n = n + 1 end
    local values = {}
    for _, k in ipairs(keys()) do
      if settings[k] ~= G.DEFAULTS[k] then values[k] = settings[k] end
    end
    local p = { name = STR.preset .. " " .. n, uid = uid, values = values,
      tuning = copy(G.tuning.global), hacksoff = copy(settings.hacksOff) }
    settings.presets[#settings.presets + 1] = p
    G.saveMenuData()
    G.hotkeys.toast(STR.presetsaved .. ": " .. p.name, true)
  end

  function P.apply(uid)
    local p = P.find(uid)
    if not p then return end
    for _, k in ipairs(keys()) do
      local v = p.values[k]
      if v == nil or type(v) ~= type(G.DEFAULTS[k]) then v = G.DEFAULTS[k] end
      settings[k] = v
    end
    G.tuning.global = {}
    for k, v in pairs(p.tuning or {}) do
      if G.tuning.DEFAULTS[k] ~= nil and type(v) == "number" then G.tuning.global[k] = G.tuning.clamp(k, v) end
    end
    for _, hack in ipairs(G.hacks.HACKS) do
      local on = not (p.hacksoff or {})[hack.key]
      if G.hacks.isOn(hack.key) ~= on then G.hacks.setOn(hack.key, on) end
    end
    G.saveSettings()
    G.applySettings()
    G.companion.applyImmortalAll()
    G.hotkeys.toast(STR.preset .. ": " .. p.name, true)
  end

  function P.rename(uid, name)
    local p = P.find(uid)
    name = tostring(name or ""):gsub("[\t\n\r|\"\\]", " "):match("^%s*(.-)%s*$")
    if not p or name == "" then return end
    p.name = name:sub(1, 48)
    G.saveMenuData()
  end

  function P.delete(uid)
    local p, i = P.find(uid)
    if not p then return end
    table.remove(settings.presets, i)
    if settings.presetauto == uid then settings.presetauto = 0 end
    local suffix = "|pre|u" .. uid
    local function bound(k) return k:sub(-#suffix) == suffix end
    for j = #settings.favrows, 1, -1 do
      if bound(settings.favrows[j]) then table.remove(settings.favrows, j) end
    end
    for k in pairs(settings.padkeys) do
      if bound(k) then settings.padkeys[k] = nil end
    end
    for k in pairs(settings.hotkeys) do
      if bound(k) then settings.hotkeys[k] = nil end
    end
    G.saveSettings()
    G.saveMenuData()
    G.hotkeys.toast(p.name .. ": " .. STR.presetdeleted, true)
  end

  local CODE = "DC-PRESET:"

  function P.export(uid)
    local p = P.find(uid)
    if not p then return end
    local ok, text = pcall(function()
      local out = json.encode({ n = p.name, v = p.values, t = p.tuning, h = p.hacksoff })
      return out
    end)
    if ok and text then G.copyLink(CODE .. text, STR.presetcopied) end
  end

  local function numbers(tbl, valid)
    local out = {}
    for k, v in pairs(type(tbl) == "table" and tbl or {}) do
      if type(k) == "string" and valid(k, v) then out[k] = v end
    end
    return out
  end

  function P.import(text)
    local body = tostring(text or ""):match("DC%-PRESET:(.+)$")
    local ok, data = pcall(function()
      local d = json.decode(body)
      return d
    end)
    if not body or not ok or type(data) ~= "table" or type(data.v) ~= "table" then
      G.hotkeys.toast(STR.presetbad, true)
      return
    end
    local allowed = {}
    for _, k in ipairs(keys()) do allowed[k] = true end
    local uid = 1
    for _, p in ipairs(settings.presets) do uid = math.max(uid, (p.uid or 0) + 1) end
    local name = tostring(data.n or ""):gsub("[\t\n\r|\"\\]", " "):match("^%s*(.-)%s*$")
    if name == "" then name = STR.preset .. " " .. (#settings.presets + 1) end
    local p = { name = name:sub(1, 48), uid = uid,
      values = numbers(data.v, function(k, v) return allowed[k] and type(v) == type(G.DEFAULTS[k]) end),
      tuning = numbers(data.t, function(k, v) return G.tuning.DEFAULTS[k] ~= nil and type(v) == "number" end),
      hacksoff = numbers(data.h, function(_, v) return v == true end) }
    settings.presets[#settings.presets + 1] = p
    G.saveMenuData()
    G.hotkeys.toast(STR.presetpasted .. ": " .. p.name, true)
  end

  function P.autoName()
    local p = P.find(settings.presetauto)
    return p and p.name or nil
  end

  function P.stepAuto(dir)
    local list = { 0 }
    for _, p in ipairs(settings.presets) do list[#list + 1] = p.uid end
    local at = 1
    for i, uid in ipairs(list) do if uid == settings.presetauto then at = i end end
    settings.presetauto = list[((at - 1 + dir) % #list) + 1]
    G.saveMenuData()
  end

  function P.describe(p, labelOf)
    local names = {}
    for k, v in pairs(p.values) do
      local label = labelOf(k)
      if label then
        local shown = k == "loadout" and G.armory.label(v) or tostring(v)
        if type(v) == "boolean" then shown = v and STR.on or STR.off end
        names[#names + 1] = label .. " " .. shown
      end
    end
    for k in pairs(p.tuning or {}) do
      local label = labelOf("tune|" .. k)
      if label then names[#names + 1] = label end
    end
    for k in pairs(p.hacksoff or {}) do
      local label = labelOf("hack|" .. k)
      if label then names[#names + 1] = label .. " " .. STR.off end
    end
    table.sort(names)
    if #names == 0 then return STR.presetempty end
    return table.concat(names, ", ") .. "."
  end

  return P
end
