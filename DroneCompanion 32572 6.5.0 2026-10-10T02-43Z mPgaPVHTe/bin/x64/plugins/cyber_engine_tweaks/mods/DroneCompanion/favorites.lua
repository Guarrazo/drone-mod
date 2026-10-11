return function(G)
  local settings = G.settings
  local F = {}
  local NO_STAR = { tab_settings = true, tab_presets = true, tab_search = true }

  function F.key(tabKey, sub, kind, id)
    return tabKey .. "|" .. sub .. "|" .. kind .. "|" .. G.stableId(id)
  end

  function F.has(key)
    for _, k in ipairs(settings.favrows) do
      if k == key then return true end
    end
    return false
  end

  function F.allowed(tabKey)
    return not NO_STAR[tabKey]
  end

  function F.toggle(key, label)
    local text
    for i, k in ipairs(settings.favrows) do
      if k == key then
        table.remove(settings.favrows, i)
        text = G.STR.favremoved
      end
    end
    if not text then
      settings.favrows[#settings.favrows + 1] = key
      text = G.STR.favadded
    end
    G.saveMenuData()
    G.hotkeys.toast((label and (label .. ": ") or "") .. text, true)
  end

  function F.options(options, query)
    local out = {}
    for _, o in ipairs(options) do
      if F.has(F.key(o.tab, o.sub, o.row.kind, o.row.id))
        and (not query or query == "" or o.fold:find(query, 1, true)) then
        out[#out + 1] = o
      end
    end
    return out
  end

  function F.any()
    return #settings.favrows > 0
  end

  return F
end
