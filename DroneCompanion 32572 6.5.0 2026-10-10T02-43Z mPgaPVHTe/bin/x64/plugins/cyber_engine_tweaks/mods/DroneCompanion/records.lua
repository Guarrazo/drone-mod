return function(G)
  local M = {}
  local setupCombatStateEffects, tweakFollowerCommonBehavior, setupVehicle

  function M.pathOf(id)
    if id == nil then return nil end
    local raw = tostring(id)
    return raw:match("%-%-%[%[%s*([%w_%.]+)") or raw
  end

  local COPY = {
    "abilities", "actionMap", "affiliation", "appearanceName", "archetypeData",
    "archetypeName", "attachmentSlots", "audioResourceName", "audioMeleeMaterial",
    "baseAttitudeGroup", "characterType", "communitySquad", "contentAssignment",
    "crowdMemberSettings", "defaultCrosshair", "defaultEquipment", "displayName",
    "driving", "dropsAmmoOnDeath", "dropsMoneyOnDeath", "dropsWeaponOnDeath",
    "effectors", "enableSensesOnStart", "entityTemplatePath", "fullDisplayName",
    "genders", "idleActions", "isBumpable", "itemGroups", "items", "lootDrop",
    "objectActions", "onSpawnGLPs", "persistentName", "primaryEquipment",
    "priority", "quest", "rarity", "reactionPreset", "referenceName", "savable",
    "scannerModulePreset", "secondaryEquipment", "sensePreset", "squadParamsID",
    "startingEquippedItems", "stateMachineName", "statModifierGroups",
    "statModifiers", "statPools", "tags", "threatTrackingPreset", "uiNameplate",
    "vendorID", "visualTags", "voiceTag", "weakspots",
  }
  local COPY_CNAME = {
    "alertedSensesPreset", "combatSensesPreset", "keepColliderOnDeath",
    "relaxedSensesPreset", "statusEffectParamsPackageName", "weaponSlot",
  }
  local COPY_FLOAT = {
    "airDeathRagdollDelay", "combatDefaultZOffset", "mass",
    "massNormalizedCoefficient", "pseudoAcceleration", "sizeBack", "sizeFront",
    "sizeLeft", "sizeRight", "speedIdleThreshold", "startingRecoveryBalance",
    "tiltAngleOnSpeed", "turnInertiaDamping", "walkTiltCoefficient",
  }

  local function appendToFlat(flatPath, value, createIfMissing)
    local list = TweakDB:GetFlat(flatPath)
    if list == nil then
      if not createIfMissing then
        G.log("missing vanilla flat: " .. flatPath)
        return false
      end
      list = {}
    end
    for _, v in ipairs(list) do
      if tostring(v) == tostring(value) then return true end
    end
    table.insert(list, value)
    TweakDB:SetFlat(flatPath, list)
    return true
  end

  M.appendToFlat = appendToFlat

  local function ensureRecord(id, recordType)
    if TweakDB:GetRecord(id) == nil then
      TweakDB:CreateRecord(id, recordType)
    end
  end

  function M.applyMechArmor()
    pcall(function()
      local player = Game.GetPlayer()
      if player then player:DCSetMechArmor(G.settings.mechArmor == true) end
    end)
  end

  function M.applyAndroidHeads()
    pcall(function()
      local player = Game.GetPlayer()
      if player then player:DCSetAndroidHeads(G.settings.androidHeads == true) end
    end)
  end

  local function buildSubCharacter(id, base, tag)
    if TweakDB:GetRecord(base) == nil then
      G.log("ERROR: base record not found: " .. base)
      return
    end
    ensureRecord(id, "gamedataSubCharacter_Record")
    for _, f in ipairs(COPY) do
      local flat = TweakDB:GetFlat(base .. "." .. f)
      if flat ~= nil then TweakDB:SetFlatNoUpdate(id .. "." .. f, flat) end
    end
    for _, f in ipairs(COPY_CNAME) do
      local flat = TweakDB:GetFlat(base .. "." .. f)
      if flat ~= nil then TweakDB:SetFlat(id .. "." .. f, flat) end
    end
    for _, f in ipairs(COPY_FLOAT) do
      local flat = TweakDB:GetFlat(base .. "." .. f)
      if flat ~= nil then TweakDB:SetFlat(id .. "." .. f, flat, "Float") end
    end
    TweakDB:SetFlatNoUpdate(id .. ".baseAttitudeGroup", "player")
    TweakDB:SetFlatNoUpdate(id .. ".disableDefeatedState", true)
    TweakDB:SetFlatNoUpdate(id .. ".dropsWeaponOnDeath", false)
    TweakDB:SetFlatNoUpdate(id .. ".lootBagEntity", "None")
    if tag then
      TweakDB:SetFlatNoUpdate(id .. ".visualTags", { tag })
    end
    TweakDB:Update(id)

    local tpl = TweakDB:GetFlat(id .. ".entityTemplatePath")
    if tpl == nil or tostring(tpl) == "" then
      G.log("WARNING: " .. id .. " has no entityTemplatePath (base flat unreadable?)")
    end
  end

  local STAT_FLATS = { "statPools", "statModifierGroups", "rarity" }

  local function borrowStats(id, donor)
    if TweakDB:GetRecord(donor) == nil then
      G.log("ERROR: stat donor not found: " .. donor)
      return
    end
    for _, f in ipairs(STAT_FLATS) do
      local flat = TweakDB:GetFlat(donor .. "." .. f)
      if flat ~= nil then TweakDB:SetFlatNoUpdate(id .. "." .. f, flat) end
    end
    TweakDB:Update(id)
  end

  local function createStatModifier(id, modType, stat, value)
    ensureRecord(id, "gamedataConstantStatModifier_Record")
    TweakDB:SetFlatNoUpdate(id .. ".modifierType", modType)
    TweakDB:SetFlatNoUpdate(id .. ".statType", stat)
    TweakDB:SetFlatNoUpdate(id .. ".value", value)
    TweakDB:Update(id)
  end

  function M.applyCatchUp()
    local id = G.TDB .. "FollowerAboveNear"
    if TweakDB == nil or TweakDB:GetRecord(id) == nil then return end
    local old = TweakDB:GetFlat(id .. ".distance")
    local range = Vector2.new()
    range.X = G.tuning.get("catchup")
    range.Y = (old and old.Y) or -1
    TweakDB:SetFlat(id .. ".distance", range)
  end

  local GUNSMITHS = {
    "wat_nid_gunsmith_01", "wat_lch_gunsmith_01", "wat_kab_gunsmith_01",
    "wat_kab_gunsmith_02", "wbr_jpn_gunsmith_01", "cct_dtn_guns_01",
    "hey_spr_gunsmith_01", "hey_gle_gunsmith_01", "hey_rey_gunsmith_01",
    "std_arr_gunsmith_01", "std_rcr_gunsmith_01", "pac_wwd_gunsmith_01",
    "bls_ina_se1_gunsmith_01a", "bls_ina_se1_gunsmith_02",
    "bls_ina_se5_gunsmith_01", "cz_stadium_gunsmith_01", "cz_con_gunsmith_01",
  }
  local SHARD_STOCKS = {
    { stock = "StockBombus", item = "ShardBombus" },
    { stock = "StockOctant", item = "ShardOctant" },
    { stock = "StockAndroid", item = "ShardAndroid" },
    { stock = "StockGriffin", item = "ShardGriffin" },
    { stock = "StockWyvern", item = "ShardWyvern" },
    { stock = "StockMinotaur", item = "ShardMinotaur" },
    { stock = "StockCerberus", item = "ShardCerberus" },
    { stock = "StockShardFlathead", item = "ShardFlathead" },
    { stock = "StockShardChimera", item = "ShardChimera" },
  }
  local FIRM_STOCKS = { "StockUpCombat", "StockUpSupport", "StockUpUtility" }

  local function ownedQty(itemId)
    local n = 0
    pcall(function()
      n = Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(),
        ItemID.FromTDBID(TweakDBID.new(G.TDB .. itemId)))
    end)
    return n
  end

  local function setStock(vendor, wanted)
    local path = "Vendors." .. vendor .. ".itemStock"
    local list = TweakDB:GetFlat(path)
    if list == nil then return end
    local out, have = {}, {}
    for _, v in ipairs(list) do
      local name = M.pathOf(v)
      local keep = true
      for stockName, want in pairs(wanted) do
        if name == G.TDB .. stockName then
          have[stockName] = true
          keep = want
        end
      end
      if keep then table.insert(out, v) end
    end
    for stockName, want in pairs(wanted) do
      if want and not have[stockName] then
        table.insert(out, TweakDBID.new(G.TDB .. stockName))
      end
    end
    TweakDB:SetFlat(path, out)
  end

  local FIRM_PRICE_STEP = 1.25
  local firmBasePrice = {}

  function M.applyFirmPrices()
    for _, f in ipairs(FIRM_STOCKS) do
      local item = f:gsub("^Stock", "")
      local path = G.TDB .. item .. "Price.value"
      if firmBasePrice[item] == nil then
        local base = nil
        pcall(function() base = TweakDB:GetFlat(path) end)
        firmBasePrice[item] = tonumber(base) or 15000
      end
      local owned = G.tuning.upCount(item)
      local price = math.floor(firmBasePrice[item] * (FIRM_PRICE_STEP ^ owned) + 0.5)
      local ok = pcall(function() TweakDB:SetFlat(path, price, "Float") end)
      if not ok then G.log(string.format("firmware price %s: SetFlat failed", item)) end
    end
  end

  function M.stockSignature()
    local sig = G.settings.immersive and "i" or "-"
    for _, s in ipairs(SHARD_STOCKS) do
      sig = sig .. (ownedQty(s.item) > 0 and "1" or "0")
    end
    return sig .. (ownedQty("RiggerGatekeeper") > 0 and "G" or "g")
  end

  function M.refreshStocks()
    local anyShard = false
    local wanted = {}
    for _, s in ipairs(SHARD_STOCKS) do
      local has = ownedQty(s.item) > 0
      if has then anyShard = true end
      wanted[s.stock] = not has
    end
    local firmOk = anyShard or not G.settings.immersive
    for _, f in ipairs(FIRM_STOCKS) do wanted[f] = firmOk end
    wanted.StockGatekeeper = ownedQty("RiggerGatekeeper") <= 0
    for _, v in ipairs(GUNSMITHS) do pcall(setStock, v, wanted) end
    M.applyFirmPrices()
  end

  local function statModId(model, field)
    return G.TDB .. (field == "dmg" and "Dmg_" or "HP_") .. model.key
  end

  local function makeEquipGroup(groupId, item, slot, donor)
    local entry = groupId .. "Entry"
    if TweakDB:GetRecord(entry) == nil then
      TweakDB:CloneRecord(entry, donor or "Character.max_border_guards_baton_inline1")
    end
    TweakDB:SetFlatNoUpdate(entry .. ".item", item)
    TweakDB:SetFlat(entry .. ".equipSlot", slot)
    ensureRecord(groupId, "gamedataNPCEquipmentGroup_Record")
    TweakDB:SetFlat(groupId .. ".equipmentItems", { entry })
  end

  local function makeEquipPair(groupId, itemRight, itemLeft)
    local right, left = groupId .. "R", groupId .. "L"
    for _, pair in ipairs({ { right, itemRight, "AttachmentSlots.WeaponRight" },
                            { left, itemLeft, "AttachmentSlots.WeaponLeft" } }) do
      if TweakDB:GetRecord(pair[1]) == nil then
        TweakDB:CloneRecord(pair[1], "Character.max_border_guards_baton_inline1")
      end
      TweakDB:SetFlatNoUpdate(pair[1] .. ".item", pair[2])
      TweakDB:SetFlat(pair[1] .. ".equipSlot", pair[3])
    end
    ensureRecord(groupId, "gamedataNPCEquipmentGroup_Record")
    TweakDB:SetFlat(groupId .. ".equipmentItems", { right, left })
  end

  local function explosiveWeapon(id, weaponClone, effectClone, projectileClone, explodeClone,
    bulletMult, blastMult)
    if TweakDB:GetRecord(weaponClone) == nil then
      G.log("weapon source missing: " .. weaponClone)
      return false
    end
    if TweakDB:GetRecord(id) == nil then TweakDB:CloneRecord(id, weaponClone) end

    ensureRecord(id .. "_pkg", "gamedataRangedAttackPackage_Record")
    ensureRecord(id .. "_atk", "gamedataRangedAttack_Record")
    for _, pair in ipairs({ { "_proj", projectileClone }, { "_eff", effectClone },
                            { "_blast", explodeClone } }) do
      if TweakDB:GetRecord(id .. pair[1]) == nil then
        if TweakDB:GetRecord(pair[2]) == nil then
          G.log("attack source missing: " .. pair[2])
          return false
        end
        TweakDB:CloneRecord(id .. pair[1], pair[2])
      end
    end

    createStatModifier(id .. "_blastDmg", "Multiplier", "BaseStats.PhysicalDamage", blastMult)
    createStatModifier(id .. "_bulletDmg", "Multiplier", "BaseStats.PhysicalDamage", bulletMult)

    TweakDB:SetFlatNoUpdate(id .. "_blast.playerIncomingDamageMultiplier", 1.0)
    TweakDB:SetFlatNoUpdate(id .. "_blast.range", 2.0)
    appendToFlat(id .. "_blast.statModifiers", id .. "_blastDmg")

    TweakDB:SetFlat(id .. "_proj.explosionAttack", id .. "_blast")
    TweakDB:SetFlat(id .. "_proj.hitCooldown", 0.1, "Float")
    appendToFlat(id .. "_proj.statModifiers", id .. "_bulletDmg")

    TweakDB:SetFlat(id .. "_eff.explosionAttack", id .. "_blast")
    appendToFlat(id .. "_eff.statModifiers", id .. "_bulletDmg")

    TweakDB:SetFlatNoUpdate(id .. "_atk.NPCAttack", id .. "_eff")
    TweakDB:SetFlatNoUpdate(id .. "_atk.NPCTimeDilated", id .. "_proj")
    TweakDB:SetFlatNoUpdate(id .. "_atk.playerAttack", id .. "_eff")
    TweakDB:SetFlat(id .. "_atk.playerTimeDilated", id .. "_proj")

    TweakDB:SetFlatNoUpdate(id .. "_pkg.chargeFire", id .. "_atk")
    TweakDB:SetFlat(id .. "_pkg.defaultFire", id .. "_atk")

    TweakDB:SetFlatNoUpdate(id .. ".rangedAttacks", id .. "_pkg")
    appendToFlat(id .. ".attacks", id .. "_proj", true)
    appendToFlat(id .. ".attacks", id .. "_eff", true)
    TweakDB:Update(id)
    return true
  end

  M.LOADOUTS = {
    { key = "default", item = nil },
    { key = "rifle",   item = "Items.Preset_Ajax_Military" },
    { key = "shotgun", item = "Items.Preset_Satara_Military" },
    { key = "sniper",  item = "Items.Preset_Nekomata_Military" },
    { key = "melee",   item = "Items.Preset_Katana_Military" },
    { key = "handgun", item = "Items.Preset_Lexington_Neon" },
    { key = "lmg",     item = "Items.Preset_Defender_Military" },
  }

  function M.loadoutItem(loadoutKey)
    if type(loadoutKey) == "string" and loadoutKey:sub(1, 5) == "item:" then
      return loadoutKey:sub(6)
    end
    for _, lo in ipairs(M.LOADOUTS) do
      if lo.key == loadoutKey and lo.item and not lo.broken then return lo.item end
    end
    return nil
  end

  local function setupLoadouts()
    for _, lo in ipairs(M.LOADOUTS) do
      if lo.item then
        if TweakDB:GetRecord(lo.item) == nil then
          G.log("loadout item missing: " .. lo.item)
          lo.broken = true
        else
          makeEquipGroup(G.TDB .. "Loadout" .. lo.key, lo.item, "AttachmentSlots.WeaponRight")
        end
      end
    end
  end

  local function loadoutGroup(loadoutKey)
    for _, lo in ipairs(M.LOADOUTS) do
      if lo.key == loadoutKey and lo.item and not lo.broken then
        return G.TDB .. "Loadout" .. lo.key
      end
    end
    if type(loadoutKey) == "string" and loadoutKey:sub(1, 5) == "item:" then
      local item = loadoutKey:sub(6)
      if TweakDB:GetRecord(item) ~= nil then
        local group = G.TDB .. "LoadoutItem_" .. item:gsub("[^%w]", "_")
        makeEquipGroup(group, item, "AttachmentSlots.WeaponRight")
        return group
      end
    end
    return nil
  end

  local function setPrimary(id, model, group)
    if group then
      TweakDB:SetFlat(id .. ".primaryEquipment", group)
    else
      local base = TweakDB:GetFlat(model.base .. ".primaryEquipment")
      if base ~= nil then TweakDB:SetFlat(id .. ".primaryEquipment", base) end
    end
  end

  function M.applyLoadout(model, loadoutKey)
    local group = loadoutGroup(loadoutKey)
    for i = 1, G.INSTANCES do
      local rec = G.recordId(model, i)
      local own = G.companion and G.companion.weaponOf[rec]
      if own then setPrimary(rec, model, loadoutGroup(own)) else setPrimary(rec, model, group) end
    end
    G.log(string.format("loadout %s -> %s", model.key, loadoutKey))
  end

  function M.applyLoadoutRec(model, rec, loadoutKey)
    setPrimary(rec, model, loadoutGroup(loadoutKey))
    G.log(string.format("loadout %s -> %s", rec, loadoutKey))
  end

  local function setupWeapons()

    if TweakDB:GetRecord(G.TDB .. "SmartAutocannon") == nil then
      TweakDB:CloneRecord(G.TDB .. "SmartAutocannon", "Items.Octant_Autocannon")
      TweakDB:CloneRecord(G.TDB .. "SmartAutocannonRPG", "Items.Octant_Autocannon_inline0")
    end
    TweakDB:SetFlat(G.TDB .. "SmartAutocannonRPG.statModifierGroups", {
      "Items.Octant_Autocannon_Handling_Stats",
      "Items.Wyvern_Rifle_SmartGun_Stats",
      "Items.Wyvern_Rifle_Projectile_Stats",
    })
    TweakDB:SetFlatNoUpdate(G.TDB .. "SmartAutocannon.evolution", "WeaponEvolution.Smart")
    TweakDB:SetFlatNoUpdate(G.TDB .. "SmartAutocannon.npcRPGData", G.TDB .. "SmartAutocannonRPG")
    TweakDB:SetFlatNoUpdate(G.TDB .. "SmartAutocannon.rangedAttacks", "Attacks.SmartBulletDronePackage")
    TweakDB:Update(G.TDB .. "SmartAutocannon")
    makeEquipGroup(G.TDB .. "SmartCannonEquip", G.TDB .. "SmartAutocannon", "AttachmentSlots.WeaponRight")

    if not G.settings.explosive then return end

    local built = {}
    if explosiveWeapon(G.TDB .. "BoomAutocannon", "Items.Octant_Autocannon",
      "Attacks.NPCBulletEffect", "Attacks.NPCBulletProjectile", "Attacks.BulletExplosion",
      0.6, 0.6) then
      makeEquipGroup(G.TDB .. "BoomCannonEquip", G.TDB .. "BoomAutocannon",
        "AttachmentSlots.WeaponRight")
      table.insert(built, "Octant")
    end

    local right = explosiveWeapon(G.TDB .. "BoomGriffinR", "Items.Griffin_Rifle_Right",
      "Attacks.NPCBulletEffect", "Attacks.NPCBulletProjectile", "Attacks.BulletExplosion",
      0.5, 0.5)
    local left = explosiveWeapon(G.TDB .. "BoomGriffinL", "Items.Griffin_Rifle_Left",
      "Attacks.NPCBulletEffect", "Attacks.NPCBulletProjectile", "Attacks.BulletExplosion",
      0.5, 0.5)
    if right and left then
      makeEquipPair(G.TDB .. "BoomGriffinEquip", G.TDB .. "BoomGriffinR", G.TDB .. "BoomGriffinL")
      table.insert(built, "Griffin")
    end

    if explosiveWeapon(G.TDB .. "BoomWyvern", "Items.Wyvern_Rifle",
      "Attacks.NPCSmartBullet", "Attacks.NPCSmartBullet",
      "Attacks.BulletSmartBulletHighExplosion", 0.5, 0.5) then
      makeEquipGroup(G.TDB .. "BoomWyvernEquip", G.TDB .. "BoomWyvern",
        "AttachmentSlots.WeaponRight")
      table.insert(built, "Wyvern")
    end
    local function firstOf(flatPath)
      if flatPath == nil then return nil end
      local list = TweakDB:GetFlat(flatPath)
      return list ~= nil and list[1] or nil
    end

    local function weaponFrom(groupId)
      local entry = firstOf(M.pathOf(groupId) .. ".equipmentItems")
      if entry == nil then return nil end
      local item = TweakDB:GetFlat(M.pathOf(entry) .. ".item")
      if item ~= nil then return item end
      local pool = firstOf(M.pathOf(entry) .. ".pool")
      if pool == nil then return nil end
      local poolItem = firstOf(M.pathOf(pool) .. ".items")
      return poolItem ~= nil and TweakDB:GetFlat(M.pathOf(poolItem) .. ".item") or nil
    end

    local mechWeapon
    local group = TweakDB:GetFlat("Character.militech_base_minotaur.primaryEquipment")
    if group ~= nil then mechWeapon = weaponFrom(group) end
    if mechWeapon ~= nil and explosiveWeapon(G.TDB .. "BoomMinotaur", M.pathOf(mechWeapon),
      "Attacks.NPCSmartBullet", "Attacks.NPCSmartBullet",
      "Attacks.BulletSmartBulletHighExplosion", 0.5, 0.5) then
      makeEquipGroup(G.TDB .. "BoomMinotaurEquip", G.TDB .. "BoomMinotaur",
        "AttachmentSlots.WeaponRight")
      table.insert(built, "Minotaur")
    else
      G.log("mech weapon not resolved from base record: " .. tostring(mechWeapon))
    end

    G.log("explosive weapons: " .. (#built > 0 and table.concat(built, ", ") or "none built"))
  end

  local WEAPON_EQUIP = {
    smart = "SmartCannonEquip",
  }

  local EXPLOSIVE_EQUIP = {
    Octant = "BoomCannonEquip",
    Griffin = "BoomGriffinEquip",
    Wyvern = "BoomWyvernEquip",
    Minotaur = "BoomMinotaurEquip",
  }

  local function tweakFollowerBehavior()

    if TweakDB:GetRecord(G.TDB .. "FollowerBelow100m") == nil then
      TweakDB:CloneRecord(G.TDB .. "FollowerBelow100m", "Condition.FollowerBelow10m")
    end
    local range = Vector2.new()
    range.X = -1
    range.Y = 100
    TweakDB:SetFlat(G.TDB .. "FollowerBelow100m.distance", range)

    if TweakDB:GetRecord(G.TDB .. "FollowerAboveNear") == nil
      and TweakDB:GetRecord("Condition.FollowerAbove17m") ~= nil then
      TweakDB:CloneRecord(G.TDB .. "FollowerAboveNear", "Condition.FollowerAbove17m")
    end
    M.applyCatchUp()
    local aboveCond = TweakDB:GetRecord(G.TDB .. "FollowerAboveNear") ~= nil
      and (G.TDB .. "FollowerAboveNear") or "Condition.FollowerAbove17m"

    ensureRecord(G.TDB .. "CatchUpRange", "gamedataAIActionAND_Record")
    TweakDB:SetFlat(G.TDB .. "CatchUpRange.AND",
      { aboveCond, G.TDB .. "FollowerBelow100m" })

    appendToFlat("FollowerActions.TeleportToTarget_inline2.OR", G.TDB .. "CatchUpRange")
    appendToFlat("DroneActions.EvaluateTeleportToTarget_inline2.AND", G.TDB .. "FollowerBelow100m")

    if TweakDB:GetFlat("FollowerActions.TeleportToFollower_inline0.duration") ~= nil then
      TweakDB:SetFlat("FollowerActions.TeleportToFollower_inline0.duration", 0.1, "Float")
    end

    if TweakDB:GetFlat("Condition.FollowFarStopCondition_inline1.AND") ~= nil then
      TweakDB:SetFlat("Condition.FollowFarStopCondition_inline1.AND",
        { "Condition.IsDistanceToDestinationInMediumRange" })
    end
  end

  function M.setup()

    ensureRecord(G.TDB .. "CompanionSE", "gamedataStatusEffect_Record")
    TweakDB:SetFlatNoUpdate(G.TDB .. "CompanionSE.duration", "BaseStats.InfiniteDuration")
    TweakDB:SetFlatNoUpdate(G.TDB .. "CompanionSE.statusEffectType", "BaseStatusEffectTypes.Misc")
    TweakDB:Update(G.TDB .. "CompanionSE")

    ensureRecord(G.TDB .. "DefensiveSE", "gamedataStatusEffect_Record")
    TweakDB:SetFlatNoUpdate(G.TDB .. "DefensiveSE.duration", "BaseStats.InfiniteDuration")
    TweakDB:SetFlatNoUpdate(G.TDB .. "DefensiveSE.statusEffectType", "BaseStatusEffectTypes.Misc")
    TweakDB:Update(G.TDB .. "DefensiveSE")

    ensureRecord(G.TDB .. "RetreatSE", "gamedataStatusEffect_Record")
    TweakDB:SetFlatNoUpdate(G.TDB .. "RetreatSE.duration", "BaseStats.InfiniteDuration")
    TweakDB:SetFlatNoUpdate(G.TDB .. "RetreatSE.statusEffectType", "BaseStatusEffectTypes.Misc")
    TweakDB:Update(G.TDB .. "RetreatSE")

    ensureRecord(G.TDB .. "ArenaSE", "gamedataStatusEffect_Record")
    TweakDB:SetFlatNoUpdate(G.TDB .. "ArenaSE.duration", "BaseStats.InfiniteDuration")
    TweakDB:SetFlatNoUpdate(G.TDB .. "ArenaSE.statusEffectType", "BaseStatusEffectTypes.Misc")
    TweakDB:Update(G.TDB .. "ArenaSE")

    ensureRecord(G.TDB .. "PassiveSE", "gamedataStatusEffect_Record")
    TweakDB:SetFlatNoUpdate(G.TDB .. "PassiveSE.duration", "BaseStats.InfiniteDuration")
    TweakDB:SetFlatNoUpdate(G.TDB .. "PassiveSE.statusEffectType", "BaseStatusEffectTypes.Misc")
    TweakDB:Update(G.TDB .. "PassiveSE")

    for _, ch in ipairs(G.CHASSIS) do
      local se = G.TDB .. "Chassis" .. ch.key .. "SE"
      ensureRecord(se, "gamedataStatusEffect_Record")
      TweakDB:SetFlatNoUpdate(se .. ".duration", "BaseStats.InfiniteDuration")
      TweakDB:SetFlatNoUpdate(se .. ".statusEffectType", "BaseStatusEffectTypes.Misc")
      TweakDB:Update(se)
    end

    for _, ch in ipairs(G.CHASSIS) do
      local v = TweakDB:GetFlat(G.TDB .. "ShardPrice" .. ch.key .. ".value")
        or TweakDB:GetFlat(G.TDB .. "Shard" .. ch.key .. "Price.value")
      if v then
        ch.price = math.floor(tonumber(v) or 0)
      else
        G.log("shard price flat missing for " .. ch.key .. " (TweakXL yaml not loaded?)")
      end
    end

    local function onHitTrigger(id)
      ensureRecord(id, "gamedataMultiPrereq_Record")
      TweakDB:SetFlatNoUpdate(id .. ".aggregationType", "AND")
      TweakDB:SetFlatNoUpdate(id .. ".prereqClassName", "gameMultiPrereq")
      if TweakDB:GetRecord(id .. "Hit") == nil then
        TweakDB:CloneRecord(id .. "Hit", "Items.ElectroshockMechanismEffector_inline0")
      end
      TweakDB:SetFlat(id .. ".nestedPrereqs", { id .. "Hit" })
    end

    local function onHitAbility(name, seId, duration)
      local se = G.TDB .. seId
      ensureRecord(se, "gamedataStatusEffect_Record")
      ensureRecord(se .. "Dur", "gamedataStatModifierGroup_Record")
      TweakDB:SetFlatNoUpdate(se .. "Dur.statModsLimit", -1)
      createStatModifier(se .. "DurMod", "Additive", "BaseStats.MaxDuration", duration)
      TweakDB:SetFlat(se .. "Dur.statModifiers", { se .. "DurMod" })
      TweakDB:SetFlatNoUpdate(se .. ".duration", se .. "Dur")
      TweakDB:SetFlat(se .. ".statusEffectType", "BaseStatusEffectTypes.Misc")

      local ab = G.TDB .. name
      ensureRecord(ab, "gamedataGameplayAbility_Record")
      ensureRecord(ab .. "Pkg", "gamedataGameplayLogicPackage_Record")
      ensureRecord(ab .. "Apply", "gamedataApplyStatusEffectEffector_Record")
      TweakDB:SetFlatNoUpdate(ab .. "Apply.count", 1)
      TweakDB:SetFlatNoUpdate(ab .. "Apply.effectorClassName", "ApplyStatusEffectEffector")
      TweakDB:SetFlatNoUpdate(ab .. "Apply.statusEffect", se)
      onHitTrigger(ab .. "OnHit")
      TweakDB:SetFlat(ab .. "Apply.prereqRecord", ab .. "OnHit")
      TweakDB:SetFlat(ab .. "Pkg.effectors", { ab .. "Apply" })
      TweakDB:SetFlat(ab .. ".abilityPackage", ab .. "Pkg")
      return se
    end

    local function setupChassisTraits()
      local se = onHitAbility("TraitRepair", "TraitRepairSE", 3.0)
      ensureRecord(se .. "Pkg", "gamedataGameplayLogicPackage_Record")
      if TweakDB:GetRecord(se .. "Heal") == nil then
        TweakDB:CloneRecord(se .. "Heal", "BaseStatusEffect.Health_Regen_inline4")
      end
      TweakDB:SetFlatNoUpdate(se .. "Heal.prereqRecord", "Prereqs.AlwaysTruePrereq")
      if TweakDB:GetRecord(se .. "HealVal") == nil then
        TweakDB:CloneRecord(se .. "HealVal", "BaseStatusEffect.Health_Regen_inline5")
      end
      TweakDB:SetFlatNoUpdate(se .. "HealVal.valuePerSec", 1.67)
      TweakDB:SetFlat(se .. "Heal.poolModifier", se .. "HealVal")
      TweakDB:SetFlat(se .. "Pkg.effectors", { se .. "Heal" })
      TweakDB:SetFlat(se .. ".packages", { se .. "Pkg" })

      se = onHitAbility("TraitArmor", "TraitArmorSE", 10.0)
      ensureRecord(se .. "Pkg", "gamedataGameplayLogicPackage_Record")
      createStatModifier(se .. "ArmorMod", "Additive", "BaseStats.Armor", 5.0)
      TweakDB:SetFlat(se .. "Pkg.stats", { se .. "ArmorMod" })
      TweakDB:SetFlatNoUpdate(se .. "Pkg.stackable", true)
      ensureRecord(se .. "Stacks", "gamedataStatModifierGroup_Record")
      TweakDB:SetFlatNoUpdate(se .. "Stacks.statModsLimit", -1)
      createStatModifier(se .. "StacksMod", "Additive", "BaseStats.MaxStacks", 10.0)
      TweakDB:SetFlat(se .. "Stacks.statModifiers", { se .. "StacksMod" })
      TweakDB:SetFlatNoUpdate(se .. ".maxStacks", se .. "Stacks")
      TweakDB:SetFlat(se .. ".packages", { se .. "Pkg" })

      local ab = G.TDB .. "TraitDisorient"
      ensureRecord(ab, "gamedataGameplayAbility_Record")
      ensureRecord(ab .. "Pkg", "gamedataGameplayLogicPackage_Record")
      local chance = TweakDB:GetFlat("BaseStatusEffect.Blind_inline1.applicationChance")
        or TweakDB:GetFlat("BaseStatusEffect.Stun_inline1.applicationChance")
      local fx = {}
      for i, eff in ipairs({ "BaseStatusEffect.Blind", "BaseStatusEffect.Stun" }) do
        local e = ab .. "Fx" .. i
        ensureRecord(e, "gamedataAddStatusEffectToAttackEffector_Record")
        TweakDB:SetFlatNoUpdate(e .. ".isRandom", true)
        TweakDB:SetFlatNoUpdate(e .. ".stacks", 1)
        TweakDB:SetFlatNoUpdate(e .. ".effectorClassName", "AddStatusEffectToAttackEffector")
        TweakDB:SetFlatNoUpdate(e .. ".prereqRecord", "Perks.IsAttackRanged")
        TweakDB:SetFlat(e .. ".statusEffect", eff)
        if chance ~= nil then
          TweakDB:SetFlat(e .. ".applicationChance", chance)
        else
          TweakDB:SetFlat(e .. ".applicationChance", {}, "array:TweakDBID")
        end
        fx[#fx + 1] = e
      end
      TweakDB:SetFlat(ab .. "Pkg.effectors", fx)
      TweakDB:SetFlat(ab .. ".abilityPackage", ab .. "Pkg")
    end

    local function setupStimBlock()
      local cond = G.TDB .. "NotCompanionCond"
      ensureRecord(cond, "gamedataAIStatusEffectCond_Record")
      TweakDB:SetFlatNoUpdate(cond .. ".statusEffect", G.TDB .. "CompanionSE")
      TweakDB:SetFlatNoUpdate(cond .. ".target", "AIActionTarget.Owner")
      TweakDB:SetFlat(cond .. ".invert", true)
      appendToFlat("SpecialActions.CoverUseCombatStimConsumable_inline11.AND", cond)
      appendToFlat("SpecialActions.UseCombatStimConsumable_inline5.AND", cond)
    end

    setupChassisTraits()
    setupStimBlock()

    setupWeapons()
    setupLoadouts()
    G.netrunner.setup()
    G.hacks.setup()

    local flyIdx = 0
    local hooked = 0
    for _, model in ipairs(G.MODELS) do
      local mods = {}
      if model.dmg and model.dmg ~= 1.0 then
        createStatModifier(statModId(model, "dmg"), "Multiplier",
          "BaseStats.NPCDamage", model.dmg)
        table.insert(mods, statModId(model, "dmg"))
      end

      if model.hp and model.hp ~= 1.0 then
        createStatModifier(statModId(model, "hp"), "Multiplier",
          "BaseStats.Health", model.hp)
        table.insert(mods, statModId(model, "hp"))
      end
      for i = 1, G.INSTANCES do
        local id = G.recordId(model, i)
        buildSubCharacter(id, model.base, model.tag)
        if model.template then
          local ok, err = pcall(function()
            TweakDB:SetFlat(id .. ".entityTemplatePath", model.template)
          end)
          if i == 1 and not ok then
            G.log(string.format("template %s -> %s failed: %s", model.key, model.template, tostring(err)))
          end
        end
        local trait = ({ Octant = "TraitRepair", Griffin = "TraitArmor",
          Wyvern = "TraitDisorient" })[model.chassis]
        if trait then
          appendToFlat(id .. ".abilities", G.TDB .. trait)
        end
        if model.statsFrom then
          borrowStats(id, model.statsFrom)
        end
        if model.reaction then
          TweakDB:SetFlat(id .. ".reactionPreset", model.reaction)
        end
        if model.appearance then
          TweakDB:SetFlat(id .. ".appearanceName", CName.new(model.appearance))
        end

        if model.weapon then
          TweakDB:SetFlat(id .. ".primaryEquipment", G.TDB .. WEAPON_EQUIP[model.weapon])
        end
        local boom = G.settings.explosive and EXPLOSIVE_EQUIP[model.chassis]
        if boom and TweakDB:GetRecord(G.TDB .. boom) ~= nil then
          TweakDB:SetFlat(id .. ".primaryEquipment", G.TDB .. boom)
        end
        local loadout = model.chassis == "Android" and G.settings.loadout
        if loadout and loadout ~= "default" then
          local group = G.TDB .. "Loadout" .. loadout
          if TweakDB:GetRecord(group) ~= nil then
            TweakDB:SetFlat(id .. ".primaryEquipment", group)
          end
        end
        TweakDB:SetFlat(id .. ".statModifiers", mods)

        for _, action in ipairs(G.hacks.actionsFor(model)) do
          if appendToFlat(id .. ".objectActions", action, true) then hooked = hooked + 1 end
        end

        if model.fly then
          for _, side in ipairs({ "sizeFront", "sizeBack", "sizeLeft", "sizeRight" }) do
            local sz = TweakDB:GetFlat(id .. "." .. side)
            if sz ~= nil then
              TweakDB:SetFlat(id .. "." .. side, sz + 1.2, "Float")
            end
          end
          local zBase = TweakDB:GetFlat(id .. ".combatDefaultZOffset")
          if zBase ~= nil then
            TweakDB:SetFlat(id .. ".combatDefaultZOffset", zBase + (flyIdx % 3) * 1.8, "Float")
          end
          flyIdx = flyIdx + 1
        end
      end
    end

    tweakFollowerBehavior()
    setupCombatStateEffects()
    tweakFollowerCommonBehavior()
    setupVehicle()
    G.log(string.format("records ready (%d hack actions attached to %d subcharacters)",
      hooked, #G.MODELS * G.INSTANCES))
  end

  setupCombatStateEffects = function()
    ensureRecord(G.TDB .. "InCombatSE", "gamedataStatusEffect_Record")
    TweakDB:SetFlatNoUpdate(G.TDB .. "InCombatSE.duration", "BaseStats.InfiniteDuration")
    TweakDB:SetFlatNoUpdate(G.TDB .. "InCombatSE.statusEffectType", "BaseStatusEffectTypes.Misc")
    TweakDB:Update(G.TDB .. "InCombatSE")

    ensureRecord(G.TDB .. "InCombat", "gamedataStatusEffectPrereq_Record")
    TweakDB:SetFlatNoUpdate(G.TDB .. "InCombat.statusEffect", G.TDB .. "InCombatSE")
    TweakDB:SetFlatNoUpdate(G.TDB .. "InCombat.prereqClassName", "StatusEffectPrereq")
    TweakDB:Update(G.TDB .. "InCombat")

    ensureRecord(G.TDB .. "NotInCombat", "gamedataStatusEffectPrereq_Record")
    TweakDB:SetFlatNoUpdate(G.TDB .. "NotInCombat.statusEffect", G.TDB .. "InCombatSE")
    TweakDB:SetFlatNoUpdate(G.TDB .. "NotInCombat.prereqClassName", "StatusEffectAbsentPrereq")
    TweakDB:Update(G.TDB .. "NotInCombat")
  end

  setupVehicle = function()
    if TweakDB:GetRecord("Condition.EnterVehicleAICondition") == nil then
      G.log("vehicle: EnterVehicleAICondition missing, mount gate skipped")
      return
    end
    if TweakDB:GetRecord(G.TDB .. "VehAndroidOnly") == nil then
      TweakDB:CloneRecord(G.TDB .. "VehAndroidOnly", "Condition.Human")
      TweakDB:SetFlat(G.TDB .. "VehAndroidOnly.allowedNPCTypes",
        { "NPCType.Android", "NPCType.Human" })
    end
    appendToFlat("Condition.EnterVehicleAICondition.AND", G.TDB .. "VehAndroidOnly")
    if TweakDB:GetFlat("Condition.FollowerDrivingVehicle.freeSlots") ~= nil then
      TweakDB:SetFlat("Condition.FollowerDrivingVehicle.freeSlots", {})
    end
  end

  tweakFollowerCommonBehavior = function()

    if TweakDB:GetRecord(G.TDB .. "StealthOnlyHumans") == nil
      and TweakDB:GetFlat("FollowerActions.EnterStealth_inline0.condition") ~= nil then
      TweakDB:CloneRecord(G.TDB .. "StealthOnlyHumans", "Condition.EnterStealthCondition")
      appendToFlat(G.TDB .. "StealthOnlyHumans.AND", "Condition.Human")
      TweakDB:SetFlat("FollowerActions.EnterStealth_inline0.condition", G.TDB .. "StealthOnlyHumans")
    end

    local nodes = TweakDB:GetFlat("MovementActions.MovementPolicyCompositeDefault.nodes")
    if nodes ~= nil and TweakDB:GetFlat("FollowerActions.CombatMovementComposite.nodes") ~= nil then
      TweakDB:SetFlat("FollowerActions.CombatMovementComposite.nodes", nodes)
    end
  end

  return M
end
