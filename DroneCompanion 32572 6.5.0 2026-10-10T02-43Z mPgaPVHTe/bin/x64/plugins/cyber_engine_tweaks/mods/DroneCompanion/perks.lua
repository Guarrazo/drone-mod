return function(G)
  local M = { spent = {} }

  local LEVEL_PER_POINT = 4

  M.COLUMNS = { "combat", "support", "utility", "title" }
  M.TITLE = { hp = 0.20, dmg = 0.15, overload = 0.10, range = 5 }

  M.PERKS = {
    { col = "combat",  key = "armor",    values = { 0.15, 0.30, 0.50 } },
    { col = "combat",  key = "damage",   values = { 0.10, 0.20, 0.30 } },
    { col = "combat",  key = "overload", values = { 0.15, 0.30, 0.45 } },
    { col = "support", key = "repair",   values = { 3.0, 4.0, 5.0 } },
    { col = "support", key = "quickfix", values = { 2, 1, 0 } },
    { col = "support", key = "rescue",   values = { 3, 2, 1 } },
    { col = "utility", key = "range",    values = { 10, 20, 30 } },
    { col = "utility", key = "bond",     values = { 40, 70, 100 } },
    { col = "title",   key = "squadtitle", values = { 1, 2, 3 }, cost = { 2, 3, 4 } },
  }

  local BY_KEY = {}
  for _, p in ipairs(M.PERKS) do BY_KEY[p.key] = p end

  function M.rank(key) return M.spent[key] or 0 end

  function M.costOf(key, rank)
    local p = BY_KEY[key]
    if not p or not p.cost then return 1 end
    return p.cost[rank] or p.cost[#p.cost] or 1
  end

  function M.titleRank() return M.rank("squadtitle") end

  local TITLE_BONUS = { armor = "hp", damage = "dmg", overload = "overload", range = "range" }

  local COL_SHARD = { combat = "UpCombat", support = "UpSupport", utility = "UpUtility" }

  function M.shardRanks(col)
    local id = COL_SHARD[col]
    if not id then return 0 end
    return G.tuning.upCount(id)
  end

  function M.effRank(key)
    local p = BY_KEY[key]
    if not p then return 0 end
    return M.rank(key) + M.shardRanks(p.col)
  end

  function M.valueAt(p, r)
    if not p or r < 1 then return nil end
    local n = #p.values
    if r <= n then return p.values[r] end
    local step = n > 1 and (p.values[n] - p.values[n - 1]) or 0
    local v = p.values[n] + step * (r - n)
    if step < 0 and v < 0 then v = 0 end
    return v
  end

  function M.value(key)
    local p = BY_KEY[key]
    local r = M.effRank(key)
    if not p then return nil end
    local bonus = TITLE_BONUS[key] and M.TITLE[TITLE_BONUS[key]] * M.titleRank() or 0
    if r == 0 then
      if bonus > 0 then return bonus end
      return nil
    end
    return M.valueAt(p, r) + bonus
  end

  M.lastLevel = 0

  function M.playerLevel()
    local lvl = 0
    pcall(function()
      lvl = Game.GetStatsSystem():GetStatValue(
        Game.GetPlayer():GetEntityID(), "Level")
    end)
    if lvl and lvl > 0 then
      M.lastLevel = math.floor(lvl)
      return M.lastLevel
    end
    pcall(function()
      lvl = PlayerDevelopmentSystem.GetData(Game.GetPlayer()):GetLevel()
    end)
    lvl = math.floor(lvl or 0)
    if lvl > 0 then
      M.lastLevel = lvl
      return lvl
    end
    return M.lastLevel
  end

  function M.total(level)
    return math.floor((level or M.playerLevel()) / LEVEL_PER_POINT)
  end

  function M.used()
    local n = 0
    for key, r in pairs(M.spent) do
      for i = 1, r do n = n + M.costOf(key, i) end
    end
    return n
  end

  function M.available(level)
    return M.total(level) - M.used()
  end

  function M.buy(key, level)
    local p = BY_KEY[key]
    if not p then return false, "unknown" end
    if M.rank(key) >= #p.values then return false, "max" end
    if M.available(level) < M.costOf(key, M.rank(key) + 1) then return false, "nopoints" end
    M.spent[key] = M.rank(key) + 1
    M.applyPlayer()
    return true
  end

  function M.refund(key)
    if not BY_KEY[key] then return false, "unknown" end
    local rank = M.rank(key)
    if rank < 1 then return false, "empty" end
    M.spent[key] = rank > 1 and rank - 1 or nil
    M.applyPlayer()
    return true
  end

  function M.respec()
    M.spent = {}
    M.applyPlayer()
  end

  function M.applyPlayer()
    if G.hacks then G.hacks.applyCooldowns() end
    if G.menu and G.menu.push then pcall(G.menu.push) end
  end

  function M.hpMult(model)
    local catalog = (model and model.hp) or 1.0
    return (G.tuning.hpFor(model) / catalog) * (1.0 + (M.value("armor") or 0.0))
  end

  function M.dmgMult(model)
    local catalog = (model and model.dmg) or 1.0
    return G.tuning.dmgFor(model) / catalog
  end

  function M.applyToDrone(ent, model, rec)
    if Game == nil or not ent or not IsDefined(ent) or not model then return end
    local ss = Game.GetStatsSystem()
    local id = ent:GetEntityID()
    local rank = (rec and G.squad and G.squad.rankBonus(rec)) or 0
    if rank > 0 then
      G.log(string.format("rank bonus %s: +%d%% (%d kills)", rec, math.floor(rank * 100 + 0.5),
        G.squad.killsOf(rec)))
    end

    local hp = M.hpMult(model) * (1 + rank)
    if math.abs(hp - 1.0) > 0.001 then
      local ok, err = pcall(function()
        ss:AddModifier(id, RPGManager.CreateStatModifier(gamedataStatType.Health,
          gameStatModifierType.Multiplier, hp))
      end)
      if not ok then G.log("health modifier FAILED: " .. tostring(err)) end
    end

    local dmg = M.dmgMult(model) * (1 + rank)
    if math.abs(dmg - 1.0) > 0.001 then
      local ok, err = pcall(function()
        ss:AddModifier(id, RPGManager.CreateStatModifier(gamedataStatType.NPCDamage,
          gameStatModifierType.Multiplier, dmg))
      end)
      if not ok then G.log("damage modifier FAILED: " .. tostring(err)) end
    end
  end

  function M.tempBuff(ent, statName, amount, seconds, additive)
    if Game == nil or not ent or not IsDefined(ent) or amount == 0 then return false end
    local statType = gamedataStatType[statName]
    if statType == nil then return false end
    local ss = Game.GetStatsSystem()
    local id = ent:GetEntityID()
    local modType = additive and gameStatModifierType.Additive or gameStatModifierType.Multiplier
    local ok = pcall(function()
      ss:AddModifier(id, RPGManager.CreateStatModifier(statType, modType, amount))
    end)
    if not ok then return false end
    G.Cron.After(seconds, function()
      if not IsDefined(ent) then return end
      pcall(function()
        ss:AddModifier(id, RPGManager.CreateStatModifier(statType, modType,
          additive and -amount or 1.0 / amount))
      end)
    end)
    return true
  end

  function M.save()
    local t = {}
    for k, v in pairs(M.spent) do t[k] = v end
    return t
  end

  function M.load(t)
    M.spent = {}
    if type(t) == "table" then
      for k, v in pairs(t) do
        if BY_KEY[k] and type(v) == "number" then
          M.spent[k] = math.max(0, math.min(math.floor(v), #BY_KEY[k].values))
        end
      end
    end
    M.applyPlayer()
  end

  function M.demo()
    M.spent = {}
    assert(M.total(0) == 0, "nivel 0 = 0 pontos")
    assert(M.total(60) == 15, "nivel 60 = 15 pontos")
    assert(M.available(60) == 15, "nada gasto")

    assert(M.buy("armor", 60))
    assert(M.rank("armor") == 1 and M.value("armor") == 0.15)
    assert(M.available(60) == 14, "gastou 1")

    assert(M.buy("armor", 60) and M.buy("armor", 60))
    assert(M.rank("armor") == 3)
    local ok, why = M.buy("armor", 60)
    assert(not ok and why == "max", "nao passa do rank maximo")

    local ok2, why2 = M.buy("armor", 0)
    assert(not ok2 and why2 == "max", "rank cheio antes de checar ponto")
    local ok3, why3 = M.buy("damage", 0)
    assert(not ok3 and why3 == "nopoints", "sem ponto nao compra")

    M.load({ bond = 9, lixo = 2, range = 1 })
    assert(M.rank("bond") == 3, "rank salvo alem do maximo e cortado")
    assert(M.rank("lixo") == 0, "chave desconhecida ignorada")
    assert(M.rank("range") == 1)

    M.spent = { armor = 2 }
    assert(M.refund("armor") and M.rank("armor") == 1, "refund devolve um rank")
    assert(M.refund("armor") and M.rank("armor") == 0, "refund ate zerar")
    local okr, whyr = M.refund("armor")
    assert(not okr and whyr == "empty", "sem rank nao devolve")
    assert(M.used() == 0, "rank zerado sai da conta de pontos")

    M.spent = { bond = 3, range = 1 }
    M.respec()
    assert(M.used() == 0 and M.rank("range") == 0, "respec zera")

    M.spent = {}
    assert(M.costOf("squadtitle", 1) == 2 and M.costOf("squadtitle", 3) == 4, "titulo custa 2, 3 e 4")
    local okt, whyt = M.buy("squadtitle", 4)
    assert(not okt and whyt == "nopoints", "1 ponto nao paga o titulo")
    assert(M.buy("squadtitle", 8) and M.used() == 2, "rank 1 do titulo gasta 2")
    assert(M.buy("squadtitle", 20) and M.used() == 5, "rank 2 gasta 3")
    assert(math.abs(M.value("armor") - 0.40) < 0.001, "titulo soma HP sem perk de armadura")
    assert(math.abs(M.value("overload") - 0.20) < 0.001 and M.value("range") == 10, "titulo soma habilidades")
    assert(M.refund("squadtitle") and M.used() == 2, "refund devolve o custo do rank")
    M.spent = {}
    assert(M.value("armor") == nil, "sem titulo nem perk = nil")

    if G.tuning then
      local model = { chassis = "Minotaur", hp = 2.0, dmg = 2.0 }
      G.tuning.reset()
      M.spent = {}
      assert(M.hpMult(model) == 1.0, "sem ajuste nem perk = neutro (record ja tem o catalogo)")
      assert(M.dmgMult(model) == 1.0, "dano idem")

      M.spent = { armor = 3 }
      assert(math.abs(M.hpMult(model) - 1.5) < 0.001, "so o perk entra na entidade")

      G.tuning.set("hp", 2.0)
      assert(math.abs(M.hpMult(model) - 3.0) < 0.001, "global multiplica sem duplicar o catalogo")

      G.tuning.reset()
      M.spent = {}
    end
    return true
  end

  return M
end
