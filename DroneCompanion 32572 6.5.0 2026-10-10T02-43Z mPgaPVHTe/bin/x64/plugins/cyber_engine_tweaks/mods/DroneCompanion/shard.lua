return function(G)
  local M = { ready = false }

  local ACTION = nil
  local WANTED = { "Use", "ActivateDevice", "TogglePower" }
  local AS_NAME = "Consume"

  local function actionName(rec)
    local ok, name = pcall(function() return NameToString(rec:ActionName()) end)
    if ok and name and name ~= "" and name ~= "None" then return name end
    return nil
  end

  local function hasUI(rec)
    local ok, ui = pcall(function() return rec:ObjectActionUI() end)
    return ok and ui ~= nil
  end

  local DONOR_NAME = "Consume"

  local function firstItemAction()
    local ok, recs = pcall(function()
      return TweakDB:GetRecords("gamedataObjectAction_Record")
    end)
    if not ok or not recs then
      G.log("shard: GetRecords unavailable: " .. tostring(recs))
      return nil
    end
    local byName, seen, scanned, noName = {}, {}, 0, 0
    for _, rec in ipairs(recs) do
      scanned = scanned + 1
      local name = actionName(rec)
      if not name then
        noName = noName + 1
      else
        if not seen[name] then
          seen[name] = true
          table.insert(seen, name)
        end
        if not byName[name] then byName[name] = rec:GetID() end
      end
    end
    G.log(string.format("shard: %d actions, %d without name, %d distinct",
      scanned, noName, #seen))
    for _, want in ipairs(WANTED) do
      if byName[want] then
        DONOR_NAME = want
        G.log(string.format("shard: donor '%s' = %s", want, tostring(byName[want])))
        return byName[want]
      end
    end
    return nil
  end

  local function buildAction()
    local id = G.TDB .. "SummonAction"
    if TweakDB:GetRecord(id) ~= nil then return id end

    local donor = firstItemAction()
    if not donor then
      G.log("shard: no item action donor found, summon-from-shard disabled")
      return nil
    end

    local ui = id .. "UI"
    if TweakDB:GetRecord(ui) == nil then
      if TweakDB:GetRecord("Interactions.PingHack") == nil then
        G.log("shard: Interactions.PingHack missing, cannot build action UI")
        return nil
      end
      TweakDB:CloneRecord(ui, "Interactions.PingHack")
    end
    local locKey = "Mod-DroneCompanion-Summon"
    local okCaption = pcall(function()
      TweakDB:SetFlatNoUpdate(ui .. ".caption", LocKey(locKey))
    end)
    if not okCaption then
      TweakDB:SetFlatNoUpdate(ui .. ".caption", locKey)
    end
    TweakDB:Update(ui)

    TweakDB:CloneRecord(id, donor)
    CName.add(AS_NAME)
    TweakDB:SetFlatNoUpdate(id .. ".actionName", AS_NAME)
    TweakDB:SetFlatNoUpdate(id .. ".isQuickHack", false)
    TweakDB:SetFlatNoUpdate(id .. ".objectActionUI", ui)
    TweakDB:SetFlatNoUpdate(id .. ".completionEffects", {})
    TweakDB:SetFlatNoUpdate(id .. ".startEffects", {})
    TweakDB:SetFlatNoUpdate(id .. ".instigatorPrereqs", {})
    TweakDB:SetFlatNoUpdate(id .. ".targetActivePrereqs", {})
    TweakDB:Update(id)
    return id
  end

  function M.setup()
    ACTION = buildAction()
    if not ACTION then return end
    local hooked = 0
    for _, ch in ipairs(G.CHASSIS) do
      local item = G.shardId(ch.key)
      if TweakDB:GetRecord(item) ~= nil then
        TweakDB:SetFlat(item .. ".objectActions", { ACTION })
        hooked = hooked + 1
      end
    end
    M.ready = hooked > 0
    G.log(string.format("shard: summon action on %d/%d shards", hooked, #G.CHASSIS))
  end

  function M.learnRecipes()
    pcall(function()
      local player = Game.GetPlayer()
      if player then player:DCLearnRecipes() end
    end)
  end

  local function craftChassisOf(recipe)
    local ok, path = pcall(function()
      return G.records.pathOf(tostring(recipe.id:GetID()))
    end)
    if not ok or type(path) ~= "string" then return nil end
    local fam = path:match("Craft(%a+)$")
    if fam and path == G.TDB .. "Craft" .. fam and G.chassisOf(fam) then
      return fam
    end
    return nil
  end

  function M.installCraftHook()
    Override("CraftingLogicController", "CraftItem", function(_, recipe, amount, wrapped)
      local fam = craftChassisOf(recipe)
      if not fam then return wrapped(recipe, amount) end
      local ok, why = G.companion.canDeploy(fam)
      if not ok then
        if why and why ~= "" then G.notify(why) end
        return
      end
      G.menu.openPicker(fam)
    end)
  end

  function M.craftConfirm(fam, facKey, armKey)
    local index, model
    for i, m in ipairs(G.MODELS) do
      if m.key == fam .. facKey then
        index, model = i, m
        break
      end
    end
    if not index then return end
    local ok, why = G.companion.canDeploy(fam)
    if not ok then
      if why and why ~= "" then G.notify(why) end
      return
    end
    local paid = false
    pcall(function()
      paid = Game.GetPlayer():DCCraftItem(TweakDBID.new(G.TDB .. "Craft" .. fam)) == true
    end)
    if not paid then
      G.notify(G.STR.pk_nomats)
      return
    end
    G.Cron.After(0.2, function()
      pcall(function()
        local player = Game.GetPlayer()
        local ts = Game.GetTransactionSystem()
        local itemId = ItemID.FromTDBID(TweakDBID.new(G.TDB .. "Craft" .. fam))
        local n = ts:GetItemQuantity(player, itemId)
        if n > 0 then ts:RemoveItem(player, itemId, n) end
      end)
      G.ui.selectedIndex = index
      G.companion.summon(index, true, model.chassis == "Android" and armKey or nil)
    end)
  end

  function M.summonByChassis(fam, skipShard)
    local ch = G.chassisOf(fam)
    if not ch then return end
    local index = G.ui.firstOf(fam)
    for i, model in ipairs(G.MODELS) do
      if model.chassis == fam and i == G.ui.selectedIndex then index = i end
    end
    if not index then return end
    G.ui.selectedIndex = index
    return G.companion.summon(index, skipShard)
  end

  return M
end
