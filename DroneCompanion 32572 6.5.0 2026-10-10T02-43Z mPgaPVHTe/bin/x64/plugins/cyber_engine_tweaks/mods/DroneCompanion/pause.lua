return function(G)
  local settings, STR = G.settings, G.STR
  local PZ = { paused = false, menuPaused = false }

  local function handler()
    return Game.GetSystemRequestsHandler()
  end

  local function gamePaused()
    local paused = false
    pcall(function() paused = handler():IsGamePaused() == true end)
    return paused
  end

  local function notice()
    local text = (PZ.paused and settings.pausenotice ~= false) and STR.pausednotice or ""
    pcall(function() Game.GetPlayer():DCMNotice(text) end)
  end

  local function hold(on)
    return pcall(function() if on then handler():PauseGame() else handler():UnpauseGame() end end)
  end

  function PZ.set(on)
    on = on == true
    if on == PZ.paused then return end
    if on or not PZ.menuPaused then
      if not hold(on) then return end
    end
    PZ.paused = on
    PZ.stepLeft = nil
    notice()
  end

  function PZ.step()
    if not PZ.paused and not PZ.menuPaused then return end
    if hold(false) then PZ.stepLeft = 1 end
  end

  function PZ.refreshNotice()
    notice()
  end

  function PZ.menuOpened()
    if settings.pausemenu ~= true or settings.enabled == false or PZ.paused or gamePaused() then return end
    if hold(true) then PZ.menuPaused = true end
  end

  function PZ.menuClosed()
    if not PZ.menuPaused then return end
    PZ.menuPaused = false
    PZ.stepLeft = nil
    if not PZ.paused then hold(false) end
  end

  function PZ.tick()
    if PZ.stepLeft then
      PZ.stepLeft = PZ.stepLeft - 1
      if PZ.stepLeft < 0 then
        PZ.stepLeft = nil
        hold(true)
      end
      return
    end
    if not PZ.paused then return end
    if settings.enabled == false then
      PZ.set(false)
      return
    end
    if not gamePaused() then
      PZ.paused = false
      notice()
    end
  end

  function PZ.install()
    ObserveAfter("PlayerPuppet", "OnGameAttached", function()
      PZ.paused, PZ.menuPaused, PZ.stepLeft = false, false, nil
    end)
  end

  return PZ
end
