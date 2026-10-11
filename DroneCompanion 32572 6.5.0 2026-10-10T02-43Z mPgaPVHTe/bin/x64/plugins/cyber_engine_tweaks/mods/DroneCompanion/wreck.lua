return function(G)
  local M = { rec = nil, toasted = nil }

  local RANGE = 4.0

  local function entKey(ent)
    if not IsDefined(ent) then return nil end
    local key
    pcall(function() key = tostring(ent:GetEntityID().hash) end)
    return key
  end

  local function nearestWreck(player)
    local pPos = player:GetWorldPosition()
    local best, bestDist
    for rec in pairs(G.companion.wreckUntil) do
      local ent = G.companion.entityOf(rec)
      if IsDefined(ent) then
        local d = Vector4.Distance(pPos, ent:GetWorldPosition())
        if d <= RANGE and (not bestDist or d < bestDist) then best, bestDist = rec, d end
      end
    end
    return best, bestDist
  end

  local function lookedAtWreck(player)
    local target
    pcall(function()
      target = Game.GetTargetingSystem():GetLookAtObject(player, true, false)
    end)
    local key = entKey(target)
    if not key then return nil end
    local pPos = player:GetWorldPosition()
    for rec in pairs(G.companion.wreckUntil) do
      local ent = G.companion.entityOf(rec)
      if entKey(ent) == key and Vector4.Distance(pPos, ent:GetWorldPosition()) <= RANGE then
        return rec
      end
    end
    return nil
  end

  function M.tick()
    local player = Game.GetPlayer()
    if not player then return end
    local rec, dist = nearestWreck(player)
    M.rec = rec
    if rec == M.toasted then return end
    M.toasted = rec
    if not rec then return end
    local model = G.modelOf(rec)
    local cost = G.companion.repairCost(model)
    local name = G.squad.displayName(rec, model)
    G.notify("[" .. G.hotkeys.label(G.prompt.keyOf("wreck") or "F") .. "] "
      .. (cost > 0 and string.format(G.STR.repair_prompt, name, cost) or string.format(G.STR.repair_prompt_free, name)))
    G.log(string.format("wreck toast %s dist=%.1f cost=%d", rec, dist, cost))
  end

  function M.promptTick(player)
    local rec = lookedAtWreck(player)
    if not rec then return nil end
    local model = G.modelOf(rec)
    local cost = G.companion.repairCost(model)
    local label = cost > 0 and string.format(G.STR.repair_cost, cost) or G.STR.repair_free
    return G.squad.displayName(rec, model), label
  end

  function M.onChoice()
    local rec = M.rec
    if not rec then return false end
    G.log("wreck prompt: Choice1 on " .. rec)
    local ok = G.companion.repair(rec)
    if ok then
      M.rec, M.toasted = nil, nil
      G.prompt.set(nil)
    end
    return ok
  end

  return M
end
