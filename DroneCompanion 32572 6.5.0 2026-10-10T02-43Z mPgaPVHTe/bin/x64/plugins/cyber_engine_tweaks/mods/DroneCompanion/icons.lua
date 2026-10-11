return function(G)
  local ICONS = {
    tab_search = "Magnify", tab_pinned = "Pin", tab_active = "ToggleSwitch", tab_drones = "Quadcopter", tab_squad = "AccountGroup",
    tab_upgrades = "ArrowUpBold", tab_commands = "Console", tab_tuning = "Tune", tab_settings = "Cog",
    statuscard = "InformationOutline", st_points = "ArrowUpBold", st_drones = "Quadcopter", st_kills = "Skull",
    st_kd = "ChartLine", st_firmware = "Chip", st_title = "Medal",
    presets = "BookmarkMultiple", chauffeur = "Steering", behavior = "Robot", weapons = "Pistol",
    interface = "Palette", cmdhacks = "Cpu64Bit", power = "Fire", mobility = "RunFast", abilities = "Flash",
    hacks = "Cpu64Bit", arena = "SwordCross", tunesquad = "AccountGroup", uisettings = "Palette", tabs = "Tab",
    backup = "BackupRestore",
    stance = "ShieldSword", hold = "Anchor", camera = "Cctv", camera_exit = "VideoOff", light = "LightbulbOn",
    light_off = "LightbulbOff", sound = "VolumeHigh", muted = "VolumeOff", more = "DotsHorizontal",
    dismiss = "Close", repair = "Wrench", st_combat = "Sword", st_defensive = "Shield", st_passive = "Peace",
    st_arena = "SwordCross", col_combat = "Sword", col_support = "ShieldPlus", col_utility = "Tools",
    col_title = "Crown", firmware = "Chip",
    tab_fav = "Star", favoff = "StarOutline", tab_presets = "ContentSave", presetnew = "Plus", pausehdr = "Pause",
    indhdr = "MonitorEye", supporthdr = "Heart", padhkhdr = "Gamepad", actionshdr = "Wrench",
  }

  local function icon(key)
    local name = key and ICONS[key]
    if not name or type(IconGlyphs) ~= "table" then return "" end
    local glyph = IconGlyphs[name]
    return type(glyph) == "string" and glyph or ""
  end

  local function iconLabel(key, label)
    local glyph = icon(key)
    if glyph == "" then return label end
    return glyph .. " " .. label
  end

  G.ICONS = ICONS
  G.icon = icon
  G.iconLabel = iconLabel
end
