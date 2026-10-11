return function(G)
  local M = { held = {}, actions = {}, BINDS = {}, DEBUG = false }

  local HELD_MAX = 8.0
  local PAD_BTN = {
    A = { main = "Jump", actions = { Jump = true } },
    X = { main = "Reload", actions = { Reload = true } },
    Y = { main = "SwitchItem", actions = { SwitchItem = true, EnterCombatMode = true } },
    B = { main = "ToggleCrouch", actions = { ToggleCrouch = true, Dodge = true, Dive = true, Crouch = true } },
  }
  M.IDS = { "toggle", "cycle", "command", "preset1", "preset2", "preset3", "preset4", "preset5", "holster",
    "stanceall", "hijack" }
  M.DEFAULTS = { toggle = "LB+A", cycle = "RB+A", command = "LB+B" }

  local MOD_ALIASES = {
    LeftShoulder = "LB",
    DriverCombatVisionHold = "LB",
    UI_vehicle_customization_tab_left = "LB",
    UI_smart_frame_controller_zoom_out = "LB",
    RightShoulder = "RB",
    UI_vehicle_customization_tab_right = "RB",
    UI_smart_frame_controller_zoom_in = "RB",
  }


  local UI_PREFIXES = { "UI_", "Choice", "Menu", "Radial", "world_map", "Disassemble", "Open" }
  local BLOCKED = {
    TogglePhotoMode = true, QuickSave = true, QuickLoad = true,
    TogglePause = true, Exit = true,
  }

  function M.isGameplay(name)
    if BLOCKED[name] then return false end
    for _, p in ipairs(UI_PREFIXES) do
      if name:sub(1, #p) == p then return false end
    end
    return true
  end

  function M.parse(combo)
    local a, b = tostring(combo or ""):match("^([^+]+)%+([^+]+)$")
    if not a then return nil end
    if PAD_BTN[a] then a, b = b, a end
    if (a == "LB" or a == "RB") and PAD_BTN[b] then return a, b end
  end

  function M.comboOf(id)
    local saved = G.settings.padbinds[id]
    if saved ~= nil then return saved end
    return M.DEFAULTS[id] or ""
  end

  function M.reload()
    M.BINDS = {}
    for _, id in ipairs(M.IDS) do
      local mod, btn = M.parse(M.comboOf(id))
      if mod then
        M.BINDS[id] = { mod = mod, key = PAD_BTN[btn].main, actions = PAD_BTN[btn].actions, btnLabel = btn }
      end
    end
  end
  M.reload()

  function M.setCombo(id, combo)
    if id == "padcombo" then
      for _, other in ipairs(M.IDS) do
        if M.comboOf(other) == combo then return "pad_used" end
      end
      G.settings.padcombo = combo
    else
      local mod, btn = M.parse(combo)
      if not mod then return "pad_invalid" end
      combo = mod .. "+" .. btn
      if combo == M.comboOf(id) then
        combo = ""
      elseif combo == G.settings.padcombo then
        return "pad_used"
      else
        for _, other in ipairs(M.IDS) do
          if M.comboOf(other) == combo then return "pad_used" end
        end
      end
      G.settings.padbinds[id] = combo
    end
    G.saveSettings()
    M.reload()
  end

  M.graceUntil = {}
  M.recentKey = {}
  M.lastFired = {}

  function M.fire(id, fn)
    if G.settings.enabled == false then return false end
    local now = os.clock()
    if M.lastFired[id] and now - M.lastFired[id] < 0.5 then return false end
    M.lastFired[id] = now
    local bind = M.BINDS[id]
    if bind and bind.mod then M.graceUntil[bind.mod] = nil end
    if M.DEBUG then G.log("input-debug: combo " .. id .. " fired") end
    pcall(fn)
    return true
  end

  function M.fireById(id)
    local fn = M.actions[id]
    if fn then return M.fire("kb:" .. id, fn) end
    return false
  end

  function M.matches(bind, name, held)
    if not bind or not bind.key or bind.key == "" then return false end
    if bind.actions then
      if not bind.actions[name] then return false end
    elseif bind.key ~= name then
      return false
    end
    if bind.mod and bind.mod ~= "" then
      local grace = M.graceUntil[bind.mod]
      if not held[bind.mod] and not (grace and grace > os.clock()) then return false end
    end
    return true
  end

  local function recentFor(bind)
    if not bind then return nil end
    if bind.actions then
      local best
      for action in pairs(bind.actions) do
        local t = M.recentKey[action]
        if t and (not best or t > best) then best = t end
      end
      return best
    end
    return M.recentKey[bind.key]
  end

  local function clearRecent(bind)
    if bind.actions then
      for action in pairs(bind.actions) do M.recentKey[action] = nil end
    else
      M.recentKey[bind.key] = nil
    end
  end

  function M.install()
    Override("PlayerPuppet", "OnAction", function(_, action, consumer, wrapped)
      local name, pressed, released, kind
      local ok = pcall(function()
        name = Game.NameToString(ListenerAction.GetName(action))
        kind = ListenerAction.GetType(action)
        pressed = kind == gameinputActionType.BUTTON_PRESSED
        released = kind == gameinputActionType.BUTTON_RELEASED
      end)
      if not ok or not name then
        if not M.readFailed then
          M.readFailed = true
          G.log("input: could not read action name/type - controller binds are off")
        end
        return wrapped(action, consumer)
      end

      if G.dronecam and G.dronecam.active then
        pcall(G.dronecam.onAction, name, action, pressed, released, kind)
      end

      if name:find("utodrive")
        and (pressed or kind == gameinputActionType.BUTTON_HOLD_COMPLETE) then
        G.log("input: autodrive action " .. name)
        if G.chauffeur then pcall(G.chauffeur.onAutodrive) end
      end

      local phys = MOD_ALIASES[name]
      for k, at in pairs(M.held) do
        if os.clock() - at > HELD_MAX then M.held[k] = nil end
      end
      if M.DEBUG and (pressed or released) and (phys or M.isGameplay(name)) then
        local mods = {}
        for k in pairs(M.held) do mods[#mods + 1] = k end
        G.log(string.format("input-debug: %s%s %s held={%s}",
          name, phys and ("->" .. phys) or "",
          pressed and "pressed" or "released", table.concat(mods, ",")))
      end
      if released and name == "Choice1" then
        if G.prompt.owner == "hijack" then
          if not G.prompt.keyOf("hijack") then pcall(G.hijack.trigger) end
        elseif G.wreck.rec and not G.prompt.keyOf("wreck") then
          pcall(G.wreck.onChoice)
        end
      end
      local holdDone = kind == gameinputActionType.BUTTON_HOLD_COMPLETE
      if released or holdDone then
        if M.isGameplay(name) then
          for id, fn in pairs(M.actions) do
            if M.matches(M.BINDS[id], name, M.held) then M.fire(id, fn) end
          end
        end
        if released and phys and M.held[phys] then
          M.held[phys] = nil
          M.graceUntil[phys] = os.clock() + 0.3
        end
        return wrapped(action, consumer)
      end
      if not pressed then return wrapped(action, consumer) end

      local swallow = false
      if M.isGameplay(name) then
        for id, fn in pairs(M.actions) do
          if M.matches(M.BINDS[id], name, M.held) and M.fire(id, fn) then
            swallow = true
          end
        end
        M.recentKey[name] = os.clock()
      end
      if phys then
        M.held[phys] = os.clock()
        for id, fn in pairs(M.actions) do
          local bind = M.BINDS[id]
          local t = recentFor(bind)
          if bind and bind.mod == phys and t and os.clock() - t < 0.15 then
            clearRecent(bind)
            M.fire(id, fn)
          end
        end
      end
      if swallow then
        pcall(function() ListenerActionConsumer.Consume(consumer) end)
      end
      return wrapped(action, consumer)
    end)
  end

  function M.demo()
    local held = { LB = 1.0 }
    assert(M.matches({ mod = "LB", key = "X" }, "X", held))
    assert(not M.matches({ mod = "LB", key = "X" }, "X", {}))
    assert(not M.matches({ mod = "LB", key = "X" }, "Y", held))
    M.graceUntil.LB = os.clock() + 0.3
    assert(M.matches({ mod = "LB", key = "X" }, "X", {}))
    M.graceUntil.LB = os.clock() - 1
    assert(not M.matches({ mod = "LB", key = "X" }, "X", {}))
    M.graceUntil.LB = nil
    assert(M.matches({ mod = "", key = "X" }, "X", {}))
    assert(not M.matches({ mod = "", key = "" }, "", {}))
    assert(not M.matches(nil, "X", {}))
    local alias = { mod = "LB", key = "ToggleCrouch", actions = { ToggleCrouch = true, Dodge = true } }
    assert(M.matches(alias, "Dodge", held))
    assert(M.matches(alias, "ToggleCrouch", held))
    assert(not M.matches(alias, "Jump", held))
    local saved = G.settings.padbinds
    G.settings.padbinds = {}
    M.reload()
    assert(M.BINDS.toggle.mod == "LB" and M.BINDS.toggle.key == "Jump")
    assert(M.BINDS.cycle.mod == "RB" and M.BINDS.cycle.btnLabel == "A")
    assert(M.BINDS.command.mod == "LB" and M.BINDS.command.actions.Dodge
      and M.BINDS.command.actions.Dive and M.BINDS.command.actions.Crouch)
    assert(M.BINDS.preset1 == nil and M.BINDS.menu == nil)
    G.settings.padbinds = { toggle = "", cycle = "X+LB", preset1 = "RB+Y", hijack = "LB+RB", holster = "A" }
    M.reload()
    assert(M.BINDS.toggle == nil and M.BINDS.hijack == nil and M.BINDS.holster == nil)
    assert(M.BINDS.cycle.mod == "LB" and M.BINDS.cycle.key == "Reload")
    assert(M.BINDS.preset1.mod == "RB" and M.BINDS.preset1.actions.SwitchItem)
    assert(not M.matches(M.BINDS.toggle, "Jump", held))
    G.settings.padbinds = saved
    M.reload()
    local n = 0
    assert(M.fire("demo", function() n = n + 1 end))
    assert(not M.fire("demo", function() n = n + 1 end))
    assert(n == 1)
    M.actions.demo2 = function() n = n + 10 end
    assert(M.fireById("demo2"))
    assert(not M.fireById("nope"))
    assert(n == 11)
    M.actions.demo2 = nil
    assert(M.isGameplay("Jump"))
    assert(not M.isGameplay("UI_vehicle_customization_confirm"))
    assert(not M.isGameplay("ChoiceScrollUp"))
    assert(not M.isGameplay("OpenPauseMenu"))
    assert(not M.isGameplay("QuickSave"))
    print("input demo ok")
  end

  return M
end
