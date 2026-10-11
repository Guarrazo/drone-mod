return function(G, N)
  local settings, STR, HK = G.settings, G.STR, G.hotkeys
  local COMBO = "LB+X"
  local DISCORD = "https://discord.gg/VcuRghJJMh"
  local PAYPAL = "https://www.paypal.com/donate/?business=SR28XBBCYSPHE&no_recurring=0&item_name=Help+me+buy+a+coffee.&currency_code=USD"
  local INDICATOR_POS = { "indtr", "indtl", "indbr" }
  local TOGGLES = { keyhints = true, statusind = false, pausemenu = false, pausenotice = true, vibrate = false }
  local armed = {}
  local ACTION_KEY = {}
  for _, action in ipairs(HK.ACTIONS) do ACTION_KEY[action[1]] = action[2] end

  local function isArmed(id)
    return armed.id == id and os.clock() - (armed.at or 0) < 3.0
  end

  local function confirm(id, fn)
    if isArmed(id) then
      armed = {}
      fn()
    else
      armed = { id = id, at = os.clock() }
      HK.toast(STR.pressagain, true)
    end
  end

  local function bgLabel(v)
    if (v or 0) == 0 then return STR.bgauto end
    return ((v - 1) * 20) .. "%"
  end

  local function subKeys()
    local keys = { "subgeneral" }
    if not G.inkmenu.pad then keys[#keys + 1] = "subhotkeys" end
    keys[#keys + 1] = "subcontroller"
    keys[#keys + 1] = "subbackup"
    return keys
  end

  local function toggle(id, label, on, default, info)
    N.row("toggle", id, label, on and "1" or "0", info).changed = on ~= default
  end

  local function general()
    N.head(STR.grp_general, nil, "setgeneral")
    toggle("enabled", STR.tenabled, settings.enabled ~= false, true,
      settings.enabled == false and STR.moddisabled or STR.enabledhint)
    local pick = G.LANG_NAMES[settings.langpick or ""] and settings.langpick or "auto"
    N.row("choice", "langpick", STR.langlabel, pick == "auto" and STR.langauto or G.LANG_NAMES[pick], STR.langhint)
      .changed = pick ~= "auto"
    toggle("notify", STR.notifylabel, settings.notify ~= false, true, STR.notifyhint)

    N.head(STR.sec_interface, "interface", "setinterface")
    G.menu.inkPart(N, "theme")
    N.row("choice", "menubg", STR.menubg, bgLabel(settings.menubg), STR.menubghint).changed = (settings.menubg or 0) ~= 0
    toggle("descbox", STR.descbox, settings.descbox ~= false, true, STR.descboxhint)
    toggle("keyhints", STR.keyhints, settings.keyhints ~= false, true, STR.keyhintshint)
    if not G.inkmenu.pad then N.key("menukey", STR.menukey, HK.menuKey(), STR.menukeyhint) end
    N.row("btn", "resetpos", STR.resetpos, "", STR.resetposhint)

    G.menu.inkPart(N, "hud")

    N.head(STR.pausehdr, "pausehdr", "setpause")
    toggle("pausemenu", STR.pausemenu, settings.pausemenu == true, false, STR.pausemenuhint)
    toggle("pausegame", STR.gpause, G.pause.paused, false, STR.gpausehint)
    N.row("btn", "pausestep", STR.gstep, "", STR.gstephint)
    toggle("pausenotice", STR.pausenotice, settings.pausenotice ~= false, true, STR.pausenoticehint)

    N.head(STR.indhdr, "indhdr", "setindicator")
    toggle("statusind", STR.statusind, settings.statusind == true, false, STR.statusindhint)
    N.row("choice", "indpos", STR.indpos, STR[INDICATOR_POS[(settings.indpos or 0) + 1]]).changed = (settings.indpos or 0) ~= 0

    N.head(STR.tabshdr, "tabs", "settabs")
    for _, tab in ipairs(N.tabs) do
      if tab.key ~= "tab_settings" then
        toggle("tab|" .. tab.key, tab.title(), not G.tabHidden(tab.key), true, STR.tabshint)
      end
    end

    N.head(STR.supporthdr, "supporthdr", "setsupport")
    N.row("btn", "discord", "Discord", "", STR.discordhint).brand = "0.345,0.396,0.949"
    N.row("btn", "paypal", STR.paypal, "", STR.paypalhint).brand = "0.000,0.439,0.729"
  end

  local function hotkeys()
    N.head(STR.hk_actions, nil, "hkactions")
    for _, action in ipairs(HK.ACTIONS) do
      local info = STR.hkhint
      if action[1] == "command" then info = info .. " " .. STR.hk_command_hint end
      if action[1] == "hijack" or action[1] == "repair" then info = info .. " " .. STR.hk_prompt_hint end
      N.key("hk|act|" .. action[1], HK.actionLabel(action[2]), settings.hotkeys["act|" .. action[1]], info)
    end
    for _, tab in ipairs(N.visibleTabs()) do
      local rows = {}
      for _, o in ipairs(G.inkmenu.options) do
        if o.tab == tab.key and HK.bindable(o.tab, o.row) then
          local bind = HK.bind(o.tab, o.sub, o.row.kind, o.row.id)
          rows[#rows + 1] = { "hk|" .. bind, o.row.label, settings.hotkeys[bind],
            (o.where and (o.where .. ". ") or "") .. STR.hkhint }
        end
      end
      if #rows > 0 then
        N.head(tab.title(), tab.key, "hk" .. tab.key)
        for _, r in ipairs(rows) do N.key(r[1], r[2], r[3], r[4]) end
      end
    end
  end

  local function padHotkeys()
    for _, tab in ipairs(N.visibleTabs()) do
      local rows = {}
      for _, o in ipairs(G.inkmenu.options) do
        if o.tab == tab.key and HK.bindable(o.tab, o.row) then rows[#rows + 1] = o end
      end
      if #rows > 0 then
        N.head(STR.padhkhdr .. "  \194\187  " .. tab.title(), tab.key, "pad" .. tab.key)
        for _, o in ipairs(rows) do
          local bind = HK.bind(o.tab, o.sub, o.row.kind, o.row.id)
          N.row("choice", "ph|" .. bind, o.row.label, settings.padkeys[bind] or STR.hknone,
            (o.where and (o.where .. ". ") or "") .. STR.padhkhint).changed = settings.padkeys[bind] ~= nil
        end
      end
    end
  end

  local function controller()
    N.head(STR.subcontroller, "padhkhdr", "padgeneral")
    toggle("padopen", STR.padopen, settings.padopen ~= false, true, STR.padopenhint)
    local combo = settings.padcombo or COMBO
    N.row("choice", "padcombo", STR.padcombo, combo, STR.padcombohint).changed = combo ~= COMBO
    toggle("vibrate", STR.vibrate, settings.vibrate == true, false, STR.vibratehint)
    N.head(STR.hk_actions, nil, "padactions")
    for _, id in ipairs(G.input.IDS) do
      local cur = G.input.comboOf(id)
      N.row("choice", "pc|" .. id, HK.actionLabel(ACTION_KEY[id]), cur ~= "" and cur or STR.hknone, STR.pad_hint)
        .changed = cur ~= (G.input.DEFAULTS[id] or "")
    end
    padHotkeys()
  end

  local function backup()
    local info = G.backupInfo()
    N.head(STR.subbackup, nil, "setbackup")
    N.row("btn", "export", STR.backup_save, info or STR.backup_none, STR.backup_hint)
    if info then
      N.row("btn", "import", STR.backup_restore, isArmed("import") and ("!" .. STR.pressagain) or info, STR.backup_hint)
    end
    N.row("btn", "resetall", STR.resetall, isArmed("resetall") and ("!" .. STR.pressagain) or "!", STR.resetallhint)
  end

  local BUILD = { subgeneral = general, subhotkeys = hotkeys, subcontroller = controller, subbackup = backup }

  local function setEnabled(on)
    G.setEnabled(on)
    HK.toast(STR.tenabled .. ": " .. (on and STR.on or STR.off), true)
  end

  local function step(id, dir)
    if id == "langpick" then
      local keys = { "auto" }
      for _, code in ipairs(G.LANGS) do keys[#keys + 1] = code end
      local cur = 1
      for i, k in ipairs(keys) do if k == settings.langpick then cur = i end end
      G.setLangPick(keys[(cur - 1 + dir) % #keys + 1])
      return true
    end
    if id == "indpos" then
      settings.indpos = ((settings.indpos or 0) + dir) % #INDICATOR_POS
      G.saveSettings()
      return true
    end
    if id:find("^ph|") then
      HK.setPad(id:sub(4), dir)
      return true
    end
    if id ~= "menubg" then return false end
    settings.menubg = ((settings.menubg or 0) + dir) % 7
    G.saveSettings()
    return true
  end

  local function isToggle(id)
    return id == "enabled" or id == "notify" or id == "padopen" or id == "descbox" or TOGGLES[id] ~= nil
      or id == "pausegame" or id:find("^tab|") ~= nil
  end

  local function act(id)
    if id == "enabled" then
      setEnabled(settings.enabled == false)
    elseif id == "notify" then
      settings.notify = settings.notify == false
      G.saveSettings()
    elseif id == "padopen" then
      settings.padopen = settings.padopen == false
      G.saveSettings()
      G.inkmenu.sendCombo()
    elseif id == "descbox" then
      settings.descbox = settings.descbox == false
      G.saveSettings()
    elseif TOGGLES[id] ~= nil then
      settings[id] = not settings[id]
      G.saveSettings()
      if id == "pausenotice" then G.pause.refreshNotice() end
    elseif id == "pausegame" then
      G.pause.set(not G.pause.paused)
    elseif id == "pausestep" then
      G.pause.step()
    elseif id:find("^tab|") then
      local key = id:sub(5)
      settings.hiddentabs[key] = (not G.tabHidden(key)) or nil
      G.saveSettings()
    elseif id == "discord" or id == "paypal" then
      G.copyLink(id == "discord" and DISCORD or PAYPAL)
    elseif id == "resetpos" then
      settings.menupos, settings.squadpos, settings.menusize = nil, nil, nil
      G.saveSettings()
    elseif id == "export" then
      G.notify(G.backupSettings() and STR.backup_done or STR.give_fail)
    elseif id == "import" then
      if not G.backupInfo() then return end
      confirm(id, function()
        local ok = G.restoreSettings()
        if ok and settings.enabled == false then G.setEnabled(false) end
        G.notify(ok and STR.restore_done or STR.give_fail)
      end)
    elseif id == "resetall" then
      confirm(id, function()
        G.resetAll()
        G.notify(STR.resetdone)
      end)
    elseif not step(id, 1) then
      G.menu.inkHandlers.act(id)
    end
  end

  local function adjust(id, dir)
    if isToggle(id) then
      act(id)
    elseif not step(id, dir) then
      G.menu.inkHandlers[dir > 0 and "inc" or "dec"](id)
    end
  end

  local function reset(id)
    if isToggle(id) then
      act(id)
    elseif id == "indpos" then
      settings.indpos = 0
      G.saveSettings()
    elseif id:find("^ph|") then
      settings.padkeys[id:sub(4)] = nil
      G.saveMenuData()
    elseif id == "menubg" then
      settings.menubg = 0
      G.saveSettings()
    elseif id == "langpick" then
      G.setLangPick("auto")
    elseif id == "padcombo" then
      settings.padcombo = COMBO
      G.saveSettings()
      G.inkmenu.sendCombo()
    elseif id:find("^pc|") then
      settings.padbinds[id:sub(4)] = nil
      G.saveSettings()
      G.input.reload()
    else
      G.menu.inkHandlers.reset(id)
    end
  end

  N.tab("tab_settings", function() return STR.tab_settings end, function()
    BUILD[subKeys()[N.sub("tab_settings")] or "subgeneral"]()
  end, {
    act = act,
    inc = function(id) adjust(id, 1) end,
    dec = function(id) adjust(id, -1) end,
    reset = reset,
    set = function(id, value) return G.menu.inkHandlers.set(id, value) end,
  }, function()
    local out = {}
    for i, key in ipairs(subKeys()) do out[i] = STR[key] end
    return out
  end)
end
