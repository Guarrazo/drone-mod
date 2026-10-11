return function(G, N)
  local INK = require("inkicons")
  local IM = { open = false, acc = 0, last = "", lastWin = "", query = "", winQuery = "", tabCounts = {}, options = {},
    countsDirty = true, winOpen = false }
  local settings = G.settings

  local FOLD = {
    ["á"] = "a", ["à"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a",
    ["Á"] = "a", ["À"] = "a", ["Â"] = "a", ["Ã"] = "a", ["Ä"] = "a",
    ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e", ["É"] = "e", ["È"] = "e", ["Ê"] = "e", ["Ë"] = "e",
    ["í"] = "i", ["ì"] = "i", ["î"] = "i", ["ï"] = "i", ["Í"] = "i", ["Î"] = "i", ["Ï"] = "i",
    ["ó"] = "o", ["ò"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o", ["Ó"] = "o", ["Ô"] = "o", ["Õ"] = "o", ["Ö"] = "o",
    ["ú"] = "u", ["ù"] = "u", ["û"] = "u", ["ü"] = "u", ["Ú"] = "u", ["Û"] = "u", ["Ü"] = "u",
    ["ç"] = "c", ["Ç"] = "c", ["ñ"] = "n", ["Ñ"] = "n", ["ß"] = "ss", ["ÿ"] = "y",
    ["ą"] = "a", ["Ą"] = "a", ["ć"] = "c", ["Ć"] = "c", ["ę"] = "e", ["Ę"] = "e", ["ł"] = "l", ["Ł"] = "l",
    ["ń"] = "n", ["Ń"] = "n", ["ś"] = "s", ["Ś"] = "s", ["ź"] = "z", ["Ź"] = "z", ["ż"] = "z", ["Ż"] = "z",
    ["œ"] = "oe", ["Œ"] = "oe",
  }

  local function cyrLower(c)
    local b = c:byte()
    return b < 160 and ("\208" .. string.char(b + 32)) or ("\209" .. string.char(b - 32))
  end

  function IM.fold(s)
    s = tostring(s or ""):lower():gsub("[\195-\197][\128-\191]", FOLD)
    s = s:gsub("\208([\144-\175])", cyrLower)
    return (s:gsub("\208\129", "\208\181"):gsub("\209\145", "\208\181"))
  end

  local function utf8(cp)
    return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
  end

  function IM.glyph(key)
    local name = key and G.ICONS[key]
    local cp = name and INK[name]
    return cp and utf8(cp) or ""
  end

  local function clean(s)
    s = tostring(s or "")
    s = s:gsub("[\240-\244][\128-\191][\128-\191][\128-\191] ?", ""):gsub("[\t\n\r]", " ")
    return s == "" and "~" or s
  end

  local function line(...)
    local n = select("#", ...)
    local parts = { ... }
    for i = 2, n do parts[i] = clean(parts[i]) end
    return table.concat(parts, "\t", 1, n)
  end

  local function rgb(c)
    return string.format("%.3f,%.3f,%.3f", c[1], c[2], c[3])
  end

  local BASE_INK = { row = { 0.02, 0.02, 0.03, 0.72 }, tabs = { 0, 0, 0, 0.82 }, bar = { 0, 0, 0, 0.9 } }
  local INKS = {
    vanilla = { row = { 0.047, 0.031, 0.039, 0.93 }, tabs = { 0.031, 0.02, 0.027, 0.95 },
      bar = { 0.031, 0.02, 0.027, 0.97 }, sel = { 1.00, 0.38, 0.35, 0.24 } },
    default = { row = { 0, 0, 0, 0.6 }, tabs = { 0, 0, 0, 0.72 }, bar = { 0, 0, 0, 0.88 },
      sel = { 0.945, 0.945, 0.945, 1 }, selInk = { 0, 0, 0 } },
    slate = { row = { 0.165, 0.22, 0.32, 0.96 }, tabs = { 0.133, 0.18, 0.267, 0.98 }, bar = { 0.039, 0.043, 0.059, 1 },
      sel = { 0.918, 0.918, 0.925, 1 }, selInk = { 0.039, 0.043, 0.059 } },
  }

  local function alphas(ink)
    local ra, ta, ba = ink.row[4], ink.tabs[4], ink.bar[4]
    local bg = settings.menubg or 0
    if bg > 0 then
      ra = (bg - 1) * 0.2
      ta, ba = math.min(1, ra + 0.1), math.min(1, ra + 0.25)
    end
    return ra, ta, ba
  end

  local function paletteLine(th)
    local ink = INKS[th.key] or BASE_INK
    local row, tabs, bar = ink.row, ink.tabs, ink.bar
    local ra, ta, ba = alphas(ink)
    local sel = ink.sel or { th.accent[1], th.accent[2], th.accent[3], 0.24 }
    return line("C", rgb(th.accent), rgb(th.bright), rgb(sel), tostring(sel[4]), ink.selInk and rgb(ink.selInk) or "",
      rgb(row), tostring(ra), rgb(tabs), tostring(ta), rgb(bar), tostring(ba))
  end

  function IM.toast(text, seconds)
    if not IM.hudReady then return false end
    local p
    pcall(function() p = Game.GetPlayer() end)
    if not p then return false end
    local ok, shown = pcall(function()
      return p:DCMToast(tostring(text), settings.screenscale or 1, seconds or 1.8)
    end)
    return ok and shown == true
  end

  local function placeLine(win)
    local pos = win and settings.squadpos or settings.menupos
    local size = not win and settings.menusize or nil
    return line("P", pos and tostring(pos.x) or "", pos and tostring(pos.y) or "", tostring(settings.screenscale or 1),
      settings.descbox == false and "0" or "1", settings.keyhints == false and "0" or "1",
      size and tostring(size.w) or "", size and tostring(size.h) or "")
  end

  local UI_KEYS = { "hintselect", "hintvalue", "hintcollapse", "hinthelp", "hintback", "hintclose", "typefilter",
    "helpmove", "helpenter", "helpchange", "helpjump", "helpsub", "helpreset",
    "helptab", "helpfilter", "helpcollapse", "helpesc", "helpthis", "helpopen", "helpfine",
    "hintfav", "hinttype", "hintrename", "helpfav", "helptype", "helprename", "hintgoto", "helpgoto", "helpdigits", "newtag" }

  local function uiLine()
    local parts = {}
    for i, key in ipairs(UI_KEYS) do parts[i] = G.STR[key] end
    return line("H", unpack(parts))
  end

  local SELECT = { key = true, toggle = true, choice = true, btn = true }
  local LIST_TABS = { tab_active = true, tab_fav = true }
  local NO_COUNT = { tab_settings = true, tab_fav = true, tab_presets = true }
  local BUTTON_WORDS = { "presetapply" }
  local FAV = G.favorites
  local SEP = "  \194\187  "
  local PLAIN = { head = true, dim = true, warn = true }
  local NEW_OPTS = { ["tab_presets|presetauto"] = true, ["tab_presets|prepaste"] = true }

  local function newKey(tabKey, id)
    local tk, rid = tostring(id or ""):match("^opt|([^|]+)|%d+|(.*)$")
    return (tk or tabKey) .. "|" .. (rid or tostring(id or ""))
  end

  local function counts(row)
    if row.changed ~= nil then return row.changed end
    return row.kind == "toggle" and row.value == "1"
  end

  local function indexed(row)
    return SELECT[row.kind] and row.kind ~= "key" and row.id ~= "" and not row.id:find("^nm|")
      and not row.id:find("^pn|") and not row.id:find("^ph|")
  end

  local function scanTab(tab, options)
    local labels = N.subLabels(tab)
    local st = N.state(tab.key)
    local keep = st.sub
    local n = (labels and #labels > 0) and #labels or 1
    local total = 0
    N.within(tab, function()
      for si = 1, n do
        if n > 1 then st.sub = si end
        local c, head = 0, nil
        local path = tab.title() .. (n > 1 and (SEP .. labels[si]) or "")
        local sub = n > 1 and labels[si] or nil
        for _, row in ipairs(N.build()) do
          if counts(row) then c = c + 1 end
          if row.kind == "head" then
            head = row.label
          elseif indexed(row) then
            options[#options + 1] = { tab = tab.key, sub = si, row = row, fold = IM.fold(row.label),
              path = path .. (head and (SEP .. head) or ""),
              where = (sub and head) and (sub .. SEP .. head) or sub or head }
          end
        end
        total = total + c
      end
    end)
    st.sub = keep
    return total
  end

  function IM.scan()
    local options = {}
    local tabs = N.visibleTabs()
    if N.detached then tabs[#tabs + 1] = N.find(N.detached) end
    for _, tab in ipairs(tabs) do
      if tab.key ~= "tab_search" and not LIST_TABS[tab.key] then
        IM.tabCounts[tab.key] = scanTab(tab, options)
      end
    end
    N.dirty = true
    IM.options, IM.countsDirty = options, false
    IM.tabCounts.tab_active = #IM.active()
  end

  function IM.active(query)
    local out = {}
    for _, o in ipairs(IM.options) do
      if o.tab ~= "tab_settings" and o.tab ~= "tab_presets" and counts(o.row)
        and (not query or query == "" or o.fold:find(query, 1, true)) then
        out[#out + 1] = o
      end
    end
    return out
  end

  local function matching(query)
    local out = {}
    if #query < 2 then return out end
    for _, o in ipairs(IM.options) do
      if o.fold:find(query, 1, true) then out[#out + 1] = o end
    end
    return out
  end

  local function optionRows(options)
    local out, last = {}, nil
    for _, o in ipairs(options) do
      if o.path ~= last then
        out[#out + 1] = { kind = "head", label = o.path, gkey = "result|" .. o.path,
          target = "opt|" .. o.tab .. "|" .. o.sub .. "|" .. o.row.id }
        last = o.path
      end
      out[#out + 1] = { kind = o.row.kind, id = "opt|" .. o.tab .. "|" .. o.sub .. "|" .. o.row.id, rename = o.row.rename,
        label = o.row.label, value = o.row.value, info = o.row.info, changed = o.row.changed, defText = o.row.defText,
        bind = G.hotkeys.bindable(o.tab, o.row) and G.hotkeys.bind(o.tab, o.sub, o.row.kind, o.row.id) or nil }
    end
    return out
  end

  function IM.inTab(tabKey, sub, fn)
    local target
    for _, tab in ipairs(N.tabs) do
      if tab.key == tabKey then target = tab end
    end
    if not target then return end
    local st = N.state(tabKey)
    local keep = st.sub
    local labels = N.subLabels(target)
    if labels and #labels > 1 then st.sub = sub end
    local ok, err = pcall(N.within, target, function()
      N.build()
      fn()
    end)
    st.sub = keep
    N.dirty = true
    if not ok then G.log("option action failed: " .. tostring(err)) end
  end

  function IM.activeOff()
    for _, o in ipairs(IM.active()) do
      IM.inTab(o.tab, o.sub, function()
        for _, row in ipairs(N.rows) do
          if row.kind == o.row.kind and row.id == o.row.id then
            if row.changed ~= nil then N.route("reset", row.id) elseif row.value == "1" then N.route("act", row.id) end
            return
          end
        end
      end)
    end
    IM.countsDirty = true
  end

  local function rawNumber(value)
    return tostring(value or ""):match("^[%+x]?(%-?%d+%.?%d*)")
  end

  local function rowFlags(tab, row)
    local flags, key = "", nil
    local optTab, optSub, optId = tostring(row.id or ""):match("^opt|([^|]+)|(%d+)|(.*)$")
    if optTab then
      if FAV.allowed(optTab) then key = FAV.key(optTab, optSub, row.kind, optId) end
    elseif FAV.allowed(tab.key) and not LIST_TABS[tab.key] and indexed(row) then
      key = FAV.key(tab.key, N.sub(tab.key), row.kind, row.id)
    end
    if key then flags = flags .. "s" .. (FAV.has(key) and "f" or "") end
    local plainId = optId or tostring(row.id)
    if row.kind == "choice" and rawNumber(row.value) and not plainId:find("^perk|") and plainId ~= "menubg" then
      flags = flags .. "t"
    end
    if row.rename then flags = flags .. "n" end
    if optTab then flags = flags .. "g" end
    local nk = newKey(tab.key, row.id)
    if NEW_OPTS[nk] and not (IM.seenSnap or settings.newseen)[nk] then flags = flags .. "w" end
    if row.kind == "btn" then
      for _, w in ipairs(BUTTON_WORDS) do
        if row.value == G.STR[w] then flags = flags .. "x" end
      end
    end
    return flags
  end

  local function groupKey(prefix, row)
    return (prefix .. tostring(row.gkey or row.label)):gsub('[";\\]', "")
  end

  local function countText(n)
    return (n or 0) > 0 and tostring(n) or ""
  end

  local WRAP = 46

  local function wrapText(text)
    local lines, cur = {}, ""
    for word in text:gmatch("%S+") do
      local try = cur == "" and word or (cur .. " " .. word)
      if #try > WRAP and cur ~= "" then
        lines[#lines + 1] = cur
        cur = word
      else
        cur = try
      end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    return lines
  end

  local function expand(row)
    if row.kind == "dim" or row.kind == "warn" then
      local text = row.label .. ((row.value or "") ~= "" and ("  " .. row.value) or "")
      local out = {}
      for _, l in ipairs(wrapText(text)) do out[#out + 1] = { kind = row.kind, label = l } end
      return out
    end
    return { row }
  end

  local function filtered(rows, query)
    if query == "" then return rows end
    local out, head = {}, nil
    for _, row in ipairs(rows) do
      if row.kind == "head" then
        head = row
      elseif not PLAIN[row.kind] and IM.fold(row.label):find(query, 1, true) then
        if head then out[#out + 1] = head; head = nil end
        out[#out + 1] = row
      end
    end
    return out
  end

  local function textOnly(row)
    return row.kind == "dim" and (row.value or "") == ""
  end

  local function attachNotes(rows)
    local out, notes, loose = {}, {}, {}
    local lastOpt, lastAny, pending, used = nil, nil, {}, false
    local function add(row, text)
      notes[row] = notes[row] or {}
      notes[row][#notes[row] + 1] = text
    end
    local function flush()
      if not used then
        for _, r in ipairs(pending) do loose[#loose + 1] = r.label end
      end
      lastOpt, pending, used = nil, {}, false
    end
    for _, row in ipairs(rows) do
      if row.kind == "head" then
        flush()
        out[#out + 1] = row
      elseif textOnly(row) then
        if lastOpt then add(lastOpt, row.label) else pending[#pending + 1] = row end
      else
        if SELECT[row.kind] then
          for _, r in ipairs(pending) do add(row, r.label) end
          used = used or #pending > 0
          lastOpt, lastAny = row, row
        end
        out[#out + 1] = row
      end
    end
    flush()
    for _, text in ipairs(loose) do
      if lastAny then add(lastAny, text) end
    end
    return out, notes, (not lastAny and #loose > 0) and table.concat(loose, "  ") or nil
  end

  function IM.payload(win)
    local rows, notes, loose = attachNotes(N.build())
    local tab = N.current()
    local query = win and IM.winQuery or IM.query
    local out = {}
    local search
    for _, row in ipairs(rows) do
      if row.kind == "search" then search = row; break end
    end
    if win then IM.searchWin = search else IM.searchMain = search end
    local subs = N.subLabels(tab)
    local sub = (subs and #subs > 0) and (N.sub(tab.key) - 1) or -1
    out[#out + 1] = line("T", win and 0 or (N.tabPos() - 1), sub, search and search.id or "",
      search and search.value or "", search and search.hint or "", tab.key == "tab_search" and "1" or "",
      not win and IM.focus or "")
    out[#out + 1] = paletteLine(G.ui.theme())
    out[#out + 1] = placeLine(win)
    out[#out + 1] = uiLine()
    out[#out + 1] = line("G", IM.glyph("tab_fav"), IM.glyph("favoff"))
    if N.photo then out[#out + 1] = line("I", N.photo.part, N.photo.title, unpack(N.photo.lines)) end
    for _, vt in ipairs(win and { tab } or N.visibleTabs()) do
      out[#out + 1] = line("B", vt.title(), IM.glyph(vt.key), NO_COUNT[vt.key] and "" or countText(IM.tabCounts[vt.key]))
    end
    for _, label in ipairs(subs or {}) do out[#out + 1] = line("S", label, "") end
    if loose then out[#out + 1] = line("F", loose) end
    local list = {}
    for _, src in ipairs(search and rows or filtered(rows, query)) do
      if src.kind ~= "search" then
        for _, row in ipairs(expand(src)) do list[#list + 1] = row end
      end
    end
    if search and tab.key == "tab_search" then
      for _, row in ipairs(optionRows(matching(IM.fold(search.value)))) do list[#list + 1] = row end
    elseif tab.key == "tab_active" then
      for _, row in ipairs(optionRows(IM.active(query))) do list[#list + 1] = row end
    elseif tab.key == "tab_fav" then
      for _, row in ipairs(optionRows(FAV.options(IM.options, query))) do list[#list + 1] = row end
    end
    if #list == 0 and not search and query ~= "" then
      list[1] = { kind = "dim", id = "", label = G.STR.noresults, value = "" }
    elseif #list == 0 and tab.key == "tab_active" then
      list[1] = { kind = "dim", id = "", label = G.STR.activenone, value = "" }
    end
    local openAll = (not search and query ~= "") or (search and tab.key == "tab_search" and (search.value or "") ~= "")
      or LIST_TABS[tab.key] == true
    local sizes, head = {}, nil
    for _, row in ipairs(list) do
      if row.kind == "head" then
        head = row
        sizes[row] = 0
      elseif head and SELECT[row.kind] then
        sizes[head] = sizes[head] + 1
      end
    end
    local prefix = tab.key .. "|" .. N.sub(tab.key) .. "|"
    local focusHead
    if IM.focus and not win then
      local cur
      for _, row in ipairs(list) do
        if row.kind == "head" then cur = row elseif row.id == IM.focus then focusHead = cur end
      end
    end
    local open = true
    for _, row in ipairs(list) do
      if row.kind == "head" then
        local key = groupKey(prefix, row)
        if row == focusHead then settings.opengroups[key] = true end
        open = openAll or settings.opengroups[key] == true
        out[#out + 1] = line("R", "head", "grp|" .. key, row.label, (open and "1" or "0") .. "|" .. (row.summary or sizes[row]),
          0, IM.glyph(row.icon), row.info or "", "0", "", row.target and "g" or "", "", row.target or "", row.pic or "", row.tint or "")
      elseif open then
        local desc = row.info or ""
        for _, text in ipairs(notes[row] or {}) do
          if not desc:find(text, 1, true) then desc = desc == "" and text or (desc .. "  " .. text) end
        end
        if row.changed and row.defText and row.defText ~= row.value then
          local defLine = string.format(G.STR.defaultval, N.thousands(row.defText))
          desc = desc == "" and defLine or (desc .. "  " .. defLine)
        end
        local key = row.key
        if not key and row.bind then
          key = settings.hotkeys[row.bind]
        elseif not key and G.hotkeys.bindable(tab.key, row) then
          key = settings.hotkeys[G.hotkeys.bind(tab.key, N.sub(tab.key), row.kind, row.id)]
        end
        local flags = rowFlags(tab, row)
        out[#out + 1] = line("R", row.kind, row.id, row.label, N.thousands(row.value), 0, "", desc,
          row.changed and "1" or "0", key or "", flags, row.brand or "", flags:find("t", 1, true) and rawNumber(row.value) or "",
          row.pic or "", row.tint or "")
      end
    end
    return table.concat(out, "\n")
  end

  local function player()
    local p
    pcall(function() p = Game.GetPlayer() end)
    return p
  end

  local function moved()
    IM.query = ""
    IM.winQuery = ""
    if N.onMove then N.onMove() end
  end

  local function setDetached(on)
    if on == (N.detached ~= nil) then return end
    if on then
      local cur = N.current()
      local pos = N.tabPos()
      N.detached = "tab_squad"
      if cur and cur.key == "tab_squad" then N.setTab(math.max(1, pos - 1)) end
    else
      N.detached = nil
      if IM.jump then
        for i, tab in ipairs(N.tabs) do
          if tab.key == "tab_squad" then N.active = i - 1 end
        end
      end
    end
    IM.jump = nil
    settings.menutab = N.current().key
    G.saveSettings()
    moved()
    IM.last, IM.lastWin, IM.countsDirty = "", "", true
  end

  local function wantWin()
    return IM.open and settings.squadwin == true and not IM.pad and not N.pregame and settings.enabled ~= false
  end

  local function syncWin(p)
    local want = wantWin()
    if want == IM.winOpen then return end
    local ok, res = pcall(function()
      if want then return p:DCMSquadShow() end
      return p:DCMSquadHide()
    end)
    IM.winOpen = want and ok and res == true
    setDetached(IM.winOpen)
  end

  function IM.detachSquad(on)
    settings.squadwin = on
    IM.jump = not on
    G.saveSettings()
  end

  function IM.push(force)
    if not IM.open then return end
    local p = player()
    if not p then return end
    syncWin(p)
    if IM.countsDirty then
      local ok, err = pcall(IM.scan)
      if not ok then
        IM.countsDirty = false
        G.log("menu counts failed: " .. tostring(err))
      end
    end
    local ok, payload = pcall(IM.payload)
    if not ok then
      G.log("menu payload failed: " .. tostring(payload))
    elseif force or payload ~= IM.last then
      IM.last = payload
      pcall(function() p:DCMMenuPush(payload) end)
      IM.focus = nil
    end
    if not IM.winOpen then return end
    local okWin, winPayload = pcall(function()
      local out
      N.within(N.find("tab_squad"), function() out = IM.payload(true) end)
      return out
    end)
    if not okWin then
      G.log("squad window payload failed: " .. tostring(winPayload))
      return
    end
    if not force and winPayload == IM.lastWin then return end
    IM.lastWin = winPayload
    local shown = -1
    pcall(function() shown = p:DCMSquadPush(winPayload) end)
    if shown == -1 then
      IM.winOpen = false
      setDetached(false)
    end
  end

    local function findRow(rows, id)
    for _, r in ipairs(rows or {}) do
      if r.id == id then return r end
    end
  end

  local function inRowTab(id, fn)
    local tabKey, sub, rid = tostring(id):match("^opt|([^|]+)|(%d+)|(.*)$")
    if tabKey then
      IM.inTab(tabKey, tonumber(sub), function() fn(rid, tabKey, tonumber(sub)) end)
    else
      local tab = N.current()
      if tab then fn(id, tab.key, N.sub(tab.key)) end
    end
    IM.countsDirty = true
  end

  function IM.toggleFav(id)
    inRowTab(id, function(rid, tabKey, sub)
      local row = findRow(N.build(), rid)
      if row and FAV.allowed(tabKey) and indexed(row) then
        FAV.toggle(FAV.key(tabKey, sub, row.kind, row.id), row.label)
      end
    end)
  end

  local function walkTo(id, target)
    local function now()
      local row = findRow(N.build(), id)
      return row and tonumber(rawNumber(row.value))
    end
    for _, m in ipairs({ 100, 10, 1 }) do
      N.mult = m > 1 and m or nil
      for _ = 1, 1000 do
        local before = now()
        if not before or math.abs(before - target) < 1e-6 then break end
        local dir = before < target and "inc" or "dec"
        N.route(dir, id)
        local after = now()
        if not after or math.abs(after - before) < 1e-6 then break end
        local wrong = (dir == "inc" and after < before) or (dir == "dec" and after > before)
        local past = (dir == "inc" and after > target) or (dir == "dec" and after < target)
        if wrong or (past and m > 1) then
          N.route(dir == "inc" and "dec" or "inc", id)
          if wrong then N.mult = nil; return end
          break
        end
        if past then break end
      end
    end
    N.mult = nil
  end

  function IM.setValue(id, text)
    local raw = tostring(text or ""):gsub("%s", "")
    if not raw:match("%d") then return end
    inRowTab(id, function(rid)
      local row = findRow(N.build(), rid)
      local decimal = row and (rawNumber(row.value) or ""):find("%.") ~= nil
      local head, rest = raw:match("^(%-?%d%d?%d?)([.,]%d%d%d.*)$")
      if not decimal and head and (rest:gsub("[.,]%d%d%d", "")) == "" then raw = raw:gsub("[.,]", "") end
      local target = tonumber((raw:gsub(",", "."):match("%-?%d+%.?%d*")))
      if not target then return end
      target = math.max(-2147483647, math.min(2147483647, target))
      if not N.trySet(rid, target) then walkTo(rid, target) end
    end)
  end

  function IM.goTo(target)
    local tabKey, sub, rid = tostring(target):match("^opt|([^|]+)|(%d+)|(.*)$")
    if not tabKey then return end
    local keep = N.active
    for i, tab in ipairs(N.tabs) do
      if tab.key == tabKey then N.active = i - 1 end
    end
    local tab = N.current()
    if not tab or tab.key ~= tabKey then
      N.active = keep
      return
    end
    N.setSub(tabKey, tonumber(sub) or 1)
    settings.menutab = tabKey
    settings.menusub[tabKey] = N.sub(tabKey)
    moved()
    IM.focus = rid
    G.saveSettings()
  end

  function IM.rename(id, text)
    inRowTab(id, function(rid) N.route("rename", rid, text) end)
  end

  local function indicatorText()
    if settings.statusind ~= true or settings.enabled == false then return "" end
    local lines = {}
    for _, o in ipairs(IM.active()) do
      local text = o.row.label
      if o.row.kind == "choice" and (o.row.value or "") ~= "" then
        text = text .. " " .. N.thousands((tostring(o.row.value):match("|(.*)$")) or o.row.value)
      end
      lines[#lines + 1] = text
    end
    return table.concat(lines, "\n")
  end

  function IM.tickIndicator()
    if settings.statusind == true and IM.indDirty and not IM.open then
      IM.indDirty = nil
      pcall(IM.scan)
    end
    local text = indicatorText()
    if text == IM.indLast and settings.indpos == IM.indPos then return end
    local p = player()
    if not p or not IM.hudReady then return end
    local ok = pcall(function() p:DCMIndicator(text, settings.indpos or 0, settings.screenscale or 1) end)
    if ok then IM.indLast, IM.indPos = text, settings.indpos end
  end

  function G.copyLink(url, message)
    IM.clip = url
    G.hotkeys.toast(message or G.STR.linkcopied, true)
  end

  function IM.paste(fn)
    IM.pasteFn = fn
  end

  function IM.draw()
    if IM.clip then
      local url = IM.clip
      IM.clip = nil
      pcall(function() ImGui.SetClipboardText(url) end)
    end
    if IM.pasteFn then
      local fn = IM.pasteFn
      IM.pasteFn = nil
      local ok, text = pcall(function() return ImGui.GetClipboardText() end)
      IM.pasted = { fn = fn, text = ok and text or "" }
    end
  end

  function IM.toggle()
    local p = player()
    if p then pcall(function() p:DCMMenuToggle() end) end
  end


  local function setCombo(id, combo)
    local problem = G.input.setCombo(id, combo)
    if problem then G.hotkeys.toast(G.STR[problem], true) end
    IM.sendCombo()
  end

  local function toggleGroup(verb, rest)
    local key = rest:match("^grp|(.*)$")
    if not key then return end
    local want = verb == "gopen" or (verb == "gtoggle" and settings.opengroups[key] ~= true)
    settings.opengroups[key] = want or nil
    G.saveSettings()
  end

  local function handleWin(rest)
    if not IM.open or not IM.winOpen then return end
    local verb, arg = rest:match("^([^\t]+)\t?(.*)$")
    local squad = N.find("tab_squad")
    if verb == "act" or verb == "inc" or verb == "dec" or verb == "reset" then
      N.within(squad, function() N.route(verb, arg) end)
      IM.countsDirty = true
    elseif verb == "filter" then
      if IM.searchWin then
        N.within(squad, function() N.route("text", IM.searchWin.id, arg) end)
      else
        IM.winQuery = IM.fold(arg)
      end
    elseif verb == "gtoggle" or verb == "gopen" or verb == "gclose" then
      toggleGroup(verb, arg)
    elseif verb == "pos" then
      local x, y = arg:match("^([%-%d%.]+)\t([%-%d%.]+)$")
      if x then
        settings.squadpos = { x = math.floor(tonumber(x) + 0.5), y = math.floor(tonumber(y) + 0.5) }
        G.saveSettings()
      end
    end
    IM.acc = 0
    IM.push(false)
  end

  function IM.handle(msg)
    local mod = msg:match("^([sc])inc\t") or msg:match("^([sc])dec\t")
    if mod then
      N.mult = mod == "c" and 100 or 10
      local ok, err = pcall(IM.handle, msg:sub(2))
      N.mult = nil
      if not ok then error(err, 0) end
      return
    end
    local verb, rest = msg:match("^([^\t]+)\t?(.*)$")
    if verb == "hold" then
      local dir, id, mods, num = rest:match("^(%a+)\t([^\t]+)\t(%a?)\t(%d)$")
      IM.hold = dir and { dir = dir, id = id, mod = mods, num = num == "1", t = 0, next = 0.35 } or nil
      return
    end
    if verb == "unhold" or verb == "close" or verb == "tab" or verb == "sub" or verb == "filter" then IM.hold = nil end
    if verb == "unhold" then return end
    if verb == "win" then return handleWin(rest) end
    if verb == "hk" then
      local key, down, mods = rest:match("^([^\t]+)\t(%d)\t?(.*)$")
      if key then G.hotkeys.fire(key, down == "1", mods) end
      return
    end
    if verb == "phk" then
      G.hotkeys.firePad(rest)
      return
    end
    if verb == "device" or verb == "open" then
      IM.pad = rest == "1"
      N.padMode = IM.pad
      IM.countsDirty = true
    end
    if verb == "device" then
      IM.push(false)
      return
    end
    if verb == "open" then
      N.pregame = false
      pcall(function() N.pregame = Game.GetSystemRequestsHandler():IsPreGame() == true end)
      if not IM.restored then
        IM.restored = true
        for i, tab in ipairs(N.tabs) do
          if tab.key == (settings.menutab or "tab_drones") then N.active = i - 1 end
          local sub = settings.menusub[tab.key]
          if sub then N.state(tab.key).sub = math.max(1, math.min(sub, #(N.subLabels(tab) or { 1 }))) end
        end
      end
      IM.open, IM.last = true, ""
      IM.seenSnap = {}
      for k, v in pairs(settings.newseen) do IM.seenSnap[k] = v end
      moved()
      IM.sendCombo()
      G.pause.menuOpened()
      IM.push(true)
      return
    end
    if verb == "close" then
      IM.open, IM.last, IM.lastWin = false, "", ""
      N.pregame = false
      IM.winOpen = false
      setDetached(false)
      G.pause.menuClosed()
      IM.indDirty = true
      return
    end
    if not IM.open then return end
    if verb == "tab" then
      N.setTab((tonumber(rest) or 0) + 1)
      moved()
      settings.menutab = N.current().key
      G.saveSettings()
    elseif verb == "sub" then
      local tab = N.current()
      if tab then
        N.setSub(tab.key, (tonumber(rest) or 0) + 1)
        settings.menusub[tab.key] = N.sub(tab.key)
        G.saveSettings()
      end
      moved()
    elseif verb == "pos" then
      local x, y = rest:match("^([%-%d%.]+)\t([%-%d%.]+)$")
      if x then
        settings.menupos = { x = math.floor(tonumber(x) + 0.5), y = math.floor(tonumber(y) + 0.5) }
        G.saveSettings()
      end
    elseif verb == "size" then
      local w, h = rest:match("^([%d%.]+)\t([%d%.]+)$")
      if w then
        w, h = math.floor(tonumber(w) + 0.5), math.floor(tonumber(h) + 0.5)
        settings.menusize = (w > 0 or h > 0) and { w = w, h = h } or nil
        G.saveSettings()
      end
    elseif verb == "fav" then
      IM.toggleFav(rest)
    elseif verb == "seen" then
      local tab = N.current()
      local nk = newKey(tab and tab.key or "", rest)
      if NEW_OPTS[nk] and not settings.newseen[nk] then
        settings.newseen[nk] = true
        G.saveMenuData()
      end
    elseif verb == "goto" then
      IM.goTo(rest)
    elseif verb == "set" or verb == "ren" then
      local id, text = rest:match("^([^\t]+)\t(.*)$")
      if id and verb == "set" then IM.setValue(id, text) elseif id then IM.rename(id, text) end
    elseif verb == "padcombo" then
      if rest ~= "" and #rest <= 48 then setCombo("padcombo", rest) end
    elseif verb == "padset" then
      local id, combo = rest:match("^pc|(%w+)\t(.*)$")
      if id then setCombo(id, combo) end
    elseif verb == "hkset" or verb == "hkclear" then
      local id, key = rest:match("^([^\t]+)\t?(.*)$")
      if id then G.hotkeys.set(id, verb == "hkset" and key ~= "" and key or nil) end
    elseif (verb == "act" or verb == "inc" or verb == "dec" or verb == "reset") and rest:find("^opt|") then
      local tabKey, sub, id = rest:match("^opt|([^|]+)|(%d+)|(.*)$")
      if tabKey then
        IM.inTab(tabKey, tonumber(sub), function() N.route(verb, id) end)
        IM.countsDirty = true
      end
    elseif verb == "act" or verb == "inc" or verb == "dec" or verb == "reset" then
      N.route(verb, rest)
      IM.countsDirty = true
    elseif verb == "gtoggle" or verb == "gopen" or verb == "gclose" then
      toggleGroup(verb, rest)
    elseif verb == "filter" then
      local row = IM.searchMain
      if row then N.route("text", row.id, rest) else IM.query = IM.fold(rest) end
    end
    IM.acc = 0
    IM.push(false)
  end

  function IM.tick(dt)
    if IM.pasted then
      local job = IM.pasted
      IM.pasted = nil
      pcall(job.fn, job.text)
      IM.countsDirty = true
      N.dirty = true
    end
    if IM.autoAt and IM.hudReady then
      IM.autoAt = IM.autoAt - dt
      if IM.autoAt <= 0 then
        IM.autoAt = nil
        local pre = true
        pcall(function() pre = Game.GetSystemRequestsHandler():IsPreGame() end)
        if not pre and settings.enabled ~= false and G.presets.find(settings.presetauto) then
          pcall(G.presets.apply, settings.presetauto)
        end
      end
    end
    IM.indAcc = (IM.indAcc or 0) + dt
    if IM.indAcc >= 0.5 then
      IM.indAcc = 0
      IM.tickIndicator()
    end
    if not IM.open then return end
    local h = IM.hold
    if h then
      h.t = h.t + dt
      local fired = 0
      while IM.hold == h and h.t >= h.next and fired < 4 do
        fired = fired + 1
        h.next = h.next + 0.07
        local mods = h.mod
        if h.num and mods ~= "c" then
          if h.t >= 2.4 then mods = "c" elseif h.t >= 1.3 and mods == "" then mods = "s" end
        end
        local ok, err = pcall(IM.handle, mods .. h.dir .. "\t" .. h.id)
        if not ok then IM.hold = nil; G.log("menu hold failed: " .. tostring(err)) end
      end
    end
    IM.acc = IM.acc + dt
    if IM.acc >= 0.5 or N.dirty then
      IM.acc = 0
      IM.push(false)
    end
  end

  function IM.sendCombo(p)
    p = p or player()
    local combo = settings.padopen == false and "off" or (settings.padcombo or "LB+X")
    if p then pcall(function() p:DCMMenuSetCombo(combo) end) end
    G.hotkeys.send(p)
  end

  function IM.install()
    ObserveAfter("PlayerPuppet", "OnGameAttached", function(self)
      IM.sendCombo(self)
      G.pushLang(self)
      IM.indLast, IM.indDirty = nil, true
      if (settings.presetauto or 0) ~= 0 then IM.autoAt = 3 end
    end)
    Observe("PlayerPuppet", "DCMMenuEmit", function(_, msg)
      local ok, err = pcall(IM.handle, tostring(msg or ""))
      if not ok then G.log("menu event failed: " .. tostring(err)) end
    end)
    ObserveAfter("QuestTrackerGameController", "OnInitialize", function()
      IM.hudReady = true
    end)
    Observe("QuestTrackerGameController", "OnUninitialize", function()
      IM.hudReady = false
    end)
    IM.sendCombo()
    G.pushLang()
    if player() then
      pcall(function() IM.hudReady = not Game.GetSystemRequestsHandler():IsPreGame() end)
    end
  end

  return IM
end
