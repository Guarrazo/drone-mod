return function(G)
  local M = { owner = nil }
  local KEY_OF = { wreck = "act|repair", hijack = "act|hijack" }

  function M.keyOf(owner)
    return G.settings.hotkeys[KEY_OF[owner]]
  end

  local HUB_ID = -2077

  local function push(title, label, active)
    local data = InteractionChoiceHubData.new()
    data.id = HUB_ID
    data.active = active
    data.flags = EVisualizerDefinitionFlags.Undefined
    data.title = title
    local choice = InteractionChoiceData.new()
    choice.localizedName = label
    choice.inputAction = "Choice1"
    local kind = ChoiceTypeWrapper.new()
    kind:SetType(gameinteractionsChoiceType.Blueline)
    choice.type = kind
    data.choices = { choice }
    local vis = VisualizersInfo.new()
    vis.activeVisId = HUB_ID
    vis.visIds = { HUB_ID }
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():Get(defs.UIInteractions)
    bb:SetVariant(defs.UIInteractions.InteractionChoiceHub, ToVariant(data), true)
    bb:SetVariant(defs.UIInteractions.VisualizersInfo, ToVariant(vis), true)
  end

  local function hub(on, title, label)
    if on then
      M.hub = true
      pcall(push, title, label, true)
    elseif M.hub then
      M.hub = false
      pcall(push, "", "", false)
    end
  end

  local function own(key, label)
    local shown = key and (key .. "\t" .. label) or nil
    if shown == M.shown or not G.inkmenu.hudReady then return end
    M.shown = shown
    local accent = G.ui.theme().accent
    pcall(function()
      Game.GetPlayer():DCMPrompt(key ~= nil, key and G.hotkeys.label(key) or "", label or "",
        string.format("%.3f,%.3f,%.3f", accent[1], accent[2], accent[3]))
    end)
  end

  function M.set(owner, title, label)
    local key = owner and M.keyOf(owner)
    M.owner = owner
    hub(owner ~= nil and not key, title, label)
    own(key, label)
  end

  function M.tick()
    if not G.settings.lookPrompt or G.settings.enabled == false then return M.set(nil) end
    local player = Game.GetPlayer()
    if not player then return M.set(nil) end
    local title, label = G.wreck.promptTick(player)
    if title then return M.set("wreck", title, label) end
    title, label = G.hijack.promptTick(player)
    if title then return M.set("hijack", title, label) end
    M.set(nil)
  end

  return M
end
