return function(G)
  local M = { global = {} }

  M.KEYS = { "dmg", "hp", "catchup", "range", "cooldown", "instances", "leash",
    "nethack", "lowhp", "autodismiss", "recon", "medic" }

  M.DEFAULTS = {
    dmg = 1.0, hp = 1.0, catchup = 9.0, range = 0.0,
    cooldown = 1.0, instances = 3, leash = 30.0, nethack = 8.0, lowhp = 0.0,
    autodismiss = 20.0, recon = 40.0, medic = 0.0,
  }

  M.LIMITS = {
    dmg = { 0.1, 10.0 }, hp = { 0.1, 10.0 }, catchup = { 4.0, 30.0 },
    range = { 0.0, 60.0 }, cooldown = { 0.2, 3.0 },
    instances = { 1, 10 }, leash = { 10.0, 100.0 }, nethack = { 3.0, 40.0 },
    lowhp = { 0.0, 60.0 }, autodismiss = { 5.0, 120.0 },
    recon = { 10.0, 80.0 }, medic = { 0.0, 60.0 },
  }

  local function clamp(key, v)
    local lim = M.LIMITS[key]
    if not lim or type(v) ~= "number" then return M.DEFAULTS[key] end
    if key == "instances" then v = math.floor(v + 0.5) end
    return math.max(lim[1], math.min(lim[2], v))
  end
  M.clamp = clamp

  function M.get(key)
    local v = M.global[key]
    if v == nil then return M.DEFAULTS[key] end
    return v
  end

  function M.set(key, v)
    if M.DEFAULTS[key] == nil then return end
    M.global[key] = clamp(key, v)
    M.commit()
  end

  function M.catalog(chassisKey, field)
    for _, ch in ipairs(G.CHASSIS) do
      if ch.key == chassisKey then return ch[field] or 1.0 end
    end
    return 1.0
  end

  function M.reset()
    M.global = {}
    M.commit()
  end

  function M.upCount(id)
    local n = 0
    pcall(function()
      n = Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(),
        ItemID.FromTDBID(TweakDBID.new(G.TDB .. id)))
    end)
    return n
  end

  function M.dmgFor(model)
    return M.catalog(model.chassis, "dmg") * M.get("dmg")
      * (1.0 + (G.perks.value("damage") or 0.0))
  end

  function M.hpFor(model)
    return M.catalog(model.chassis, "hp") * M.get("hp")
  end

  function M.commit()
    M.dirty = true
    if G.records then G.records.applyCatchUp() end
    if G.hacks then G.hacks.applyCooldowns() end
  end

  function M.flush()
    if not M.dirty then return end
    M.dirty = false
    if G.saveSettings then G.saveSettings() end
  end

  function M.demo()
    G.CHASSIS = { { key = "Minotaur", dmg = 2.0, hp = 1.0 } }
    G.perks = { value = function() return nil end }
    G.saveSettings = function() end
    M.global = {}

    local model = { chassis = "Minotaur", dmg = 2.0 }
    assert(M.dmgFor(model) == 2.0, "sem ajuste = catalogo")

    M.set("dmg", 2.0)
    assert(M.dmgFor(model) == 4.0, "global multiplica")

    M.set("dmg", 999)
    assert(M.get("dmg") == 10.0, "clamp no teto")
    M.set("instances", 2.6)
    assert(M.get("instances") == 3, "instances arredonda")

    G.perks.value = function(k) return k == "damage" and 0.30 or nil end
    M.set("dmg", 1.0)
    assert(math.abs(M.dmgFor(model) - 2.6) < 0.001, "perk soma por cima")

    M.reset()
    assert(M.get("dmg") == 1.0 and M.get("leash") == 30.0, "reset volta ao padrao")

    local saved = 0
    G.saveSettings = function() saved = saved + 1 end
    M.set("dmg", 2.0)
    M.set("dmg", 3.0)
    assert(saved == 0, "commit nao grava direto")
    M.flush()
    M.flush()
    assert(saved == 1, "flush grava uma vez so")
    print("tuning demo ok")
  end

  return M
end
