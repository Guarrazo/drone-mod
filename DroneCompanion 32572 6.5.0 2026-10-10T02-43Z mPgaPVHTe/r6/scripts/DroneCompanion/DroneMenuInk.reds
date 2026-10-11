module DroneCompanion.Menu

import Codeware.*
import Codeware.UI.*
import Codeware.UI.TextInput.*

public func DCMFont() -> String {
  return "base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily";
}

public func DCMIconFont() -> String {
  return "dronecompanion\\fonts\\mdi.inkfontfamily";
}

public func DCMFit(text: String, most: Int32) -> String {
  if UTF8StrLen(text) <= most {
    return text;
  };
  return UTF8StrLeft(text, Max(1, most - 1)) + "\u{2026}";
}

public func DCMTextW(text: String, size: Float) -> Float {
  let chars: array<String> = [" ", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", "À", "Á", "Â", "Ã", "Ä", "Æ", "Ç", "È", "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï", "Ñ", "Ò", "Ó", "Ô", "Õ", "Ö", "Ø", "Ù", "Ú", "Û", "Ü", "Ý", "Œ", "Ą", "Ć", "Ę", "Ł", "Ń", "Ś", "Ź", "Ż", "…"];
  let widths: array<Int32> = [238, 238, 344, 672, 518, 732, 610, 187, 297, 297, 401, 549, 199, 312, 199, 404, 528, 327, 487, 504, 533, 497, 515, 412, 533, 515, 199, 199, 544, 554, 554, 469, 749, 548, 552, 540, 555, 480, 454, 543, 574, 253, 513, 548, 450, 715, 583, 552, 528, 564, 542, 548, 434, 557, 513, 802, 526, 508, 506, 309, 404, 309, 494, 372, 287, 512, 518, 405, 518, 493, 335, 514, 517, 233, 233, 456, 233, 787, 517, 504, 518, 512, 335, 435, 351, 517, 448, 691, 443, 467, 432, 308, 222, 308, 549, 547, 547, 547, 547, 547, 778, 540, 480, 480, 480, 480, 253, 253, 252, 252, 583, 552, 552, 552, 552, 552, 572, 557, 557, 557, 557, 508, 779, 547, 540, 480, 512, 583, 548, 506, 506, 601];
  let total: Int32 = 0;
  let n: Int32 = UTF8StrLen(text);
  let i: Int32 = 0;
  while i < n {
    let ch: String = UTF8StrMid(text, i, 1);
    let k: Int32 = ArrayFindFirst(chars, ch);
    total += k >= 0 ? widths[k] : (StrLen(ch) >= 3 ? 1000 : 591);
    i += 1;
  };
  return Cast<Float>(total) * size / 1000.0;
}

public func DCMFitW(text: String, room: Float, size: Float) -> String {
  if DCMTextW(text, size) <= room + 0.5 {
    return text;
  };
  let n: Int32 = UTF8StrLen(text) - 1;
  while n > 1 && DCMTextW(UTF8StrLeft(text, n) + "\u{2026}", size) > room {
    n -= 1;
  };
  return UTF8StrLeft(text, n) + "\u{2026}";
}

public func DCMUpper(text: String) -> String {
  let out: String = StrUpper(text);
  if StrLen(out) == UTF8StrLen(out) {
    return out;
  };
  let lower: array<String> = ["à", "á", "â", "ã", "ä", "å", "æ", "ç", "è", "é", "ê", "ë", "ì", "í", "î", "ï", "ð", "ñ", "ò", "ó", "ô", "õ", "ö", "ø", "ù", "ú", "û", "ü", "ý", "þ", "ÿ", "œ", "ą", "ć", "ę", "ł", "ń", "ś", "ź", "ż", "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я"];
  let upper: array<String> = ["À", "Á", "Â", "Ã", "Ä", "Å", "Æ", "Ç", "È", "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï", "Ð", "Ñ", "Ò", "Ó", "Ô", "Õ", "Ö", "Ø", "Ù", "Ú", "Û", "Ü", "Ý", "Þ", "Ÿ", "Œ", "Ą", "Ć", "Ę", "Ł", "Ń", "Ś", "Ź", "Ż", "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"];
  let i: Int32 = 0;
  while i < ArraySize(lower) {
    out = StrReplaceAll(out, lower[i], upper[i]);
    i += 1;
  };
  return out;
}

public func DCMField(parts: array<String>, i: Int32) -> String {
  if i >= ArraySize(parts) || Equals(parts[i], "~") {
    return "";
  };
  return parts[i];
}

public func DCMPadKeys() -> array<EInputKey> {
  return [EInputKey.IK_Pad_LeftShoulder, EInputKey.IK_Pad_RightShoulder, EInputKey.IK_Pad_LeftTrigger, EInputKey.IK_Pad_RightTrigger,
    EInputKey.IK_Pad_LeftThumb, EInputKey.IK_Pad_RightThumb, EInputKey.IK_Pad_A_CROSS, EInputKey.IK_Pad_B_CIRCLE,
    EInputKey.IK_Pad_X_SQUARE, EInputKey.IK_Pad_Y_TRIANGLE, EInputKey.IK_Pad_Back_Select, EInputKey.IK_Pad_Start,
    EInputKey.IK_Pad_DigitUp, EInputKey.IK_Pad_DigitDown, EInputKey.IK_Pad_DigitLeft, EInputKey.IK_Pad_DigitRight];
}

public func DCMPadNames() -> array<String> {
  return ["LB", "RB", "LT", "RT", "L3", "R3", "A", "B", "X", "Y", "Select", "Start",
    "D-pad up", "D-pad down", "D-pad left", "D-pad right"];
}

public func DCMPadIndex(key: EInputKey) -> Int32 {
  let keys: array<EInputKey> = DCMPadKeys();
  let i: Int32 = 0;
  while i < ArraySize(keys) {
    if Equals(keys[i], key) {
      return i;
    };
    i += 1;
  };
  return -1;
}

public func DCMComboText(keys: array<EInputKey>) -> String {
  let names: array<String> = DCMPadNames();
  let all: array<EInputKey> = DCMPadKeys();
  let text: String = "";
  let i: Int32 = 0;
  while i < ArraySize(all) {
    if ArrayContains(keys, all[i]) {
      text = StrLen(text) > 0 ? text + "+" + names[i] : names[i];
    };
    i += 1;
  };
  return text;
}

public func DCMKeyId(key: EInputKey) -> String {
  return EnumValueToString("EInputKey", Cast<Int64>(EnumInt(key)));
}

public func DCMKeyLabel(id: String) -> String {
  return StrBeginsWith(id, "IK_") ? StrMid(id, 3, StrLen(id) - 3) : id;
}

public func DCMIsKeyboard(id: String) -> Bool {
  return StrLen(id) > 3 && !StrBeginsWith(id, "IK_Pad") && StrFindFirst(id, "Mouse") < 0 && !Equals(id, "IK_None");
}

public func DCMTypable(id: String) -> Bool {
  return (StrLen(id) == 4 && StrBeginsWith(id, "IK_")) || Equals(id, "IK_Space");
}

public func DCMOver(target: Float, base: Float) -> Float {
  if base >= 0.999 {
    return 0.0;
  };
  return ClampF((target - base) / (1.0 - base), 0.0, 1.0);
}

public func DCMColor(text: String) -> HDRColor {
  let p: array<String> = StrSplit(text, ",");
  if ArraySize(p) < 3 {
    return new HDRColor(0.368, 0.964, 1.0, 1.0);
  };
  return new HDRColor(StringToFloat(p[0]), StringToFloat(p[1]), StringToFloat(p[2]), 1.0);
}

public func DCMResolution(game: GameInstance) -> Vector2 {
  let res: ref<ConfigVarListString> = GameInstance.GetSettingsSystem(game).GetVar(n"/video/display", n"Resolution") as ConfigVarListString;
  if !IsDefined(res) {
    return Vector2(0.0, 0.0);
  };
  let parts: array<String> = StrSplit(res.GetValue(), "x");
  if ArraySize(parts) < 2 {
    return Vector2(0.0, 0.0);
  };
  return Vector2(StringToFloat(parts[0]), StringToFloat(parts[1]));
}

public func DCMScreenScale(game: GameInstance) -> Float {
  let res: Vector2 = DCMResolution(game);
  return res.Y > 0.0 ? 2160.0 / res.Y : 1.0;
}

public func DCMScreenWidth(game: GameInstance) -> Float {
  let res: Vector2 = DCMResolution(game);
  return res.Y > 0.0 ? res.X * 2160.0 / res.Y : 3840.0;
}

public func DCMHudScale(game: GameInstance) -> Float {
  return 1.5 / DCMScreenScale(game);
}

public func DCMBindIn(group: ref<ConfigGroup>, key: CName, pre: Bool) -> String {
  if !IsDefined(group) {
    return "";
  };
  let vars: array<ref<ConfigVar>> = group.GetVars(pre);
  let i: Int32 = 0;
  while i < ArraySize(vars) {
    let bind: ref<ConfigVarName> = vars[i] as ConfigVarName;
    if IsDefined(bind) && Equals(bind.GetValue(), key) {
      let name: String = GetLocalizedTextByKey(bind.GetDisplayName());
      return StrLen(name) > 0 ? name : NameToString(bind.GetName());
    };
    i += 1;
  };
  let groups: array<ref<ConfigGroup>> = group.GetGroups(pre);
  i = 0;
  while i < ArraySize(groups) {
    let found: String = DCMBindIn(groups[i], key, pre);
    if StrLen(found) > 0 {
      return found;
    };
    i += 1;
  };
  return "";
}

public func DCMGameBind(key: String) -> String {
  if !StrBeginsWith(key, "IK_") {
    return "";
  };
  let root: ref<ConfigGroup> = GameInstance.GetSettingsSystem(GetGameInstance()).GetRootGroup();
  return DCMBindIn(root, StringToName(key), GameInstance.GetSystemRequestsHandler().IsPreGame());
}

public func DCMPillarWidth(game: GameInstance) -> Float {
  return MaxF(0.0, (DCMScreenWidth(game) - 3840.0) / 2.0);
}

public class DCMMenuRow {
  public let kind: String;
  public let id: String;
  public let label: String;
  public let value: String;
  public let rank: Int32;
  public let glyph: String;
  public let desc: String;
  public let changed: Bool;
  public let key: String;
  public let flags: String;
  public let brand: String;
  public let raw: String;
  public let pic: String;
  public let tint: String;

  public func Has(flag: String) -> Bool {
    return StrFindFirst(this.flags, flag) >= 0;
  }

  public func IsSelectable() -> Bool {
    return Equals(this.kind, "key") || Equals(this.kind, "toggle") || Equals(this.kind, "ftoggle") || Equals(this.kind, "check")
      || Equals(this.kind, "choice") || Equals(this.kind, "item")
      || Equals(this.kind, "btn") || Equals(this.kind, "fbtn") || Equals(this.kind, "apply") || Equals(this.kind, "head");
  }

  public func IsOption() -> Bool {
    return this.IsSelectable() && !this.IsHead();
  }

  public func IsOpen() -> Bool {
    return StrBeginsWith(this.value, "1");
  }

  public func GroupSize() -> String {
    let parts: array<String> = StrSplit(this.value, "|");
    return ArraySize(parts) > 1 ? parts[1] : "";
  }

  public func IsStepper() -> Bool {
    return Equals(this.kind, "choice") || Equals(this.kind, "item") || Equals(this.kind, "apply");
  }

  public func IsSwitch() -> Bool {
    return Equals(this.kind, "toggle") || Equals(this.kind, "ftoggle") || Equals(this.kind, "check");
  }

  public func IsHead() -> Bool {
    return Equals(this.kind, "head");
  }
}

public class DCMSearchInput extends TextInput {
  protected let m_edges: array<wref<inkWidget>>;
  protected let m_accent: HDRColor;

  protected func CreateWidgets() {
    super.CreateWidgets();
    let height: Float = 52.0;
    let size: Int32 = 28;
    this.m_text.SetFontSize(size);
    this.m_root.SetHeight(height);
    this.m_wrapper.SetMargin(inkMargin(14.0, (height - Cast<Float>(size)) / 2.0 - 1.0, 14.0, 0.0));
    let text: ref<inkText> = this.m_text.GetRootWidget() as inkText;
    if IsDefined(text) {
      text.UnbindProperty(n"tintColor");
      text.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
      text.SetFontFamily(DCMFont());
    };
    let shadow: ref<inkText> = this.m_measurer.GetRootWidget() as inkText;
    if IsDefined(shadow) {
      shadow.SetFontFamily(DCMFont());
    };
    let bg: ref<inkRectangle> = new inkRectangle();
    bg.SetAnchor(inkEAnchor.Fill);
    bg.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    bg.SetOpacity(0.45);
    bg.Reparent(this.m_root, 0);
    this.Edge(inkEAnchor.TopFillHorizontaly, Vector2(0.0, 2.0));
    this.Edge(inkEAnchor.BottomFillHorizontaly, Vector2(0.0, 2.0));
    this.Edge(inkEAnchor.LeftFillVerticaly, Vector2(2.0, 0.0));
    this.Edge(inkEAnchor.RightFillVerticaly, Vector2(2.0, 0.0));
  }

  protected func Edge(anchor: inkEAnchor, size: Vector2) -> Void {
    let edge: ref<inkRectangle> = new inkRectangle();
    edge.SetAnchor(anchor);
    edge.SetSize(size);
    edge.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
    edge.SetOpacity(0.15);
    edge.Reparent(this.m_root);
    ArrayPush(this.m_edges, edge);
  }

  public func SetAccent(color: HDRColor) -> Void {
    this.m_accent = color;
    this.ApplyFocusedState();
  }

  protected func ApplyFocusedState() {
    let i: Int32 = 0;
    while i < ArraySize(this.m_edges) {
      this.m_edges[i].SetTintColor(this.m_isFocused ? this.m_accent : new HDRColor(1.0, 1.0, 1.0, 1.0));
      this.m_edges[i].SetOpacity(this.m_isFocused ? 1.0 : 0.15);
      i += 1;
    };
  }

  public static func Create() -> ref<DCMSearchInput> {
    let self: ref<DCMSearchInput> = new DCMSearchInput();
    self.m_accent = new HDRColor(0.368, 0.964, 1.0, 1.0);
    self.CreateInstance();
    return self;
  }
}

public class DCMMenuPopup extends InGamePopup {
  protected let m_rows: array<ref<DCMMenuRow>>;
  protected let m_tabNames: array<String>;
  protected let m_tabGlyphs: array<String>;
  protected let m_tabCountText: array<String>;
  protected let m_subNames: array<String>;
  protected let m_tab: Int32;
  protected let m_sub: Int32;
  protected let m_searchId: String;
  protected let m_footNote: String;
  protected let m_loaded: Bool;
  protected let m_rowCells: array<wref<inkWidget>>;
  protected let m_rowSel: array<wref<inkWidget>>;
  protected let m_rowBgs: array<wref<inkWidget>>;
  protected let m_rowLabels: array<wref<inkText>>;
  protected let m_rowIcons: array<wref<inkText>>;
  protected let m_rowGlyphs: array<wref<inkText>>;
  protected let m_subCountText: array<String>;
  protected let m_collapsed: Bool;
  protected let m_helpOn: Bool;
  protected let m_help: wref<inkCanvas>;
  protected let m_back: wref<inkWidget>;
  protected let m_descBox: wref<inkWidget>;
  protected let m_descBack: wref<inkWidget>;
  protected let m_descTint: wref<inkWidget>;
  protected let m_shownRows: Int32;
  protected let m_foot: wref<inkWidget>;
  protected let m_restoreId: String;
  protected let m_restoreFirst: Int32;
  protected let m_rowValues: array<wref<inkText>>;
  protected let m_rowLeft: array<wref<inkText>>;
  protected let m_rowRight: array<wref<inkText>>;
  protected let m_rowBoxes: array<wref<inkText>>;
  protected let m_rowResets: array<wref<inkText>>;
  protected let m_rowCellValues: array<wref<inkHorizontalPanel>>;
  protected let m_selColor: HDRColor;
  protected let m_selAlpha: Float;
  protected let m_selInk: HDRColor;
  protected let m_hasSelInk: Bool;
  protected let m_tabsBack: wref<inkWidget>;
  protected let m_barBack: wref<inkWidget>;
  protected let m_footBack: wref<inkWidget>;
  protected let m_tabNameTexts: array<wref<inkText>>;
  protected let m_tabIconTexts: array<wref<inkText>>;
  protected let m_placeKey: String;
  protected let m_capture: Bool;
  protected let m_capId: String;
  protected let m_capEnd: Float;
  protected let m_capAt: Float;
  protected let m_capHeld: Int32;
  protected let m_capKeys: array<EInputKey>;
  protected let m_card: wref<inkCanvas>;
  protected let m_cardIcons: array<wref<inkText>>;
  protected let m_cardNames: array<wref<inkText>>;
  protected let m_cardValues: array<wref<inkText>>;
  protected let m_hasCard: Bool;
  protected let m_rowValueKeys: array<String>;
  protected let m_tabsPanel: wref<inkVerticalPanel>;
  protected let m_tabCells: array<wref<inkWidget>>;
  protected let m_tabSel: array<wref<inkWidget>>;
  protected let m_tabCounts: array<wref<inkText>>;
  protected let m_subBar: wref<inkCanvas>;
  protected let m_subStrip: wref<inkCanvas>;
  protected let m_subCells: array<wref<inkWidget>>;
  protected let m_subIdx: array<Int32>;
  protected let m_subLead: wref<inkWidget>;
  protected let m_subTail: wref<inkWidget>;
  protected let m_searchBar: wref<inkCanvas>;
  protected let m_search: ref<DCMSearchInput>;
  protected let m_frame: wref<inkCanvas>;
  protected let m_view: wref<inkScrollArea>;
  protected let m_list: wref<inkVerticalPanel>;
  protected let m_title: wref<inkText>;
  protected let m_counter: wref<inkText>;
  protected let m_desc: wref<inkText>;
  protected let m_descTitle: wref<inkText>;
  protected let m_descPic: wref<inkImage>;
  protected let m_descPicOn: Bool;
  protected let m_footPanel: wref<inkHorizontalPanel>;
  protected let m_accent: HDRColor;
  protected let m_bright: HDRColor;
  protected let m_first: Int32;
  protected let m_sel: Int32;
  protected let m_hover: Int32;
  protected let m_zone: Int32;
  protected let m_pad: Bool;
  protected let m_dragging: Bool;
  protected let m_dragStart: Vector2;
  protected let m_dragMargin: inkMargin;
  protected let m_scale: Float;
  protected let m_onLayer: Bool;
  protected let m_layerRoot: wref<inkCanvas>;
  protected let m_owner: wref<DCMMenuPopup>;
  protected let m_pos: Vector2;
  protected let m_stickAt: Float;
  protected let m_trigAt: Float;
  protected let m_lastKey: EInputKey;
  protected let m_ctrl: Bool;
  protected let m_searchTab: Bool;
  protected let m_descOff: Bool;
  protected let m_shift: Bool;
  protected let m_ltHeld: Bool;
  protected let m_rtHeld: Bool;
  protected let m_trigUsed: Bool;
  protected let m_hoverPart: wref<inkWidget>;
  protected let m_lastText: String;
  protected let m_quiet: Bool;
  protected let m_ui: array<String>;
  protected let m_uiKey: String;
  protected let m_photo: wref<inkCanvas>;
  protected let m_photoImg: wref<inkImage>;
  protected let m_photoTitle: wref<inkText>;
  protected let m_photoText: wref<inkText>;
  protected let m_hasPhoto: Bool;
  protected let m_hintsOff: Bool;
  protected let m_starOn: String;
  protected let m_starOff: String;
  protected let m_tabsBg: wref<inkCanvas>;
  protected let m_rowStars: array<wref<inkText>>;
  protected let m_descLines: Int32;
  protected let m_edit: ref<DCMSearchInput>;
  protected let m_editBar: wref<inkCanvas>;
  protected let m_editId: String;
  protected let m_editVerb: String;
  protected let m_editAt: Float;
  protected let m_editEnd: Float;
  protected let m_clickAt: Float;
  protected let m_clickRow: Int32;
  protected let m_footKey: String;
  protected let m_tabW: Float;
  protected let m_extraW: Float;
  protected let m_extraH: Float;
  protected let m_menuScale: Float;
  protected let m_resizing: Int32;
  protected let m_resizeStart: Vector2;
  protected let m_resizeBase: Vector2;
  protected let m_grip: wref<inkCanvas>;
  protected let m_holdKey: EInputKey;
  protected let m_seenId: String;
  protected let m_edgeRight: wref<inkWidget>;
  protected let m_edgeBottom: wref<inkWidget>;
  protected let m_builtW: Float;
  protected let m_cardCells: array<wref<inkWidget>>;

  public func GetName() -> CName {
    return n"DCMMenuPopup";
  }

  public func GetQueueName() -> CName {
    return n"dcm_menu";
  }

  public func UseCursor() -> Bool {
    return true;
  }

  public func IsOpen() -> Bool {
    return this.IsInitialized();
  }

  protected func CreateVignette() {}

  protected func SetTimeDilation() {}

  protected func ResetTimeDilation() {}

  protected func SetBackgroundBlur() {}

  protected func ResetBackgroundBlur() {}

  protected func SetUIContext() {
    if this.m_onLayer {
      return;
    };
    GameInstance.GetUISystem(this.GetGame()).RequestNewVisualState(n"inkPhotoModeState");
  }

  protected func ResetUIContext() {
    if this.m_onLayer {
      return;
    };
    GameInstance.GetUISystem(this.GetGame()).RestorePreviousVisualState(n"inkPhotoModeState");
  }

  public func GetGame() -> GameInstance {
    if this.m_onLayer {
      return GetGameInstance();
    };
    return super.GetGame();
  }

  public func OnLayer() -> Bool {
    return this.m_onLayer;
  }

  public func IsWin() -> Bool {
    return false;
  }

  public func MenuPos() -> Vector2 {
    return this.m_pos;
  }

  public func MenuW() -> Float {
    return this.m_collapsed ? this.TabW() : this.W();
  }

  public func Hovering() -> Bool {
    return this.m_hover >= 0;
  }

  public func Owns(widget: wref<inkWidget>) -> Bool {
    let w: wref<inkWidget> = widget;
    let n: Int32 = 0;
    while IsDefined(w) && n < 24 {
      if Equals(w, this.m_container) {
        return true;
      };
      w = w.GetParentWidget();
      n += 1;
    };
    return false;
  }

  protected func FocusWin() -> Bool {
    let player: ref<PlayerPuppet> = this.Player();
    return IsDefined(player) && player.m_dcmFocusWin;
  }

  protected func ClaimFocus() -> Void {
    let player: ref<PlayerPuppet> = this.Player();
    if IsDefined(player) {
      player.m_dcmFocusWin = this.IsWin();
    };
  }

  protected func WinOwns(widget: wref<inkWidget>) -> Bool {
    let player: ref<PlayerPuppet> = this.Player();
    return IsDefined(player) && IsDefined(player.m_dcmSquad) && player.m_dcmSquad.Owns(widget);
  }

  public func Close() {
    if this.m_onLayer {
      this.Detach();
      return;
    };
    super.Close();
  }

  protected cb func OnHidden() {
    if !this.m_onLayer {
      super.OnHidden();
      return;
    };
    let root: wref<inkCanvas> = this.m_layerRoot;
    if IsDefined(root) {
      let parent: ref<inkCompoundWidget> = root.GetParentWidget() as inkCompoundWidget;
      if IsDefined(parent) {
        parent.RemoveChild(root);
      };
    };
    this.ResetGameController();
    this.ResetRootWidget();
  }

  protected func BaseW() -> Float { return 1040.0; }
  protected func BaseH() -> Float { return 1016.0; }
  protected func W() -> Float { return this.BaseW() + this.m_extraW; }
  protected func H() -> Float { return this.BaseH() + this.m_extraH; }
  protected func Bar() -> Float { return 56.0; }
  protected func TabW() -> Float { return this.m_tabW > 0.0 ? this.m_tabW : 320.0; }
  protected func RowH() -> Float { return 52.0; }
  protected func Foot() -> Float { return this.m_hintsOff ? 0.0 : 56.0; }
  protected func SubH() -> Float { return 52.0; }
  protected func SearchH() -> Float { return 76.0; }
  protected func DescMin() -> Float {
    return this.m_descOff ? 0.0 : 48.0;
  }

  protected func DescBoxH() -> Float {
    if this.m_descOff || (this.m_descLines == 0 && !this.m_descPicOn) {
      return 0.0;
    };
    let h: Float = this.m_descLines > 0 ? 50.0 + Cast<Float>(this.m_descLines) * 29.0 : 48.0;
    return this.m_descPicOn ? MaxF(h, 124.0) : h;
  }

  protected func DescIndent() -> Float {
    return this.m_descPicOn ? 112.0 : 0.0;
  }

  protected func TotalH() -> Float {
    let tabs: Float = this.Bar() + Cast<Float>(ArraySize(this.m_tabNames)) * this.RowH();
    return MaxF(this.DescTop() + this.DescBoxH(), tabs) + this.Foot();
  }

  protected func FitTabW() -> Float {
    let widest: Float = 0.0;
    let t: Int32 = 0;
    while t < ArraySize(this.m_tabNames) {
      let count: String = t < ArraySize(this.m_tabCountText) ? this.m_tabCountText[t] : "";
      let w: Float = 62.0 + DCMTextW(this.m_tabNames[t], 28.0) + (StrLen(count) > 0 ? 32.0 + DCMTextW(count, 24.0) : 24.0);
      widest = MaxF(widest, w);
      t += 1;
    };
    return MaxF(widest, 160.0);
  }
  protected func CardH() -> Float { return 124.0; }
  protected func PhotoH() -> Float { return 232.0; }
  protected func ContentW() -> Float { return this.W() - this.TabW(); }

  protected func HasSubs() -> Bool {
    return ArraySize(this.m_subNames) > 0;
  }

  protected func SearchShown() -> Bool {
    return !this.m_pad;
  }

  protected func CardTop() -> Float {
    let top: Float = this.Bar();
    if this.HasSubs() {
      top += this.SubH();
    };
    if this.SearchShown() {
      top += this.SearchH();
    };
    return top;
  }

  protected func ListTop() -> Float {
    return this.CardTop() + (this.m_hasCard ? this.CardH() : 0.0) + (this.m_hasPhoto ? this.PhotoH() : 0.0);
  }

  protected func ListH() -> Float {
    let bottom: Float = this.H() - this.Foot() - this.DescMin();
    if this.DescBoxH() <= 0.0 {
      bottom = MaxF(this.H() - this.Foot(), this.Bar() + Cast<Float>(ArraySize(this.m_tabNames)) * this.RowH());
    };
    return bottom - this.ListTop();
  }

  protected func Visible() -> Int32 {
    return Cast<Int32>(this.ListH() / this.RowH());
  }

  protected func ScreenScale() -> Float {
    return DCMScreenScale(this.GetGame());
  }

  protected func Pillar() -> Float {
    return this.m_onLayer ? DCMPillarWidth(this.GetGame()) : 0.0;
  }

  protected func HomePos() -> Vector2 {
    return Vector2(this.Pillar() + 32.0, 260.0);
  }

  protected func UI(i: Int32, fallback: String) -> String {
    let text: String = DCMField(this.m_ui, i);
    return StrLen(text) > 0 ? text : fallback;
  }

  protected func CreateContainer() {
    let container: ref<inkCanvas> = new inkCanvas();
    container.SetName(n"container");
    container.SetAnchor(inkEAnchor.TopLeft);
    container.SetAnchorPoint(Vector2(0.0, 0.0));
    container.SetMargin(inkMargin(this.HomePos().X, this.HomePos().Y, 0.0, 0.0));
    container.SetSize(Vector2(this.W(), this.H()));
    container.Reparent(this.GetRootCompoundWidget());
    this.m_container = container;
    this.SetContainerWidget(container);
  }

  protected func Rect(parent: wref<inkCompoundWidget>, color: HDRColor, alpha: Float) -> ref<inkRectangle> {
    let rect: ref<inkRectangle> = new inkRectangle();
    rect.SetAnchor(inkEAnchor.Fill);
    rect.SetTintColor(color);
    rect.SetOpacity(alpha);
    rect.Reparent(parent);
    return rect;
  }

  protected func Text(parent: wref<inkCompoundWidget>, size: Int32) -> ref<inkText> {
    let text: ref<inkText> = new inkText();
    text.SetFontFamily(DCMFont(), n"Medium");
    text.SetFontStyle(n"Medium");
    text.SetFontSize(size);
    text.SetFitToContent(true);
    text.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
    text.Reparent(parent);
    return text;
  }

  protected func Icon(parent: wref<inkCompoundWidget>, size: Int32, glyph: String) -> ref<inkText> {
    let icon: ref<inkText> = new inkText();
    icon.SetFontFamily(DCMIconFont(), n"Regular");
    icon.SetFontStyle(n"Regular");
    icon.SetFontSize(size);
    icon.SetFitToContent(true);
    icon.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
    icon.SetText(glyph);
    icon.Reparent(parent);
    return icon;
  }

  protected func Left(text: ref<inkText>, margin: Float) -> Void {
    text.SetAnchor(inkEAnchor.CenterLeft);
    text.SetAnchorPoint(Vector2(0.0, 0.5));
    text.SetMargin(inkMargin(margin, 0.0, 0.0, 0.0));
  }

  protected func Right(text: ref<inkText>, margin: Float) -> Void {
    text.SetAnchor(inkEAnchor.CenterRight);
    text.SetAnchorPoint(Vector2(1.0, 0.5));
    text.SetMargin(inkMargin(0.0, 0.0, margin, 0.0));
  }

  protected cb func OnCreate() {
    super.OnCreate();
    this.m_hover = -1;
    this.m_accent = new HDRColor(0.88, 0.16, 0.14, 1.0);
    this.m_bright = new HDRColor(1.0, 0.35, 0.3, 1.0);
    this.m_selColor = this.m_accent;
    this.m_selAlpha = 0.24;
    this.m_pos = this.HomePos();
    this.m_scale = this.ScreenScale();
    this.m_menuScale = 1.0;
    this.m_clickRow = -1;
    let owner: ref<PlayerPuppet> = this.Player();
    if IsDefined(owner) && !this.IsWin() {
      if owner.m_dcmMenuHasPos {
        this.m_pos = owner.m_dcmMenuPos;
        this.m_container.SetMargin(inkMargin(this.m_pos.X, this.m_pos.Y, 0.0, 0.0));
      };
      this.m_collapsed = owner.m_dcmMenuCollapsed;
      this.m_zone = this.m_collapsed ? 1 : 0;
      this.m_restoreId = owner.m_dcmMenuSelId;
      this.m_restoreFirst = owner.m_dcmMenuFirst;
    };

    let root: wref<inkCompoundWidget> = this.m_container;
    let back: ref<inkRectangle> = this.Rect(root, new HDRColor(0.02, 0.02, 0.03, 1.0), 0.72);
    back.SetAnchor(inkEAnchor.TopLeft);
    back.SetSize(Vector2(this.W(), this.H()));
    this.m_back = back;

    let bar: ref<inkCanvas> = new inkCanvas();
    bar.SetName(n"titleBar");
    bar.SetAnchor(inkEAnchor.TopFillHorizontaly);
    bar.SetSize(Vector2(this.W(), this.Bar()));
    bar.SetInteractive(true);
    bar.Reparent(root);
    this.m_barBack = this.Rect(bar, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.9);
    let title: ref<inkText> = this.Text(bar, 28);
    title.SetFontStyle(n"Semi-Bold");
    this.Left(title, 20.0);
    this.m_title = title;
    let counter: ref<inkText> = this.Text(bar, 26);
    this.Right(counter, 20.0);
    counter.SetOpacity(0.7);
    this.m_counter = counter;
    bar.RegisterToCallback(n"OnPress", this, n"OnDCMTitlePress");

    let tabsBg: ref<inkCanvas> = new inkCanvas();
    tabsBg.SetMargin(inkMargin(0.0, this.Bar(), 0.0, 0.0));
    tabsBg.SetSize(Vector2(this.TabW(), this.H() - this.Bar() - this.Foot()));
    tabsBg.Reparent(root);
    this.m_tabsBg = tabsBg;
    this.m_tabsBack = this.Rect(tabsBg, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.35);
    let tabs: ref<inkVerticalPanel> = new inkVerticalPanel();
    tabs.Reparent(tabsBg);
    this.m_tabsPanel = tabs;

    let subBar: ref<inkCanvas> = new inkCanvas();
    subBar.SetMargin(inkMargin(this.TabW(), this.Bar(), 0.0, 0.0));
    subBar.SetSize(Vector2(this.ContentW(), this.SubH()));
    subBar.Reparent(root);
    this.Rect(subBar, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.5);
    this.m_subBar = subBar;

    let searchBar: ref<inkCanvas> = new inkCanvas();
    searchBar.SetSize(Vector2(this.ContentW(), this.SearchH()));
    searchBar.Reparent(root);
    this.m_search = DCMSearchInput.Create();
    this.m_search.SetName(n"dcmSearch");
    this.m_search.SetMaxLength(48);
    this.m_search.SetWidth(this.ContentW() - 24.0);
    this.m_search.GetRootWidget().SetMargin(inkMargin(12.0, 12.0, 0.0, 0.0));
    this.m_search.Reparent(searchBar);
    this.m_search.RegisterToCallback(n"OnInput", this, n"OnDCMSearchInput");
    this.m_searchBar = searchBar;

    let frame: ref<inkCanvas> = new inkCanvas();
    frame.Reparent(root);
    let view: ref<inkScrollArea> = new inkScrollArea();
    view.SetUseInternalMask(true);
    view.Reparent(frame);
    let list: ref<inkVerticalPanel> = new inkVerticalPanel();
    list.Reparent(view);
    this.m_frame = frame;
    this.m_view = view;
    this.m_list = list;
    this.GrowPool(this.Visible() + 1);

    this.BuildCard();
    this.BuildPhoto();

    let descBox: ref<inkCanvas> = new inkCanvas();
    descBox.SetMargin(inkMargin(this.TabW(), this.H() - this.Foot() - this.DescMin(), 0.0, 0.0));
    descBox.SetSize(Vector2(this.ContentW(), this.DescMin()));
    descBox.Reparent(root);
    this.m_descBox = descBox;
    this.m_descBack = this.Rect(descBox, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.9);
    this.m_descTint = this.Rect(descBox, new HDRColor(1.0, 1.0, 1.0, 1.0), 0.12);
    let descTitle: ref<inkText> = this.Text(descBox, 24);
    descTitle.SetFontStyle(n"Semi-Bold");
    descTitle.SetMargin(inkMargin(28.0, 8.0, 0.0, 0.0));
    this.m_descTitle = descTitle;
    let desc: ref<inkText> = this.Text(descBox, 22);
    desc.SetOpacity(0.75);
    desc.SetWrapping(true, this.ContentW() - 56.0);
    desc.SetMargin(inkMargin(28.0, 40.0, 0.0, 0.0));
    this.m_desc = desc;
    let pic: ref<inkImage> = new inkImage();
    pic.SetAtlasResource(ResRef.FromString("dronecompanion\\gui\\dc_icons.inkatlas"));
    pic.SetSize(Vector2(100.0, 100.0));
    pic.SetMargin(inkMargin(16.0, 12.0, 0.0, 0.0));
    pic.SetVisible(false);
    pic.Reparent(descBox);
    this.m_descPic = pic;

    let foot: ref<inkCanvas> = new inkCanvas();
    foot.SetMargin(inkMargin(0.0, this.H() - this.Foot(), 0.0, 0.0));
    foot.SetSize(Vector2(this.W(), this.Foot()));
    foot.Reparent(root);
    this.m_footBack = this.Rect(foot, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.9);
    let footPanel: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    footPanel.SetAnchor(inkEAnchor.CenterRight);
    footPanel.SetAnchorPoint(Vector2(1.0, 0.5));
    footPanel.SetMargin(inkMargin(0.0, 0.0, 40.0, 0.0));
    footPanel.SetFitToContent(true);
    footPanel.Reparent(foot);
    this.m_footPanel = footPanel;
    this.m_foot = foot;

    let editBar: ref<inkCanvas> = new inkCanvas();
    editBar.SetSize(Vector2(this.ContentW(), this.RowH()));
    editBar.SetVisible(false);
    editBar.Reparent(root);
    this.m_edit = DCMSearchInput.Create();
    this.m_edit.SetName(n"dcmEdit");
    this.m_edit.SetMaxLength(48);
    this.m_edit.Reparent(editBar);
    this.m_editBar = editBar;

    this.BuildResize();
    this.BuildHelp();
    this.Layout();
    this.PaintFooter();
  }

  protected func ResizeEdge(parent: wref<inkCompoundWidget>) -> ref<inkRectangle> {
    let edge: ref<inkRectangle> = new inkRectangle();
    edge.SetAnchor(inkEAnchor.TopLeft);
    edge.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
    edge.SetOpacity(0.01);
    edge.SetInteractive(true);
    edge.Reparent(parent);
    edge.RegisterToCallback(n"OnPress", this, n"OnDCMResizePress");
    edge.RegisterToCallback(n"OnEnter", this, n"OnDCMResizeEnter");
    edge.RegisterToCallback(n"OnLeave", this, n"OnDCMResizeLeave");
    return edge;
  }

  protected func BuildResize() -> Void {
    let root: wref<inkCompoundWidget> = this.m_container;
    this.m_edgeRight = this.ResizeEdge(root);
    this.m_edgeBottom = this.ResizeEdge(root);
    let grip: ref<inkCanvas> = new inkCanvas();
    grip.SetAnchor(inkEAnchor.TopLeft);
    grip.SetSize(Vector2(28.0, 28.0));
    grip.SetInteractive(true);
    grip.Reparent(root);
    let hit: ref<inkRectangle> = this.Rect(grip, new HDRColor(1.0, 1.0, 1.0, 1.0), 0.01);
    hit.SetInteractive(true);
    let i: Int32 = 0;
    while i < 3 {
      let j: Int32 = 0;
      while j <= i {
        let dot: ref<inkRectangle> = new inkRectangle();
        dot.SetAnchor(inkEAnchor.TopLeft);
        dot.SetSize(Vector2(4.0, 4.0));
        dot.SetMargin(inkMargin(20.0 - Cast<Float>(j) * 8.0, 8.0 + Cast<Float>(i) * 8.0, 0.0, 0.0));
        dot.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
        dot.SetOpacity(0.5);
        dot.Reparent(grip);
        j += 1;
      };
      i += 1;
    };
    grip.RegisterToCallback(n"OnPress", this, n"OnDCMResizePress");
    this.m_grip = grip;
  }

  public func IsEditing() -> Bool {
    return StrLen(this.m_editId) > 0;
  }

  protected func OpenEdit(verb: String) -> Void {
    let row: ref<DCMMenuRow> = this.Selected();
    if this.m_pad || !IsDefined(row) || this.m_sel < this.m_first || this.m_sel >= this.m_first + this.Visible() {
      return;
    };
    let rename: Bool = Equals(verb, "ren");
    let width: Float = rename ? this.ContentW() - 40.0 : 300.0;
    let x: Float = rename ? 20.0 : this.ContentW() - width - 12.0;
    this.m_editBar.SetMargin(inkMargin(this.TabW() + x, this.ListTop() + Cast<Float>(this.m_sel - this.m_first) * this.RowH(), 0.0, 0.0));
    this.m_edit.SetWidth(width);
    this.m_edit.SetText(rename ? row.label : row.raw);
    this.m_edit.SetAccent(this.m_accent);
    this.m_editBar.SetVisible(true);
    this.m_editId = row.id;
    this.m_editVerb = verb;
    this.m_editAt = this.Now();
    this.GetGameController().RequestSetFocus(this.m_edit.GetRootWidget());
  }

  protected func CloseEdit(commit: Bool) -> Void {
    if !this.IsEditing() || (commit && this.Now() - this.m_editAt < 0.3) {
      return;
    };
    this.m_editEnd = this.Now();
    let id: String = this.m_editId;
    this.m_editId = "";
    this.m_editBar.SetVisible(false);
    this.GetGameController().RequestSetFocus(null);
    if commit {
      this.Emit(this.m_editVerb + "\t" + id + "\t" + this.m_edit.GetText());
    };
  }

  public func ToggleFav() -> Void {
    let row: ref<DCMMenuRow> = this.Selected();
    if this.m_zone == 0 && !this.m_collapsed && IsDefined(row) && row.Has("s") {
      this.Emit("fav\t" + row.id);
    };
  }

  public func RenameSelected() -> Void {
    let row: ref<DCMMenuRow> = this.Selected();
    if IsDefined(row) && row.Has("n") && this.m_zone == 0 {
      this.OpenEdit("ren");
    };
  }

  protected func BuildCard() -> Void {
    let card: ref<inkCanvas> = new inkCanvas();
    card.SetSize(Vector2(this.ContentW(), this.CardH()));
    card.Reparent(this.m_container);
    this.Rect(card, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.35);
    let i: Int32 = 0;
    while i < 6 {
      let cell: ref<inkCanvas> = new inkCanvas();
      cell.Reparent(card);
      ArrayPush(this.m_cardCells, cell);
      let icon: ref<inkText> = this.Icon(cell, 30, "");
      this.Left(icon, 8.0);
      let name: ref<inkText> = this.Text(cell, 19);
      name.SetOpacity(0.6);
      name.SetMargin(inkMargin(48.0, 2.0, 0.0, 0.0));
      let value: ref<inkText> = this.Text(cell, 26);
      value.SetFontStyle(n"Semi-Bold");
      value.SetMargin(inkMargin(48.0, 24.0, 0.0, 0.0));
      ArrayPush(this.m_cardIcons, icon);
      ArrayPush(this.m_cardNames, name);
      ArrayPush(this.m_cardValues, value);
      i += 1;
    };
    card.SetVisible(false);
    this.m_card = card;
  }

  protected func BuildPhoto() -> Void {
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(this.ContentW(), this.PhotoH()));
    box.Reparent(this.m_container);
    this.Rect(box, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.35);
    let img: ref<inkImage> = new inkImage();
    img.SetAtlasResource(ResRef.FromString("dronecompanion\\gui\\dc_icons.inkatlas"));
    img.SetSize(Vector2(200.0, 200.0));
    img.SetMargin(inkMargin(16.0, 16.0, 0.0, 0.0));
    img.Reparent(box);
    let title: ref<inkText> = this.Text(box, 30);
    title.SetFontStyle(n"Semi-Bold");
    title.SetMargin(inkMargin(236.0, 14.0, 0.0, 0.0));
    let text: ref<inkText> = this.Text(box, 22);
    text.SetOpacity(0.75);
    text.SetWrapping(true, this.ContentW() - 256.0);
    text.SetMargin(inkMargin(236.0, 56.0, 0.0, 0.0));
    box.SetVisible(false);
    this.m_photo = box;
    this.m_photoImg = img;
    this.m_photoTitle = title;
    this.m_photoText = text;
  }

  protected func FillPhoto(f: array<String>) -> Void {
    this.m_photoImg.SetTexturePart(StringToName(DCMField(f, 1)));
    this.m_photoTitle.SetText(DCMFit(DCMUpper(DCMField(f, 2)), 30));
    this.m_photoTitle.SetTintColor(this.m_bright);
    let text: String = "";
    let i: Int32 = 3;
    while i < ArraySize(f) {
      text = StrLen(text) > 0 ? text + "\n" + DCMField(f, i) : DCMField(f, i);
      i += 1;
    };
    this.m_photoText.SetText(text);
  }

  protected func FillCard(f: array<String>) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.m_cardNames) {
      this.m_cardIcons[i].SetText(DCMField(f, 1 + i * 3));
      this.m_cardIcons[i].SetTintColor(this.m_bright);
      this.m_cardNames[i].SetText(DCMUpper(DCMField(f, 2 + i * 3)));
      this.m_cardValues[i].SetText(DCMField(f, 3 + i * 3));
      this.m_cardValues[i].SetTintColor(this.m_bright);
      i += 1;
    };
  }

  protected func Layout() -> Void {
    let open: Bool = !this.m_collapsed;
    let list: Bool = open && !this.m_helpOn;
    let tabW: Float = this.TabW();
    let contentW: Float = this.ContentW();
    this.GrowPool(this.Visible() + 1);
    if AbsF(this.m_builtW - contentW) > 0.5 {
      this.m_builtW = contentW;
      this.BuildSubs();
      this.BuildHelp();
      this.PaintFooter();
    };
    this.m_card.SetVisible(list && this.m_hasCard);
    this.m_card.SetMargin(inkMargin(tabW, this.CardTop(), 0.0, 0.0));
    this.m_card.SetSize(Vector2(contentW, this.CardH()));
    let cellW: Float = (contentW - 16.0) / 3.0;
    let i: Int32 = 0;
    while i < ArraySize(this.m_cardCells) {
      this.m_cardCells[i].SetMargin(inkMargin(8.0 + Cast<Float>(i % 3) * cellW, 6.0 + Cast<Float>(i / 3) * 56.0, 0.0, 0.0));
      this.m_cardCells[i].SetSize(Vector2(cellW, 56.0));
      i += 1;
    };
    this.m_photo.SetVisible(list && this.m_hasPhoto);
    this.m_photo.SetMargin(inkMargin(tabW, this.CardTop() + (this.m_hasCard ? this.CardH() : 0.0), 0.0, 0.0));
    this.m_photo.SetSize(Vector2(contentW, this.PhotoH()));
    this.m_photoText.SetWrapping(true, contentW - 256.0);
    this.m_subBar.SetVisible(list && this.HasSubs());
    this.m_subBar.SetMargin(inkMargin(tabW, this.Bar(), 0.0, 0.0));
    this.m_subBar.SetSize(Vector2(contentW, this.SubH()));
    this.m_searchBar.SetVisible(list && this.SearchShown());
    this.m_searchBar.SetSize(Vector2(contentW, this.SearchH()));
    this.m_search.SetWidth(contentW - 24.0);
    this.m_frame.SetVisible(list);
    let total: Float = this.TotalH();
    this.m_descBox.SetVisible(open && this.DescBoxH() > 0.0);
    this.m_foot.SetVisible(open && !this.m_hintsOff);
    this.m_foot.SetMargin(inkMargin(0.0, total - this.Foot(), 0.0, 0.0));
    this.m_foot.SetSize(Vector2(this.W(), this.Foot()));
    this.m_help.SetVisible(open && this.m_helpOn);
    this.m_help.SetMargin(inkMargin(tabW, this.Bar(), 0.0, 0.0));
    this.m_help.SetSize(Vector2(contentW, total - this.Bar() - this.Foot()));
    this.m_back.SetSize(Vector2(open ? this.W() : tabW, open ? total : total - this.Foot()));
    this.m_tabsBg.SetSize(Vector2(tabW, total - this.Bar() - this.Foot()));
    this.m_container.SetSize(Vector2(open ? this.W() : tabW, total));
    let searchTop: Float = this.Bar() + (this.HasSubs() ? this.SubH() : 0.0);
    this.m_searchBar.SetMargin(inkMargin(tabW, searchTop, 0.0, 0.0));
    this.m_frame.SetMargin(inkMargin(tabW, this.ListTop(), 0.0, 0.0));
    this.m_frame.SetSize(Vector2(contentW, this.ListH()));
    this.m_view.SetSize(Vector2(contentW, this.ListH()));
    i = 0;
    while i < ArraySize(this.m_rowCells) {
      this.m_rowCells[i].SetSize(Vector2(contentW, this.RowH()));
      i += 1;
    };
    i = 0;
    while i < ArraySize(this.m_tabCells) {
      this.m_tabCells[i].SetSize(Vector2(tabW, this.RowH()));
      i += 1;
    };
    this.m_descBox.SetMargin(inkMargin(tabW, this.DescTop(), 0.0, 0.0));
    this.m_descBox.SetSize(Vector2(contentW, this.DescBoxH()));
    this.m_desc.SetWrapping(true, contentW - 56.0 - this.DescIndent());
    let resize: Bool = open && !this.m_pad && !this.IsWin();
    this.m_grip.SetVisible(resize);
    this.m_edgeRight.SetVisible(resize);
    this.m_edgeBottom.SetVisible(resize);
    this.m_grip.SetMargin(inkMargin(this.W() - 28.0, total - 28.0, 0.0, 0.0));
    this.m_edgeRight.SetMargin(inkMargin(this.W() - 8.0, this.Bar(), 0.0, 0.0));
    this.m_edgeRight.SetSize(Vector2(8.0, MaxF(0.0, total - this.Bar() - 28.0)));
    this.m_edgeBottom.SetMargin(inkMargin(tabW, total - 8.0, 0.0, 0.0));
    this.m_edgeBottom.SetSize(Vector2(MaxF(0.0, contentW - 28.0), 8.0));
    this.m_shownRows = this.Visible();
  }

  protected func DescTop() -> Float {
    return this.ListTop() + Cast<Float>(this.Visible()) * this.RowH();
  }

  protected cb func OnAttach() {
    super.OnAttach();
    this.RegisterInput();
    this.Opened();
  }

  protected func RegisterInput() -> Void {
    this.RegisterToGlobalInputCallback(n"OnPostOnPress", this, n"OnDCMPress");
    this.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnDCMRelative");
    GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnDCMKey")
      .SetLifetime(CallbackLifetime.Session);
  }

  protected func UnregisterInput() -> Void {
    this.UnregisterFromGlobalInputCallback(n"OnPostOnPress", this, n"OnDCMPress");
    this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnDCMRelative");
    GameInstance.GetCallbackSystem().UnregisterCallback(n"Input/Key", this, n"OnDCMKey");
  }

  protected func Opened() -> Void {
    let player: ref<PlayerPuppet> = this.Player();
    if IsDefined(player) {
      player.m_dcmMenuOpen = true;
      this.m_pad = !player.PlayerLastUsedKBM();
      this.Layout();
      this.PaintFooter();
      player.DCMMenuEmit("open\t" + (this.m_pad ? "1" : "0"));
    };
  }

  protected cb func OnDetach() {
    this.UnregisterInput();
    this.Closed();
    super.OnDetach();
  }

  protected func Closed() -> Void {
    let player: ref<PlayerPuppet> = this.Player();
    if IsDefined(player) {
      player.DCMSquadHide();
      player.m_dcmMenuOpen = false;
      if this.m_onLayer {
        player.m_dcmSwallow = true;
      };
      player.m_dcmMenuPos = this.m_pos;
      player.m_dcmMenuHasPos = true;
      player.m_dcmMenuCollapsed = this.m_collapsed;
      let row: ref<DCMMenuRow> = this.Selected();
      player.m_dcmMenuSelId = IsDefined(row) ? row.id : "";
      player.m_dcmMenuFirst = this.m_first;
      if player.m_dcmMenu == this {
        player.m_dcmMenu = null;
      };
      player.DCMMenuEmit("close");
    };
  }

  public func OpenSquad() -> ref<DCMSquadPopup> {
    let root: wref<inkCompoundWidget> = this.GetRootCompoundWidget();
    if !IsDefined(root) {
      return null;
    };
    let host: ref<inkCanvas> = new inkCanvas();
    host.SetName(n"DCMSquadHost");
    host.SetAnchor(inkEAnchor.Fill);
    host.Reparent(root);
    let win: ref<DCMSquadPopup> = new DCMSquadPopup();
    win.m_onLayer = true;
    win.m_layerRoot = host;
    win.m_owner = this;
    let player: ref<PlayerPuppet> = this.Player();
    if IsDefined(player) {
      player.m_dcmSquad = win;
    };
    win.Attach(host, this.GetGameController(), new inkGameNotificationData());
    return win;
  }

  protected cb func OnShown() {
    this.DeviceChanged();
  }

  protected func Player() -> ref<PlayerPuppet> {
    return GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
  }

  protected func Emit(msg: String) -> Void {
    let player: ref<PlayerPuppet> = this.Player();
    if IsDefined(player) {
      player.DCMMenuEmit(msg);
    };
  }

  protected func Now() -> Float {
    return EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGame()));
  }

  protected func Pos(evt: ref<inkPointerEvent>) -> Vector2 {
    return WidgetUtils.GlobalToLocal(this.GetRootWidget(), evt.GetScreenSpacePosition());
  }

  public func DeviceChanged() -> Void {
    let player: ref<PlayerPuppet> = this.Player();
    if !IsDefined(player) {
      return;
    };
    let pad: Bool = !player.PlayerLastUsedKBM();
    let changed: Bool = NotEquals(pad, this.m_pad);
    this.m_pad = pad;
    this.GetGameController().SetCursorContext(this.m_pad ? n"Hide" : n"Show");
    if this.m_pad {
      this.m_hover = -1;
      this.GetGameController().RequestSetFocus(null);
      if changed && StrLen(this.m_search.GetText()) > 0 && !this.HasSearchRow() {
        this.SetSearchText("");
        this.Emit("filter\t");
      };
    } else {
      this.AutoFocusSearch();
    };
    this.Layout();
    if changed {
      this.BuildSubs();
    };
    this.EnsureVisible();
    this.PaintFooter();
    if changed {
      this.Emit("device\t" + (this.m_pad ? "1" : "0"));
    };
  }

  public func IsTyping() -> Bool {
    return (this.SearchShown() && this.m_search.IsFocused()) || this.IsEditing();
  }

  protected func HasSearchRow() -> Bool {
    return StrLen(this.m_searchId) > 0;
  }

  protected func FocusSearch() -> Void {
    if this.m_pad || !IsDefined(this.m_search) || NotEquals(this.FocusWin(), this.IsWin()) {
      return;
    };
    this.GetGameController().RequestSetFocus(this.m_search.GetRootWidget());
  }

  protected func BlurSearch() -> Void {
    if IsDefined(this.m_search) && this.m_search.IsFocused() {
      this.GetGameController().RequestSetFocus(null);
    };
  }

  protected func AutoFocusSearch() -> Void {
    if this.m_searchTab {
      this.FocusSearch();
    } else {
      this.BlurSearch();
    };
  }

  protected func SetSearchText(text: String) -> Void {
    this.m_quiet = true;
    this.m_search.SetText(text);
    this.m_lastText = text;
    this.m_quiet = false;
  }

  protected cb func OnDCMSearchInput(widget: wref<inkWidget>) {
    if this.m_quiet {
      return;
    };
    if this.m_ctrl || this.CapturedLately() {
      this.SetSearchText(this.m_lastText);
      return;
    };
    let text: String = this.m_search.GetText();
    if Equals(text, this.m_lastText) {
      return;
    };
    this.m_lastText = text;
    this.m_sel = -1;
    this.m_first = 0;
    this.Emit("filter\t" + text);
  }

  protected func GrowPool(most: Int32) -> Void {
    let rowW: Float = this.ContentW();
    let k: Int32 = ArraySize(this.m_rowCells);
    while k < most {
      let cell: ref<inkCanvas> = new inkCanvas();
      cell.SetSize(Vector2(rowW, this.RowH()));
      cell.SetInteractive(true);
      cell.Reparent(this.m_list);
      let bg: ref<inkRectangle> = this.Rect(cell, new HDRColor(1.0, 1.0, 1.0, 1.0), 0.0);
      let sel: ref<inkRectangle> = this.Rect(cell, this.m_accent, 0.0);
      let icon: ref<inkText> = this.Icon(cell, 30, "");
      this.Left(icon, 14.0);
      let glyph: ref<inkText> = this.Icon(cell, 30, "");
      this.Left(glyph, 50.0);
      let label: ref<inkText> = this.Text(cell, 28);
      this.Left(label, 28.0);
      let vbox: ref<inkHorizontalPanel> = new inkHorizontalPanel();
      vbox.SetAnchor(inkEAnchor.CenterRight);
      vbox.SetAnchorPoint(Vector2(1.0, 0.5));
      vbox.SetMargin(inkMargin(0.0, 0.0, 12.0, 0.0));
      vbox.SetFitToContent(true);
      vbox.Reparent(cell);
      let star: ref<inkText> = this.Icon(vbox, 28, "");
      star.SetVAlign(inkEVerticalAlign.Center);
      let reset: ref<inkText> = this.Icon(vbox, 28, "");
      reset.SetVAlign(inkEVerticalAlign.Center);
      reset.SetMargin(inkMargin(0.0, 0.0, 10.0, 0.0));
      reset.SetInteractive(true);
      let left: ref<inkText> = this.Icon(vbox, 30, "");
      left.SetVAlign(inkEVerticalAlign.Center);
      left.SetInteractive(true);
      let value: ref<inkText> = this.Text(vbox, 28);
      value.SetVAlign(inkEVerticalAlign.Center);
      value.SetMargin(inkMargin(6.0, 0.0, 6.0, 0.0));
      let right: ref<inkText> = this.Icon(vbox, 30, "");
      right.SetVAlign(inkEVerticalAlign.Center);
      right.SetInteractive(true);
      let box: ref<inkText> = this.Icon(cell, 34, "\u{e007}");
      this.Right(box, 11.0);
      cell.RegisterToCallback(n"OnRelease", this, n"OnDCMRowClick");
      cell.RegisterToCallback(n"OnEnter", this, n"OnDCMRowEnter");
      cell.RegisterToCallback(n"OnLeave", this, n"OnDCMRowLeave");
      ArrayPush(this.m_rowCells, cell);
      ArrayPush(this.m_rowBgs, bg);
      ArrayPush(this.m_rowSel, sel);
      ArrayPush(this.m_rowIcons, icon);
      ArrayPush(this.m_rowGlyphs, glyph);
      ArrayPush(this.m_rowLabels, label);
      ArrayPush(this.m_rowValues, value);
      ArrayPush(this.m_rowLeft, left);
      ArrayPush(this.m_rowRight, right);
      ArrayPush(this.m_rowBoxes, box);
      ArrayPush(this.m_rowResets, reset);
      ArrayPush(this.m_rowStars, star);
      ArrayPush(this.m_rowCellValues, vbox);
      ArrayPush(this.m_rowValueKeys, "");
      k += 1;
    };
  }

  protected func FillValue(k: Int32, star: String, reset: String, left: String, value: String, right: String, cap: String, button: Int32, fresh: Int32) -> Void {
    let key: String = star + "|" + reset + "|" + left + "|" + value + "|" + right + "|" + cap + "|" + IntToString(button) + "|" + IntToString(fresh);
    if Equals(this.m_rowValueKeys[k], key) {
      return;
    };
    this.m_rowValueKeys[k] = key;
    let vbox: wref<inkHorizontalPanel> = this.m_rowCellValues[k];
    vbox.RemoveAllChildren();
    if fresh > 0 {
      let tag: ref<inkFlex> = new inkFlex();
      tag.SetVAlign(inkEVerticalAlign.Center);
      tag.SetMargin(inkMargin(0.0, 0.0, 12.0, 0.0));
      tag.Reparent(vbox);
      let tagBack: ref<inkRectangle> = new inkRectangle();
      tagBack.SetHAlign(inkEHorizontalAlign.Fill);
      tagBack.SetVAlign(inkEVerticalAlign.Fill);
      tagBack.SetTintColor(fresh > 1 ? new HDRColor(0.0, 0.0, 0.0, 1.0) : this.m_bright);
      tagBack.Reparent(tag);
      let tagText: ref<inkText> = this.Text(tag, 18);
      tagText.SetFontStyle(n"Semi-Bold");
      tagText.SetText(DCMUpper(this.UI(30, "New")));
      tagText.SetTintColor(fresh > 1 ? new HDRColor(1.0, 1.0, 1.0, 1.0) : new HDRColor(0.0, 0.0, 0.0, 1.0));
      tagText.SetMargin(inkMargin(8.0, 1.0, 8.0, 1.0));
      tagText.SetHAlign(inkEHorizontalAlign.Center);
      tagText.SetVAlign(inkEVerticalAlign.Center);
    };
    let starText: ref<inkText> = this.Icon(vbox, 28, star);
    starText.SetVAlign(inkEVerticalAlign.Center);
    starText.SetMargin(inkMargin(0.0, 0.0, StrLen(star) > 0 ? 12.0 : 0.0, 0.0));
    starText.SetInteractive(true);
    this.m_rowStars[k] = starText;
    if StrLen(cap) > 0 {
      let keyCap: ref<inkFlex> = new inkFlex();
      keyCap.SetVAlign(inkEVerticalAlign.Center);
      keyCap.SetMargin(inkMargin(0.0, 0.0, 12.0, 0.0));
      keyCap.Reparent(vbox);
      this.CapEdge(keyCap, inkEHorizontalAlign.Fill, inkEVerticalAlign.Top, Vector2(0.0, 2.0));
      this.CapEdge(keyCap, inkEHorizontalAlign.Fill, inkEVerticalAlign.Bottom, Vector2(0.0, 2.0));
      this.CapEdge(keyCap, inkEHorizontalAlign.Left, inkEVerticalAlign.Fill, Vector2(2.0, 0.0));
      this.CapEdge(keyCap, inkEHorizontalAlign.Right, inkEVerticalAlign.Fill, Vector2(2.0, 0.0));
      let capText: ref<inkText> = this.Text(keyCap, 22);
      capText.SetFontStyle(n"Semi-Bold");
      capText.SetText(DCMKeyLabel(cap));
      capText.SetMargin(inkMargin(10.0, 2.0, 10.0, 2.0));
      capText.SetHAlign(inkEHorizontalAlign.Center);
      capText.SetVAlign(inkEVerticalAlign.Center);
    };
    let resetText: ref<inkText> = this.Icon(vbox, 28, reset);
    resetText.SetVAlign(inkEVerticalAlign.Center);
    resetText.SetMargin(inkMargin(0.0, 0.0, 10.0, 0.0));
    resetText.SetInteractive(true);
    let leftText: ref<inkText> = this.Icon(vbox, 30, left);
    leftText.SetVAlign(inkEVerticalAlign.Center);
    leftText.SetMargin(inkMargin(0.0, 0.0, -15.5, 0.0));
    leftText.SetInteractive(true);
    let valueParent: wref<inkCompoundWidget> = vbox;
    if button > 0 {
      let frame: ref<inkFlex> = new inkFlex();
      frame.SetVAlign(inkEVerticalAlign.Center);
      frame.SetMargin(inkMargin(6.0, 0.0, 0.0, 0.0));
      frame.Reparent(vbox);
      let edge: Float = button > 1 ? 4.0 : 2.0;
      this.CapEdge(frame, inkEHorizontalAlign.Fill, inkEVerticalAlign.Top, Vector2(0.0, edge));
      this.CapEdge(frame, inkEHorizontalAlign.Fill, inkEVerticalAlign.Bottom, Vector2(0.0, edge));
      this.CapEdge(frame, inkEHorizontalAlign.Left, inkEVerticalAlign.Fill, Vector2(edge, 0.0));
      this.CapEdge(frame, inkEHorizontalAlign.Right, inkEVerticalAlign.Fill, Vector2(edge, 0.0));
      valueParent = frame;
    };
    let valueText: ref<inkText> = new inkText();
    valueText.SetFontFamily(DCMFont(), button > 0 ? n"Semi-Bold" : n"Medium");
    valueText.SetFontStyle(button > 0 ? n"Semi-Bold" : n"Medium");
    valueText.SetFontSize(button > 0 ? 24 : 28);
    valueText.SetFitToContent(true);
    valueText.SetText(button > 0 ? DCMUpper(value) : value);
    valueText.SetVAlign(inkEVerticalAlign.Center);
    valueText.SetHAlign(inkEHorizontalAlign.Center);
    valueText.SetMargin(button > 0 ? inkMargin(18.0, 4.0, 18.0, 4.0) : inkMargin(6.0, 0.0, 6.0, 0.0));
    valueText.SetInteractive(true);
    valueText.RegisterToCallback(n"OnEnter", this, n"OnDCMPartEnter");
    valueText.RegisterToCallback(n"OnLeave", this, n"OnDCMPartLeave");
    valueText.Reparent(valueParent);
    let rightText: ref<inkText> = this.Icon(vbox, 30, right);
    rightText.SetVAlign(inkEVerticalAlign.Center);
    rightText.SetInteractive(true);
    if StrLen(right) > 0 {
      rightText.SetMargin(inkMargin(4.0, 0.0, -12.0, 0.0));
    };
    this.HoverPart(resetText);
    this.HoverPart(leftText);
    this.HoverPart(rightText);
    this.m_rowResets[k] = resetText;
    this.m_rowLeft[k] = leftText;
    this.m_rowValues[k] = valueText;
    this.m_rowRight[k] = rightText;
  }

  protected func BuildTabs() -> Void {
    this.m_tabsPanel.RemoveAllChildren();
    ArrayClear(this.m_tabCells);
    ArrayClear(this.m_tabSel);
    ArrayClear(this.m_tabCounts);
    ArrayClear(this.m_tabNameTexts);
    ArrayClear(this.m_tabIconTexts);
    let t: Int32 = 0;
    while t < ArraySize(this.m_tabNames) {
      let cell: ref<inkCanvas> = new inkCanvas();
      cell.SetSize(Vector2(this.TabW(), this.RowH()));
      cell.SetInteractive(true);
      cell.Reparent(this.m_tabsPanel);
      let sel: ref<inkRectangle> = this.Rect(cell, this.m_accent, 0.0);
      let icon: ref<inkText> = this.Icon(cell, 30, this.m_tabGlyphs[t]);
      this.Left(icon, 18.0);
      let name: ref<inkText> = this.Text(cell, 28);
      name.SetFontStyle(n"Semi-Bold");
      name.SetText(this.m_tabNames[t]);
      this.Left(name, 62.0);
      let count: ref<inkText> = this.Text(cell, 24);
      this.Right(count, 16.0);
      count.SetOpacity(0.6);
      cell.RegisterToCallback(n"OnRelease", this, n"OnDCMTabClick");
      ArrayPush(this.m_tabCells, cell);
      ArrayPush(this.m_tabSel, sel);
      ArrayPush(this.m_tabCounts, count);
      ArrayPush(this.m_tabNameTexts, name);
      ArrayPush(this.m_tabIconTexts, icon);
      t += 1;
    };
  }

  protected func SubEdge(strip: ref<inkCanvas>, text: String, right: Bool) -> ref<inkFlex> {
    let cap: ref<inkFlex> = new inkFlex();
    cap.SetAnchor(right ? inkEAnchor.CenterRight : inkEAnchor.CenterLeft);
    cap.SetAnchorPoint(Vector2(right ? 1.0 : 0.0, 0.5));
    cap.SetMargin(inkMargin(right ? 0.0 : 12.0, 0.0, right ? 12.0 : 0.0, 0.0));
    cap.SetInteractive(true);
    cap.Reparent(strip);
    this.CapEdge(cap, inkEHorizontalAlign.Fill, inkEVerticalAlign.Top, Vector2(0.0, 2.0));
    this.CapEdge(cap, inkEHorizontalAlign.Fill, inkEVerticalAlign.Bottom, Vector2(0.0, 2.0));
    this.CapEdge(cap, inkEHorizontalAlign.Left, inkEVerticalAlign.Fill, Vector2(2.0, 0.0));
    this.CapEdge(cap, inkEHorizontalAlign.Right, inkEVerticalAlign.Fill, Vector2(2.0, 0.0));
    let t: ref<inkText> = this.Text(cap, 20);
    t.SetFontStyle(n"Semi-Bold");
    t.SetText(text);
    t.SetMargin(inkMargin(8.0, 2.0, 8.0, 2.0));
    t.SetHAlign(inkEHorizontalAlign.Center);
    t.SetVAlign(inkEVerticalAlign.Center);
    return cap;
  }

  protected func BuildSubs() -> Void {
    if IsDefined(this.m_subStrip) {
      this.m_subBar.RemoveChild(this.m_subStrip);
    };
    ArrayClear(this.m_subCells);
    ArrayClear(this.m_subIdx);
    if !this.HasSubs() {
      return;
    };
    let strip: ref<inkCanvas> = new inkCanvas();
    strip.SetAnchor(inkEAnchor.Fill);
    strip.Reparent(this.m_subBar);
    this.m_subStrip = strip;
    let lead: ref<inkFlex> = this.SubEdge(strip, this.m_pad ? "LT" : "Q", false);
    let tail: ref<inkFlex> = this.SubEdge(strip, this.m_pad ? "RT" : "E", true);
    lead.RegisterToCallback(n"OnRelease", this, n"OnDCMSubEdge");
    tail.RegisterToCallback(n"OnRelease", this, n"OnDCMSubEdge");
    this.m_subLead = lead;
    this.m_subTail = tail;
    let n: Int32 = ArraySize(this.m_subNames);
    let labels: array<String>;
    let widths: array<Float>;
    let i: Int32 = 0;
    while i < n {
      let count: String = i < ArraySize(this.m_subCountText) ? this.m_subCountText[i] : "";
      let label: String = DCMUpper(this.m_subNames[i]) + (StrLen(count) > 0 ? "  " + count : "");
      ArrayPush(labels, label);
      ArrayPush(widths, DCMTextW(label, 22.0) + 28.0);
      i += 1;
    };
    let left: Float = 38.0 + DCMTextW(this.m_pad ? "LT" : "Q", 20.0);
    let right: Float = this.ContentW() - 38.0 - DCMTextW(this.m_pad ? "RT" : "E", 20.0);
    let partial: Float = 96.0;
    let sel: Int32 = Clamp(this.m_sub, 0, n - 1);
    let first: Int32 = 0;
    let found: Bool = false;
    while first < sel && !found {
      let used: Float = (first > 0 ? partial : 0.0) + (sel < n - 1 ? partial : 0.0);
      i = first;
      while i <= sel {
        used += widths[i];
        i += 1;
      };
      if used <= right - left {
        found = true;
      } else {
        first += 1;
      };
    };
    let x: Float = left;
    if first > 0 {
      this.SubCell(strip, first - 1, labels[first - 1], x, partial);
      x += partial;
    };
    i = first;
    while i < n && x < right - 1.0 {
      let room: Float = right - x;
      if widths[i] <= room - (i < n - 1 ? partial : 0.0) || (i == sel && widths[i] <= room) {
        this.SubCell(strip, i, labels[i], x, widths[i]);
        x += widths[i];
      } else {
        this.SubCell(strip, i, labels[i], x, room);
        x = right;
      };
      i += 1;
    };
  }

  protected func SubCell(strip: ref<inkCanvas>, index: Int32, label: String, x: Float, width: Float) -> Void {
    let cell: ref<inkCanvas> = new inkCanvas();
    cell.SetAnchor(inkEAnchor.TopLeft);
    cell.SetMargin(inkMargin(x, 6.0, 0.0, 0.0));
    cell.SetSize(Vector2(width - 4.0, this.SubH() - 12.0));
    cell.SetInteractive(true);
    cell.Reparent(strip);
    this.Rect(cell, this.m_accent, index == this.m_sub ? 0.3 : 0.0);
    let name: ref<inkText> = this.Text(cell, 22);
    name.SetFontStyle(index == this.m_sub ? n"Semi-Bold" : n"Medium");
    name.SetText(DCMFitW(label, width - 28.0, 22.0));
    name.SetOpacity(index == this.m_sub ? 1.0 : 0.6);
    name.SetAnchor(inkEAnchor.Centered);
    name.SetAnchorPoint(Vector2(0.5, 0.5));
    cell.RegisterToCallback(n"OnRelease", this, n"OnDCMSubClick");
    ArrayPush(this.m_subCells, cell);
    ArrayPush(this.m_subIdx, index);
  }

  public func Load(payload: String) -> Int32 {
    let keepId: String = "";
    if this.m_sel >= 0 && this.m_sel < ArraySize(this.m_rows) {
      keepId = this.m_rows[this.m_sel].id;
    };
    let oldTab: Int32 = this.m_tab;
    let oldSub: Int32 = this.m_sub;
    let oldTabs: String = "";
    let t: Int32 = 0;
    while t < ArraySize(this.m_tabNames) {
      oldTabs = oldTabs + this.m_tabNames[t] + "|" + this.m_tabGlyphs[t] + "\n";
      t += 1;
    };
    let oldSubs: String = "";
    t = 0;
    while t < ArraySize(this.m_subNames) {
      oldSubs = oldSubs + this.m_subNames[t] + "|" + this.m_subCountText[t] + "\n";
      t += 1;
    };
    let wasLoaded: Bool = this.m_loaded;
    let oldSearch: String = this.m_searchId;
    let uiChanged: Bool = false;
    let hadSubs: Bool = this.HasSubs();
    let hadCard: Bool = this.m_hasCard;
    this.m_hasCard = false;
    let hadPhoto: Bool = this.m_hasPhoto;
    this.m_hasPhoto = false;
    let searchValue: String = "";
    let searchHint: String = "";
    let focusId: String = "";
    let hadDesc: Bool = this.m_descOff;
    let hadHints: Bool = this.m_hintsOff;
    let hadSize: Vector2 = Vector2(this.m_extraW, this.m_extraH);
    ArrayClear(this.m_rows);
    ArrayClear(this.m_tabNames);
    ArrayClear(this.m_tabGlyphs);
    ArrayClear(this.m_tabCountText);
    ArrayClear(this.m_subNames);
    ArrayClear(this.m_subCountText);
    this.m_searchId = "";
    this.m_footNote = "";
    let lines: array<String> = StrSplit(payload, "\n");
    let i: Int32 = 0;
    while i < ArraySize(lines) {
      let f: array<String> = StrSplit(lines[i], "\t");
      let tag: String = DCMField(f, 0);
      if Equals(tag, "R") {
        let row: ref<DCMMenuRow> = new DCMMenuRow();
        row.kind = DCMField(f, 1);
        row.id = DCMField(f, 2);
        row.label = DCMField(f, 3);
        row.value = DCMField(f, 4);
        row.rank = StringToInt(DCMField(f, 5));
        row.glyph = DCMField(f, 6);
        row.desc = DCMField(f, 7);
        row.changed = Equals(DCMField(f, 8), "1");
        row.key = DCMField(f, 9);
        row.flags = DCMField(f, 10);
        row.brand = DCMField(f, 11);
        row.raw = DCMField(f, 12);
        row.pic = DCMField(f, 13);
        row.tint = DCMField(f, 14);
        ArrayPush(this.m_rows, row);
      } else {
        if Equals(tag, "B") {
          ArrayPush(this.m_tabNames, DCMField(f, 1));
          ArrayPush(this.m_tabGlyphs, DCMField(f, 2));
          ArrayPush(this.m_tabCountText, DCMField(f, 3));
        } else {
          if Equals(tag, "S") {
            ArrayPush(this.m_subNames, DCMField(f, 1));
            ArrayPush(this.m_subCountText, DCMField(f, 2));
          } else {
            if Equals(tag, "T") {
              this.m_tab = StringToInt(DCMField(f, 1));
              this.m_sub = StringToInt(DCMField(f, 2));
              this.m_searchId = DCMField(f, 3);
              searchValue = DCMField(f, 4);
              searchHint = DCMField(f, 5);
              this.m_searchTab = Equals(DCMField(f, 6), "1");
              focusId = DCMField(f, 7);
            } else {
              if Equals(tag, "C") {
                this.m_accent = DCMColor(DCMField(f, 1));
                this.m_bright = DCMColor(DCMField(f, 2));
                this.m_selColor = DCMColor(DCMField(f, 3));
                this.m_selAlpha = StringToFloat(DCMField(f, 4));
                this.m_hasSelInk = StrLen(DCMField(f, 5)) > 0;
                if this.m_hasSelInk {
                  this.m_selInk = DCMColor(DCMField(f, 5));
                };
                this.ApplyPalette(DCMColor(DCMField(f, 6)), StringToFloat(DCMField(f, 7)), DCMColor(DCMField(f, 8)),
                  StringToFloat(DCMField(f, 9)), DCMColor(DCMField(f, 10)), StringToFloat(DCMField(f, 11)));
              } else {
                if Equals(tag, "F") {
                  this.m_footNote = DCMField(f, 1);
                } else {
                  if Equals(tag, "P") {
                    this.m_descOff = Equals(DCMField(f, 4), "0");
                    this.m_hintsOff = Equals(DCMField(f, 5), "0");
                    if !this.IsWin() && this.m_resizing == 0 {
                      this.m_extraW = MaxF(0.0, StringToFloat(DCMField(f, 6)));
                      this.m_extraH = MaxF(0.0, StringToFloat(DCMField(f, 7)));
                    };
                    this.Place(DCMField(f, 1), DCMField(f, 2), StringToFloat(DCMField(f, 3)));
                  } else {
                    if Equals(tag, "K") {
                      this.m_hasCard = true;
                      this.FillCard(f);
                    } else {
                      if Equals(tag, "H") && !Equals(lines[i], this.m_uiKey) {
                        this.m_uiKey = lines[i];
                        this.m_ui = f;
                        uiChanged = true;
                      };
                      if Equals(tag, "I") {
                        this.m_hasPhoto = true;
                        this.FillPhoto(f);
                      };
                      if Equals(tag, "G") {
                        this.m_starOn = DCMField(f, 1);
                        this.m_starOff = DCMField(f, 2);
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
      i += 1;
    };
    let newTabs: String = "";
    t = 0;
    while t < ArraySize(this.m_tabNames) {
      newTabs = newTabs + this.m_tabNames[t] + "|" + this.m_tabGlyphs[t] + "\n";
      t += 1;
    };
    if !Equals(newTabs, oldTabs) {
      this.BuildTabs();
    };
    let newSubs: String = "";
    t = 0;
    while t < ArraySize(this.m_subNames) {
      newSubs = newSubs + this.m_subNames[t] + "|" + this.m_subCountText[t] + "\n";
      t += 1;
    };
    let moved: Bool = !wasLoaded || this.m_tab != oldTab || this.m_sub != oldSub;
    if moved || !Equals(newSubs, oldSubs) {
      this.BuildSubs();
    };
    let tabW: Float = this.IsWin() ? 0.0 : this.FitTabW();
    let widthChanged: Bool = AbsF(tabW - this.m_tabW) > 0.5;
    this.m_tabW = tabW;
    if NotEquals(hadSubs, this.HasSubs()) || NotEquals(hadCard, this.m_hasCard) || NotEquals(hadPhoto, this.m_hasPhoto) || NotEquals(hadDesc, this.m_descOff)
      || NotEquals(hadHints, this.m_hintsOff) || widthChanged || hadSize.X != this.m_extraW || hadSize.Y != this.m_extraH {
      this.Layout();
    };
    if uiChanged {
      this.BuildHelp();
      this.Layout();
      this.PaintFooter();
    };
    this.m_search.SetDefaultText(DCMFitW(StrLen(searchHint) > 0 ? searchHint : this.UI(7, "Ctrl+F or click to filter"), this.ContentW() - 64.0, 28.0));
    if moved || !Equals(oldSearch, this.m_searchId) {
      this.SetSearchText(this.HasSearchRow() ? searchValue : "");
      if !moved && this.HasSearchRow() {
        this.FocusSearch();
      } else {
        this.AutoFocusSearch();
      };
    };
    this.m_search.SetAccent(this.m_accent);
    this.m_loaded = true;
    let restoring: Bool = !wasLoaded && StrLen(this.m_restoreId) > 0;
    if restoring {
      keepId = this.m_restoreId;
      this.Layout();
    };
    let found: Int32 = -1;
    if (!moved || restoring) && StrLen(keepId) > 0 {
      i = 0;
      while i < ArraySize(this.m_rows) && found < 0 {
        if Equals(this.m_rows[i].id, keepId) && this.m_rows[i].IsSelectable() {
          found = i;
        };
        i += 1;
      };
    };
    if found >= 0 {
      this.m_sel = found;
      if restoring {
        this.m_first = this.m_restoreFirst;
        this.EnsureVisible();
      } else {
        this.Paint();
      };
    } else {
      if moved {
        this.m_first = 0;
      };
      this.m_sel = this.FirstSelectable();
      this.EnsureVisible();
    };
    if StrLen(focusId) > 0 {
      i = 0;
      while i < ArraySize(this.m_rows) {
        if Equals(this.m_rows[i].id, focusId) && this.m_rows[i].IsSelectable() {
          this.m_sel = i;
          this.m_zone = 0;
          this.m_first = i - this.Visible() / 2;
          this.ClampFirst();
          this.Paint();
          i = ArraySize(this.m_rows);
        };
        i += 1;
      };
    };
    return ArraySize(this.m_rows);
  }

  protected func ApplyPalette(row: HDRColor, rowAlpha: Float, tabs: HDRColor, tabsAlpha: Float, bar: HDRColor, barAlpha: Float) -> Void {
    if this.m_onLayer {
      rowAlpha = 1.0;
    };
    this.m_back.SetTintColor(row);
    this.m_back.SetOpacity(rowAlpha);
    this.m_tabsBack.SetTintColor(tabs);
    this.m_tabsBack.SetOpacity(DCMOver(tabsAlpha, rowAlpha));
    this.m_barBack.SetTintColor(bar);
    this.m_barBack.SetOpacity(DCMOver(barAlpha, rowAlpha));
    this.m_footBack.SetTintColor(bar);
    this.m_footBack.SetOpacity(DCMOver(barAlpha, rowAlpha));
    this.m_descBack.SetTintColor(bar);
    this.m_descBack.SetOpacity(DCMOver(barAlpha, rowAlpha));
    this.m_descTint.SetTintColor(this.m_accent);
  }

  protected func Place(x: String, y: String, scale: Float) -> Void {
    let key: String = x + "|" + y + "|" + FloatToString(scale);
    if this.m_dragging || Equals(key, this.m_placeKey) {
      return;
    };
    this.m_placeKey = key;
    this.m_pos = StrLen(x) > 0 ? Vector2(StringToFloat(x), StringToFloat(y)) : this.HomePos();
    let s: Float = scale > 0.0 ? scale : 1.0;
    this.m_menuScale = s;
    if this.m_pos.Y + this.H() * s > 2160.0 {
      this.m_pos.Y = MaxF(0.0, 2160.0 - this.H() * s);
    };
    let pillar: Float = this.Pillar();
    if pillar > 0.0 {
      let right: Float = DCMScreenWidth(this.GetGame()) - pillar - this.W() * s;
      this.m_pos.X = ClampF(this.m_pos.X, pillar, MaxF(pillar, right));
    };
    this.m_container.SetMargin(inkMargin(this.m_pos.X, this.m_pos.Y, 0.0, 0.0));
    this.m_container.SetRenderTransformPivot(Vector2(0.0, 0.0));
    this.m_container.SetScale(Vector2(s, s));
  }

  public func IsCapturing() -> Bool {
    return this.m_capture;
  }

  protected func PadCapture(id: String) -> Bool {
    return Equals(id, "padcombo") || StrBeginsWith(id, "pc|");
  }

  protected func Captures(id: String) -> Bool {
    return this.PadCapture(id) || Equals(id, "menukey") || StrBeginsWith(id, "hk|");
  }

  protected func CapturedLately() -> Bool {
    return this.m_capture || this.Now() - this.m_capEnd < 0.3;
  }

  protected func StartCapture(id: String) -> Void {
    this.m_capture = true;
    this.m_capId = id;
    this.m_capAt = this.Now();
    this.m_capHeld = 0;
    ArrayClear(this.m_capKeys);
    this.Paint();
  }

  protected func StopCapture(save: Bool) -> Void {
    this.m_capture = false;
    this.m_capEnd = this.Now();
    if save && ArraySize(this.m_capKeys) > 0 {
      if Equals(this.m_capId, "padcombo") {
        this.Emit("padcombo\t" + DCMComboText(this.m_capKeys));
      } else {
        this.Emit("padset\t" + this.m_capId + "\t" + DCMComboText(this.m_capKeys));
      };
    } else {
      this.Paint();
    };
  }

  protected func CaptureKey(key: EInputKey, act: EInputAction) -> Void {
    if Equals(key, EInputKey.IK_Escape) {
      if Equals(act, EInputAction.IACT_Press) {
        this.StopCapture(false);
      };
      return;
    };
    if !this.PadCapture(this.m_capId) {
      let id: String = DCMKeyId(key);
      if !Equals(act, EInputAction.IACT_Press) || this.Now() - this.m_capAt <= 0.25 || !DCMIsKeyboard(id) {
        return;
      };
      this.m_capture = false;
      this.m_capEnd = this.Now();
      if Equals(key, EInputKey.IK_Backspace) {
        this.Emit("hkclear\t" + this.m_capId);
      } else {
        this.Emit("hkset\t" + this.m_capId + "\t" + id);
      };
      this.Paint();
      return;
    };
    if DCMPadIndex(key) < 0 {
      return;
    };
    if Equals(act, EInputAction.IACT_Press) && this.Now() - this.m_capAt > 0.25 && !ArrayContains(this.m_capKeys, key) {
      ArrayPush(this.m_capKeys, key);
      this.m_capHeld += 1;
      this.Paint();
      return;
    };
    if Equals(act, EInputAction.IACT_Release) && ArrayContains(this.m_capKeys, key) {
      this.m_capHeld -= 1;
      if this.m_capHeld <= 0 {
        this.StopCapture(true);
      };
    };
  }

  protected func FirstSelectable() -> Int32 {
    let i: Int32 = 0;
    while i < ArraySize(this.m_rows) {
      if this.m_rows[i].IsOption() {
        return i;
      };
      i += 1;
    };
    i = 0;
    while i < ArraySize(this.m_rows) {
      if this.m_rows[i].IsSelectable() {
        return i;
      };
      i += 1;
    };
    return -1;
  }

  protected func Selected() -> ref<DCMMenuRow> {
    if this.m_sel < 0 || this.m_sel >= ArraySize(this.m_rows) {
      return null;
    };
    return this.m_rows[this.m_sel];
  }

  protected func ValueText(row: ref<DCMMenuRow>) -> String {
    let v: String = row.value;
    if Equals(v, "!") {
      return "";
    };
    if StrLen(v) > 1 && (StrBeginsWith(v, "!") || StrBeginsWith(v, "*")) {
      v = StrMid(v, 1, StrLen(v) - 1);
    };
    return v;
  }

  protected func ValueColor(row: ref<DCMMenuRow>) -> HDRColor {
    if StrBeginsWith(row.value, "!") || Equals(row.kind, "warn") {
      return new HDRColor(1.0, 0.62, 0.2, 1.0);
    };
    if StrLen(row.value) > 1 && StrBeginsWith(row.value, "*") {
      return new HDRColor(0.3, 0.85, 0.35, 1.0);
    };
    return new HDRColor(1.0, 1.0, 1.0, 1.0);
  }

  protected func RankColor(rank: Int32) -> HDRColor {
    if rank >= 10 {
      return new HDRColor(1.0, 0.6, 0.2, 1.0);
    };
    if rank >= 8 {
      return new HDRColor(0.75, 0.45, 0.95, 1.0);
    };
    if rank >= 6 {
      return new HDRColor(0.35, 0.62, 1.0, 1.0);
    };
    if rank >= 4 {
      return new HDRColor(0.45, 0.85, 0.45, 1.0);
    };
    return new HDRColor(1.0, 1.0, 1.0, 1.0);
  }

  protected func Paint() -> Void {
    this.ClampFirst();
    let visible: Int32 = this.Visible();
    let k: Int32 = 0;
    while k < ArraySize(this.m_rowCells) {
      let idx: Int32 = this.m_first + k;
      if k >= visible || idx >= ArraySize(this.m_rows) {
        this.m_rowCells[k].SetVisible(false);
      } else {
        let row: ref<DCMMenuRow> = this.m_rows[idx];
        let head: Bool = row.IsHead();
        let plain: Bool = Equals(row.kind, "dim") || Equals(row.kind, "warn");
        this.m_rowCells[k].SetVisible(true);
        let brand: Bool = StrLen(row.brand) > 0;
        this.m_rowBgs[k].SetTintColor(head ? new HDRColor(0.0, 0.0, 0.0, 1.0) : (brand ? DCMColor(row.brand) : new HDRColor(1.0, 1.0, 1.0, 1.0)));
        this.m_rowBgs[k].SetOpacity(head ? 0.5 : (brand ? 1.0 : (idx % 2 == 0 ? 0.0 : 0.035)));
        let shownLabel: String = head ? DCMUpper(row.label) : row.label;
        let valueMost: Int32 = -1;
        if !Equals(row.kind, "dim") && !Equals(row.kind, "warn") {
          let used: Int32 = row.IsSwitch() ? 3 : UTF8StrLen(this.ValueText(row)) + (row.IsStepper() ? 5 : 0) + (row.changed ? 2 : 0);
          if row.Has("w") {
            used += 5;
          };
          if StrLen(row.value) == 0 && !row.IsSwitch() {
            used = 2;
          };
          if StrLen(row.key) > 0 && !this.m_pad {
            used += UTF8StrLen(DCMKeyLabel(row.key)) + 3;
          };
          if row.Has("s") {
            used += 3;
          };
          if row.Has("x") {
            used += 3;
          };
          let start: Float = head ? 90.0 : 46.0;
          let perChar: Float = head ? 16.0 : 13.5;
          let room: Int32 = Cast<Int32>((this.ContentW() - start - 24.0) / perChar) - used - 1;
          let keep: Int32 = Min(12, UTF8StrLen(shownLabel));
          if room < keep && !row.IsSwitch() && StrLen(this.ValueText(row)) > 0 {
            valueMost = Max(4, UTF8StrLen(this.ValueText(row)) - (keep - room));
            room = keep;
          };
          shownLabel = head ? DCMFitW(shownLabel, this.ContentW() - start - 24.0 - Cast<Float>(used + 1) * perChar, 28.0)
            : DCMFit(shownLabel, room);
        };
        this.m_rowLabels[k].SetText(shownLabel);
        let labelColor: HDRColor = head ? this.m_bright : this.RankColor(row.rank);
        if Equals(row.kind, "warn") {
          labelColor = new HDRColor(1.0, 0.62, 0.2, 1.0);
        };
        this.m_rowLabels[k].SetTintColor(labelColor);
        this.m_rowLabels[k].SetOpacity(Equals(row.kind, "dim") ? 0.6 : 1.0);
        this.m_rowLabels[k].SetFontStyle(head ? n"Semi-Bold" : n"Medium");
        let glyph: Bool = head && StrLen(row.glyph) > 0;
        let dot: Bool = !head && row.rank > 0;
        this.m_rowLabels[k].SetMargin(inkMargin(head ? (glyph ? 90.0 : 54.0) : (dot ? 46.0 : 28.0), 0.0, 0.0, 0.0));
        this.m_rowIcons[k].SetVisible(head || dot);
        if dot {
          this.m_rowIcons[k].SetText("\u{e00a}");
          this.m_rowIcons[k].SetTintColor(this.RankColor(row.rank));
        };
        this.m_rowGlyphs[k].SetVisible(glyph);
        if head {
          this.m_rowIcons[k].SetText(row.IsOpen() ? "\u{e000}" : "\u{e001}");
          this.m_rowIcons[k].SetTintColor(this.m_bright);
        };
        if glyph {
          this.m_rowGlyphs[k].SetText(row.glyph);
          this.m_rowGlyphs[k].SetTintColor(this.m_bright);
        };
        let alpha: Float = 0.0;
        if idx == this.m_sel {
          alpha = this.m_zone == 0 ? this.m_selAlpha : this.m_selAlpha * 0.4;
        } else {
          if idx == this.m_hover && row.IsSelectable() {
            alpha = this.m_selAlpha * 0.4;
          };
        };
        this.m_rowSel[k].SetTintColor(this.m_selColor);
        this.m_rowSel[k].SetOpacity(alpha);
        let on: Bool = row.IsSwitch() && Equals(row.value, "1");
        let stepper: Bool = row.IsStepper();
        this.m_rowBoxes[k].SetVisible(row.IsSwitch());
        this.m_rowCellValues[k].SetMargin(inkMargin(0.0, 0.0, row.IsSwitch() ? 62.0 : 12.0, 0.0));
        this.m_rowBoxes[k].SetText(on ? "\u{e008}" : "\u{e007}");
        this.m_rowBoxes[k].SetTintColor(on ? this.m_bright : new HDRColor(1.0, 1.0, 1.0, 1.0));
        this.m_rowBoxes[k].SetOpacity(on ? 1.0 : 0.6);
        let arrow: Bool = !stepper && !row.IsSwitch() && !plain && !head && StrLen(row.value) == 0;
        let value: String = row.IsSwitch() ? "" : (head ? row.GroupSize() : this.ValueText(row));
        let cap: String = this.m_pad ? "" : row.key;
        if Equals(row.kind, "key") && StrLen(row.key) > 0 {
          value = "";
        };
        if valueMost > 0 {
          value = DCMFit(value, valueMost);
        };
        if this.m_capture && Equals(row.id, this.m_capId) {
          cap = "";
          value = this.PadCapture(row.id) && ArraySize(this.m_capKeys) > 0 ? DCMComboText(this.m_capKeys) : "\u{2026}";
        };
        let fav: Bool = row.Has("f");
        let starShown: Bool = fav || (row.Has("s") && !this.m_pad && (idx == this.m_sel || idx == this.m_hover));
        let star: String = starShown ? (fav ? this.m_starOn : this.m_starOff) : "";
        let button: Int32 = row.Has("x") ? (idx == this.m_sel && this.m_zone == 0 ? 2 : 1) : 0;
        let fresh: Int32 = row.Has("w") ? (this.m_hasSelInk && idx == this.m_sel && this.m_zone == 0 ? 2 : 1) : 0;
        this.FillValue(k, star, stepper && row.changed ? "\u{e006}" : "", stepper ? "\u{e009}" : "", value, stepper || arrow ? "\u{e001}" : "", cap, button, fresh);
        this.m_rowStars[k].SetTintColor(fav ? this.m_bright : new HDRColor(1.0, 1.0, 1.0, 1.0));
        this.m_rowStars[k].SetOpacity(fav ? 1.0 : 0.5);
        this.m_rowResets[k].SetTintColor(this.m_bright);
        this.m_rowRight[k].SetOpacity(arrow ? 0.4 : 1.0);
        this.m_rowLeft[k].SetTintColor(this.m_bright);
        this.m_rowRight[k].SetTintColor(arrow ? new HDRColor(1.0, 1.0, 1.0, 1.0) : this.m_bright);
        this.m_rowValues[k].SetTintColor(this.ValueColor(row));
        this.m_rowValues[k].SetOpacity(plain || head ? 0.6 : 1.0);
        if StrLen(row.tint) > 0 {
          this.m_rowValues[k].SetTintColor(DCMColor(row.tint));
          this.m_rowValues[k].SetOpacity(1.0);
        };
        if this.m_hasSelInk && idx == this.m_sel && this.m_zone == 0 {
          this.m_rowLabels[k].SetFontStyle(n"Semi-Bold");
          this.m_rowLabels[k].SetTintColor(this.m_selInk);
          this.m_rowIcons[k].SetTintColor(this.m_selInk);
          this.m_rowGlyphs[k].SetTintColor(this.m_selInk);
          this.m_rowBoxes[k].SetTintColor(this.m_selInk);
          this.m_rowValues[k].SetTintColor(this.m_selInk);
          this.m_rowLeft[k].SetTintColor(this.m_selInk);
          this.m_rowRight[k].SetTintColor(this.m_selInk);
          this.m_rowResets[k].SetTintColor(this.m_selInk);
        };
        if brand {
          this.m_rowLabels[k].SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
          this.m_rowLabels[k].SetFontStyle(n"Semi-Bold");
          this.m_rowRight[k].SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
        };
        this.PaintPart(this.m_rowResets[k], stepper && row.changed);
        this.PaintPart(this.m_rowLeft[k], stepper);
        this.PaintPart(this.m_rowRight[k], stepper);
      };
      k += 1;
    };
    let picked: ref<DCMMenuRow> = this.Selected();
    if IsDefined(picked) && picked.Has("w") && this.m_zone == 0 && !this.m_collapsed && !Equals(picked.id, this.m_seenId) {
      this.m_seenId = picked.id;
      this.Emit("seen\t" + picked.id);
    };
    this.PaintHeader();
    this.PaintDesc();
    if !Equals(this.FootKey(), this.m_footKey) {
      this.PaintFooter();
    };
  }

  protected func PaintHeader() -> Void {
    let pos: Int32 = 0;
    let total: Int32 = 0;
    let i: Int32 = 0;
    while i < ArraySize(this.m_rows) {
      if this.m_rows[i].IsSelectable() {
        total += 1;
        if i <= this.m_sel {
          pos += 1;
        };
      };
      i += 1;
    };
    let t: Int32 = 0;
    while t < ArraySize(this.m_tabSel) {
      let active: Bool = t == this.m_tab;
      let full: Bool = active && this.m_zone == 1;
      let inked: Bool = full && this.m_hasSelInk;
      if this.m_hasSelInk {
        this.m_tabSel[t].SetTintColor(full ? this.m_selColor : this.m_accent);
        this.m_tabSel[t].SetOpacity(full ? this.m_selAlpha : (active ? 0.18 : 0.0));
      } else {
        this.m_tabSel[t].SetTintColor(this.m_selColor);
        this.m_tabSel[t].SetOpacity(active ? (full ? 0.35 : 0.18) : 0.0);
      };
      let ink: HDRColor = inked ? this.m_selInk : new HDRColor(1.0, 1.0, 1.0, 1.0);
      this.m_tabNameTexts[t].SetTintColor(ink);
      this.m_tabIconTexts[t].SetTintColor(ink);
      this.m_tabCounts[t].SetTintColor(ink);
      this.m_tabCounts[t].SetText(this.m_tabCountText[t]);
      t += 1;
    };
    let crumb: String = this.m_collapsed ? "DRONE" : "DRONE COMPANION";
    if this.m_tab >= 0 && this.m_tab < ArraySize(this.m_tabNames) {
      crumb = crumb + "  \u{00bb}  " + DCMUpper(this.m_tabNames[this.m_tab]);
    };
    this.m_counter.SetVisible(!this.m_collapsed);
    if !this.m_collapsed && this.m_sub >= 0 && this.m_sub < ArraySize(this.m_subNames) {
      crumb = crumb + "  \u{00bb}  " + DCMUpper(this.m_subNames[this.m_sub]);
    };
    this.m_title.SetText(crumb);
    this.m_counter.SetText(total > 0 ? IntToString(pos) + " / " + IntToString(total) : "");
  }

  protected func WrapLines(text: String, room: Float) -> Int32 {
    if StrLen(text) == 0 {
      return 0;
    };
    let parts: array<String> = StrSplit(text, "\n");
    if ArraySize(parts) > 1 {
      let total: Int32 = 0;
      let p: Int32 = 0;
      while p < ArraySize(parts) {
        total += Max(1, this.WrapLines(parts[p], room));
        p += 1;
      };
      return total;
    };
    let words: array<String> = StrSplit(text, " ");
    let space: Float = DCMTextW(" ", 22.0);
    let lines: Int32 = 1;
    let used: Float = 0.0;
    let i: Int32 = 0;
    while i < ArraySize(words) {
      let w: Float = DCMTextW(words[i], 22.0);
      let gap: Float = used > 0.0 ? space : 0.0;
      if w > room {
        let total: Float = used + gap + w;
        let extra: Int32 = Cast<Int32>(total / room);
        lines += extra;
        used = total - Cast<Float>(extra) * room;
      } else {
        if used > 0.0 && used + gap + w > room {
          lines += 1;
          used = w;
        } else {
          used += gap + w;
        };
      };
      i += 1;
    };
    return lines;
  }

  protected func DescText(text: String) -> String {
    let room: Float = this.ContentW() - 64.0 - this.DescIndent();
    if this.WrapLines(text, room) <= 8 {
      this.SetDescLines(this.WrapLines(text, room));
      return text;
    };
    let lo: Int32 = 1;
    let hi: Int32 = UTF8StrLen(text);
    while lo < hi {
      let mid: Int32 = (lo + hi + 1) / 2;
      if this.WrapLines(UTF8StrLeft(text, mid) + "\u{2026}", room) <= 8 {
        lo = mid;
      } else {
        hi = mid - 1;
      };
    };
    this.SetDescLines(8);
    return UTF8StrLeft(text, lo) + "\u{2026}";
  }

  protected func Relayout() -> Void {
    let before: Int32 = this.m_shownRows;
    this.Layout();
    if this.m_shownRows != before {
      this.EnsureVisible();
    };
  }

  protected func SetDescLines(n: Int32) -> Void {
    if n != this.m_descLines {
      this.m_descLines = n;
      this.Relayout();
    };
  }

  protected func PaintDesc() -> Void {
    let row: ref<DCMMenuRow> = this.Selected();
    if !this.m_pad && this.m_hover >= this.m_first && this.m_hover < this.m_first + this.Visible() && this.m_hover < ArraySize(this.m_rows)
      && this.m_rows[this.m_hover].IsSelectable() {
      row = this.m_rows[this.m_hover];
    };
    let picOn: Bool = IsDefined(row) && StrLen(row.pic) > 0;
    if picOn {
      this.m_descPic.SetTexturePart(StringToName(row.pic));
    };
    this.m_descPic.SetVisible(picOn);
    let x: Float = picOn ? 140.0 : 28.0;
    this.m_descTitle.SetMargin(inkMargin(x, 8.0, 0.0, 0.0));
    this.m_desc.SetMargin(inkMargin(x, 40.0, 0.0, 0.0));
    if NotEquals(picOn, this.m_descPicOn) {
      this.m_descPicOn = picOn;
      this.m_desc.SetWrapping(true, this.ContentW() - 56.0 - this.DescIndent());
      this.Relayout();
    };
    if !IsDefined(row) {
      this.m_descTitle.SetText("");
      this.m_desc.SetText(this.DescText(this.m_footNote));
      return;
    };
    this.m_descTitle.SetText(DCMUpper(row.label));
    this.m_desc.SetText(this.DescText(StrReplaceAll(StrLen(row.desc) > 0 ? row.desc : this.m_footNote, "\u{00b6}", "\n")));
  }

  protected func FootKey() -> String {
    let row: ref<DCMMenuRow> = this.Selected();
    let flags: String = IsDefined(row) && this.m_zone == 0 ? row.flags : "";
    return (this.m_pad ? "p" : "k") + flags + this.m_uiKey + FloatToString(this.W());
  }

  protected func PaintFooter() -> Void {
    if !IsDefined(this.m_footPanel) {
      return;
    };
    this.m_footKey = this.FootKey();
    this.m_footPanel.RemoveAllChildren();
    let row: ref<DCMMenuRow> = this.Selected();
    let flags: String = IsDefined(row) && this.m_zone == 0 ? row.flags : "";
    let keys: array<String>;
    let labels: array<String>;
    let icons: array<Bool>;
    if StrFindFirst(flags, "s") >= 0 {
      ArrayPush(keys, this.m_pad ? "Start" : "F");
      ArrayPush(labels, this.UI(21, "Favorite"));
      ArrayPush(icons, false);
    };
    if !this.m_pad && StrFindFirst(flags, "t") >= 0 {
      ArrayPush(keys, "Enter");
      ArrayPush(labels, this.UI(22, "Type"));
      ArrayPush(icons, false);
    };
    if !this.m_pad && StrFindFirst(flags, "g") >= 0 {
      ArrayPush(keys, "G");
      ArrayPush(labels, this.UI(27, "Go to"));
      ArrayPush(icons, false);
    };
    if !this.m_pad && StrFindFirst(flags, "n") >= 0 {
      ArrayPush(keys, "F2");
      ArrayPush(labels, this.UI(23, "Rename"));
      ArrayPush(icons, false);
    };
    let owner: ref<PlayerPuppet> = this.Player();
    ArrayPush(keys, this.m_pad ? "Select" : "F1");
    ArrayPush(labels, this.UI(4, "Help"));
    ArrayPush(icons, false);
    if !this.m_pad {
      ArrayPush(keys, IsDefined(owner) ? DCMKeyLabel(owner.DCMMenuKey()) : "F8");
      ArrayPush(labels, this.UI(6, "Close"));
      ArrayPush(icons, false);
    };
    ArrayPush(keys, this.m_pad ? "Y" : "Tab");
    ArrayPush(labels, this.UI(3, "Collapse"));
    ArrayPush(icons, false);
    ArrayPush(keys, "\u{e005}");
    ArrayPush(labels, this.UI(2, "Value"));
    ArrayPush(icons, true);
    ArrayPush(keys, this.m_pad ? "A" : "Enter");
    ArrayPush(labels, this.UI(1, "Select"));
    ArrayPush(icons, false);
    ArrayPush(keys, this.m_pad ? "B" : "Esc");
    ArrayPush(labels, this.UI(5, "Back"));
    ArrayPush(icons, false);
    let room: Float = this.W() - 64.0;
    let i: Int32 = 0;
    while i < ArraySize(keys) {
      let w: Float = (icons[i] ? 28.0 : DCMTextW(keys[i], 22.0)) + 20.0 + 8.0 + DCMTextW(labels[i], 22.0) + 22.0;
      if w <= room {
        room -= w;
        this.Hint(keys[i], labels[i], icons[i]);
      } else {
        room = -1.0;
      };
      i += 1;
    };
  }

  protected func CapEdge(cap: wref<inkCompoundWidget>, h: inkEHorizontalAlign, v: inkEVerticalAlign, size: Vector2) -> Void {
    let edge: ref<inkRectangle> = new inkRectangle();
    edge.SetHAlign(h);
    edge.SetVAlign(v);
    edge.SetSize(size);
    edge.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
    edge.SetOpacity(0.55);
    edge.Reparent(cap);
  }

  protected func Hint(key: String, label: String, icon: Bool) -> Void {
    let item: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    item.SetMargin(inkMargin(22.0, 0.0, 0.0, 0.0));
    item.SetVAlign(inkEVerticalAlign.Center);
    item.Reparent(this.m_footPanel);
    this.KeyCap(item, key, icon);
    let text: ref<inkText> = this.Text(item, 22);
    text.SetText(label);
    text.SetOpacity(0.7);
    text.SetMargin(inkMargin(8.0, 0.0, 0.0, 0.0));
    text.SetVAlign(inkEVerticalAlign.Center);
  }

  protected func KeyCap(parent: wref<inkCompoundWidget>, key: String, icon: Bool) -> Void {
    let cap: ref<inkFlex> = new inkFlex();
    cap.SetVAlign(inkEVerticalAlign.Center);
    cap.Reparent(parent);
    this.CapEdge(cap, inkEHorizontalAlign.Fill, inkEVerticalAlign.Top, Vector2(0.0, 2.0));
    this.CapEdge(cap, inkEHorizontalAlign.Fill, inkEVerticalAlign.Bottom, Vector2(0.0, 2.0));
    this.CapEdge(cap, inkEHorizontalAlign.Left, inkEVerticalAlign.Fill, Vector2(2.0, 0.0));
    this.CapEdge(cap, inkEHorizontalAlign.Right, inkEVerticalAlign.Fill, Vector2(2.0, 0.0));
    let keyText: ref<inkText>;
    if icon {
      keyText = this.Icon(cap, 24, key);
    } else {
      keyText = this.Text(cap, 22);
      keyText.SetFontStyle(n"Semi-Bold");
      keyText.SetText(key);
    };
    keyText.SetMargin(inkMargin(10.0, icon ? 5.0 : 3.0, 10.0, icon ? 5.0 : 3.0));
    keyText.SetHAlign(inkEHorizontalAlign.Center);
    keyText.SetVAlign(inkEVerticalAlign.Center);
  }

  protected func ResetSelected() -> Void {
    let row: ref<DCMMenuRow> = this.Selected();
    if this.m_zone == 0 && !this.m_collapsed && IsDefined(row) && row.changed {
      this.Emit("reset\t" + row.id);
    };
  }

  protected func SetCollapsed(value: Bool) -> Void {
    if Equals(value, this.m_collapsed) {
      return;
    };
    this.m_collapsed = value;
    this.m_zone = value ? 1 : 0;
    if value {
      this.m_helpOn = false;
      this.GetGameController().RequestSetFocus(null);
    } else {
      this.AutoFocusSearch();
    };
    this.Layout();
    this.Paint();
  }

  protected func ToggleHelp() -> Void {
    if this.m_collapsed {
      return;
    };
    this.m_helpOn = !this.m_helpOn;
    this.Layout();
  }

  protected func HelpLine(panel: wref<inkCompoundWidget>, key: String, icon: Bool, text: String) -> Void {
    let row: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    row.SetMargin(inkMargin(24.0, 5.0, 0.0, 5.0));
    row.Reparent(panel);
    let keys: ref<inkCanvas> = new inkCanvas();
    keys.SetSize(Vector2(200.0, 40.0));
    keys.SetVAlign(inkEVerticalAlign.Center);
    keys.Reparent(row);
    let caps: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    caps.SetAnchor(inkEAnchor.CenterLeft);
    caps.SetAnchorPoint(Vector2(0.0, 0.5));
    caps.Reparent(keys);
    let parts: array<String> = StrSplit(key, " / ");
    let i: Int32 = 0;
    while i < ArraySize(parts) {
      if i > 0 {
        let slash: ref<inkText> = this.Text(caps, 22);
        slash.SetText("/");
        slash.SetOpacity(0.6);
        slash.SetMargin(inkMargin(8.0, 0.0, 8.0, 0.0));
        slash.SetVAlign(inkEVerticalAlign.Center);
      };
      this.KeyCap(caps, parts[i], icon);
      i += 1;
    };
    let t: ref<inkText> = this.Text(row, 24);
    t.SetText(text);
    t.SetOpacity(0.8);
    t.SetWrapping(true, this.ContentW() - 272.0);
    t.SetVAlign(inkEVerticalAlign.Center);
  }

  protected func BuildHelp() -> Void {
    if IsDefined(this.m_help) {
      this.m_container.RemoveChild(this.m_help);
    };
    let help: ref<inkCanvas> = new inkCanvas();
    help.SetMargin(inkMargin(this.TabW(), this.Bar(), 0.0, 0.0));
    help.SetSize(Vector2(this.ContentW(), this.H() - this.Bar() - this.Foot()));
    help.Reparent(this.m_container);
    let bg: ref<inkRectangle> = this.Rect(help, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.94);
    bg.SetAnchor(inkEAnchor.Fill);
    let panel: ref<inkVerticalPanel> = new inkVerticalPanel();
    panel.SetMargin(inkMargin(0.0, 16.0, 0.0, 0.0));
    panel.Reparent(help);
    this.HelpLine(panel, "\u{e004}", true, this.UI(8, "Move (D-pad, left stick)"));
    this.HelpLine(panel, "Enter", false, this.UI(9, "Select, open or close a group (A)"));
    this.HelpLine(panel, "\u{e005}", true, this.UI(10, "Change value, close or open a group"));
    this.HelpLine(panel, "Shift / Ctrl", false, this.UI(20, "Change value \u{00d7}10 / \u{00d7}100 (hold LT / RT)"));
    this.HelpLine(panel, "PgUp / PgDn", false, this.UI(11, "Previous or next group (right stick)"));
    this.HelpLine(panel, "Q / E", false, this.UI(12, "Sub-tab (tap LT / RT)"));
    this.HelpLine(panel, "R", false, this.UI(13, "Reset to default (X)"));
    this.HelpLine(panel, "F", false, this.UI(24, "Add to or remove from Favorites (Start, or click the star)"));
    this.HelpLine(panel, "Enter", false, this.UI(25, "Type an exact value (Enter or double click on a number)"));
    this.HelpLine(panel, "F2", false, this.UI(26, "Rename a preset"));
    this.HelpLine(panel, "G", false, this.UI(28, "Go to the option in its tab (Search, Active, Favorites)"));
    this.HelpLine(panel, "1 / 9", false, this.UI(29, "Jump to tab 1 to 9"));
    this.HelpLine(panel, "LB / RB", false, this.UI(14, "Tab (controller)"));
    this.HelpLine(panel, "Ctrl+F", false, this.UI(15, "Filter the list"));
    this.HelpLine(panel, "Tab", false, this.UI(16, "Collapse (Y, or click the open tab)"));
    this.HelpLine(panel, "Esc", false, this.UI(17, "Leave search, clear filter, tabs, collapse, close (B)"));
    this.HelpLine(panel, "F1", false, this.UI(18, "This help (Select)"));
    let owner: ref<PlayerPuppet> = this.Player();
    this.HelpLine(panel, IsDefined(owner) ? DCMKeyLabel(owner.DCMMenuKey()) : "F8", false, this.UI(19, "Open or close the menu") + (IsDefined(owner) && owner.m_dcmComboOff ? "" : " (" + (IsDefined(owner) ? DCMComboText(owner.DCMMenuCombo()) : "LB+X") + ")"));
    help.SetVisible(false);
    this.m_help = help;
  }

  protected func ClampFirst() -> Void {
    let maxFirst: Int32 = Max(0, ArraySize(this.m_rows) - this.Visible());
    this.m_first = Clamp(this.m_first, 0, maxFirst);
  }

  protected func EnsureVisible() -> Void {
    if this.m_sel >= 0 {
      if this.m_sel < this.m_first {
        this.m_first = this.m_sel;
      };
      if this.m_sel >= this.m_first + this.Visible() {
        this.m_first = this.m_sel - this.Visible() + 1;
      };
      if this.m_sel == this.FirstSelectable() {
        this.m_first = 0;
      };
    };
    this.Paint();
  }

  protected func SwitchTab(index: Int32) -> Void {
    this.CloseEdit(false);
    let count: Int32 = ArraySize(this.m_tabNames);
    if count == 0 {
      return;
    };
    if index < 0 {
      index = count - 1;
    };
    if index >= count {
      index = 0;
    };
    this.Emit("tab\t" + IntToString(index));
  }

  protected func SwitchSub(dir: Int32) -> Void {
    this.CloseEdit(false);
    let count: Int32 = ArraySize(this.m_subNames);
    if count == 0 {
      return;
    };
    let next: Int32 = this.m_sub + dir;
    if next < 0 {
      next = count - 1;
    };
    if next >= count {
      next = 0;
    };
    this.Emit("sub\t" + IntToString(next));
  }

  protected func Move(dir: Int32) -> Void {
    if this.m_zone == 1 {
      let next: Int32 = this.m_tab + dir;
      if next >= 0 && next < ArraySize(this.m_tabNames) {
        this.SwitchTab(next);
      };
      return;
    };
    let i: Int32 = this.m_sel + dir;
    while i >= 0 && i < ArraySize(this.m_rows) {
      if this.m_rows[i].IsSelectable() {
        this.m_sel = i;
        this.EnsureVisible();
        return;
      };
      i += dir;
    };
    if dir < 0 && this.m_first > 0 {
      this.m_first = 0;
      this.Paint();
    };
  }

  protected func Jump(dir: Int32) -> Void {
    if this.m_zone == 1 || ArraySize(this.m_rows) == 0 {
      return;
    };
    let i: Int32 = this.m_sel + dir;
    let target: Int32 = -1;
    while i >= 0 && i < ArraySize(this.m_rows) && target < 0 {
      if this.m_rows[i].IsHead() {
        target = i;
      };
      i += dir;
    };
    if target < 0 {
      target = dir > 0 ? ArraySize(this.m_rows) - 1 : 0;
    };
    let j: Int32 = target;
    while j < ArraySize(this.m_rows) && !this.m_rows[j].IsSelectable() {
      j += 1;
    };
    if j < ArraySize(this.m_rows) {
      this.m_sel = j;
      this.EnsureVisible();
    };
  }

  public func GameAction(name: CName, type: gameinputActionType, value: Float) -> Void {
    if this.CapturedLately() {
      return;
    };
    if Equals(name, n"__DEVICE_CHANGED__") {
      this.DeviceChanged();
      return;
    };
    if Equals(type, gameinputActionType.REPEAT) {
      if Equals(name, n"popup_navigate_up") || Equals(name, n"popup_moveUp_left_stick_up") {
        this.Move(-1);
      } else {
        if Equals(name, n"popup_navigate_down") || Equals(name, n"popup_moveUp_left_stick_down") {
          this.Move(1);
        };
      };
      return;
    };
    if Equals(name, n"popup_axisY_right") && Equals(type, gameinputActionType.AXIS_CHANGE) {
      let now: Float = this.Now();
      if AbsF(value) > 0.6 && now - this.m_stickAt > 0.3 {
        this.m_stickAt = now;
        this.Jump(value > 0.0 ? -1 : 1);
      };
    };
  }

  protected func Activate() -> Void {
    if this.m_collapsed {
      this.SetCollapsed(false);
      this.m_zone = 0;
      this.Paint();
      return;
    };
    if this.m_zone == 1 {
      this.m_zone = 0;
      this.Paint();
      return;
    };
    let row: ref<DCMMenuRow> = this.Selected();
    if !IsDefined(row) || !row.IsSelectable() {
      return;
    };
    if row.IsHead() {
      this.Emit(row.Has("g") ? "goto\t" + row.raw : "gtoggle\t" + row.id);
      return;
    };
    if this.Captures(row.id) {
      this.StartCapture(row.id);
      return;
    };
    if !this.m_pad && row.Has("t") && Equals(row.kind, "choice") {
      this.OpenEdit("set");
      return;
    };
    if Equals(row.kind, "choice") {
      this.Emit("inc\t" + row.id);
    } else {
      this.Emit("act\t" + row.id);
    };
  }

  protected func Step(dir: Int32) -> Void {
    if this.m_zone == 1 {
      if dir > 0 {
        this.m_zone = 0;
        this.Paint();
      };
      return;
    };
    let row: ref<DCMMenuRow> = this.Selected();
    if !IsDefined(row) || !row.IsSelectable() {
      return;
    };
    if row.IsHead() {
      this.Emit((dir > 0 ? "gopen\t" : "gclose\t") + row.id);
      return;
    };
    if this.Captures(row.id) {
      this.StartCapture(row.id);
      return;
    };
    let big: Bool = this.m_ctrl || (this.m_pad && this.m_rtHeld);
    let mid: Bool = !big && (this.m_shift || (this.m_pad && this.m_ltHeld));
    if (big || mid) && this.m_pad {
      this.m_trigUsed = true;
    };
    this.Emit((big ? "c" : (mid ? "s" : "")) + (dir > 0 ? "inc\t" : "dec\t") + row.id);
  }

  protected func Hold(target: ref<DCMMenuPopup>, key: EInputKey, dir: Int32) -> Void {
    let row: ref<DCMMenuRow> = target.Selected();
    if target.IsWin() || target.m_zone != 0 || target.m_collapsed || !IsDefined(row) || !row.IsStepper() || target.Captures(row.id) {
      return;
    };
    let big: Bool = this.m_ctrl || (this.m_pad && this.m_rtHeld);
    let mid: Bool = !big && (this.m_shift || (this.m_pad && this.m_ltHeld));
    this.m_holdKey = key;
    this.Emit("hold\t" + (dir > 0 ? "inc" : "dec") + "\t" + row.id + "\t" + (big ? "c" : (mid ? "s" : "")) + "\t" + (row.Has("t") ? "1" : "0"));
  }

  public func GoToSelected() -> Void {
    let row: ref<DCMMenuRow> = this.Selected();
    if IsDefined(row) && row.Has("g") && this.m_zone == 0 && !this.m_collapsed {
      this.Emit("goto\t" + (row.IsHead() ? row.raw : row.id));
    };
  }

  protected func IndexOf(list: array<wref<inkWidget>>, target: wref<inkWidget>) -> Int32 {
    let i: Int32 = 0;
    while i < ArraySize(list) {
      if Equals(list[i], target) {
        return i;
      };
      i += 1;
    };
    return -1;
  }

  protected cb func OnDCMPress(evt: ref<inkPointerEvent>) -> Bool {
    if this.CapturedLately() || evt.IsAction(n"mouse_left") || evt.IsAction(n"mouse_right") {
      return false;
    };
    if NotEquals(this.FocusWin(), this.IsWin()) {
      return false;
    };
    if this.IsEditing() {
      if evt.IsAction(n"proceed") {
        this.CloseEdit(true);
      };
      return false;
    };
    if evt.IsAction(n"proceed") && this.Now() - this.m_editEnd < 0.3 {
      return false;
    };
    if evt.IsAction(n"up_button") || evt.IsAction(n"popup_moveUp_left_stick_up") {
      this.Move(-1);
    } else {
      if evt.IsAction(n"down_button") || evt.IsAction(n"popup_moveUp_left_stick_down") {
        this.Move(1);
      } else {
        if evt.IsAction(n"left_button") && this.m_pad {
          this.Step(-1);
        } else {
          if evt.IsAction(n"right_button") && this.m_pad {
            this.Step(1);
          } else {
            if evt.IsAction(n"proceed") {
              this.BlurSearch();
              this.Activate();
            } else {
              if evt.IsAction(n"prior_menu") && this.m_pad {
                this.SwitchTab(this.m_tab - 1);
              } else {
                if evt.IsAction(n"next_menu") && this.m_pad {
                  this.SwitchTab(this.m_tab + 1);
                };
              };
            };
          };
        };
      };
    };
    return false;
  }

  protected cb func OnGlobalReleaseInput(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_left") && this.m_dragging {
      this.m_dragging = false;
      this.Emit("pos\t" + FloatToString(this.m_pos.X) + "\t" + FloatToString(this.m_pos.Y));
    };
    if evt.IsAction(n"mouse_left") && this.m_resizing > 0 {
      this.m_resizing = 0;
      this.Emit("size\t" + FloatToString(this.m_extraW) + "\t" + FloatToString(this.m_extraH));
    };
    if evt.IsAction(n"mouse_left") && this.IsEditing() && !this.m_edit.IsHovered() {
      this.CloseEdit(false);
    };
    if evt.IsAction(n"mouse_left") {
      if this.Owns(evt.GetTarget()) {
        this.ClaimFocus();
      } else {
        if this.WinOwns(evt.GetTarget()) {
          return false;
        };
      };
    };
    if this.CapturedLately() && evt.IsAction(n"cancel") {
      evt.Handle();
      return true;
    };
    if evt.IsAction(n"cancel") && !evt.IsHandled() {
      if Equals(this.m_lastKey, EInputKey.IK_Backspace) {
        evt.Handle();
        return true;
      };
      if this.IsEditing() {
        this.CloseEdit(false);
        evt.Handle();
        return true;
      };
      if this.m_helpOn {
        this.ToggleHelp();
        evt.Handle();
        return true;
      };
      if this.IsTyping() {
        this.BlurSearch();
        evt.Handle();
        return true;
      };
      if this.SearchShown() && StrLen(this.m_search.GetText()) > 0 {
        this.SetSearchText("");
        this.m_sel = -1;
        this.Emit("filter\t");
        evt.Handle();
        return true;
      };
      if this.m_zone == 0 && !this.m_collapsed {
        this.m_zone = 1;
        this.Paint();
        evt.Handle();
        return true;
      };
      if !this.m_collapsed {
        this.SetCollapsed(true);
        evt.Handle();
        return true;
      };
    };
    let result: Bool = super.OnGlobalReleaseInput(evt);
    if evt.IsAction(n"mouse_left") && this.m_search.IsHovered() {
      this.FocusSearch();
    };
    return result;
  }

  protected func WheelHere() -> Bool {
    let player: ref<PlayerPuppet> = this.Player();
    return !IsDefined(player) || !IsDefined(player.m_dcmSquad) || !player.m_dcmSquad.Hovering();
  }

  protected cb func OnDCMRelative(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_wheel") && this.WheelStep(evt.GetAxisData()) {
      return false;
    };
    if evt.IsAction(n"mouse_wheel") {
      if !this.WheelHere() {
        return false;
      };
      this.CloseEdit(false);
      let axis: Float = evt.GetAxisData();
      let before: Int32 = this.m_first;
      if axis > 0.0 {
        this.m_first -= 3;
      };
      if axis < 0.0 {
        this.m_first += 3;
      };
      this.ClampFirst();
      if this.m_hover >= 0 {
        this.m_hover += this.m_first - before;
        this.FollowMouse();
      };
      this.Paint();
      return false;
    };
    if this.m_resizing > 0 && (evt.IsAction(n"mouse_x") || evt.IsAction(n"mouse_y")) {
      this.ResizeTo(this.Pos(evt));
      return false;
    };
    if !this.m_dragging && this.m_hover >= 0 && this.m_hover != this.m_sel && (evt.IsAction(n"mouse_x") || evt.IsAction(n"mouse_y")) {
      this.FollowMouse();
      this.Paint();
    };
    if this.m_dragging && (evt.IsAction(n"mouse_x") || evt.IsAction(n"mouse_y")) {
      let pos: Vector2 = this.Pos(evt);
      this.m_pos = Vector2(this.m_dragMargin.left + (pos.X - this.m_dragStart.X) * this.m_scale, this.m_dragMargin.top + (pos.Y - this.m_dragStart.Y) * this.m_scale);
      this.m_container.SetMargin(inkMargin(this.m_pos.X, this.m_pos.Y, 0.0, 0.0));
    };
    return false;
  }

  protected cb func OnDCMKey(event: ref<KeyInputEvent>) {
    let key: EInputKey = event.GetKey();
    let act: EInputAction = event.GetAction();
    if this.m_capture {
      this.CaptureKey(key, act);
      return;
    };
    if Equals(key, EInputKey.IK_LControl) || Equals(key, EInputKey.IK_RControl) {
      this.m_ctrl = !Equals(act, EInputAction.IACT_Release);
    };
    if Equals(key, EInputKey.IK_LShift) || Equals(key, EInputKey.IK_RShift) {
      this.m_shift = !Equals(act, EInputAction.IACT_Release);
    };
    let squad: ref<PlayerPuppet> = this.Player();
    if IsDefined(squad) && IsDefined(squad.m_dcmSquad) {
      squad.m_dcmSquad.SetModifiers(this.m_ctrl, this.m_shift);
    };
    if Equals(act, EInputAction.IACT_Press) && this.IsEditing() && Equals(key, EInputKey.IK_Enter) {
      this.CloseEdit(true);
      return;
    };
    if Equals(act, EInputAction.IACT_Press) {
      this.m_lastKey = key;
      let player: ref<PlayerPuppet> = this.Player();
      let target: ref<DCMMenuPopup> = this;
      if this.FocusWin() && IsDefined(player.m_dcmSquad) {
        target = player.m_dcmSquad;
      };
      let letters: Bool = this.m_ctrl || !target.IsTyping();
      if (letters && !this.m_ctrl && Equals(key, EInputKey.IK_F)) || Equals(key, EInputKey.IK_Pad_Start) {
        target.ToggleFav();
      };
      if !target.IsTyping() && Equals(key, EInputKey.IK_F2) {
        target.RenameSelected();
      };
      if Equals(key, EInputKey.IK_PageUp) || Equals(key, EInputKey.IK_PageDown) {
        target.Jump(Equals(key, EInputKey.IK_PageUp) ? -1 : 1);
      };
      if !this.m_pad && !this.CapturedLately() && !this.IsEditing() && (Equals(key, EInputKey.IK_Left) || Equals(key, EInputKey.IK_Right))
        && !Equals(key, this.m_holdKey) {
        target.Step(Equals(key, EInputKey.IK_Left) ? -1 : 1);
        this.Hold(target, key, Equals(key, EInputKey.IK_Left) ? -1 : 1);
      };
      if this.m_pad && (Equals(key, EInputKey.IK_Pad_DigitLeft) || Equals(key, EInputKey.IK_Pad_DigitRight)) && !Equals(key, this.m_holdKey) {
        this.Hold(target, key, Equals(key, EInputKey.IK_Pad_DigitLeft) ? -1 : 1);
      };
      if !target.IsTyping() && Equals(key, EInputKey.IK_G) {
        target.GoToSelected();
      };
      let digits: array<EInputKey> = [EInputKey.IK_1, EInputKey.IK_2, EInputKey.IK_3, EInputKey.IK_4, EInputKey.IK_5, EInputKey.IK_6,
        EInputKey.IK_7, EInputKey.IK_8, EInputKey.IK_9];
      let digit: Int32 = 0;
      while digit < 9 && !Equals(digits[digit], key) {
        digit += 1;
      };
      if !target.IsTyping() && !this.CapturedLately() && digit < 9 && digit < ArraySize(this.m_tabNames) {
        this.m_zone = 0;
        this.SetCollapsed(false);
        if digit != this.m_tab {
          this.SwitchTab(digit);
        };
      };
      if letters && (Equals(key, EInputKey.IK_Q) || Equals(key, EInputKey.IK_E)) {
        this.SwitchSub(Equals(key, EInputKey.IK_Q) ? -1 : 1);
      };
      if this.m_ctrl && Equals(key, EInputKey.IK_F) {
        target.FocusSearch();
      };
      if (letters && Equals(key, EInputKey.IK_R)) || Equals(key, EInputKey.IK_Pad_X_SQUARE) {
        target.ResetSelected();
      };
      if (Equals(key, EInputKey.IK_Tab) && !this.IsEditing()) || Equals(key, EInputKey.IK_Pad_Y_TRIANGLE) {
        this.SetCollapsed(!this.m_collapsed);
      };
      if Equals(key, EInputKey.IK_F1) || Equals(key, EInputKey.IK_Pad_Back_Select) {
        this.ToggleHelp();
      };
    };
    if Equals(act, EInputAction.IACT_Release) && Equals(key, this.m_holdKey) {
      this.m_holdKey = EInputKey.IK_None;
      this.Emit("unhold");
    };
    if Equals(key, EInputKey.IK_Pad_LeftTrigger) || Equals(key, EInputKey.IK_Pad_RightTrigger) {
      let lt: Bool = Equals(key, EInputKey.IK_Pad_LeftTrigger);
      if Equals(act, EInputAction.IACT_Press) {
        if !this.m_ltHeld && !this.m_rtHeld {
          this.m_trigUsed = false;
        };
        this.m_trigAt = this.Now();
        if lt {
          this.m_ltHeld = true;
        } else {
          this.m_rtHeld = true;
        };
      } else {
        if Equals(act, EInputAction.IACT_Release) {
          if lt {
            this.m_ltHeld = false;
          } else {
            this.m_rtHeld = false;
          };
          if this.Now() - this.m_trigAt < 0.25 && !this.m_trigUsed {
            this.SwitchSub(lt ? -1 : 1);
          };
        };
      };
    };
  }

  protected cb func OnDCMResizePress(evt: ref<inkPointerEvent>) -> Bool {
    if !evt.IsAction(n"mouse_left") || this.m_pad {
      return false;
    };
    let target: wref<inkWidget> = evt.GetCurrentTarget();
    this.m_resizing = Equals(target, this.m_edgeRight) ? 2 : (Equals(target, this.m_edgeBottom) ? 3 : 1);
    this.m_resizeStart = this.Pos(evt);
    this.m_resizeBase = Vector2(this.m_extraW, this.m_extraH);
    return false;
  }

  protected cb func OnDCMResizeEnter(evt: ref<inkPointerEvent>) -> Bool {
    evt.GetCurrentTarget().SetOpacity(0.25);
    return false;
  }

  protected cb func OnDCMResizeLeave(evt: ref<inkPointerEvent>) -> Bool {
    evt.GetCurrentTarget().SetOpacity(0.01);
    return false;
  }

  protected func ResizeTo(pos: Vector2) -> Void {
    let s: Float = this.m_menuScale > 0.0 ? this.m_menuScale : 1.0;
    let dx: Float = (pos.X - this.m_resizeStart.X) * this.m_scale / s;
    let dy: Float = (pos.Y - this.m_resizeStart.Y) * this.m_scale / s;
    let maxW: Float = MaxF(0.0, (DCMScreenWidth(this.GetGame()) - this.Pillar() - this.m_pos.X) / s - this.BaseW());
    let maxH: Float = MaxF(0.0, (2160.0 - this.m_pos.Y) / s - this.BaseH());
    let w: Float = this.m_resizing == 3 ? this.m_extraW : ClampF(this.m_resizeBase.X + dx, 0.0, maxW);
    let h: Float = this.m_resizing == 2 ? this.m_extraH : ClampF(this.m_resizeBase.Y + dy, 0.0, maxH);
    if AbsF(w - this.m_extraW) < 1.0 && AbsF(h - this.m_extraH) < 1.0 {
      return;
    };
    this.m_extraW = w;
    this.m_extraH = h;
    this.Layout();
    this.EnsureVisible();
  }

  protected cb func OnDCMTitlePress(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_left") {
      this.m_dragging = true;
      this.m_dragStart = this.Pos(evt);
      this.m_dragMargin = inkMargin(this.m_pos.X, this.m_pos.Y, 0.0, 0.0);
    };
    return false;
  }

  protected cb func OnDCMRowClick(evt: ref<inkPointerEvent>) -> Bool {
    let right: Bool = evt.IsAction(n"mouse_right");
    if !evt.IsAction(n"mouse_left") && !right {
      return false;
    };
    let k: Int32 = this.IndexOf(this.m_rowCells, evt.GetCurrentTarget());
    let i: Int32 = k < 0 ? -1 : this.m_first + k;
    if i < 0 || i >= ArraySize(this.m_rows) || !this.m_rows[i].IsSelectable() {
      return false;
    };
    if right {
      this.m_sel = i;
      this.m_zone = 0;
      this.Paint();
      this.ResetSelected();
      return false;
    };
    this.BlurSearch();
    this.m_sel = i;
    this.m_zone = 0;
    this.Paint();
    let target: wref<inkWidget> = evt.GetTarget();
    if this.m_rows[i].Has("s") && Equals(target, this.m_rowStars[k]) {
      this.Emit("fav\t" + this.m_rows[i].id);
      return false;
    };
    if this.m_rows[i].changed && Equals(target, this.m_rowResets[k]) {
      this.ResetSelected();
      return false;
    };
    if this.m_rows[i].Has("t") && Equals(target, this.m_rowValues[k]) {
      if this.m_clickRow == i && this.Now() - this.m_clickAt < 0.4 {
        this.m_clickRow = -1;
        this.OpenEdit("set");
      } else {
        this.m_clickRow = i;
        this.m_clickAt = this.Now();
      };
      return false;
    };
    if this.m_rows[i].IsStepper() && Equals(target, this.m_rowLeft[k]) {
      this.Step(-1);
    } else {
      if this.m_rows[i].IsStepper() && Equals(target, this.m_rowRight[k]) {
        this.Step(1);
      } else {
        if Equals(this.m_rows[i].kind, "choice") {
          this.Step(1);
        } else {
          this.Activate();
        };
      };
    };
    return false;
  }

  protected cb func OnDCMRowEnter(evt: ref<inkPointerEvent>) -> Bool {
    if this.m_pad {
      return false;
    };
    let k: Int32 = this.IndexOf(this.m_rowCells, evt.GetCurrentTarget());
    this.m_hover = k < 0 ? -1 : this.m_first + k;
    this.FollowMouse();
    this.Paint();
    return false;
  }

  protected func FollowMouse() -> Void {
    if this.m_pad || this.m_collapsed || this.m_helpOn || this.IsEditing() || this.CapturedLately() || this.m_dragging
      || this.m_resizing > 0 || this.m_hover < 0 || this.m_hover >= ArraySize(this.m_rows) || !this.m_rows[this.m_hover].IsSelectable() {
      return;
    };
    if this.m_sel != this.m_hover || this.m_zone != 0 {
      this.ClaimFocus();
    };
    this.m_sel = this.m_hover;
    this.m_zone = 0;
  }

  public func SetModifiers(ctrl: Bool, shift: Bool) -> Void {
    this.m_ctrl = ctrl;
    this.m_shift = shift;
  }

  protected func WheelStep(axis: Float) -> Bool {
    if this.m_pad || axis == 0.0 || !IsDefined(this.m_hoverPart) {
      return false;
    };
    let k: Int32 = 0;
    while k < ArraySize(this.m_rowLeft) && !Equals(this.m_rowLeft[k], this.m_hoverPart) && !Equals(this.m_rowRight[k], this.m_hoverPart)
      && !Equals(this.m_rowValues[k], this.m_hoverPart) {
      k += 1;
    };
    let i: Int32 = k >= ArraySize(this.m_rowLeft) ? -1 : this.m_first + k;
    if i < 0 || i >= ArraySize(this.m_rows) || !this.m_rows[i].IsStepper() {
      return false;
    };
    this.m_sel = i;
    this.m_zone = 0;
    this.Step(axis > 0.0 ? 1 : -1);
    return true;
  }

  protected func HoverPart(part: ref<inkText>) -> Void {
    part.SetRenderTransformPivot(Vector2(0.5, 0.5));
    part.RegisterToCallback(n"OnEnter", this, n"OnDCMPartEnter");
    part.RegisterToCallback(n"OnLeave", this, n"OnDCMPartLeave");
  }

  protected func PaintPart(part: wref<inkText>, live: Bool) -> Void {
    let hot: Bool = live && !this.m_pad && Equals(part, this.m_hoverPart);
    part.SetScale(hot ? Vector2(1.4, 1.4) : Vector2(1.0, 1.0));
    if hot {
      part.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
      part.SetOpacity(1.0);
    };
  }

  protected cb func OnDCMPartEnter(evt: ref<inkPointerEvent>) -> Bool {
    this.m_hoverPart = evt.GetCurrentTarget();
    this.Paint();
    return false;
  }

  protected cb func OnDCMPartLeave(evt: ref<inkPointerEvent>) -> Bool {
    if Equals(this.m_hoverPart, evt.GetCurrentTarget()) {
      this.m_hoverPart = null;
      this.Paint();
    };
    return false;
  }

  protected cb func OnDCMRowLeave(evt: ref<inkPointerEvent>) -> Bool {
    this.m_hover = -1;
    this.Paint();
    return false;
  }

  protected cb func OnDCMTabClick(evt: ref<inkPointerEvent>) -> Bool {
    if !evt.IsAction(n"mouse_left") {
      return false;
    };
    let t: Int32 = this.IndexOf(this.m_tabCells, evt.GetCurrentTarget());
    if t >= 0 {
      this.m_zone = 0;
      if t == this.m_tab {
        this.SetCollapsed(!this.m_collapsed);
      } else {
        this.SetCollapsed(false);
        this.SwitchTab(t);
      };
    };
    return false;
  }

  protected cb func OnDCMSubClick(evt: ref<inkPointerEvent>) -> Bool {
    if !evt.IsAction(n"mouse_left") {
      return false;
    };
    let k: Int32 = this.IndexOf(this.m_subCells, evt.GetCurrentTarget());
    if k >= 0 && this.m_subIdx[k] != this.m_sub {
      this.Emit("sub\t" + IntToString(this.m_subIdx[k]));
    };
    return false;
  }

  protected cb func OnDCMSubEdge(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_left") {
      this.SwitchSub(Equals(evt.GetCurrentTarget(), this.m_subLead) ? -1 : 1);
    };
    return false;
  }

  public static func Show(player: ref<PlayerPuppet>) -> ref<DCMMenuPopup> {
    let popup: ref<DCMMenuPopup> = new DCMMenuPopup();
    GameInstance.GetUISystem(player.GetGame()).QueueEvent(ShowCustomPopupEvent.Create(popup));
    return popup;
  }

  public static func ShowOnLayer(player: ref<PlayerPuppet>) -> ref<DCMMenuPopup> {
    let layer: ref<inkLayerWrapper> = GameInstance.GetInkSystem().GetLayer(n"inkMenuLayer");
    if !IsDefined(layer) {
      return null;
    };
    let window: wref<inkVirtualWindow> = layer.GetVirtualWindow();
    let controller: wref<inkGameController> = layer.GetGameController() as inkGameController;
    if !IsDefined(window) || !IsDefined(controller) {
      return null;
    };
    let game: GameInstance = GetGameInstance();
    let s: Float = DCMScreenScale(game);
    let screen: Vector2 = ScreenHelper.GetScreenSize(game);
    let root: ref<inkCanvas> = new inkCanvas();
    root.SetName(n"DCMMenuLayer");
    root.SetAnchor(inkEAnchor.TopLeft);
    root.SetSize(Vector2(screen.X * s, screen.Y * s));
    root.SetRenderTransformPivot(Vector2(0.0, 0.0));
    root.SetScale(Vector2(1.0 / s, 1.0 / s));
    root.Reparent(window);
    let popup: ref<DCMMenuPopup> = new DCMMenuPopup();
    popup.m_onLayer = true;
    popup.m_layerRoot = root;
    player.m_dcmMenu = popup;
    popup.Attach(root, controller, new inkGameNotificationData());
    return popup;
  }
}

public class DCMSquadPopup extends DCMMenuPopup {
  public func IsWin() -> Bool {
    return true;
  }

  protected func W() -> Float { return 720.0; }
  protected func TabW() -> Float { return 0.0; }

  protected func RegisterInput() -> Void {
    this.RegisterToGlobalInputCallback(n"OnPostOnPress", this, n"OnDCMPress");
    this.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnDCMRelative");
  }

  protected func UnregisterInput() -> Void {
    this.UnregisterFromGlobalInputCallback(n"OnPostOnPress", this, n"OnDCMPress");
    this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnDCMRelative");
  }

  protected func WheelHere() -> Bool {
    return this.m_hover >= 0;
  }

  protected func Opened() -> Void {
    this.m_pad = false;
    this.Layout();
    this.PaintFooter();
  }

  protected func Closed() -> Void {}

  protected cb func OnShown() {}

  protected func BuildTabs() -> Void {}

  protected func PaintFooter() -> Void {
    if !IsDefined(this.m_footPanel) {
      return;
    };
    this.m_footPanel.RemoveAllChildren();
    this.Hint("Enter", this.UI(1, "Select"), false);
    this.Hint("\u{e005}", this.UI(2, "Value"), true);
  }

  protected func Emit(msg: String) -> Void {
    super.Emit("win\t" + msg);
  }

  protected cb func OnGlobalReleaseInput(evt: ref<inkPointerEvent>) -> Bool {
    if !evt.IsAction(n"mouse_left") {
      return false;
    };
    if this.m_dragging {
      this.m_dragging = false;
      this.Emit("pos\t" + FloatToString(this.m_pos.X) + "\t" + FloatToString(this.m_pos.Y));
    };
    if this.Owns(evt.GetTarget()) {
      this.ClaimFocus();
      if this.m_search.IsHovered() {
        this.FocusSearch();
      };
    };
    return false;
  }

  protected func Place(x: String, y: String, scale: Float) -> Void {
    let s: Float = scale > 0.0 ? scale : 1.0;
    if StrLen(x) > 0 || !IsDefined(this.m_owner) {
      super.Place(x, y, scale);
      return;
    };
    let p: Vector2 = this.m_owner.MenuPos();
    super.Place(FloatToString(p.X + this.m_owner.MenuW() * s + 32.0), FloatToString(p.Y), scale);
  }
}

public class DCMToastHide extends DelayCallback {
  public let player: wref<PlayerPuppet>;
  public let seq: Int32;

  public func Call() -> Void {
    if IsDefined(this.player) && this.player.m_dcmToastSeq == this.seq && IsDefined(this.player.m_dcmToast) {
      this.player.m_dcmToast.SetVisible(false);
    };
  }
}

public func DCMToastText(parent: ref<inkCompoundWidget>, size: Int32, style: CName) -> ref<inkText> {
  let text: ref<inkText> = new inkText();
  text.SetFontFamily(DCMFont(), style);
  text.SetFontStyle(style);
  text.SetFontSize(size);
  text.SetFitToContent(true);
  text.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
  text.Reparent(parent);
  return text;
}

@addField(PlayerPuppet)
public let m_dcmToast: wref<inkCanvas>;

@addField(PlayerPuppet)
public let m_dcmToastShadow: wref<inkText>;

@addField(PlayerPuppet)
public let m_dcmToastText: wref<inkText>;

@addField(PlayerPuppet)
public let m_dcmToastSeq: Int32;

@addMethod(PlayerPuppet)
public func DCMToastBuild() -> Bool {
  let layer: ref<inkLayerWrapper> = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
  if !IsDefined(layer) {
    return false;
  };
  let root: ref<inkCompoundWidget> = layer.GetVirtualWindow();
  if !IsDefined(root) {
    return false;
  };
  let old: wref<inkWidget> = root.GetWidget(n"dcmToast");
  if IsDefined(old) {
    root.RemoveChild(old);
  };
  let box: ref<inkCanvas> = new inkCanvas();
  box.SetName(n"dcmToast");
  box.SetAnchor(inkEAnchor.TopRight);
  box.SetAnchorPoint(Vector2(1.0, 0.0));
  box.SetTranslation(Vector2(-30.0, 120.0));
  box.SetRenderTransformPivot(Vector2(1.0, 0.0));
  box.Reparent(root);
  this.m_dcmToastShadow = DCMToastText(box, 24, n"Semi-Bold");
  this.m_dcmToastShadow.SetAnchor(inkEAnchor.TopRight);
  this.m_dcmToastShadow.SetAnchorPoint(Vector2(1.0, 0.0));
  this.m_dcmToastShadow.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
  this.m_dcmToastShadow.SetOpacity(0.85);
  this.m_dcmToastShadow.SetTranslation(Vector2(2.0, 2.0));
  this.m_dcmToastText = DCMToastText(box, 24, n"Semi-Bold");
  this.m_dcmToastText.SetAnchor(inkEAnchor.TopRight);
  this.m_dcmToastText.SetAnchorPoint(Vector2(1.0, 0.0));
  this.m_dcmToast = box;
  return true;
}

@addMethod(PlayerPuppet)
public func DCMToast(text: String, scale: Float, seconds: Float) -> Bool {
  if !IsDefined(this.m_dcmToast) && !this.DCMToastBuild() {
    return false;
  };
  this.m_dcmToastShadow.SetText(text);
  this.m_dcmToastText.SetText(text);
  this.m_dcmToast.SetSize(Vector2(DCMTextW(text, 24.0) + 8.0, 34.0));
  let k: Float = DCMHudScale(this.GetGame());
  let s: Float = (scale > 0.0 ? scale : 1.0) * k;
  this.m_dcmToast.SetScale(Vector2(s, s));
  this.m_dcmToast.SetTranslation(Vector2(-30.0 * k, 120.0 * k));
  this.m_dcmToast.SetVisible(true);
  this.m_dcmToastSeq += 1;
  let hide: ref<DCMToastHide> = new DCMToastHide();
  hide.player = this;
  hide.seq = this.m_dcmToastSeq;
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(hide, seconds > 0.0 ? seconds : 1.8, false);
  return true;
}

public func DCMShadowLine(parent: ref<inkCompoundWidget>, text: String, size: Int32, right: Bool) -> Void {
  let line: ref<inkCanvas> = new inkCanvas();
  line.SetSize(Vector2(DCMTextW(text, Cast<Float>(size)) + 8.0, Cast<Float>(size) + 8.0));
  line.SetHAlign(right ? inkEHorizontalAlign.Right : inkEHorizontalAlign.Left);
  line.Reparent(parent);
  let shadow: ref<inkText> = DCMToastText(line, size, n"Semi-Bold");
  shadow.SetText(text);
  shadow.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
  shadow.SetOpacity(0.85);
  shadow.SetTranslation(Vector2(2.0, 2.0));
  let front: ref<inkText> = DCMToastText(line, size, n"Semi-Bold");
  front.SetText(text);
}

public func DCMHudRoot() -> ref<inkCompoundWidget> {
  let layer: ref<inkLayerWrapper> = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
  if !IsDefined(layer) {
    return null;
  };
  return layer.GetVirtualWindow();
}

@addField(PlayerPuppet)
public let m_dcmIndicator: wref<inkVerticalPanel>;

@addField(PlayerPuppet)
public let m_dcmNotice: wref<inkVerticalPanel>;

@addMethod(PlayerPuppet)
public func DCMIndicator(text: String, corner: Int32, scale: Float) -> Bool {
  let root: ref<inkCompoundWidget> = DCMHudRoot();
  if !IsDefined(root) {
    return false;
  };
  if IsDefined(this.m_dcmIndicator) {
    root.RemoveChild(this.m_dcmIndicator);
  };
  if StrLen(text) == 0 {
    return true;
  };
  let right: Bool = corner != 1;
  let bottom: Bool = corner == 2;
  let panel: ref<inkVerticalPanel> = new inkVerticalPanel();
  panel.SetName(n"dcmIndicator");
  panel.SetAnchor(bottom ? inkEAnchor.BottomRight : (right ? inkEAnchor.TopRight : inkEAnchor.TopLeft));
  panel.SetAnchorPoint(Vector2(right ? 1.0 : 0.0, bottom ? 1.0 : 0.0));
  panel.SetRenderTransformPivot(Vector2(right ? 1.0 : 0.0, bottom ? 1.0 : 0.0));
  let k: Float = DCMHudScale(this.GetGame());
  panel.SetTranslation(Vector2((right ? -30.0 : 30.0) * k, (bottom ? -320.0 : 170.0) * k));
  let s: Float = (scale > 0.0 ? scale : 1.0) * k;
  panel.SetScale(Vector2(s, s));
  panel.Reparent(root);
  let lines: array<String> = StrSplit(text, "\n");
  let i: Int32 = 0;
  while i < ArraySize(lines) {
    DCMShadowLine(panel, lines[i], 22, right);
    i += 1;
  };
  this.m_dcmIndicator = panel;
  return true;
}

@addMethod(PlayerPuppet)
public func DCMNotice(text: String) -> Bool {
  let root: ref<inkCompoundWidget> = DCMHudRoot();
  if !IsDefined(root) {
    return false;
  };
  if IsDefined(this.m_dcmNotice) {
    root.RemoveChild(this.m_dcmNotice);
  };
  if StrLen(text) == 0 {
    return true;
  };
  let panel: ref<inkVerticalPanel> = new inkVerticalPanel();
  panel.SetName(n"dcmNotice");
  panel.SetAnchor(inkEAnchor.TopCenter);
  panel.SetAnchorPoint(Vector2(0.5, 0.0));
  let k: Float = DCMHudScale(this.GetGame());
  panel.SetRenderTransformPivot(Vector2(0.5, 0.0));
  panel.SetScale(Vector2(k, k));
  panel.SetTranslation(Vector2(0.0, 120.0 * k));
  panel.Reparent(root);
  DCMShadowLine(panel, text, 40, false);
  this.m_dcmNotice = panel;
  return true;
}

@addField(PlayerPuppet)
public let m_dcmPrompt: wref<inkCanvas>;

@addField(PlayerPuppet)
public let m_dcmPromptBg: wref<inkRectangle>;

@addField(PlayerPuppet)
public let m_dcmPromptCap: wref<inkCanvas>;

@addField(PlayerPuppet)
public let m_dcmPromptKey: wref<inkText>;

@addField(PlayerPuppet)
public let m_dcmPromptText: wref<inkText>;

public func DCMPromptEdge(cap: ref<inkCanvas>, anchor: inkEAnchor, size: Vector2) -> Void {
  let edge: ref<inkRectangle> = new inkRectangle();
  edge.SetAnchor(anchor);
  edge.SetSize(size);
  edge.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
  edge.SetOpacity(0.7);
  edge.Reparent(cap);
}

@addMethod(PlayerPuppet)
public func DCMPromptBuild() -> Bool {
  let layer: ref<inkLayerWrapper> = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
  if !IsDefined(layer) {
    return false;
  };
  let root: ref<inkCompoundWidget> = layer.GetVirtualWindow();
  if !IsDefined(root) {
    return false;
  };
  let old: wref<inkWidget> = root.GetWidget(n"dcmPrompt");
  if IsDefined(old) {
    root.RemoveChild(old);
  };
  let k: Float = 1.0 / DCMScreenScale(this.GetGame());
  let box: ref<inkCanvas> = new inkCanvas();
  box.SetName(n"dcmPrompt");
  box.SetAnchor(inkEAnchor.Centered);
  box.SetAnchorPoint(Vector2(0.0, 0.5));
  box.SetRenderTransformPivot(Vector2(0.0, 0.5));
  box.SetScale(Vector2(k, k));
  box.SetTranslation(Vector2(150.0 * k, 110.0 * k));
  box.Reparent(root);
  let bg: ref<inkRectangle> = new inkRectangle();
  bg.SetAnchor(inkEAnchor.Fill);
  bg.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
  bg.SetOpacity(0.6);
  bg.Reparent(box);
  let cap: ref<inkCanvas> = new inkCanvas();
  cap.SetMargin(inkMargin(14.0, 10.0, 0.0, 0.0));
  cap.Reparent(box);
  DCMPromptEdge(cap, inkEAnchor.TopFillHorizontaly, Vector2(0.0, 3.0));
  DCMPromptEdge(cap, inkEAnchor.BottomFillHorizontaly, Vector2(0.0, 3.0));
  DCMPromptEdge(cap, inkEAnchor.LeftFillVerticaly, Vector2(3.0, 0.0));
  DCMPromptEdge(cap, inkEAnchor.RightFillVerticaly, Vector2(3.0, 0.0));
  this.m_dcmPromptKey = DCMToastText(cap, 28, n"Semi-Bold");
  this.m_dcmPromptKey.SetAnchor(inkEAnchor.Centered);
  this.m_dcmPromptKey.SetAnchorPoint(Vector2(0.5, 0.5));
  this.m_dcmPromptText = DCMToastText(box, 30, n"Medium");
  this.m_dcmPrompt = box;
  this.m_dcmPromptBg = bg;
  this.m_dcmPromptCap = cap;
  return true;
}

@addMethod(PlayerPuppet)
public func DCMPrompt(show: Bool, key: String, text: String, accent: String) -> Bool {
  if !IsDefined(this.m_dcmPrompt) {
    if !show || !this.DCMPromptBuild() {
      return false;
    };
  };
  if show {
    let capW: Float = Cast<Float>(UTF8StrLen(key)) * 17.0 + 28.0;
    this.m_dcmPromptCap.SetSize(Vector2(capW, 44.0));
    this.m_dcmPromptKey.SetText(key);
    this.m_dcmPromptText.SetText(text);
    this.m_dcmPromptText.SetTintColor(DCMColor(accent));
    this.m_dcmPromptText.SetMargin(inkMargin(capW + 30.0, 12.0, 0.0, 0.0));
    this.m_dcmPrompt.SetSize(Vector2(capW + 50.0 + Cast<Float>(UTF8StrLen(text)) * 14.5, 64.0));
  };
  this.m_dcmPrompt.SetVisible(show);
  return true;
}

@addField(PlayerPuppet)
public let m_dcmMenu: ref<DCMMenuPopup>;

@addField(PlayerPuppet)
public let m_dcmMenuOpen: Bool;

@addField(PlayerPuppet)
public let m_dcmMenuBlocked: Bool;

@addField(PlayerPuppet)
public let m_dcmCombo: array<EInputKey>;

@addField(PlayerPuppet)
public let m_dcmComboOff: Bool;

@addField(PlayerPuppet)
public let m_dcmHeld: array<EInputKey>;

@addField(PlayerPuppet)
public let m_dcmComboAt: Float;

@addField(PlayerPuppet)
public let m_dcmMenuKey: String;

@addField(PlayerPuppet)
public let m_dcmKeys: array<String>;

@addField(PlayerPuppet)
public let m_dcmMenuPos: Vector2;

@addField(PlayerPuppet)
public let m_dcmMenuHasPos: Bool;

@addField(PlayerPuppet)
public let m_dcmMenuCollapsed: Bool;

@addField(PlayerPuppet)
public let m_dcmMenuSelId: String;

@addField(PlayerPuppet)
public let m_dcmMenuFirst: Int32;

@addMethod(PlayerPuppet)
public func DCMMenuEmit(msg: String) -> Bool {
  return true;
}

@addField(PlayerPuppet)
public let m_dcmSquad: ref<DCMSquadPopup>;

@addField(PlayerPuppet)
public let m_dcmFocusWin: Bool;

@addMethod(PlayerPuppet)
public func DCMSquadShow() -> Bool {
  if !this.DCMMenuIsOpen() {
    return false;
  };
  if !IsDefined(this.m_dcmSquad) {
    this.m_dcmMenu.OpenSquad();
  };
  return IsDefined(this.m_dcmSquad);
}

@addMethod(PlayerPuppet)
public func DCMSquadHide() -> Bool {
  this.m_dcmFocusWin = false;
  if IsDefined(this.m_dcmSquad) {
    let win: ref<DCMSquadPopup> = this.m_dcmSquad;
    this.m_dcmSquad = null;
    win.Close();
  };
  return true;
}

@addMethod(PlayerPuppet)
public func DCMSquadPush(payload: String) -> Int32 {
  if IsDefined(this.m_dcmSquad) {
    return this.m_dcmSquad.Load(payload);
  };
  return -1;
}

@addMethod(PlayerPuppet)
public func DCMMenuPush(payload: String) -> Int32 {
  if IsDefined(this.m_dcmMenu) && this.m_dcmMenu.IsOpen() {
    return this.m_dcmMenu.Load(payload);
  };
  return -1;
}

@addMethod(PlayerPuppet)
public func DCMMenuSetCombo(names: String) -> Bool {
  ArrayClear(this.m_dcmCombo);
  this.m_dcmComboOff = Equals(names, "off");
  let parts: array<String> = StrSplit(names, "+");
  let labels: array<String> = DCMPadNames();
  let keys: array<EInputKey> = DCMPadKeys();
  let p: Int32 = 0;
  while p < ArraySize(parts) {
    let i: Int32 = 0;
    while i < ArraySize(labels) {
      if Equals(parts[p], labels[i]) && !ArrayContains(this.m_dcmCombo, keys[i]) {
        ArrayPush(this.m_dcmCombo, keys[i]);
      };
      i += 1;
    };
    p += 1;
  };
  return ArraySize(this.m_dcmCombo) > 0;
}

@addMethod(PlayerPuppet)
public func DCMMenuCombo() -> array<EInputKey> {
  if ArraySize(this.m_dcmCombo) > 0 {
    return this.m_dcmCombo;
  };
  return [EInputKey.IK_Pad_LeftShoulder, EInputKey.IK_Pad_X_SQUARE];
}

@addMethod(PlayerPuppet)
public func DCMMenuSetKeys(menuKey: String, keys: String) -> Bool {
  this.m_dcmMenuKey = menuKey;
  this.m_dcmKeys = StrSplit(keys, ",");
  return true;
}

@addMethod(PlayerPuppet)
public func DCMMenuKey() -> String {
  return DCMIsKeyboard(this.m_dcmMenuKey) ? this.m_dcmMenuKey : "IK_F8";
}

@addMethod(PlayerPuppet)
public func DCMGameBindOf(key: String) -> String {
  return DCMGameBind(key);
}

@addMethod(PlayerPuppet)
public func DCMMenuIsOpen() -> Bool {
  return IsDefined(this.m_dcmMenu) && this.m_dcmMenu.IsOpen();
}

@addField(PlayerPuppet)
public let m_dcmPause: wref<PauseMenuGameController>;

@addField(PlayerPuppet)
public let m_dcmInHub: Bool;

@addField(PlayerPuppet)
public let m_dcmSwallow: Bool;

@wrapMethod(PauseMenuGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    player.m_dcmPause = this;
  };
  return result;
}

@addMethod(PlayerPuppet)
public func DCMMenuOverMenu() -> Bool {
  return GameInstance.GetSystemRequestsHandler().IsPreGame() || this.m_dcmInHub || (this.m_dcmMenuBlocked && IsDefined(this.m_dcmPause));
}

@addMethod(PlayerPuppet)
public func DCMMenuLayerBusy() -> Bool {
  if this.DCMMenuIsOpen() && this.m_dcmMenu.OnLayer() {
    return true;
  };
  return this.m_dcmSwallow;
}

public func DCMLayerBusy() -> Bool {
  let player: ref<PlayerPuppet> = GetPlayer(GetGameInstance());
  return IsDefined(player) && player.DCMMenuLayerBusy();
}

@addMethod(PlayerPuppet)
public func DCMCloseLayerMenu() -> Void {
  if this.DCMMenuIsOpen() && this.m_dcmMenu.OnLayer() {
    this.m_dcmMenu.Close();
    this.m_dcmMenu = null;
  };
}

@addMethod(PlayerPuppet)
public func DCMMenuToggle() -> Bool {
  if this.DCMMenuIsOpen() {
    this.m_dcmMenu.Close();
    this.m_dcmMenu = null;
    return false;
  };
  if this.DCMMenuOverMenu() {
    this.m_dcmMenu = DCMMenuPopup.ShowOnLayer(this);
    return IsDefined(this.m_dcmMenu);
  };
  if this.m_dcmMenuBlocked {
    return false;
  };
  this.m_dcmMenu = DCMMenuPopup.Show(this);
  return true;
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnDCMMenuKey")
    .SetLifetime(CallbackLifetime.Session);
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  GameInstance.GetCallbackSystem().UnregisterCallback(n"Input/Key", this, n"OnDCMMenuKey");
  return wrappedMethod();
}

@addMethod(PlayerPuppet)
protected cb func OnDCMMenuKey(event: ref<KeyInputEvent>) {
  let key: EInputKey = event.GetKey();
  let act: EInputAction = event.GetAction();
  if Equals(act, EInputAction.IACT_Press) {
    this.m_dcmSwallow = false;
  };
  let pad: Bool = DCMPadIndex(key) >= 0;
  if pad && Equals(act, EInputAction.IACT_Release) {
    ArrayRemove(this.m_dcmHeld, key);
  };
  if pad && Equals(act, EInputAction.IACT_Press) && !ArrayContains(this.m_dcmHeld, key) {
    ArrayPush(this.m_dcmHeld, key);
  };
  if this.DCMMenuIsOpen() && this.m_dcmMenu.IsCapturing() {
    return;
  };
  let id: String = pad ? "" : DCMKeyId(key);
  if pad && Equals(act, EInputAction.IACT_Press) && !this.DCMMenuIsOpen() && !this.m_dcmMenuBlocked
    && ArrayContains(this.m_dcmHeld, EInputKey.IK_Pad_LeftTrigger) && ArrayContains(this.m_dcmHeld, EInputKey.IK_Pad_RightTrigger)
    && !Equals(key, EInputKey.IK_Pad_LeftTrigger) && !Equals(key, EInputKey.IK_Pad_RightTrigger) {
    this.DCMMenuEmit("phk\t" + DCMPadNames()[DCMPadIndex(key)]);
  };
  if !pad && !this.DCMMenuIsOpen() && !this.m_dcmMenuBlocked && ArrayContains(this.m_dcmKeys, id) {
    let mods: String = event.IsShiftDown() ? "S" : (event.IsControlDown() ? "C" : "");
    this.DCMMenuEmit("hk\t" + id + "\t" + (Equals(act, EInputAction.IACT_Press) ? "1" : "0") + "\t" + mods);
  };
  if !Equals(act, EInputAction.IACT_Press) {
    return;
  };
  let keys: array<EInputKey> = this.DCMMenuCombo();
  let combo: Bool = pad && !this.m_dcmComboOff && ArrayContains(keys, key);
  let i: Int32 = 0;
  while combo && i < ArraySize(keys) {
    if !ArrayContains(this.m_dcmHeld, keys[i]) {
      combo = false;
    };
    i += 1;
  };
  if !combo && !Equals(id, this.DCMMenuKey()) {
    return;
  };
  if !combo && this.DCMMenuIsOpen() && this.m_dcmMenu.IsTyping() && DCMTypable(id) {
    return;
  };
  if combo {
    this.m_dcmComboAt = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGame()));
  };
  this.DCMMenuToggle();
}

@wrapMethod(gameuiPhotoModeMenuController)
protected cb func OnPhotoModeFailedToOpenEvent() -> Bool {
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) && player.m_dcmComboAt > 0.0 && EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame())) - player.m_dcmComboAt < 1.0 {
    return true;
  };
  return wrappedMethod();
}

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
  if this.m_dcmMenuOpen && IsDefined(this.m_dcmMenu) && this.m_dcmMenu.IsOpen() {
    let type: gameinputActionType = ListenerAction.GetType(action);
    if this.m_dcmFocusWin && IsDefined(this.m_dcmSquad) && Equals(type, gameinputActionType.REPEAT) {
      this.m_dcmSquad.GameAction(ListenerAction.GetName(action), type, ListenerAction.GetValue(action));
    } else {
      this.m_dcmMenu.GameAction(ListenerAction.GetName(action), type, ListenerAction.GetValue(action));
    };
  };
  return wrappedMethod(action, consumer);
}

@wrapMethod(PauseMenuBackgroundGameController)
protected cb func OnInitialize() -> Bool {
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    player.m_dcmMenuBlocked = true;
  };
  return wrappedMethod();
}

@wrapMethod(PauseMenuBackgroundGameController)
protected cb func OnUninitialize() -> Bool {
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    player.m_dcmMenuBlocked = false;
    player.DCMCloseLayerMenu();
  };
  return wrappedMethod();
}

@wrapMethod(MenuHubGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    player.m_dcmInHub = true;
  };
  return result;
}

@wrapMethod(MenuHubGameController)
protected cb func OnUninitialize() -> Bool {
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    player.m_dcmInHub = false;
    player.DCMCloseLayerMenu();
  };
  return wrappedMethod();
}

@wrapMethod(gameuiInGameMenuGameController)
protected cb func OnHandleMenuInput(evt: ref<inkPointerEvent>) -> Bool {
  if DCMLayerBusy() {
    return false;
  };
  return wrappedMethod(evt);
}

@wrapMethod(PauseMenuGameController)
protected cb func OnGlobalRelease(e: ref<inkPointerEvent>) -> Bool {
  if DCMLayerBusy() {
    return false;
  };
  return wrappedMethod(e);
}

@wrapMethod(PauseMenuGameController)
protected cb func OnListRelease(e: ref<inkPointerEvent>) -> Bool {
  if DCMLayerBusy() {
    return false;
  };
  return wrappedMethod(e);
}

@wrapMethod(SingleplayerMenuGameController)
protected cb func OnGlobalRelease(e: ref<inkPointerEvent>) -> Bool {
  if DCMLayerBusy() {
    return false;
  };
  return wrappedMethod(e);
}

@wrapMethod(SingleplayerMenuGameController)
protected cb func OnListRelease(e: ref<inkPointerEvent>) -> Bool {
  if DCMLayerBusy() {
    return false;
  };
  return wrappedMethod(e);
}

@wrapMethod(DeathMenuGameController)
protected cb func OnInitialize() -> Bool {
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    player.m_dcmMenuBlocked = true;
  };
  return wrappedMethod();
}

@wrapMethod(DeathMenuGameController)
protected cb func OnUninitialize() -> Bool {
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    player.m_dcmMenuBlocked = false;
  };
  return wrappedMethod();
}
