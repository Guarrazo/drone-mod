return function(G)
  local Cron = G.Cron
  local M = { fighters = {}, lastLeft = nil }

  local TAG = "DroneCompanionArena"
  local IMMORTAL_SOURCE = "DroneCompanionArena"
  local KO_PCT = 10.0
  local HP_MULT = 15.0
  local HOLD_S = 3.0
  local ARM_DELAYS = { 1.5, 3.0, 6.0 }
  local SPAWN_GRACE = 6.0
  local GONE_TICKS = 3
  local MAX_DIST = 100.0
  local STALL_S = 90.0

  local function tdbid(s) return TweakDBID.new(s) end

  local function nameOf(rec)
    return G.squad.displayName(rec, G.modelOf(rec))
  end

  local function hpPct(ent)
    local pct = -1
    pcall(function()
      pct = Game.GetStatPoolsSystem():GetStatPoolValue(ent:GetEntityID(), gamedataStatPoolType.Health, true)
    end)
    return pct
  end

  local function stateOf(ent)
    local s
    pcall(function() s = ent:GetHighLevelStateFromBlackboard() end)
    return s
  end

  local function threatCount(ent)
    local n = -1
    pcall(function() n = #ent:GetTargetTrackerComponent():GetHostileThreats(false) end)
    return n
  end

  function M.busy(rec) return M.fighters[rec] ~= nil end

  function M.count()
    local n = 0
    for _ in pairs(M.fighters) do n = n + 1 end
    return n
  end

  function M.fighting() return M.count() > 0 end

  function M.entityOf(rec)
    local f = M.fighters[rec]
    if not f then return nil end
    local ent
    pcall(function() ent = Game.FindEntityByID(f.id) end)
    return IsDefined(ent) and ent or nil
  end

  function M.isFighterEnt(ent)
    if not IsDefined(ent) then return false end
    local key = G.companion.entKey(ent)
    for _, f in pairs(M.fighters) do
      if f.key == key then return true end
    end
    return false
  end

  function M.rows()
    local out = {}
    for rec in pairs(M.fighters) do
      local ent = M.entityOf(rec)
      if ent then out[#out + 1] = { rec = rec, ent = ent, model = G.modelOf(rec), arena = true } end
    end
    table.sort(out, function(a, b) return a.rec < b.rec end)
    return out
  end

  local order, orderFor
  function M.withFighters(rows)
    local fighters = M.rows()
    if #fighters == 0 then return rows end
    if orderFor ~= G.INSTANCES then
      order, orderFor = {}, G.INSTANCES
      local n = 0
      for _, model in ipairs(G.MODELS) do
        for i = 1, G.INSTANCES do
          n = n + 1
          order[G.recordId(model, i)] = n
        end
      end
    end
    for _, row in ipairs(fighters) do rows[#rows + 1] = row end
    local key = {}
    for i, row in ipairs(rows) do key[row] = order[row.rec] or (1e9 + i) end
    table.sort(rows, function(a, b) return key[a] < key[b] end)
    return rows
  end

  function M.captured()
    local out = {}
    for rec, f in pairs(M.fighters) do
      local ent = M.entityOf(rec)
      local pct = ent and hpPct(ent) or -1
      if pct < 0 then pct = f.lastHp end
      local saved = f.saved
      out[#out + 1] = { record = rec, hp = math.max(pct, KO_PCT), muted = saved.muted,
        weapon = saved.weapon, lit = saved.lit, holstered = saved.holstered, keepDrawn = saved.keepDrawn }
    end
    return out
  end

  function M.pointsUsed()
    local used = 0
    for rec in pairs(M.fighters) do
      local model = G.modelOf(rec)
      if model then used = used + G.pointsOf(model.chassis) end
    end
    return used
  end

  local function eligible(row, piloted)
    local rec = row.rec
    return G.companion.arena[rec] ~= nil and not M.busy(rec)
      and not row.model.static and not row.model.hijack
      and rec ~= piloted and not G.chauffeur.crew[rec]
      and not G.companion.isDown(row.ent)
      and (os.clock() - (G.companion.spawnTime[rec] or 0)) > SPAWN_GRACE
      and (os.clock() - (G.companion.arenaSince[rec] or 0)) >= HOLD_S
      and hpPct(row.ent) > KO_PCT
  end

  function M.waiting(rows)
    local piloted = G.dronecam and G.dronecam.active
    local out = {}
    for _, row in ipairs(rows or G.companion.aliveCache or {}) do
      if eligible(row, piloted) then out[#out + 1] = row end
    end
    return out
  end

  function M.arenaCount()
    local n = M.count()
    for _, row in ipairs(G.companion.aliveCache or {}) do
      if G.companion.arena[row.rec] and not row.model.static and not row.model.hijack then n = n + 1 end
    end
    return n
  end

  local function armPair(a, b)
    if GameObject.GetAttitudeTowards(a, b) == EAIAttitude.AIA_Hostile then return false end
    a:GetAttitudeAgent():SetAttitudeTowards(b:GetAttitudeAgent(), EAIAttitude.AIA_Hostile)
    return true
  end

  local function kick(ent, target)
    pcall(function() TargetTrackingExtension.InjectThreat(ent, target) end)
    pcall(function() ent.reactionComponent:TriggerCombat(target) end)
  end

  local function nearestOpponent(rec, from)
    local best, bestDist
    for other in pairs(M.fighters) do
      if other ~= rec then
        local ent = M.entityOf(other)
        if ent and not G.companion.isDown(ent) then
          local d = Vector4.Distance(from, ent:GetWorldPosition())
          if not bestDist or d < bestDist then best, bestDist = ent, d end
        end
      end
    end
    return best, bestDist
  end

  function M.arm(rec, force)
    local ent = M.entityOf(rec)
    if not ent then return end
    local repaired = 0
    for other in pairs(M.fighters) do
      if other ~= rec then
        local o = M.entityOf(other)
        if o then
          local ok, did = pcall(armPair, ent, o)
          if ok and did then repaired = repaired + 1 end
        end
      end
    end
    local target, dist = nearestOpponent(rec, ent:GetWorldPosition())
    if not target then return end
    local state = stateOf(ent)
    if force or repaired > 0 or state ~= gamedataNPCHighLevelState.Combat then
      kick(ent, target)
      if force or repaired > 0 then
        G.log(string.format("arena kick %s hls=%s threats=%d dist=%.1f repaired=%d", rec,
          tostring(state), threatCount(ent), dist or -1, repaired))
      end
    end
  end

  local function spawnFighter(rec, snap)
    local id
    local ok, err = pcall(function()
      local spec = DynamicEntitySpec.new()
      spec.recordID = tdbid(rec)
      if snap.app then spec.appearanceName = snap.app end
      spec.position = snap.pos
      spec.orientation = snap.orient
      spec.persistState = false
      spec.persistSpawn = false
      spec.alwaysSpawned = false
      spec.tags = { CName.new(TAG) }
      id = Game.GetDynamicEntitySystem():CreateEntity(spec)
    end)
    if not ok or not id then
      G.log(string.format("arena spawn FAILED %s: %s", rec, tostring(err)))
      return nil
    end
    return id
  end

  local function setup(rec, id)
    local f = M.fighters[rec]
    if not f or f.id ~= id then return end
    local ent = M.entityOf(rec)
    if not ent then
      G.log("arena spawn " .. rec .. " defined=false")
      return
    end
    local model = G.modelOf(rec)
    pcall(function() StatusEffectHelper.ApplyStatusEffect(ent, tdbid(G.TDB .. "ArenaSE")) end)
    if model and model.chassis then
      pcall(function()
        StatusEffectHelper.ApplyStatusEffect(ent, tdbid(G.TDB .. "Chassis" .. model.chassis .. "SE"))
      end)
    end
    local okGod, errGod = pcall(function()
      Game.GetGodModeSystem():AddGodMode(id, gameGodModeType.Immortal, CName.new(IMMORTAL_SOURCE))
    end)
    if not okGod then G.log("arena immortal: " .. tostring(errGod)) end
    pcall(function() ent.NPCManager:ScaleToPlayer() end)
    pcall(function()
      ent.reactionComponent:SetReactionPreset(
        TweakDBInterface.GetReactionPresetRecord(tdbid("ReactionPresets.Ganger_Aggressive")))
    end)
    G.perks.applyToDrone(ent, model, rec)
    local maxHp = -1
    pcall(function()
      local ss = Game.GetStatsSystem()
      ss:AddModifier(id, RPGManager.CreateStatModifier(gamedataStatType.Health,
        gameStatModifierType.Multiplier, HP_MULT))
      maxHp = ss:GetStatValue(id, "Health")
    end)
    pcall(function()
      Game.GetStatPoolsSystem():RequestSettingStatPoolValue(id, gamedataStatPoolType.Health, f.snap.hp, ent)
    end)
    G.log(string.format("arena spawn %s maxhp=%.0f hp=%.0f", rec, maxHp, f.snap.hp))
    if G.settings.minimap then G.companion.attachMappin(rec, ent) end
    f.ready = true
  end

  local function join(row)
    local rec = row.rec
    local snap = G.companion.swapOut(rec)
    if not snap then return false end
    local id = spawnFighter(rec, snap)
    if not id then
      G.companion.arena[rec] = nil
      G.companion.swapIn(rec, snap.pos, snap.hp)
      return false
    end
    local now = os.clock()
    M.fighters[rec] = { id = id, key = tostring(id.hash), snap = snap, saved = snap.saved,
      pos = snap.pos, lastHp = snap.hp, hpAt = now, at = now, ready = false, gone = 0 }
    G.log(string.format("arena join %s hp=%.0f app=%s", rec, snap.hp, tostring(snap.app)))
    Cron.After(1.0, function() setup(rec, id) end)
    for _, delay in ipairs(ARM_DELAYS) do
      Cron.After(delay, function()
        local f = M.fighters[rec]
        if f and f.id == id then M.arm(rec, true) end
      end)
    end
    return true
  end

  function M.leave(rec, why)
    local f = M.fighters[rec]
    if not f then return end
    local ent = M.entityOf(rec)
    M.fighters[rec] = nil
    local pct = ent and hpPct(ent) or -1
    if pct < 0 then pct = f.lastHp end
    local pos = f.pos
    if ent then pcall(function() pos = ent:GetWorldPosition() end) end
    pcall(function()
      Game.GetGodModeSystem():RemoveGodMode(f.id, gameGodModeType.Immortal, CName.new(IMMORTAL_SOURCE))
    end)
    G.companion.dropMappin(rec)
    pcall(function() Game.GetDynamicEntitySystem():DeleteEntity(f.id) end)
    G.companion.arena[rec] = nil
    G.log(string.format("arena leave %s why=%s hp=%.0f left=%d", rec, why, pct, M.count()))
    if why == "ko" then
      G.notify(string.format(G.STR.arena_lost, nameOf(rec)))
      G.companion.swapIn(rec, pos, math.max(pct, KO_PCT))
    elseif why == "withdraw" or why == "win" then
      G.companion.swapIn(rec, pos, pct)
    elseif why == "gone" or why == "cancel" then
      local saved = f.saved
      saved.hp = math.max(pct, KO_PCT)
      G.companion.respawn({ saved })
    end
    if why == "ko" or why == "withdraw" or why == "dismiss" or why == "gone" then
      M.lastLeft = why
      M.settle()
    end
  end

  function M.settle()
    if M.count() ~= 1 then return end
    local last
    for rec in pairs(M.fighters) do last = rec end
    if M.lastLeft == "ko" then
      G.notify(string.format(G.STR.arena_won, nameOf(last)))
      M.leave(last, "win")
    else
      G.notify(G.STR.arena_need_two)
      M.leave(last, "withdraw")
    end
  end

  function M.abort(restore)
    local recs = {}
    for rec in pairs(M.fighters) do recs[#recs + 1] = rec end
    if #recs == 0 then return end
    G.log(string.format("arena abort restore=%s n=%d", tostring(restore), #recs))
    for _, rec in ipairs(recs) do M.leave(rec, restore and "cancel" or "abort") end
    if restore then G.notify(G.STR.arena_cancel) end
  end

  function M.reset()
    M.fighters = {}
    M.lastLeft = nil
    local strays = 0
    pcall(function()
      local des = Game.GetDynamicEntitySystem()
      strays = #des:GetTaggedIDs(CName.new(TAG))
      des:DeleteTagged(CName.new(TAG))
    end)
    G.log("arena reset strays=" .. strays)
  end

  function M.tick(rows, player)
    local waiting = M.waiting(rows)
    if #waiting >= 2 or (M.fighting() and #waiting > 0) then
      local names = {}
      for _, row in ipairs(waiting) do
        if join(row) then names[#names + 1] = nameOf(row.rec) end
      end
      if #names > 0 then G.notify(string.format(G.STR.arena_start, table.concat(names, ", "))) end
    end
    if not M.fighting() then return end
    local now = os.clock()
    local pPos = player:GetWorldPosition()
    local nearest
    local recs = {}
    for rec in pairs(M.fighters) do recs[#recs + 1] = rec end
    table.sort(recs)
    for _, rec in ipairs(recs) do
      local f = M.fighters[rec]
      local ent = f and M.entityOf(rec)
      if not f then
      elseif not ent then
        f.gone = f.gone + 1
        if f.gone >= GONE_TICKS and now - f.at > SPAWN_GRACE then
          G.log("arena gone " .. rec)
          M.leave(rec, "gone")
        end
      else
        f.gone = 0
        f.pos = ent:GetWorldPosition()
        local d = Vector4.Distance(pPos, f.pos)
        if not nearest or d < nearest then nearest = d end
        local pct = hpPct(ent)
        if pct >= 0 and pct ~= f.lastHp then f.lastHp, f.hpAt = pct, now end
        if f.ready then
          local down = G.companion.isDown(ent)
          if (pct >= 0 and pct <= KO_PCT) or down then
            G.log(string.format("arena ko %s hp=%.1f down=%s", rec, pct, tostring(down)))
            M.leave(rec, "ko")
          else
            M.arm(rec, false)
            if now - f.hpAt > STALL_S then
              G.log("arena stall " .. rec)
              M.abort(true)
              return
            end
          end
        end
      end
    end
    if M.fighting() and nearest and nearest > MAX_DIST then
      G.log(string.format("arena far %.0f", nearest))
      M.abort(true)
    end
  end

  function M.demo()
    local toasts, swapped, spawned = {}, {}, {}
    G.log = function() end
    G.notify = function(t) toasts[#toasts + 1] = t end
    G.STR = { arena_won = "%s won", arena_lost = "%s lost", arena_need_two = "need two", arena_cancel = "cancel" }
    G.modelOf = function() return { chassis = "Octant" } end
    G.pointsOf = function() return 2 end
    G.squad = { displayName = function(rec) return rec end }
    G.companion = { arena = {}, entKey = function() return "" end, dropMappin = function() end,
      swapIn = function(rec, _, hp) swapped[rec] = hp end,
      respawn = function(list) spawned[list[1].record] = list[1].hp end }
    local function fighter(rec, hp)
      G.companion.arena[rec] = true
      M.fighters[rec] = { key = rec, snap = {}, saved = { record = rec }, pos = {}, lastHp = hp,
        hpAt = 0, at = 0, ready = true, gone = 0 }
    end
    M.fighters = {}
    fighter("A", 4) fighter("B", 50) fighter("C", 50)
    assert(M.pointsUsed() == 6, "fighters count against capacity")
    M.leave("A", "ko")
    assert(swapped.A == KO_PCT and M.count() == 2 and toasts[1] == "A lost", "knockout keeps the bout")
    M.leave("B", "ko")
    assert(M.count() == 0 and swapped.C == 50 and toasts[3] == "C won", "last one standing wins")
    fighter("D", 80) fighter("E", 80)
    M.leave("D", "withdraw")
    assert(M.count() == 0 and toasts[#toasts] == "need two" and swapped.E == 80, "withdrawal cancels")
    fighter("F", 30) fighter("H", 30)
    M.abort(false)
    assert(M.count() == 0 and swapped.F == nil and spawned.F == nil, "abort leaves restore to the caller")
    fighter("I", 30) fighter("J", 30)
    M.abort(true)
    assert(spawned.I == 30 and toasts[#toasts] == "cancel", "cancel respawns near the player")
    return true
  end

  return M
end
