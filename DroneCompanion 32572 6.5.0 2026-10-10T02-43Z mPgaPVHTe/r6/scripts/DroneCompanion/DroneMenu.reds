module DroneCompanion

import Codeware.UI.*

public struct DCRow {
  public let id: String;
  public let kind: String;
  public let label: String;
  public let value: String;
  public let icon: String;
  public let hint: String;
}

public class DCMenuPopup extends InGamePopup {
  protected let m_header: ref<InGamePopupHeader>;
  protected let m_footer: ref<InGamePopupFooter>;
  protected let m_content: ref<InGamePopupContent>;
  protected let m_tabBar: wref<inkHorizontalPanel>;
  protected let m_tabTexts: array<wref<inkText>>;
  protected let m_tabMarks: array<wref<inkRectangle>>;
  protected let m_tabs: array<String>;
  protected let m_tab: Int32;
  protected let m_mode: String = "rows";
  protected let m_listPanel: wref<inkVerticalPanel>;
  protected let m_rows: array<DCRow>;
  protected let m_rowLabels: array<wref<inkText>>;
  protected let m_rowValues: array<wref<inkText>>;
  protected let m_rowMarks: array<wref<inkWidget>>;
  protected let m_rowRings: array<wref<inkWidget>>;
  protected let m_rowTops: array<Float>;
  protected let m_contentHeight: Float;
  protected let m_sel: Int32;
  protected let m_scroll: Float;
  protected let m_payload: String;
  protected let m_owner: wref<PlayerPuppet>;
  protected let m_outer: wref<inkVerticalPanel>;
  protected let m_view: wref<inkScrollArea>;
  protected let m_scrollTrack: wref<inkRectangle>;
  protected let m_scrollThumb: wref<inkRectangle>;
  protected let m_hint: wref<inkText>;
  protected let m_scale: Float = 1.0;
  protected let m_accent: HDRColor;
  protected let m_hintLine: String;
  protected let m_rowBars: array<wref<inkRectangle>>;
  protected let m_accentKey: String;
  protected let m_hover: Int32;
  protected let m_rowHits: array<wref<inkWidget>>;
  protected let m_rowUses: array<wref<inkWidget>>;
  protected let m_gridBtn: Int32;
  protected let m_attached: Bool;
  protected let m_respecArmed: Bool;
  protected let m_pendingHints: String;
  protected let m_pushedContext: Bool;
  protected let m_lastInput: Float;
  protected let m_cellCol: array<Int32>;
  protected let m_cellRow: array<Int32>;
  protected let m_subBar: wref<inkHorizontalPanel>;
  protected let m_subTexts: array<wref<inkText>>;
  protected let m_subMarks: array<wref<inkRectangle>>;
  protected let m_subs: array<String>;
  protected let m_sub: Int32;
  protected let m_footerText: String;

  public func GetName() -> CName {
    return n"DCMenuPopup";
  }

  public func UseCursor() -> Bool {
    return true;
  }

  public func DCIsOpen() -> Bool {
    return this.m_attached || this.IsInitialized();
  }

  public func DCBind(player: ref<PlayerPuppet>) -> Void {
    this.m_owner = player;
  }

  protected func DCEmit(action: String) -> Void {
    if IsDefined(this.m_owner) {
      this.m_owner.DCEmit(action);
    };
  }

  protected func DCAccent() -> HDRColor {
    if StrLen(this.m_accentKey) > 0 {
      return this.m_accent;
    };
    return new HDRColor(0.88, 0.16, 0.14, 1.0);
  }

  protected func DCColorOf(kind: String, selected: Bool) -> HDRColor {
    if selected {
      return new HDRColor(1.0, 1.0, 1.0, 1.0);
    };
    if Equals(kind, "head") || Equals(kind, "unit") || Equals(kind, "group") {
      return this.DCAccent();
    };
    if Equals(kind, "warn") {
      return new HDRColor(1.0, 0.62, 0.20, 1.0);
    };
    if Equals(kind, "dim") {
      return new HDRColor(0.50, 0.50, 0.55, 1.0);
    };
    return new HDRColor(0.82, 0.82, 0.85, 1.0);
  }

  protected func DCApplyHints(line: String) -> Void {
    if Equals(line, this.m_hintLine) {
      return;
    };
    if !IsDefined(this.m_footer) {
      this.m_pendingHints = line;
      return;
    };
    this.m_hintLine = line;
    let hints: wref<ButtonHintsEx> = this.m_footer.GetHints();
    if !IsDefined(hints) {
      return;
    };
    hints.ClearButtonHints();
    let f: array<String> = StrSplit(line, "\t", true);
    let names: array<CName>;
    ArrayPush(names, n"click");
    ArrayPush(names, n"popup_navigate_right");
    ArrayPush(names, n"next_menu");
    ArrayPush(names, n"cancel");
    ArrayPush(names, n"next_sub_menu");
    let i: Int32 = 1;
    let kbm: Bool = IsDefined(this.m_owner) && this.m_owner.PlayerLastUsedKBM();
    while i < ArraySize(f) && i <= ArraySize(names) {
      if StrLen(f[i]) > 0 && !(kbm && Equals(names[i - 1], n"next_sub_menu")) {
        hints.AddButtonHint(names[i - 1], f[i]);
      };
      i += 1;
    };
  }

  protected func DCSetRespecPrompt(armed: Bool) -> Void {
    if !IsDefined(this.m_footer) {
      return;
    };
    let hints: wref<ButtonHintsEx> = this.m_footer.GetHints();
    if !IsDefined(hints) {
      return;
    };
    if armed {
      hints.RemoveButtonHint(n"next_menu");
      hints.AddButtonHint(n"next_menu", DroneCompanionText("Mod-DroneCompanion-L-respec_confirm"));
    } else {
      this.m_hintLine = "";
    };
  }

  protected func DCStripMark(value: String) -> String {
    if StrLen(value) > 0 && (Equals(StrLeft(value, 1), "!") || Equals(StrLeft(value, 1), "*")) {
      return StrRight(value, StrLen(value) - 1);
    };
    return value;
  }

  protected func DCValueTone(row: DCRow) -> Int32 {
    if Equals(row.kind, "toggle") {
      return Equals(row.value, "1") ? 2 : 3;
    };
    if Equals(row.kind, "btn") {
      if StrLen(row.value) > 0 && Equals(StrLeft(row.value, 1), "!") {
        return 1;
      };
      if StrLen(row.value) > 0 && Equals(StrLeft(row.value, 1), "*") {
        return 2;
      };
      return 0;
    };
    return 4;
  }

  protected func DCToneColor(tone: Int32, selected: Bool) -> HDRColor {
    if tone == 1 {
      return new HDRColor(1.00, 0.62, 0.20, 1.0);
    };
    if tone == 2 {
      return new HDRColor(0.30, 0.85, 0.35, 1.0);
    };
    if tone == 3 {
      return selected ? new HDRColor(0.82, 0.82, 0.85, 1.0) : new HDRColor(0.50, 0.50, 0.55, 1.0);
    };
    if tone == 0 {
      return new HDRColor(1.00, 0.82, 0.00, 1.0);
    };
    return selected ? new HDRColor(1.0, 1.0, 1.0, 1.0) : new HDRColor(0.82, 0.82, 0.85, 1.0);
  }

  protected func DCIsSelectable(kind: String) -> Bool {
    return Equals(kind, "btn") || Equals(kind, "toggle") || Equals(kind, "choice")
      || Equals(kind, "slider") || Equals(kind, "item") || Equals(kind, "cell")
      || Equals(kind, "gridbtn") || Equals(kind, "unit");
  }

  protected func DCIsWrapped(kind: String) -> Bool {
    return Equals(kind, "dim") || Equals(kind, "warn") || Equals(kind, "text");
  }

  protected func DCIsGrid() -> Bool {
    return Equals(this.m_mode, "grid");
  }

  protected func DCIsPicker() -> Bool {
    return Equals(this.m_mode, "picker");
  }

  protected func DCViewWidth() -> Float {
    if this.DCIsPicker() {
      return 1440.0;
    };
    return this.DCIsGrid() ? 2600.0 : 1940.0;
  }

  protected func DCViewHeight() -> Float {
    if this.DCIsPicker() {
      return 560.0;
    };
    return this.DCIsGrid() ? 1600.0 : 1390.0;
  }

  protected func DCS(value: Float) -> Float {
    return value * this.m_scale;
  }

  protected func DCFontSize(value: Int32) -> Int32 {
    return Cast<Int32>(MaxF(12.0, Cast<Float>(value) * this.m_scale));
  }

  protected func DCWrapWidth(row: DCRow) -> Float {
    let w: Float = this.DCViewWidth();
    return StrLen(row.value) > 0 ? w - 790.0 : w - 240.0;
  }

  protected func DCRowHeight(row: DCRow) -> Float {
    if Equals(row.kind, "head") || Equals(row.kind, "unit") {
      return this.DCS(96.0);
    };
    if Equals(row.kind, "hp") {
      return this.DCS(46.0);
    };
    if Equals(row.kind, "group") {
      return this.DCS(58.0);
    };
    if Equals(row.kind, "slider") && StrContains(row.value, "|") {
      return this.DCS(72.0);
    };
    if this.DCIsWrapped(row.kind) {
      let charWidth: Float = Cast<Float>(this.DCFontSize(38)) * 0.46;
      let raw: Int32 = Cast<Int32>(this.DCWrapWidth(row) / charWidth);
      let perLine: Int32 = raw < 8 ? 8 : raw;
      let lines: Int32 = (StrLen(row.label) / perLine) + 1;
      return this.DCS(46.0) * Cast<Float>(lines) + this.DCS(14.0);
    };
    return this.DCS(62.0);
  }

  protected func DCMakeText(size: Int32, parent: ref<inkCompoundWidget>) -> ref<inkText> {
    let text: ref<inkText> = new inkText();
    text.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    text.SetFontStyle(n"Medium");
    text.SetFontSize(size);
    text.SetFitToContent(true);
    text.SetVAlign(inkEVerticalAlign.Top);
    text.Reparent(parent);
    return text;
  }

  protected cb func OnCreate() {
    super.OnCreate();
    let grid: Bool = this.DCIsGrid();
    let picker: Bool = this.DCIsPicker();
    this.m_container.SetSize(grid ? Vector2(2900.0, 1700.0) : (picker ? Vector2(1620.0, 800.0) : Vector2(2320.0, 1360.0)));
    this.m_hover = -1;
    this.m_gridBtn = -1;

    let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();

    let pattern: ref<inkImage> = new inkImage();
    pattern.SetName(n"dcPattern");
    pattern.SetAtlasResource(ResRef.FromString("base\\gameplay\\gui\\fullscreen\\inventory\\atlas_inventory.inkatlas"));
    pattern.SetTexturePart(n"BLUEPRINT_3slot");
    pattern.SetBrushTileType(inkBrushTileType.Both);
    pattern.SetTileHAlign(inkEHorizontalAlign.Left);
    pattern.SetTileVAlign(inkEVerticalAlign.Top);
    pattern.SetAnchor(inkEAnchor.Fill);
    pattern.SetTintColor(new HDRColor(1.1761, 0.3809, 0.3476, 1.0));
    pattern.SetOpacity(0.03);
    pattern.Reparent(root);

    if !grid && !picker {
      this.m_header = InGamePopupHeader.Create();
      this.m_header.SetTitle("DRONE COMPANION");
      this.m_header.SetFluffLeft("");
      this.m_header.SetFluffRight("DRONECOMPANION");
      this.m_header.Reparent(this);
    };

    this.m_footer = InGamePopupFooter.Create();
    this.m_footer.SetFluffIcon(n"fluff_triangle2");
    this.m_footer.Reparent(this);

    if !picker {
      let footRoot: ref<inkWidget> = this.m_footer.GetRootWidget();
      if IsDefined(footRoot) {
        let fm: inkMargin = footRoot.GetMargin();
        footRoot.SetMargin(inkMargin(fm.left, fm.top, fm.right, fm.bottom - (grid ? 360.0 : 550.0)));
      };
    };

    this.m_content = InGamePopupContent.Create();
    this.m_content.Reparent(this);

    if picker {
      let contentRoot: ref<inkCompoundWidget> = this.m_content.GetRootCompoundWidget();
      let panel: ref<inkImage> = new inkImage();
      panel.SetAtlasResource(ResRef.FromString("base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas"));
      panel.SetTexturePart(n"cell_bg");
      panel.SetNineSliceScale(true);
      panel.SetAnchor(inkEAnchor.Fill);
      panel.SetTintColor(new HDRColor(0.02, 0.03, 0.04, 1.0));
      panel.SetOpacity(0.88);
      panel.Reparent(contentRoot);
      let frame: ref<inkImage> = new inkImage();
      frame.SetAtlasResource(ResRef.FromString("base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas"));
      frame.SetTexturePart(n"cell_fg");
      frame.SetNineSliceScale(true);
      frame.SetAnchor(inkEAnchor.Fill);
      frame.SetTintColor(this.DCAccent());
      frame.SetOpacity(0.30);
      frame.Reparent(contentRoot);
    };

    let outer: ref<inkVerticalPanel> = new inkVerticalPanel();
    outer.SetName(n"outer");
    outer.SetMargin(grid ? inkMargin(24.0, 40.0, 0.0, 0.0) : (picker ? inkMargin(48.0, 48.0, 0.0, 0.0) : inkMargin(24.0, 8.0, 0.0, 0.0)));
    outer.Reparent(this.m_content.GetRootCompoundWidget());

    if !grid && !picker {
      let tabBar: ref<inkHorizontalPanel> = new inkHorizontalPanel();
      tabBar.SetName(n"tabs");
      tabBar.SetMargin(inkMargin(0.0, 0.0, 0.0, 12.0));
      tabBar.Reparent(outer);
      this.m_tabBar = tabBar;

      let divider: ref<inkRectangle> = new inkRectangle();
      divider.SetSize(1900.0, 2.0);
      divider.SetTintColor(new HDRColor(0.70, 0.70, 0.75, 1.0));
      divider.SetOpacity(0.18);
      divider.SetMargin(inkMargin(0.0, 0.0, 0.0, 12.0));
      divider.Reparent(outer);

      let subSlot: ref<inkCanvas> = new inkCanvas();
      subSlot.SetSize(1900.0, 64.0);
      subSlot.Reparent(outer);
      let subBar: ref<inkHorizontalPanel> = new inkHorizontalPanel();
      subBar.SetName(n"subtabs");
      subBar.Reparent(subSlot);
      this.m_subBar = subBar;
    };

    let viewport: ref<inkCanvas> = new inkCanvas();
    viewport.SetSize(this.DCViewWidth() + 24.0, this.DCViewHeight());
    viewport.Reparent(outer);

    let view: ref<inkScrollArea> = new inkScrollArea();
    view.SetSize(Vector2(this.DCViewWidth(), this.DCViewHeight()));
    view.SetUseInternalMask(true);
    view.SetConstrainContentPosition(true);
    view.Reparent(viewport);
    this.m_view = view;

    let list: ref<inkVerticalPanel> = new inkVerticalPanel();
    list.SetName(n"list");
    list.Reparent(view);
    this.m_listPanel = list;

    let track: ref<inkRectangle> = new inkRectangle();
    track.SetSize(6.0, this.DCViewHeight());
    track.SetMargin(inkMargin(this.DCViewWidth() - 28.0, 0.0, 0.0, 0.0));
    track.SetTintColor(new HDRColor(0.70, 0.70, 0.75, 1.0));
    track.SetOpacity(0.10);
    track.Reparent(viewport);
    this.m_scrollTrack = track;

    let thumb: ref<inkRectangle> = new inkRectangle();
    thumb.SetSize(6.0, this.DCViewHeight());
    thumb.SetMargin(inkMargin(this.DCViewWidth() - 28.0, 0.0, 0.0, 0.0));
    thumb.SetTintColor(this.DCAccent());
    thumb.SetOpacity(0.0);
    thumb.Reparent(viewport);
    this.m_scrollThumb = thumb;

    let hintParent: ref<inkCompoundWidget> = outer;
    if !grid && !picker {
      let hintBox: ref<inkCanvas> = new inkCanvas();
      hintBox.SetSize(this.DCViewWidth(), 110.0);
      hintBox.SetMargin(inkMargin(0.0, this.DCViewHeight() + 12.0, 0.0, 0.0));
      hintBox.Reparent(viewport);
      let hintRule: ref<inkRectangle> = new inkRectangle();
      hintRule.SetSize(this.DCViewWidth() - 40.0, 2.0);
      hintRule.SetTintColor(new HDRColor(0.70, 0.70, 0.75, 1.0));
      hintRule.SetOpacity(0.14);
      hintRule.Reparent(hintBox);
      hintParent = hintBox;
    };
    let hint: ref<inkText> = this.DCMakeText(this.DCFontSize(!grid && !picker ? 34 : 30), hintParent);
    hint.SetMargin(inkMargin(!grid && !picker ? 26.0 : 0.0, 14.0, 0.0, 0.0));
    if !grid && !picker {
      hint.SetWrapping(true, this.DCViewWidth() - 80.0);
    };
    hint.SetTintColor(new HDRColor(0.78, 0.78, 0.82, 1.0));
    hint.SetOpacity(!grid && !picker ? 0.90 : 0.75);
    this.m_hint = hint;

    this.m_outer = outer;
    if StrLen(this.m_pendingHints) > 0 {
      let pending: String = this.m_pendingHints;
      this.m_pendingHints = "";
      this.DCApplyHints(pending);
    };
    this.DCRebuildTabs();
    this.DCRebuildSubs();
    this.DCRebuildRows();
  }

  public func DCSetState(payload: String) -> Void {
    if Equals(payload, this.m_payload) {
      return;
    };
    let tabsBefore: Int32 = ArraySize(this.m_tabs);
    let accentBefore: String = this.m_accentKey;
    let keepId: String = this.DCSelectedId();
    this.m_payload = payload;
    this.DCParse(payload);
    this.DCApplyScale();
    this.DCRestoreSelection(keepId);
    if tabsBefore != ArraySize(this.m_tabs) || NotEquals(accentBefore, this.m_accentKey) {
      this.DCRebuildTabs();
      if IsDefined(this.m_scrollThumb) {
        this.m_scrollThumb.SetTintColor(this.DCAccent());
      };
    };
    this.DCRebuildSubs();
    this.DCRebuildRows();
  }

  protected func DCParse(payload: String) -> Void {
    ArrayClear(this.m_rows);
    ArrayClear(this.m_subs);
    this.m_sub = 0;
    let lines: array<String> = StrSplit(payload, "\n");
    let i: Int32 = 0;
    while i < ArraySize(lines) {
      let f: array<String> = StrSplit(lines[i], "\t", true);
      if ArraySize(f) >= 2 {
        if Equals(f[0], "T") {
          ArrayClear(this.m_tabs);
          let t: Int32 = 1;
          while t < ArraySize(f) {
            ArrayPush(this.m_tabs, f[t]);
            t += 1;
          };
        };
        if Equals(f[0], "M") {
          this.m_mode = f[1];
        };
        if Equals(f[0], "A") {
          this.m_tab = StringToInt(f[1], 0);
        };
        if Equals(f[0], "U") {
          let u: Int32 = 1;
          while u < ArraySize(f) {
            ArrayPush(this.m_subs, f[u]);
            u += 1;
          };
        };
        if Equals(f[0], "B") {
          this.m_sub = StringToInt(f[1], 0);
        };
        if Equals(f[0], "F") {
          this.DCSetFooter(f[1]);
        };
        if Equals(f[0], "H") {
          this.DCApplyHints(lines[i]);
        };
        if Equals(f[0], "S") {
          this.m_scale = MaxF(0.6, MinF(2.0, StringToFloat(f[1], 1.0)));
          if this.DCIsGrid() {
            this.m_scale = MinF(this.m_scale, (this.DCViewHeight() - 40.0) / 1524.0);
          };
        };
        if Equals(f[0], "C") && ArraySize(f) >= 4 {
          this.m_accent = new HDRColor(StringToFloat(f[1], 0.88), StringToFloat(f[2], 0.16), StringToFloat(f[3], 0.14), 1.0);
          this.m_accentKey = lines[i];
        };
        if Equals(f[0], "R") && ArraySize(f) >= 4 {
          let row: DCRow;
          row.id = f[1];
          row.kind = f[2];
          row.label = f[3];
          row.value = ArraySize(f) >= 5 ? f[4] : "";
          row.icon = ArraySize(f) >= 6 ? f[5] : "";
          row.hint = ArraySize(f) >= 7 ? f[6] : "";
          ArrayPush(this.m_rows, row);
        };
      };
      i += 1;
    };
    this.DCClampSelection(1);
  }

  protected func DCApplyScale() -> Void {
    if IsDefined(this.m_hint) {
      this.m_hint.SetFontSize(this.DCFontSize(this.DCIsGrid() || this.DCIsPicker() ? 30 : 34));
    };
  }

  protected func DCSelectedId() -> String {
    if this.m_sel < 0 || this.m_sel >= ArraySize(this.m_rows) {
      return "";
    };
    return this.m_rows[this.m_sel].id;
  }

  protected func DCRestoreSelection(id: String) -> Void {
    if StrLen(id) == 0 {
      return;
    };
    let i: Int32 = 0;
    while i < ArraySize(this.m_rows) {
      if Equals(this.m_rows[i].id, id) {
        this.m_sel = i;
        return;
      };
      i += 1;
    };
  }

  protected func DCClampSelection(dir: Int32) -> Void {
    if ArraySize(this.m_rows) == 0 {
      this.m_sel = -1;
      return;
    };
    if this.m_sel < 0 {
      this.m_sel = 0;
    };
    if this.m_sel >= ArraySize(this.m_rows) {
      this.m_sel = ArraySize(this.m_rows) - 1;
    };
    let steps: Int32 = 0;
    while steps <= ArraySize(this.m_rows) {
      if this.DCIsSelectable(this.m_rows[this.m_sel].kind) {
        return;
      };
      this.m_sel += dir;
      if this.m_sel < 0 {
        this.m_sel = ArraySize(this.m_rows) - 1;
      };
      if this.m_sel >= ArraySize(this.m_rows) {
        this.m_sel = 0;
      };
      steps += 1;
    };
    this.m_sel = -1;
  }

  protected func DCRebuildTabs() -> Void {
    if !IsDefined(this.m_tabBar) {
      return;
    };
    this.m_tabBar.RemoveAllChildren();
    ArrayClear(this.m_tabTexts);
    ArrayClear(this.m_tabMarks);
    let i: Int32 = 0;
    while i < ArraySize(this.m_tabs) {
      let cell: ref<inkVerticalPanel> = new inkVerticalPanel();
      cell.SetMargin(inkMargin(0.0, 0.0, 64.0, 0.0));
      cell.Reparent(this.m_tabBar);

      let tab: ref<inkText> = this.DCMakeText(this.DCFontSize(46), cell);
      tab.SetHAlign(inkEHorizontalAlign.Center);
      tab.SetLetterCase(textLetterCase.UpperCase);
      tab.SetInteractive(true);
      tab.SetText(this.m_tabs[i]);
      ArrayPush(this.m_tabTexts, tab);

      let mark: ref<inkRectangle> = new inkRectangle();
      mark.SetSize(this.DCTabMarkWidth(i), 5.0);
      mark.SetHAlign(inkEHorizontalAlign.Center);
      mark.SetMargin(inkMargin(0.0, 8.0, 0.0, 0.0));
      mark.SetTintColor(this.DCAccent());
      mark.Reparent(cell);
      ArrayPush(this.m_tabMarks, mark);

      i += 1;
    };
    this.DCPaintTabs();
  }

  protected func DCRebuildSubs() -> Void {
    if !IsDefined(this.m_subBar) {
      return;
    };
    this.m_subBar.RemoveAllChildren();
    ArrayClear(this.m_subTexts);
    ArrayClear(this.m_subMarks);
    let i: Int32 = 0;
    while i < ArraySize(this.m_subs) {
      let cell: ref<inkVerticalPanel> = new inkVerticalPanel();
      cell.SetMargin(inkMargin(0.0, 0.0, 48.0, 0.0));
      cell.Reparent(this.m_subBar);

      let text: ref<inkText> = this.DCMakeText(this.DCFontSize(34), cell);
      text.SetHAlign(inkEHorizontalAlign.Center);
      text.SetInteractive(true);
      text.SetText(this.m_subs[i]);
      ArrayPush(this.m_subTexts, text);

      let mark: ref<inkRectangle> = new inkRectangle();
      mark.SetSize(this.DCSubMarkWidth(i), 3.0);
      mark.SetHAlign(inkEHorizontalAlign.Center);
      mark.SetMargin(inkMargin(0.0, 6.0, 0.0, 0.0));
      mark.SetTintColor(this.DCAccent());
      mark.Reparent(cell);
      ArrayPush(this.m_subMarks, mark);
      i += 1;
    };
    this.DCPaintSubs();
  }

  protected func DCSubMarkWidth(index: Int32) -> Float {
    if index < ArraySize(this.m_subTexts) && IsDefined(this.m_subTexts[index]) {
      let measured: Float = this.m_subTexts[index].GetDesiredSize().X;
      if measured > 1.0 {
        return measured + 8.0;
      };
    };
    return Cast<Float>(StrLen(this.m_subs[index])) * this.DCS(17.0) + 8.0;
  }

  protected func DCPaintSubs() -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.m_subTexts) {
      let active: Bool = i == this.m_sub;
      this.m_subMarks[i].SetSize(this.DCSubMarkWidth(i), 3.0);
      this.m_subTexts[i].SetTintColor(active ? this.DCAccent() : new HDRColor(0.70, 0.70, 0.75, 1.0));
      this.m_subTexts[i].SetOpacity(active ? 1.0 : 0.55);
      this.m_subMarks[i].SetOpacity(active ? 1.0 : 0.0);
      i += 1;
    };
  }

  protected func DCSwitchSub(dir: Int32) -> Void {
    let count: Int32 = ArraySize(this.m_subs);
    if count < 2 {
      return;
    };
    this.DCSelectSub((this.m_sub + dir + count) % count);
  }

  protected func DCSelectSub(index: Int32) -> Void {
    if index == this.m_sub || index < 0 || index >= ArraySize(this.m_subs) {
      return;
    };
    this.m_sub = index;
    this.m_sel = 0;
    this.m_scroll = 0.0;
    this.DCPaintSubs();
    this.DCEmit("sub:" + IntToString(index));
  }

  protected func DCUpdateHint() -> Void {
    if !IsDefined(this.m_hint) {
      return;
    };
    let index: Int32 = this.m_hover >= 0 ? this.m_hover : this.m_sel;
    let text: String = "";
    if index >= 0 && index < ArraySize(this.m_rows) {
      text = this.m_rows[index].hint;
    };
    this.m_hint.SetText(StrLen(text) > 0 ? text : this.m_footerText);
  }

  protected func DCTabMarkWidth(index: Int32) -> Float {
    if index < ArraySize(this.m_tabTexts) && IsDefined(this.m_tabTexts[index]) {
      let measured: Float = this.m_tabTexts[index].GetDesiredSize().X;
      if measured > 1.0 {
        return measured + 12.0;
      };
    };
    return Cast<Float>(StrLen(this.m_tabs[index])) * this.DCS(26.0) + 12.0;
  }

  protected func DCPaintTabs() -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.m_tabTexts) {
      this.m_tabMarks[i].SetSize(this.DCTabMarkWidth(i), 5.0);
      if i == this.m_tab {
        this.m_tabTexts[i].SetTintColor(this.DCAccent());
        this.m_tabTexts[i].SetOpacity(1.0);
        this.m_tabMarks[i].SetOpacity(1.0);
      } else {
        this.m_tabTexts[i].SetTintColor(new HDRColor(0.70, 0.70, 0.75, 1.0));
        this.m_tabTexts[i].SetOpacity(0.55);
        this.m_tabMarks[i].SetOpacity(0.0);
      };
      i += 1;
    };
  }


  protected func DCColColor(key: String) -> HDRColor {
    if Equals(key, "1") { return new HDRColor(1.1761, 0.3809, 0.3476, 1.0); };
    if Equals(key, "2") { return new HDRColor(0.556863, 0.788235, 0.427451, 1.0); };
    if Equals(key, "4") { return new HDRColor(1.0, 0.84, 0.40, 1.0); };
    return new HDRColor(0.368627, 0.964706, 1.0, 1.0);
  }

  protected func DCField(packed: String, index: Int32) -> String {
    let parts: array<String> = StrSplit(packed, "|");
    if index < ArraySize(parts) {
      return parts[index];
    };
    return "";
  }

  protected func DCCanBuy(index: Int32) -> Bool {
    if index < 0 || index >= ArraySize(this.m_rows) {
      return false;
    };
    if NotEquals(this.m_rows[index].kind, "cell") {
      return false;
    };
    let rank: Int32 = StringToInt(this.DCField(this.m_rows[index].value, 0), 0);
    let max: Int32 = StringToInt(this.DCField(this.m_rows[index].value, 1), 3);
    return rank < max;
  }

  protected func DCPerkKey(id: String) -> String {
    let parts: array<String> = StrSplit(id, "|");
    if ArraySize(parts) >= 2 {
      return parts[1];
    };
    return id;
  }

  protected func DCIconAtlas(key: String) -> String {
    if Equals(key, "armor") || Equals(key, "quickfix") {
      return "base\\gameplay\\gui\\common\\icons\\attributes_icons.inkatlas";
    };
    if Equals(key, "damage") || Equals(key, "repair") {
      return "base\\gameplay\\gui\\common\\icons\\atlas_damage_types_icons.inkatlas";
    };
    if Equals(key, "overload") || Equals(key, "rescue") || Equals(key, "range")
      || Equals(key, "bond") {
      return "base\\gameplay\\gui\\common\\icons\\quickhacks_icons.inkatlas";
    };
    return "base\\gameplay\\gui\\fullscreen\\perks\\atlas_perks.inkatlas";
  }

  protected func DCIconPart(key: String) -> CName {
    if Equals(key, "armor") { return n"ico_body"; };
    if Equals(key, "damage") { return n"icon_physical"; };
    if Equals(key, "overload") { return n"OverLoad"; };
    if Equals(key, "repair") { return n"icon_health"; };
    if Equals(key, "quickfix") { return n"skill_engineering"; };
    if Equals(key, "rescue") { return n"CommunicationCallIn"; };
    if Equals(key, "range") { return n"Ping"; };
    if Equals(key, "bond") { return n"TakeControl"; };
    return n"ico_reset";
  }

  protected func DCOpt(raw: String) -> String {
    if Equals(raw, "-") {
      return "";
    };
    return raw;
  }

  protected func DCPips(rank: Int32, max: Int32, eff: Int32) -> String {
    let out: String = "";
    let i: Int32 = 0;
    while i < max {
      if i < rank {
        out += "[x]";
      } else {
        if i < eff { out += "[+]"; } else { out += "[ ]"; };
      };
      i += 1;
    };
    return out;
  }

  protected func DCCenterWrap(text: ref<inkText>, width: Float) -> Void {
    text.SetWrapping(true, width);
    text.SetJustificationType(textJustificationType.Center);
  }

  protected func DCRebuildGrid() -> Void {
    this.m_listPanel.RemoveAllChildren();
    this.m_hover = -1;
    ArrayClear(this.m_rowLabels);
    ArrayClear(this.m_rowValues);
    ArrayClear(this.m_rowMarks);
    ArrayClear(this.m_rowTops);
    ArrayClear(this.m_rowHits);
    ArrayClear(this.m_rowUses);
    this.m_gridBtn = -1;
    ArrayClear(this.m_cellCol);
    ArrayClear(this.m_cellRow);
    this.m_contentHeight = 0.0;

    let colCount: Int32 = 0;
    let countedCol: String = "";
    let k: Int32 = 0;
    while k < ArraySize(this.m_rows) {
      if Equals(this.m_rows[k].kind, "cell") {
        let key: String = this.DCField(this.m_rows[k].value, 3);
        if NotEquals(key, countedCol) {
          countedCol = key;
          colCount += 1;
        };
      };
      k += 1;
    };
    let colGap: Float = this.DCS(40.0);
    let cellW: Float = MinF(this.DCS(560.0), (this.DCViewWidth() - 60.0) / Cast<Float>(Max(colCount, 1)) - colGap);
    let textW: Float = cellW - this.DCS(24.0);
    let cellH: Float = this.DCS(420.0);
    let nodeSize: Float = this.DCS(152.0);
    let gap: Float = this.DCS(48.0);
    let perkAtlas: String = "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas";
    let colStrip: ref<inkHorizontalPanel>;
    let colPanel: ref<inkVerticalPanel>;
    let lastCol: String = "";
    let colIdx: Int32 = -1;
    let rowInCol: Int32 = 0;

    let i: Int32 = 0;
    while i < ArraySize(this.m_rows) {
      let row: DCRow = this.m_rows[i];
      ArrayPush(this.m_rowTops, this.m_contentHeight);

      if Equals(row.kind, "cell") {
        let colKey: String = this.DCField(row.value, 3);
        if !IsDefined(colStrip) {
          colStrip = new inkHorizontalPanel();
          colStrip.SetHAlign(inkEHorizontalAlign.Center);
          colStrip.SetMargin(inkMargin(0.0, this.DCS(10.0), 0.0, 0.0));
          colStrip.Reparent(this.m_listPanel);
        };
        if NotEquals(colKey, lastCol) {
          lastCol = colKey;
          colIdx += 1;
          rowInCol = 0;
          colPanel = new inkVerticalPanel();
          colPanel.SetMargin(inkMargin(0.0, 0.0, colGap, 0.0));
          colPanel.Reparent(colStrip);

          let colHead: ref<inkText> = this.DCMakeText(this.DCFontSize(38), colPanel);
          colHead.SetText(this.DCOpt(this.DCField(row.value, 6)));
          colHead.SetLetterCase(textLetterCase.UpperCase);
          colHead.SetTintColor(this.DCColColor(colKey));
          colHead.SetHAlign(inkEHorizontalAlign.Center);
          colHead.SetMargin(inkMargin(0.0, this.DCS(10.0), 0.0, this.DCS(4.0)));

          let fwCount: Int32 = StringToInt(this.DCOpt(this.DCField(row.value, 7)), 0);
          let colTag: ref<inkText> = this.DCMakeText(this.DCFontSize(24), colPanel);
          colTag.SetText(DroneCompanionText("Mod-DroneCompanion-L-fw_tag") + " x" + IntToString(fwCount));
          colTag.SetTintColor(this.DCColColor(colKey));
          colTag.SetOpacity(fwCount > 0 ? 0.85 : 0.30);
          colTag.SetHAlign(inkEHorizontalAlign.Center);
          colTag.SetMargin(inkMargin(0.0, 0.0, 0.0, this.DCS(18.0)));
        };

        ArrayPush(this.m_cellCol, colIdx);
        ArrayPush(this.m_cellRow, rowInCol);

        let cell: ref<inkCanvas> = new inkCanvas();
        cell.SetSize(cellW, cellH);
        cell.SetMargin(inkMargin(0.0, 0.0, 0.0, gap));
        cell.SetInteractive(true);
        cell.Reparent(colPanel);
        cell.RegisterToCallback(n"OnEnter", this, n"OnDCRowEnter");
        cell.RegisterToCallback(n"OnLeave", this, n"OnDCRowLeave");
        cell.RegisterToCallback(n"OnRelease", this, n"OnDCRowClick");
        ArrayPush(this.m_rowHits, cell);

        let rank: Int32 = StringToInt(this.DCField(row.value, 0), 0);
        let max: Int32 = StringToInt(this.DCField(row.value, 1), 3);
        let eff: Int32 = StringToInt(this.DCField(row.value, 2), 0);
        let colColor: HDRColor = this.DCColColor(colKey);
        let owned: Bool = rank > 0;
        let fill: Float = max > 0 ? MinF(1.0, Cast<Float>(rank) / Cast<Float>(max)) : 0.0;

        let stack: ref<inkVerticalPanel> = new inkVerticalPanel();
        stack.SetAnchor(inkEAnchor.TopCenter);
        stack.SetAnchorPoint(new Vector2(0.5, 0.0));
        stack.SetFitToContent(true);
        stack.Reparent(cell);

        let node: ref<inkCanvas> = new inkCanvas();
        node.SetSize(nodeSize, nodeSize);
        node.SetHAlign(inkEHorizontalAlign.Center);
        node.Reparent(stack);

        let nodeBg: ref<inkImage> = new inkImage();
        nodeBg.SetAtlasResource(ResRef.FromString(perkAtlas));
        nodeBg.SetTexturePart(n"cell_bg");
        nodeBg.SetNineSliceScale(true);
        nodeBg.SetAnchor(inkEAnchor.Fill);
        nodeBg.SetTintColor(colColor);
        nodeBg.SetOpacity(0.12);
        nodeBg.Reparent(node);

        if fill > 0.0 && max > 0 {
          let nodeFill: ref<inkRectangle> = new inkRectangle();
          nodeFill.SetAnchor(inkEAnchor.BottomLeft);
          nodeFill.SetAnchorPoint(new Vector2(0.0, 1.0));
          nodeFill.SetSize(new Vector2(nodeSize, nodeSize * fill));
          nodeFill.SetTintColor(colColor);
          nodeFill.SetOpacity(0.85);
          nodeFill.Reparent(node);
        };

        let nodeRing: ref<inkImage> = new inkImage();
        nodeRing.SetAtlasResource(ResRef.FromString(perkAtlas));
        nodeRing.SetTexturePart(n"cell_fg");
        nodeRing.SetNineSliceScale(true);
        nodeRing.SetAnchor(inkEAnchor.Centered);
        nodeRing.SetAnchorPoint(new Vector2(0.5, 0.5));
        nodeRing.SetSize(new Vector2(nodeSize + this.DCS(18.0), nodeSize + this.DCS(18.0)));
        nodeRing.SetTintColor(colColor);
        nodeRing.SetOpacity(0.0);
        nodeRing.Reparent(node);
        ArrayPush(this.m_rowUses, nodeRing);

        let nodeGlow: ref<inkImage> = new inkImage();
        nodeGlow.SetAtlasResource(ResRef.FromString(perkAtlas));
        nodeGlow.SetTexturePart(n"cell_fg");
        nodeGlow.SetNineSliceScale(true);
        nodeGlow.SetAnchor(inkEAnchor.Fill);
        nodeGlow.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
        nodeGlow.SetOpacity(0.0);
        nodeGlow.Reparent(node);
        ArrayPush(this.m_rowMarks, nodeGlow);

        let nodeFg: ref<inkImage> = new inkImage();
        nodeFg.SetAtlasResource(ResRef.FromString(perkAtlas));
        nodeFg.SetTexturePart(n"cell_fg");
        nodeFg.SetNineSliceScale(true);
        nodeFg.SetAnchor(inkEAnchor.Fill);
        nodeFg.SetTintColor(colColor);
        nodeFg.SetOpacity(max > 0 ? 0.45 + 0.55 * fill : 0.95);
        nodeFg.Reparent(node);

        let nodeIcon: ref<inkImage> = new inkImage();
        let iconKey: String = this.DCPerkKey(row.id);
        nodeIcon.SetAtlasResource(ResRef.FromString(this.DCIconAtlas(iconKey)));
        nodeIcon.SetTexturePart(this.DCIconPart(iconKey));
        nodeIcon.SetSize(new Vector2(nodeSize * (max > 0 ? 0.46 : 0.52), nodeSize * (max > 0 ? 0.46 : 0.52)));
        nodeIcon.SetAnchor(inkEAnchor.Centered);
        nodeIcon.SetAnchorPoint(new Vector2(0.5, 0.5));
        nodeIcon.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
        nodeIcon.SetOpacity(max > 0 ? 0.75 + 0.25 * fill : 0.95);
        nodeIcon.Reparent(node);

        if max > 0 {
        let tally: ref<inkCanvas> = new inkCanvas();
        tally.SetSize(nodeSize * 0.46, this.DCS(34.0));
        tally.SetAnchor(inkEAnchor.BottomCenter);
        tally.SetAnchorPoint(new Vector2(0.5, 1.0));
        tally.SetMargin(inkMargin(0.0, 0.0, 0.0, this.DCS(-6.0)));
        tally.Reparent(node);

        let tallyBg: ref<inkRectangle> = new inkRectangle();
        tallyBg.SetAnchor(inkEAnchor.Fill);
        tallyBg.SetTintColor(new HDRColor(0.05, 0.06, 0.09, 1.0));
        tallyBg.SetOpacity(0.95);
        tallyBg.Reparent(tally);

        let tallyText: ref<inkText> = this.DCMakeText(this.DCFontSize(26), tally);
        tallyText.SetText(IntToString(rank) + "/" + IntToString(max));
        tallyText.SetTintColor(colColor);
        tallyText.SetOpacity(owned ? 1.0 : 0.55);
        tallyText.SetAnchor(inkEAnchor.Centered);
        tallyText.SetAnchorPoint(new Vector2(0.5, 0.5));
        tallyText.SetHAlign(inkEHorizontalAlign.Center);
        tallyText.SetVAlign(inkEVerticalAlign.Center);
        };

        let name: ref<inkText> = this.DCMakeText(this.DCFontSize(34), stack);
        name.SetText(row.label);
        name.SetLetterCase(textLetterCase.UpperCase);
        name.SetHAlign(inkEHorizontalAlign.Center);
        this.DCCenterWrap(name, textW);
        name.SetMargin(inkMargin(0.0, this.DCS(12.0), 0.0, 0.0));
        ArrayPush(this.m_rowLabels, name);

        let now: ref<inkText> = this.DCMakeText(this.DCFontSize(28), stack);
        now.SetText(this.DCField(row.value, 4));
        now.SetTintColor(colColor);
        now.SetHAlign(inkEHorizontalAlign.Center);
        this.DCCenterWrap(now, textW);
        now.SetMargin(inkMargin(0.0, this.DCS(6.0), 0.0, 0.0));
        ArrayPush(this.m_rowValues, now);

        let nxt: String = this.DCOpt(this.DCField(row.value, 5));
        if StrLen(nxt) > 0 {
          let next: ref<inkText> = this.DCMakeText(this.DCFontSize(24), stack);
          next.SetText("-> " + nxt);
          next.SetHAlign(inkEHorizontalAlign.Center);
          this.DCCenterWrap(next, textW);
          next.SetOpacity(0.50);
          next.SetMargin(inkMargin(0.0, this.DCS(4.0), 0.0, 0.0));
        };

        let total: String = this.DCOpt(this.DCField(row.value, 8));
        if StrLen(total) > 0 {
          let eft: ref<inkText> = this.DCMakeText(this.DCFontSize(24), stack);
          eft.SetText(total);
          eft.SetTintColor(new HDRColor(1.1192, 0.8441, 0.2565, 1.0));
          eft.SetHAlign(inkEHorizontalAlign.Center);
          this.DCCenterWrap(eft, textW);
          eft.SetMargin(inkMargin(0.0, this.DCS(4.0), 0.0, 0.0));
        };

        rowInCol += 1;
      } else if Equals(row.kind, "gridhead") {
        ArrayPush(this.m_cellCol, -1);
        ArrayPush(this.m_cellRow, -1);
        ArrayPush(this.m_rowHits, null);
        ArrayPush(this.m_rowUses, null);

        let bar: ref<inkCanvas> = new inkCanvas();
        bar.SetHAlign(inkEHorizontalAlign.Center);
        bar.SetSize(this.DCViewWidth(), this.DCS(72.0));
        bar.SetMargin(inkMargin(0.0, 0.0, 0.0, this.DCS(4.0)));
        bar.Reparent(this.m_listPanel);
        this.m_contentHeight += this.DCS(112.0);

        let headMark: ref<inkRectangle> = new inkRectangle();
        headMark.SetSize(this.DCViewWidth(), this.DCS(72.0));
        headMark.SetOpacity(0.0);
        headMark.Reparent(bar);
        ArrayPush(this.m_rowMarks, headMark);

        let cyan: HDRColor = new HDRColor(0.368627, 0.964706, 1.0, 1.0);
        let gold: HDRColor = new HDRColor(1.1192, 0.8441, 0.2565, 1.0);

        let left: ref<inkHorizontalPanel> = new inkHorizontalPanel();
        left.SetAnchor(inkEAnchor.CenterLeft);
        left.SetAnchorPoint(new Vector2(0.0, 0.5));
        left.SetFitToContent(true);
        left.SetChildMargin(inkMargin(0.0, 0.0, this.DCS(12.0), 0.0));
        left.Reparent(bar);

        let availText: ref<inkText> = this.DCMakeText(this.DCFontSize(48), left);
        availText.SetText(this.DCField(row.value, 0));
        availText.SetTintColor(cyan);
        availText.SetVAlign(inkEVerticalAlign.Center);
        ArrayPush(this.m_rowLabels, availText);

        let availIcon: ref<inkImage> = new inkImage();
        availIcon.SetAtlasResource(ResRef.FromString("base\\gameplay\\gui\\fullscreen\\perks\\atlas_perks.inkatlas"));
        availIcon.SetTexturePart(n"ico_points_perks");
        availIcon.SetSize(new Vector2(this.DCS(48.0), this.DCS(48.0)));
        availIcon.SetTintColor(cyan);
        availIcon.SetVAlign(inkEVerticalAlign.Center);
        availIcon.Reparent(left);

        let availLabel: ref<inkText> = this.DCMakeText(this.DCFontSize(34), left);
        availLabel.SetText(DroneCompanionText("Mod-DroneCompanion-L-hd_points"));
        availLabel.SetTintColor(cyan);
        availLabel.SetVAlign(inkEVerticalAlign.Center);

        let mid: ref<inkVerticalPanel> = new inkVerticalPanel();
        mid.SetAnchor(inkEAnchor.Centered);
        mid.SetAnchorPoint(new Vector2(0.5, 0.5));
        mid.SetFitToContent(true);
        mid.Reparent(bar);

        let midRow: ref<inkHorizontalPanel> = new inkHorizontalPanel();
        midRow.SetFitToContent(true);
        midRow.SetHAlign(inkEHorizontalAlign.Center);
        midRow.SetChildMargin(inkMargin(0.0, 0.0, this.DCS(12.0), 0.0));
        midRow.Reparent(mid);

        let midIcon: ref<inkImage> = new inkImage();
        midIcon.SetAtlasResource(ResRef.FromString("dronecompanion\\gui\\dc_icons.inkatlas"));
        midIcon.SetTexturePart(n"dc_filter");
        midIcon.SetSize(new Vector2(this.DCS(44.0), this.DCS(44.0)));
        midIcon.SetTintColor(cyan);
        midIcon.SetVAlign(inkEVerticalAlign.Center);
        midIcon.Reparent(midRow);

        let midText: ref<inkText> = this.DCMakeText(this.DCFontSize(44), midRow);
        midText.SetText(DroneCompanionText("Mod-DroneCompanion-L-hd_title"));
        midText.SetLetterCase(textLetterCase.UpperCase);
        midText.SetTintColor(cyan);
        midText.SetVAlign(inkEVerticalAlign.Center);

        let midTotal: ref<inkText> = this.DCMakeText(this.DCFontSize(44), midRow);
        midTotal.SetText(this.DCField(row.value, 1));
        midTotal.SetTintColor(cyan);
        midTotal.SetVAlign(inkEVerticalAlign.Center);
        ArrayPush(this.m_rowValues, midTotal);

        let midLine: ref<inkRectangle> = new inkRectangle();
        midLine.SetSize(this.DCS(360.0), this.DCS(4.0));
        midLine.SetHAlign(inkEHorizontalAlign.Center);
        midLine.SetMargin(inkMargin(0.0, this.DCS(6.0), 0.0, 0.0));
        midLine.SetTintColor(cyan);
        midLine.Reparent(mid);

        let right: ref<inkHorizontalPanel> = new inkHorizontalPanel();
        right.SetAnchor(inkEAnchor.CenterRight);
        right.SetAnchorPoint(new Vector2(1.0, 0.5));
        right.SetHAlign(inkEHorizontalAlign.Right);
        right.SetFitToContent(true);
        right.SetChildMargin(inkMargin(0.0, 0.0, this.DCS(12.0), 0.0));
        right.Reparent(bar);

        let fwText: ref<inkText> = this.DCMakeText(this.DCFontSize(48), right);
        fwText.SetText(this.DCField(row.value, 2));
        fwText.SetTintColor(gold);
        fwText.SetVAlign(inkEVerticalAlign.Center);

        let fwIcon: ref<inkImage> = new inkImage();
        fwIcon.SetAtlasResource(ResRef.FromString("base\\gameplay\\gui\\fullscreen\\perks\\atlas_perks.inkatlas"));
        fwIcon.SetTexturePart(n"ico_points_spy");
        fwIcon.SetSize(new Vector2(this.DCS(48.0), this.DCS(48.0)));
        fwIcon.SetTintColor(gold);
        fwIcon.SetVAlign(inkEVerticalAlign.Center);
        fwIcon.Reparent(right);

        let fwLabel: ref<inkText> = this.DCMakeText(this.DCFontSize(34), right);
        fwLabel.SetText(DroneCompanionText("Mod-DroneCompanion-L-hd_firmware"));
        fwLabel.SetTintColor(gold);
        fwLabel.SetVAlign(inkEVerticalAlign.Center);

        let sep: ref<inkRectangle> = new inkRectangle();
        sep.SetHAlign(inkEHorizontalAlign.Center);
        sep.SetSize(this.DCViewWidth(), this.DCS(3.0));
        sep.SetMargin(inkMargin(0.0, this.DCS(4.0), 0.0, this.DCS(10.0)));
        sep.SetTintColor(new HDRColor(0.6, 0.1, 0.1, 1.0));
        sep.Reparent(this.m_listPanel);
      } else if Equals(row.kind, "gridbtn") {
        ArrayPush(this.m_cellCol, -1);
        ArrayPush(this.m_cellRow, -1);
        ArrayPush(this.m_rowUses, null);
        this.m_gridBtn = i;

        let btn: ref<inkCanvas> = new inkCanvas();
        btn.SetHAlign(inkEHorizontalAlign.Center);
        btn.SetSize(this.DCS(420.0), this.DCS(64.0));
        btn.SetMargin(inkMargin(0.0, this.DCS(16.0), 0.0, this.DCS(8.0)));
        btn.SetInteractive(true);
        btn.Reparent(this.m_listPanel);
        btn.RegisterToCallback(n"OnEnter", this, n"OnDCRowEnter");
        btn.RegisterToCallback(n"OnLeave", this, n"OnDCRowLeave");
        btn.RegisterToCallback(n"OnRelease", this, n"OnDCRowClick");
        ArrayPush(this.m_rowHits, btn);
        this.m_contentHeight += this.DCS(88.0);

        let btnMark: ref<inkRectangle> = new inkRectangle();
        btnMark.SetSize(this.DCS(420.0), this.DCS(64.0));
        btnMark.SetTintColor(this.DCAccent());
        btnMark.SetOpacity(0.0);
        btnMark.Reparent(btn);
        ArrayPush(this.m_rowMarks, btnMark);

        let btnBack: ref<inkRectangle> = new inkRectangle();
        btnBack.SetSize(this.DCS(414.0), this.DCS(58.0));
        btnBack.SetMargin(inkMargin(this.DCS(3.0), this.DCS(3.0), 0.0, 0.0));
        btnBack.SetTintColor(new HDRColor(0.05, 0.06, 0.09, 1.0));
        btnBack.SetOpacity(0.97);
        btnBack.Reparent(btn);

        let btnText: ref<inkText> = this.DCMakeText(this.DCFontSize(32), btn);
        btnText.SetText(row.label);
        btnText.SetLetterCase(textLetterCase.UpperCase);
        btnText.SetTintColor(this.DCAccent());
        btnText.SetAnchor(inkEAnchor.Centered);
        btnText.SetAnchorPoint(new Vector2(0.5, 0.5));
        btnText.SetHAlign(inkEHorizontalAlign.Center);
        btnText.SetVAlign(inkEVerticalAlign.Center);
        ArrayPush(this.m_rowLabels, btnText);

        let btnSpacer: ref<inkText> = this.DCMakeText(this.DCFontSize(30), btn);
        btnSpacer.SetOpacity(0.0);
        ArrayPush(this.m_rowValues, btnSpacer);
      } else {
        ArrayPush(this.m_cellCol, -1);
        ArrayPush(this.m_cellRow, -1);
        ArrayPush(this.m_rowHits, null);
        ArrayPush(this.m_rowUses, null);

        let bar: ref<inkCanvas> = new inkCanvas();
        bar.SetHAlign(inkEHorizontalAlign.Center);
        bar.SetSize(this.DCViewWidth(), this.DCS(56.0));
        bar.SetMargin(inkMargin(0.0, this.DCS(10.0), 0.0, 0.0));
        bar.Reparent(this.m_listPanel);
        this.m_contentHeight += this.DCS(66.0);

        let mark2: ref<inkRectangle> = new inkRectangle();
        mark2.SetSize(this.DCViewWidth(), this.DCS(56.0));
        mark2.SetOpacity(0.0);
        mark2.Reparent(bar);
        ArrayPush(this.m_rowMarks, mark2);

        let head: ref<inkText> = this.DCMakeText(this.DCFontSize(Equals(row.kind, "gridhead") ? 42 : 28), bar);
        head.SetText(row.label);
        head.SetTintColor(Equals(row.kind, "gridhead") ? this.DCAccent() : new HDRColor(0.70, 0.70, 0.75, 1.0));
        ArrayPush(this.m_rowLabels, head);

        let spacer: ref<inkText> = this.DCMakeText(this.DCFontSize(30), bar);
        spacer.SetOpacity(0.0);
        ArrayPush(this.m_rowValues, spacer);
      };
      i += 1;
    };
    this.m_contentHeight += (cellH + gap) * 3.0 + this.DCS(120.0);
    if IsDefined(this.m_scrollTrack) {
      this.m_scrollTrack.SetVisible(false);
    };
    if IsDefined(this.m_scrollThumb) {
      this.m_scrollThumb.SetVisible(false);
    };
    if this.m_sel < 0 || this.m_sel >= ArraySize(this.m_cellCol) || this.m_cellCol[this.m_sel] < 0 {
      let first: Int32 = this.DCFindCell(0, 0);
      if first >= 0 {
        this.m_sel = first;
      };
    };
    this.DCPaintRows();
  }

  protected func DCFindCell(col: Int32, row: Int32) -> Int32 {
    let i: Int32 = 0;
    while i < ArraySize(this.m_cellCol) {
      if this.m_cellCol[i] == col && this.m_cellRow[i] == row {
        return i;
      };
      i += 1;
    };
    return -1;
  }

  protected func DCColLen(col: Int32) -> Int32 {
    let n: Int32 = 0;
    let i: Int32 = 0;
    while i < ArraySize(this.m_cellCol) {
      if this.m_cellCol[i] == col {
        n += 1;
      };
      i += 1;
    };
    return n;
  }

  protected func DCGridMove(dCol: Int32, dRow: Int32) -> Void {
    if this.m_sel < 0 || this.m_sel >= ArraySize(this.m_cellCol) {
      return;
    };
    if this.m_sel == this.m_gridBtn && this.m_gridBtn >= 0 {
      if dRow < 0 {
        let back: Int32 = this.DCFindCell(0, this.DCColLen(0) - 1);
        if back >= 0 {
          this.m_sel = back;
          this.DCPaintRows();
        };
      };
      return;
    };
    let col: Int32 = this.m_cellCol[this.m_sel];
    let row: Int32 = this.m_cellRow[this.m_sel];
    if col < 0 {
      let first: Int32 = this.DCFindCell(0, 0);
      if first >= 0 {
        this.m_sel = first;
        this.DCPaintRows();
      };
      return;
    };

    if dRow != 0 {
      let len: Int32 = this.DCColLen(col);
      row += dRow;
      if row >= len && this.m_gridBtn >= 0 {
        this.m_sel = this.m_gridBtn;
        this.DCPaintRows();
        return;
      };
      if row < 0 {
        row = len - 1;
      };
      if row >= len {
        row = 0;
      };
    };
    if dCol != 0 {
      let tries: Int32 = 0;
      while tries < 3 {
        col += dCol;
        if col < 0 {
          col = 2;
        };
        if col > 2 {
          col = 0;
        };
        if this.DCColLen(col) > 0 {
          tries = 3;
        } else {
          tries += 1;
        };
      };
      let len2: Int32 = this.DCColLen(col);
      if row >= len2 {
        row = len2 - 1;
      };
    };

    let target: Int32 = this.DCFindCell(col, row);
    if target < 0 {
      return;
    };
    this.m_sel = target;
    this.DCPaintRows();
    let id: String = this.DCSelectedId();
    if StrLen(id) > 0 {
      this.DCEmit("sel:" + id);
    };
  }

  protected func DCRebuildRows() -> Void {
    if !IsDefined(this.m_listPanel) {
      return;
    };
    if Equals(this.m_mode, "grid") {
      this.DCRebuildGrid();
      return;
    };
    this.m_listPanel.RemoveAllChildren();
    this.m_hover = -1;
    ArrayClear(this.m_rowLabels);
    ArrayClear(this.m_rowValues);
    ArrayClear(this.m_rowMarks);
    ArrayClear(this.m_rowRings);
    ArrayClear(this.m_rowBars);
    ArrayClear(this.m_rowHits);
    ArrayClear(this.m_rowUses);
    ArrayClear(this.m_rowTops);
    this.m_contentHeight = 0.0;

    let stripe: Int32 = 0;
    let i: Int32 = 0;
    while i < ArraySize(this.m_rows) {
      let row: DCRow = this.m_rows[i];
      let height: Float = this.DCRowHeight(row);
      let rowW: Float = this.DCViewWidth() - 40.0;
      ArrayPush(this.m_rowTops, this.m_contentHeight);
      this.m_contentHeight += height;

      let isHead: Bool = Equals(row.kind, "head") || Equals(row.kind, "unit");
      let topPad: Float = this.DCS(isHead ? 24.0 : 12.0);

      let canvas: ref<inkCanvas> = new inkCanvas();
      canvas.SetSize(rowW, height);
      canvas.Reparent(this.m_listPanel);

      if isHead || Equals(row.kind, "group") {
        stripe = 0;
      } else {
        if this.DCIsSelectable(row.kind) {
          stripe += 1;
          if stripe % 2 == 0 {
            let band: ref<inkRectangle> = new inkRectangle();
            band.SetSize(rowW - 40.0, height);
            band.SetTintColor(new HDRColor(0.80, 0.82, 0.88, 1.0));
            band.SetOpacity(0.035);
            band.Reparent(canvas);
          };
        };
      };

      let shapeAtlas: String = "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas";
      let mark: ref<inkImage> = new inkImage();
      mark.SetAtlasResource(ResRef.FromString(shapeAtlas));
      mark.SetTexturePart(n"cell_bg");
      mark.SetNineSliceScale(true);
      mark.SetSize(rowW, height);
      mark.SetTintColor(this.DCAccent());
      mark.SetOpacity(0.0);
      mark.Reparent(canvas);
      ArrayPush(this.m_rowMarks, mark);

      let ring: ref<inkImage> = new inkImage();
      ring.SetAtlasResource(ResRef.FromString(shapeAtlas));
      ring.SetTexturePart(n"cell_fg");
      ring.SetNineSliceScale(true);
      ring.SetSize(rowW, height);
      ring.SetTintColor(this.DCAccent());
      ring.SetOpacity(0.0);
      ring.Reparent(canvas);
      ArrayPush(this.m_rowRings, ring);

      let bar: ref<inkRectangle> = new inkRectangle();
      bar.SetSize(6.0, height);
      bar.SetAnchor(inkEAnchor.LeftFillVerticaly);
      bar.SetTintColor(this.DCAccent());
      bar.SetOpacity(0.0);
      bar.Reparent(canvas);
      ArrayPush(this.m_rowBars, bar);

      if isHead {
        let headBg: ref<inkImage> = new inkImage();
        headBg.SetAtlasResource(ResRef.FromString(shapeAtlas));
        headBg.SetTexturePart(n"cell_bg");
        headBg.SetNineSliceScale(true);
        headBg.SetSize(rowW - 40.0, height - topPad);
        headBg.SetMargin(inkMargin(0.0, topPad, 0.0, 0.0));
        headBg.SetTintColor(this.DCAccent());
        headBg.SetOpacity(0.07);
        headBg.Reparent(canvas);
        let underline: ref<inkRectangle> = new inkRectangle();
        underline.SetSize(rowW - 40.0, 2.0);
        underline.SetAnchor(inkEAnchor.BottomFillHorizontaly);
        underline.SetAnchorPoint(new Vector2(0.0, 1.0));
        underline.SetTintColor(this.DCAccent());
        underline.SetOpacity(0.45);
        underline.Reparent(canvas);
      };

      if isHead && i > 0 {
        let divider: ref<inkRectangle> = new inkRectangle();
        divider.SetSize(rowW - 40.0, 2.0);
        divider.SetMargin(inkMargin(0.0, 6.0, 0.0, 0.0));
        divider.SetTintColor(new HDRColor(0.70, 0.70, 0.75, 1.0));
        divider.SetOpacity(0.14);
        divider.Reparent(canvas);
      };

      let line: ref<inkHorizontalPanel> = new inkHorizontalPanel();
      line.SetMargin(inkMargin(isHead ? 0.0 : 26.0, topPad, 0.0, 0.0));
      line.Reparent(canvas);

      if StrLen(row.icon) > 0 {
        let iconParts: array<String> = StrSplit(row.icon, ":");
        let gameIcon: Bool = ArraySize(iconParts) >= 2 && Equals(iconParts[0], "g");
        let icon: ref<inkImage> = new inkImage();
        if gameIcon {
          icon.SetAtlasResource(ResRef.FromString(this.DCIconAtlas(iconParts[1])));
          icon.SetTexturePart(this.DCIconPart(iconParts[1]));
        } else {
          icon.SetAtlasResource(ResRef.FromString("dronecompanion\\gui\\dc_icons.inkatlas"));
          icon.SetTexturePart(StringToName(row.icon));
        };
        let iconSize: Float = this.DCS(isHead ? 60.0 : 44.0);
        icon.SetSize(Vector2(iconSize, iconSize));
        icon.SetMargin(inkMargin(0.0, this.DCS(4.0), 16.0, 0.0));
        if !isHead {
          icon.SetTintColor(new HDRColor(0.90, 0.92, 0.95, 1.0));
          icon.SetOpacity(0.85);
        };
        icon.Reparent(line);
      };

      if Equals(row.kind, "hp") {
        let frac: Float = MaxF(0.0, MinF(1.0, StringToFloat(this.DCField(row.value, 0), 0.0)));
        let barWidth: Float = this.DCS(900.0);
        let barHeight: Float = this.DCS(14.0);
        let hpColor: HDRColor = frac > 0.5
          ? new HDRColor(0.36, 0.86, 0.42, 1.0)
          : (frac > 0.25 ? new HDRColor(0.98, 0.76, 0.22, 1.0) : new HDRColor(0.94, 0.28, 0.22, 1.0));
        let barCanvas: ref<inkCanvas> = new inkCanvas();
        barCanvas.SetSize(barWidth, barHeight);
        barCanvas.SetMargin(inkMargin(0.0, this.DCS(8.0), 0.0, 0.0));
        barCanvas.Reparent(line);
        let track: ref<inkRectangle> = new inkRectangle();
        track.SetSize(barWidth, barHeight);
        track.SetTintColor(new HDRColor(0.70, 0.70, 0.75, 1.0));
        track.SetOpacity(0.14);
        track.Reparent(barCanvas);
        if frac > 0.0 {
          let fillBar: ref<inkRectangle> = new inkRectangle();
          fillBar.SetSize(barWidth * frac, barHeight);
          fillBar.SetTintColor(hpColor);
          fillBar.SetOpacity(0.85);
          fillBar.Reparent(barCanvas);
        };
      };

      let isGroup: Bool = Equals(row.kind, "group");
      let label: ref<inkText> = this.DCMakeText(this.DCFontSize(isHead ? 44 : (isGroup ? 30 : 38)), line);
      label.SetInteractive(true);
      if isHead {
        label.SetMargin(inkMargin(0.0, this.DCS(6.0), 0.0, 0.0));
      };
      if isGroup {
        label.SetLetterCase(textLetterCase.UpperCase);
        label.SetMargin(inkMargin(0.0, this.DCS(8.0), 0.0, 0.0));
        let groupFont: Float = Cast<Float>(this.DCFontSize(30));
        let ruleX: Float = 26.0 + Cast<Float>(StrLen(row.label)) * groupFont * 0.62 + 18.0;
        if ruleX < rowW - 80.0 {
          let rule: ref<inkRectangle> = new inkRectangle();
          rule.SetSize(rowW - 40.0 - ruleX, 2.0);
          rule.SetMargin(inkMargin(ruleX, topPad + this.DCS(8.0) + groupFont * 0.6, 0.0, 0.0));
          rule.SetTintColor(this.DCAccent());
          rule.SetOpacity(0.25);
          rule.Reparent(canvas);
        };
      };
      if this.DCIsWrapped(row.kind) {
        label.SetWrapping(true, this.DCWrapWidth(row));
      };
      label.SetText(row.label);
      label.RegisterToCallback(n"OnEnter", this, n"OnDCRowEnter");
      label.RegisterToCallback(n"OnLeave", this, n"OnDCRowLeave");
      ArrayPush(this.m_rowLabels, label);

      let value: ref<inkText> = this.DCMakeText(this.DCFontSize(isHead ? 40 : 38), canvas);
      value.SetAnchor(inkEAnchor.TopRight);
      value.SetAnchorPoint(new Vector2(1.0, 0.0));
      value.SetHAlign(inkEHorizontalAlign.Right);
      value.SetMargin(inkMargin(0.0, topPad, 40.0, 0.0));
      value.SetInteractive(true);
      if Equals(row.kind, "toggle") {
        let on: Bool = Equals(row.value, "1");
        let dotSize: Float = this.DCS(18.0);
        let dot: ref<inkRectangle> = new inkRectangle();
        dot.SetAnchor(inkEAnchor.TopRight);
        dot.SetAnchorPoint(new Vector2(1.0, 0.0));
        dot.SetSize(dotSize, dotSize);
        dot.SetMargin(inkMargin(0.0, topPad + this.DCS(14.0), 40.0, 0.0));
        dot.SetTintColor(on ? new HDRColor(0.30, 0.85, 0.35, 1.0) : new HDRColor(0.50, 0.50, 0.55, 1.0));
        dot.SetOpacity(on ? 1.0 : 0.45);
        dot.Reparent(canvas);
        value.SetMargin(inkMargin(0.0, topPad, 40.0 + dotSize + this.DCS(14.0), 0.0));
      };
      if Equals(row.kind, "slider") && StrContains(row.value, "|") {
        let frac: Float = MaxF(0.0, MinF(1.0, StringToFloat(this.DCField(row.value, 0), 0.0)));
        let barW: Float = this.DCS(280.0);
        let barH: Float = this.DCS(4.0);
        let barY: Float = height - this.DCS(9.0);
        let track: ref<inkRectangle> = new inkRectangle();
        track.SetAnchor(inkEAnchor.TopRight);
        track.SetAnchorPoint(new Vector2(1.0, 0.0));
        track.SetSize(barW, barH);
        track.SetMargin(inkMargin(0.0, barY, 40.0, 0.0));
        track.SetTintColor(new HDRColor(0.70, 0.70, 0.75, 1.0));
        track.SetOpacity(0.18);
        track.Reparent(canvas);
        if frac > 0.0 {
          let fill: ref<inkRectangle> = new inkRectangle();
          fill.SetAnchor(inkEAnchor.TopRight);
          fill.SetAnchorPoint(new Vector2(1.0, 0.0));
          fill.SetSize(barW * frac, barH);
          fill.SetMargin(inkMargin(0.0, barY, 40.0 + barW * (1.0 - frac), 0.0));
          fill.SetTintColor(this.DCAccent());
          fill.SetOpacity(0.90);
          fill.Reparent(canvas);
        };
      };
      value.SetText(this.DCValueOf(i));
      value.RegisterToCallback(n"OnEnter", this, n"OnDCRowEnter");
      value.RegisterToCallback(n"OnLeave", this, n"OnDCRowLeave");
      ArrayPush(this.m_rowValues, value);

      i += 1;
    };
    this.DCPaintRows();
    this.DCApplyScroll();
  }

  protected func DCValueOf(index: Int32) -> String {
    let row: DCRow = this.m_rows[index];
    if Equals(row.kind, "btn") {
      let text: String = this.DCStripMark(row.value);
      if StrLen(text) == 0 {
        return ">";
      };
      return text + "  >";
    };
    if Equals(row.kind, "toggle") {
      return Equals(row.value, "1")
        ? DroneCompanionText("Mod-DroneCompanion-L-on")
        : DroneCompanionText("Mod-DroneCompanion-L-off");
    };
    if Equals(row.kind, "choice") || Equals(row.kind, "slider") {
      return "<  " + this.DCSliderText(row) + "  >";
    };
    if Equals(row.kind, "hp") {
      return this.DCField(row.value, 1);
    };
    return row.value;
  }

  protected func DCSliderText(row: DCRow) -> String {
    if Equals(row.kind, "slider") && StrContains(row.value, "|") {
      return this.DCField(row.value, 1);
    };
    return row.value;
  }

  protected func DCPaintGrid() -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.m_rowMarks) {
      let selected: Bool = i == this.m_sel;
      let active: Bool = selected || i == this.m_hover;
      this.m_rowMarks[i].SetOpacity(selected ? 1.0 : (i == this.m_hover ? 0.45 : 0.0));
      if i < ArraySize(this.m_rowLabels) {
        this.m_rowLabels[i].SetOpacity(selected ? 1.0 : 0.78);
        this.m_rowLabels[i].SetTintColor(selected
          ? new HDRColor(1.0, 1.0, 1.0, 1.0)
          : new HDRColor(0.78, 0.80, 0.84, 1.0));
      };
      if i < ArraySize(this.m_rowUses) && IsDefined(this.m_rowUses[i]) {
        this.m_rowUses[i].SetOpacity(selected ? 0.95 : (i == this.m_hover ? 0.45 : 0.0));
      };
      i += 1;
    };
  }

  protected func DCPaintRows() -> Void {
    if Equals(this.m_mode, "grid") {
      this.DCPaintGrid();
      return;
    };
    let i: Int32 = 0;
    while i < ArraySize(this.m_rowLabels) {
      let selected: Bool = i == this.m_sel;
      let tone: Int32 = this.DCValueTone(this.m_rows[i]);
      this.m_rowLabels[i].SetTintColor(this.DCColorOf(this.m_rows[i].kind, selected));
      this.m_rowValues[i].SetText(this.DCValueOf(i));
      if tone == 4 {
        this.m_rowValues[i].SetTintColor(this.DCColorOf(this.m_rows[i].kind, selected));
      } else {
        this.m_rowValues[i].SetTintColor(this.DCToneColor(tone, selected));
      };
      this.m_rowMarks[i].SetOpacity(selected ? 0.16 : (i == this.m_hover ? 0.08 : 0.0));
      if i < ArraySize(this.m_rowRings) && IsDefined(this.m_rowRings[i]) {
        this.m_rowRings[i].SetOpacity(selected ? 0.65 : 0.0);
      };
      this.m_rowBars[i].SetOpacity(selected ? 1.0 : 0.0);
      i += 1;
    };
    this.DCUpdateHint();
  }

  protected func DCRowIndexOf(target: wref<inkWidget>) -> Int32 {
    let i: Int32 = 0;
    while i < ArraySize(this.m_rowLabels) {
      if Equals(target, this.m_rowLabels[i]) || Equals(target, this.m_rowValues[i]) {
        return i;
      };
      if i < ArraySize(this.m_rowHits) && IsDefined(this.m_rowHits[i]) && Equals(target, this.m_rowHits[i]) {
        return i;
      };
      i += 1;
    };
    return -1;
  }

  protected cb func OnDCRowEnter(evt: ref<inkPointerEvent>) -> Bool {
    let index: Int32 = this.DCRowIndexOf(evt.GetCurrentTarget());
    if index >= 0 && this.DCIsSelectable(this.m_rows[index].kind) {
      this.m_hover = index;
      this.DCPaintRows();
    };
    return false;
  }

  protected cb func OnDCRowClick(evt: ref<inkPointerEvent>) -> Bool {
    if !evt.IsAction(n"click") {
      return false;
    };
    let index: Int32 = this.DCRowIndexOf(evt.GetCurrentTarget());
    if index < 0 || !this.DCIsSelectable(this.m_rows[index].kind) {
      return false;
    };
    this.m_sel = index;
    this.DCPaintRows();
    this.DCActivate("act");
    return true;
  }

  protected cb func OnDCRowLeave(evt: ref<inkPointerEvent>) -> Bool {
    if this.DCRowIndexOf(evt.GetCurrentTarget()) == this.m_hover {
      this.m_hover = -1;
      this.DCPaintRows();
    };
    return false;
  }

  protected func DCApplyScroll() -> Void {
    let viewHeight: Float = this.DCViewHeight();
    if this.m_sel >= 0 && this.m_sel < ArraySize(this.m_rowTops) {
      let top: Float = this.m_rowTops[this.m_sel];
      let height: Float = this.DCRowHeight(this.m_rows[this.m_sel]);
      if top + this.m_scroll < 0.0 {
        this.m_scroll = -top;
      };
      if top + height + this.m_scroll > viewHeight {
        this.m_scroll = viewHeight - top - height;
      };
    };
    let maxScroll: Float = MaxF(0.0, this.m_contentHeight - viewHeight);
    this.m_scroll = MinF(0.0, MaxF(-maxScroll, this.m_scroll));
    this.m_listPanel.SetTranslation(new Vector2(0.0, this.m_scroll));
    this.DCPaintScrollBar(maxScroll);
  }

  protected func DCPaintScrollBar(maxScroll: Float) -> Void {
    if !IsDefined(this.m_scrollThumb) || !IsDefined(this.m_scrollTrack) {
      return;
    };
    if maxScroll <= 0.0 {
      this.m_scrollThumb.SetOpacity(0.0);
      this.m_scrollTrack.SetOpacity(0.0);
      return;
    };
    let viewHeight: Float = this.DCViewHeight();
    let thumbHeight: Float = MaxF(60.0, viewHeight * viewHeight / this.m_contentHeight);
    let travel: Float = viewHeight - thumbHeight;
    let progress: Float = -this.m_scroll / maxScroll;
    this.m_scrollTrack.SetOpacity(0.10);
    this.m_scrollThumb.SetOpacity(0.55);
    this.m_scrollThumb.SetSize(6.0, thumbHeight);
    this.m_scrollThumb.SetMargin(inkMargin(this.DCViewWidth() - 28.0, travel * progress, 0.0, 0.0));
  }

  protected func DCScrollBy(lines: Float) -> Void {
    let maxScroll: Float = MaxF(0.0, this.m_contentHeight - this.DCViewHeight());
    if maxScroll <= 0.0 {
      return;
    };
    this.m_scroll = MinF(0.0, MaxF(-maxScroll, this.m_scroll + lines * this.DCS(52.0) * 3.0));
    this.m_listPanel.SetTranslation(new Vector2(0.0, this.m_scroll));
    this.DCPaintScrollBar(maxScroll);
  }

  protected func DCMove(dir: Int32) -> Void {
    if ArraySize(this.m_rows) == 0 {
      return;
    };
    this.m_sel += dir;
    if this.m_sel < 0 {
      this.m_sel = ArraySize(this.m_rows) - 1;
    };
    if this.m_sel >= ArraySize(this.m_rows) {
      this.m_sel = 0;
    };
    this.DCClampSelection(dir);
    this.DCPaintRows();
    this.DCApplyScroll();
    let id: String = this.DCSelectedId();
    if StrLen(id) > 0 {
      this.DCEmit("sel:" + id);
    };
  }

  protected func DCSwitchTab(dir: Int32) -> Void {
    if ArraySize(this.m_tabs) == 0 {
      return;
    };
    this.m_tab += dir;
    if this.m_tab < 0 {
      this.m_tab = ArraySize(this.m_tabs) - 1;
    };
    if this.m_tab >= ArraySize(this.m_tabs) {
      this.m_tab = 0;
    };
    this.m_sel = 0;
    this.m_scroll = 0.0;
    this.DCPaintTabs();
    this.DCEmit("tab:" + IntToString(this.m_tab));
  }

  protected func DCActivate(suffix: String) -> Void {
    if this.m_sel < 0 || this.m_sel >= ArraySize(this.m_rows) {
      return;
    };
    if StrLen(this.m_rows[this.m_sel].id) == 0 {
      return;
    };
    this.DCEmit(suffix + ":" + this.m_rows[this.m_sel].id);
  }

  protected cb func OnAttach() {
    super.OnAttach();
    this.m_attached = true;
    if IsDefined(this.m_owner) && this.DCIsGrid() {
      let holder: ref<DCMenuHolder> = DCMenuHolder.Get(this.m_owner.GetGame());
      if IsDefined(holder) {
        holder.DCSetOpening(false);
        holder.DCSet(this);
        holder.DCApplyHide();
      };
      let ui: ref<UISystem> = GameInstance.GetUISystem(this.m_owner.GetGame());
      if IsDefined(ui) {
        ui.PushGameContext(UIGameContext.ModalPopup);
        ui.RequestNewVisualState(n"inkInGameMenuState");
        this.m_pushedContext = true;
      };
    };
    this.RegisterToGlobalInputCallback(n"OnPostOnPress", this, n"OnDCInput");
    this.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnDCWheel");
    this.DCEmit("menu:open");
  }

  protected cb func OnDetach() {
    this.m_attached = false;
    if IsDefined(this.m_owner) {
      let holder: ref<DCMenuHolder> = DCMenuHolder.Get(this.m_owner.GetGame());
      if IsDefined(holder) {
        holder.DCRestore();
        holder.DCSetOpening(false);
      };
      if this.m_pushedContext {
        this.m_pushedContext = false;
        let ui: ref<UISystem> = GameInstance.GetUISystem(this.m_owner.GetGame());
        if IsDefined(ui) {
          ui.PopGameContext(UIGameContext.ModalPopup);
          ui.RestorePreviousVisualState(n"inkInGameMenuState");
        };
      };
    };
    this.UnregisterFromGlobalInputCallback(n"OnPostOnPress", this, n"OnDCInput");
    this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnDCWheel");
    this.DCEmit("menu:close");
    super.OnDetach();
  }

  protected cb func OnDCInput(evt: ref<inkPointerEvent>) -> Bool {
    if this.DCIsPicker() && evt.IsAction(n"cancel") {
      if IsDefined(this.m_owner) {
        let holder: ref<DCMenuHolder> = DCMenuHolder.Get(this.m_owner.GetGame());
        if IsDefined(holder) {
          holder.DCSet(null);
        };
      };
      this.Close();
      evt.Handle();
      evt.Consume();
      return false;
    };
    let grid: Bool = Equals(this.m_mode, "grid");


    if grid {
      if evt.IsAction(n"up_button") || evt.IsAction(n"popup_navigate_up") {
        this.DCGridMove(0, -1);
        evt.Handle();
        evt.Consume();
        return false;
      };
      if evt.IsAction(n"down_button") || evt.IsAction(n"popup_navigate_down") {
        this.DCGridMove(0, 1);
        evt.Handle();
        evt.Consume();
        return false;
      };
      if evt.IsAction(n"popup_navigate_left") {
        this.DCGridMove(-1, 0);
        evt.Handle();
        evt.Consume();
        return false;
      };
      if evt.IsAction(n"popup_navigate_right") {
        this.DCGridMove(1, 0);
        evt.Handle();
        evt.Consume();
        return false;
      };
      if evt.IsAction(n"next_menu") || evt.IsAction(n"prior_menu")
        || evt.IsAction(n"next_sub_menu") || evt.IsAction(n"prior_sub_menu") {
        evt.Handle();
        evt.Consume();
        return false;
      };
      if evt.IsAction(n"click") {
        return false;
      };
      if evt.IsAction(n"proceed") || evt.IsAction(n"popup_accept") {
        this.DCActivate("act");
        evt.Handle();
        evt.Consume();
        return false;
      };
      return false;
    };

    if evt.IsAction(n"popup_navigate_up") {
      this.DCMove(-1);
      return false;
    };
    if evt.IsAction(n"popup_navigate_down") {
      this.DCMove(1);
      return false;
    };
    if evt.IsAction(n"popup_navigate_left") {
      this.DCActivate("dec");
      return false;
    };
    if evt.IsAction(n"popup_navigate_right") {
      this.DCActivate("inc");
      return false;
    };
    if evt.IsAction(n"click") {
      return false;
    };
    if evt.IsAction(n"proceed") || evt.IsAction(n"popup_accept") {
      this.DCActivate("act");
      return false;
    };
    if evt.IsAction(n"next_menu") {
      this.DCSwitchTab(1);
      return false;
    };
    if evt.IsAction(n"prior_menu") {
      this.DCSwitchTab(-1);
      return false;
    };
    if evt.IsAction(n"next_sub_menu") {
      this.DCSwitchSub(1);
      return false;
    };
    if evt.IsAction(n"prior_sub_menu") {
      this.DCSwitchSub(-1);
      return false;
    };
    return false;
  }

  protected cb func OnDCWheel(evt: ref<inkPointerEvent>) -> Bool {
    if !evt.IsAction(n"mouse_wheel") {
      return false;
    };
    let axis: Float = evt.GetAxisData();
    if axis > 0.0 || axis < 0.0 {
      this.DCScrollBy(axis);
    };
    return false;
  }

  protected cb func OnGlobalReleaseInput(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_left") && !evt.IsHandled() {
      let target: wref<inkWidget> = evt.GetTarget();
      let i: Int32 = 0;
      while IsDefined(target) && i < ArraySize(this.m_rowLabels) {
        if Equals(target, this.m_rowLabels[i]) || Equals(target, this.m_rowValues[i]) {
          if this.DCIsSelectable(this.m_rows[i].kind) {
            this.m_sel = i;
            this.DCPaintRows();
            this.DCActivate("act");
          };
          i = ArraySize(this.m_rowLabels);
        } else {
          i += 1;
        };
      };
      let t: Int32 = 0;
      while IsDefined(target) && t < ArraySize(this.m_tabTexts) {
        if Equals(target, this.m_tabTexts[t]) {
          this.m_tab = t;
          this.m_sel = 0;
          this.m_scroll = 0.0;
          this.DCPaintTabs();
          this.DCEmit("tab:" + IntToString(this.m_tab));
          t = ArraySize(this.m_tabTexts);
        } else {
          t += 1;
        };
      };
      let s: Int32 = 0;
      while IsDefined(target) && s < ArraySize(this.m_subTexts) {
        if Equals(target, this.m_subTexts[s]) {
          this.DCSelectSub(s);
          s = ArraySize(this.m_subTexts);
        } else {
          s += 1;
        };
      };
    };
    return super.OnGlobalReleaseInput(evt);
  }

  public func DCSetFooter(text: String) -> Void {
    this.m_footerText = text;
    if IsDefined(this.m_hint) {
      this.m_hint.SetText(text);
    };
  }

  public static func Show(player: ref<PlayerPuppet>, payload: String) -> ref<DCMenuPopup> {
    let popup: ref<DCMenuPopup> = new DCMenuPopup();
    popup.DCBind(player);
    popup.DCSetState(payload);
    GameInstance.GetUISystem(player.GetGame()).QueueEvent(ShowCustomPopupEvent.Create(popup));
    return popup;
  }
}

public class DCMenuHolder extends ScriptableSystem {
  private let m_popup: ref<DCMenuPopup>;
  private let m_opening: Bool;

  public final func DCIsBusy() -> Bool {
    return this.m_opening;
  }

  public final func DCSetOpening(value: Bool) -> Void {
    this.m_opening = value;
  }
  private let m_hidden: wref<inkWidget>;

  public final func DCHide(widget: ref<inkWidget>) -> Void {
    this.m_hidden = widget;
  }

  public final func DCIsOpenNow() -> Bool {
    return IsDefined(this.m_popup) && this.m_popup.DCIsOpen();
  }

  public final func DCApplyHide() -> Void {
    if IsDefined(this.m_hidden) {
      this.m_hidden.SetVisible(false);
    };
  }

  public final func DCRestore() -> Void {
    if IsDefined(this.m_hidden) {
      this.m_hidden.SetVisible(true);
      this.m_hidden = null;
    };
  }

  public final static func Get(game: GameInstance) -> ref<DCMenuHolder> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"DroneCompanion.DCMenuHolder") as DCMenuHolder;
  }

  public final func DCGet() -> ref<DCMenuPopup> {
    return this.m_popup;
  }

  public final func DCSet(popup: ref<DCMenuPopup>) -> Void {
    this.m_popup = popup;
  }
}

@addField(PlayerPuppet)
let m_dcPopup: ref<DCMenuPopup>;

@addMethod(PlayerPuppet)
public func DCEmit(action: String) -> Bool {
  return true;
}

@addMethod(PlayerPuppet)
public func DCPushState(payload: String) -> Bool {
  let holder: ref<DCMenuHolder> = DCMenuHolder.Get(this.GetGame());
  let popup: ref<DCMenuPopup> = IsDefined(holder) ? holder.DCGet() : this.m_dcPopup;
  if !IsDefined(popup) {
    popup = this.m_dcPopup;
  };
  if IsDefined(popup) && popup.DCIsOpen() {
    popup.DCSetState(payload);
    return true;
  };
  return false;
}

@addMethod(PlayerPuppet)
public func DCToggleMenu(payload: String) -> Bool {
  let holder: ref<DCMenuHolder> = DCMenuHolder.Get(this.GetGame());
  let popup: ref<DCMenuPopup> = IsDefined(holder) ? holder.DCGet() : this.m_dcPopup;
  if IsDefined(popup) && popup.DCIsOpen() {
    popup.Close();
    this.m_dcPopup = null;
    if IsDefined(holder) {
      holder.DCSet(null);
    };
    return false;
  };
  if GameInstance.GetSystemRequestsHandler().IsPreGame() {
    return false;
  };
  if IsDefined(holder) && holder.DCIsBusy() {
    return false;
  };
  if IsDefined(holder) {
    holder.DCSetOpening(true);
  };
  this.m_dcPopup = DCMenuPopup.Show(this, payload);
  if IsDefined(holder) {
    holder.DCSet(this.m_dcPopup);
  };
  return true;
}
