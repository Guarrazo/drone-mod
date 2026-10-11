return function(G)
  local M = { list = {}, listAt = -100 }

  local TYPES = {
    Wea_Handgun = true, Wea_Revolver = true, Wea_SubmachineGun = true,
    Wea_AssaultRifle = true, Wea_Rifle = true, Wea_Shotgun = true, Wea_ShotgunDual = true,
    Wea_LightMachineGun = true, Wea_HeavyMachineGun = true,
    Wea_SniperRifle = true, Wea_PrecisionRifle = true,
    Wea_Katana = true, Wea_Machete = true, Wea_Sword = true, Wea_LongBlade = true,
    Wea_Hammer = true, Wea_OneHandedClub = true, Wea_TwoHandedClub = true,
    Wea_Chainsword = true, Wea_ShortBlade = true,
  }
  local names = {}

  function M.isItemKey(key)
    return type(key) == "string" and key:sub(1, 5) == "item:"
  end

  function M.itemPath(key)
    return M.isItemKey(key) and key:sub(6) or nil
  end

  function M.nameOf(path)
    if names[path] then return names[path] end
    local name
    pcall(function()
      local rec = TweakDB:GetRecord(path)
      if rec then name = Game.GetLocalizedTextByKey(rec:DisplayName()) end
    end)
    if not name or name == "" then name = path:match("Preset_(.+)$") or path end
    names[path] = name
    return name
  end

  function M.label(key)
    local path = M.itemPath(key)
    if path then return M.nameOf(path) end
    return G.STR["lo_" .. tostring(key or "default")] or tostring(key or "default")
  end

  function M.inventory(force)
    local now = os.clock()
    if not force and now - M.listAt < 2.0 then return M.list end
    M.listAt = now
    local out, seen = {}, {}
    local player = Game.GetPlayer()
    if not player then M.list = out return out end
    pcall(function()
      local _, items = Game.GetTransactionSystem():GetItemList(player)
      for _, it in ipairs(items or {}) do
        pcall(function()
          if not TYPES[it:GetItemType().value] then return end
          local path = G.records.pathOf(it:GetID().id)
          if not path or not path:find("^Items%.") or seen[path] then return end
          seen[path] = true
          out[#out + 1] = { path = path, name = M.nameOf(path) }
        end)
      end
    end)
    table.sort(out, function(a, b) return a.name < b.name end)
    M.list = out
    return out
  end

  function M.give(rec, path, key)
    local model = G.modelOf(rec)
    if not model or model.chassis ~= "Android" then return false end
    local ent
    G.companion.eachActive(function(r, e) if r == rec then ent = e end end)
    if not ent then return false end
    local saved = G.companion.captureOne(rec, true)
    saved.weapon = key or ("item:" .. path)
    local stance = G.companion.stanceOf(rec)
    G.companion.dismiss(rec, true)
    local gen = G.companion.spawnGen[rec]
    G.Cron.After(1.5, function()
      if G.companion.spawnGen[rec] ~= gen then return end
      G.companion.setStance(rec, stance)
      G.companion.respawn({ saved })
    end)
    G.notify(string.format(G.STR.weapon_given, G.squad.displayName(rec, model), M.nameOf(path)))
    return true
  end

  function M.options(includeDefault)
    local opts = {}
    if includeDefault then opts[1] = "default" end
    for _, lo in ipairs(G.records.LOADOUTS) do
      if lo.item and not lo.broken then opts[#opts + 1] = lo.key end
    end
    for _, w in ipairs(M.inventory()) do opts[#opts + 1] = "item:" .. w.path end
    return opts
  end

  function M.nextKey(cur, step)
    local opts = M.options()
    if #opts == 0 then return cur end
    local at = 0
    for i, key in ipairs(opts) do
      if key == cur then at = i end
    end
    at = at + step
    if at < 1 then at = #opts end
    if at > #opts then at = 1 end
    return opts[at]
  end

  function M.set(rec, key)
    local path = M.itemPath(key)
    if path then return M.give(rec, path) end
    local item = G.records.loadoutItem(key)
    if not item then return false end
    return M.give(rec, item, key)
  end

  return M
end
