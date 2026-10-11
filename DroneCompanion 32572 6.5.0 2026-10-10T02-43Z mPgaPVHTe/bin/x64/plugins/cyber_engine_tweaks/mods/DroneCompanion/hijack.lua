return function(G)
  local M = { list = {}, serial = 0 }

  local RANGE = 30.0
  local RAM_COST = 8
  local MAX_UNITS = 3
  local KEY = "Hijack"

  local CHASSIS_HINTS = {
    { find = "octant",   chassis = "Octant" },
    { find = "wyvern",   chassis = "Wyvern" },
    { find = "griffin",  chassis = "Griffin" },
    { find = "bombus",   chassis = "Bombus" },
    { find = "minotaur", chassis = "Minotaur" },
    { find = "chimera",  chassis = "Chimera" },
    { find = "android",  chassis = "Android" },
    { find = "mech",     chassis = "Minotaur" },
    { find = "drone",    chassis = "Octant" },
  }

  local function tdbid(s) return TweakDBID.new(s) end

  function M.is(rec)
    return type(rec) == "string" and rec:find(G.TDB .. KEY, 1, true) == 1
  end

  local function reject(reason)
    G.log("hijack refused: " .. reason)
    G.notify(string.format(G.STR.hijack_refused, reason))
    return false
  end

  local function recordName(target)
    local raw = ""
    pcall(function() raw = tostring(target:GetRecordID()) end)
    return raw:match("%[%[ (.-) %-%-%]%]") or raw:match("Character%.([%w_]+)") or raw
  end

  local function prettyName(record)
    local s = record:gsub("^Character%.", ""):gsub("^q%d+_", ""):gsub("_base_", "_")
      :gsub("_drone_", "_")
    local words = {}
    for w in s:gmatch("[^_]+") do
      if not w:match("^%d+$") then words[#words + 1] = w:sub(1, 1):upper() .. w:sub(2) end
    end
    return #words > 0 and table.concat(words, " ") or "Unit"
  end

  local function buildModel(target)
    local record = recordName(target)
    local lower = record:lower()
    local chassisKey = "Android"
    for _, hint in ipairs(CHASSIS_HINTS) do
      if lower:find(hint.find, 1, true) then chassisKey = hint.chassis break end
    end
    local ch = G.chassisOf(chassisKey) or {}
    return {
      name = prettyName(record),
      chassis = chassisKey,
      key = KEY,
      fly = ch.fly == true,
      dmg = ch.dmg or 1.0,
      hp = ch.hp or 1.0,
      static = false,
      hijack = true,
      record = record,
    }
  end

  local function candidate(player)
    local target
    pcall(function()
      target = Game.GetTargetingSystem():GetLookAtObject(player, true, false)
    end)
    if not IsDefined(target) then return nil, "no target" end
    if target:IsPlayer() or not target:IsNPC() then return nil, "not an NPC" end
    local ours = false
    pcall(function()
      ours = Game.GetStatusEffectSystem():HasStatusEffect(target:GetEntityID(),
        tdbid(G.TDB .. "CompanionSE"))
    end)
    if ours then return nil, "already yours" end
    if G.companion.isDown(target) then return nil, "target is down" end
    local mech = false
    pcall(function() mech = target:IsMechanical() == true end)
    if not mech then return nil, "not a machine" end
    local boss = false
    pcall(function() boss = target:IsBoss() == true end)
    if boss and not G.settings.hijackBosses then return nil, "boss" end
    local att = ""
    pcall(function()
      att = tostring(target:GetAttitudeAgent():GetAttitudeTowards(player:GetAttitudeAgent()))
    end)
    if not att:find("Hostile", 1, true) then return nil, "not hostile" end
    local dist = Vector4.Distance(player:GetWorldPosition(), target:GetWorldPosition())
    if dist > RANGE then return nil, string.format("too far (%.0f m)", dist) end
    return target, dist
  end

  local function payRam(player)
    local sps = Game.GetStatPoolsSystem()
    local id = player:GetEntityID()
    local before, after = -1, -1
    pcall(function() before = sps:GetStatPoolValue(id, gamedataStatPoolType.Memory, false) end)
    if before >= 0 and before < RAM_COST then return false, before end
    pcall(function()
      sps:RequestChangingStatPoolValue(id, gamedataStatPoolType.Memory, -RAM_COST, player, false, false)
    end)
    pcall(function() after = sps:GetStatPoolValue(id, gamedataStatPoolType.Memory, false) end)
    G.log(string.format("hijack ram: %.1f -> %.1f (cost %d)", before, after, RAM_COST))
    return true, before
  end

  local function count()
    local n = 0
    for _ in pairs(M.list) do n = n + 1 end
    return n
  end

  local function forgetSquadState(rec)
    if not G.squad then return end
    G.squad.names[rec] = nil
    G.squad.kills[rec] = nil
    G.squad.deaths[rec] = nil
  end

  local function adopt(target)
    M.serial = M.serial + 1
    local rec = G.TDB .. KEY .. M.serial
    local model = buildModel(target)
    M.list[rec] = { ent = target, model = model, at = os.clock() }
    forgetSquadState(rec)
    local ok, err = pcall(G.companion.adoptHijacked, target, rec)
    if not ok then
      M.list[rec] = nil
      G.log("hijack adopt FAILED: " .. tostring(err))
      return nil
    end
    local hacks = 0
    if G.hacks and G.hacks.attachToRecord then
      local okAttach, n = pcall(G.hacks.attachToRecord, model.record, model)
      hacks = okAttach and n or 0
      if not okAttach then G.log("hijack hacks attach FAILED: " .. tostring(n)) end
    end
    G.log(string.format("hijack ok: %s as %s (%s, chassis %s), %d hijacked, %d hacks attached",
      model.record, rec, model.name, model.chassis, count(), hacks))
    return rec
  end

  local function ramNow(player)
    local v = -1
    pcall(function()
      v = Game.GetStatPoolsSystem():GetStatPoolValue(player:GetEntityID(),
        gamedataStatPoolType.Memory, false)
    end)
    return v
  end

  function M.promptTick(player)
    if count() >= MAX_UNITS then return nil end
    local target = candidate(player)
    if not target then return nil end
    local name = prettyName(recordName(target))
    local ram = ramNow(player)
    if ram >= 0 and ram < RAM_COST then
      return name, string.format(G.STR.hijack_no_ram, RAM_COST)
    end
    return name, string.format(G.STR.hijack_prompt, RAM_COST)
  end

  function M.trigger()
    local player = Game.GetPlayer()
    if not player then return false end
    if count() >= MAX_UNITS then return reject("limit reached") end
    local target, why = candidate(player)
    if not target then return reject(why) end
    local paid, ram = payRam(player)
    if not paid then return reject(string.format("need %d RAM (have %.0f)", RAM_COST, ram)) end
    local rec = adopt(target)
    if rec then
      G.notify(string.format(G.STR.hijack_ok, M.list[rec].model.name))
      return true
    end
    return false
  end

  local function shutdown(entry)
    local ent = entry.ent
    if not IsDefined(ent) then return end
    pcall(function()
      StatusEffectHelper.RemoveStatusEffect(ent, tdbid(G.TDB .. "CompanionSE"))
    end)
    local ok = pcall(function()
      StatusEffectHelper.ApplyStatusEffect(ent, tdbid("BaseStatusEffect.SystemCollapse"))
    end)
    local dead = false
    G.Cron.After(1.5, function()
      if not IsDefined(ent) then return end
      pcall(function() dead = ent:IsDead() end)
      if not dead then pcall(function() ent:Kill(Game.GetPlayer(), false, false) end) end
      G.log(string.format("hijack release %s: collapse=%s killed=%s", entry.model.name,
        tostring(ok), tostring(not dead)))
    end)
  end

  local function drop(rec)
    local entry = M.list[rec]
    M.list[rec] = nil
    local shared = false
    for _, other in pairs(M.list) do
      if entry and other.model.record == entry.model.record then shared = true end
    end
    if entry and not shared and G.hacks and G.hacks.detachFromRecord then
      pcall(G.hacks.detachFromRecord, entry.model.record)
    end
    forgetSquadState(rec)
    if G.companion.forgetHijacked then G.companion.forgetHijacked(rec) end
    if G.hacks then
      G.hacks.held[rec] = nil
      G.hacks.anchor[rec] = nil
    end
  end

  function M.releaseOne(rec)
    local entry = M.list[rec]
    if not entry then return false end
    shutdown(entry)
    drop(rec)
    G.notify(string.format(G.STR.hijack_released, 1))
    G.log("hijack release one: " .. rec)
    return true
  end

  function M.releaseAll()
    local n = 0
    for rec, entry in pairs(M.list) do
      shutdown(entry)
      drop(rec)
      n = n + 1
    end
    if n > 0 then G.notify(string.format(G.STR.hijack_released, n)) end
    G.log("hijack release all: " .. n)
    return n
  end

  function M.lost(rec)
    local entry = M.list[rec]
    if not entry then return end
    local name = (G.squad and G.squad.displayName(rec, entry.model)) or entry.model.name
    drop(rec)
    G.log(string.format("hijack lost: %s", rec))
    G.notify(string.format(G.STR.hijack_lost, name))
  end

  function M.each(fn)
    for rec, entry in pairs(M.list) do
      if IsDefined(entry.ent) then
        fn(rec, entry.ent, entry.model)
      else
        G.log("hijack entity undefined: " .. rec)
        M.lost(rec)
      end
    end
  end

  function M.entityOf(rec)
    local entry = M.list[rec]
    return entry and entry.ent or nil
  end

  function M.modelOf(rec)
    local entry = M.list[rec]
    return entry and entry.model or nil
  end

  function M.count()
    return count()
  end

  return M
end
