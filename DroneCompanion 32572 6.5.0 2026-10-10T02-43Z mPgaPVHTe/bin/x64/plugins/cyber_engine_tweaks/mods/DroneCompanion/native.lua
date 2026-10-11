return function(G)
  local N = { active = 0, tabs = {}, rows = {}, dirty = true }
  local states = {}

  function N.tab(key, title, build, handlers, subs)
    N.tabs[#N.tabs + 1] = {
      key = key,
      title = title,
      build = build,
      act = handlers and handlers.act,
      inc = handlers and handlers.inc,
      dec = handlers and handlers.dec,
      reset = handlers and handlers.reset,
      text = handlers and handlers.text,
      rename = handlers and handlers.rename,
      set = handlers and handlers.set,
      subs = subs,
    }
  end

  function N.state(key)
    states[key] = states[key] or {}
    return states[key]
  end

  function N.subLabels(tab)
    if not tab or not tab.subs then return nil end
    return tab.subs()
  end

  function N.sub(key)
    return N.state(key).sub or 1
  end

  function N.setSub(key, index)
    local tab
    for _, tb in ipairs(N.tabs) do
      if tb.key == key then tab = tb end
    end
    local labels = N.subLabels(tab)
    if not labels or #labels == 0 then return end
    N.state(key).sub = ((index - 1) % #labels) + 1
    N.dirty = true
  end

  function N.row(kind, id, label, value, info)
    N.rows[#N.rows + 1] = { id = id or "", kind = kind, label = label or "", value = value or "", rank = 0,
      info = info }
    return N.rows[#N.rows]
  end

  function N.head(label, icon, gkey)
    local row = N.row("head", "", label, "")
    row.icon, row.gkey = icon, gkey
    return row
  end

  function N.by()
    return N.mult or 1
  end

  function N.search(id, label, value, hint)
    N.row("search", id, label, value).hint = hint
  end

  function N.key(id, label, key, info)
    N.row("key", id, label, key and G.hotkeys.label(key) or G.STR.hknone, info).key = key
  end

  local function off(tab)
    return (G.settings.enabled == false or N.pregame) and tab.key ~= "tab_settings"
  end

  local function hidden(tab)
    if tab.key == "tab_settings" then return false end
    return off(tab) or (N.padMode and tab.key == "tab_search") or tab.key == N.detached
      or (tab.key == "tab_fav" and not G.favorites.any()) or G.tabHidden(tab.key)
  end

  function N.thousands(text)
    text = tostring(text or "")
    local sep = G.STR.thousands
    if sep == "thousands" then sep = "," end
    return (text:gsub("()(%d+)()", function(a, digits, b)
      local before, after = text:sub(a - 1, a - 1), text:sub(b, b + 1)
      if #digits < 4 or before:find("[%.,:]") or after:find("^[%.,:]%d") or after:find("^%-") then return nil end
      local out = digits:reverse():gsub("(%d%d%d)", "%1" .. sep:reverse()):reverse()
      if out:sub(1, #sep) == sep then out = out:sub(#sep + 1) end
      return out
    end))
  end

  function N.find(key)
    for _, tab in ipairs(N.tabs) do
      if tab.key == key then return tab end
    end
  end

  function N.within(tab, fn)
    local keep = N.forced
    N.forced = tab
    local ok, err = pcall(fn)
    N.forced = keep
    if not ok then error(err, 0) end
  end

  function N.visibleTabs()
    local out = {}
    for _, tab in ipairs(N.tabs) do
      if not hidden(tab) then out[#out + 1] = tab end
    end
    return out
  end

  function N.current()
    if N.forced then return N.forced end
    local tab = N.tabs[N.active + 1]
    if tab and not hidden(tab) then return tab end
    return N.visibleTabs()[1]
  end

  function N.tabPos()
    local cur = N.current()
    for i, tab in ipairs(N.visibleTabs()) do
      if tab == cur then return i end
    end
    return 1
  end

  function N.build()
    N.rows = {}
    N.photo = nil
    local tab = N.current()
    if tab then
      local ok, err = pcall(tab.build)
      if not ok then
        N.rows = {}
        N.row("warn", "", "Tab failed", tostring(err))
        G.log("tab build failed: " .. tostring(err))
      end
    end
    N.dirty = false
    return N.rows
  end

  function N.route(verb, id, value)
    local tab = N.current()
    if not tab or off(tab) then return end
    local ok, err = pcall(function()
      if verb == "act" and tab.act then
        tab.act(id)
      elseif verb == "inc" and tab.inc then
        tab.inc(id)
      elseif verb == "dec" and tab.dec then
        tab.dec(id)
      elseif verb == "reset" and tab.reset then
        tab.reset(id)
      elseif verb == "text" and tab.text then
        tab.text(id, value)
      elseif verb == "rename" and tab.rename then
        tab.rename(id, value)
      end
    end)
    if not ok then G.log("menu action " .. verb .. ":" .. tostring(id) .. " failed: " .. tostring(err)) end
    N.dirty = true
  end

  function N.trySet(id, value)
    local tab = N.current()
    if not tab or off(tab) or not tab.set then return false end
    local ok, done = pcall(tab.set, id, value)
    N.dirty = true
    return ok and done == true
  end

  function N.setTab(index)
    local vis = N.visibleTabs()
    if #vis == 0 then return end
    local target = vis[((index - 1) % #vis) + 1]
    for i, tab in ipairs(N.tabs) do
      if tab == target then N.active = i - 1 end
    end
    N.dirty = true
  end

  return N
end
