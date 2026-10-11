return function(G)
  local M = { on = {}, mods = {}, crouchTicks = 0, lastLoco = nil, crouchValues = {} }

  local CROUCH = { "Crouch", "CrouchSprint" }
  local FALLBACK_CROUCH = { [2] = "Crouch" }
  local DETAILED_CROUCH = { [4] = "Crouch" }
  local HOLD_TICKS = 2

  function M.setup()
    M.crouchValues = {}
    local names = {}
    for _, name in ipairs(CROUCH) do
      local ok, v = pcall(function() return EnumInt(gamePSMLocomotionStates[name]) end)
      if ok and type(v) == "number" then
        M.crouchValues[v] = name
        names[#names + 1] = name .. "=" .. v
      end
    end
    if next(M.crouchValues) == nil then
      for v, name in pairs(FALLBACK_CROUCH) do
        M.crouchValues[v] = name
        names[#names + 1] = name .. "=" .. v .. "(fallback)"
      end
    end
    G.log("ghost: crouch states " .. table.concat(names, ","))
  end

  local function locomotion(player)
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():GetLocalInstanced(player:GetEntityID(), defs.PlayerStateMachine)
    local detailed = -1
    pcall(function() detailed = bb:GetInt(defs.PlayerStateMachine.LocomotionDetailed) end)
    return bb:GetInt(defs.PlayerStateMachine.Locomotion), detailed
  end

  local function crouched(player)
    local ok, loco, detailed = pcall(locomotion, player)
    if not ok or type(loco) ~= "number" then return false end
    local is = M.crouchValues[loco] ~= nil or DETAILED_CROUCH[detailed] ~= nil
    M.lastLoco = loco
    M.lastDetailed = detailed
    M.lastCrouch = is
    return is
  end

  local GHOST = {
    { stat = "DetectionSpeedDecrease", kind = "Additive", value = 1.0 },
    { stat = "Visibility", kind = "Multiplier", value = 0.0 },
  }

  local function set(ent, rec, on)
    local ok, err = pcall(function()
      local ss = Game.GetStatsSystem()
      local id = ent:GetEntityID()
      for _, mod in ipairs(M.mods[rec] or {}) do ss:RemoveModifier(id, mod) end
      M.mods[rec] = nil
      if on then
        local mods = {}
        for _, g in ipairs(GHOST) do
          local mod = RPGManager.CreateStatModifier(gamedataStatType[g.stat],
            gameStatModifierType[g.kind], g.value)
          ss:AddModifier(id, mod)
          mods[#mods + 1] = mod
        end
        M.mods[rec] = mods
        M.on[rec] = true
      else
        M.on[rec] = nil
      end
    end)
    if not ok then G.log(string.format("ghost %s %s failed: %s", on and "on" or "off", rec, tostring(err))) end
  end

  function M.tick()
    local player = Game.GetPlayer()
    local want = false
    if G.settings.stealthGhost and player then
      local inCombat = false
      pcall(function() inCombat = player:IsInCombat() end)
      local piloted = G.dronecam and G.dronecam.active
      want = crouched(player) and not inCombat and not piloted
    end
    M.crouchTicks = want and M.crouchTicks + 1 or 0
    local apply = M.crouchTicks >= HOLD_TICKS
    local seen = {}
    for _, row in ipairs(G.companion.aliveCache or {}) do
      if IsDefined(row.ent) and not row.model.static and not row.ent:IsDead() then
        seen[row.rec] = true
        if apply and not M.on[row.rec] then
          set(row.ent, row.rec, true)
        elseif not apply and M.on[row.rec] then
          set(row.ent, row.rec, false)
        end
      end
    end
    for rec in pairs(M.on) do
      if not seen[rec] then
        M.on[rec] = nil
        M.mods[rec] = nil
      end
    end
  end

  return M
end
