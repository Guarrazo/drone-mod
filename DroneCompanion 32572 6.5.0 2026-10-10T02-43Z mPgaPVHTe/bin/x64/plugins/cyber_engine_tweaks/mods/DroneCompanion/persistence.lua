return function(G)
  local Cron = G.Cron
  local GameSession = G.GameSession
  local companion = G.companion

  local state = { drones = {}, perks = {}, kills = {}, deaths = {}, squad = {} }
  local ftStash = nil

  local function sessionDir()
    local probe = io.open("sessions/.probe", "w")
    if not probe then
      G.log("sessions folder missing: storing session data in the mod root")
      return "."
    end
    probe:close()
    os.remove("sessions/.probe")
    return "sessions"
  end

  GameSession.IdentifyAs("DroneCompanion")
  GameSession.StoreInDir(sessionDir())
  GameSession.Persist(state)

  GameSession.Listen("SaveData", function()
    state.drones = companion.captureAll()
    state.perks = G.perks.save()
    state.kills = G.squad.kills
    state.deaths = G.squad.deaths
    state.squad = G.squad.save()
  end)

  local pendingRestore = nil

  companion.cancelRestore = function()
    if pendingRestore then
      Cron.Halt(pendingRestore)
      pendingRestore = nil
      G.log("restore skipped: drones dismissed before the respawn")
    end
  end

  GameSession.Listen("Start", function()
    G.shard.learnRecipes()
    G.perks.load(state.perks)
    G.squad.kills = type(state.kills) == "table" and state.kills or {}
    G.squad.deaths = type(state.deaths) == "table" and state.deaths or {}
    G.squad.load(state.squad)
    if pendingRestore then Cron.Halt(pendingRestore) end

    pendingRestore = Cron.After(5.0, function()
      pendingRestore = nil
      G.arena.reset()
      if state.drones and #state.drones > 0 and G.settings.enabled ~= false then
        companion.respawn(state.drones)
      end
    end)
  end)

  GameSession.Listen("End", function()
    G.arena.reset()
    companion.stashed = nil
    companion.garage = nil
    ftStash = nil
  end)

  Observe("FastTravelSystem", "SetFastTravelStarted", function()
    local captured = companion.captureAll()
    if #captured > 0 then
      ftStash = captured
      companion.stashed = nil
      companion.dismissAll(true)
    end
  end)

  Observe("FastTravelSystem", "OnLoadingScreenFinished", function()
    if not ftStash then return end
    local captured = ftStash
    ftStash = nil
    Cron.After(3.0, function()
      companion.respawn(captured)
    end)
  end)
end
