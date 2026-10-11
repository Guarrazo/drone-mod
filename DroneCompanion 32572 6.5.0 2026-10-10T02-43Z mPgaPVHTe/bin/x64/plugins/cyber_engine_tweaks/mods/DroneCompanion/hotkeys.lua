return function(G)
  local settings = G.settings
  local HK = { last = {} }
  local KINDS = { toggle = true, choice = true }
  local SKIP_TABS = { tab_search = true, tab_active = true, tab_fav = true, tab_settings = true, tab_squad = true }
  local SETTINGS_KEYS = { hud = true, minimap = true, lookprompt = true, pausegame = true, pausestep = true }
  HK.PAD = { "A", "B", "X", "Y", "LB", "RB", "L3", "R3", "D-pad up", "D-pad down", "D-pad left", "D-pad right" }
  local MODS = { command = { S = "commandfly", C = "commandground" } }

  HK.ACTIONS = {
    { "toggle", "Set-Cat-Toggle" }, { "cycle", "Set-Cat-Cycle" }, { "command", "Set-Cat-Command" },
    { "preset1", "Set-Cat-Preset1" }, { "preset2", "Set-Cat-Preset2" }, { "preset3", "Set-Cat-Preset3" },
    { "preset4", "Set-Cat-Preset4" }, { "preset5", "Set-Cat-Preset5" }, { "holster", "Set-Cat-Holster" },
    { "stanceall", "Set-Cat-StanceAll" }, { "hijack", "Set-Cat-Hijack" }, { "repair", "L-act_repair" },
    { "waypoint", "L-sq_to_wp" },
    { "regroup", "L-sq_regroup" }, { "dismissall", "L-dismiss_all" }, { "chdrive", "L-ch_drive" },
    { "chattack", "L-ch_attack" }, { "chcam", "L-ch_cam" },
  }

  function HK.actionLabel(key)
    return G.text("Mod-DroneCompanion-" .. key) or key
  end

  function HK.bind(tabKey, sub, kind, id)
    return tabKey .. "|" .. sub .. "|" .. kind .. "|" .. G.stableId(id)
  end

  function HK.label(key)
    return (tostring(key or ""):gsub("^IK_", ""))
  end

  function HK.bindable(tabKey, row)
    local id = row.id or ""
    if tabKey == "tab_settings" then return SETTINGS_KEYS[id] == true end
    if tabKey == "tab_presets" then return id:find("^pre|u%d+$") ~= nil end
    return not SKIP_TABS[tabKey] and KINDS[row.kind] == true and not id:find("^hack|") and not id:find("^give|")
  end

  function HK.menuKey()
    local key = settings.menukey
    return (type(key) == "string" and key ~= "") and key or "IK_F8"
  end

  function HK.send(p)
    if not p then pcall(function() p = Game.GetPlayer() end) end
    if not p then return end
    local keys, seen = {}, {}
    for _, key in pairs(settings.hotkeys) do
      if not seen[key] then
        seen[key] = true
        keys[#keys + 1] = key
      end
    end
    pcall(function() p:DCMMenuSetKeys(HK.menuKey(), table.concat(keys, ",")) end)
  end

  local function owner(key, except)
    if key == HK.menuKey() and except ~= "menukey" then return "menukey" end
    for bind, k in pairs(settings.hotkeys) do
      if k == key and "hk|" .. bind ~= except then return bind end
    end
  end

  function HK.toast(text, force)
    if settings.notify == false and not force then return end
    if not G.inkmenu.toast(text) then G.notify(text) end
  end

  function HK.set(id, key)
    if id ~= "menukey" and not id:find("^hk|") then return end
    if key == nil and id == "menukey" then key = "IK_F8" end
    if key and owner(key, id) then
      HK.toast(G.STR.hkused .. ": " .. HK.label(key), true)
      return
    end
    if id == "menukey" then
      settings.menukey = key
    else
      settings.hotkeys[id:sub(4)] = key
    end
    G.saveSettings()
    HK.send()
    local game = ""
    pcall(function() game = Game.GetPlayer():DCMGameBindOf(key or "") end)
    if key and type(game) == "string" and game ~= "" then HK.toast(string.format(G.STR.hkgame, HK.label(key), game), true) end
  end

  local function same(a, b)
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 1e-6 end
    return a == b
  end

  local function walk(id, get, dir, target)
    for _ = 1, 400 do
      local before = tonumber(get())
      if not before or (target and same(before, target)) then return end
      G.native.route(dir, id)
      local now = tonumber(get())
      if not now or same(now, before) then return end
      if (dir == "inc" and now < before) or (dir == "dec" and now > before) then
        G.native.route(dir == "inc" and "dec" or "inc", id)
        return
      end
    end
  end

  local function stepValue(bind, row)
    local function get() return (G.menu.optionState(row.id)) end
    local cur, def = G.menu.optionState(row.id)
    if type(def) ~= "number" then
      G.native.route("inc", row.id)
    elseif not same(cur, def) then
      HK.last[bind] = cur
      G.native.route("reset", row.id)
    elseif HK.last[bind] then
      walk(row.id, get, HK.last[bind] > cur and "inc" or "dec", HK.last[bind])
    else
      walk(row.id, get, "inc")
    end
  end

  local function find(rows, kind, id)
    for _, r in ipairs(rows or {}) do
      if r.kind == kind and G.stableId(r.id) == id then return r end
    end
  end

  function HK.run(bind)
    local tabKey, sub, kind, id = bind:match("^([^|]+)|(%d+)|([^|]+)|(.*)$")
    if not tabKey then return end
    local N = G.native
    local text
    G.inkmenu.inTab(tabKey, tonumber(sub), function()
      local row = find(N.rows, kind, id)
      if not row then return end
      HK.running = true
      if kind == "choice" then stepValue(bind, row) else N.route("act", row.id) end
      HK.running = nil
      local after = find(N.build(), kind, id) or row
      if kind == "toggle" then
        text = row.label .. ": " .. (after.value == "1" and G.STR.on or G.STR.off)
      elseif kind == "choice" then
        text = row.label .. ": " .. tostring(after.value or "")
      end
    end)
    if text then HK.toast(text) end
    G.inkmenu.indDirty = true
    if settings.vibrate then
      pcall(function()
        GameObject.PlaySound(Game.GetPlayer(), TweakDB:GetFlat("rumble.local.light_pulse"))
      end)
    end
  end

  function HK.firePad(button)
    if settings.enabled == false or button == "" then return end
    for bind, b in pairs(settings.padkeys) do
      if b == button then HK.run(bind) end
    end
  end

  function HK.setPad(bind, dir)
    local cur = 0
    for i, name in ipairs(HK.PAD) do
      if settings.padkeys[bind] == name then cur = i end
    end
    local used = {}
    for b, name in pairs(settings.padkeys) do
      if b ~= bind then used[name] = true end
    end
    local nxt = cur
    repeat nxt = (nxt + dir) % (#HK.PAD + 1) until nxt == 0 or not used[HK.PAD[nxt]]
    settings.padkeys[bind] = HK.PAD[nxt]
    G.saveMenuData()
  end

  function HK.fire(key, down, mods)
    if not down or settings.enabled == false then return end
    for bind, k in pairs(settings.hotkeys) do
      if k == key then
        local action = bind:match("^act|(.+)$")
        if action then
          G.input.fireById((MODS[action] or {})[mods] or action)
        else
          HK.run(bind)
        end
      end
    end
  end

  return HK
end
