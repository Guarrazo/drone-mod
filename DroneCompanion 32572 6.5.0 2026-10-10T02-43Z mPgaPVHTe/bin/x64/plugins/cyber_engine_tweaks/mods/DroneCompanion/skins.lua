return function(G)
  local M = {}

  function M.listFor(model)
    return G.skinsFor(model)
  end

  M.RANDOM = "random"

  function M.current(model)
    return model and G.settings.skins[model.key] or nil
  end

  function M.currentFor(rec)
    local own = G.settings.skins[rec]
    if own then return own end
    return M.current(G.modelOf(rec))
  end

  function M.resolve(rec)
    local app = M.currentFor(rec)
    if app ~= M.RANDOM then return app end
    local list = M.listFor(G.modelOf(rec))
    if not list or #list == 0 then return nil end
    local pick = list[math.random(#list)].app
    G.log(string.format("skin random %s: %s", rec, pick))
    return pick
  end

  function M.entryLabel(e)
    local label = G.STR[e.label]
    if e.n then label = label .. " " .. e.n end
    return label
  end

  local function labelOf(model, app, none)
    if not app then return none end
    if app == M.RANDOM then return G.STR.skin_random end
    for _, e in ipairs(M.listFor(model) or {}) do
      if e.app == app then return M.entryLabel(e) end
    end
    return app
  end

  function M.label(model)
    return labelOf(model, M.current(model), G.STR.skin_default)
  end

  function M.labelFor(rec, app)
    return labelOf(G.modelOf(rec), app, G.STR.skin_follow)
  end

  M.original = {}

  local function currentName(ent)
    local cur = nil
    pcall(function() cur = ent:GetCurrentAppearanceName() end)
    return cur
  end

  local function rememberOriginal(ent, rec)
    if M.original[rec] then return end
    local cur = currentName(ent)
    if cur ~= nil and tostring(cur) ~= "" then
      M.original[rec] = cur
    end
  end

  function M.forget(rec)
    M.original[rec] = nil
  end

  local function byRecord(rec)
    local model = G.modelOf(rec)
    return model ~= nil and model.paintByRecord == true
  end

  M.recordDefault = {}

  function M.prepareRecord(rec)
    if not byRecord(rec) then return false end
    local flat = rec .. ".appearanceName"
    if M.recordDefault[rec] == nil then
      local cur = TweakDB:GetFlat(flat)
      M.recordDefault[rec] = cur ~= nil and cur or CName.new("None")
    end
    local app = M.resolve(rec)
    local target = app and CName.new(app) or M.recordDefault[rec]
    local ok, err = pcall(function() TweakDB:SetFlat(flat, target) end)
    G.log(string.format("skin record %s: %s ok=%s %s", rec, tostring(app or "default"),
      tostring(ok), ok and "" or tostring(err)))
    return ok
  end

  function M.applyTo(ent, rec, app)
    if not IsDefined(ent) then return false end
    if byRecord(rec) then
      return G.companion.respawnInPlace(rec)
    end
    rememberOriginal(ent, rec)
    local target = app and CName.new(app) or M.original[rec]
    if target == nil then
      G.log("skin apply " .. rec .. ": no original appearance to revert to")
      return false
    end
    local ok, err = pcall(function() ent:ScheduleAppearanceChange(target) end)
    if not ok then G.log(string.format("skin apply %s: %s failed: %s", rec, tostring(app or "default"), tostring(err))) end
    return ok
  end

  function M.apply(ent, rec)
    if byRecord(rec) then return false end
    M.forget(rec)
    rememberOriginal(ent, rec)
    local app = M.resolve(rec)
    if not app then return false end
    return M.applyTo(ent, rec, app)
  end

  function M.set(model, app)
    if not model then return end
    G.settings.skins[model.key] = app
    G.saveSettings()
    G.log(string.format("skin set %s: %s", model.key, tostring(app or "default")))
    G.companion.eachActive(function(rec, ent)
      local m = G.modelOf(rec)
      if m and m.key == model.key and not G.settings.skins[rec] then
        M.applyTo(ent, rec, M.resolve(rec))
      end
    end)
  end

  function M.setFor(rec, app)
    G.settings.skins[rec] = app
    G.saveSettings()
    G.log(string.format("skin set unit %s: %s", rec, tostring(app or "follow")))
    G.companion.eachActive(function(r, ent)
      if r == rec then M.applyTo(ent, rec, M.resolve(rec)) end
    end)
  end

  local function cycleIn(list, cur, step, extra)
    local n = #list + 1 + (extra and 1 or 0)
    local at = 0
    if extra and cur == M.RANDOM then at = #list + 1 end
    for i, e in ipairs(list) do
      if e.app == cur then at = i end
    end
    at = (at + step) % n
    if at == 0 then return nil end
    if at > #list then return M.RANDOM end
    return list[at].app
  end

  function M.cycle(model, step)
    local list = M.listFor(model)
    if not list then return end
    M.set(model, cycleIn(list, M.current(model), step, true))
  end

  function M.nextFor(rec, app, step)
    local list = M.listFor(G.modelOf(rec))
    if not list then return app end
    return cycleIn(list, app, step, false)
  end

  return M
end
