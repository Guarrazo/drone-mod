module TerminalKit

import Codeware.UI.*
import RedFunctions.*

public abstract class TKKind {
  public static func Heading() -> Int32 = 1
  public static func Text() -> Int32 = 2
  public static func Pair() -> Int32 = 3
  public static func Meter() -> Int32 = 4
  public static func Button() -> Int32 = 5
  public static func Note() -> Int32 = 6
  public static func Gap() -> Int32 = 7
  public static func Item() -> Int32 = 8
  public static func Links() -> Int32 = 9
  public static func Buttons() -> Int32 = 12
  public static func Slider() -> Int32 = 13
  public static func Track() -> Int32 = 14
  public static func Section() -> Int32 = 15
  public static func Input() -> Int32 = 16
  public static func Entry() -> Int32 = 17
  public static func Dossier() -> Int32 = 18
  public static func Columns() -> Int32 = 19
  public static func Custom() -> Int32 = 20
  public static func Table() -> Int32 = 21
  public static func Card() -> Int32 = 22
  public static func Board() -> Int32 = 23
  public static func ColumnStart() -> Int32 = 24
  public static func ColumnsEnd() -> Int32 = 25
  public static func Ticker() -> Int32 = 26
  public static func Stat() -> Int32 = 27
  public static func Tile() -> Int32 = 28
  public static func Dropdown() -> Int32 = 29
  public static func Check() -> Int32 = 30
  public static func Search() -> Int32 = 31
  public static func SortHead() -> Int32 = 32
  public static func Pager() -> Int32 = 33
  public static func Live() -> Int32 = 34
  public static func Message() -> Int32 = 35
  public static func Choice() -> Int32 = 36
  public static func Gauge() -> Int32 = 37
  public static func Stack() -> Int32 = 38
  public static func File() -> Int32 = 39
  public static func Posting() -> Int32 = 40
  public static func Run() -> Int32 = 41
  public static func Region() -> Int32 = 42
  public static func Key() -> Int32 = 43
  public static func Bay() -> Int32 = 44
  public static func Leds() -> Int32 = 45
  public static func Ring() -> Int32 = 46
  public static func Compare() -> Int32 = 47
  public static func Feed() -> Int32 = 48
  public static func Wave() -> Int32 = 49
}

public class TKRow extends IScriptable {
  public let kind: Int32;
  public let text: String;
  public let value: String;
  public let color: String;
  public let label: String;
  public let action: String;
  public let arg: String;
  public let fraction: Float;
  public let on: Bool;
  public let extra: String;
  public let tip: String;
  public let image: String;

  public let labels: array<String>;
  public let actions: array<String>;
  public let args: array<String>;

  public func IsAction() -> Bool = ArraySize(this.actions) > 0
}

public abstract class TKStr {
  public static func Split(s: String, sep: String) -> array<String> {
    let parts: array<String>;
    let n = StrLen(sep);
    let at = n > 0 ? StrFindFirst(s, sep) : -1;
    while at >= 0 {
      ArrayPush(parts, StrLeft(s, at));
      s = StrMid(s, at + n, StrLen(s) - at - n);
      at = StrFindFirst(s, sep);
    }
    ArrayPush(parts, s);
    return parts;
  }

  public static func Part(s: String, sep: String, i: Int32) -> String {
    let parts = TKStr.Split(s, sep);
    return i < ArraySize(parts) ? parts[i] : "";
  }

  public static func Join(parts: array<String>, sep: String) -> String {
    let out = "";
    let i = 0;
    while i < ArraySize(parts) {
      out += (i > 0 ? sep : "") + parts[i];
      i += 1;
    }
    return out;
  }
}

public class TKPage extends IScriptable {
  public let page: String;
  public let answered: Bool;
  public let title: String;
  public let subtitle: String;
  public let message: String;
  public let nextPage: String;
  public let nextArg: String;
  public let theme: String;
  public let rebuild: Bool;
  public let skipRedraw: Bool;
  public let section: String;
  public let bare: Bool;
  public let wheelReserved: Bool;
  public let refresh: array<String>;
  public let overlayRegion: String;
  public let overlayPage: String;
  public let overlayArg: String;
  public let overlayEnd: Bool;
  public let noOverlayBack: Bool;
  public let rows: array<ref<TKRow>>;

  public let fieldKeys: array<String>;
  public let fieldValues: array<String>;
  public let content: ref<TKContent>;

  public let confirmText: String;
  public let confirmYes: String;
  public let confirmAction: String;
  public let confirmArg: String;

  public func Request(page: String, arg: String) -> Void {
    if IsDefined(this.content) {
      this.content.Request(this, page, arg);
    }
  }

  public func Act(action: String, arg: String) -> Void {
    if IsDefined(this.content) {
      this.content.Act(this, action, arg);
    }
  }

  public func SetTitle(title: String, subtitle: String) -> Void {
    this.title = title;
    this.subtitle = subtitle;
    this.answered = true;
  }
  public func SetMessage(text: String) -> Void { this.message = text; this.answered = true; }
  public func GoTo(page: String, arg: String) -> Void { this.nextPage = page; this.nextArg = arg; }
  public func SetTheme(id: String) -> Void { this.theme = id; }
  public func Rebuild() -> Void { this.rebuild = true; }
  public func SetSection(id: String) -> Void { this.section = id; }
  public func Bare() -> Void { this.bare = true; }

  public func Region(name: String) -> Void { this.Push(TKKind.Region(), name, "", "", "", "", "", 0.0, true); }

  public func Refresh(name: String) -> Void { ArrayPush(this.refresh, name); }

  public func Overlay(page: String, arg: String) -> Void { this.OverlayOn("", page, arg); }
  public func OverlayOn(region: String, page: String, arg: String) -> Void {
    this.overlayRegion = region;
    this.overlayPage = page;
    this.overlayArg = arg;
  }

  public func SetOverlayBack(on: Bool) -> Void { this.noOverlayBack = !on; }

  public func EndOverlay(region: String) -> Void {
    this.overlayRegion = region;
    this.overlayEnd = true;
  }
  public func GetField(key: String) -> String {
    let i = 0;
    while i < ArraySize(this.fieldKeys) {
      if Equals(this.fieldKeys[i], key) {
        return this.fieldValues[i];
      }
      i += 1;
    }
    return "";
  }

  public func Row(i: Int32) -> ref<TKRow> = i >= 0 && i < ArraySize(this.rows) ? this.rows[i] : new TKRow()
  public func Count() -> Int32 = ArraySize(this.rows)

  private func Push(kind: Int32, text: String, value: String, color: String, label: String, action: String, arg: String, fraction: Float, on: Bool) -> ref<TKRow> {
    let r = new TKRow();
    r.kind = kind; r.text = text; r.value = value; r.color = color;
    r.label = label; r.action = action; r.arg = arg;
    r.fraction = fraction; r.on = on;
    ArrayPush(this.rows, r);
    this.answered = true;
    return r;
  }

  private func PushAct(kind: Int32, text: String, value: String, color: String, labels: String, actions: String, args: String, fraction: Float, on: Bool) -> ref<TKRow> {
    let r = this.Push(kind, text, value, color, labels, actions, args, fraction, on);
    let names = TKStr.Split(labels, "|");
    let acts = TKStr.Split(actions, "|");
    let vals = ArraySize(acts) > 1 ? (StrContains(args, "\n") ? TKStr.Split(args, "\n") : TKStr.Split(args, "|")) : [args];
    let k = 0;
    while k < ArraySize(acts) {
      ArrayPush(r.labels, k < ArraySize(names) ? names[k] : "");
      ArrayPush(r.actions, acts[k]);
      ArrayPush(r.args, k < ArraySize(vals) ? vals[k] : "");
      k += 1;
    }
    return r;
  }

  public func Actions(kind: Int32, text: String, value: String, color: String, labels: array<String>, actions: array<String>, args: array<String>, fraction: Float, on: Bool) -> ref<TKRow> {
    let r = this.Push(kind, text, value, color, TKStr.Join(labels, "|"), TKStr.Join(actions, "|"), TKStr.Join(args, "\n"), fraction, on);
    r.labels = labels; r.actions = actions; r.args = args;
    return r;
  }

  public func Heading(text: String) -> Void { this.Push(TKKind.Heading(), text, "", "red", "", "", "", 0.0, false); }
  public func Text(text: String, color: String) -> Void { this.Push(TKKind.Text(), text, "", color, "", "", "", 0.0, false); }
  public func Pair(label: String, value: String, color: String) -> Void { this.Push(TKKind.Pair(), label, value, color, "", "", "", 0.0, false); }
  public func Meter(label: String, value: String, fraction: Float) -> Void { this.Push(TKKind.Meter(), label, value, "yellow", "", "", "", fraction, false); }
  public func Button(label: String, action: String, arg: String, on: Bool) -> Void { this.PushAct(TKKind.Button(), "", "", "", label, action, arg, 0.0, on); }
  public func Note(text: String) -> Void { this.Push(TKKind.Note(), text, "", "dim", "", "", "", 0.0, false); }

  public func ItemNote(text: String) -> Void { this.Push(TKKind.Note(), text, "item", "dim", "", "", "", 0.0, false); }
  public func Gap() -> Void { this.Push(TKKind.Gap(), "", "", "", "", "", "", 0.0, false); }
  public func Item(text: String, value: String, color: String, label: String, action: String, arg: String, on: Bool) -> Void {
    this.PushAct(TKKind.Item(), text, value, color, label, action, arg, 0.0, on);
  }

  public func Levels(text: String, value: String, color: String, level: Int32, max: Int32, label: String, action: String, arg: String, on: Bool) -> Void {
    this.PushAct(TKKind.Item(), text, value, color, label, action, arg, 0.0, on).extra = IntToString(level) + ":" + IntToString(max);
  }

  public func Ledger(style: String, cells: String, cols: String) -> Void {
    this.Push(TKKind.Table(), cells, cols, style, "", "", "", 0.0, true);
  }

  public func Card(head: String, details: String, color: String, labels: String, actions: String, args: String, bright: Bool) -> Void {
    this.PushAct(TKKind.Card(), head, details, color, labels, actions, args, 0.0, bright);
  }

  public func File(head: String, stats: String, lines: String, quote: String, color: String, labels: String, actions: String, args: String, bright: Bool) -> Void {
    this.PushAct(TKKind.File(), head, stats + "\n" + lines + "\n" + quote, color, labels, actions, args, 0.0, bright);
  }

  public func Posting(head: String, chips: String, lines: String, odds: Float, color: String, labels: String, actions: String, args: String, bright: Bool) -> Void {
    this.PushAct(TKKind.Posting(), head, chips + "\n" + lines, color, labels, actions, args, odds, bright);
  }

  public func Run(head: String, lines: String, start: Float, end: Float, color: String, labels: String, actions: String, args: String, bright: Bool) -> Void {
    this.PushAct(TKKind.Run(), head, lines + "\n" + FloatToString(start) + "|" + FloatToString(end), color, labels, actions, args, 0.0, bright);
  }

  public func Board(style: String, cells: String, cols: String, label: String, action: String, arg: String, on: Bool) -> Void {
    this.PushAct(TKKind.Board(), cells, cols, style, label, action, arg, 0.0, on);
  }

  public func Ticker(name: String, value: String, change: String, series: String, note: String) -> Void {
    this.Push(TKKind.Ticker(), name + "|" + value + "|" + change + "|" + note, series, "", "", "", "", 0.0, true);
  }

  public func Gauge(name: String, value: String, sub: String, fraction: Float, color: String) -> Void {
    this.Push(TKKind.Gauge(), name + "|" + value + "|" + sub, "", color, "", "", "", fraction, true);
  }

  public func Stack(label: String, value: String, names: String, shares: String, colors: String) -> Void {
    this.Push(TKKind.Stack(), label, value, "", names, shares, colors, 0.0, true);
  }

  public func Stat(name: String, value: String, sub: String, fraction: Float) -> Void {
    this.Push(TKKind.Stat(), name + "|" + value + "|" + sub, "", "", "", "", "", fraction, true);
  }

  public func Tile(name: String, value: String, sub: String, color: String, label: String, action: String, arg: String, on: Bool) -> Void {
    this.PushAct(TKKind.Tile(), name + "|" + value + "|" + sub, "", color, label, action, arg, 0.0, on);
  }

  public func Column(share: Float) -> Void { this.Push(TKKind.ColumnStart(), "", "", "", "", "", "", share, true); }
  public func EndColumns() -> Void { this.Push(TKKind.ColumnsEnd(), "", "", "", "", "", "", 0.0, true); }

  public func Buttons(text: String, value: String, color: String, labels: String, actions: String, args: String) -> Void {
    this.PushAct(TKKind.Buttons(), text, value, color, labels, actions, args, 0.0, true);
  }

  public func Slider(text: String, value: String, color: String, spec: String, action: String, arg: String) -> Void {
    this.PushAct(TKKind.Slider(), text, value, color, spec, action, arg, 0.0, true);
  }

  public func Track(text: String, value: String, fraction: Float, names: String, marks: String) -> Void {
    this.Push(TKKind.Track(), text, value, "", names, marks, "", fraction, true);
  }

  public func Input(label: String, value: String, field: String) -> Void {
    this.Push(TKKind.Input(), label, value, "", "", "", field, 0.0, true);
  }

  public func Section(text: String, value: String, open: Bool, action: String, arg: String) -> Void {
    this.PushAct(TKKind.Section(), text, value, "", open ? "CLOSE" : "OPEN", action, arg, 0.0, open);
  }

  public func Entry(time: String, status: String, tag: String, head: String, details: String, quote: String, color: String) -> Void {
    this.Push(TKKind.Entry(), head, details, color, time + "|" + status + "|" + tag, quote, "", 0.0, true);
  }

  public func Dossier(name: String, line: String, stamp: String, color: String) -> Void {
    this.Push(TKKind.Dossier(), name, line, color, stamp, "", "", 0.0, true);
  }

  public func Columns(leftLabels: String, leftValues: String, rightLabels: String, rightValues: String) -> Void {
    this.Push(TKKind.Columns(), leftLabels, leftValues, "", rightLabels, rightValues, "", 0.0, true);
  }

  public func Links(labels: String, targets: String, current: String) -> Void {
    this.Push(TKKind.Links(), labels, targets, "", current, "", "", 0.0, true);
  }

  public func Custom(tag: String, a: String, b: String, c: String, d: String, wheel: Bool) -> Void {
    this.Push(TKKind.Custom(), tag, a, b, c, d, "", wheel ? 1.0 : 0.0, true);
    if wheel {
      this.wheelReserved = true;
    }
  }

  public func Dropdown(text: String, value: String, current: String, labels: String, values: String, action: String, arg: String) -> Void {
    let r = this.Push(TKKind.Dropdown(), text, value, "", labels, action, arg, 0.0, true);
    r.labels = TKStr.Split(labels, "|");
    r.args = TKStr.Split(values, "|");
    r.extra = current;
  }

  public func Check(text: String, value: String, on: Bool, action: String, arg: String) -> Void {
    this.Push(TKKind.Check(), text, value, "", "", action, arg, 0.0, on);
  }

  public func Search(label: String, value: String, field: String, action: String) -> Void {
    let r = this.PushAct(TKKind.Search(), label, value, "", "SEARCH", action, "", 0.0, true);
    r.extra = field;
  }

  public func SortHead(cells: String, cols: String, col: Int32, desc: Bool, action: String, arg: String) -> Void {
    this.Push(TKKind.SortHead(), cells, cols, "", "", action, arg, Cast<Float>(col), desc);
  }

  public func Pager(page: Int32, pages: Int32, action: String, arg: String) -> Void {
    let prefix = StrLen(arg) > 0 ? arg + ":" : "";
    let r = this.PushAct(TKKind.Pager(), "PAGE " + IntToString(page + 1) + " OF " + IntToString(Max(1, pages)), "", "",
      (page > 0 ? "" : "!") + "PREV|" + (page < pages - 1 ? "" : "!") + "NEXT", action + "|" + action,
      prefix + IntToString(Max(0, page - 1)) + "\n" + prefix + IntToString(Min(Max(0, pages - 1), page + 1)), 0.0, true);
    r.fraction = Cast<Float>(page);
  }

  public func Countdown(text: String, value: String, endsAt: Float, total: Float, action: String, arg: String) -> Void {
    this.Push(TKKind.Live(), text, value, "", FloatToString(endsAt - total) + "|" + FloatToString(endsAt) + "|0", action, arg, 0.0, true);
  }

  public func Progress(text: String, value: String, start: Float, end: Float, action: String, arg: String) -> Void {
    this.Push(TKKind.Live(), text, value, "", FloatToString(start) + "|" + FloatToString(end) + "|1", action, arg, 0.0, true);
  }

  public func Choice(label: String, value: String, color: String, chosen: Bool, action: String, arg: String) -> Void {
    this.Push(TKKind.Choice(), value, label, color, "", action, arg, 0.0, chosen);
  }

  public func Message(who: String, time: String, text: String, mine: Bool, color: String) -> Void {
    this.Push(TKKind.Message(), text, who, color, time, "", "", 0.0, mine);
  }

  public func Key(inputAction: String, label: String, action: String, arg: String) -> Void {
    this.Push(TKKind.Key(), StrBeforeFirst(label + "|", "|"), StrAfterFirst(label, "|"), "", inputAction, action, arg, 0.0, true);
  }

  public func Bay(head: String, atlas: String, part: String, fraction: Float, color: String, selected: Bool, action: String, arg: String) -> Void {
    this.Push(TKKind.Bay(), head, atlas + "|" + part, color, "", action, arg, fraction, selected);
  }

  public func Leds(label: String, value: String, colors: String, blinks: String) -> Void {
    this.Push(TKKind.Leds(), label, value, "", colors, blinks, "", 0.0, true);
  }

  public func Ring(name: String, value: String, sub: String, fraction: Float, color: String) -> Void {
    this.Push(TKKind.Ring(), name + "|" + value + "|" + sub, "", color, "", "", "", fraction, true);
  }

  public func Compare(label: String, value: String, fraction: Float, current: Float, color: String) -> Void {
    this.Push(TKKind.Compare(), label, value, color, FloatToString(current), "", "", fraction, true);
  }

  public func Feed(label: String, text: String, color: String) -> Void {
    this.Push(TKKind.Feed(), text, label, color, "", "", "", 0.0, true);
  }

  public func Wave(label: String, value: String, series: String, color: String, live: Bool) -> Void {
    this.Push(TKKind.Wave(), label, value, color, series, "", "", 0.0, live);
  }

  public func Confirm(text: String, yes: String, action: String, arg: String) -> Void {
    this.confirmText = text;
    this.confirmYes = yes;
    this.confirmAction = action;
    this.confirmArg = arg;
  }

  public func SetTip(tip: String) -> Void {
    if ArraySize(this.rows) > 0 {
      this.rows[ArraySize(this.rows) - 1].tip = tip;
    }
  }

  public func SetExtra(extra: String) -> Void {
    if ArraySize(this.rows) > 0 {
      this.rows[ArraySize(this.rows) - 1].extra = extra;
    }
  }

  public func SetPortrait(kind: String, atlas: String, part: String) -> Void {
    if ArraySize(this.rows) > 0 {
      this.rows[ArraySize(this.rows) - 1].image = kind + "|" + atlas + "|" + part;
    }
  }

  public func SetPortraitImage(kind: String, faceAtlas: String, facePart: String, atlas: String, part: String) -> Void {
    if ArraySize(this.rows) > 0 {
      this.rows[ArraySize(this.rows) - 1].image = kind + "|" + atlas + "|" + part + "|" + faceAtlas + "|" + facePart;
    }
  }

  public func SetPortraitWire(atlas: String, part: String) -> Void {
    if ArraySize(this.rows) > 0 {
      this.rows[ArraySize(this.rows) - 1].image = "w|" + atlas + "|" + part;
    }
  }
}

public abstract class TKContent extends IScriptable {
  public func Request(p: ref<TKPage>, page: String, arg: String) -> Void {}
  public func Act(p: ref<TKPage>, action: String, arg: String) -> Void {}

  public func Custom(v: ref<TKView>, parent: ref<inkCompoundWidget>, p: ref<TKPage>, r: ref<TKRow>) -> ref<TKCustom> { return null; }

  public func Rebuild() -> Void {}

  public func HitHover(v: ref<TKView>, action: String, arg: String, over: Bool) -> Void {}

  public func HitWheel(v: ref<TKView>, action: String, arg: String, delta: Float) -> Bool = false
}

public abstract class TKCustom extends IScriptable {
  public func Stop() -> Void {}
}

public abstract class TKFrame extends IScriptable {
  public func Owner() -> ref<inkCustomController> { return null; }
  public func SetBare(bare: Bool) -> Void {}
}

public abstract class TKTheme {

  public static func Paint(w: ref<inkWidget>, theme: String, role: String) -> Void {
    if !IsDefined(w) {
      return;
    }
    if Equals(theme, "") || Equals(theme, "hud") {
      w.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
      w.BindProperty(n"tintColor", TKTheme.HudColor(role));
      return;
    }

    w.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
    w.BindProperty(n"tintColor", TKTheme.HudColor(role));
    w.UnbindProperty(n"tintColor");
    w.SetTintColor(TKTheme.Color(theme, role));
  }

  public static func PaintNew(w: ref<inkWidget>, theme: String, role: String) -> Void {
    if Equals(theme, "") || Equals(theme, "hud") {
      w.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
      w.BindProperty(n"tintColor", TKTheme.HudColor(role));
    } else {
      w.SetTintColor(TKTheme.Color(theme, role));
    }
  }

  public static func Fix(w: ref<inkWidget>, theme: String, color: HDRColor) -> Void {
    if Equals(theme, "") || Equals(theme, "hud") {
      w.UnbindProperty(n"tintColor");
    }
    w.SetTintColor(color);
  }

  public static func HudColor(role: String) -> CName {
    switch role {
      case "accent": return n"MainColors.Red";
      case "text": return n"MainColors.PanelBlue";
      case "rule": return n"MainColors.DarkRed";
      default: return n"MainColors.Blue";
    }
  }

  public static func C(r: Float, g: Float, b: Float) -> HDRColor = new HDRColor(MinF(r, 1.0), MinF(g, 1.0), MinF(b, 1.0), 1.0)

  public static func Ids() -> array<String> {
    let ids = ["hud", "kiroshi", "arasaka", "militech", "netwatch", "mono"];
    let sys = TKThemeSystem.Get();
    if IsDefined(sys) {
      for p in sys.palettes {
        ArrayPush(ids, p.Id());
      }
    }
    return ids;
  }

  public static func Register(palette: ref<TKPalette>) -> Void {
    let sys = TKThemeSystem.Get();
    if !IsDefined(sys) || !IsDefined(palette) || StrLen(palette.Id()) == 0 {
      return;
    }
    let i = 0;
    while i < ArraySize(sys.palettes) {
      if Equals(sys.palettes[i].Id(), palette.Id()) {
        sys.palettes[i] = palette;
        return;
      }
      i += 1;
    }
    ArrayPush(sys.palettes, palette);
  }

  private static func Registered(theme: String) -> ref<TKPalette> {
    let sys = TKThemeSystem.Get();
    if IsDefined(sys) {
      for p in sys.palettes {
        if Equals(p.Id(), theme) {
          return p;
        }
      }
    }
    return null;
  }

  public static func Color(theme: String, role: String) -> HDRColor {
    switch theme {
      case "kiroshi":
        switch role {
          case "title": return TKTheme.C(0.37, 0.96, 1.19);
          case "accent": return TKTheme.C(0.55, 1.0, 1.1);
          case "text": return TKTheme.C(0.45, 0.72, 0.78);
          case "rule": return TKTheme.C(0.12, 0.38, 0.44);
          default: return TKTheme.C(0.85, 1.0, 1.0);
        }
      case "arasaka":
        switch role {
          case "title": return TKTheme.C(1.0, 0.3, 0.28);
          case "accent": return TKTheme.C(1.0, 0.18, 0.18);
          case "text": return TKTheme.C(0.82, 0.72, 0.72);
          case "rule": return TKTheme.C(0.45, 0.07, 0.07);
          case "frame": return TKTheme.C(1.0, 0.25, 0.25);
          default: return TKTheme.C(1.0, 0.95, 0.95);
        }
      case "militech":
        switch role {
          case "title": return TKTheme.C(1.0, 0.72, 0.22);
          case "accent": return TKTheme.C(1.0, 0.55, 0.1);
          case "text": return TKTheme.C(0.85, 0.74, 0.52);
          case "rule": return TKTheme.C(0.45, 0.3, 0.08);
          default: return TKTheme.C(1.0, 0.88, 0.58);
        }
      case "netwatch":
        switch role {
          case "title": return TKTheme.C(0.35, 1.0, 0.6);
          case "accent": return TKTheme.C(0.2, 0.9, 0.5);
          case "text": return TKTheme.C(0.55, 0.82, 0.66);
          case "rule": return TKTheme.C(0.08, 0.4, 0.22);
          default: return TKTheme.C(0.8, 1.0, 0.85);
        }
      case "mono":
        switch role {
          case "title": return TKTheme.C(1.0, 1.0, 1.0);
          case "accent": return TKTheme.C(0.9, 0.9, 0.9);
          case "text": return TKTheme.C(0.62, 0.62, 0.62);
          case "rule": return TKTheme.C(0.3, 0.3, 0.3);
          default: return TKTheme.C(0.95, 0.95, 0.95);
        }
      default:

        let mine = TKTheme.Registered(theme);
        return IsDefined(mine) ? mine.Color(role) : TKTheme.C(0.37, 0.96, 1.19);
    }
  }

  public static func Gain() -> HDRColor = new HDRColor(0.36, 0.94, 0.55, 1.0)
  public static func Loss() -> HDRColor = new HDRColor(1.0, 0.36, 0.33, 1.0)
  public static func Amber() -> HDRColor = new HDRColor(1.0, 0.72, 0.22, 1.0)
  public static func Gold() -> HDRColor = new HDRColor(1.0, 0.86, 0.35, 1.0)
  public static func Ink() -> HDRColor = new HDRColor(0.02, 0.03, 0.05, 1.0)

  public static func Tone(w: ref<inkWidget>, theme: String, color: String) -> Void {
    switch color {
      case "blue": TKTheme.PaintNew(w, theme, "value"); break;
      case "dim": TKTheme.PaintNew(w, theme, "text"); break;
      case "red": TKTheme.PaintNew(w, theme, "accent"); break;
      case "yellow": TKTheme.Fix(w, theme, TKTheme.Gold()); break;
      case "green": TKTheme.Fix(w, theme, TKTheme.Gain()); break;
      case "grey": TKTheme.Fix(w, theme, new HDRColor(0.45, 0.45, 0.45, 1.0)); break;
      case "orange": TKTheme.Fix(w, theme, new HDRColor(1.0, 0.55, 0.15, 1.0)); break;
      case "purple": TKTheme.Fix(w, theme, new HDRColor(0.72, 0.36, 1.0, 1.0)); break;
      case "pink": TKTheme.Fix(w, theme, new HDRColor(1.0, 0.36, 0.76, 1.0)); break;
      case "cyan": TKTheme.Fix(w, theme, new HDRColor(0.15, 0.86, 0.8, 1.0)); break;
      case "white": TKTheme.Fix(w, theme, new HDRColor(0.92, 0.94, 0.96, 1.0)); break;
      case "amber": TKTheme.Fix(w, theme, TKTheme.Amber()); break;
      default: break;
    }
  }

  public static func Unmark(s: String, out red: Bool, out green: Bool) -> String {
    red = StrBeginsWith(s, "!");
    green = StrBeginsWith(s, "*");
    if red || green {
      return StrMid(s, 1, StrLen(s) - 1);
    }
    green = StrBeginsWith(s, "+");
    return s;
  }
}

public abstract class TKPalette extends IScriptable {
  public func Id() -> String = ""
  public func Color(role: String) -> HDRColor = TKTheme.C(0.37, 0.96, 1.19)
}

public class TKThemeSystem extends ScriptableSystem {
  public let palettes: array<ref<TKPalette>>;

  public static func Get() -> ref<TKThemeSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"TerminalKit.TKThemeSystem") as TKThemeSystem
}

public class TKStyle extends IScriptable {
  public let frame: Int32;
  public let rivets: Bool;
  public let hazard: Bool;
  public let scanlines: Float;
  public let headerPlates: Bool;
  public let segmentedBars: Int32;
  public let openSound: CName;
  public let closeSound: CName;
  public let selectSound: CName;
  public let denySound: CName;
  public let fontFamily: String;
  public let fontStyle: CName;
  public let cutCorner: Float;
}

public abstract class TKScaleSource extends IScriptable {
  public func Value(key: String, def: Float) -> Float { return def; }
  public func Text(text: String) -> String { return text; }
}

public class TKScaleDefaults extends TKScaleSource {}

public class TKScaleSystem extends ScriptableSystem {
  public let source: ref<TKScaleSource>;
  public let active: ref<TKScaleSource>;
  public let font: String;
  public let fontStyle: CName;

  public static func Get() -> ref<TKScaleSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"TerminalKit.TKScaleSystem") as TKScaleSystem
}

public abstract class TKScale {
  public static func Use(source: ref<TKScaleSource>) -> Void {
    let sys = TKScaleSystem.Get();
    if IsDefined(sys) {
      sys.source = source;
    }
  }

  public static func F(key: String, def: Float) -> Float {
    let sys = TKScaleSystem.Get();
    if !IsDefined(sys) {
      return def;
    }
    if IsDefined(sys.active) {
      return sys.active.Value(key, def);
    }
    return IsDefined(sys.source) ? sys.source.Value(key, def) : def;
  }

  public static func Activate(source: ref<TKScaleSource>) -> Void {
    let sys = TKScaleSystem.Get();
    if IsDefined(sys) {
      sys.active = source;
    }
  }

  public static func I(key: String, def: Int32) -> Int32 = RoundF(TKScale.F(key, Cast<Float>(def)))

  public static func T(text: String) -> String {
    let sys = TKScaleSystem.Get();
    if !IsDefined(sys) || StrLen(text) == 0 {
      return text;
    }
    if IsDefined(sys.active) {
      return sys.active.Text(text);
    }
    return IsDefined(sys.source) ? sys.source.Text(text) : text;
  }

  public static func TypeXS() -> Int32 = TKScale.I("type.xs", 24)
  public static func TypeSM() -> Int32 = TKScale.I("type.sm", 28)
  public static func TypeMD() -> Int32 = TKScale.I("type.md", 32)
  public static func TypeLG() -> Int32 = TKScale.I("type.lg", 46)
  public static func TypeXL() -> Int32 = TKScale.I("type.xl", 54)
  public static func SpaceXS() -> Float = TKScale.F("space.xs", 4.0)
  public static func SpaceSM() -> Float = TKScale.F("space.sm", 8.0)
  public static func SpaceMD() -> Float = TKScale.F("space.md", 16.0)
  public static func SpaceLG() -> Float = TKScale.F("space.lg", 24.0)
  public static func ButtonH() -> Float = TKScale.F("button.h", 64.0)
}

public abstract class TKInk {
  public static func Font(t: ref<inkText>, size: Int32, weight: CName) -> Void {
    let sys = TKScaleSystem.Get();
    let own = IsDefined(sys) && StrLen(sys.font) > 0;
    t.SetFontFamily(own ? sys.font : "base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    t.SetFontStyle(own && NotEquals(sys.fontStyle, n"") ? sys.fontStyle : weight);
    t.SetFontSize(size);
    t.SetLetterCase(textLetterCase.UpperCase);
  }

  public static func UseFont(family: String, style: CName) -> Void {
    let sys = TKScaleSystem.Get();
    if IsDefined(sys) {
      sys.font = family;
      sys.fontStyle = style;
    }
  }

  public static func OwnFont(t: ref<inkText>) -> Void {
    let sys = TKScaleSystem.Get();
    if IsDefined(sys) && StrLen(sys.font) > 0 && IsDefined(t) {
      t.SetFontFamily(sys.font);
      if NotEquals(sys.fontStyle, n"") {
        t.SetFontStyle(sys.fontStyle);
      }
    }
  }

  public static func Strip(parent: ref<inkCompoundWidget>, above: Float) -> ref<inkHorizontalPanel> {
    let strip: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    strip.SetMargin(inkMargin(0.0, above, 0.0, 0.0));
    strip.SetHAlign(inkEHorizontalAlign.Left);
    strip.Reparent(parent);
    return strip;
  }

  public static func Plain(parent: ref<inkCompoundWidget>, text: String, size: Int32, weight: CName, above: Float) -> ref<inkText> {
    let t: ref<inkText> = new inkText();
    TKInk.Font(t, size, weight);
    t.SetMargin(inkMargin(0.0, above, 0.0, 0.0));
    t.SetVAlign(inkEVerticalAlign.Bottom);
    t.SetText(text);
    t.Reparent(parent);
    return t;
  }

  public static func Line(parent: ref<inkCompoundWidget>, text: String, size: Int32, weight: CName, color: CName, above: Float) -> ref<inkText> {
    let t = TKInk.Plain(parent, text, size, weight, above);
    t.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
    t.BindProperty(n"tintColor", color);
    return t;
  }

  public static func Tinted(parent: ref<inkCompoundWidget>, text: String, size: Int32, weight: CName, color: HDRColor, above: Float) -> ref<inkText> {
    let t = TKInk.Plain(parent, text, size, weight, above);
    t.SetTintColor(color);
    return t;
  }

  public static func Meter(parent: ref<inkCompoundWidget>, width: Float, height: Float, fraction: Float, color: HDRColor, above: Float) -> Void {
    let track: ref<inkCanvas> = TKInk.Track(parent, width, height, above);
    let fill: ref<inkRectangle> = new inkRectangle();
    fill.SetSize(Vector2(MaxF(2.0, width * ClampF(fraction, 0.0, 1.0)), height));
    fill.SetTintColor(color);
    fill.Reparent(track);
  }

  public static func Track(parent: ref<inkCompoundWidget>, width: Float, height: Float, above: Float) -> ref<inkCanvas> {
    let track: ref<inkCanvas> = new inkCanvas();
    track.SetSize(Vector2(width, height));
    track.SetMargin(inkMargin(0.0, above, 0.0, 0.0));
    track.SetHAlign(inkEHorizontalAlign.Left);
    track.Reparent(parent);

    let bed: ref<inkRectangle> = new inkRectangle();
    bed.SetSize(Vector2(width, height));
    bed.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
    bed.BindProperty(n"tintColor", n"MainColors.DarkRed");
    bed.SetOpacity(0.5);
    bed.Reparent(track);
    return track;
  }

  public static func Rect(parent: ref<inkCompoundWidget>, x: Float, y: Float, w: Float, h: Float) -> ref<inkRectangle> {
    let r: ref<inkRectangle> = new inkRectangle();
    r.SetSize(Vector2(w, h));
    r.SetMargin(inkMargin(x, y, 0.0, 0.0));
    r.Reparent(parent);
    return r;
  }

  public static func Seg(parent: ref<inkCanvas>, a: Vector2, b: Vector2, t: Float, color: HDRColor, opacity: Float) -> Void {
    let dx = b.X - a.X;
    let dy = b.Y - a.Y;
    let len = SqrtF(dx * dx + dy * dy);
    if len < 0.5 {
      return;
    }
    let w = len + t * 0.5;
    let bar: ref<inkRectangle> = new inkRectangle();
    bar.SetAnchor(inkEAnchor.TopLeft);
    bar.SetAnchorPoint(Vector2(0.0, 0.0));
    bar.SetRenderTransformPivot(Vector2(0.5, 0.5));
    bar.SetSize(Vector2(w, t));
    bar.SetMargin(inkMargin((a.X + b.X) / 2.0 - w / 2.0, (a.Y + b.Y) / 2.0 - t / 2.0, 0.0, 0.0));
    bar.SetRotation(Rad2Deg(AtanF(dy, dx)));
    bar.SetTintColor(color);
    bar.SetOpacity(opacity);
    bar.Reparent(parent);
  }

  public static func Lines(s: String, size: Int32, width: Float) -> Float {
    if StrLen(s) == 0 {
      return 0.0;
    }
    let total = 0.0;
    for part in StrSplit(s, "\n") {
      let need = Cast<Float>(Max(1, StrLen(part))) * 0.58 * Cast<Float>(size) / width;
      let n = Cast<Int32>(need);
      if Cast<Float>(n) < need {
        n += 1;
      }
      total += Cast<Float>(Max(1, n));
    }
    return total;
  }
}

public class TKButton extends SimpleButton {
  public func SetFontSize(size: Int32) -> Void { this.m_label.SetFontSize(size); }
  public func GetLabel() -> wref<inkText> { return this.m_label; }

  public static func Make(parent: ref<inkCompoundWidget>, text: String, name: String, width: Float, height: Float, size: Int32) -> ref<TKButton> {
    let b: ref<TKButton> = new TKButton();
    b.CreateInstance();
    let label = TKScale.T(text);
    b.SetText(label);
    b.SetFontSize(TKButton.FitSize(label, width, size));
    TKInk.OwnFont(b.m_label);
    b.ToggleSounds(true);
    b.Reparent(parent);
    b.SetName(StringToName(name));
    let root = b.GetRootWidget();
    root.SetSize(Vector2(width, height));
    root.SetAnchorPoint(Vector2(0.0, 0.0));
    return b;
  }

  public static func FitSize(text: String, width: Float, size: Int32) -> Int32 {
    let room = width - 36.0;
    let chars = Cast<Float>(Max(1, StrLen(text)));
    let fit = Cast<Int32>(room / (chars * 0.55));
    return Max(16, Min(size, fit));
  }
}

public class TKSlider extends IScriptable {
  public let row: Int32;
  public let min: Int32;
  public let step: Int32;
  public let value: Int32;
  public let suffix: String;
  public let segs: array<wref<inkRectangle>>;
  public let readout: wref<inkText>;
}

public class TKView extends IScriptable {

  private let m_content: wref<inkVerticalPanel>;
  private let m_title: wref<inkText>;
  private let m_subtitle: wref<inkText>;
  private let m_message: wref<inkText>;
  private let m_width: Float;
  private let m_theme: String = "hud";
  private let m_style: ref<TKStyle>;
  private let m_frame: ref<TKFrame>;
  private let m_provider: ref<TKContent>;
  private let m_chrome: array<wref<inkWidget>>;
  private let m_roles: array<String>;
  private let m_tabs: array<ref<TKButton>>;

  private let m_scroll: wref<inkScrollArea>;
  private let m_scrollH: Float;
  private let m_scrollY: Float;
  private let m_bar: wref<inkRectangle>;
  private let m_barTrack: wref<inkRectangle>;
  public let grown: Float;

  private let m_history: array<String>;
  private let m_noPush: Bool;

  private let m_tipLayer: wref<inkCanvas>;
  private let m_tips: array<String>;
  private let m_tip: wref<inkWidget>;
  private let m_popup: wref<inkWidget>;
  private let m_blocker: wref<inkWidget>;
  private let m_dlgAction: String;
  private let m_dlgArg: String;
  private let m_dropRow: Int32;

  private let m_liveRows: array<Int32>;
  private let m_liveFills: array<wref<inkRectangle>>;
  private let m_liveTexts: array<wref<inkText>>;
  private let m_liveWidths: array<Float>;
  private let m_liveStarts: array<Float>;
  private let m_liveEnds: array<Float>;
  private let m_liveModes: array<Int32>;
  private let m_liveFired: array<Bool>;
  private let m_liveGen: Int32;

  private let m_data: ref<TKPage>;
  private let m_page: String;
  private let m_arg: String;
  private let m_buttons: array<ref<TKButton>>;
  private let m_sliders: array<ref<TKSlider>>;
  private let m_inputs: array<ref<HubTextInput>>;
  private let m_inputKeys: array<String>;
  private let m_drag: Int32;
  private let m_custom: array<ref<TKCustom>>;

  public let linkRows: Int32;
  public let tableLine: Int32;
  private let m_cards: wref<inkHorizontalPanel>;
  private let m_cardCount: Int32;
  private let m_gridKind: Int32;
  private let m_split: wref<inkHorizontalPanel>;
  private let m_pageContent: wref<inkVerticalPanel>;
  private let m_pageWidth: Float;

  private let m_host: wref<TKRegions>;
  private let m_region: String;
  private let m_noScroll: Bool;

  private let m_hitActions: array<String>;
  private let m_hitArgs: array<String>;
  private let m_hitTips: array<String>;
  private let m_hitOff: array<Bool>;

  private let m_holdName: String;
  private let m_holdFill: wref<inkWidget>;
  private let m_holdProxy: ref<inkAnimProxy>;

  private let m_keyNames: array<CName>;
  private let m_keyActions: array<String>;
  private let m_keyArgs: array<String>;
  private let m_keyOff: array<Bool>;

  private let m_focusW: array<wref<inkWidget>>;
  private let m_focusNames: array<String>;
  private let m_focusOff: array<Bool>;
  private let m_focus: Int32;
  private let m_focusOpacity: Float;

  public func Bind(content: ref<inkVerticalPanel>, title: ref<inkText>, subtitle: ref<inkText>, message: ref<inkText>, width: Float) -> Void {
    this.m_focus = -1;
    this.m_content = content;
    this.m_title = title;
    this.m_subtitle = subtitle;
    this.m_message = message;
    this.m_width = width;
    this.Chrome(title, "title");
    this.Chrome(subtitle, "text");
    this.Chrome(message, "value");
  }

  public func BindScroll(area: ref<inkScrollArea>, height: Float, track: ref<inkRectangle>, bar: ref<inkRectangle>) -> Void {
    this.m_scroll = area;
    this.m_scrollH = height;
    this.m_barTrack = track;
    this.m_bar = bar;
    this.m_scrollY = 0.0;

    area.SetInteractive(true);
    area.RegisterToCallback(n"OnRelative", this, n"OnAreaRelative");
  }

  public func BindRegion(host: ref<TKRegions>, name: String, content: ref<inkVerticalPanel>, width: Float, fixed: Bool) -> Void {
    this.m_focus = -1;
    this.m_host = host;
    this.m_region = name;
    this.m_noScroll = fixed;
    this.m_content = content;
    this.m_width = width;
  }

  public func Region() -> String = this.m_region
  public func Host() -> ref<TKRegions> = this.m_host

  public func Height() -> Float = this.m_scrollH

  public func SetTipLayer(layer: ref<inkCanvas>) -> Void { this.m_tipLayer = layer; }

  public func SetContent(provider: ref<TKContent>) -> Void { this.m_provider = provider; }
  public func SetFrame(frame: ref<TKFrame>) -> Void { this.m_frame = frame; }
  public func FrameOf() -> ref<TKFrame> = this.m_frame
  public func Owner() -> ref<inkCustomController> = IsDefined(this.m_frame) ? this.m_frame.Owner() : null
  public func Provider() -> ref<TKContent> = this.m_provider

  public func Chrome(w: ref<inkWidget>, role: String) -> Void {
    ArrayPush(this.m_chrome, w);
    ArrayPush(this.m_roles, role);
    TKTheme.Paint(w, this.m_theme, role);
  }

  public func AddTab(parent: ref<inkCompoundWidget>, text: String, page: String, width: Float, height: Float, size: Int32) -> ref<TKButton> {
    let b = TKButton.Make(parent, text, "tab_" + page, width, height, size);
    b.RegisterToCallback(n"OnBtnClick", this, n"OnTabClick");
    ArrayPush(this.m_tabs, b);
    TKTheme.Paint(b.GetLabel(), this.m_theme, "value");
    return b;
  }

  public func CurrentPage() -> String { return this.m_page; }
  public func CurrentArg() -> String { return this.m_arg; }

  public func SetArg(arg: String) -> Void { this.m_arg = arg; }
  public func Theme() -> String { return this.m_theme; }

  public func SetStyle(style: ref<TKStyle>) -> Void { this.m_style = style; }
  public func Style() -> ref<TKStyle> {
    if !IsDefined(this.m_style) {
      this.m_style = new TKStyle();
    }
    return this.m_style;
  }

  public func Segments(parent: ref<inkCompoundWidget>, x: Float, y: Float, w: Float, h: Float) -> Void {
    let n = this.Style().segmentedBars;
    if n < 2 {
      return;
    }
    let gap = MaxF(2.0, MinF(5.0, w / Cast<Float>(n) * 0.16));
    let k = 1;
    while k < n {
      let cut = TKInk.Rect(parent, x + w * Cast<Float>(k) / Cast<Float>(n) - gap / 2.0, y, gap, h);
      cut.SetTintColor(TKTheme.Ink());
      k += 1;
    }
  }

  protected cb func OnDeniedPress(e: ref<inkPointerEvent>) -> Bool {
    if e.IsAction(n"click") {
      this.DenySound();
    }
    return false;
  }

  private func ClickSound() -> Void {
    let sound = this.Style().selectSound;
    if NotEquals(sound, n"") {
      let player = GetPlayer(GetGameInstance());
      if IsDefined(player) {
        GameObject.PlaySound(player, sound);
      }
    }
  }
  public func Content() -> ref<inkVerticalPanel> { return this.m_content; }
  public func Page() -> ref<TKPage> { return this.m_data; }
  public func RowWidth() -> Float { return this.m_width - 40.0; }
  public func Width() -> Float { return this.m_width; }

  public func StopCustom() -> Void {
    for c in this.m_custom {
      if IsDefined(c) {
        c.Stop();
      }
    }
    ArrayClear(this.m_custom);
  }

  private func SetTheme(theme: String) -> Void {
    if Equals(theme, "") || Equals(theme, this.m_theme) {
      return;
    }
    this.m_theme = theme;
    let i = 0;
    while i < ArraySize(this.m_chrome) {
      TKTheme.Paint(this.m_chrome[i], theme, this.m_roles[i]);
      i += 1;
    }
    for tab in this.m_tabs {
      TKTheme.Paint(tab.GetLabel(), theme, "value");
    }
  }

  public func OnWheel(e: ref<inkPointerEvent>) -> Bool {
    if !IsDefined(this.m_scroll) || !e.IsAction(n"mouse_wheel") || e.IsHandled() {
      return false;
    }
    if (IsDefined(this.m_data) && this.m_data.wheelReserved) || this.m_noScroll {
      return false;
    }
    let d = e.GetAxisData();
    if d == 0.0 {
      return false;
    }
    this.ScrollTo(this.m_scrollY - d * TKScale.F("scroll.step", 140.0));
    e.Handle();
    return true;
  }

  protected cb func OnAreaRelative(e: ref<inkPointerEvent>) -> Bool {
    return this.OnWheel(e);
  }

  public func Grew(h: Float) -> Void { this.grown += h; }

  private func ScrollMax() -> Float {
    if !IsDefined(this.m_content) {
      return 0.0;
    }
    return MaxF(0.0, MaxF(this.m_content.GetDesiredSize().Y, this.grown) - this.m_scrollH);
  }

  public func ScrollTo(y: Float) -> Void {
    if !IsDefined(this.m_scroll) || !IsDefined(this.m_content) {
      return;
    }
    let max = this.ScrollMax();
    this.m_scrollY = ClampF(y, 0.0, max);
    this.m_content.SetTranslation(Vector2(0.0, -this.m_scrollY));
    this.PaintBar(max);
  }

  private func PaintBar(max: Float) -> Void {
    if !IsDefined(this.m_bar) || !IsDefined(this.m_barTrack) {
      return;
    }
    let show = max > 1.0;
    this.m_bar.SetVisible(show);
    this.m_barTrack.SetVisible(show);
    if !show {
      return;
    }
    let total = max + this.m_scrollH;
    let h = MaxF(24.0, this.m_scrollH * this.m_scrollH / total);
    this.m_bar.SetSize(Vector2(this.m_bar.GetSize().X, h));
    this.m_bar.SetMargin(inkMargin(0.0, (this.m_scrollH - h) * (this.m_scrollY / max), 0.0, 0.0));
  }

  public func Settle() -> Void {
    this.ScrollTo(this.m_scrollY);
  }

  public func Back() -> Bool {
    if IsDefined(this.m_host) {
      return this.m_host.Back();
    }
    let n = ArraySize(this.m_history);
    if n == 0 {
      return false;
    }
    let last = this.m_history[n - 1];
    ArrayPop(this.m_history);
    this.m_noPush = true;
    this.Show(StrBeforeFirst(last, "~"), StrAfterFirst(last, "~"), "");
    return true;
  }

  public func Hoverable(w: ref<inkWidget>, tip: String) -> Void {
    if StrLen(tip) == 0 || !IsDefined(w) || !IsDefined(this.m_tipLayer) {
      return;
    }
    w.SetName(StringToName("tip_" + IntToString(ArraySize(this.m_tips))));
    ArrayPush(this.m_tips, tip);
    w.SetInteractive(true);
    w.RegisterToCallback(n"OnHoverOver", this, n"OnTipOver");
    w.RegisterToCallback(n"OnHoverOut", this, n"OnTipOut");
  }

  protected cb func OnTipOver(e: ref<inkPointerEvent>) -> Bool {
    let name = NameToString(e.GetTarget().GetName());
    if !StrBeginsWith(name, "tip_") || !IsDefined(this.m_tipLayer) {
      return false;
    }
    let i = StringToInt(StrAfterFirst(name, "tip_"), -1);
    if i < 0 || i >= ArraySize(this.m_tips) {
      return false;
    }
    this.ShowTip(this.m_tips[i], e);
    return false;
  }

  private func ShowTip(text: String, e: ref<inkPointerEvent>) -> Void {
    if StrLen(text) == 0 || !IsDefined(this.m_tipLayer) {
      return;
    }
    this.HideTip();
    let at = WidgetUtils.GlobalToLocal(this.m_tipLayer, e.GetScreenSpacePosition());
    let w = TKScale.F("tip.w", 640.0);
    let font = TKScale.I("note", 26);
    let h = TKInk.Lines(text, font, w - 40.0) * Cast<Float>(font) * 1.35 + 36.0;
    let x = MinF(at.X + 24.0, MaxF(0.0, this.m_tipLayer.GetSize().X - w));
    let y = MaxF(0.0, at.Y - h - 12.0);
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(w, h));
    box.SetMargin(inkMargin(x, y, 0.0, 0.0));
    box.Reparent(this.m_tipLayer);
    let fill = TKInk.Rect(box, 0.0, 0.0, w, h);
    fill.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    fill.SetOpacity(1.0);
    let fill2 = TKInk.Rect(box, 0.0, 0.0, w, h);
    fill2.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    box.SetOpacity(1.0);
    this.Frame(box, w, h, 2.0, "value", 0.9);
    let t = this.Text(box, text, font, n"Regular", "text", 0.0);
    t.SetLetterCase(textLetterCase.OriginalCase);
    t.SetMargin(inkMargin(20.0, 14.0, 0.0, 0.0));
    t.SetVAlign(inkEVerticalAlign.Top);
    t.SetWrapping(true, w - 40.0);
    this.m_tip = box;
  }

  public func Hit(w: ref<inkWidget>, action: String, arg: String, tip: String, opt off: Bool) -> Void {
    if !IsDefined(w) {
      return;
    }
    w.SetName(StringToName("hit_" + IntToString(ArraySize(this.m_hitActions))));
    ArrayPush(this.m_hitActions, action);
    ArrayPush(this.m_hitArgs, arg);
    ArrayPush(this.m_hitTips, tip);
    ArrayPush(this.m_hitOff, off);
    this.AddFocus(w, NameToString(w.GetName()), off);
    w.SetInteractive(true);
    w.RegisterToCallback(n"OnHoverOver", this, n"OnHitOver");
    w.RegisterToCallback(n"OnHoverOut", this, n"OnHitOut");
    w.RegisterToCallback(n"OnRelease", this, n"OnHitRelease");
    w.RegisterToCallback(n"OnRelative", this, n"OnHitRelative");
  }

  private func HitIndex(e: ref<inkPointerEvent>) -> Int32 {
    let target = e.GetCurrentTarget();
    if !IsDefined(target) {
      return -1;
    }
    let name = NameToString(target.GetName());
    if !StrBeginsWith(name, "hit_") {
      return -1;
    }
    let i = StringToInt(StrAfterFirst(name, "hit_"), -1);
    return i >= 0 && i < ArraySize(this.m_hitActions) ? i : -1;
  }

  protected cb func OnHitOver(e: ref<inkPointerEvent>) -> Bool {
    let i = this.HitIndex(e);
    if i >= 0 {
      this.ShowTip(this.m_hitTips[i], e);
      if IsDefined(this.m_provider) {
        this.m_provider.HitHover(this, this.m_hitActions[i], this.m_hitArgs[i], true);
      }
    }
    return false;
  }

  protected cb func OnHitOut(e: ref<inkPointerEvent>) -> Bool {
    let i = this.HitIndex(e);
    this.HideTip();
    if i >= 0 && IsDefined(this.m_provider) {
      this.m_provider.HitHover(this, this.m_hitActions[i], this.m_hitArgs[i], false);
    }
    return false;
  }

  protected cb func OnHitRelease(e: ref<inkPointerEvent>) -> Bool {
    let i = this.HitIndex(e);
    if i < 0 || !e.IsAction(n"click") {
      return false;
    }
    if this.m_hitOff[i] {
      this.DenySound();

      return true;
    }
    this.ClickSound();
    this.HideTip();
    this.Act(this.m_hitActions[i], this.m_hitArgs[i]);
    return true;
  }

  protected cb func OnHitRelative(e: ref<inkPointerEvent>) -> Bool {
    let i = this.HitIndex(e);
    if i < 0 || !e.IsAction(n"mouse_wheel") || e.IsHandled() || !IsDefined(this.m_provider) {
      return false;
    }
    let d = e.GetAxisData();
    if d != 0.0 && this.m_provider.HitWheel(this, this.m_hitActions[i], this.m_hitArgs[i], d) {
      e.Handle();
      return true;
    }
    return false;
  }

  protected cb func OnTipOut(e: ref<inkPointerEvent>) -> Bool {
    this.HideTip();
    return false;
  }

  private func HideTip() -> Void {
    if IsDefined(this.m_tip) && IsDefined(this.m_tipLayer) {
      this.m_tipLayer.RemoveChild(this.m_tip);
    }
    this.m_tip = null;
  }

  protected cb func OnTabClick(widget: wref<inkWidget>) -> Bool {
    this.RunTab(StrAfterFirst(NameToString(widget.GetName()), "tab_"));
    return true;
  }

  private func RunTab(target: String) -> Void {
    this.ClickSound();
    if StrContains(target, "~") {
      this.Show(StrBeforeFirst(target, "~"), StrAfterFirst(target, "~"), "");
    } else {
      this.Show(target, "", "");
    }
  }

  protected cb func OnActClick(widget: wref<inkWidget>) -> Bool {
    this.RunAct(StrAfterFirst(NameToString(widget.GetName()), "act_"));
    return true;
  }

  private func RunAct(id: String) -> Void {
    let n = 0;
    if StrContains(id, "_") {
      n = StringToInt(StrAfterFirst(id, "_"), 0);
      id = StrBeforeFirst(id, "_");
    }
    let i = StringToInt(id, -1);
    if !IsDefined(this.m_data) || i < 0 || i >= this.m_data.Count() {
      return;
    }
    let row = this.m_data.Row(i);
    if n < 0 || n >= ArraySize(row.actions) {
      return;
    }
    let arg = row.args[n];
    this.ClickSound();
    if row.kind == TKKind.Search() {
      arg = this.FieldText(row.extra);
    }

    let label = n < ArraySize(row.labels) ? row.labels[n] : "";
    if StrBeginsWith(label, "!") {
      label = StrAfterFirst(label, "!");
    }
    if StrBeginsWith(label, "?") {
      let yes = StrAfterFirst(label, "?");

      let named = row.kind == TKKind.Card() || row.kind == TKKind.File() || row.kind == TKKind.Posting() || row.kind == TKKind.Run();
      let about = StrContains(row.text, "|") ? TKStr.Part(row.text, "|", named ? 1 : 0) : row.text;
      let red: Bool;
      let green: Bool;
      about = TKTheme.Unmark(about, red, green);
      this.Dialog(yes + "?" + (StrLen(about) > 0 ? "\n" + about : ""), yes, row.actions[n], arg);
      return;
    }
    this.Act(row.actions[n], arg);
  }

  public func Act(action: String, arg: String) -> Void {
    if IsDefined(this.m_host) {
      this.m_host.ActFrom(this, action, arg);
      return;
    }
    let act: ref<TKPage> = new TKPage();
    act.content = this.m_provider;
    act.page = this.m_page;
    this.Fields(act);
    act.Act(action, arg);
    if act.rebuild && IsDefined(this.m_provider) {
      this.m_provider.Rebuild();
    }
    if act.skipRedraw {
      return;
    }
    let next = StrLen(act.nextPage) > 0 ? act.nextPage : this.m_page;
    let nextArg = StrLen(act.nextPage) > 0 ? act.nextArg : this.m_arg;
    this.Show(next, nextArg, act.message);
    if StrLen(act.confirmAction) > 0 {
      this.Dialog(act.confirmText, StrLen(act.confirmYes) > 0 ? act.confirmYes : "CONFIRM", act.confirmAction, act.confirmArg);
    }
  }

  public func Clickable(w: ref<inkWidget>, name: String) -> Void {
    if !StrBeginsWith(name, "ovl_") {
      this.AddFocus(w, name, false);
    }
    w.SetName(StringToName(name));
    w.SetInteractive(true);
    w.RegisterToCallback(n"OnRelease", this, n"OnControlRelease");
  }

  public func ControlButton(parent: ref<inkCompoundWidget>, label: String, name: String, width: Float, height: Float, size: Int32) -> ref<TKButton> {
    let b = TKButton.Make(parent, label, name, width, height, size);
    TKTheme.Paint(b.GetLabel(), this.m_theme, "value");
    b.GetRootWidget().RegisterToCallback(n"OnRelease", this, n"OnControlRelease");
    ArrayPush(this.m_buttons, b);
    if !StrBeginsWith(name, "dlg_") && !StrBeginsWith(name, "ddo_") {
      this.AddFocus(b.GetRootWidget(), name, false);
    }
    return b;
  }

  private static func Prefix(arg: String) -> String = StrLen(arg) > 0 ? arg + ":" : ""

  protected cb func OnControlRelease(e: ref<inkPointerEvent>) -> Bool {
    if !e.IsAction(n"click") {
      return false;
    }
    let target = e.GetCurrentTarget();
    if !IsDefined(target) {
      return false;
    }
    return this.RunControl(NameToString(target.GetName()), e);
  }

  private func RunControl(name: String, e: ref<inkPointerEvent>) -> Bool {
    if Equals(name, "dlg_yes") {
      let action = this.m_dlgAction;
      let arg = this.m_dlgArg;
      this.CloseOverlay();
      this.Act(action, arg);
      return true;
    }
    if Equals(name, "dlg_no") || Equals(name, "ovl_block") {
      this.CloseOverlay();
      return true;
    }
    if StrBeginsWith(name, "ddo_") {
      let k = StringToInt(StrAfterFirst(name, "ddo_"), -1);
      let row = this.m_data.Row(this.m_dropRow);
      this.CloseOverlay();
      if k >= 0 && k < ArraySize(row.args) {
        this.Act(row.action, TKView.Prefix(row.arg) + row.args[k]);
      }
      return true;
    }
    if !IsDefined(this.m_data) {
      return false;
    }
    if StrBeginsWith(name, "dd_") {
      this.OpenDrop(StringToInt(StrAfterFirst(name, "dd_"), -1), e);
      return true;
    }
    if StrBeginsWith(name, "ch_") {
      let row = this.m_data.Row(StringToInt(StrAfterFirst(name, "ch_"), -1));
      if StrLen(row.action) > 0 {
        this.Act(row.action, row.arg);
      }
      return true;
    }
    if StrBeginsWith(name, "ck_") {
      let row = this.m_data.Row(StringToInt(StrAfterFirst(name, "ck_"), -1));
      this.Act(row.action, TKView.Prefix(row.arg) + (row.on ? "0" : "1"));
      return true;
    }
    if StrBeginsWith(name, "so_") {
      let rest = StrAfterFirst(name, "so_");
      let row = this.m_data.Row(StringToInt(StrBeforeFirst(rest, "_"), -1));
      this.Act(row.action, TKView.Prefix(row.arg) + StrAfterFirst(rest, "_"));
      return true;
    }
    return false;
  }

  private func Blocker() -> Void {
    let layer = this.m_tipLayer;
    let block: ref<inkRectangle> = new inkRectangle();
    block.SetSize(layer.GetSize());
    block.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    block.SetOpacity(0.35);
    block.Reparent(layer);
    this.Clickable(block, "ovl_block");
    this.m_blocker = block;
  }

  public func Dialog(text: String, yes: String, action: String, arg: String) -> Void {
    if !IsDefined(this.m_tipLayer) {
      this.Act(action, arg);
      return;
    }
    this.CloseOverlay();
    this.HideTip();
    this.Blocker();
    this.m_dlgAction = action;
    this.m_dlgArg = arg;
    let layer = this.m_tipLayer;
    let w = TKScale.F("dialog.w", 1000.0);
    let font = TKScale.I("row.title", 32);
    let textH = TKInk.Lines(text, font, w - 80.0) * Cast<Float>(font) * 1.35;
    let bh = TKScale.ButtonH();
    let h = textH + bh + 130.0;
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(w, h));
    let size = layer.GetSize();
    box.SetMargin(inkMargin(MaxF(0.0, (size.X - w) / 2.0), MaxF(0.0, (size.Y - h) / 2.5), 0.0, 0.0));
    box.Reparent(layer);
    let fill = TKInk.Rect(box, 0.0, 0.0, w, h);
    fill.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    let fill2 = TKInk.Rect(box, 0.0, 0.0, w, h);
    fill2.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    this.Frame(box, w, h, 3.0, "accent", 1.0);
    let t = this.Text(box, text, font, n"Medium", "value", 0.0);
    t.SetWrapping(true, w - 80.0);
    t.SetMargin(inkMargin(40.0, 40.0, 0.0, 0.0));
    t.SetVAlign(inkEVerticalAlign.Top);
    let bw = TKScale.F("dialog.button", 300.0);
    let bar: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    bar.SetAnchor(inkEAnchor.BottomRight);
    bar.SetAnchorPoint(Vector2(1.0, 1.0));
    bar.SetMargin(inkMargin(0.0, 0.0, 40.0, 34.0));
    bar.Reparent(box);
    this.ControlButton(bar, "CANCEL", "dlg_no", bw, bh, TKScale.I("button.font", 30));
    this.ControlButton(bar, yes, "dlg_yes", bw, bh, TKScale.I("button.font", 30)).GetRootWidget().SetMargin(inkMargin(20.0, 0.0, 0.0, 0.0));
    this.m_popup = box;
  }

  private func OpenDrop(i: Int32, e: ref<inkPointerEvent>) -> Void {
    if !IsDefined(this.m_tipLayer) || i < 0 || i >= this.m_data.Count() {
      return;
    }
    this.CloseOverlay();
    this.HideTip();
    let row = this.m_data.Row(i);
    this.m_dropRow = i;
    this.Blocker();
    this.m_blocker.SetOpacity(0.01);
    let layer = this.m_tipLayer;

    let at = IsDefined(e) ? WidgetUtils.GlobalToLocal(layer, e.GetScreenSpacePosition()) : Vector2(layer.GetSize().X / 2.0, layer.GetSize().Y / 3.0);
    let bw = TKScale.F("dropdown.w", 420.0);
    let bh = TKScale.F("dropdown.h", 56.0);
    let n = ArraySize(row.labels);
    let h = Cast<Float>(n) * (bh + 6.0) + 16.0;
    let size = layer.GetSize();
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(bw + 16.0, h));
    box.SetMargin(inkMargin(ClampF(at.X - bw / 2.0, 0.0, MaxF(0.0, size.X - bw - 16.0)), ClampF(at.Y + 30.0, 0.0, MaxF(0.0, size.Y - h)), 0.0, 0.0));
    box.Reparent(layer);
    let fill = TKInk.Rect(box, 0.0, 0.0, bw + 16.0, h);
    fill.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    this.Frame(box, bw + 16.0, h, 2.0, "value", 1.0);
    let list: ref<inkVerticalPanel> = new inkVerticalPanel();
    list.SetMargin(inkMargin(8.0, 8.0, 0.0, 0.0));
    list.Reparent(box);
    let k = 0;
    while k < n {
      let b = this.ControlButton(list, row.labels[k], "ddo_" + IntToString(k), bw, bh, 26);
      b.GetRootWidget().SetMargin(inkMargin(0.0, 0.0, 0.0, 6.0));
      b.SetDisabled(k < ArraySize(row.args) && Equals(row.args[k], row.extra));
      k += 1;
    }
    this.m_popup = box;
  }

  public func CloseOverlay() -> Bool {
    if IsDefined(this.m_host) {
      return this.m_host.CloseOverlay();
    }
    return this.CloseOwnOverlay();
  }

  public func CloseOwnOverlay() -> Bool {
    let had = IsDefined(this.m_popup) || IsDefined(this.m_blocker);
    if IsDefined(this.m_tipLayer) {
      if IsDefined(this.m_popup) {
        this.m_tipLayer.RemoveChild(this.m_popup);
      }
      if IsDefined(this.m_blocker) {
        this.m_tipLayer.RemoveChild(this.m_blocker);
      }
    }
    this.m_popup = null;
    this.m_blocker = null;
    return had;
  }

  public func AddLive(row: Int32, fill: ref<inkRectangle>, text: ref<inkText>, width: Float, start: Float, end: Float, mode: Int32) -> Void {
    ArrayPush(this.m_liveRows, row);
    ArrayPush(this.m_liveFills, fill);
    ArrayPush(this.m_liveTexts, text);
    ArrayPush(this.m_liveWidths, width);
    ArrayPush(this.m_liveStarts, start);
    ArrayPush(this.m_liveEnds, end);
    ArrayPush(this.m_liveModes, mode);
    ArrayPush(this.m_liveFired, false);
  }

  public func StopLive() -> Void {
    this.m_liveGen += 1;
    ArrayClear(this.m_liveRows);
    ArrayClear(this.m_liveFills);
    ArrayClear(this.m_liveTexts);
    ArrayClear(this.m_liveWidths);
    ArrayClear(this.m_liveStarts);
    ArrayClear(this.m_liveEnds);
    ArrayClear(this.m_liveModes);
    ArrayClear(this.m_liveFired);
  }

  private func StartLive() -> Void {
    if ArraySize(this.m_liveRows) > 0 {
      this.LiveStep(this.m_liveGen);
    }
  }

  public func LiveStep(gen: Int32) -> Void {
    if gen != this.m_liveGen || ArraySize(this.m_liveRows) == 0 {
      return;
    }
    let now = TKClock.Now();
    let fire = -1;
    let k = 0;
    while k < ArraySize(this.m_liveRows) {
      let start = this.m_liveStarts[k];
      let end = this.m_liveEnds[k];
      let span = MaxF(1.0, end - start);
      let frac: Float;
      let text: String;
      if this.m_liveModes[k] == 0 {
        frac = ClampF((end - now) / span, 0.0, 1.0);
        text = now < end ? TKClock.Left(end - now) : "DONE";
      } else {
        frac = ClampF((now - start) / span, 0.0, 1.0);
        text = IntToString(FloorF(frac * 100.0)) + "%";
      }
      if IsDefined(this.m_liveFills[k]) {
        this.m_liveFills[k].SetSize(Vector2(MaxF(2.0, this.m_liveWidths[k] * frac), this.m_liveFills[k].GetSize().Y));
      }
      if IsDefined(this.m_liveTexts[k]) {
        this.m_liveTexts[k].SetText(text);
      }
      if now >= end && !this.m_liveFired[k] {
        this.m_liveFired[k] = true;

        let lr = this.m_data.Row(this.m_liveRows[k]);
        if fire < 0 && lr.kind == TKKind.Live() && StrLen(lr.action) > 0 {
          fire = this.m_liveRows[k];
        }
      }
      k += 1;
    }
    if fire >= 0 {
      let row = this.m_data.Row(fire);
      this.Act(row.action, row.arg);
      return;
    }
    let cb = new TKLiveTick();
    cb.view = this;
    cb.gen = gen;
    GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(cb, 1.0, false);
  }

  private func Clear(page: String, arg: String) -> Void {
    this.m_page = page;
    this.m_arg = arg;
    this.StopCustom();
    this.StopLive();
    this.CloseOwnOverlay();
    this.HideTip();
    ArrayClear(this.m_tips);
    ArrayClear(this.m_hitActions);
    ArrayClear(this.m_hitArgs);
    ArrayClear(this.m_hitTips);
    ArrayClear(this.m_hitOff);
    this.grown = 0.0;
    this.m_content.RemoveAllChildren();
    ArrayClear(this.m_buttons);
    ArrayClear(this.m_sliders);
    ArrayClear(this.m_inputs);
    ArrayClear(this.m_inputKeys);
    this.m_drag = -1;
    this.HoldStop();
    ArrayClear(this.m_keyNames);
    ArrayClear(this.m_keyActions);
    ArrayClear(this.m_keyArgs);
    ArrayClear(this.m_keyOff);
    ArrayClear(this.m_focusW);
    ArrayClear(this.m_focusNames);
    ArrayClear(this.m_focusOff);
    this.linkRows = 0;
    this.tableLine = 0;
    this.m_cards = null;
    this.m_cardCount = 0;
    this.m_split = null;
  }

  private func DenySound() -> Void {
    let player = GetPlayer(GetGameInstance());
    if IsDefined(player) && NotEquals(this.Style().denySound, n"") {
      GameObject.PlaySound(player, this.Style().denySound);
    }
  }
  public func Show(page: String, arg: String, message: String) -> Void {
    if IsDefined(this.m_host) {
      this.m_host.Show(page, arg, message);
      return;
    }
    if !IsDefined(this.m_content) {
      return;
    }
    let same = Equals(page, this.m_page) && Equals(arg, this.m_arg);
    if !same && StrLen(this.m_page) > 0 && !this.m_noPush {
      ArrayPush(this.m_history, this.m_page + "~" + this.m_arg);
      while ArraySize(this.m_history) > 30 {
        ArrayErase(this.m_history, 0);
      }
    }
    this.m_noPush = false;
    this.Clear(page, arg);

    this.m_data = new TKPage();
    this.m_data.content = this.m_provider;
    this.m_data.page = page;
    this.m_data.Request(page, arg);

    if IsDefined(this.m_scroll) {
      this.m_scroll.SetUseInternalMask(!this.m_data.wheelReserved);
    }
    this.SetTheme(this.m_data.theme);
    this.m_message.SetText(TKScale.T(message));

    let section = StrLen(this.m_data.section) > 0 ? this.m_data.section : page;
    let i = 0;
    while i < ArraySize(this.m_tabs) {
      this.m_tabs[i].SetDisabled(Equals(NameToString(this.m_tabs[i].GetName()), "tab_" + section));
      i += 1;
    }
    if IsDefined(this.m_frame) {
      this.m_frame.SetBare(this.m_data.bare);
    }
    if !this.m_data.answered {
      this.m_title.SetText(TKScale.T("LINK OFFLINE"));
      this.m_subtitle.SetText(TKScale.T("Load a save first, then try again."));
      this.m_subtitle.SetVisible(true);
      return;
    }
    this.m_title.SetText(TKScale.T(this.m_data.title));
    this.m_subtitle.SetText(TKScale.T(this.m_data.subtitle));

    this.m_subtitle.SetVisible(StrLen(this.m_data.subtitle) > 0 && !this.m_data.bare);
    if StrLen(this.m_data.message) > 0 {
      this.m_message.SetText(TKScale.T(this.m_data.message));
    }

    let content = this.m_content;
    let width = this.m_width;
    i = 0;
    while i < this.m_data.Count() {
      this.Draw(i, this.m_data.Row(i));
      i += 1;
    }
    this.m_content = content;
    this.m_width = width;

    this.ScrollTo(same ? this.m_scrollY : 0.0);
    this.StartLive();
    this.RestoreFocus();
  }

  public func Present(data: ref<TKPage>, page: String, arg: String, keep: Bool) -> Void {
    if !IsDefined(this.m_content) {
      return;
    }
    this.Clear(page, arg);

    this.m_data = data;
    if IsDefined(this.m_scroll) {
      this.m_scroll.SetUseInternalMask(!data.wheelReserved);
    }
    this.SetTheme(data.theme);
    let content = this.m_content;
    let width = this.m_width;
    let i = 0;
    while i < data.Count() {
      this.Draw(i, data.Row(i));
      i += 1;
    }
    this.m_content = content;
    this.m_width = width;
    this.ScrollTo(keep ? this.m_scrollY : 0.0);
    this.StartLive();
    this.RestoreFocus();
  }

  public func SlideIn() -> Void {
    if !IsDefined(this.m_scroll) {
      return;
    }
    let def: ref<inkAnimDef> = new inkAnimDef();
    let move: ref<inkAnimTranslation> = new inkAnimTranslation();
    move.SetStartTranslation(Vector2(MinF(160.0, this.m_width * 0.2), 0.0));
    move.SetEndTranslation(Vector2(0.0, 0.0));
    move.SetDuration(0.22);
    move.SetType(inkanimInterpolationType.Quadratic);
    move.SetMode(inkanimInterpolationMode.EasyOut);
    def.AddInterpolator(move);
    TKPopup.Fade(def, 0.0, 1.0, 0.18, 0.0);
    this.m_scroll.PlayAnimation(def);
  }

  public func AddKey(name: CName, action: String, arg: String, off: Bool) -> Void {
    ArrayPush(this.m_keyNames, name);
    ArrayPush(this.m_keyActions, action);
    ArrayPush(this.m_keyArgs, arg);
    ArrayPush(this.m_keyOff, off);
  }

  public func PressKey(e: ref<inkPointerEvent>) -> Bool {
    let k = 0;
    while k < ArraySize(this.m_keyNames) {
      if NotEquals(this.m_keyNames[k], n"") && e.IsAction(this.m_keyNames[k]) {
        if this.m_keyOff[k] {
          this.DenySound();

        } else {
          this.ClickSound();
          this.Act(this.m_keyActions[k], this.m_keyArgs[k]);
        }
        return true;
      }
      k += 1;
    }
    return false;
  }

  public func AddFocus(w: ref<inkWidget>, name: String, off: Bool) -> Void {
    if !IsDefined(w) {
      return;
    }
    ArrayPush(this.m_focusW, w);
    ArrayPush(this.m_focusNames, name);
    ArrayPush(this.m_focusOff, off);
  }

  public func Focusables() -> Int32 = ArraySize(this.m_focusW)
  public func HasFocus() -> Bool = this.m_focus >= 0

  public func Focus(i: Int32) -> Void {
    if this.m_focus >= 0 && this.m_focus < ArraySize(this.m_focusW) && IsDefined(this.m_focusW[this.m_focus]) {
      this.m_focusW[this.m_focus].SetScale(Vector2(1.0, 1.0));
      this.m_focusW[this.m_focus].SetOpacity(this.m_focusOpacity);
    }
    this.m_focus = i >= 0 && i < ArraySize(this.m_focusW) ? i : -1;
    if this.m_focus >= 0 && IsDefined(this.m_focusW[this.m_focus]) {
      let w = this.m_focusW[this.m_focus];
      w.SetRenderTransformPivot(Vector2(0.5, 0.5));
      w.SetScale(Vector2(1.05, 1.05));
      this.m_focusOpacity = w.GetOpacity();
      w.SetOpacity(1.0);
      this.HideTip();
    }
  }

  public func FocusStep(step: Int32) -> Bool {
    let n = ArraySize(this.m_focusW);
    if n == 0 {
      return false;
    }
    let i = this.m_focus < 0 ? (step > 0 ? 0 : n - 1) : (this.m_focus + step + n) % n;
    this.Focus(i);
    return true;
  }

  private func RestoreFocus() -> Void {
    if this.m_focus >= 0 {
      let i = Min(this.m_focus, ArraySize(this.m_focusW) - 1);
      this.m_focus = -1;
      this.Focus(i);
    }
  }

  public func Activate() -> Bool {
    if this.m_focus < 0 || this.m_focus >= ArraySize(this.m_focusNames) {
      return false;
    }
    let name = this.m_focusNames[this.m_focus];
    if this.m_focusOff[this.m_focus] {
      this.DenySound();

      return true;
    }
    if StrBeginsWith(name, "act_") {
      this.RunAct(StrAfterFirst(name, "act_"));
      return true;
    }
    if StrBeginsWith(name, "tab_") {
      this.RunTab(StrAfterFirst(name, "tab_"));
      return true;
    }
    if StrBeginsWith(name, "hit_") {
      let i = StringToInt(StrAfterFirst(name, "hit_"), -1);
      if i >= 0 && i < ArraySize(this.m_hitActions) {
        this.ClickSound();
        this.Act(this.m_hitActions[i], this.m_hitArgs[i]);
      }
      return true;
    }
    return this.RunControl(name, null);
  }

  public func TabStep(step: Int32) -> Bool {
    let n = ArraySize(this.m_tabs);
    if n == 0 {
      return false;
    }
    let at = 0;
    let i = 0;
    while i < n {
      if this.m_tabs[i].IsDisabled() {
        at = i;
      }
      i += 1;
    }
    let next = this.m_tabs[(at + step + n) % n];
    this.RunTab(StrAfterFirst(NameToString(next.GetName()), "tab_"));
    return true;
  }

  public func AddFields(act: ref<TKPage>) -> Void { this.Fields(act); }

  private func Draw(i: Int32, r: ref<TKRow>) -> Void {
    let kind = r.kind;
    if kind != TKKind.Card() && kind != TKKind.Ticker() && kind != TKKind.Stat() && kind != TKKind.Tile() && kind != TKKind.Gauge()
      && kind != TKKind.File() && kind != TKKind.Posting() && kind != TKKind.Run() && kind != TKKind.Key() && kind != TKKind.Ring() {
      this.m_cards = null;
    }
    switch kind {
      case 1: TKRows.Heading(this, r); break;
      case 2: TKRows.Text(this, r); break;
      case 3: TKRows.Pair(this, r); break;
      case 4: TKRows.Meter(this, r); break;
      case 5: TKRows.Button(this, i, r); break;
      case 6: TKRows.Note(this, r); break;
      case 7: TKRows.Gap(this); break;
      case 8: TKRows.Item(this, i, r); break;
      case 9: TKRows.Links(this, r); break;
      case 12: TKRows.Buttons(this, i, r); break;
      case 13: this.SliderRow(i, r); break;
      case 14: TKRows.Track(this, r); break;
      case 15: TKRows.Section(this, i, r); break;
      case 16: this.InputRow(r); break;
      case 17: TKRows.Entry(this, r); break;
      case 18: TKRows.Dossier(this, r); break;
      case 19: TKRows.Columns(this, r); break;
      case 20: this.CustomRow(r); break;
      case 21: TKTables.Table(this, r); break;
      case 22: TKTiles.Card(this, i, r); break;
      case 23: TKTables.Board(this, i, r); break;
      case 24: this.ColumnStart(r.fraction); break;
      case 25: this.ColumnsEnd(); break;
      case 26: TKTiles.Ticker(this, r); break;
      case 27: TKTiles.Stat(this, r); break;
      case 28: TKTiles.Tile(this, i, r); break;
      case 29: TKControls.Dropdown(this, i, r); break;
      case 30: TKControls.Check(this, i, r); break;
      case 31: TKControls.Search(this, i, r); break;
      case 32: TKControls.SortHead(this, i, r); break;
      case 33: TKControls.Pager(this, i, r); break;
      case 34: TKControls.Live(this, i, r); break;
      case 35: TKControls.Message(this, r); break;
      case 36: TKControls.Choice(this, i, r); break;
      case 37: TKTiles.Gauge(this, r); break;
      case 38: TKRows.Stack(this, r); break;
      case 39: TKCards.File(this, i, r); break;
      case 40: TKCards.Posting(this, i, r); break;
      case 41: TKCards.Run(this, i, r); break;
      case 43: TKConsole.Key(this, i, r); break;
      case 44: TKConsole.Bay(this, i, r); break;
      case 45: TKConsole.Leds(this, r); break;
      case 46: TKConsole.Ring(this, r); break;
      case 47: TKConsole.Compare(this, r); break;
      case 48: TKConsole.Feed(this, r); break;
      case 49: TKConsole.Wave(this, r); break;
      default: break;
    }
  }

  private func CustomRow(r: ref<TKRow>) -> Void {
    if IsDefined(this.m_provider) {
      let live = this.m_provider.Custom(this, this.m_content, this.m_data, r);
      if IsDefined(live) {
        ArrayPush(this.m_custom, live);
      }
    }
  }

  public func Text(parent: ref<inkCompoundWidget>, text: String, size: Int32, weight: CName, role: String, above: Float) -> ref<inkText> {
    let t = TKInk.Plain(parent, TKScale.T(text), size, weight, above);
    TKTheme.PaintNew(t, this.m_theme, role);
    return t;
  }

  public func Tone(w: ref<inkWidget>, color: String) -> Void { TKTheme.Tone(w, this.m_theme, color); }

  public func Mark(t: ref<inkWidget>, red: Bool, green: Bool) -> Void {
    if red {
      TKTheme.Fix(t, this.m_theme, TKTheme.Loss());
    } else {
      if green {
        TKTheme.Fix(t, this.m_theme, TKTheme.Gain());
      }
    }
  }

  public func Marked(parent: ref<inkCompoundWidget>, s: String, size: Int32, weight: CName, above: Float, width: Float) -> ref<inkText> {
    let red: Bool;
    let green: Bool;
    let t = this.Wrap(this.Text(parent, TKTheme.Unmark(s, red, green), size, weight, "text", above), width);
    this.Mark(t, red, green);
    return t;
  }

  public func Wrap(t: ref<inkText>, width: Float) -> ref<inkText> {
    t.SetWrapping(true, width);
    return t;
  }

  public func Paint(w: ref<inkWidget>, role: String) -> Void { TKTheme.PaintNew(w, this.m_theme, role); }
  public func Fix(w: ref<inkWidget>, color: HDRColor) -> Void { TKTheme.Fix(w, this.m_theme, color); }

  public func Sep(parent: ref<inkCompoundWidget>, size: Int32) -> Void {
    let bar: ref<inkRectangle> = new inkRectangle();
    bar.SetSize(Vector2(2.0, Cast<Float>(size) * 0.8));
    bar.SetMargin(inkMargin(16.0, Cast<Float>(size) * 0.2, 16.0, 0.0));
    bar.SetVAlign(inkEVerticalAlign.Center);
    bar.Reparent(parent);
    TKTheme.PaintNew(bar, this.m_theme, "rule");
  }

  public func Rule(parent: ref<inkCompoundWidget>, above: Float, opacity: Float) -> Void {
    let rule: ref<inkRectangle> = new inkRectangle();
    rule.SetSize(Vector2(this.RowWidth(), 2.0));
    rule.SetMargin(inkMargin(0.0, above, 0.0, 0.0));
    rule.SetHAlign(inkEHorizontalAlign.Left);
    rule.SetOpacity(opacity);
    rule.Reparent(parent);
    TKTheme.PaintNew(rule, this.m_theme, "rule");
  }

  public func Frame(box: ref<inkCanvas>, w: Float, h: Float, t: Float, role: String, opacity: Float) -> Void {
    let edges = [Vector4(0.0, 0.0, w, t), Vector4(0.0, h - t, w, t), Vector4(0.0, 0.0, t, h), Vector4(w - t, 0.0, t, h)];
    for r in edges {
      let e = TKInk.Rect(box, r.X, r.Y, r.Z, r.W);
      e.SetOpacity(opacity);
      TKTheme.PaintNew(e, this.m_theme, role);
    }
  }

  public func TonedFrame(box: ref<inkCanvas>, w: Float, h: Float, t: Float, color: String) -> Void {
    let edges = [Vector4(0.0, 0.0, w, t), Vector4(0.0, h - t, w, t), Vector4(0.0, 0.0, t, h), Vector4(w - t, 0.0, t, h)];
    for r in edges {
      let e = TKInk.Rect(box, r.X, r.Y, r.Z, r.W);
      TKTheme.PaintNew(e, this.m_theme, "value");
      this.Tone(e, color);
    }
  }

  public func Panel(box: ref<inkCanvas>, w: Float, h: Float, opacity: Float) -> Void {
    let fill = TKInk.Rect(box, 0.0, 0.0, w, h);
    fill.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    fill.SetOpacity(opacity);
    this.Frame(box, w, h, 2.0, "rule", 1.0);
  }

  public func GridCell(kind: Int32, w: Float, h: Float) -> ref<inkCanvas> {
    let gap = TKScale.SpaceLG();
    let per = Max(1, Cast<Int32>((this.RowWidth() + gap) / (w + gap)));
    if !IsDefined(this.m_cards) || this.m_cardCount >= per || this.m_gridKind != kind {
      this.m_cards = TKInk.Strip(this.m_content, IsDefined(this.m_cards) && this.m_gridKind == kind ? gap : 12.0);
      this.m_cardCount = 0;
      this.m_gridKind = kind;
      this.grown += h + gap;
    }
    let cell: ref<inkCanvas> = new inkCanvas();
    cell.SetSize(Vector2(w, h));
    cell.SetMargin(inkMargin(this.m_cardCount > 0 ? gap : 0.0, 0.0, 0.0, 0.0));
    cell.Reparent(this.m_cards);
    this.m_cardCount += 1;
    return cell;
  }

  public func RowBox(textW: Float, text: String, value: String, color: String, opt tip: String) -> ref<inkCanvas> {
    let ts = TKScale.I("row.title", 32);
    let vs = TKScale.I("row.detail", 29);
    let h = MaxF(TKScale.F("row.minh", 66.0), TKInk.Lines(text, ts, textW) * Cast<Float>(ts) * 1.32
      + TKInk.Lines(value, vs, textW) * Cast<Float>(vs) * 1.32 + 8.0);
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(this.RowWidth(), h));
    row.SetMargin(inkMargin(0.0, TKScale.F("row.gap", 10.0), 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(this.m_content);
    this.grown += h + TKScale.F("row.gap", 10.0);
    let col: ref<inkVerticalPanel> = new inkVerticalPanel();
    col.Reparent(row);
    if StrLen(text) > 0 {
      let title = this.Wrap(this.Text(col, text, ts, n"Medium", "value", 0.0), textW);
      this.Tone(title, color);
      this.Hoverable(title, tip);
    }
    if StrLen(value) > 0 {
      this.Wrap(this.Text(col, value, vs, n"Regular", "text", 2.0), textW);
    }
    return row;
  }

  public func PinRight(w: ref<inkWidget>) -> Void {
    w.SetAnchor(inkEAnchor.TopRight);
    w.SetAnchorPoint(Vector2(1.0, 0.0));
    w.SetMargin(inkMargin(0.0, 2.0, 0.0, 0.0));
  }

  public func ActButton(parent: ref<inkCompoundWidget>, i: Int32, n: Int32, label: String, on: Bool, width: Float, height: Float, size: Int32) -> ref<TKButton> {
    let off = StrBeginsWith(label, "!");
    let shown = off ? StrAfterFirst(label, "!") : label;
    if StrBeginsWith(shown, "?") {
      shown = StrAfterFirst(shown, "?");
    }
    let hold = StrBeginsWith(shown, "~");
    if hold {
      shown = StrAfterFirst(shown, "~");
    }
    let b = TKButton.Make(parent, shown, "act_" + IntToString(i) + (n > 0 ? "_" + IntToString(n) : ""), width, height, size);
    b.SetDisabled(off || !on);

    if (off || !on) && NotEquals(this.Style().denySound, n"") {
      b.GetRootWidget().RegisterToCallback(n"OnPress", this, n"OnDeniedPress");
    }
    if hold && !off && on {

      let fill = new inkRectangle();
      fill.SetName(n"hold_fill");
      fill.SetAnchor(inkEAnchor.CenterLeft);
      fill.SetAnchorPoint(Vector2(0.0, 0.5));
      fill.SetSize(Vector2(0.0, height));
      fill.SetOpacity(0.3);
      fill.Reparent(b.GetRootCompoundWidget());
      TKTheme.PaintNew(fill, this.m_theme, "accent");
      let root = b.GetRootWidget();
      root.RegisterToCallback(n"OnPress", this, n"OnHoldPress");
      root.RegisterToCallback(n"OnRelease", this, n"OnHoldRelease");
      root.RegisterToCallback(n"OnHoverOut", this, n"OnHoldRelease");
    } else {
      b.RegisterToCallback(n"OnBtnClick", this, n"OnActClick");
    }
    TKTheme.Paint(b.GetLabel(), this.m_theme, "value");
    ArrayPush(this.m_buttons, b);
    this.AddFocus(b.GetRootWidget(), "act_" + IntToString(i) + (n > 0 ? "_" + IntToString(n) : ""), off || !on);
    return b;
  }

  protected cb func OnHoldPress(e: ref<inkPointerEvent>) -> Bool {
    if !e.IsAction(n"click") {
      return false;
    }
    let root = e.GetCurrentTarget() as inkCompoundWidget;
    if !IsDefined(root) {
      return false;
    }
    let fill = root.GetWidget(n"hold_fill");
    if !IsDefined(fill) {
      return false;
    }
    this.HoldStop();
    this.m_holdName = NameToString(root.GetName());
    this.m_holdFill = fill;
    let def: ref<inkAnimDef> = new inkAnimDef();
    let grow: ref<inkAnimSize> = new inkAnimSize();
    grow.SetStartSize(Vector2(0.0, fill.GetHeight()));
    grow.SetEndSize(Vector2(root.GetWidth(), fill.GetHeight()));
    grow.SetDuration(TKScale.F("hold.secs", 1.2));
    def.AddInterpolator(grow);
    this.m_holdProxy = fill.PlayAnimation(def);
    this.m_holdProxy.RegisterToCallback(inkanimEventType.OnFinish, this, n"OnHoldDone");
    return true;
  }

  protected cb func OnHoldRelease(e: ref<inkPointerEvent>) -> Bool {
    this.HoldStop();
    return false;
  }

  protected cb func OnHoldDone(proxy: ref<inkAnimProxy>) -> Bool {
    let name = this.m_holdName;
    this.HoldStop();
    let id = StrAfterFirst(name, "act_");
    let n = 0;
    if StrContains(id, "_") {
      n = StringToInt(StrAfterFirst(id, "_"), 0);
      id = StrBeforeFirst(id, "_");
    }
    let i = StringToInt(id, -1);
    if !IsDefined(this.m_data) || i < 0 || i >= this.m_data.Count() {
      return true;
    }
    let row = this.m_data.Row(i);
    if n >= 0 && n < ArraySize(row.actions) {
      this.ClickSound();
      this.Act(row.actions[n], row.args[n]);
    }
    return true;
  }

  private func HoldStop() -> Void {
    if IsDefined(this.m_holdProxy) {
      this.m_holdProxy.UnregisterFromAllCallbacks(inkanimEventType.OnFinish);
      this.m_holdProxy.Stop();
      this.m_holdProxy = null;
    }
    if IsDefined(this.m_holdFill) {
      this.m_holdFill.SetSize(Vector2(0.0, this.m_holdFill.GetHeight()));
    }
    this.m_holdFill = null;
    this.m_holdName = "";
  }

  public func LinkButton(parent: ref<inkCompoundWidget>, label: String, target: String, current: Bool, width: Float, height: Float, size: Int32) -> ref<TKButton> {
    let b = TKButton.Make(parent, label, "tab_" + target, width, height, size);
    b.SetDisabled(current);
    b.RegisterToCallback(n"OnBtnClick", this, n"OnTabClick");
    TKTheme.Paint(b.GetLabel(), this.m_theme, "value");
    ArrayPush(this.m_buttons, b);
    this.AddFocus(b.GetRootWidget(), "tab_" + target, current);
    return b;
  }

  private func ColumnStart(share: Float) -> Void {
    if !IsDefined(this.m_split) {
      this.m_pageContent = this.m_content;
      this.m_pageWidth = this.m_width;
      this.m_split = TKInk.Strip(this.m_content, 0.0);
    }
    let col: ref<inkVerticalPanel> = new inkVerticalPanel();
    col.SetVAlign(inkEVerticalAlign.Top);
    col.SetMargin(inkMargin(0.0, 0.0, 40.0, 0.0));
    col.Reparent(this.m_split);
    this.m_content = col;
    this.m_width = this.m_pageWidth * ClampF(share, 0.1, 1.0);
  }

  private func ColumnsEnd() -> Void {
    if IsDefined(this.m_split) {
      this.m_content = this.m_pageContent;
      this.m_width = this.m_pageWidth;
      this.m_split = null;
    }
  }

  private func InputRow(r: ref<TKRow>) -> Void {
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(this.RowWidth(), 96.0));
    row.SetMargin(inkMargin(0.0, TKScale.F("row.gap", 10.0), 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(this.m_content);
    this.grown += 106.0;
    let name = this.Text(row, r.text, TKScale.I("row.title", 32), n"Medium", "value", 0.0);
    name.SetMargin(inkMargin(0.0, 24.0, 0.0, 0.0));
    this.TextBox(row, r.value, r.arg, 440.0, this.RowWidth() - 460.0);
  }

  public func TextBox(parent: ref<inkCompoundWidget>, value: String, key: String, x: Float, width: Float) -> ref<HubTextInput> {
    let box = HubTextInput.Create();
    box.SetName(StringToName("in_" + key));
    box.SetText(value);
    box.SetLetterCase(textLetterCase.OriginalCase);
    box.SetMaxLength(300);
    box.Reparent(parent);
    box.SetWidth(width);
    box.GetRootWidget().SetMargin(inkMargin(x, 0.0, 0.0, 0.0));
    ArrayPush(this.m_inputs, box);
    ArrayPush(this.m_inputKeys, key);
    return box;
  }

  public func FieldText(key: String) -> String {
    let k = 0;
    while k < ArraySize(this.m_inputs) {
      if Equals(this.m_inputKeys[k], key) {
        return this.m_inputs[k].GetText();
      }
      k += 1;
    }
    return "";
  }

  private func Fields(act: ref<TKPage>) -> Void {
    let k = 0;
    while k < ArraySize(this.m_inputs) {
      ArrayPush(act.fieldKeys, this.m_inputKeys[k]);
      ArrayPush(act.fieldValues, this.m_inputs[k].GetText());
      k += 1;
    }
  }

  public func IsTyping() -> Bool {
    for box in this.m_inputs {
      if box.IsFocused() {
        return true;
      }
    }
    return false;
  }

  private func SliderRow(i: Int32, r: ref<TKRow>) -> Void {
    let parts = StrSplit(r.label, "|");
    if ArraySize(parts) < 4 {
      return;
    }
    let sl: ref<TKSlider> = new TKSlider();
    sl.row = i;
    sl.min = StringToInt(parts[0]);
    let max = StringToInt(parts[1]);
    sl.step = Max(1, StringToInt(parts[2]));
    sl.value = StringToInt(parts[3]);
    sl.suffix = ArraySize(parts) > 4 ? parts[4] : "";
    let count = (max - sl.min) / sl.step + 1;
    let w = TKScale.F("slider.w", 612.0);
    let h = TKScale.F("slider.h", 26.0);
    let line = this.RowBox(this.RowWidth() - w - 160.0, r.text, r.value, r.color, r.tip);
    let group: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    group.Reparent(line);
    this.PinRight(group);
    let track: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    track.SetMargin(inkMargin(0.0, 4.0, 0.0, 0.0));
    track.Reparent(group);
    let cell = w / Cast<Float>(count);
    let gap = cell >= 6.0 ? 2.0 : 1.0;
    let id = ArraySize(this.m_sliders);
    let k = 0;
    while k < count {
      let name = StringToName("sl_" + IntToString(id) + "_" + IntToString(k));
      let hit: ref<inkCanvas> = new inkCanvas();
      hit.SetName(name);
      hit.SetSize(Vector2(cell, h + 28.0));
      hit.SetInteractive(true);
      hit.Reparent(track);
      hit.RegisterToCallback(n"OnPress", this, n"OnSlidePress");
      hit.RegisterToCallback(n"OnHoverOver", this, n"OnSlideHover");
      hit.RegisterToCallback(n"OnRelease", this, n"OnSlideRelease");
      let seg: ref<inkRectangle> = new inkRectangle();
      seg.SetName(name);
      seg.SetSize(Vector2(MaxF(1.0, cell - gap), h));
      seg.SetMargin(inkMargin(0.0, 14.0, 0.0, 0.0));
      seg.Reparent(hit);
      ArrayPush(sl.segs, seg);
      k += 1;
    }
    let readout = this.Text(group, "", TKScale.I("row.title", 32), n"Semi-Bold", "value", 0.0);
    readout.SetMargin(inkMargin(24.0, 6.0, 0.0, 0.0));
    readout.SetSize(Vector2(120.0, 40.0));
    sl.readout = readout;
    ArrayPush(this.m_sliders, sl);
    this.PaintSlider(sl);
  }

  private func PaintSlider(sl: ref<TKSlider>) -> Void {
    let k = 0;
    while k < ArraySize(sl.segs) {
      let lit = sl.min + k * sl.step <= sl.value;
      TKTheme.PaintNew(sl.segs[k], this.m_theme, lit ? "value" : "rule");
      sl.segs[k].SetOpacity(lit ? 1.0 : 0.55);
      k += 1;
    }
    sl.readout.SetText(IntToString(sl.value) + sl.suffix);
  }

  private func SlideTarget(e: ref<inkPointerEvent>, out slider: Int32, out value: Int32) -> Bool {
    let name = NameToString(e.GetTarget().GetName());
    if !StrBeginsWith(name, "sl_") {
      return false;
    }
    let rest = StrAfterFirst(name, "sl_");
    slider = StringToInt(StrBeforeFirst(rest, "_"), -1);
    if slider < 0 || slider >= ArraySize(this.m_sliders) {
      return false;
    }
    let sl = this.m_sliders[slider];
    value = sl.min + StringToInt(StrAfterFirst(rest, "_"), 0) * sl.step;
    return true;
  }

  private func SlideCommit(sl: ref<TKSlider>) -> ref<TKPage> {
    let act: ref<TKPage> = new TKPage();
    act.content = this.m_provider;
    act.page = this.m_page;
    let row = this.m_data.Row(sl.row);

    act.Act(row.action, TKView.Prefix(row.arg) + IntToString(sl.value));
    return act;
  }

  private func SlideSet(s: Int32, v: Int32) -> Void {
    let sl = this.m_sliders[s];
    if sl.value != v {
      sl.value = v;
      this.PaintSlider(sl);
      this.SlideCommit(sl);
    }
  }

  protected cb func OnSlidePress(e: ref<inkPointerEvent>) -> Bool {
    let s: Int32;
    let v: Int32;
    if e.IsAction(n"click") && this.SlideTarget(e, s, v) {
      this.m_drag = s;
      this.m_sliders[s].value = v;
      this.PaintSlider(this.m_sliders[s]);
      this.SlideCommit(this.m_sliders[s]);
    }
    return true;
  }

  protected cb func OnSlideHover(e: ref<inkPointerEvent>) -> Bool {
    if this.m_drag < 0 {
      return true;
    }

    if !RedFunc.MouseButton(1) {
      this.SlideEnd();
      return true;
    }
    let s: Int32;
    let v: Int32;
    if this.SlideTarget(e, s, v) && s == this.m_drag {
      this.SlideSet(s, v);
    }
    return true;
  }

  protected cb func OnSlideRelease(e: ref<inkPointerEvent>) -> Bool {
    if this.m_drag >= 0 && e.IsAction(n"click") {
      this.SlideEnd();
    }
    return true;
  }

  private func SlideEnd() -> Void {
    let sl = this.m_sliders[this.m_drag];
    this.m_drag = -1;
    let act = this.SlideCommit(sl);
    if act.rebuild && IsDefined(this.m_provider) {
      this.m_provider.Rebuild();
    }
    this.Show(StrLen(act.nextPage) > 0 ? act.nextPage : this.m_page, StrLen(act.nextPage) > 0 ? act.nextArg : this.m_arg, act.message);
  }
}

public class TKLiveTick extends DelayCallback {
  public let view: wref<TKView>;
  public let gen: Int32;
  public func Call() -> Void {
    if IsDefined(this.view) {
      this.view.LiveStep(this.gen);
    }
  }
}

public class TKPopup extends InGamePopup {
  protected let m_player: wref<PlayerPuppet>;
  protected let m_view: ref<TKView>;
  protected let m_regions: ref<TKRegions>;
  protected let m_frame: wref<inkCompoundWidget>;
  protected let m_boot: wref<inkText>;
  protected let m_bootProxy: ref<inkAnimProxy>;
  protected let m_bootLines: array<wref<inkText>>;
  protected let m_lens: wref<inkWidget>;
  protected let m_hideable: array<wref<inkWidget>>;
  protected let m_bare: Bool;
  protected let m_rightDown: Bool;

  public func Content() -> ref<TKContent> = null

  public func Tabs() -> array<String> {
    let none: array<String>;
    return none;
  }
  public func Brand() -> String = "TERMINAL KIT"
  public func Name() -> String = "TERMINAL"
  public func Status() -> String = ""
  public func Footer() -> String = "[ESC] CLOSE    [RIGHT CLICK] BACK"

  public func Hints() -> array<String> {
    let none: array<String>;
    return none;
  }
  public func BootText() -> String = "CONNECTING..."

  public func BootLines() -> array<String> {
    let none: array<String>;
    return none;
  }
  public func BootSeconds() -> Float = 0.0
  public func Style() -> ref<TKStyle> = null

  public func ScaleSource() -> ref<TKScaleSource> = null

  public func Layout() -> array<String> {
    let none: array<String>;
    return none;
  }

  public func Regions() -> ref<TKRegions> = this.m_regions
  public func StartPage() -> String = "home"
  public func StartArg() -> String = ""
  public func CornerTab() -> String = ""
  public func Lens() -> Bool = true
  public func FrameWidth() -> Float = TKScale.F("frame.w", 3000.0)
  public func FrameHeight() -> Float = TKScale.F("frame.h", 1500.0)
  public func PageWidth() -> Float = TKScale.F("content.w", 2300.0)
  public func PageHeight() -> Float = TKScale.F("content.h", 1080.0)
  protected func Setup() -> Void {}
  protected func Icon(bar: ref<inkHorizontalPanel>) -> Void {}
  protected func Opened() -> Void {
    this.m_view.Show(this.StartPage(), this.StartArg(), "");
  }
  protected func Closing() -> Void {}
  protected func Closed() -> Void {}

  public static func CanOpen(player: ref<PlayerPuppet>) -> Bool {
    if !IsDefined(player) {
      return false;
    }
    let game = player.GetGame();
    let ui = GameInstance.GetBlackboardSystem(game).Get(GetAllBlackboardDefs().UI_System);
    if IsDefined(ui) && ui.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu) {
      return false;
    }
    if GameInstance.GetTimeSystem(game).IsPausedState() {
      return false;
    }
    if GameInstance.GetPhotoModeSystem(game).IsPhotoModeActive() {
      return false;
    }
    return true;
  }

  public static func Open(player: ref<PlayerPuppet>, popup: ref<TKPopup>) -> Void {
    if !IsDefined(player) || !IsDefined(popup) {
      return;
    }
    popup.m_player = player;
    GameInstance.GetUISystem(player.GetGame()).QueueEvent(ShowCustomPopupEvent.Create(popup));
  }

  public func View() -> ref<TKView> = this.m_view
  public func Player() -> wref<PlayerPuppet> = this.m_player
  public func IsTyping() -> Bool = IsDefined(this.m_regions) ? this.m_regions.IsTyping() : IsDefined(this.m_view) && this.m_view.IsTyping()

  public func UseCursor() -> Bool = true

  protected func SetUIContext() -> Void {
    GameInstance.GetUISystem(this.GetGame()).PushGameContext(UIGameContext.ModalPopup);
  }

  protected func ResetUIContext() -> Void {
    GameInstance.GetUISystem(this.GetGame()).PopGameContext(UIGameContext.ModalPopup);
  }

  protected func PlayShowSound() -> Void {
    if IsDefined(this.m_player) {
      let style = this.Style();
      GameObject.PlaySound(this.m_player, IsDefined(style) && NotEquals(style.openSound, n"") ? style.openSound : n"ui_hacking_access_granted");
    }
  }

  protected func PlayHideSound() -> Void {
    if IsDefined(this.m_player) {
      let style = this.Style();
      GameObject.PlaySound(this.m_player, IsDefined(style) && NotEquals(style.closeSound, n"") ? style.closeSound : n"ui_menu_onpress");
    }
  }

  protected func CreateVignette() -> Void {
    let tint: ref<inkRectangle> = new inkRectangle();
    tint.SetName(n"lens");
    tint.SetAnchor(inkEAnchor.Fill);
    tint.SetTintColor(new HDRColor(0.02, 0.07, 0.09, 1.0));
    tint.SetOpacity(0.55);
    tint.Reparent(this.GetRootCompoundWidget());
    this.m_lens = tint;

    let edge: ref<inkImage> = new inkImage();
    edge.SetName(n"vignette");
    edge.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\notifications\\vignette.inkatlas");
    edge.SetTexturePart(n"vignette_1");
    edge.SetNineSliceScale(true);
    edge.SetAnchor(inkEAnchor.Fill);
    edge.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
    edge.BindProperty(n"tintColor", n"MainColors.Blue");
    edge.SetOpacity(0.35);
    edge.Reparent(this.GetRootCompoundWidget());
    this.m_vignette = edge;
    if !this.Lens() {
      tint.SetVisible(false);
      edge.SetVisible(false);
    }
  }

  protected func CreateContainer() -> Void {
    let frame: ref<inkCanvas> = new inkCanvas();
    frame.SetName(n"container");
    frame.SetAnchor(inkEAnchor.Centered);
    frame.SetAnchorPoint(Vector2(0.5, 0.5));
    frame.SetSize(Vector2(this.FrameWidth(), this.FrameHeight()));
    frame.Reparent(this.GetRootCompoundWidget());
    this.m_container = frame;
    this.m_frame = frame;
    this.SetContainerWidget(frame);
  }

  protected cb func OnCreate() -> Void {
    super.OnCreate();
    TKScale.Activate(this.ScaleSource());
    let look = this.Style();
    TKInk.UseFont(IsDefined(look) ? look.fontFamily : "", IsDefined(look) ? look.fontStyle : n"");
    this.Setup();
    this.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnFrameRelative");
    this.RegisterToGlobalInputCallback(n"OnPostOnPress", this, n"OnFramePress");
    this.BuildFrame();
    this.Opened();
  }

  public func Rebuild() -> Void {
    let page = this.m_view.CurrentPage();
    let arg = this.m_view.CurrentArg();
    this.SetBare(false);
    this.m_view.StopCustom();
    this.m_frame.RemoveAllChildren();
    this.BuildFrame();
    this.m_boot.SetOpacity(0.0);
    this.m_view.Show(page, arg, "");
  }

  private func BuildFrame() -> Void {
    let frame = this.m_frame;
    let fw = this.FrameWidth();
    ArrayClear(this.m_hideable);
    this.m_regions = null;
    this.m_view = new TKView();
    let adapter = new TKPopupFrame();
    adapter.popup = this;
    this.m_view.SetFrame(adapter);
    this.m_view.SetContent(this.Content());
    this.m_view.SetStyle(this.Style());
    this.m_view.Chrome(this.m_vignette, "frame");
    this.Brackets(frame);
    this.Decor(frame);

    let bar: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    bar.SetMargin(inkMargin(70.0, 30.0, 0.0, 0.0));
    bar.Reparent(frame);
    ArrayPush(this.m_hideable, bar);
    this.Icon(bar);
    let brand = TKInk.Line(bar, TKScale.T(this.Brand()), TKScale.I("frame.brand", 30), n"Medium", n"MainColors.PanelBlue", 0.0);
    brand.SetVAlign(inkEVerticalAlign.Center);
    this.m_view.Chrome(brand, "text");
    let slash = TKInk.Line(bar, "   //   ", 30, n"Regular", n"MainColors.DarkRed", 0.0);
    slash.SetVAlign(inkEVerticalAlign.Center);
    this.m_view.Chrome(slash, "rule");
    let name = TKInk.Line(bar, TKScale.T(this.Name()), TKScale.I("frame.name", 64), n"Semi-Bold", n"MainColors.Red", 0.0);
    name.SetVAlign(inkEVerticalAlign.Center);
    this.m_view.Chrome(name, "accent");

    let corner = this.CornerTab();
    let right = 70.0;
    if StrLen(corner) > 0 {
      let w = TKScale.F("settings.w", 280.0);
      let b = this.m_view.AddTab(frame, StrBeforeFirst(corner, "|"), StrAfterFirst(corner, "|"), w, TKScale.F("settings.h", 64.0), TKScale.I("side.font", 30));
      let root = b.GetRootWidget();
      root.SetAnchor(inkEAnchor.TopRight);
      root.SetAnchorPoint(Vector2(1.0, 0.0));
      root.SetMargin(inkMargin(0.0, 52.0, 70.0, 0.0));
      ArrayPush(this.m_hideable, root);
      right += w + 40.0;
    }
    if StrLen(this.Status()) > 0 {
      let status: ref<inkText> = TKInk.Line(frame, TKScale.T(this.Status()), 26, n"Regular", n"MainColors.PanelBlue", 0.0);
      status.SetAnchor(inkEAnchor.TopRight);
      status.SetAnchorPoint(Vector2(1.0, 0.0));
      status.SetMargin(inkMargin(0.0, 70.0, right, 0.0));
      status.SetOpacity(0.7);
      this.m_view.Chrome(status, "text");
      ArrayPush(this.m_hideable, status);
    }

    let rule: ref<inkRectangle> = new inkRectangle();
    rule.SetSize(Vector2(fw - 140.0, 2.0));
    rule.SetMargin(inkMargin(70.0, 150.0, 0.0, 0.0));
    rule.Reparent(frame);
    this.m_view.Chrome(rule, "rule");
    ArrayPush(this.m_hideable, rule);

    let specs = this.Layout();
    if ArraySize(specs) > 0 {
      this.BuildRegions(frame, specs);
    } else {
      this.BuildPage(frame);
    }

    let hints = this.Hints();
    if ArraySize(hints) > 0 {
      this.KeyHints(frame, hints);
    } else if StrLen(this.Footer()) > 0 {
      let foot: ref<inkText> = TKInk.Line(frame, TKScale.T(this.Footer()), 26, n"Medium", n"MainColors.PanelBlue", 0.0);
      foot.SetAnchor(inkEAnchor.BottomLeft);
      foot.SetAnchorPoint(Vector2(0.0, 1.0));
      foot.SetMargin(inkMargin(70.0, 0.0, 0.0, 40.0));
      foot.SetOpacity(0.7);
      this.m_view.Chrome(foot, "text");
      ArrayPush(this.m_hideable, foot);
    }

    let lines = this.m_view.Style().scanlines;
    if lines > 0.0 {
      let scan: ref<inkCanvas> = new inkCanvas();
      scan.SetSize(Vector2(fw, this.FrameHeight()));
      scan.SetOpacity(MinF(lines, 0.6));
      scan.Reparent(frame);
      ArrayPush(this.m_hideable, scan);
      let y = 0.0;
      while y < this.FrameHeight() {
        TKInk.Rect(scan, 0.0, y, fw, 3.0).SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
        y += 9.0;
      }
    }

    let boots = this.BootLines();
    ArrayClear(this.m_bootLines);
    this.m_boot = TKInk.Line(frame, ArraySize(boots) > 0 ? "" : TKScale.T(this.BootText()), 40, n"Medium", n"MainColors.Blue", 0.0);
    this.m_boot.SetAnchor(inkEAnchor.BottomRight);
    this.m_boot.SetAnchorPoint(Vector2(1.0, 1.0));
    this.m_boot.SetMargin(inkMargin(0.0, 0.0, 70.0, 40.0));
    this.m_view.Chrome(this.m_boot, "value");
    if ArraySize(boots) > 0 {
      let stack: ref<inkVerticalPanel> = new inkVerticalPanel();
      stack.SetAnchor(inkEAnchor.BottomRight);
      stack.SetAnchorPoint(Vector2(1.0, 1.0));
      stack.SetMargin(inkMargin(0.0, 0.0, 70.0, 40.0));
      stack.Reparent(frame);
      for text in boots {
        let line = TKInk.Line(stack, TKScale.T(text), 32, n"Medium", n"MainColors.Blue", 2.0);
        line.SetHAlign(inkEHorizontalAlign.Right);
        line.SetOpacity(0.0);
        this.m_view.Chrome(line, "value");
        ArrayPush(this.m_bootLines, line);
      }
    }
  }

  private func BuildRegions(frame: ref<inkCompoundWidget>, specs: array<String>) -> Void {
    let message = TKInk.Line(frame, "", TKScale.I("message", 30), n"Medium", n"MainColors.Blue", 0.0);
    message.SetAnchor(inkEAnchor.BottomRight);
    message.SetAnchorPoint(Vector2(1.0, 1.0));
    message.SetMargin(inkMargin(0.0, 0.0, 70.0, 40.0));
    this.m_view.Chrome(message, "value");
    this.m_regions = new TKRegions();
    let top = TKScale.F("layout.top", 180.0);
    let foot = TKScale.F("layout.foot", 110.0);
    this.m_regions.Build(frame, 70.0, top, this.FrameWidth() - 140.0, this.FrameHeight() - top - foot, specs,
      this.m_view, this.m_view.FrameOf(), this.Content(), this.Style(), message);
  }

  private func BuildPage(frame: ref<inkCompoundWidget>) -> Void {
    let body: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    body.SetMargin(inkMargin(70.0, 190.0, 0.0, 0.0));
    body.Reparent(frame);
    let tabs = this.Tabs();
    if ArraySize(tabs) > 0 {
      let side: ref<inkVerticalPanel> = new inkVerticalPanel();
      side.SetMargin(inkMargin(0.0, 0.0, 80.0, 0.0));
      side.Reparent(body);
      ArrayPush(this.m_hideable, side);
      for pair in tabs {
        this.m_view.AddTab(side, StrBeforeFirst(pair, "|"), StrAfterFirst(pair, "|"), TKScale.F("side.w", 460.0), TKScale.F("side.h", 74.0), TKScale.I("side.font", 30))
          .GetRootWidget().SetMargin(inkMargin(0.0, 0.0, 0.0, TKScale.F("side.gap", 12.0)));
      }
    }

    let page: ref<inkVerticalPanel> = new inkVerticalPanel();
    page.Reparent(body);
    let title = TKInk.Line(page, "", TKScale.I("title", 56), n"Medium", n"MainColors.Blue", 0.0);
    let subtitle = TKInk.Line(page, "", TKScale.I("subtitle", 28), n"Regular", n"MainColors.PanelBlue", 2.0);
    ArrayPush(this.m_hideable, title);
    ArrayPush(this.m_hideable, subtitle);

    let contentW = this.PageWidth();
    let contentH = this.PageHeight();
    let viewport: ref<inkCanvas> = new inkCanvas();
    viewport.SetSize(Vector2(contentW + 30.0, contentH));
    viewport.SetMargin(inkMargin(0.0, 12.0, 0.0, 0.0));
    viewport.Reparent(page);
    let clip: ref<inkScrollArea> = new inkScrollArea();
    clip.SetAnchor(inkEAnchor.TopLeft);
    clip.SetAnchorPoint(Vector2(0.0, 0.0));
    clip.SetFitToContentDirection(inkFitToContentDirection.None);
    clip.SetConstrainContentPosition(false);
    clip.SetUseInternalMask(true);
    clip.SetSize(Vector2(contentW, contentH));
    clip.Reparent(viewport);
    let content: ref<inkVerticalPanel> = new inkVerticalPanel();
    content.SetAnchor(inkEAnchor.TopLeft);
    content.SetAnchorPoint(Vector2(0.0, 0.0));
    content.Reparent(clip);
    let track: ref<inkRectangle> = new inkRectangle();
    track.SetSize(Vector2(4.0, contentH));
    track.SetMargin(inkMargin(contentW + 20.0, 0.0, 0.0, 0.0));
    track.SetOpacity(0.35);
    track.Reparent(viewport);
    this.m_view.Chrome(track, "rule");
    let thumb: ref<inkRectangle> = new inkRectangle();
    thumb.SetSize(Vector2(4.0, 40.0));
    thumb.SetMargin(inkMargin(contentW + 20.0, 0.0, 0.0, 0.0));
    thumb.Reparent(viewport);
    this.m_view.Chrome(thumb, "value");
    let message = TKInk.Line(page, "", TKScale.I("message", 30), n"Medium", n"MainColors.Blue", 8.0);
    this.m_view.Bind(content, title, subtitle, message, contentW);
    this.m_view.BindScroll(clip, contentH, track, thumb);

    let overlay: ref<inkCanvas> = new inkCanvas();
    overlay.SetSize(Vector2(contentW + 30.0, contentH));
    overlay.SetAnchor(inkEAnchor.TopLeft);
    overlay.SetAnchorPoint(Vector2(0.0, 0.0));
    overlay.Reparent(viewport);
    this.m_view.SetTipLayer(overlay);
  }

  private func KeyHints(frame: ref<inkCompoundWidget>, hints: array<String>) -> Void {
    let bar = this.SpawnFromExternal(frame, r"base\\gameplay\\gui\\common\\buttonhints.inkwidget", n"Root");
    if !IsDefined(bar) {
      return;
    }
    bar.SetAnchor(inkEAnchor.BottomLeft);
    bar.SetAnchorPoint(Vector2(0.0, 1.0));
    bar.SetMargin(inkMargin(70.0, 0.0, 0.0, 40.0));
    ArrayPush(this.m_hideable, bar);
    let ctrl = bar.GetController() as ButtonHints;
    if !IsDefined(ctrl) {
      return;
    }
    ctrl.SetInverted(true);
    for pair in hints {
      ctrl.AddButtonHint(StringToName(StrBeforeFirst(pair, "|")), TKScale.T(StrAfterFirst(pair, "|")));
    }
  }

  private func Decor(frame: ref<inkCompoundWidget>) -> Void {
    let style = this.m_view.Style();
    let w = this.FrameWidth();
    let h = this.FrameHeight();
    if style.frame == 1 {

      let n = 70.0;
      this.Diag(frame, 0.0, n, n, 0.0);
      this.Diag(frame, w - n, 0.0, w, n);
      this.Diag(frame, 0.0, h - n, n, h);
      this.Diag(frame, w - n, h, w, h - n);
    }
    if style.frame == 2 {

      this.Bar(frame, 0.0, 0.0, w, 3.0);
      this.Bar(frame, 0.0, h - 3.0, w, 3.0);
      this.Bar(frame, 0.0, 0.0, 3.0, h);
      this.Bar(frame, w - 3.0, 0.0, 3.0, h);
      let o = 16.0;
      this.Bar(frame, o, o, w - o * 2.0, 2.0).SetOpacity(0.4);
      this.Bar(frame, o, h - o - 2.0, w - o * 2.0, 2.0).SetOpacity(0.4);
      this.Bar(frame, o, o, 2.0, h - o * 2.0).SetOpacity(0.4);
      this.Bar(frame, w - o - 2.0, o, 2.0, h - o * 2.0).SetOpacity(0.4);
      let len = 170.0;
      let t = 10.0;
      this.Bar(frame, 0.0, 0.0, len, t);
      this.Bar(frame, 0.0, 0.0, t, len);
      this.Bar(frame, w - len, 0.0, len, t);
      this.Bar(frame, w - t, 0.0, t, len);
      this.Bar(frame, 0.0, h - t, len, t);
      this.Bar(frame, 0.0, h - len, t, len);
      this.Bar(frame, w - len, h - t, len, t);
      this.Bar(frame, w - t, h - len, t, len);
    }
    if style.rivets {

      let x = 260.0;
      while x < w - 260.0 {
        this.Rivet(frame, x, 12.0);
        this.Rivet(frame, x, h - 22.0);
        x += 150.0;
      }
    }
    if style.hazard {

      this.Hazard(frame, w - 470.0, 10.0);
      this.Hazard(frame, 230.0, h - 30.0);
    }
  }

  private func Rivet(frame: ref<inkCompoundWidget>, x: Float, y: Float) -> Void {
    let r = this.Bar(frame, x, y, 10.0, 10.0);
    r.SetRenderTransformPivot(Vector2(0.5, 0.5));
    r.SetRotation(45.0);
    r.SetOpacity(0.7);
  }

  private func Hazard(frame: ref<inkCompoundWidget>, x: Float, y: Float) -> Void {
    let k = 0;
    while k < 6 {
      let r: ref<inkRectangle> = new inkRectangle();
      r.SetSize(Vector2(12.0, 26.0));
      r.SetMargin(inkMargin(x + Cast<Float>(k) * 26.0, y, 0.0, 0.0));
      r.SetRenderTransformPivot(Vector2(0.5, 0.5));
      r.SetRotation(35.0);
      r.SetOpacity(0.85);
      r.Reparent(frame);
      this.m_view.Chrome(r, "accent");
      ArrayPush(this.m_hideable, r);
      k += 1;
    }
  }

  private func Diag(frame: ref<inkCompoundWidget>, x1: Float, y1: Float, x2: Float, y2: Float) -> Void {
    let dx = x2 - x1;
    let dy = y2 - y1;
    let len = SqrtF(dx * dx + dy * dy);
    let r = this.Bar(frame, (x1 + x2) / 2.0 - len / 2.0, (y1 + y2) / 2.0 - 2.0, len, 4.0);
    r.SetRenderTransformPivot(Vector2(0.5, 0.5));
    r.SetRotation(Rad2Deg(AtanF(dy, dx)));
  }

  private func Brackets(frame: ref<inkCompoundWidget>) -> Void {
    let len: Float = 120.0;
    let t: Float = 4.0;
    let w = this.FrameWidth();
    let h = this.FrameHeight();
    this.Bar(frame, 0.0, 0.0, len, t);
    this.Bar(frame, 0.0, 0.0, t, len);
    this.Bar(frame, w - len, 0.0, len, t);
    this.Bar(frame, w - t, 0.0, t, len);
    this.Bar(frame, 0.0, h - t, len, t);
    this.Bar(frame, 0.0, h - len, t, len);
    this.Bar(frame, w - len, h - t, len, t);
    this.Bar(frame, w - t, h - len, t, len);
  }

  private func Bar(frame: ref<inkCompoundWidget>, x: Float, y: Float, w: Float, h: Float) -> ref<inkRectangle> {
    let r: ref<inkRectangle> = new inkRectangle();
    r.SetSize(Vector2(w, h));
    r.SetMargin(inkMargin(x, y, 0.0, 0.0));
    r.SetOpacity(0.8);
    r.Reparent(frame);
    this.m_view.Chrome(r, "frame");
    ArrayPush(this.m_hideable, r);
    return r;
  }

  public func SetBare(bare: Bool) -> Void {
    if Equals(bare, this.m_bare) {
      return;
    }
    this.m_bare = bare;
    for w in this.m_hideable {
      w.SetVisible(!bare);
    }
    let lens = this.Lens() && !bare;
    this.m_lens.SetVisible(lens);
    this.m_vignette.SetVisible(lens);
    if bare {
      this.ResetBackgroundBlur();
    } else {
      this.SetBackgroundBlur();
    }
  }

  protected cb func OnShow() -> Void {
    super.OnShow();
    let flicker: ref<inkAnimDef> = new inkAnimDef();
    TKPopup.Fade(flicker, 0.0, 0.7, 0.05, 0.0);
    TKPopup.Fade(flicker, 0.7, 0.15, 0.05, 0.05);
    TKPopup.Fade(flicker, 0.15, 1.0, 0.18, 0.10);
    let zoom: ref<inkAnimScale> = new inkAnimScale();
    zoom.SetStartScale(Vector2(1.04, 1.04));
    zoom.SetEndScale(Vector2(1.0, 1.0));
    zoom.SetDuration(0.3);
    zoom.SetType(inkanimInterpolationType.Quadratic);
    zoom.SetMode(inkanimInterpolationMode.EasyOut);
    flicker.AddInterpolator(zoom);
    this.m_frame.PlayAnimation(flicker);

    let n = ArraySize(this.m_bootLines);
    let stay = this.BootSeconds() > 0.0 ? this.BootSeconds() : (n > 0 ? 0.6 + 0.3 * Cast<Float>(n) : 0.9);
    let boot: ref<inkAnimDef> = new inkAnimDef();
    TKPopup.Fade(boot, 1.0, 0.0, 0.4, stay);
    this.m_bootProxy = this.m_boot.PlayAnimation(boot);

    let step = n > 0 ? (stay - 0.2) / Cast<Float>(n) : 0.0;
    let i = 0;
    while i < n {
      let line: ref<inkAnimDef> = new inkAnimDef();
      TKPopup.Fade(line, 0.0, 1.0, 0.08, 0.1 + step * Cast<Float>(i));
      TKPopup.Fade(line, 1.0, 0.0, 0.4, stay);
      this.m_bootLines[i].PlayAnimation(line);
      i += 1;
    }
  }

  public static func Fade(def: ref<inkAnimDef>, from: Float, to: Float, duration: Float, delay: Float) -> Void {
    let a: ref<inkAnimTransparency> = new inkAnimTransparency();
    a.SetStartTransparency(from);
    a.SetEndTransparency(to);
    a.SetDuration(duration);
    a.SetStartDelay(delay);
    def.AddInterpolator(a);
  }

  protected cb func OnFrameRelative(e: ref<inkPointerEvent>) -> Bool {
    if IsDefined(this.m_view) && !IsDefined(this.m_regions) {
      this.m_view.OnWheel(e);
    }
    return false;
  }

  protected cb func OnFramePress(e: ref<inkPointerEvent>) -> Bool {

    if !this.IsTyping() && !e.IsAction(n"click") && this.PressKey(e) {
      return false;
    }
    if this.PadInput(e) {
      return false;
    }
    if IsDefined(this.m_view) && RedFunc.MouseButton(2) && !e.IsAction(n"click") && !e.IsAction(n"mouse_left") {
      if !this.m_rightDown {
        if !this.m_view.CloseOverlay() {
          this.m_view.Back();
        }
      }
      this.m_rightDown = true;
    } else {
      this.m_rightDown = false;
    }
    return false;
  }

  private func PadInput(e: ref<inkPointerEvent>) -> Bool {
    let pad = IsDefined(this.m_player) && this.m_player.PlayerLastUsedPad();
    let focused = IsDefined(this.m_regions) ? this.m_regions.HasFocus() : IsDefined(this.m_view) && this.m_view.HasFocus();
    if focused && (e.IsAction(n"select") || e.IsAction(n"proceed") || (pad && e.IsAction(n"click"))) {
      return IsDefined(this.m_regions) ? this.m_regions.Activate() : this.m_view.Activate();
    }
    if e.IsAction(n"click") || e.IsAction(n"mouse_left") {
      if focused && !pad {
        if IsDefined(this.m_regions) {
          this.m_regions.ClearFocus();
        } else {
          this.m_view.Focus(-1);
        }
      }
      return false;
    }
    let step = 0;
    if e.IsAction(n"navigate_up") || e.IsAction(n"navigate_left") {
      step = -1;
    }
    if e.IsAction(n"navigate_down") || e.IsAction(n"navigate_right") {
      step = 1;
    }
    if step != 0 {
      return IsDefined(this.m_regions) ? this.m_regions.FocusStep(step) : IsDefined(this.m_view) && this.m_view.FocusStep(step);
    }
    let dir = e.IsAction(n"prior_menu") ? -1 : (e.IsAction(n"next_menu") ? 1 : 0);
    if dir != 0 {
      return IsDefined(this.m_regions) ? this.m_regions.FocusRegion(dir) : IsDefined(this.m_view) && this.m_view.TabStep(dir);
    }
    return false;
  }

  private func PressKey(e: ref<inkPointerEvent>) -> Bool {
    if IsDefined(this.m_regions) {
      let i = 0;
      while i < this.m_regions.Count() {
        if this.m_regions.View(i).PressKey(e) {
          return true;
        }
        i += 1;
      }
      return false;
    }
    return IsDefined(this.m_view) && this.m_view.PressKey(e);
  }

  protected cb func OnGlobalReleaseInput(evt: ref<inkPointerEvent>) -> Bool {
    if this.m_rightDown && (evt.IsAction(this.m_closeAction) || !RedFunc.MouseButton(2)) {
      this.m_rightDown = false;
      evt.Handle();
      return true;
    }

    if IsDefined(this.m_regions) && evt.IsAction(this.m_closeAction) && this.m_regions.HasOverlay() {
      this.m_regions.EndOverlay("");
      evt.Handle();
      return true;
    }
    return super.OnGlobalReleaseInput(evt);
  }

  protected cb func OnHidden() -> Void {
    this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnFrameRelative");
    this.UnregisterFromGlobalInputCallback(n"OnPostOnPress", this, n"OnFramePress");
    if IsDefined(this.m_view) {
      this.m_view.StopCustom();
      this.m_view.StopLive();
    }
    if IsDefined(this.m_regions) {
      this.m_regions.Stop();
    }
    this.Closing();
    TKScale.Activate(null);
    TKInk.UseFont("", n"");
    super.OnHidden();
    this.Closed();
  }
}

public class TKPopupFrame extends TKFrame {
  public let popup: wref<TKPopup>;
  public func Owner() -> ref<inkCustomController> {
    let owner: ref<TKPopup> = this.popup;
    return owner;
  }
  public func SetBare(bare: Bool) -> Void {
    if IsDefined(this.popup) {
      this.popup.SetBare(bare);
    }
  }
}

public class TKRegions extends IScriptable {
  private let m_names: array<String>;
  private let m_views: array<ref<TKView>>;
  private let m_provider: ref<TKContent>;
  private let m_message: wref<inkText>;
  private let m_page: String;
  private let m_arg: String;
  private let m_history: array<String>;
  private let m_noPush: Bool;
  private let m_sides: array<String>;

  private let m_overPages: array<String>;
  private let m_overArgs: array<String>;
  private let m_focusRegion: Int32;

  public func Count() -> Int32 = ArraySize(this.m_views)
  public func View(i: Int32) -> ref<TKView> = i >= 0 && i < ArraySize(this.m_views) ? this.m_views[i] : null
  public func CurrentPage() -> String = this.m_page
  public func CurrentArg() -> String = this.m_arg

  public func Find(name: String) -> ref<TKView> {
    let i = this.IndexOf(name);
    return i >= 0 ? this.m_views[i] : null;
  }

  private func IndexOf(name: String) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_names) {
      if Equals(this.m_names[i], name) {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func Build(parent: ref<inkCompoundWidget>, x: Float, y: Float, w: Float, h: Float, specs: array<String>,
    first: ref<TKView>, frame: ref<TKFrame>, provider: ref<TKContent>, style: ref<TKStyle>, message: ref<inkText>) -> Void {
    this.m_provider = provider;
    this.m_message = message;
    this.m_focusRegion = -1;
    let gap = TKScale.F("region.gap", 20.0);

    let left = x;
    let top = y;
    let right = x + w;
    let bottom = y + h;
    let rects: array<Vector4>;
    let i = 0;
    while i < ArraySize(specs) {
      let side = TKStr.Part(specs[i], "|", 1);
      let size = StringToFloat(TKStr.Part(specs[i], "|", 2), 0.0);
      let r = Vector4(0.0, 0.0, 0.0, 0.0);
      switch side {
        case "top":
          r = Vector4(left, top, right - left, size);
          top += size + gap;
          break;
        case "bottom":
          r = Vector4(left, bottom - size, right - left, size);
          bottom -= size + gap;
          break;
        case "left":
          r = Vector4(left, top, size, bottom - top);
          left += size + gap;
          break;
        case "right":
          r = Vector4(right - size, top, size, bottom - top);
          right -= size + gap;
          break;
        default:
          break;
      }
      ArrayPush(rects, r);
      i += 1;
    }
    i = 0;
    while i < ArraySize(specs) {
      let side = TKStr.Part(specs[i], "|", 1);
      if !Equals(side, "top") && !Equals(side, "bottom") && !Equals(side, "left") && !Equals(side, "right") {
        rects[i] = Vector4(left, top, MaxF(0.0, right - left), MaxF(0.0, bottom - top));
      }
      i += 1;
    }

    i = 0;
    while i < ArraySize(specs) {
      let name = TKStr.Part(specs[i], "|", 0);
      let v = i == 0 && IsDefined(first) ? first : new TKView();
      if i > 0 || !IsDefined(first) {
        v.SetFrame(frame);
        v.SetContent(provider);
        v.SetStyle(style);
      }
      this.Pane(parent, v, specs[i], rects[i], style);
      ArrayPush(this.m_names, name);
      ArrayPush(this.m_views, v);
      ArrayPush(this.m_sides, TKStr.Part(specs[i], "|", 1));
      ArrayPush(this.m_overPages, "");
      ArrayPush(this.m_overArgs, "");
      i += 1;
    }
    let overlay: ref<inkCanvas> = new inkCanvas();
    overlay.SetSize(Vector2(w, h));
    overlay.SetMargin(inkMargin(x, y, 0.0, 0.0));
    overlay.Reparent(parent);
    for v in this.m_views {
      v.SetTipLayer(overlay);
    }
  }

  private func Pane(parent: ref<inkCompoundWidget>, v: ref<TKView>, spec: String, r: Vector4, style: ref<TKStyle>) -> Void {
    let name = TKStr.Part(spec, "|", 0);
    let flags = TKStr.Part(spec, "|", 3);
    let title = TKStr.Part(spec, "|", 4);
    let fixed = StrContains(flags, "fixed");
    let cut = 0.0;
    if !StrContains(flags, "square") {
      cut = IsDefined(style) && style.cutCorner > 0.0 ? style.cutCorner : (StrContains(flags, "cut") ? 24.0 : 0.0);
    }
    cut = MinF(cut, MinF(r.Z, r.W) / 3.0);
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetName(StringToName("region_" + name));
    box.SetSize(Vector2(r.Z, r.W));
    box.SetMargin(inkMargin(r.X, r.Y, 0.0, 0.0));
    box.Reparent(parent);
    this.Shell(v, box, r.Z, r.W, cut);
    let pad = TKScale.F("region.pad", 18.0);
    let head = 0.0;
    if StrLen(title) > 0 {

      head = TKScale.F("region.head", 58.0);
      let plate = TKInk.Rect(box, pad, pad, r.Z - pad * 2.0 - cut * 0.5, head);
      plate.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
      plate.SetOpacity(0.8);
      v.Chrome(TKInk.Rect(box, pad, pad, 8.0, head), "accent");
      let t = TKInk.Plain(box, TKScale.T(title), TKScale.I("region.title", 30), n"Semi-Bold", 0.0);
      t.SetVAlign(inkEVerticalAlign.Top);
      t.SetMargin(inkMargin(pad + 26.0, pad + (head - Cast<Float>(TKScale.I("region.title", 30))) / 2.0 - 2.0, 0.0, 0.0));
      v.Chrome(t, "title");
      head += 10.0;
    }
    let barW = fixed ? 0.0 : 18.0;
    let innerW = MaxF(10.0, r.Z - pad * 2.0 - barW);
    let innerH = MaxF(10.0, r.W - pad * 2.0 - head);
    let clip: ref<inkScrollArea> = new inkScrollArea();
    clip.SetAnchor(inkEAnchor.TopLeft);
    clip.SetAnchorPoint(Vector2(0.0, 0.0));
    clip.SetFitToContentDirection(inkFitToContentDirection.None);
    clip.SetConstrainContentPosition(false);
    clip.SetUseInternalMask(true);
    clip.SetSize(Vector2(innerW, innerH));
    clip.SetMargin(inkMargin(pad, pad + head, 0.0, 0.0));
    clip.Reparent(box);
    let content: ref<inkVerticalPanel> = new inkVerticalPanel();
    content.SetAnchor(inkEAnchor.TopLeft);
    content.SetAnchorPoint(Vector2(0.0, 0.0));
    content.Reparent(clip);
    let track: ref<inkRectangle>;
    let thumb: ref<inkRectangle>;
    if !fixed {
      track = TKInk.Rect(box, r.Z - pad - 4.0, pad + head, 4.0, innerH);
      track.SetOpacity(0.35);
      v.Chrome(track, "rule");
      thumb = TKInk.Rect(box, r.Z - pad - 4.0, pad + head, 4.0, 40.0);
      v.Chrome(thumb, "value");
    }

    v.BindRegion(this, name, content, innerW + 40.0, fixed);
    v.BindScroll(clip, innerH, track, thumb);
  }

  private func Shell(v: ref<TKView>, box: ref<inkCanvas>, w: Float, h: Float, cut: Float) -> Void {
    let opacity = TKScale.F("region.fill", 0.45);
    if cut <= 0.0 {
      let fill = TKInk.Rect(box, 0.0, 0.0, w, h);
      fill.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
      fill.SetOpacity(opacity);
      let edges = [Vector4(0.0, 0.0, w, 2.0), Vector4(0.0, h - 2.0, w, 2.0), Vector4(0.0, 0.0, 2.0, h), Vector4(w - 2.0, 0.0, 2.0, h)];
      for e in edges {
        v.Chrome(TKInk.Rect(box, e.X, e.Y, e.Z, e.W), "rule");
      }
      return;
    }
    let mid = TKInk.Rect(box, 0.0, cut, w, h - cut * 2.0);
    mid.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    mid.SetOpacity(opacity);
    let y = 0.0;
    while y < cut {
      let s = MinF(3.0, cut - y);
      let top = TKInk.Rect(box, 0.0, y, w - (cut - y), s);
      top.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
      top.SetOpacity(opacity);
      let bottom = TKInk.Rect(box, cut - y - s, h - cut + y, w - (cut - y - s), s);
      bottom.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
      bottom.SetOpacity(opacity);
      y += s;
    }
    v.Chrome(TKInk.Rect(box, 0.0, 0.0, w - cut, 2.0), "rule");
    v.Chrome(TKInk.Rect(box, w - 2.0, cut, 2.0, h - cut), "rule");
    v.Chrome(TKInk.Rect(box, cut, h - 2.0, w - cut, 2.0), "rule");
    v.Chrome(TKInk.Rect(box, 0.0, 0.0, 2.0, h - cut), "rule");
    let color = TKTheme.Color(v.Theme(), "rule");
    TKInk.Seg(box, Vector2(w - cut, 1.0), Vector2(w - 1.0, cut), 2.0, color, 1.0);
    TKInk.Seg(box, Vector2(1.0, h - cut), Vector2(cut, h - 1.0), 2.0, color, 1.0);
  }

  public func Show(page: String, arg: String, message: String) -> Void {
    let same = Equals(page, this.m_page) && Equals(arg, this.m_arg);
    if !same && StrLen(this.m_page) > 0 && !this.m_noPush {
      ArrayPush(this.m_history, this.m_page + "~" + this.m_arg);
      while ArraySize(this.m_history) > 30 {
        ArrayErase(this.m_history, 0);
      }
    }
    this.m_noPush = false;
    if !same {
      this.EndOverlays();
    }
    let none: array<String>;
    this.Draw(page, arg, message, same, none);
  }

  private func Draw(page: String, arg: String, message: String, keep: Bool, only: array<String>) -> Void {
    this.m_page = page;
    this.m_arg = arg;
    let data = new TKPage();
    data.content = this.m_provider;
    data.page = page;
    data.Request(page, arg);
    let parts = this.Split(data);
    let i = 0;
    while i < ArraySize(this.m_views) {
      if ArraySize(only) == 0 || ArrayContains(only, this.m_names[i]) {
        if StrLen(this.m_overPages[i]) > 0 {
          this.m_views[i].Present(this.OverlayPage(i), this.m_overPages[i], this.m_overArgs[i], keep);
        } else {
          this.m_views[i].Present(parts[i], page, arg, keep);
        }
      }
      i += 1;
    }
    if IsDefined(this.m_message) {
      this.m_message.SetText(TKScale.T(StrLen(data.message) > 0 ? data.message : message));
    }
  }

  public func HasOverlay() -> Bool {
    for p in this.m_overPages {
      if StrLen(p) > 0 {
        return true;
      }
    }
    return false;
  }

  private func DefaultOverlay() -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_sides) {
      if Equals(this.m_sides[i], "fill") {
        return i;
      }
      i += 1;
    }
    return 0;
  }

  private func OverlayPage(i: Int32) -> ref<TKPage> {
    let data = new TKPage();
    data.content = this.m_provider;
    data.page = this.m_overPages[i];
    data.Request(this.m_overPages[i], this.m_overArgs[i]);
    let p = new TKPage();
    p.content = this.m_provider;
    p.page = data.page;
    p.answered = true;
    p.theme = data.theme;
    p.wheelReserved = data.wheelReserved;
    if !data.noOverlayBack {
      p.Actions(TKKind.Item(), StrLen(data.title) > 0 ? data.title : StrUpper(data.page), data.subtitle, "", ["BACK"], ["tk_overlay_back"], [this.m_names[i]], 0.0, true);
    } else {

      if StrLen(data.title) > 0 {
        p.Heading(data.title);
      }
      if StrLen(data.subtitle) > 0 {
        p.Note(data.subtitle);
      }
    }
    for r in data.rows {
      if r.kind != TKKind.Region() {
        ArrayPush(p.rows, r);
      }
    }
    return p;
  }

  public func Overlay(region: String, page: String, arg: String) -> Void {
    let i = StrLen(region) > 0 ? this.IndexOf(region) : this.DefaultOverlay();
    if i < 0 {
      return;
    }
    let opening = StrLen(this.m_overPages[i]) == 0;
    this.m_overPages[i] = page;
    this.m_overArgs[i] = arg;
    this.m_views[i].Present(this.OverlayPage(i), page, arg, false);
    if opening {
      this.m_views[i].SlideIn();
    }
  }

  public func EndOverlay(region: String) -> Bool {
    let had = false;
    let i = 0;
    while i < ArraySize(this.m_overPages) {
      if StrLen(this.m_overPages[i]) > 0 && (StrLen(region) == 0 || Equals(this.m_names[i], region)) {
        this.m_overPages[i] = "";
        this.m_overArgs[i] = "";
        had = true;
        let only = [this.m_names[i]];
        this.Draw(this.m_page, this.m_arg, "", true, only);
      }
      i += 1;
    }
    return had;
  }

  private func EndOverlays() -> Void {
    let i = 0;
    while i < ArraySize(this.m_overPages) {
      this.m_overPages[i] = "";
      this.m_overArgs[i] = "";
      i += 1;
    }
  }

  private func Split(data: ref<TKPage>) -> array<ref<TKPage>> {
    let parts: array<ref<TKPage>>;
    for name in this.m_names {
      let p = new TKPage();
      p.content = data.content;
      p.page = data.page;
      p.answered = data.answered;
      p.title = data.title;
      p.subtitle = data.subtitle;
      p.theme = data.theme;
      p.section = data.section;
      ArrayPush(parts, p);
    }
    if ArraySize(parts) == 0 {
      return parts;
    }
    let at = 0;
    for r in data.rows {
      if r.kind == TKKind.Region() {
        at = Max(0, this.IndexOf(r.text));
      } else {
        ArrayPush(parts[at].rows, r);
        if r.kind == TKKind.Custom() && r.fraction > 0.0 {
          parts[at].wheelReserved = true;
        }
      }
    }
    return parts;
  }

  public func Act(action: String, arg: String) -> Void { this.ActFrom(null, action, arg); }

  public func ActFrom(from: ref<TKView>, action: String, arg: String) -> Void {
    if Equals(action, "tk_overlay_back") {
      this.EndOverlay(arg);
      return;
    }
    let at = IsDefined(from) ? this.IndexOf(from.Region()) : -1;
    let over = at >= 0 && StrLen(this.m_overPages[at]) > 0;
    let act: ref<TKPage> = new TKPage();
    act.content = this.m_provider;
    act.page = over ? this.m_overPages[at] : this.m_page;
    for v in this.m_views {
      v.AddFields(act);
    }
    act.Act(action, arg);
    if act.rebuild && IsDefined(this.m_provider) {
      this.m_provider.Rebuild();
    }
    if act.skipRedraw {
      return;
    }
    let only = act.refresh;

    if act.overlayEnd {
      let target = StrLen(act.overlayRegion) > 0 ? act.overlayRegion : (over ? this.m_names[at] : "");
      this.EndOverlay(target);
    }
    if StrLen(act.overlayPage) > 0 {
      this.Overlay(act.overlayRegion, act.overlayPage, act.overlayArg);
    }
    if over && StrLen(act.nextPage) > 0 && !act.overlayEnd {

      this.Overlay(this.m_names[at], act.nextPage, act.nextArg);
    } else {
      let moved = StrLen(act.nextPage) > 0 && (NotEquals(act.nextPage, this.m_page) || NotEquals(act.nextArg, this.m_arg));
      if moved {
        this.Show(act.nextPage, act.nextArg, act.message);
      } else {

        if ArraySize(only) > 0 || (!act.overlayEnd && StrLen(act.overlayPage) == 0) {
          this.Draw(this.m_page, this.m_arg, act.message, true, only);
        } else {
          if IsDefined(this.m_message) {
            this.m_message.SetText(TKScale.T(act.message));
          }
        }
      }
    }
    if StrLen(act.confirmAction) > 0 && ArraySize(this.m_views) > 0 {
      (IsDefined(from) ? from : this.m_views[0]).Dialog(act.confirmText, StrLen(act.confirmYes) > 0 ? act.confirmYes : "CONFIRM", act.confirmAction, act.confirmArg);
    }
  }

  public func Back() -> Bool {
    if this.EndOverlay("") {
      return true;
    }
    let n = ArraySize(this.m_history);
    if n == 0 {
      return false;
    }
    let last = this.m_history[n - 1];
    ArrayPop(this.m_history);
    this.m_noPush = true;
    this.Show(StrBeforeFirst(last, "~"), StrAfterFirst(last, "~"), "");
    return true;
  }

  public func CloseOverlay() -> Bool {
    let had = false;
    for v in this.m_views {
      if v.CloseOwnOverlay() {
        had = true;
      }
    }
    return had;
  }

  public func IsTyping() -> Bool {
    for v in this.m_views {
      if v.IsTyping() {
        return true;
      }
    }
    return false;
  }

  public func HasFocus() -> Bool = this.m_focusRegion >= 0

  public func FocusStep(step: Int32) -> Bool {
    if this.m_focusRegion < 0 || this.m_focusRegion >= ArraySize(this.m_views) {
      return this.FocusRegion(1);
    }
    return this.m_views[this.m_focusRegion].FocusStep(step);
  }

  public func FocusRegion(dir: Int32) -> Bool {
    let n = ArraySize(this.m_views);
    if n == 0 {
      return false;
    }
    let at = this.m_focusRegion;
    let k = 0;
    while k < n {
      at = at < 0 ? (dir > 0 ? 0 : n - 1) : (at + dir + n) % n;
      if this.m_views[at].Focusables() > 0 {
        if this.m_focusRegion >= 0 && this.m_focusRegion < n {
          this.m_views[this.m_focusRegion].Focus(-1);
        }
        this.m_focusRegion = at;
        this.m_views[at].FocusStep(1);
        return true;
      }
      k += 1;
    }
    return false;
  }

  public func Activate() -> Bool {
    return this.m_focusRegion >= 0 && this.m_focusRegion < ArraySize(this.m_views) && this.m_views[this.m_focusRegion].Activate();
  }

  public func ClearFocus() -> Void {
    for v in this.m_views {
      v.Focus(-1);
    }
    this.m_focusRegion = -1;
  }

  public func Stop() -> Void {
    for v in this.m_views {
      v.StopCustom();
      v.StopLive();
    }
  }
}

public abstract class TKRows {

  public static func Stack(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let c = v.Content();
    let font = TKScale.I("meter.font", 30);
    let top = TKInk.Strip(c, 10.0);
    v.Hoverable(v.Text(top, r.text, font, n"Medium", "text", 0.0), r.tip);
    v.Text(top, "   " + r.value, font, n"Semi-Bold", "value", 0.0);
    let w = v.RowWidth();
    let h = TKScale.F("stack.h", 26.0);
    let bar: ref<inkCanvas> = new inkCanvas();
    bar.SetSize(Vector2(w, h));
    bar.SetMargin(inkMargin(0.0, 8.0, 0.0, 0.0));
    bar.SetHAlign(inkEHorizontalAlign.Left);
    bar.Reparent(c);
    let bed = TKInk.Rect(bar, 0.0, 0.0, w, h);
    v.Paint(bed, "rule");
    bed.SetOpacity(0.4);
    let names = TKStr.Split(r.label, "|");
    let shares = TKStr.Split(r.action, "|");
    let colors = TKStr.Split(r.arg, "|");
    let legend = TKInk.Strip(c, 10.0);
    let x = 0.0;
    let k = 0;
    while k < ArraySize(names) {
      let share = ClampF(StringToFloat(k < ArraySize(shares) ? shares[k] : "0", 0.0), 0.0, 1.0);
      let color = k < ArraySize(colors) ? colors[k] : "";
      if share > 0.0 && x < w {
        let part = TKInk.Rect(bar, x, 0.0, MaxF(3.0, MinF(w - x, w * share) - 2.0), h);
        v.Paint(part, "value");
        v.Tone(part, color);
        x += w * share;
      }

      let chip = TKInk.Rect(legend, 0.0, 0.0, 16.0, 16.0);
      chip.SetMargin(inkMargin(k > 0 ? 30.0 : 0.0, 8.0, 10.0, 0.0));
      v.Paint(chip, "value");
      v.Tone(chip, color);
      v.Text(legend, names[k], TKScale.I("type.xs", 24), n"Medium", "text", 0.0);
      k += 1;
    }
    v.Grew(Cast<Float>(font) * 1.4 + h + 18.0 + Cast<Float>(TKScale.I("type.xs", 24)) * 1.4 + 10.0);
  }

  public static func Heading(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let c = v.Content();

    if v.Style().headerPlates {
      let size = TKScale.I("heading", 46) - 8;
      let ph = Cast<Float>(size) * 1.4 + 14.0;
      let pw = v.Width() - 40.0;
      let plate: ref<inkCanvas> = new inkCanvas();
      plate.SetSize(Vector2(pw, ph));
      plate.SetMargin(inkMargin(0.0, 22.0, 0.0, 14.0));
      plate.SetHAlign(inkEHorizontalAlign.Left);
      plate.Reparent(c);
      let back = TKInk.Rect(plate, 0.0, 0.0, pw, ph);
      back.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
      back.SetOpacity(0.6);
      v.Paint(TKInk.Rect(plate, 0.0, 0.0, 9.0, ph), "accent");
      let under = TKInk.Rect(plate, 0.0, ph - 2.0, pw, 2.0);
      v.Paint(under, "rule");

      let k = 0;
      while k < 5 {
        let tick = TKInk.Rect(plate, pw - 24.0 - Cast<Float>(k) * 14.0, ph * 0.3, 6.0, ph * 0.4);
        v.Paint(tick, "rule");
        k += 1;
      }
      let label = v.Text(plate, r.text, size, n"Semi-Bold", "accent", 0.0);
      label.SetMargin(inkMargin(26.0, 5.0, 0.0, 0.0));
      v.Grew(ph + 36.0);
      return;
    }
    let head = v.Text(c, r.text, TKScale.I("heading", 46), n"Medium", "accent", 0.0);
    head.SetMargin(inkMargin(0.0, 22.0, 0.0, 6.0));
    v.Grew(Cast<Float>(TKScale.I("heading", 46)) * 1.4 + 45.0);
    let rule: ref<inkRectangle> = new inkRectangle();
    rule.SetSize(Vector2(v.Width() - 40.0, 3.0));
    rule.SetMargin(inkMargin(0.0, 0.0, 0.0, 14.0));
    rule.SetHAlign(inkEHorizontalAlign.Left);
    rule.Reparent(c);
    v.Paint(rule, "rule");
  }

  public static func Text(v: ref<TKView>, r: ref<TKRow>) -> Void {
    v.Tone(v.Text(v.Content(), r.text, TKScale.I("text", 32), n"Regular", "text", 6.0), r.color);
    v.Grew(Cast<Float>(TKScale.I("text", 32)) * 1.4 + 6.0);
  }

  public static func Pair(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let pair = TKInk.Strip(v.Content(), 6.0);
    v.Hoverable(v.Text(pair, r.text, TKScale.I("pair", 30), n"Medium", "text", 0.0), r.tip);
    v.Tone(v.Text(pair, "   " + r.value, TKScale.I("pair", 30), n"Semi-Bold", "value", 0.0), r.color);
    v.Grew(Cast<Float>(TKScale.I("pair", 30)) * 1.4 + 6.0);
  }

  public static func Meter(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let c = v.Content();
    let top = TKInk.Strip(c, 10.0);
    v.Hoverable(v.Text(top, r.text, TKScale.I("meter.font", 30), n"Medium", "text", 0.0), r.tip);
    v.Text(top, "   " + r.value, TKScale.I("meter.font", 30), n"Semi-Bold", "value", 0.0);
    let mw = MinF(TKScale.F("meter.w", 900.0), v.Width());
    let mh = TKScale.F("meter.h", 10.0) + (v.Style().segmentedBars > 1 ? 6.0 : 0.0);
    let track = TKInk.Track(c, mw, mh, 6.0);
    TKInk.Rect(track, 0.0, 0.0, MaxF(2.0, mw * ClampF(r.fraction, 0.0, 1.0)), mh).SetTintColor(TKTheme.Gold());
    v.Segments(track, 0.0, 0.0, mw, mh);
    v.Grew(Cast<Float>(TKScale.I("meter.font", 30)) * 1.4 + TKScale.F("meter.h", 10.0) + 16.0);
  }

  public static func Button(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    v.ActButton(v.Content(), i, 0, r.label, r.on, TKScale.F("button.w", 520.0), TKScale.ButtonH(), TKScale.I("button.font", 30))
      .GetRootWidget().SetMargin(inkMargin(0.0, 14.0, 0.0, 0.0));
    v.Grew(TKScale.ButtonH() + 14.0);
  }

  public static func Note(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let note = v.Text(v.Content(), r.text, TKScale.I("note", 26), n"Regular", "text", 4.0);
    note.SetLetterCase(textLetterCase.OriginalCase);
    note.SetWrapping(true, Equals(r.value, "item") ? v.RowWidth() - TKScale.F("item.w", 380.0) - 40.0 : v.Width());
    note.SetOpacity(0.85);
    v.Grew(TKInk.Lines(r.text, TKScale.I("note", 26), v.Width()) * Cast<Float>(TKScale.I("note", 26)) * 1.4 + 4.0);
  }

  public static func Gap(v: ref<TKView>) -> Void {
    let gap: ref<inkRectangle> = new inkRectangle();
    gap.SetSize(Vector2(10.0, 18.0));
    gap.SetOpacity(0.0);
    gap.Reparent(v.Content());
    v.Grew(18.0);
  }

  public static func Item(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let iw = TKScale.F("item.w", 380.0);
    let track = StrLen(r.extra) > 0 ? TKRows.PipsWidth(r.extra) + 24.0 : 0.0;
    let item = v.RowBox(v.RowWidth() - iw - 40.0 - track, r.text, r.value, r.color, r.tip);
    if StrLen(r.label) > 0 {
      v.PinRight(v.ActButton(item, i, 0, r.label, r.on, iw, TKScale.ButtonH(), TKScale.I("button.font", 30)).GetRootWidget());
    }
    if StrLen(r.extra) > 0 {
      TKRows.Pips(v, item, r.extra, iw + 24.0);
    }
  }

  public static func Buttons(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let n = ArraySize(r.labels);

    let bw: Float = n > 4 ? TKScale.F("multi.wSmall", 170.0) : TKScale.F("multi.w", 280.0);
    let line = v.RowBox(MaxF(400.0, v.RowWidth() - Cast<Float>(n) * (bw + 16.0) - 40.0), r.text, r.value, r.color, r.tip);
    let group: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    group.Reparent(line);
    v.PinRight(group);
    let k = 0;
    while k < n {
      let b = v.ActButton(group, i, k, r.labels[k], true, bw, TKScale.F("multi.h", 60.0), TKScale.I("multi.font", 24));
      b.GetRootWidget().SetMargin(inkMargin(16.0, 6.0, 0.0, 0.0));
      k += 1;
    }
  }

  public static func Links(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let row = TKInk.Strip(v.Content(), 8.0);
    let names = StrSplit(r.text, "|");
    let targets = StrSplit(r.value, "|");
    let n = 0;
    let width = MinF(TKScale.F("link.w", 360.0), (v.Width() - 20.0) / Cast<Float>(Max(1, ArraySize(names))) - 16.0);
    v.linkRows += 1;
    if v.linkRows > 1 {
      let used = Cast<Float>(ArraySize(names)) * (width + 16.0);
      row.SetMargin(inkMargin(MaxF(0.0, (v.RowWidth() - used) / 2.0), 8.0, 0.0, 0.0));
    }
    while n < ArraySize(names) && n < ArraySize(targets) {
      let b = v.LinkButton(row, names[n], targets[n], Equals(targets[n], r.label), width, TKScale.F("link.h", 58.0), TKScale.I("link.font", 26));
      b.GetRootWidget().SetMargin(inkMargin(0.0, 0.0, 16.0, 0.0));
      n += 1;
    }
    v.Grew(TKScale.F("link.h", 58.0) + 16.0);
  }

  public static func Section(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let size = TKScale.I("heading", 46);
    let c = v.Content();
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(v.RowWidth(), MaxF(Cast<Float>(size) * 1.4, TKScale.ButtonH())));
    row.SetMargin(inkMargin(0.0, 18.0, 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(c);
    let strip: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    strip.Reparent(row);
    v.Text(strip, (r.on ? "[-]  " : "[+]  ") + r.text, size, n"Medium", "accent", 0.0);
    let note = v.Text(strip, "     " + r.value, TKScale.I("row.detail", 29), n"Regular", "text", 0.0);
    note.SetVAlign(inkEVerticalAlign.Center);
    v.PinRight(v.ActButton(row, i, 0, r.label, true, 220.0, TKScale.ButtonH(), TKScale.I("button.font", 30)).GetRootWidget());
    let rule: ref<inkRectangle> = new inkRectangle();
    rule.SetSize(Vector2(v.RowWidth(), 3.0));
    rule.SetMargin(inkMargin(0.0, 4.0, 0.0, 8.0));
    rule.SetHAlign(inkEHorizontalAlign.Left);
    rule.Reparent(c);
    v.Paint(rule, "rule");
    v.Grew(MaxF(Cast<Float>(size) * 1.4, TKScale.ButtonH()) + 33.0);
  }

  public static func Entry(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let box: ref<inkVerticalPanel> = new inkVerticalPanel();
    box.SetMargin(inkMargin(0.0, 14.0, 0.0, 0.0));
    box.SetHAlign(inkEHorizontalAlign.Left);
    box.Reparent(v.Content());
    let small = TKScale.I("row.detail", 29);
    let parts = StrSplit(r.label, "|");
    let top = TKInk.Strip(box, 0.0);
    v.Text(top, ArraySize(parts) > 0 ? parts[0] : "", small, n"Semi-Bold", "value", 0.0);
    v.Sep(top, small);
    v.Tone(v.Text(top, ArraySize(parts) > 1 ? parts[1] : "", small, n"Semi-Bold", "value", 0.0), r.color);
    v.Sep(top, small);
    v.Text(top, ArraySize(parts) > 2 ? parts[2] : "", small, n"Medium", "accent", 0.0);
    let h = v.Text(box, r.text, TKScale.I("row.title", 32), n"Medium", "value", 4.0);
    h.SetWrapping(true, v.RowWidth());
    v.Tone(h, r.color);

    if StrLen(r.value) > 0 {
      let line = TKInk.Strip(box, 4.0);
      let used = 0.0;
      let first = true;
      for item in StrSplit(r.value, "|") {
        let w = Cast<Float>(StrLen(item)) * 0.55 * Cast<Float>(small) + 34.0;
        if !first && used + w > v.RowWidth() {
          line = TKInk.Strip(box, 2.0);
          used = 0.0;
          first = true;
        }
        if !first {
          v.Sep(line, small);
        }
        v.Text(line, item, small, n"Regular", "text", 0.0);
        used += w;
        first = false;
      }
    }
    if StrLen(r.action) > 0 {
      let q = v.Text(box, r.action, TKScale.I("note", 26), n"Regular", "text", 4.0);
      q.SetLetterCase(textLetterCase.OriginalCase);
      q.SetWrapping(true, v.RowWidth());
      q.SetOpacity(0.8);
    }
    v.Rule(box, 14.0, 0.5);
    v.Grew(Cast<Float>(small) * 1.4 + TKInk.Lines(r.text, TKScale.I("row.title", 32), v.RowWidth()) * 42.0 + (StrLen(r.value) > 0 ? Cast<Float>(small) * 1.4 + 4.0 : 0.0)
      + (StrLen(r.action) > 0 ? TKInk.Lines(r.action, TKScale.I("note", 26), v.RowWidth()) * 36.0 + 4.0 : 0.0) + 32.0);
  }

  public static func Dossier(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let c = v.Content();
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(v.RowWidth(), 118.0));
    row.SetMargin(inkMargin(0.0, 8.0, 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(c);
    let col: ref<inkVerticalPanel> = new inkVerticalPanel();
    col.Reparent(row);
    v.Text(col, r.text, TKScale.TypeXL(), n"Semi-Bold", "title", 0.0);
    v.Text(col, r.value, TKScale.I("row.detail", 29), n"Medium", "text", 4.0);

    TKCards.Stamp(v, row, r.label, r.color, 10.0, 22.0, 30);
    v.Rule(c, 6.0, 0.8);
    v.Grew(134.0);
  }

  public static func Columns(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let strip = TKInk.Strip(v.Content(), 10.0);
    let colW = v.RowWidth() / 2.0 - 20.0;
    TKRows.PairColumn(v, strip, colW, r.text, r.value);
    TKRows.PairColumn(v, strip, colW, r.label, r.action);
    let left = StrSplit(r.text, "|");
    let right = StrSplit(r.label, "|");
    v.Grew(Cast<Float>(Max(ArraySize(left), ArraySize(right))) * Cast<Float>(TKScale.I("pair", 30)) * 1.4 + 30.0);
  }

  private static func PairColumn(v: ref<TKView>, parent: ref<inkCompoundWidget>, width: Float, labels: String, values: String) -> Void {
    let col: ref<inkVerticalPanel> = new inkVerticalPanel();
    col.SetMargin(inkMargin(0.0, 0.0, 40.0, 0.0));
    col.SetSize(Vector2(width, 10.0));
    col.Reparent(parent);
    let names = StrSplit(labels, "|");
    let vals = StrSplit(values, "|");
    let size = TKScale.I("pair", 30);
    let k = 0;
    let i = 0;
    while i < ArraySize(names) {
      if StrBeginsWith(names[i], "#") {
        v.Text(col, StrAfterFirst(names[i], "#"), size, n"Semi-Bold", "accent", i == 0 ? 0.0 : 14.0);
        let rule: ref<inkRectangle> = new inkRectangle();
        rule.SetSize(Vector2(width, 2.0));
        rule.SetMargin(inkMargin(0.0, 4.0, 0.0, 6.0));
        rule.SetOpacity(0.6);
        rule.Reparent(col);
        v.Paint(rule, "rule");
      } else {
        let row: ref<inkCanvas> = new inkCanvas();
        row.SetSize(Vector2(width, Cast<Float>(size) * 1.4));
        row.Reparent(col);
        v.Text(row, names[i], size, n"Medium", "text", 0.0);
        let val = v.Text(row, k < ArraySize(vals) ? vals[k] : "", size, n"Semi-Bold", "value", 0.0);
        k += 1;
        val.SetAnchor(inkEAnchor.TopRight);
        val.SetAnchorPoint(Vector2(1.0, 0.0));
        val.SetHorizontalAlignment(textHorizontalAlignment.Right);
      }
      i += 1;
    }
  }

  public static func Track(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let c = v.Content();
    if StrLen(r.text) > 0 || StrLen(r.value) > 0 {
      let top = TKInk.Strip(c, 10.0);
      v.Hoverable(v.Text(top, r.text, TKScale.I("meter.font", 30), n"Medium", "text", 0.0), r.tip);
      v.Text(top, "   " + r.value, TKScale.I("meter.font", 30), n"Semi-Bold", "value", 0.0);
      v.Grew(Cast<Float>(TKScale.I("meter.font", 30)) * 1.4 + 10.0);
    }
    let w = MinF(TKScale.F("track.w", 1400.0), v.RowWidth());
    let h = TKScale.F("meter.h", 10.0);
    let font = TKScale.I("note", 26);
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(w, h + 26.0 + Cast<Float>(font) * 1.3));
    box.SetMargin(inkMargin(0.0, 8.0, 0.0, 6.0));
    box.SetHAlign(inkEHorizontalAlign.Left);
    box.Reparent(c);
    v.Grew(h + 26.0 + Cast<Float>(font) * 1.3 + 14.0);
    TKInk.Meter(box, w, h, r.fraction, TKTheme.Gold(), 8.0);
    let labels = StrSplit(r.label, "|");
    let at = StrSplit(r.action, "|");
    let n = 0;
    while n < ArraySize(labels) && n < ArraySize(at) {
      let f = ClampF(StringToFloat(at[n]), 0.0, 1.0);
      let reached = r.fraction >= f;
      let tick = TKInk.Rect(box, w * f, 0.0, 3.0, h + 16.0);
      v.Paint(tick, reached ? "value" : "rule");
      let name = v.Text(box, labels[n], font, n"Semi-Bold", reached ? "value" : "text", 0.0);
      name.SetMargin(inkMargin(w * f + 8.0, h + 18.0, 0.0, 0.0));
      name.SetVAlign(inkEVerticalAlign.Top);
      if !reached {
        name.SetOpacity(0.5);
      }
      n += 1;
    }
  }

  public static func PipsWidth(spec: String) -> Float {
    let max = Cast<Float>(Max(1, StringToInt(TKStr.Part(spec, ":", 1), 3)));
    return max * 72.0 + (max - 1.0) * 10.0;
  }

  public static func Pips(v: ref<TKView>, row: ref<inkCanvas>, spec: String, right: Float) -> Void {
    let level = StringToInt(TKStr.Part(spec, ":", 0), 0);
    let max = Max(1, StringToInt(TKStr.Part(spec, ":", 1), 3));
    let roman = ["I", "II", "III", "IV", "V", "VI"];
    let h = 48.0;
    let group: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    group.SetAnchor(inkEAnchor.TopRight);
    group.SetAnchorPoint(Vector2(1.0, 0.0));
    group.SetMargin(inkMargin(0.0, 2.0 + (TKScale.ButtonH() - h) / 2.0, right, 0.0));
    group.Reparent(row);
    let k = 0;
    while k < max {
      let lit = k < level;
      let box: ref<inkCanvas> = new inkCanvas();
      box.SetSize(Vector2(72.0, h));
      box.SetMargin(inkMargin(k > 0 ? 10.0 : 0.0, 0.0, 0.0, 0.0));
      box.Reparent(group);
      if lit {
        v.Paint(TKInk.Rect(box, 0.0, 0.0, 72.0, h), "value");
      } else {
        v.Frame(box, 72.0, h, 2.0, k == level ? "value" : "rule", k == level ? 0.8 : 1.0);
      }
      let t = v.Text(box, k < ArraySize(roman) ? roman[k] : IntToString(k + 1), 26, n"Semi-Bold", lit ? "value" : "text", 0.0);
      t.SetAnchor(inkEAnchor.Centered);
      t.SetAnchorPoint(Vector2(0.5, 0.5));
      if lit {
        v.Fix(t, TKTheme.Ink());
      } else {
        if k > level {
          t.SetOpacity(0.5);
        }
      }
      k += 1;
    }
  }
}

public abstract class TKTables {

  private static func Col(spec: String, w: Float, out right: Bool) -> Float {
    right = StrBeginsWith(spec, "R");
    return w * StringToFloat(StrMid(spec, 1, StrLen(spec) - 1), 0.0) / 100.0;
  }

  public static func Table(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let style = r.color;
    let head = Equals(style, "head");
    let group = Equals(style, "group");
    let total = Equals(style, "total");
    let net = Equals(style, "net");
    let base = TKScale.I("table.font", 28);
    let size = head || group ? Max(14, base - 4) : (net ? base + 4 : base);
    let w = v.RowWidth();
    let h = Cast<Float>(size) * 1.6;
    let c = v.Content();
    if total || net {
      v.Rule(c, 4.0, 0.9);
    }
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(w, h));
    row.SetMargin(inkMargin(0.0, group ? 10.0 : 0.0, 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(c);
    v.Grew(h + (group ? 10.0 : 0.0) + (total || net || head ? 6.0 : 0.0));
    if head || group {
      v.tableLine = 0;
    }
    if Equals(style, "line") {
      if v.tableLine % 2 == 1 {
        let shade = TKInk.Rect(row, 0.0, 0.0, w, h);
        v.Paint(shade, "rule");
        shade.SetOpacity(0.25);
      }
      v.tableLine += 1;
    }
    let spec = TKStr.Split(r.value, "|");
    let parts = TKStr.Split(r.text, "|");
    let x = 0.0;
    let k = 0;
    while k < ArraySize(spec) {
      let right: Bool;
      let cw = TKTables.Col(spec[k], w, right);
      let cell: ref<inkCanvas> = new inkCanvas();
      cell.SetSize(Vector2(MaxF(10.0, cw - 24.0), h));
      cell.SetMargin(inkMargin(x + 12.0, 0.0, 0.0, 0.0));
      cell.Reparent(row);
      let s = k < ArraySize(parts) ? parts[k] : "";
      let red = StrBeginsWith(s, "!");
      if red {
        s = StrMid(s, 1, StrLen(s) - 1);
      }
      let t = v.Text(cell, s, size, head || total || net ? n"Semi-Bold" : n"Medium", head ? "text" : "value", 0.0);
      t.SetAnchor(right ? inkEAnchor.CenterRight : inkEAnchor.CenterLeft);
      t.SetAnchorPoint(Vector2(right ? 1.0 : 0.0, 0.5));
      if right {
        t.SetHorizontalAlignment(textHorizontalAlignment.Right);
      }
      if group {
        v.Paint(t, "accent");
      } else {
        if !head {
          if red || StrBeginsWith(s, "-") && StrLen(s) > 1 {
            v.Fix(t, TKTheme.Loss());
          } else {
            if StrBeginsWith(s, "+") {
              v.Fix(t, TKTheme.Gain());
            } else {
              if Equals(s, "-") {
                v.Paint(t, "text");
                t.SetOpacity(0.5);
              }
            }
          }
        }
      }
      x += cw;
      k += 1;
    }
    if head {
      v.Rule(c, 0.0, 0.6);
    }
    if net {
      v.Rule(c, 4.0, 0.9);
      v.Rule(c, 3.0, 0.9);
    }
  }

  public static func Board(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let style = r.color;
    let head = Equals(style, "head");
    let title = Equals(style, "title");
    let size = title ? 42 : (head ? 20 : 26);
    let h = title ? 62.0 : (head ? 32.0 : 50.0);
    let bw = StrLen(r.label) > 0 ? TKScale.F("board.button", 230.0) : 0.0;
    let w = v.RowWidth() - (bw > 0.0 ? bw + 16.0 : 0.0);
    let c = v.Content();
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(v.RowWidth(), h));
    row.SetMargin(inkMargin(0.0, head ? 12.0 : (title ? 16.0 : 6.0), 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(c);
    v.Grew(h + (head ? 12.0 : (title ? 27.0 : 6.0)));
    let spec = TKStr.Split(r.value, "|");
    let parts = TKStr.Split(r.text, "|");
    let x = 0.0;
    let k = 0;
    while k < ArraySize(spec) {
      let right: Bool;
      let cw = TKTables.Col(spec[k], w, right);
      if !head && !title {

        let tile = TKInk.Rect(row, x, 0.0, MaxF(4.0, cw - 5.0), h);
        tile.SetTintColor(new HDRColor(0.035, 0.035, 0.04, 1.0));
        tile.SetOpacity(0.85);
        let seam = TKInk.Rect(row, x, h / 2.0 - 1.0, MaxF(4.0, cw - 5.0), 2.0);
        seam.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
        seam.SetOpacity(0.95);
      }
      let cell: ref<inkCanvas> = new inkCanvas();
      cell.SetSize(Vector2(MaxF(10.0, cw - 30.0), h));
      cell.SetMargin(inkMargin(x + 13.0, 0.0, 0.0, 0.0));
      cell.Reparent(row);
      let s = k < ArraySize(parts) ? parts[k] : "";
      let color = TKTheme.Amber();
      let mark = StrLeft(s, 1);
      if Equals(mark, "!") || Equals(mark, "*") || Equals(mark, "^") || Equals(mark, "~") {
        s = StrMid(s, 1, StrLen(s) - 1);
        if Equals(mark, "!") { color = TKTheme.Loss(); }
        if Equals(mark, "*") { color = TKTheme.Gain(); }
        if Equals(mark, "^") { color = new HDRColor(1.0, 0.95, 0.35, 1.0); }
        if Equals(mark, "~") { color = new HDRColor(0.5, 0.5, 0.52, 1.0); }
      }
      let t = v.Text(cell, s, size, n"Semi-Bold", "value", 0.0);
      v.Fix(t, color);
      if head {
        t.SetOpacity(0.65);
      }
      t.SetAnchor(right ? inkEAnchor.CenterRight : inkEAnchor.CenterLeft);
      t.SetAnchorPoint(Vector2(right ? 1.0 : 0.0, 0.5));
      if right {
        t.SetHorizontalAlignment(textHorizontalAlignment.Right);
      }
      x += cw;
      k += 1;
    }
    if bw > 0.0 {
      let root = v.ActButton(row, i, 0, r.label, r.on, bw, h - 4.0, 24).GetRootWidget();
      root.SetAnchor(inkEAnchor.TopRight);
      root.SetAnchorPoint(Vector2(1.0, 0.0));
      root.SetMargin(inkMargin(0.0, 2.0, 0.0, 0.0));
    }
    if title {
      let rule: ref<inkRectangle> = new inkRectangle();
      rule.SetSize(Vector2(v.RowWidth(), 3.0));
      rule.SetMargin(inkMargin(0.0, 4.0, 0.0, 4.0));
      rule.SetHAlign(inkEHorizontalAlign.Left);
      rule.SetTintColor(TKTheme.Amber());
      rule.SetOpacity(0.8);
      rule.Reparent(c);
    }
  }
}

public abstract class TKTiles {

  public static func Stat(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let w = TKScale.F("stat.w", 355.0);
    let h = TKScale.F("stat.h", 176.0);
    let tile = v.GridCell(TKKind.Stat(), w, h);
    v.Panel(tile, w, h, 0.45);
    let parts = TKStr.Split(r.text, "|");
    v.Paint(TKInk.Rect(tile, 0.0, 0.0, w, 4.0), "accent");
    let name = v.Text(tile, parts[0], 22, n"Semi-Bold", "text", 0.0);
    name.SetMargin(inkMargin(18.0, 16.0, 0.0, 0.0));
    v.Hoverable(name, r.tip);
    let red: Bool;
    let green: Bool;
    let value = v.Text(tile, TKTheme.Unmark(ArraySize(parts) > 1 ? parts[1] : "", red, green), 50, n"Semi-Bold", "value", 0.0);
    value.SetMargin(inkMargin(18.0, 42.0, 0.0, 0.0));
    v.Mark(value, red, green);
    if ArraySize(parts) > 2 && StrLen(parts[2]) > 0 {
      let sub = v.Marked(tile, parts[2], 22, n"Medium", 0.0, w - 36.0);
      sub.SetMargin(inkMargin(18.0, 108.0, 0.0, 0.0));
    }
    if r.fraction >= 0.0 {
      let bed = TKInk.Rect(tile, 18.0, h - 24.0, w - 36.0, 8.0);
      bed.SetOpacity(0.5);
      v.Paint(bed, "rule");
      let fill = TKInk.Rect(tile, 18.0, h - 24.0, MaxF(3.0, (w - 36.0) * ClampF(r.fraction, 0.0, 1.0)), 8.0);
      v.Paint(fill, "value");
      v.Mark(fill, red, green);
      v.Segments(tile, 18.0, h - 24.0, w - 36.0, 8.0);
    }
  }

  public static func Gauge(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let w = TKScale.F("gauge.w", 355.0);
    let h = TKScale.F("gauge.h", 270.0);
    let tile = v.GridCell(TKKind.Gauge(), w, h);
    v.Panel(tile, w, h, 0.45);
    let parts = TKStr.Split(r.text, "|");
    v.Paint(TKInk.Rect(tile, 0.0, 0.0, w, 4.0), "accent");
    let name = v.Text(tile, parts[0], 22, n"Semi-Bold", "text", 0.0);
    name.SetMargin(inkMargin(18.0, 14.0, 0.0, 0.0));
    v.Hoverable(name, r.tip);

    let cx = w / 2.0;
    let cy = 168.0;
    let radius = 104.0;
    let n = 19;
    let f = ClampF(r.fraction, 0.0, 1.0);
    let k = 0;
    while k < n {
      let t = Cast<Float>(k) / Cast<Float>(n - 1);
      let angle = Deg2Rad(180.0 - 180.0 * t);
      let lit = t <= f + 0.001;
      let long = k % 3 == 0;
      let len = long ? 20.0 : 13.0;
      let a = Vector2(cx + CosF(angle) * radius, cy - SinF(angle) * radius);
      let b = Vector2(cx + CosF(angle) * (radius - len), cy - SinF(angle) * (radius - len));
      let color = StrLen(r.color) > 0 ? TKTheme.Gold() : (t < 0.34 ? TKTheme.Loss() : (t < 0.67 ? TKTheme.Amber() : TKTheme.Gain()));
      TKInk.Seg(tile, a, b, long ? 5.0 : 4.0, lit ? color : new HDRColor(0.35, 0.37, 0.4, 1.0), lit ? 1.0 : 0.45);
      k += 1;
    }

    let na = Deg2Rad(180.0 - 180.0 * f);
    let dir = Vector2(CosF(na), -SinF(na));
    let reach = radius - 24.0;
    let lit = StrLen(r.color) > 0 ? TKTheme.Gold() : (f < 0.34 ? TKTheme.Loss() : (f < 0.67 ? TKTheme.Amber() : TKTheme.Gain()));
    let white = new HDRColor(0.94, 0.95, 0.97, 1.0);
    let c = Vector2(cx, cy);
    TKInk.Seg(tile, c, TKTiles.Along(c, dir, reach + 4.0), 16.0, lit, 0.16);
    TKInk.Seg(tile, TKTiles.Along(c, dir, -22.0), c, 9.0, white, 0.85);
    TKInk.Seg(tile, c, TKTiles.Along(c, dir, reach * 0.42), 8.0, white, 1.0);
    TKInk.Seg(tile, TKTiles.Along(c, dir, reach * 0.38), TKTiles.Along(c, dir, reach * 0.78), 5.0, white, 1.0);
    TKInk.Seg(tile, TKTiles.Along(c, dir, reach * 0.74), TKTiles.Along(c, dir, reach), 3.0, lit, 1.0);
    let hub = TKInk.Rect(tile, cx - 14.0, cy - 14.0, 28.0, 28.0);
    hub.SetRenderTransformPivot(Vector2(0.5, 0.5));
    hub.SetRotation(45.0);
    hub.SetTintColor(new HDRColor(0.06, 0.07, 0.09, 1.0));
    let ring = TKInk.Rect(tile, cx - 11.0, cy - 11.0, 22.0, 22.0);
    ring.SetRenderTransformPivot(Vector2(0.5, 0.5));
    ring.SetRotation(45.0);
    ring.SetTintColor(white);
    let core = TKInk.Rect(tile, cx - 6.0, cy - 6.0, 12.0, 12.0);
    core.SetRenderTransformPivot(Vector2(0.5, 0.5));
    core.SetRotation(45.0);
    core.SetTintColor(lit);

    let red: Bool;
    let green: Bool;
    let value = v.Text(tile, TKTheme.Unmark(ArraySize(parts) > 1 ? parts[1] : "", red, green), 34, n"Semi-Bold", "value", 0.0);
    value.SetAnchor(inkEAnchor.TopCenter);
    value.SetAnchorPoint(Vector2(0.5, 0.0));
    value.SetHorizontalAlignment(textHorizontalAlignment.Center);
    value.SetMargin(inkMargin(0.0, cy + 10.0, 0.0, 0.0));
    v.Mark(value, red, green);
    v.Tone(value, r.color);
    if ArraySize(parts) > 2 && StrLen(parts[2]) > 0 {
      let sub = v.Marked(tile, parts[2], 20, n"Medium", 0.0, w - 36.0);
      sub.SetAnchor(inkEAnchor.TopCenter);
      sub.SetAnchorPoint(Vector2(0.5, 0.0));
      sub.SetHorizontalAlignment(textHorizontalAlignment.Center);
      sub.SetMargin(inkMargin(0.0, h - 34.0, 0.0, 0.0));
    }
  }

  private static func Along(c: Vector2, dir: Vector2, d: Float) -> Vector2 = Vector2(c.X + dir.X * d, c.Y + dir.Y * d)

  public static func Tile(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let w = TKScale.F("tile.w", 350.0);
    let h = TKScale.F("tile.h", 236.0);
    if StrContains(r.extra, ":") {
      w = StringToFloat(StrBeforeFirst(r.extra, ":"), w);
      h = StringToFloat(StrAfterFirst(r.extra, ":"), h);
    }
    let tile = v.GridCell(TKKind.Tile(), w, h);
    if !r.on {
      tile.SetOpacity(0.6);
    }
    v.Panel(tile, w, h, 0.45);
    let color = r.color;
    if StrBeginsWith(color, "*") {
      color = StrMid(color, 1, StrLen(color) - 1);
      v.TonedFrame(tile, w, h, 4.0, color);
    }
    let parts = TKStr.Split(r.text, "|");
    let bar = TKInk.Rect(tile, 0.0, 0.0, w, 6.0);
    v.Paint(bar, "value");
    v.Tone(bar, color);
    let name = v.Text(tile, parts[0], 26, n"Semi-Bold", "value", 0.0);
    name.SetMargin(inkMargin(18.0, 18.0, 0.0, 0.0));
    v.Tone(name, color);
    v.Hoverable(name, r.tip);
    let red: Bool;
    let green: Bool;
    let value = v.Text(tile, TKTheme.Unmark(ArraySize(parts) > 1 ? parts[1] : "", red, green), 34, n"Semi-Bold", "value", 0.0);
    value.SetMargin(inkMargin(18.0, 54.0, 0.0, 0.0));
    v.Mark(value, red, green);
    if ArraySize(parts) > 2 && StrLen(parts[2]) > 0 {
      let sub = v.Marked(tile, parts[2], 22, n"Medium", 0.0, w - 36.0);
      sub.SetMargin(inkMargin(18.0, 100.0, 0.0, 0.0));
    }
    if StrLen(r.label) > 0 {
      let root = v.ActButton(tile, i, 0, r.label, true, w - 36.0, 54.0, 24).GetRootWidget();
      root.SetAnchor(inkEAnchor.BottomLeft);
      root.SetAnchorPoint(Vector2(0.0, 1.0));
      root.SetMargin(inkMargin(18.0, 0.0, 0.0, 16.0));
    }
  }

  public static func Ticker(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let w = TKScale.F("tick.w", 355.0);
    let h = TKScale.F("tick.h", 250.0);
    let tile = v.GridCell(TKKind.Ticker(), w, h);
    v.Panel(tile, w, h, 0.45);
    let parts = TKStr.Split(r.text, "|");
    v.Paint(TKInk.Rect(tile, 0.0, 0.0, w, 4.0), "accent");
    let name = v.Text(tile, parts[0], 24, n"Semi-Bold", "text", 0.0);
    name.SetMargin(inkMargin(18.0, 16.0, 0.0, 0.0));
    let value = v.Text(tile, ArraySize(parts) > 1 ? parts[1] : "", 52, n"Semi-Bold", "value", 0.0);
    value.SetMargin(inkMargin(18.0, 44.0, 0.0, 0.0));
    let red: Bool;
    let green: Bool;
    let change = v.Text(tile, TKTheme.Unmark(ArraySize(parts) > 2 ? parts[2] : "", red, green), 26, n"Semi-Bold", "text", 0.0);
    v.Mark(change, red, green);
    change.SetAnchor(inkEAnchor.TopRight);
    change.SetAnchorPoint(Vector2(1.0, 0.0));
    change.SetHorizontalAlignment(textHorizontalAlignment.Right);
    change.SetMargin(inkMargin(0.0, 68.0, 18.0, 0.0));
    TKTiles.Spark(v, tile, 18.0, 122.0, w - 36.0, 66.0, r.value, 1.0);
    if ArraySize(parts) > 3 && StrLen(parts[3]) > 0 {
      let note = v.Marked(tile, parts[3], 20, n"Medium", 0.0, w - 36.0);
      note.SetMargin(inkMargin(18.0, h - 40.0, 0.0, 0.0));
    }
  }

  public static func Spark(v: ref<TKView>, parent: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, values: String, base: Float) -> Void {
    let vals: array<Float>;
    for s in TKStr.Split(values, ",") {
      if StrLen(s) > 0 {
        ArrayPush(vals, StringToFloat(s, 0.0));
      }
    }
    let n = ArraySize(vals);
    if n < 2 {
      return;
    }
    let lo = vals[0];
    let hi = vals[0];
    for val in vals {
      lo = MinF(lo, val);
      hi = MaxF(hi, val);
    }
    let pad = MaxF((hi - lo) * 0.18, 0.03);
    lo -= pad;
    hi += pad;
    let color = vals[n - 1] >= vals[0] ? TKTheme.Gain() : TKTheme.Loss();
    if base > lo && base < hi {
      let mark = TKInk.Rect(parent, x, y + h - (base - lo) / (hi - lo) * h - 1.0, w, 2.0);
      mark.SetOpacity(0.35);
      v.Paint(mark, "text");
    }
    let pts: array<Vector2>;
    let k = 0;
    while k < n {
      ArrayPush(pts, Vector2(x + w * Cast<Float>(k) / Cast<Float>(n - 1), y + h - (vals[k] - lo) / (hi - lo) * h));
      k += 1;
    }
    k = 0;
    while k < n - 1 {
      TKInk.Seg(parent, pts[k], pts[k + 1], 3.0, color, 1.0);
      k += 1;
    }
    let dot = TKInk.Rect(parent, pts[n - 1].X - 6.0, pts[n - 1].Y - 6.0, 12.0, 12.0);
    dot.SetRenderTransformPivot(Vector2(0.5, 0.5));
    dot.SetRotation(45.0);
    dot.SetTintColor(color);
  }

  public static func Card(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let w = TKScale.F("card.w", 530.0);
    let h = TKScale.F("card.h", 400.0);
    if StrContains(r.extra, ":") {
      w = StringToFloat(StrBeforeFirst(r.extra, ":"), w);
      h = StringToFloat(StrAfterFirst(r.extra, ":"), h);
    }
    let card = v.GridCell(TKKind.Card(), w, h);
    if !r.on {
      card.SetOpacity(0.7);
    }
    v.Panel(card, w, h, 0.45);

    let color = r.color;
    if StrBeginsWith(color, "*") {
      color = StrMid(color, 1, StrLen(color) - 1);
      card.SetOpacity(1.0);
      v.TonedFrame(card, w, h, 5.0, color);
    }
    let parts = TKStr.Split(r.text, "|");

    let strip = TKInk.Rect(card, 0.0, 0.0, w, 46.0);
    strip.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    strip.SetOpacity(0.7);
    let band = TKInk.Rect(card, 0.0, 0.0, w, 6.0);
    v.Paint(band, "value");
    v.Tone(band, color);
    let tag = v.Text(card, parts[0], 24, n"Semi-Bold", "value", 0.0);
    tag.SetMargin(inkMargin(20.0, 11.0, 0.0, 0.0));
    v.Tone(tag, color);
    v.Hoverable(tag, r.tip);

    let tw = w - 40.0;
    let body: ref<inkVerticalPanel> = new inkVerticalPanel();
    body.SetMargin(inkMargin(20.0, 56.0, 0.0, 0.0));
    body.Reparent(card);
    v.Wrap(v.Text(body, ArraySize(parts) > 1 ? parts[1] : "", 30, n"Semi-Bold", "value", 0.0), tw);
    if ArraySize(parts) > 2 && StrLen(parts[2]) > 0 {
      v.Wrap(v.Text(body, parts[2], 22, n"Regular", "text", 2.0), tw);
    }
    let money = ArraySize(parts) > 3 ? parts[3] : "";
    let price = v.Marked(body, money, 40, n"Semi-Bold", 8.0, tw);
    if !StrBeginsWith(money, "!") && !StrBeginsWith(money, "*") && !StrBeginsWith(money, "+") {
      v.Fix(price, TKTheme.Gold());
    }
    for d in TKStr.Split(r.value, "|") {
      if StrLen(d) > 0 {
        v.Marked(body, d, 24, n"Regular", 4.0, tw);
      }
    }

    let n = ArraySize(r.labels);
    if n > 0 && StrLen(r.label) > 0 {
      let bar: ref<inkHorizontalPanel> = new inkHorizontalPanel();
      bar.SetAnchor(inkEAnchor.BottomLeft);
      bar.SetAnchorPoint(Vector2(0.0, 1.0));
      bar.SetMargin(inkMargin(20.0, 0.0, 0.0, 16.0));
      bar.Reparent(card);
      let bw = (tw - 14.0 * Cast<Float>(n - 1)) / Cast<Float>(n);
      let k = 0;
      while k < n {
        let b = v.ActButton(bar, i, k, r.labels[k], true, bw, 54.0, 24);
        b.GetRootWidget().SetMargin(inkMargin(k > 0 ? 14.0 : 0.0, 0.0, 0.0, 0.0));
        k += 1;
      }
    }
  }
}

public abstract class TKCards {
  private static func Size(r: ref<TKRow>, w: script_ref<Float>, h: script_ref<Float>) -> Void {
    if StrContains(r.extra, ":") {
      Deref(w) = StringToFloat(StrBeforeFirst(r.extra, ":"), Deref(w));
      Deref(h) = StringToFloat(StrAfterFirst(r.extra, ":"), Deref(h));
    }
  }

  public static func Brackets(v: ref<TKView>, box: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, len: Float, t: Float, color: String) -> Void {
    let marks = [
      Vector4(x, y, len, t), Vector4(x, y, t, len),
      Vector4(x + w - len, y, len, t), Vector4(x + w - t, y, t, len),
      Vector4(x, y + h - t, len, t), Vector4(x, y + h - len, t, len),
      Vector4(x + w - len, y + h - t, len, t), Vector4(x + w - t, y + h - len, t, len)
    ];
    for m in marks {
      let r = TKInk.Rect(box, m.X, m.Y, m.Z, m.W);
      v.Paint(r, "value");
      v.Tone(r, color);
    }
  }

  public static func Stamp(v: ref<TKView>, parent: ref<inkCanvas>, text: String, color: String, right: Float, top: Float, size: Int32) -> Void {
    if StrLen(text) == 0 {
      return;
    }
    let w = Cast<Float>(StrLen(text)) * 0.62 * Cast<Float>(size) + 32.0;
    let h = Cast<Float>(size) + 16.0;
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(w, h));
    box.SetAnchor(inkEAnchor.TopRight);
    box.SetAnchorPoint(Vector2(1.0, 0.0));
    box.SetMargin(inkMargin(0.0, top, right, 0.0));
    box.Reparent(parent);
    let fill = TKInk.Rect(box, 0.0, 0.0, w, h);
    fill.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    fill.SetOpacity(0.75);
    v.TonedFrame(box, w, h, 2.0, color);
    let t = v.Text(box, text, size, n"Semi-Bold", "value", 0.0);
    t.SetAnchor(inkEAnchor.Centered);
    t.SetAnchorPoint(Vector2(0.5, 0.5));
    t.SetHorizontalAlignment(textHorizontalAlignment.Center);
    v.Tone(t, color);
  }

  public static func Portrait(v: ref<TKView>, box: ref<inkCanvas>, w: Float, h: Float, female: Bool, atlas: String, part: String, color: String, opt faceAtlas: String, opt facePart: String) -> Void {
    if StrLen(atlas) > 0 && StrLen(part) > 0 {
      let size = MinF(w, h) * 0.86;
      let img: ref<inkImage> = new inkImage();
      img.SetAtlasResource(ResRef.FromString(atlas));
      img.SetTexturePart(StringToName(part));
      img.SetAnchor(inkEAnchor.Centered);
      img.SetAnchorPoint(Vector2(0.5, 0.5));
      img.SetSize(Vector2(size, size));
      img.SetOpacity(0.22);
      img.Reparent(box);
      v.Paint(img, "value");
      v.Tone(img, color);
    }

    if StrLen(faceAtlas) > 0 && StrLen(facePart) > 0 {
      TKCards.FaceImage(v, box, w, h, faceAtlas, facePart, color);
      TKCards.NoImage(v, box, w, h);
      return;
    }

    let cx = w / 2.0;
    let headY = h * 0.36;
    let rx = w * (female ? 0.175 : 0.19);
    let ry = h * (female ? 0.19 : 0.2);
    let neck = h * 0.58;
    let shoulders = h * 0.66;
    let step = 3.0;

    let pass = 0;
    while pass < 2 {
      let grow = pass == 0 ? 3.0 : 0.0;
      let y = headY - ry - grow;
      while y < h {
        let half = 0.0;
        let dy = (y - headY) / (ry + grow);
        if AbsF(dy) <= 1.0 {
          half = (rx + grow) * SqrtF(1.0 - dy * dy);
        }
        if y >= headY + ry * 0.8 && y < shoulders {
          half = MaxF(half, w * (female ? 0.08 : 0.09) + grow);
        }
        if y >= shoulders - 6.0 {
          let t = ClampF((y - shoulders + 6.0) / (h - shoulders), 0.0, 1.0);
          let span = female ? 0.37 : 0.42;
          half = MaxF(half, (w * (0.2 + (span - 0.2) * SqrtF(t))) + grow);
        }
        if half > 0.5 {
          let slice = TKInk.Rect(box, cx - half, y, half * 2.0, step + 0.5);
          if pass == 0 {
            v.Paint(slice, "value");
            v.Tone(slice, color);
            slice.SetOpacity(0.35);
          } else {
            slice.SetTintColor(new HDRColor(0.07, 0.08, 0.1, 1.0));
          }
        }
        y += step;
      }
      pass += 1;
    }
    TKCards.NoImage(v, box, w, h);
  }

  private static func FaceImage(v: ref<TKView>, box: ref<inkCanvas>, w: Float, h: Float, atlas: String, part: String, color: String) -> Void {
    let rim: ref<inkImage> = new inkImage();
    rim.SetAtlasResource(ResRef.FromString(atlas));
    rim.SetTexturePart(StringToName(part));
    rim.SetSize(Vector2(w * 1.04, h * 1.04));
    rim.SetMargin(inkMargin(-w * 0.02, -h * 0.02 + 2.0, 0.0, 0.0));
    rim.SetOpacity(0.45);
    rim.Reparent(box);
    v.Paint(rim, "value");
    v.Tone(rim, color);
    let face: ref<inkImage> = new inkImage();
    face.SetAtlasResource(ResRef.FromString(atlas));
    face.SetTexturePart(StringToName(part));
    face.SetSize(Vector2(w, h));
    face.SetTintColor(new HDRColor(0.05, 0.06, 0.07, 1.0));
    face.Reparent(box);
  }

  public static func Wireframe(v: ref<TKView>, box: ref<inkCanvas>, w: Float, h: Float, atlas: String, part: String, color: String) -> Void {
    if StrLen(atlas) == 0 || StrLen(part) == 0 {
      return;
    }
    let size = MinF(w, h);
    let pass = 0;
    while pass < 2 {
      let img: ref<inkImage> = new inkImage();
      img.SetAtlasResource(ResRef.FromString(atlas));
      img.SetTexturePart(StringToName(part));
      img.SetAnchor(inkEAnchor.Centered);
      img.SetAnchorPoint(Vector2(0.5, 0.5));
      img.SetSize(pass == 0 ? Vector2(size * 1.03, size * 1.03) : Vector2(size, size));
      img.SetOpacity(pass == 0 ? 0.3 : 1.0);
      img.Reparent(box);
      v.Paint(img, "value");
      v.Tone(img, color);
      pass += 1;
    }
  }

  private static func NoImage(v: ref<TKView>, box: ref<inkCanvas>, w: Float, h: Float) -> Void {
    let band = TKInk.Rect(box, 0.0, h - 30.0, w, 30.0);
    band.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    band.SetOpacity(0.8);
    let t = v.Text(box, "NO IMAGE", 20, n"Semi-Bold", "text", 0.0);
    t.SetAnchor(inkEAnchor.BottomCenter);
    t.SetAnchorPoint(Vector2(0.5, 1.0));
    t.SetHorizontalAlignment(textHorizontalAlignment.Center);
    t.SetMargin(inkMargin(0.0, 0.0, 0.0, 4.0));
    t.SetOpacity(0.8);
  }

  private static func Initials(name: String) -> String {
    let clean = StrReplaceAll(name, "\"", "");
    let out = StrLeft(clean, 1);
    let at = StrFindFirst(clean, " ");
    if at > 0 && at + 1 < StrLen(clean) {
      out += StrMid(clean, at + 1, 1);
    }
    return out;
  }

  public static func File(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let w = TKScale.F("file.w", 520.0);
    let h = TKScale.F("file.h", 660.0);
    TKCards.Size(r, w, h);
    let card = v.GridCell(TKKind.File(), w, h);
    if !r.on {
      card.SetOpacity(0.6);
    }
    let color = r.color;
    let framed = StrBeginsWith(color, "*");
    if framed {
      color = StrMid(color, 1, StrLen(color) - 1);
    }
    if StrLen(color) == 0 {
      color = "blue";
    }
    v.Panel(card, w, h, 0.6);
    if framed {
      v.TonedFrame(card, w, h, 4.0, color);
    }
    let head = TKStr.Split(r.text, "|");
    let name = ArraySize(head) > 1 ? head[1] : "";

    let band = TKInk.Rect(card, 0.0, 0.0, w, 56.0);
    band.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    band.SetOpacity(0.7);
    let spine = TKInk.Rect(card, 0.0, 0.0, 6.0, h);
    v.Paint(spine, "value");
    v.Tone(spine, color);
    let number = v.Text(card, head[0], 24, n"Semi-Bold", "text", 0.0);
    number.SetMargin(inkMargin(24.0, 14.0, 0.0, 0.0));
    let bx = 24.0 + Cast<Float>(StrLen(head[0])) * 0.6 * 24.0 + 16.0;
    let k = 0;
    let seed = StrLen(name) + 3;
    let stampText = ArraySize(head) > 3 ? head[3] : "";
    let stop = w - 16.0 - (StrLen(stampText) > 0 ? Cast<Float>(StrLen(stampText)) * 0.62 * 24.0 + 32.0 : 0.0) - 24.0;
    while k < 16 && bx < stop - 8.0 {
      let bw = Cast<Float>((k * seed + k / 2) % 3 + 1) * 2.0;
      let bar = TKInk.Rect(card, bx, 16.0, bw, 24.0);
      v.Paint(bar, "text");
      bar.SetOpacity(0.55);
      bx += bw + 3.0;
      k += 1;
    }
    TKCards.Stamp(v, card, ArraySize(head) > 3 ? head[3] : "", color, 16.0, 10.0, 24);

    let px = 24.0;
    let py = 72.0;
    let pw = 132.0;
    let ph = 152.0;
    let shot = TKInk.Rect(card, px, py, pw, ph);
    shot.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    shot.SetOpacity(0.8);
    let face: ref<inkCanvas> = new inkCanvas();
    face.SetSize(Vector2(pw, ph));
    face.SetMargin(inkMargin(px, py, 0.0, 0.0));
    face.Reparent(card);
    let kind = TKStr.Part(r.image, "|", 0);
    if Equals(kind, "m") || Equals(kind, "f") {
      TKCards.Portrait(v, face, pw, ph, Equals(kind, "f"), TKStr.Part(r.image, "|", 1), TKStr.Part(r.image, "|", 2), color, TKStr.Part(r.image, "|", 3), TKStr.Part(r.image, "|", 4));
    } else if Equals(kind, "w") {
      TKCards.Wireframe(v, face, pw, ph, TKStr.Part(r.image, "|", 1), TKStr.Part(r.image, "|", 2), color);
    } else {
      let ini = v.Text(face, TKCards.Initials(name), 64, n"Semi-Bold", "value", 0.0);
      ini.SetAnchor(inkEAnchor.Centered);
      ini.SetAnchorPoint(Vector2(0.5, 0.5));
      ini.SetHorizontalAlignment(textHorizontalAlignment.Center);
      v.Tone(ini, color);
    }
    let s = 1;
    while s < 12 {
      let scan = TKInk.Rect(card, px + 4.0, py + Cast<Float>(s) * ph / 12.0, pw - 8.0, 2.0);
      scan.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
      scan.SetOpacity(0.35);
      s += 1;
    }
    TKCards.Brackets(v, card, px, py, pw, ph, 22.0, 3.0, color);

    let nx = px + pw + 20.0;
    let nw = w - nx - 20.0;
    let who: ref<inkVerticalPanel> = new inkVerticalPanel();
    who.SetMargin(inkMargin(nx, py - 4.0, 0.0, 0.0));
    who.Reparent(card);
    let title = v.Wrap(v.Text(who, name, 34, n"Semi-Bold", "value", 0.0), nw);
    v.Hoverable(title, r.tip);
    if ArraySize(head) > 2 && StrLen(head[2]) > 0 {
      v.Marked(who, head[2], 24, n"Medium", 6.0, nw);
    }

    let parts = TKStr.Split(r.value, "\n");
    let tw = w - 48.0;
    let body: ref<inkVerticalPanel> = new inkVerticalPanel();
    body.SetMargin(inkMargin(24.0, py + ph + 14.0, 0.0, 0.0));
    body.Reparent(card);
    if StrLen(parts[0]) > 0 {
      for stat in TKStr.Split(parts[0], "|") {
        let n = Min(10, StringToInt(StrAfterFirst(stat, ":"), 0));
        let line = TKInk.Strip(body, 4.0);
        let lbox: ref<inkCanvas> = new inkCanvas();
        lbox.SetSize(Vector2(78.0, 30.0));
        lbox.Reparent(line);
        v.Text(lbox, StrBeforeFirst(stat + ":", ":"), 24, n"Semi-Bold", "text", 0.0);
        let segs: ref<inkCanvas> = new inkCanvas();
        let sw = MinF(26.0, (tw - 78.0 - 60.0) / 10.0);
        segs.SetSize(Vector2(sw * 10.0, 30.0));
        segs.SetMargin(inkMargin(8.0, 0.0, 12.0, 0.0));
        segs.Reparent(line);
        let q = 0;
        while q < 10 {
          let seg = TKInk.Rect(segs, Cast<Float>(q) * sw, 8.0, sw - 5.0, 16.0);
          if q < n {
            v.Paint(seg, "value");
            v.Tone(seg, color);
          } else {
            v.Paint(seg, "rule");
            seg.SetOpacity(0.4);
          }
          q += 1;
        }
        v.Text(line, IntToString(n), 24, n"Semi-Bold", "value", 0.0);
      }
    }
    if ArraySize(parts) > 1 && StrLen(parts[1]) > 0 {
      let first = true;
      for d in TKStr.Split(parts[1], "|") {
        if StrLen(d) > 0 {
          v.Marked(body, d, 24, n"Medium", first ? 12.0 : 2.0, tw);
          first = false;
        }
      }
    }
    if ArraySize(parts) > 2 && StrLen(parts[2]) > 0 {
      let quote = v.Wrap(v.Text(body, "\"" + parts[2] + "\"", 24, n"Regular", "text", 12.0), tw);
      quote.SetLetterCase(textLetterCase.OriginalCase);
      quote.SetOpacity(0.75);
    }
    TKCards.ButtonBar(v, card, i, r, w);
  }

  public static func Posting(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let w = TKScale.F("post.w", 560.0);
    let h = TKScale.F("post.h", 430.0);
    TKCards.Size(r, w, h);
    let card = v.GridCell(TKKind.Posting(), w, h);
    if !r.on {
      card.SetOpacity(0.6);
    }
    let color = r.color;
    let framed = StrBeginsWith(color, "*");
    if framed {
      color = StrMid(color, 1, StrLen(color) - 1);
    }
    if StrLen(color) == 0 {
      color = "blue";
    }
    v.Panel(card, w, h, 0.6);
    if framed {
      v.TonedFrame(card, w, h, 4.0, color);
    }
    let head = TKStr.Split(r.text, "|");

    let band = TKInk.Rect(card, 0.0, 0.0, w, 46.0);
    band.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    band.SetOpacity(0.75);
    let edge = TKInk.Rect(card, 0.0, 46.0, w, 3.0);
    v.Paint(edge, "value");
    v.Tone(edge, color);
    let dot = TKInk.Rect(card, 18.0, 17.0, 12.0, 12.0);
    dot.SetRenderTransformPivot(Vector2(0.5, 0.5));
    dot.SetRotation(45.0);
    v.Paint(dot, "value");
    v.Tone(dot, color);
    let post = v.Text(card, head[0], 24, n"Semi-Bold", "value", 0.0);
    post.SetMargin(inkMargin(42.0, 9.0, 0.0, 0.0));
    v.Tone(post, color);
    let red: Bool;
    let green: Bool;
    let left = v.Text(card, TKTheme.Unmark(ArraySize(head) > 4 ? head[4] : "", red, green), 24, n"Semi-Bold", "text", 0.0);
    left.SetAnchor(inkEAnchor.TopRight);
    left.SetAnchorPoint(Vector2(1.0, 0.0));
    left.SetHorizontalAlignment(textHorizontalAlignment.Right);
    left.SetMargin(inkMargin(0.0, 9.0, 18.0, 0.0));
    v.Mark(left, red, green);

    let tw = w - 40.0;
    let body: ref<inkVerticalPanel> = new inkVerticalPanel();
    body.SetMargin(inkMargin(20.0, 60.0, 0.0, 0.0));
    body.Reparent(card);
    let title = v.Wrap(v.Text(body, ArraySize(head) > 1 ? head[1] : "", 32, n"Semi-Bold", "value", 0.0), tw);
    v.Hoverable(title, r.tip);
    if ArraySize(head) > 2 && StrLen(head[2]) > 0 {
      v.Marked(body, head[2], 24, n"Medium", 2.0, tw);
    }
    let parts = TKStr.Split(r.value, "\n");
    if StrLen(parts[0]) > 0 {
      let chips = TKInk.Strip(body, 10.0);
      let used = 0.0;
      for chip in TKStr.Split(parts[0], "|") {
        if StrLen(chip) > 0 {
          let cr: Bool;
          let cg: Bool;
          let label = TKTheme.Unmark(chip, cr, cg);
          let cw = Cast<Float>(StrLen(label)) * 0.6 * 22.0 + 24.0;

          if used > 0.0 && used + cw > tw {
            chips = TKInk.Strip(body, 8.0);
            used = 0.0;
          }
          used += cw + 10.0;
          let box: ref<inkCanvas> = new inkCanvas();
          box.SetSize(Vector2(cw, 34.0));
          box.SetMargin(inkMargin(0.0, 0.0, 10.0, 0.0));
          box.Reparent(chips);
          let tone = cr ? "red" : (cg ? "green" : color);
          let back = TKInk.Rect(box, 0.0, 0.0, cw, 34.0);
          back.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
          back.SetOpacity(0.6);
          v.TonedFrame(box, cw, 34.0, 2.0, tone);
          let t = v.Text(box, label, 22, n"Semi-Bold", "value", 0.0);
          t.SetAnchor(inkEAnchor.Centered);
          t.SetAnchorPoint(Vector2(0.5, 0.5));
          t.SetHorizontalAlignment(textHorizontalAlignment.Center);
          v.Tone(t, tone);
        }
      }
    }

    let row = TKInk.Strip(body, 12.0);
    let half = tw * 0.5;
    let payCol: ref<inkCanvas> = new inkCanvas();
    payCol.SetSize(Vector2(half, 80.0));
    payCol.Reparent(row);
    let pays = v.Text(payCol, "PAYS", 22, n"Semi-Bold", "text", 0.0);
    pays.SetOpacity(0.7);
    let money = ArraySize(head) > 3 ? head[3] : "";
    let pay = v.Marked(payCol, money, 42, n"Semi-Bold", 0.0, half - 10.0);
    pay.SetMargin(inkMargin(0.0, 26.0, 0.0, 0.0));
    if !StrBeginsWith(money, "!") && !StrBeginsWith(money, "*") {
      v.Fix(pay, TKTheme.Gold());
    }
    if r.fraction >= 0.0 {
      let odds: ref<inkCanvas> = new inkCanvas();
      odds.SetSize(Vector2(half, 80.0));
      odds.Reparent(row);
      let f = ClampF(r.fraction, 0.0, 1.0);
      let label = v.Text(odds, "ODDS", 22, n"Semi-Bold", "text", 0.0);
      label.SetOpacity(0.7);
      let tone = f < 0.4 ? TKTheme.Loss() : (f < 0.7 ? TKTheme.Amber() : TKTheme.Gain());
      let pct = v.Text(odds, IntToString(RoundF(f * 100.0)) + "%", 30, n"Semi-Bold", "value", 0.0);
      pct.SetAnchor(inkEAnchor.TopRight);
      pct.SetAnchorPoint(Vector2(1.0, 0.0));
      pct.SetHorizontalAlignment(textHorizontalAlignment.Right);
      v.Fix(pct, tone);

      let cells = 20;
      let cw = half / Cast<Float>(cells);
      let q = 0;
      while q < cells {
        let cell = TKInk.Rect(odds, Cast<Float>(q) * cw, 48.0, cw - 4.0, 22.0);
        if (Cast<Float>(q) + 0.5) / Cast<Float>(cells) <= f {
          cell.SetTintColor(tone);
        } else {
          v.Paint(cell, "rule");
          cell.SetOpacity(0.4);
        }
        q += 1;
      }
    }
    if ArraySize(parts) > 1 && StrLen(parts[1]) > 0 {
      let first = true;
      for d in TKStr.Split(parts[1], "|") {
        if StrLen(d) > 0 {
          v.Marked(body, d, 24, n"Regular", first ? 10.0 : 2.0, tw);
          first = false;
        }
      }
    }
    TKCards.ButtonBar(v, card, i, r, w);
  }

  public static func Run(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let w = TKScale.F("run.w", 560.0);
    let h = TKScale.F("run.h", 330.0);
    TKCards.Size(r, w, h);
    let card = v.GridCell(TKKind.Run(), w, h);
    if !r.on {
      card.SetOpacity(0.6);
    }
    let color = StrLen(r.color) > 0 ? r.color : "blue";
    v.Panel(card, w, h, 0.6);
    let head = TKStr.Split(r.text, "|");
    let band = TKInk.Rect(card, 0.0, 0.0, w, 50.0);
    band.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    band.SetOpacity(0.75);
    let spine = TKInk.Rect(card, 0.0, 0.0, 6.0, h);
    v.Paint(spine, "value");
    v.Tone(spine, color);
    let tag = v.Text(card, head[0], 24, n"Semi-Bold", "value", 0.0);
    tag.SetMargin(inkMargin(24.0, 11.0, 0.0, 0.0));
    v.Tone(tag, color);
    TKCards.Stamp(v, card, ArraySize(head) > 3 ? head[3] : "", color, 14.0, 7.0, 22);
    let tw = w - 48.0;
    let body: ref<inkVerticalPanel> = new inkVerticalPanel();
    body.SetMargin(inkMargin(24.0, 62.0, 0.0, 0.0));
    body.Reparent(card);
    let title = v.Wrap(v.Text(body, ArraySize(head) > 1 ? head[1] : "", 30, n"Semi-Bold", "value", 0.0), tw);
    v.Hoverable(title, r.tip);
    if ArraySize(head) > 2 && StrLen(head[2]) > 0 {
      v.Marked(body, head[2], 24, n"Medium", 2.0, tw);
    }
    let parts = TKStr.Split(r.value, "\n");
    if StrLen(parts[0]) > 0 {
      let first = true;
      for d in TKStr.Split(parts[0], "|") {
        if StrLen(d) > 0 {
          v.Marked(body, d, 24, n"Regular", first ? 8.0 : 2.0, tw);
          first = false;
        }
      }
    }

    let buttons = ArraySize(r.labels) > 0 && StrLen(r.label) > 0;
    let base = h - (buttons ? 88.0 : 22.0);
    let spec = ArraySize(parts) > 1 ? parts[1] : "";
    let start = StringToFloat(TKStr.Part(spec, "|", 0), 0.0);
    let end = StringToFloat(TKStr.Part(spec, "|", 1), 0.0);
    let pct = v.Text(card, "", 40, n"Semi-Bold", "value", 0.0);
    pct.SetMargin(inkMargin(24.0, base - 76.0, 0.0, 0.0));
    v.Tone(pct, color);
    let left = v.Text(card, "", 24, n"Semi-Bold", "text", 0.0);
    left.SetAnchor(inkEAnchor.TopRight);
    left.SetAnchorPoint(Vector2(1.0, 0.0));
    left.SetHorizontalAlignment(textHorizontalAlignment.Right);
    left.SetMargin(inkMargin(0.0, base - 60.0, 24.0, 0.0));
    let bw = w - 48.0;
    let bed = TKInk.Rect(card, 24.0, base - 18.0, bw, 18.0);
    v.Paint(bed, "rule");
    bed.SetOpacity(0.45);
    let fill = TKInk.Rect(card, 24.0, base - 18.0, 2.0, 18.0);
    v.Paint(fill, "value");
    v.Tone(fill, color);

    let cells = 24;
    let q = 1;
    while q < cells {
      let notch = TKInk.Rect(card, 24.0 + bw * Cast<Float>(q) / Cast<Float>(cells) - 2.0, base - 18.0, 4.0, 18.0);
      notch.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
      notch.SetOpacity(0.85);
      q += 1;
    }
    v.AddLive(i, fill, pct, bw, start, end, 1);
    v.AddLive(i, null, left, bw, start, end, 0);
    TKCards.ButtonBar(v, card, i, r, w);
  }

  private static func ButtonBar(v: ref<TKView>, card: ref<inkCanvas>, i: Int32, r: ref<TKRow>, w: Float) -> Void {
    let n = ArraySize(r.labels);
    if n == 0 || StrLen(r.label) == 0 {
      return;
    }
    let bar: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    bar.SetAnchor(inkEAnchor.BottomLeft);
    bar.SetAnchorPoint(Vector2(0.0, 1.0));
    bar.SetMargin(inkMargin(20.0, 0.0, 0.0, 16.0));
    bar.Reparent(card);
    let bw = (w - 40.0 - 12.0 * Cast<Float>(n - 1)) / Cast<Float>(n);
    let k = 0;
    while k < n {
      let b = v.ActButton(bar, i, k, r.labels[k], true, bw, 56.0, 24);
      b.GetRootWidget().SetMargin(inkMargin(k > 0 ? 12.0 : 0.0, 0.0, 0.0, 0.0));
      k += 1;
    }
  }
}

public abstract class TKControls {

  public static func Dropdown(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let bw = TKScale.F("dropdown.w", 420.0);
    let line = v.RowBox(v.RowWidth() - bw - 40.0, r.text, r.value, r.color, r.tip);
    let current = r.extra;
    let k = 0;
    while k < ArraySize(r.args) {
      if Equals(r.args[k], r.extra) && k < ArraySize(r.labels) {
        current = r.labels[k];
      }
      k += 1;
    }
    let b = v.ControlButton(line, current + "   v", "dd_" + IntToString(i), bw, TKScale.ButtonH(), TKScale.I("button.font", 30));
    v.PinRight(b.GetRootWidget());
  }

  public static func Check(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let size = TKScale.F("check.size", 48.0);
    let line = v.RowBox(v.RowWidth() - size - 60.0, r.text, r.value, r.color, r.tip);
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(size, size));
    box.Reparent(line);
    v.PinRight(box);
    box.SetMargin(inkMargin(0.0, 8.0, 12.0, 0.0));
    let back = TKInk.Rect(box, 0.0, 0.0, size, size);
    back.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    back.SetOpacity(0.6);
    v.Frame(box, size, size, 3.0, "value", 1.0);
    if r.on {
      let tick = TKInk.Rect(box, 10.0, 10.0, size - 20.0, size - 20.0);
      v.Paint(tick, "value");
    }
    v.Clickable(box, "ck_" + IntToString(i));
  }

  public static func Search(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let bw = TKScale.F("search.button", 240.0);
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(v.RowWidth(), 96.0));
    row.SetMargin(inkMargin(0.0, TKScale.F("row.gap", 10.0), 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(v.Content());
    v.Grew(106.0);
    let name = v.Text(row, r.text, TKScale.I("row.title", 32), n"Medium", "value", 0.0);
    name.SetMargin(inkMargin(0.0, 24.0, 0.0, 0.0));
    v.TextBox(row, r.value, r.extra, 440.0, v.RowWidth() - 460.0 - bw - 24.0);
    v.PinRight(v.ActButton(row, i, 0, r.labels[0], true, bw, TKScale.ButtonH(), TKScale.I("button.font", 30)).GetRootWidget());
  }

  public static func SortHead(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let size = Max(14, TKScale.I("table.font", 28) - 4);
    let w = v.RowWidth();
    let h = Cast<Float>(size) * 1.9;
    let c = v.Content();
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(w, h));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(c);
    v.Grew(h + 6.0);
    v.tableLine = 0;
    let spec = TKStr.Split(r.value, "|");
    let parts = TKStr.Split(r.text, "|");
    let sorted = RoundF(r.fraction);
    let x = 0.0;
    let k = 0;
    while k < ArraySize(spec) {
      let right = StrBeginsWith(spec[k], "R");
      let cw = w * StringToFloat(StrMid(spec[k], 1, StrLen(spec[k]) - 1), 0.0) / 100.0;
      let cell: ref<inkCanvas> = new inkCanvas();
      cell.SetSize(Vector2(MaxF(10.0, cw - 8.0), h));
      cell.SetMargin(inkMargin(x + 4.0, 0.0, 0.0, 0.0));
      cell.Reparent(row);
      if k == sorted {
        let lit = TKInk.Rect(cell, 0.0, 0.0, MaxF(10.0, cw - 8.0), h);
        v.Paint(lit, "rule");
        lit.SetOpacity(0.35);
      }
      let label = (k < ArraySize(parts) ? parts[k] : "") + (k == sorted ? (r.on ? "  v" : "  ^") : "");
      let t = v.Text(cell, label, size, n"Semi-Bold", k == sorted ? "value" : "text", 0.0);
      t.SetAnchor(right ? inkEAnchor.CenterRight : inkEAnchor.CenterLeft);
      t.SetAnchorPoint(Vector2(right ? 1.0 : 0.0, 0.5));
      t.SetMargin(inkMargin(right ? 0.0 : 8.0, 0.0, right ? 8.0 : 0.0, 0.0));
      if right {
        t.SetHorizontalAlignment(textHorizontalAlignment.Right);
      }
      v.Clickable(cell, "so_" + IntToString(i) + "_" + IntToString(k));
      x += cw;
      k += 1;
    }
    v.Rule(c, 0.0, 0.6);
  }

  public static func Pager(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let bw = TKScale.F("pager.w", 220.0);
    let bh = TKScale.F("pager.h", 56.0);
    let strip = TKInk.Strip(v.Content(), 12.0);
    let label = 360.0;
    strip.SetMargin(inkMargin(MaxF(0.0, (v.RowWidth() - bw * 2.0 - label) / 2.0), 12.0, 0.0, 0.0));
    v.ActButton(strip, i, 0, r.labels[0], true, bw, bh, 24);
    let mid: ref<inkCanvas> = new inkCanvas();
    mid.SetSize(Vector2(label, bh));
    mid.Reparent(strip);
    let t = v.Text(mid, r.text, TKScale.I("row.detail", 29), n"Semi-Bold", "text", 0.0);
    t.SetAnchor(inkEAnchor.Centered);
    t.SetAnchorPoint(Vector2(0.5, 0.5));
    v.ActButton(strip, i, 1, r.labels[1], true, bw, bh, 24);
    v.Grew(bh + 12.0);
  }

  public static func Live(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let c = v.Content();
    let top = TKInk.Strip(c, 10.0);
    let font = TKScale.I("meter.font", 30);
    v.Hoverable(v.Text(top, r.text, font, n"Medium", "text", 0.0), r.tip);
    let readout = v.Text(top, "", font, n"Semi-Bold", "value", 0.0);
    readout.SetMargin(inkMargin(24.0, 0.0, 0.0, 0.0));
    if StrLen(r.value) > 0 {
      let note = v.Text(top, r.value, TKScale.I("row.detail", 29), n"Regular", "text", 0.0);
      note.SetMargin(inkMargin(24.0, 0.0, 0.0, 0.0));
      note.SetOpacity(0.8);
    }
    let w = MinF(TKScale.F("meter.w", 900.0), v.RowWidth());
    let h = TKScale.F("meter.h", 10.0) + 4.0;
    let track: ref<inkCanvas> = new inkCanvas();
    track.SetSize(Vector2(w, h));
    track.SetMargin(inkMargin(0.0, 6.0, 0.0, 0.0));
    track.SetHAlign(inkEHorizontalAlign.Left);
    track.Reparent(c);
    let bed = TKInk.Rect(track, 0.0, 0.0, w, h);
    v.Paint(bed, "rule");
    bed.SetOpacity(0.5);
    let fill = TKInk.Rect(track, 0.0, 0.0, 2.0, h);
    v.Fix(fill, TKTheme.Gold());
    let spec = TKStr.Split(r.label, "|");
    v.AddLive(i, fill, readout, w, StringToFloat(spec[0], 0.0), StringToFloat(TKStr.Part(r.label, "|", 1), 0.0), StringToInt(TKStr.Part(r.label, "|", 2), 0));
    v.Grew(Cast<Float>(font) * 1.4 + h + 20.0);
  }

  public static func Choice(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let w = v.RowWidth();
    let small = TKScale.I("type.xs", 24) - 2;
    let font = TKScale.I("row.title", 32) - 2;
    let h = TKScale.F("choice.h", 78.0);
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(w, h));
    row.SetMargin(inkMargin(0.0, 6.0, 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(v.Content());
    v.Grew(h + 6.0);
    let back = TKInk.Rect(row, 0.0, 0.0, w, h);
    back.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    back.SetOpacity(r.on ? 0.75 : 0.4);
    let tone = StrLen(r.color) > 0 ? r.color : "blue";
    if r.on {
      v.TonedFrame(row, w, h, 3.0, tone);
    }
    let bar = TKInk.Rect(row, 0.0, 0.0, 6.0, h);
    v.Paint(bar, "value");
    v.Tone(bar, tone);
    let label = v.Text(row, r.value, small, n"Semi-Bold", "text", 0.0);
    label.SetMargin(inkMargin(24.0, 8.0, 0.0, 0.0));
    let red: Bool;
    let green: Bool;
    let value = v.Text(row, TKTheme.Unmark(r.text, red, green), font, n"Semi-Bold", "value", 0.0);
    value.SetMargin(inkMargin(24.0, 8.0 + Cast<Float>(small) * 1.3, 0.0, 0.0));
    v.Mark(value, red, green);
    v.Hoverable(label, r.tip);
    v.Clickable(row, "ch_" + IntToString(i));
  }

  public static func Message(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let mine = r.on;
    let width = MinF(TKScale.F("message.w", 1300.0), v.RowWidth() * 0.75);
    let font = TKScale.I("note", 26) + 2;
    let small = TKScale.I("type.xs", 24) - 2;
    let pad = 22.0;
    let textH = TKInk.Lines(r.text, font, width - pad * 2.0) * Cast<Float>(font) * 1.35;
    let h = textH + Cast<Float>(small) * 1.4 + pad * 2.0 + 6.0;
    let line: ref<inkCanvas> = new inkCanvas();
    line.SetSize(Vector2(v.RowWidth(), h));
    line.SetMargin(inkMargin(0.0, 12.0, 0.0, 0.0));
    line.SetHAlign(inkEHorizontalAlign.Left);
    line.Reparent(v.Content());
    v.Grew(h + 12.0);
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(width, h));
    if mine {
      box.SetAnchor(inkEAnchor.TopRight);
      box.SetAnchorPoint(Vector2(1.0, 0.0));
    }
    box.Reparent(line);
    let back = TKInk.Rect(box, 0.0, 0.0, width, h);
    back.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    back.SetOpacity(mine ? 0.45 : 0.65);
    let edge = TKInk.Rect(box, mine ? width - 5.0 : 0.0, 0.0, 5.0, h);
    v.Paint(edge, mine ? "value" : "accent");
    v.Tone(edge, r.color);
    let head = v.Text(box, r.value + (StrLen(r.label) > 0 ? "   " + r.label : ""), small, n"Semi-Bold", mine ? "value" : "accent", 0.0);
    head.SetMargin(inkMargin(pad, pad - 6.0, 0.0, 0.0));
    v.Tone(head, r.color);
    let t = v.Text(box, r.text, font, n"Regular", "text", 0.0);
    t.SetLetterCase(textLetterCase.OriginalCase);
    t.SetWrapping(true, width - pad * 2.0);
    t.SetMargin(inkMargin(pad, pad + Cast<Float>(small) * 1.4, 0.0, 0.0));
    t.SetVAlign(inkEVerticalAlign.Top);
  }
}

public abstract class TKConsole {

  public static func Key(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let red: Bool;
    let primary: Bool;
    let label = TKTheme.Unmark(r.text, red, primary);
    let off = red || !r.on;
    let w = TKScale.F("key.w", 330.0);
    let h = TKScale.F("key.h", StrLen(r.value) > 0 ? 104.0 : 84.0);
    let cell = v.GridCell(TKKind.Key(), w, h);
    v.Panel(cell, w, h, 0.6);
    if primary && !off {
      v.Frame(cell, w, h, 2.0, "accent", 1.0);
    }
    cell.SetOpacity(off ? 0.45 : 1.0);

    let shown = false;
    let owner = v.Owner();
    if IsDefined(owner) && StrLen(r.label) > 0 {
      let hint = owner.SpawnFromExternal(cell, r"base\\gameplay\\gui\\common\\buttons\\base_buttons.inkwidget", n"inputDisplayLabelFlex");
      let ctrl = IsDefined(hint) ? hint.GetController() as LabelInputDisplayController : null;
      if IsDefined(ctrl) {
        hint.SetAnchor(inkEAnchor.TopLeft);
        hint.SetMargin(inkMargin(16.0, 14.0, 0.0, 0.0));
        ctrl.SetInputActionLabel(StringToName(r.label), TKScale.T(label));
        shown = true;
      }
    }
    if !shown {
      let t = v.Text(cell, "[" + StrUpper(r.label) + "]  " + label, TKScale.I("key.font", 28), n"Semi-Bold", primary ? "accent" : "value", 0.0);
      t.SetMargin(inkMargin(18.0, 18.0, 0.0, 0.0));
    }
    if StrLen(r.value) > 0 {
      let why = v.Text(cell, r.value, TKScale.TypeXS() - 4, n"Medium", "text", 0.0);
      why.SetMargin(inkMargin(18.0, h - 34.0, 0.0, 0.0));
      if off {
        v.Fix(why, TKTheme.Loss());
      }
    }
    v.Hit(cell, r.action, r.arg, r.tip, off);
    v.AddKey(StringToName(r.label), r.action, r.arg, off);
  }

  public static func Bay(v: ref<TKView>, i: Int32, r: ref<TKRow>) -> Void {
    let w = v.RowWidth();
    let h = TKScale.F("bay.h", 150.0);
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(w, h));
    box.SetMargin(inkMargin(0.0, TKScale.F("row.gap", 10.0), 0.0, 0.0));
    box.SetHAlign(inkEHorizontalAlign.Left);
    box.Reparent(v.Content());
    v.Grew(h + TKScale.F("row.gap", 10.0));
    v.Panel(box, w, h, r.on ? 0.75 : 0.5);
    if r.on {

      v.Frame(box, w, h, 2.0, "accent", 1.0);
      v.Paint(TKInk.Rect(box, 0.0, 0.0, 6.0, h), "accent");
    }

    let t = h - 28.0;
    let frame: ref<inkCanvas> = new inkCanvas();
    frame.SetSize(Vector2(t, t));
    frame.SetMargin(inkMargin(18.0, 14.0, 0.0, 0.0));
    frame.Reparent(box);
    v.Frame(frame, t, t, 2.0, "rule", 0.8);
    let atlas = TKStr.Part(r.value, "|", 0);
    let part = TKStr.Part(r.value, "|", 1);
    if StrLen(atlas) > 0 && StrLen(part) > 0 {
      let img: ref<inkImage> = new inkImage();
      img.SetAtlasResource(ResRef.FromString(atlas));
      img.SetTexturePart(StringToName(part));
      img.SetAnchor(inkEAnchor.Centered);
      img.SetAnchorPoint(Vector2(0.5, 0.5));
      img.SetSize(Vector2(t - 16.0, t - 16.0));
      img.Reparent(frame);
      v.Paint(img, "value");
      v.Tone(img, r.color);
    }
    let x = t + 40.0;
    let parts = TKStr.Split(r.text, "|");
    let id = v.Text(box, ArraySize(parts) > 0 ? parts[0] : "", TKScale.TypeXS(), n"Medium", "text", 0.0);
    id.SetMargin(inkMargin(x, 14.0, 0.0, 0.0));
    let name = v.Text(box, ArraySize(parts) > 1 ? parts[1] : "", TKScale.I("bay.name", 36), n"Semi-Bold", "value", 0.0);
    name.SetMargin(inkMargin(x, 40.0, 0.0, 0.0));
    v.Hoverable(name, r.tip);
    if ArraySize(parts) > 2 && StrLen(parts[2]) > 0 {
      TKConsole.Stamp(v, box, parts[2], r.color, x, 86.0);
    }

    let bw = w - x - 24.0;
    let cells = 10;
    let lit = RoundF(ClampF(r.fraction, 0.0, 1.0) * Cast<Float>(cells));
    let cw = bw / Cast<Float>(cells);
    let k = 0;
    while k < cells {
      let c = TKInk.Rect(box, x + Cast<Float>(k) * cw, h - 22.0, cw - 3.0, 8.0);
      v.Paint(c, k < lit ? "value" : "rule");
      if k < lit {
        v.Tone(c, r.color);
      } else {
        c.SetOpacity(0.5);
      }
      k += 1;
    }
    if StrLen(r.action) > 0 {
      v.Hit(box, r.action, r.arg, "", false);
    }
  }

  public static func Stamp(v: ref<TKView>, parent: ref<inkCanvas>, text: String, color: String, x: Float, y: Float) -> Void {
    let size = TKScale.TypeXS() - 2;
    let sw = Cast<Float>(StrLen(text)) * Cast<Float>(size) * 0.58 + 24.0;
    let sh = Cast<Float>(size) + 12.0;
    let s: ref<inkCanvas> = new inkCanvas();
    s.SetSize(Vector2(sw, sh));
    s.SetMargin(inkMargin(x, y, 0.0, 0.0));
    s.Reparent(parent);
    v.TonedFrame(s, sw, sh, 2.0, color);
    let t = v.Text(s, text, size, n"Semi-Bold", "value", 0.0);
    t.SetAnchor(inkEAnchor.Centered);
    t.SetAnchorPoint(Vector2(0.5, 0.5));
    v.Tone(t, color);
  }

  public static func Leds(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let colors = TKStr.Split(r.label, "|");
    let blinks = TKStr.Split(r.action, "|");
    let size = TKScale.F("led.size", 22.0);
    let lightsW = Cast<Float>(ArraySize(colors)) * (size + 10.0);
    let line = v.RowBox(v.RowWidth() - lightsW - 20.0, r.text, r.value, "", r.tip);
    let strip: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    strip.Reparent(line);
    v.PinRight(strip);
    strip.SetMargin(inkMargin(0.0, 14.0, 0.0, 0.0));
    let k = 0;
    while k < ArraySize(colors) {
      let led: ref<inkRectangle> = new inkRectangle();
      led.SetSize(Vector2(size, size));
      led.SetMargin(inkMargin(k > 0 ? 10.0 : 0.0, 0.0, 0.0, 0.0));
      led.Reparent(strip);
      v.Paint(led, "rule");
      if NotEquals(colors[k], "off") && StrLen(colors[k]) > 0 {
        v.Tone(led, colors[k]);
      } else {
        led.SetOpacity(0.4);
      }
      if k < ArraySize(blinks) && Equals(blinks[k], "1") {
        TKConsole.Blink(led, 1.0);
      }
      k += 1;
    }
  }

  public static func Blink(w: ref<inkWidget>, period: Float) -> Void {
    let def: ref<inkAnimDef> = new inkAnimDef();
    TKPopup.Fade(def, 1.0, 0.2, period / 2.0, 0.0);
    let opts: inkAnimOptions;
    opts.loopType = inkanimLoopType.PingPong;
    opts.loopInfinite = true;
    w.PlayAnimationWithOptions(def, opts);
  }

  public static func Ring(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let w = TKScale.F("ring.w", 300.0);
    let h = TKScale.F("ring.h", 300.0);
    let tile = v.GridCell(TKKind.Ring(), w, h);
    v.Panel(tile, w, h, 0.45);
    let parts = TKStr.Split(r.text, "|");
    let name = v.Text(tile, parts[0], 22, n"Semi-Bold", "text", 0.0);
    name.SetMargin(inkMargin(18.0, 14.0, 0.0, 0.0));
    v.Hoverable(name, r.tip);
    let cx = w / 2.0;
    let cy = h / 2.0 + 14.0;
    let radius = MinF(w, h) * 0.34;
    let n = 40;
    let f = ClampF(r.fraction, 0.0, 1.0);
    let color = TKConsole.Shade(v, r.color);
    let dim = new HDRColor(0.3, 0.33, 0.36, 1.0);
    let k = 0;
    while k < n {
      let t = Cast<Float>(k) / Cast<Float>(n);
      let angle = Deg2Rad(90.0 - 360.0 * t);
      let a = Vector2(cx + CosF(angle) * radius, cy - SinF(angle) * radius);
      let b = Vector2(cx + CosF(angle) * (radius - 16.0), cy - SinF(angle) * (radius - 16.0));
      let on = t < f - 0.0001;
      TKInk.Seg(tile, a, b, 6.0, on ? color : dim, on ? 1.0 : 0.5);
      k += 1;
    }
    let red: Bool;
    let green: Bool;
    let value = v.Text(tile, TKTheme.Unmark(ArraySize(parts) > 1 ? parts[1] : "", red, green), 40, n"Semi-Bold", "value", 0.0);
    value.SetAnchor(inkEAnchor.TopCenter);
    value.SetAnchorPoint(Vector2(0.5, 0.5));
    value.SetHorizontalAlignment(textHorizontalAlignment.Center);
    value.SetMargin(inkMargin(0.0, cy, 0.0, 0.0));
    v.Mark(value, red, green);
    if ArraySize(parts) > 2 && StrLen(parts[2]) > 0 {
      let sub = v.Marked(tile, parts[2], 20, n"Medium", 0.0, w - 36.0);
      sub.SetAnchor(inkEAnchor.TopCenter);
      sub.SetAnchorPoint(Vector2(0.5, 0.0));
      sub.SetHorizontalAlignment(textHorizontalAlignment.Center);
      sub.SetMargin(inkMargin(0.0, h - 34.0, 0.0, 0.0));
    }
  }

  public static func Shade(v: ref<TKView>, color: String) -> HDRColor {
    switch color {
      case "green": return TKTheme.Gain();
      case "red": return TKTheme.Loss();
      case "amber": return TKTheme.Amber();
      case "yellow": return TKTheme.Gold();
      case "orange": return new HDRColor(1.0, 0.55, 0.15, 1.0);
      case "cyan": return new HDRColor(0.15, 0.86, 0.8, 1.0);
      case "grey": return new HDRColor(0.45, 0.45, 0.45, 1.0);
      case "white": return new HDRColor(0.92, 0.94, 0.96, 1.0);
      default: return TKTheme.Color(v.Theme(), "value");
    }
  }

  public static func Compare(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let bw = TKScale.F("compare.w", 560.0);
    let line = v.RowBox(v.RowWidth() - bw - 140.0, r.text, "", r.color, r.tip);
    let group: ref<inkCanvas> = new inkCanvas();
    group.SetSize(Vector2(bw + 120.0, 40.0));
    group.Reparent(line);
    v.PinRight(group);
    let bed = TKInk.Rect(group, 0.0, 14.0, bw, 12.0);
    bed.SetOpacity(0.5);
    v.Paint(bed, "rule");
    let fill = TKInk.Rect(group, 0.0, 14.0, MaxF(2.0, bw * ClampF(r.fraction, 0.0, 1.0)), 12.0);
    v.Paint(fill, "value");
    v.Tone(fill, r.color);
    let at = bw * ClampF(StringToFloat(r.label, 0.0), 0.0, 1.0);
    let tick = TKInk.Rect(group, at - 2.0, 4.0, 4.0, 32.0);
    v.Fix(tick, TKTheme.Amber());
    let value = v.Text(group, r.value, TKScale.I("row.detail", 29), n"Semi-Bold", "value", 0.0);
    value.SetMargin(inkMargin(bw + 20.0, 2.0, 0.0, 0.0));
  }

  public static func Feed(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let w = v.RowWidth();
    let size = TKScale.I("feed.font", 28);
    let h = Cast<Float>(size) + 20.0;
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetSize(Vector2(w, h));
    row.SetMargin(inkMargin(0.0, TKScale.F("row.gap", 10.0), 0.0, 0.0));
    row.SetHAlign(inkEHorizontalAlign.Left);
    row.Reparent(v.Content());
    v.Grew(h + TKScale.F("row.gap", 10.0));
    let lw = 0.0;
    if StrLen(r.value) > 0 {
      let label = v.Text(row, r.value, TKScale.TypeXS(), n"Semi-Bold", "text", 0.0);
      label.SetMargin(inkMargin(0.0, 12.0, 0.0, 0.0));
      lw = Cast<Float>(StrLen(r.value)) * Cast<Float>(TKScale.TypeXS()) * 0.6 + 24.0;
    }
    let clip: ref<inkScrollArea> = new inkScrollArea();
    clip.SetAnchor(inkEAnchor.TopLeft);
    clip.SetFitToContentDirection(inkFitToContentDirection.None);
    clip.SetConstrainContentPosition(false);
    clip.SetUseInternalMask(true);
    clip.SetSize(Vector2(w - lw, h));
    clip.SetMargin(inkMargin(lw, 0.0, 0.0, 0.0));
    clip.Reparent(row);
    let text = v.Text(clip, r.text, size, n"Medium", "value", 0.0);
    text.SetAnchor(inkEAnchor.TopLeft);
    text.SetMargin(inkMargin(0.0, 8.0, 0.0, 0.0));
    v.Tone(text, StrLen(r.color) > 0 ? r.color : "amber");
    let tw = Cast<Float>(StrLen(r.text)) * Cast<Float>(size) * 0.55;
    let def: ref<inkAnimDef> = new inkAnimDef();
    let move: ref<inkAnimTranslation> = new inkAnimTranslation();
    move.SetStartTranslation(Vector2(w - lw, 0.0));
    move.SetEndTranslation(Vector2(-tw, 0.0));
    move.SetDuration((w - lw + tw) / TKScale.F("feed.speed", 120.0));
    def.AddInterpolator(move);
    let opts: inkAnimOptions;
    opts.loopType = inkanimLoopType.Cycle;
    opts.loopInfinite = true;
    text.PlayAnimationWithOptions(def, opts);
  }

  public static func Wave(v: ref<TKView>, r: ref<TKRow>) -> Void {
    let gw = TKScale.F("wave.w", 360.0);
    let gh = TKScale.F("wave.h", 56.0);
    let line = v.RowBox(v.RowWidth() - gw - 20.0, r.text, r.value, "", r.tip);
    let g: ref<inkCanvas> = new inkCanvas();
    g.SetSize(Vector2(gw, gh));
    g.Reparent(line);
    v.PinRight(g);
    let color = TKConsole.Shade(v, StrLen(r.color) > 0 ? r.color : "cyan");
    let pts = StrSplit(r.label, ",");
    let n = ArraySize(pts);
    let k = 1;
    while k < n {
      let x0 = gw * Cast<Float>(k - 1) / Cast<Float>(Max(1, n - 1));
      let x1 = gw * Cast<Float>(k) / Cast<Float>(Max(1, n - 1));
      let y0 = gh - 4.0 - (gh - 8.0) * ClampF(StringToFloat(pts[k - 1], 0.0), 0.0, 1.0);
      let y1 = gh - 4.0 - (gh - 8.0) * ClampF(StringToFloat(pts[k], 0.0), 0.0, 1.0);
      TKInk.Seg(g, Vector2(x0, y0), Vector2(x1, y1), 3.0, color, 1.0);
      k += 1;
    }
    if r.on {

      let sweep = TKInk.Rect(g, 0.0, 0.0, 6.0, gh);
      sweep.SetTintColor(color);
      sweep.SetOpacity(0.5);
      let def: ref<inkAnimDef> = new inkAnimDef();
      let move: ref<inkAnimTranslation> = new inkAnimTranslation();
      move.SetStartTranslation(Vector2(0.0, 0.0));
      move.SetEndTranslation(Vector2(gw - 6.0, 0.0));
      move.SetDuration(TKScale.F("wave.secs", 1.6));
      def.AddInterpolator(move);
      let opts: inkAnimOptions;
      opts.loopType = inkanimLoopType.Cycle;
      opts.loopInfinite = true;
      sweep.PlayAnimationWithOptions(def, opts);
    }
  }
}

public class TKMapRegion extends IScriptable {
  public let id: String;
  public let name: String;
  public let color: HDRColor;
  public let tint: Bool;
  public let surround: Bool;
  public let rings: array<Float>;
  public let ringEnds: array<Int32>;
  public let label: Vector2;
  public let hasLabel: Bool;
  public let maskAtlas: String;
  public let maskPart: CName;
  public let maskRect: Vector4;

  public func AddRing(points: array<Float>) -> Void {
    for f in points {
      ArrayPush(this.rings, f);
    }
    ArrayPush(this.ringEnds, ArraySize(this.rings));
  }
  public func Label(x: Float, y: Float) -> Void {
    this.label = Vector2(x, y);
    this.hasLabel = true;
  }
  public func Mask(atlas: String, part: CName, west: Float, north: Float, width: Float, height: Float) -> Void {
    this.maskAtlas = atlas;
    this.maskPart = part;
    this.maskRect = Vector4(west, north, width, height);
  }
}

public class TKMapPin extends IScriptable {
  public let x: Float;
  public let y: Float;
  public let letter: String;
  public let label: String;
  public let color: HDRColor;
  public let link: String;
  public let group: String;
  public let square: Bool;
  public let faint: Bool;
  public let id: String;
  public let ring: Float;
  public let iconAtlas: String;
  public let iconPart: CName;
  public let follow: String;

  public func Ring(metres: Float) -> ref<TKMapPin> { this.ring = metres; return this; }
  public func Icon(atlas: String, part: String) -> ref<TKMapPin> { this.iconAtlas = atlas; this.iconPart = StringToName(part); return this; }
  public func Named(id: String) -> ref<TKMapPin> { this.id = id; return this; }

  public func Follow(key: String) -> ref<TKMapPin> { this.follow = key; return this; }
}

public class TKMapLayer extends IScriptable {
  public let minZoom: Float;
  public let grid: Int32;
  public let path: String;
  public let part: CName;
  public let exists: String;
  public let head: String;
  public let middle: String;
  public let tail: String;

  public func Split() -> Void {
    this.head = StrBeforeFirst(this.path, "%C");
    let rest = StrAfterFirst(this.path, "%C");
    this.middle = StrBeforeFirst(rest, "%R");
    this.tail = StrAfterFirst(rest, "%R");
  }

  public func Tile(c: Int32, r: Int32) -> String = this.head + IntToString(c) + this.middle + IntToString(r) + this.tail
}

public class TKMapToggle extends IScriptable {
  public let bit: Int32;
  public let offLabel: String;
  public let onLabel: String;
  public let target: String;
}

public class TKMapLegendItem extends IScriptable {
  public let label: String;
  public let color: HDRColor;
  public let square: Bool;
  public let faint: Bool;
}

public class TKMapSpec extends IScriptable {

  public let west: Float;
  public let north: Float;
  public let span: Float;
  public let zooms: array<Float>;
  public let base: String;
  public let basePart: CName;
  public let layers: array<ref<TKMapLayer>>;
  public let regions: array<ref<TKMapRegion>>;
  public let pins: array<ref<TKMapPin>>;
  public let toggles: array<ref<TKMapToggle>>;
  public let legend: array<ref<TKMapLegendItem>>;
  public let legendTitle: String;
  public let legendHint: String;

  public let zoom: Float;
  public let mode: Int32;
  public let centreX: Float;
  public let centreY: Float;
  public let selected: String;
  public let link: String;

  public let showPlayer: Bool;
  public let playerLabel: String;
  public let findLabel: String;
  public let tintOpacity: Float;
  public let selectedTint: Float;
  public let buttonW: Float;
  public let buttonH: Float;
  public let buttonFont: Int32;
  public let clickAction: String;

  public static func Make(west: Float, north: Float, span: Float) -> ref<TKMapSpec> {
    let s = new TKMapSpec();
    s.west = west;
    s.north = north;
    s.span = span;
    s.zooms = [1.0, 2.0, 4.0, 8.0, 16.0, 32.0];
    s.basePart = n"city";
    s.zoom = 1.0;
    s.showPlayer = true;
    s.playerLabel = "V";
    s.findLabel = "FIND V";
    s.tintOpacity = 0.075;
    s.selectedTint = 0.14;
    s.legendTitle = "PINS";
    s.legendHint = "CLICK A PIN TO OPEN IT";
    s.buttonW = 180.0;
    s.buttonH = 56.0;
    s.buttonFont = 26;
    return s;
  }

  public func AddLayer(minZoom: Float, grid: Int32, path: String, part: CName, exists: String) -> ref<TKMapLayer> {
    let l = new TKMapLayer();
    l.minZoom = minZoom; l.grid = grid; l.path = path; l.part = part; l.exists = exists;
    l.Split();
    ArrayPush(this.layers, l);
    return l;
  }

  public func AddRegion(id: String, name: String, color: HDRColor) -> ref<TKMapRegion> {
    let r = new TKMapRegion();
    r.id = id; r.name = name; r.color = color; r.tint = true;
    ArrayPush(this.regions, r);
    return r;
  }

  public func AddPin(x: Float, y: Float, letter: String, label: String, color: HDRColor, link: String, group: String) -> ref<TKMapPin> {
    let p = new TKMapPin();
    p.x = x; p.y = y; p.letter = letter; p.label = label; p.color = color; p.link = link; p.group = group;
    ArrayPush(this.pins, p);
    return p;
  }

  public func AddToggle(bit: Int32, offLabel: String, onLabel: String, target: String) -> Void {
    let t = new TKMapToggle();
    t.bit = bit; t.offLabel = offLabel; t.onLabel = onLabel; t.target = target;
    ArrayPush(this.toggles, t);
  }

  public func AddLegend(label: String, color: HDRColor, square: Bool, faint: Bool) -> Void {
    let l = new TKMapLegendItem();
    l.label = label; l.color = color; l.square = square; l.faint = faint;
    ArrayPush(this.legend, l);
  }

  public func OnClick(action: String) -> Void { this.clickAction = action; }

  public func View(zoom: Float, mode: Int32, x: Float, y: Float, selected: String, link: String) -> Void {
    this.zoom = zoom; this.mode = mode; this.centreX = x; this.centreY = y; this.selected = selected; this.link = link;
  }

  public func On(target: String) -> Bool {
    for t in this.toggles {
      if Equals(t.target, target) {
        return (this.mode / t.bit) % 2 == 0;
      }
    }
    return true;
  }
}

public class TKMap extends TKCustom {
  private let m_view: wref<TKView>;
  private let m_owner: wref<inkCustomController>;
  private let m_spec: ref<TKMapSpec>;
  private let m_clip: wref<inkWidget>;
  private let m_map: wref<inkCanvas>;
  private let m_layers: array<wref<inkCanvas>>;
  private let m_have: array<String>;
  private let m_buttons: array<ref<TKButton>>;
  private let m_viewW: Float;
  private let m_viewH: Float;
  private let m_size: Float;
  private let m_zoom: Float;
  private let m_mode: Int32;
  private let m_dragging: Bool;
  private let m_button: Int32;
  private let m_moved: Bool;
  private let m_pressHooked: Bool;
  private let m_dragHooked: Bool;
  private let m_dragStart: Vector2;
  private let m_dragFrom: Vector2;
  private let m_pinAt: array<Vector2>;
  private let m_pinLinks: array<String>;
  private let m_pinIds: array<String>;
  private let m_pinFollow: array<String>;
  private let m_pinHolders: array<wref<inkCanvas>>;
  private let m_followGen: Int32;

  public static func Place(v: ref<TKView>, parent: ref<inkCompoundWidget>, spec: ref<TKMapSpec>, w: Float, h: Float) -> ref<TKMap> {
    let width = MinF(w, v.RowWidth());
    let strip = TKInk.Strip(parent, 6.0);
    strip.SetMargin(inkMargin(MaxF(0.0, (v.RowWidth() - width) / 2.0), 6.0, 0.0, 0.0));
    v.Grew(h + 12.0);
    return TKMap.Create(v, v.Owner(), strip, width, h, spec, v.Theme());
  }

  public static func Create(view: ref<TKView>, owner: ref<inkCustomController>, parent: ref<inkCompoundWidget>, viewW: Float, viewH: Float,
      spec: ref<TKMapSpec>, theme: String) -> ref<TKMap> {
    let m = new TKMap();
    m.m_view = view;
    m.m_owner = owner;
    m.m_spec = spec;
    m.m_viewW = viewW;
    m.m_viewH = viewH;
    m.m_zoom = m.Snap(spec.zoom);
    m.m_mode = spec.mode;
    m.m_size = MaxF(viewW, viewH) * m.m_zoom;
    m.Build(parent, theme);
    m.HookPress(true);
    return m;
  }

  public func ToPx(x: Float, y: Float) -> Vector2 = this.ToPxAt(x, y, this.m_size)
  private func ToPxAt(x: Float, y: Float, size: Float) -> Vector2 {
    return Vector2((x - this.m_spec.west) / this.m_spec.span * size, (this.m_spec.north - y) / this.m_spec.span * size);
  }
  private func ToWorld(p: Vector2, size: Float) -> Vector2 {
    return Vector2(this.m_spec.west + p.X / size * this.m_spec.span, this.m_spec.north - p.Y / size * this.m_spec.span);
  }

  private func Level(z: Float) -> Int32 {
    let levels = this.m_spec.zooms;
    let best = 0;
    let i = 1;
    while i < ArraySize(levels) {
      if AbsF(levels[i] - z) < AbsF(levels[best] - z) {
        best = i;
      }
      i += 1;
    }
    return best;
  }
  private func Snap(z: Float) -> Float = ArraySize(this.m_spec.zooms) > 0 ? this.m_spec.zooms[this.Level(z)] : 1.0

  private func ToggleOn(target: String) -> Bool {
    for t in this.m_spec.toggles {
      if Equals(t.target, target) {
        return (this.m_mode / t.bit) % 2 == 0;
      }
    }
    return true;
  }

  private func Build(parent: ref<inkCompoundWidget>, theme: String) -> Void {
    let s = this.m_spec;
    let w = this.m_viewW;
    let h = this.m_viewH;
    let size = this.m_size;
    let box: ref<inkCanvas> = new inkCanvas();
    box.SetSize(Vector2(w, h));
    box.Reparent(parent);

    let clip: ref<inkScrollArea> = new inkScrollArea();
    clip.SetAnchor(inkEAnchor.TopLeft);
    clip.SetAnchorPoint(Vector2(0.0, 0.0));
    clip.SetRenderTransformPivot(Vector2(0.0, 0.0));
    clip.SetFitToContentDirection(inkFitToContentDirection.None);
    clip.SetConstrainContentPosition(true);
    clip.SetUseInternalMask(true);
    clip.SetSize(Vector2(w, h));
    clip.Reparent(box);
    this.m_clip = clip;

    let map: ref<inkCanvas> = new inkCanvas();
    map.SetAnchor(inkEAnchor.TopLeft);
    map.SetAnchorPoint(Vector2(0.0, 0.0));
    map.SetRenderTransformPivot(Vector2(0.0, 0.0));
    map.SetSize(Vector2(size, size));
    map.Reparent(clip);
    this.m_map = map;
    let focus = this.ToPx(s.centreX, s.centreY);
    map.SetTranslation(this.Keep(Vector2(w / 2.0 - focus.X, h / 2.0 - focus.Y)));

    if StrLen(s.base) > 0 {
      this.Picture(map, s.base, s.basePart, 0.0, 0.0, size);
    }
    for l in s.layers {
      let layer: ref<inkCanvas> = new inkCanvas();
      layer.SetAnchor(inkEAnchor.TopLeft);
      layer.SetSize(Vector2(size, size));
      layer.Reparent(map);
      ArrayPush(this.m_layers, layer);
      ArrayPush(this.m_have, "");
    }

    let deep = this.m_zoom >= 15.9 ? 0.75 : 1.0;
    for r in s.regions {
      if r.tint && this.ToggleOn("tint") && StrLen(r.maskAtlas) > 0 {
        this.Tint(map, r, (Equals(r.id, s.selected) ? s.selectedTint : s.tintOpacity) * deep);
      }
    }
    let top: ref<TKMapRegion>;
    for r in s.regions {
      if Equals(r.id, s.selected) {
        top = r;
      } else {
        this.Outline(map, r, 2.0, 0.85);
      }
    }
    if IsDefined(top) {
      this.Outline(map, top, 4.0, 1.0);
    }
    for r in s.regions {
      if r.hasLabel {
        this.Label(map, r, Equals(r.id, s.selected));
      }
    }
    this.Pins(map);
    if s.showPlayer {
      this.Player(map);
    }
    this.EnsureTiles();

    let catcher: ref<inkCanvas> = new inkCanvas();
    catcher.SetSize(Vector2(w, h));
    catcher.SetInteractive(true);
    catcher.Reparent(box);
    catcher.RegisterToCallback(n"OnPress", this, n"OnMapPress");
    catcher.RegisterToCallback(n"OnRelease", this, n"OnMapRelease");
    catcher.RegisterToCallback(n"OnRelative", this, n"OnMapRelative");

    let bar: ref<inkVerticalPanel> = new inkVerticalPanel();
    bar.SetAnchor(inkEAnchor.TopRight);
    bar.SetAnchorPoint(Vector2(1.0, 0.0));
    bar.SetMargin(inkMargin(0.0, 20.0, 20.0, 0.0));
    bar.Reparent(box);
    this.MapButton(bar, "ZOOM +", "zoom_in", theme);
    this.MapButton(bar, "ZOOM -", "zoom_out", theme);
    if s.showPlayer && StrLen(s.findLabel) > 0 {
      this.MapButton(bar, s.findLabel, "find", theme);
    }
    let k = 0;
    for t in s.toggles {
      this.MapButton(bar, this.ToggleOn(t.target) ? t.offLabel : t.onLabel, "tog" + IntToString(k), theme);
      k += 1;
    }
    if ArraySize(s.legend) > 0 {
      this.Legend(box, h, theme);
    }

    let edges = [Vector4(0.0, 0.0, w, 2.0), Vector4(0.0, h - 2.0, w, 2.0), Vector4(0.0, 0.0, 2.0, h), Vector4(w - 2.0, 0.0, 2.0, h)];
    for e in edges {
      let r: ref<inkRectangle> = new inkRectangle();
      r.SetMargin(inkMargin(e.X, e.Y, 0.0, 0.0));
      r.SetSize(Vector2(e.Z, e.W));
      r.Reparent(box);
      TKTheme.PaintNew(r, theme, "frame");
    }
  }

  private func Picture(parent: ref<inkCanvas>, atlas: String, part: CName, x: Float, y: Float, size: Float) -> Void {
    let img: ref<inkImage> = new inkImage();
    img.SetAtlasResource(ResRef.FromString(atlas));
    img.SetTexturePart(part);
    img.SetAnchor(inkEAnchor.TopLeft);
    img.SetMargin(inkMargin(x, y, 0.0, 0.0));
    img.SetSize(Vector2(size, size));
    img.Reparent(parent);
  }

  private func MapButton(bar: ref<inkVerticalPanel>, label: String, cmd: String, theme: String) -> Void {
    let s = this.m_spec;
    let b = TKButton.Make(bar, label, "tk_map_" + cmd, TKScale.F("map.button.w", s.buttonW), TKScale.F("map.button.h", s.buttonH), TKScale.I("map.button.font", s.buttonFont));
    b.GetRootWidget().SetMargin(inkMargin(0.0, 0.0, 0.0, 10.0));
    b.RegisterToCallback(n"OnBtnClick", this, n"OnMapButton");
    TKTheme.Paint(b.GetLabel(), theme, "value");
    ArrayPush(this.m_buttons, b);
  }

  protected cb func OnMapButton(widget: wref<inkWidget>) -> Bool {
    this.Command(StrAfterFirst(NameToString(widget.GetName()), "tk_map_"));
    return true;
  }

  private func Keep(t: Vector2) -> Vector2 {
    return Vector2(ClampF(t.X, this.m_viewW - this.m_size, 0.0), ClampF(t.Y, this.m_viewH - this.m_size, 0.0));
  }

  private func Centre() -> Vector2 {
    let t = IsDefined(this.m_map) ? this.m_map.GetTranslation() : Vector2(0.0, 0.0);
    return this.ToWorld(Vector2(this.m_viewW / 2.0 - t.X, this.m_viewH / 2.0 - t.Y), this.m_size);
  }

  private func EnsureTiles() -> Void {
    if !IsDefined(this.m_map) {
      return;
    }
    let t = this.m_map.GetTranslation();
    let margin = MaxF(this.m_viewW, this.m_viewH) * 0.25;
    let x0 = -t.X - margin;
    let y0 = -t.Y - margin;
    let x1 = -t.X + this.m_viewW + margin;
    let y1 = -t.Y + this.m_viewH + margin;
    let i = 0;
    while i < ArraySize(this.m_spec.layers) {
      if this.m_zoom >= this.m_spec.layers[i].minZoom - 0.1 {
        this.Cover(i, x0, y0, x1, y1);
      }
      i += 1;
    }
  }

  private func Cover(i: Int32, x0: Float, y0: Float, x1: Float, y1: Float) -> Void {
    let l = this.m_spec.layers[i];
    let n = Max(1, l.grid);
    if StrLen(this.m_have[i]) != n * n {
      let blank = "";
      let k = 0;
      while k < n * n {
        blank += "0";
        k += 1;
      }
      this.m_have[i] = blank;
    }
    let ts = this.m_size / Cast<Float>(n);
    let c0 = Max(0, Cast<Int32>(x0 / ts));
    let c1 = Min(n - 1, Cast<Int32>(x1 / ts));
    let r0 = Max(0, Cast<Int32>(y0 / ts));
    let r1 = Min(n - 1, Cast<Int32>(y1 / ts));
    let r = r0;
    while r <= r1 {
      let c = c0;
      while c <= c1 {
        let k = r * n + c;
        if Equals(StrMid(this.m_have[i], k, 1), "0") && (StrLen(l.exists) == 0 || Equals(StrMid(l.exists, k, 1), "1")) {

          this.Picture(this.m_layers[i], l.Tile(c, r), l.part, Cast<Float>(c) * ts, Cast<Float>(r) * ts, ts + 1.0);
          this.m_have[i] = StrLeft(this.m_have[i], k) + "1" + StrRight(this.m_have[i], n * n - k - 1);
        }
        c += 1;
      }
      r += 1;
    }
  }

  private func Tint(map: ref<inkCanvas>, r: ref<TKMapRegion>, opacity: Float) -> Void {
    let m = r.maskRect;
    if m.Z <= 0.0 {
      return;
    }
    let at = this.ToPx(m.X, m.Y);
    let img: ref<inkImage> = new inkImage();
    img.SetAtlasResource(ResRef.FromString(r.maskAtlas));
    img.SetTexturePart(r.maskPart);
    img.SetAnchor(inkEAnchor.TopLeft);
    img.SetMargin(inkMargin(at.X, at.Y, 0.0, 0.0));
    img.SetSize(Vector2(m.Z / this.m_spec.span * this.m_size, m.W / this.m_spec.span * this.m_size));
    img.SetTintColor(r.color);
    img.SetOpacity(opacity);
    img.Reparent(map);
  }

  private func Outline(map: ref<inkCanvas>, r: ref<TKMapRegion>, thick: Float, opacity: Float) -> Void {
    let start = 0;
    for end in r.ringEnds {
      let k = start;
      while k + 1 < end {
        let next = k + 2 < end ? k + 2 : start;
        TKMap.Edge(map, this.ToPx(r.rings[k], r.rings[k + 1]), this.ToPx(r.rings[next], r.rings[next + 1]), thick, r.color, opacity);
        k += 2;
      }
      start = end;
    }
  }

  private static func Edge(map: ref<inkCanvas>, a: Vector2, b: Vector2, t: Float, color: HDRColor, opacity: Float) -> Void {
    let dx = b.X - a.X;
    let dy = b.Y - a.Y;
    let len = SqrtF(dx * dx + dy * dy);
    if len < 0.5 {
      return;
    }
    let w = len + t;
    let bar: ref<inkRectangle> = new inkRectangle();
    bar.SetAnchor(inkEAnchor.TopLeft);
    bar.SetAnchorPoint(Vector2(0.0, 0.0));
    bar.SetRenderTransformPivot(Vector2(0.5, 0.5));
    bar.SetSize(Vector2(w, t));
    bar.SetMargin(inkMargin((a.X + b.X) / 2.0 - w / 2.0, (a.Y + b.Y) / 2.0 - t / 2.0, 0.0, 0.0));
    bar.SetRotation(Rad2Deg(AtanF(dy, dx)));
    bar.SetTintColor(color);
    bar.SetOpacity(opacity);
    bar.Reparent(map);
  }

  private func Label(map: ref<inkCanvas>, r: ref<TKMapRegion>, selected: Bool) -> Void {
    let at = this.ToPx(r.label.X, r.label.Y);
    let font = selected ? 36 : 26;
    let t = TKInk.Tinted(map, StrUpper(r.name), font, n"Semi-Bold", r.color, 0.0);
    t.SetMargin(inkMargin(at.X - Cast<Float>(StrLen(r.name) * font) * 0.28, at.Y - Cast<Float>(font) * 0.7, 0.0, 0.0));
    t.SetOpacity(selected ? 1.0 : 0.85);
  }

  private func Player(map: ref<inkCanvas>) -> Void {
    let player = GetPlayer(GetGameInstance());
    if !IsDefined(player) {
      return;
    }
    let pos = player.GetWorldPosition();
    let at = this.ToPx(pos.X, pos.Y);
    if at.X < 0.0 || at.Y < 0.0 || at.X > this.m_size || at.Y > this.m_size {
      return;
    }
    let rim: ref<inkRectangle> = new inkRectangle();
    rim.SetSize(Vector2(26.0, 26.0));
    rim.SetMargin(inkMargin(at.X - 13.0, at.Y - 13.0, 0.0, 0.0));
    rim.SetRenderTransformPivot(Vector2(0.5, 0.5));
    rim.SetRotation(45.0);
    rim.SetTintColor(new HDRColor(0.02, 0.05, 0.08, 1.0));
    rim.Reparent(map);
    let dot: ref<inkRectangle> = new inkRectangle();
    dot.SetSize(Vector2(16.0, 16.0));
    dot.SetMargin(inkMargin(at.X - 8.0, at.Y - 8.0, 0.0, 0.0));
    dot.SetRenderTransformPivot(Vector2(0.5, 0.5));
    dot.SetRotation(45.0);
    dot.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
    dot.Reparent(map);
    let v = TKInk.Tinted(map, this.m_spec.playerLabel, 30, n"Semi-Bold", new HDRColor(1.0, 1.0, 1.0, 1.0), 0.0);
    v.SetMargin(inkMargin(at.X + 16.0, at.Y - 22.0, 0.0, 0.0));
  }

  private func Pins(map: ref<inkCanvas>) -> Void {
    ArrayClear(this.m_pinAt);
    ArrayClear(this.m_pinLinks);
    ArrayClear(this.m_pinIds);
    ArrayClear(this.m_pinFollow);
    ArrayClear(this.m_pinHolders);
    let following = false;
    for p in this.m_spec.pins {
      if StrLen(p.group) == 0 || this.ToggleOn(p.group) {
        let at = this.ToPx(p.x, p.y);

        let holder: ref<inkCanvas> = new inkCanvas();
        holder.SetAnchor(inkEAnchor.TopLeft);
        holder.SetSize(Vector2(0.0, 0.0));
        holder.SetMargin(inkMargin(at.X, at.Y, 0.0, 0.0));
        holder.Reparent(map);
        if p.ring > 0.0 {
          this.RingAround(holder, p.ring / this.m_spec.span * this.m_size, p.color);
        }
        this.Pin(holder, Vector2(0.0, 0.0), p);
        ArrayPush(this.m_pinAt, at);
        ArrayPush(this.m_pinLinks, p.link);
        ArrayPush(this.m_pinIds, p.id);
        ArrayPush(this.m_pinFollow, p.follow);
        ArrayPush(this.m_pinHolders, holder);
        if StrLen(p.follow) > 0 {
          following = true;
        }
      }
    }
    if following {
      this.m_followGen += 1;
      this.FollowStep(this.m_followGen);
    }
  }

  private func RingAround(holder: ref<inkCanvas>, radius: Float, color: HDRColor) -> Void {
    if radius < 4.0 {
      return;
    }
    let n = Clamp(RoundF(radius / 6.0), 16, 96);
    let k = 0;
    while k < n {
      if k % 2 == 0 {
        let a0 = 6.2831853 * Cast<Float>(k) / Cast<Float>(n);
        let a1 = 6.2831853 * Cast<Float>(k + 1) / Cast<Float>(n);
        TKInk.Seg(holder, Vector2(CosF(a0) * radius, SinF(a0) * radius), Vector2(CosF(a1) * radius, SinF(a1) * radius), 2.0, color, 0.9);
      }
      k += 1;
    }
  }

  public func MovePin(id: String, x: Float, y: Float) -> Void {
    let i = 0;
    while i < ArraySize(this.m_pinIds) {
      if Equals(this.m_pinIds[i], id) {
        let at = this.ToPx(x, y);
        this.m_pinAt[i] = at;
        if IsDefined(this.m_pinHolders[i]) {
          this.m_pinHolders[i].SetMargin(inkMargin(at.X, at.Y, 0.0, 0.0));
        }
      }
      i += 1;
    }
  }

  public func FollowStep(gen: Int32) -> Void {
    if gen != this.m_followGen || !IsDefined(this.m_map) {
      return;
    }
    let i = 0;
    while i < ArraySize(this.m_pinFollow) {
      let pos: Vector4;
      if StrLen(this.m_pinFollow[i]) > 0 && TKPins.Position(this.m_pinFollow[i], pos) {
        let at = this.ToPx(pos.X, pos.Y);
        this.m_pinAt[i] = at;
        if IsDefined(this.m_pinHolders[i]) {
          this.m_pinHolders[i].SetMargin(inkMargin(at.X, at.Y, 0.0, 0.0));
        }
      }
      i += 1;
    }
    let cb = new TKMapFollowTick();
    cb.map = this;
    cb.gen = gen;
    GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(cb, 0.5, false);
  }

  private func Pin(map: ref<inkCanvas>, at: Vector2, p: ref<TKMapPin>) -> Void {
    if StrLen(p.iconAtlas) > 0 {

      let isize = p.faint ? 32.0 : 44.0;
      let img: ref<inkImage> = new inkImage();
      img.SetAtlasResource(ResRef.FromString(p.iconAtlas));
      img.SetTexturePart(p.iconPart);
      img.SetAnchor(inkEAnchor.TopLeft);
      img.SetSize(Vector2(isize, isize));
      img.SetMargin(inkMargin(at.X - isize / 2.0, at.Y - isize / 2.0, 0.0, 0.0));
      img.SetTintColor(p.color);
      img.Reparent(map);
      if StrLen(p.label) > 0 {
        let label = TKInk.Tinted(map, StrUpper(p.label), 24, n"Semi-Bold", p.color, 0.0);
        label.SetMargin(inkMargin(at.X + isize / 2.0 + 10.0, at.Y - 15.0, 0.0, 0.0));
      }
      return;
    }
    let faint = p.faint;
    let color = p.color;
    let dark = new HDRColor(0.02, 0.04, 0.06, 1.0);
    let turn = p.square ? 0.0 : 45.0;
    let size = faint ? 24.0 : 32.0;
    let rim: ref<inkRectangle> = new inkRectangle();
    rim.SetSize(Vector2(size + 8.0, size + 8.0));
    rim.SetMargin(inkMargin(at.X - (size + 8.0) / 2.0, at.Y - (size + 8.0) / 2.0, 0.0, 0.0));
    rim.SetRenderTransformPivot(Vector2(0.5, 0.5));
    rim.SetRotation(turn);
    rim.SetTintColor(faint ? color : dark);
    rim.SetOpacity(faint ? 0.8 : 0.9);
    rim.Reparent(map);
    let body: ref<inkRectangle> = new inkRectangle();
    body.SetSize(Vector2(size, size));
    body.SetMargin(inkMargin(at.X - size / 2.0, at.Y - size / 2.0, 0.0, 0.0));
    body.SetRenderTransformPivot(Vector2(0.5, 0.5));
    body.SetRotation(turn);
    body.SetTintColor(faint ? dark : color);
    body.SetOpacity(faint ? 0.85 : 1.0);
    body.Reparent(map);
    let font = faint ? 16 : 20;
    let t = TKInk.Tinted(map, p.letter, font, n"Semi-Bold", faint ? color : dark, 0.0);
    t.SetMargin(inkMargin(at.X - Cast<Float>(StrLen(p.letter) * font) * 0.3, at.Y - Cast<Float>(font) * 0.66, 0.0, 0.0));
    if StrLen(p.label) > 0 && (!faint || this.m_zoom >= 3.9) {
      let name = TKInk.Tinted(map, StrUpper(p.label), faint ? 20 : 24, n"Semi-Bold", color, 0.0);
      name.SetMargin(inkMargin(at.X + size / 2.0 + 12.0, at.Y - 15.0, 0.0, 0.0));
      name.SetOpacity(faint ? 0.75 : 1.0);
    }
  }

  private func PinAt(p: Vector2) -> Int32 {
    let best = -1;
    let bestD = 24.0 * 24.0;
    let i = 0;
    while i < ArraySize(this.m_pinAt) {
      let dx = this.m_pinAt[i].X - p.X;
      let dy = this.m_pinAt[i].Y - p.Y;
      if dx * dx + dy * dy < bestD {
        best = i;
        bestD = dx * dx + dy * dy;
      }
      i += 1;
    }
    return best;
  }

  private func Legend(box: ref<inkCanvas>, h: Float, theme: String) -> Void {
    let s = this.m_spec;
    let rowH = 30.0;
    let w = 250.0;
    let lh = Cast<Float>(ArraySize(s.legend)) * rowH + 64.0;
    let panel: ref<inkCanvas> = new inkCanvas();
    panel.SetSize(Vector2(w, lh));
    panel.SetMargin(inkMargin(20.0, h - lh - 20.0, 0.0, 0.0));
    panel.Reparent(box);
    let bg: ref<inkRectangle> = new inkRectangle();
    bg.SetSize(Vector2(w, lh));
    bg.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    bg.SetOpacity(0.6);
    bg.Reparent(panel);
    let title = TKInk.Plain(panel, s.legendTitle, 22, n"Semi-Bold", 0.0);
    title.SetMargin(inkMargin(16.0, 10.0, 0.0, 0.0));
    TKTheme.PaintNew(title, theme, "accent");
    let i = 0;
    for item in s.legend {
      let y = 44.0 + Cast<Float>(i) * rowH;
      let chip: ref<inkRectangle> = new inkRectangle();
      chip.SetSize(Vector2(14.0, 14.0));
      chip.SetMargin(inkMargin(20.0, y + 4.0, 0.0, 0.0));
      chip.SetRenderTransformPivot(Vector2(0.5, 0.5));
      chip.SetRotation(item.square ? 0.0 : 45.0);
      chip.SetTintColor(item.color);
      chip.SetOpacity(item.faint ? 0.5 : 1.0);
      chip.Reparent(panel);
      let t = TKInk.Tinted(panel, item.label, 20, n"Medium", item.color, 0.0);
      t.SetMargin(inkMargin(48.0, y, 0.0, 0.0));
      i += 1;
    }
    let hint = TKInk.Plain(panel, s.legendHint, 16, n"Regular", 0.0);
    hint.SetMargin(inkMargin(16.0, lh - 26.0, 0.0, 0.0));
    hint.SetOpacity(0.7);
    TKTheme.PaintNew(hint, theme, "text");
  }

  private func RegionAt(w: Vector2) -> String {
    let outer = "";
    for r in this.m_spec.regions {
      if TKMap.Inside(w, r) {
        if !r.surround {
          return r.id;
        }
        if StrLen(outer) == 0 {
          outer = r.id;
        }
      }
    }
    return outer;
  }

  private static func Inside(p: Vector2, r: ref<TKMapRegion>) -> Bool {
    let inside = false;
    let start = 0;
    for end in r.ringEnds {
      let j = end - 2;
      let k = start;
      while k + 1 < end {
        let ax = r.rings[k];
        let ay = r.rings[k + 1];
        let bx = r.rings[j];
        let by = r.rings[j + 1];
        if !Equals(ay > p.Y, by > p.Y) && p.X < (bx - ax) * (p.Y - ay) / (by - ay) + ax {
          inside = !inside;
        }
        j = k;
        k += 2;
      }
      start = end;
    }
    return inside;
  }

  private func Command(cmd: String) -> Void {
    let centre = this.Centre();
    let levels = this.m_spec.zooms;
    let z = this.Level(this.m_zoom);
    if Equals(cmd, "zoom_in") {
      this.Go(levels[Min(z + 1, ArraySize(levels) - 1)], centre, this.m_spec.selected);
      return;
    }
    if Equals(cmd, "zoom_out") {
      this.Go(levels[Max(z - 1, 0)], centre, this.m_spec.selected);
      return;
    }
    if Equals(cmd, "find") {
      let player = GetPlayer(GetGameInstance());
      if IsDefined(player) {
        let pos = player.GetWorldPosition();
        this.Go(MaxF(this.m_zoom, 8.0), Vector2(pos.X, pos.Y), this.m_spec.selected);
      }
      return;
    }
    if StrBeginsWith(cmd, "tog") {
      let k = StringToInt(StrAfterFirst(cmd, "tog"), -1);
      if k >= 0 && k < ArraySize(this.m_spec.toggles) {
        let t = this.m_spec.toggles[k];
        this.m_mode += this.ToggleOn(t.target) ? t.bit : -t.bit;
        this.Go(this.m_zoom, centre, this.m_spec.selected);
      }
    }
  }

  private func Arg(zoom: Float, centre: Vector2, region: String) -> String {
    let target = this.m_spec.link;
    target = StrReplace(target, "%D", region);
    target = StrReplace(target, "%Z", FloatToString(zoom));
    target = StrReplace(target, "%M", IntToString(this.m_mode));
    target = StrReplace(target, "%X", IntToString(RoundF(centre.X)));
    target = StrReplace(target, "%Y", IntToString(RoundF(centre.Y)));
    return target;
  }

  private func Go(zoom: Float, centre: Vector2, region: String) -> Void {
    let target = this.Arg(zoom, centre, region);
    let view = this.m_view;
    if IsDefined(view) {
      view.Show(StrBeforeFirst(target, "~"), StrAfterFirst(target, "~"), "");
    }
  }

  private func Remember() -> Void {
    let view = this.m_view;
    if IsDefined(view) {
      view.SetArg(StrAfterFirst(this.Arg(this.m_zoom, this.Centre(), this.m_spec.selected), "~"));
    }
  }

  private func Cursor(e: ref<inkPointerEvent>) -> Vector2 {
    return WidgetUtils.GlobalToLocal(this.m_clip, e.GetScreenSpacePosition());
  }

  private func InView(p: Vector2) -> Bool {
    return p.X >= 0.0 && p.Y >= 0.0 && p.X <= this.m_viewW && p.Y <= this.m_viewH;
  }

  private static func Middle(e: ref<inkPointerEvent>) -> Bool {
    return RedFunc.MouseButton(3) || e.IsAction(n"UI_vehicle_customization_fake_slider_value") || e.IsAction(n"world_map_menu_zoom_to_mappin");
  }

  private static func Left(e: ref<inkPointerEvent>) -> Bool {
    return e.IsAction(n"mouse_left") || e.IsAction(n"click");
  }

  private func StartDrag(e: ref<inkPointerEvent>, button: Int32) -> Void {
    if this.m_dragging || !IsDefined(this.m_map) || !IsDefined(this.m_clip) {
      return;
    }
    this.m_dragging = true;
    this.m_button = button;
    this.m_moved = false;
    this.m_dragStart = this.Cursor(e);
    this.m_dragFrom = this.m_map.GetTranslation();
    this.HookDrag(true);
  }

  protected cb func OnMapPress(e: ref<inkPointerEvent>) -> Bool {
    if TKMap.Left(e) {
      this.StartDrag(e, 1);
      return true;
    }
    if TKMap.Middle(e) {
      this.StartDrag(e, 3);
      return true;
    }
    return false;
  }

  protected cb func OnGlobalPress(e: ref<inkPointerEvent>) -> Bool {
    if this.m_dragging || !IsDefined(this.m_clip) || !this.InView(this.Cursor(e)) {
      return false;
    }
    if TKMap.Middle(e) && !TKMap.Left(e) {
      this.StartDrag(e, 3);
    }
    return false;
  }

  protected cb func OnMapRelease(e: ref<inkPointerEvent>) -> Bool {
    if this.m_dragging && (this.m_button == 1 ? TKMap.Left(e) : TKMap.Middle(e) || !RedFunc.MouseButton(3)) {
      this.EndDrag();
    }
    return true;
  }

  protected cb func OnGlobalRelease(e: ref<inkPointerEvent>) -> Bool {
    if this.m_dragging && (this.m_button == 1 ? TKMap.Left(e) : !RedFunc.MouseButton(3)) {
      this.EndDrag();
    }
    return false;
  }

  protected cb func OnMapRelative(e: ref<inkPointerEvent>) -> Bool {
    if e.IsAction(n"mouse_wheel") {
      let d = e.GetAxisData();
      if d != 0.0 && !this.m_dragging {
        this.Wheel(d > 0.0, this.Cursor(e));
      }
      return true;
    }
    if e.IsAction(n"mouse_x") || e.IsAction(n"mouse_y") {
      if !this.m_dragging && RedFunc.MouseButton(3) {
        this.StartDrag(e, 3);
      } else {
        if this.m_dragging && !this.m_dragHooked {
          this.Drag(e);
        }
      }
    }
    return false;
  }

  protected cb func OnGlobalMove(e: ref<inkPointerEvent>) -> Bool {
    if !this.m_dragging {
      this.HookDrag(false);
      return false;
    }
    if e.IsAction(n"mouse_x") || e.IsAction(n"mouse_y") {

      if !RedFunc.MouseButton(this.m_button) {
        this.EndDrag();
        return false;
      }
      this.Drag(e);
    }
    return false;
  }

  private func Drag(e: ref<inkPointerEvent>) -> Void {
    if !IsDefined(this.m_map) || !IsDefined(this.m_clip) {
      this.Stop();
      return;
    }
    let cur = this.Cursor(e);
    let dx = cur.X - this.m_dragStart.X;
    let dy = cur.Y - this.m_dragStart.Y;
    if AbsF(dx) + AbsF(dy) > 8.0 {
      this.m_moved = true;
    }
    this.m_map.SetTranslation(this.Keep(Vector2(this.m_dragFrom.X + dx, this.m_dragFrom.Y + dy)));
    this.EnsureTiles();
  }

  private func EndDrag() -> Void {
    if !this.m_dragging || !IsDefined(this.m_map) {
      return;
    }
    this.m_dragging = false;
    this.HookDrag(false);
    let centre = this.Centre();
    if this.m_moved {
      this.Remember();
      return;
    }
    if this.m_button == 1 {
      let t = this.m_map.GetTranslation();
      let spot = Vector2(this.m_dragStart.X - t.X, this.m_dragStart.Y - t.Y);
      let pin = this.PinAt(spot);
      let view = this.m_view;
      if pin >= 0 && StrLen(this.m_pinLinks[pin]) > 0 && IsDefined(view) {
        let link = this.m_pinLinks[pin];
        view.Show(StrContains(link, "~") ? StrBeforeFirst(link, "~") : link, StrContains(link, "~") ? StrAfterFirst(link, "~") : "", "");
        return;
      }
      if StrLen(this.m_spec.clickAction) > 0 && IsDefined(view) {
        let w = this.ToWorld(spot, this.m_size);
        this.Remember();
        view.Act(this.m_spec.clickAction, IntToString(RoundF(w.X)) + "|" + IntToString(RoundF(w.Y)));
        return;
      }
      let hit = this.RegionAt(this.ToWorld(spot, this.m_size));
      if StrLen(hit) > 0 && !Equals(hit, this.m_spec.selected) {
        this.Go(this.m_zoom, centre, hit);
      }
    }
  }

  private func Wheel(zoomIn: Bool, cursor: Vector2) -> Void {
    let levels = this.m_spec.zooms;
    let z = this.Level(this.m_zoom);
    let k = zoomIn ? Min(z + 1, ArraySize(levels) - 1) : Max(z - 1, 0);
    if k == z || !IsDefined(this.m_map) {
      return;
    }
    let next = levels[k];
    let t = this.m_map.GetTranslation();
    let f = next / this.m_zoom;
    let spot = Vector2((cursor.X - t.X) * f, (cursor.Y - t.Y) * f);
    let nt = Vector2(cursor.X - spot.X, cursor.Y - spot.Y);
    this.Go(next, this.ToWorld(Vector2(this.m_viewW / 2.0 - nt.X, this.m_viewH / 2.0 - nt.Y), this.m_size * f), this.m_spec.selected);
  }

  private func HookPress(on: Bool) -> Void {
    let owner = this.m_owner;
    if Equals(on, this.m_pressHooked) || !IsDefined(owner) {
      return;
    }
    this.m_pressHooked = on;
    if on {
      owner.RegisterToGlobalInputCallback(n"OnPostOnPress", this, n"OnGlobalPress");
    } else {
      owner.UnregisterFromGlobalInputCallback(n"OnPostOnPress", this, n"OnGlobalPress");
    }
  }

  private func HookDrag(on: Bool) -> Void {
    let owner = this.m_owner;
    if Equals(on, this.m_dragHooked) || !IsDefined(owner) {
      return;
    }
    this.m_dragHooked = on;
    if on {
      owner.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnGlobalMove");
      owner.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalRelease");
    } else {
      owner.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnGlobalMove");
      owner.UnregisterFromGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalRelease");
    }
  }

  public func Stop() -> Void {
    this.m_followGen += 1;
    this.m_dragging = false;
    this.HookDrag(false);
    this.HookPress(false);
  }
}

public class TKMapFollowTick extends DelayCallback {
  public let map: wref<TKMap>;
  public let gen: Int32;
  public func Call() -> Void {
    if IsDefined(this.map) {
      this.map.FollowStep(this.gen);
    }
  }
}

public class TKHudTick extends DelayCallback {
  public let hud: wref<TKHudSystem>;
  public let generation: Int32;
  public func Call() -> Void {
    if IsDefined(this.hud) {
      this.hud.Step(this.generation);
    }
  }
}

public class TKHudStrip extends IScriptable {
  public let id: String;
  public let width: Float;
  public let shown: Bool;
  public let title: String;
  public let right: String;
  public let sub: String;
  public let warn: Bool;
  public let hasTarget: Bool;
  public let target: Vector4;
  public let showDistance: Bool;
  public let fraction: Float;

  public let box: ref<inkCanvas>;
  public let line: ref<inkRectangle>;
  public let titleText: ref<inkText>;
  public let rightText: ref<inkText>;
  public let subText: ref<inkText>;
  public let distText: ref<inkText>;
  public let track: ref<inkCanvas>;
  public let marker: ref<inkRectangle>;
  public let leftArrow: ref<inkText>;
  public let rightArrow: ref<inkText>;
  public let bar: ref<inkRectangle>;
  public let warned: Bool;

  public func Set(title: String, right: String, sub: String) -> Void {
    this.title = title;
    this.right = right;
    this.sub = sub;
  }

  public func Target(pos: Vector4, opt noDistance: Bool) -> Void {
    this.target = pos;
    this.hasTarget = true;
    this.showDistance = !noDistance;
  }

  public func TargetPin(key: String, opt noDistance: Bool) -> Void {
    let pos: Vector4;
    if TKPins.Position(key, pos) {
      this.Target(pos, noDistance);
    } else {
      this.NoTarget();
    }
  }
  public func NoTarget() -> Void { this.hasTarget = false; }
  public func Warn(on: Bool) -> Void { this.warn = on; }
  public func Fraction(f: Float) -> Void { this.fraction = f; }
  public func Show() -> Void {
    this.shown = true;
    TKHud.Poll();
  }
  public func Hide() -> Void { this.shown = false; }
}

public abstract class TKHud {
  public static func Get() -> ref<TKHudSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"TerminalKit.TKHudSystem") as TKHudSystem

  public static func Strip(id: String, width: Float) -> ref<TKHudStrip> {
    let hud = TKHud.Get();
    return IsDefined(hud) ? hud.GetStrip(id, width) : new TKHudStrip();
  }

  public static func Toast(kicker: String, title: String, line: String, highlight: String, text: String, items: array<String>, secs: Float, bad: Bool) -> Void {
    let hud = TKHud.Get();
    if IsDefined(hud) {
      hud.ShowToast(kicker, title, line, highlight, text, items, secs, bad);
    }
  }

  public static func SetTheme(theme: String) -> Void {
    let hud = TKHud.Get();
    if IsDefined(hud) {
      hud.SetTheme(theme);
    }
  }

  public static func Poll() -> Void {
    let hud = TKHud.Get();
    if IsDefined(hud) {
      hud.Poll();
    }
  }

  public static func Along(target: Vector4) -> Float {
    let p = GetPlayer(GetGameInstance());
    if !IsDefined(p) {
      return 0.5;
    }
    let pos = p.GetWorldPosition();
    let fw = p.GetWorldForward();
    let rel = Rad2Deg(AtanF(target.X - pos.X, target.Y - pos.Y)) - Rad2Deg(AtanF(fw.X, fw.Y));
    while rel > 180.0 { rel -= 360.0; }
    while rel < -180.0 { rel += 360.0; }
    return ClampF((rel + 90.0) / 180.0, 0.0, 1.0);
  }

  public static func Warning() -> HDRColor = new HDRColor(1.0, 0.22, 0.2, 1.0)
}

public class TKHudSystem extends ScriptableSystem {
  private let m_root: ref<inkCanvas>;
  private let m_generation: Int32;
  private let m_ticking: Bool;
  private let m_theme: String = "hud";
  private let m_built: String;
  private let m_strips: array<ref<TKHudStrip>>;

  private let m_toast: ref<inkCanvas>;
  private let m_toastTime: ref<inkRectangle>;
  private let m_toastW: Float;
  private let m_hideAt: Float;
  private let m_length: Float;

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    this.m_generation += 1;
    this.m_ticking = false;
    this.m_root = null;
    this.m_toast = null;
    this.m_hideAt = 0.0;
    for s in this.m_strips {
      s.box = null;
      s.shown = false;
    }
  }

  private func Now() -> Float = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGameInstance()))

  public func SetTheme(theme: String) -> Void {
    if StrLen(theme) > 0 {
      this.m_theme = theme;
    }
  }

  public func GetStrip(id: String, width: Float) -> ref<TKHudStrip> {
    for s in this.m_strips {
      if Equals(s.id, id) {
        return s;
      }
    }
    let s = new TKHudStrip();
    s.id = id;
    s.width = width;
    s.fraction = -1.0;
    ArrayPush(this.m_strips, s);
    return s;
  }

  private func Paint(w: ref<inkWidget>, role: String) -> Void { TKTheme.Paint(w, this.m_theme, role); }

  private func Fixed(w: ref<inkWidget>, color: HDRColor) -> Void {
    TKTheme.Paint(w, "mono", "text");
    w.SetTintColor(color);
  }

  private func Text(parent: ref<inkCompoundWidget>, size: Int32, style: CName, role: String, x: Float, y: Float, right: Bool) -> ref<inkText> {
    let t = new inkText();
    t.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    t.SetFontStyle(style);
    t.SetFontSize(size);
    t.SetLetterCase(textLetterCase.OriginalCase);
    if right {
      t.SetAnchor(inkEAnchor.TopRight);
      t.SetAnchorPoint(Vector2(1.0, 0.0));
      t.SetHorizontalAlignment(textHorizontalAlignment.Right);
      t.SetMargin(inkMargin(0.0, y, x, 0.0));
    } else {
      t.SetAnchor(inkEAnchor.TopLeft);
      t.SetMargin(inkMargin(x, y, 0.0, 0.0));
    }
    t.Reparent(parent);
    this.Paint(t, role);
    return t;
  }

  private func Rect(parent: ref<inkCompoundWidget>, x: Float, y: Float, w: Float, h: Float, role: String, opacity: Float) -> ref<inkRectangle> {
    let r = new inkRectangle();
    r.SetAnchor(inkEAnchor.TopLeft);
    r.SetMargin(inkMargin(x, y, 0.0, 0.0));
    r.SetSize(Vector2(w, h));
    r.SetOpacity(opacity);
    r.Reparent(parent);
    if StrLen(role) > 0 {
      this.Paint(r, role);
    } else {
      r.SetTintColor(new HDRColor(0.02, 0.02, 0.03, 1.0));
    }
    return r;
  }

  private func Panel(w: Float, h: Float) -> ref<inkCanvas> {
    let c = new inkCanvas();
    c.SetSize(Vector2(w, h));
    c.SetAnchor(inkEAnchor.TopCenter);
    c.SetAnchorPoint(Vector2(0.5, 0.0));
    c.SetMargin(inkMargin(0.0, 20.0, 0.0, 0.0));
    c.SetVisible(false);
    c.Reparent(this.m_root);
    return c;
  }

  private func Build() -> Bool {
    if !IsDefined(this.m_root) {
      let layer = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
      if !IsDefined(layer) {
        return false;
      }
      this.m_root = new inkCanvas();
      this.m_root.SetName(n"TKHud");
      this.m_root.SetAnchor(inkEAnchor.Fill);
      this.m_root.Reparent(layer.GetVirtualWindow());
      this.m_built = "";
    }
    if !Equals(this.m_built, this.m_theme) {
      this.m_built = this.m_theme;
      for s in this.m_strips {
        if IsDefined(s.box) {
          this.m_root.RemoveChild(s.box);
          s.box = null;
        }
      }
    }
    return true;
  }

  private func BuildStrip(s: ref<TKHudStrip>) -> Void {
    let w = s.width;
    let h = 112.0;
    s.box = this.Panel(w, h);
    this.Rect(s.box, 0.0, 0.0, w, h, "", 0.62);
    s.line = this.Rect(s.box, 0.0, 0.0, w, 3.0, "accent", 1.0);
    s.titleText = this.Text(s.box, 28, n"Semi-Bold", "accent", 20.0, 10.0, false);
    s.rightText = this.Text(s.box, 24, n"Medium", "text", 20.0, 13.0, true);

    let x = 40.0;
    let y = 58.0;
    let tw = w - 80.0;
    s.track = new inkCanvas();
    s.track.SetSize(Vector2(w, 30.0));
    s.track.Reparent(s.box);
    this.Rect(s.track, x, y, tw, 2.0, "text", 0.45);
    this.Rect(s.track, x + tw / 2.0 - 1.0, y - 6.0, 2.0, 14.0, "text", 0.6);
    s.marker = this.Rect(s.track, x, y - 4.0, 10.0, 10.0, "accent", 1.0);
    s.marker.SetRotation(45.0);
    s.leftArrow = this.Text(s.track, 26, n"Semi-Bold", "accent", x - 24.0, y - 17.0, false);
    s.leftArrow.SetText("<");
    s.rightArrow = this.Text(s.track, 26, n"Semi-Bold", "accent", x + tw + 10.0, y - 17.0, false);
    s.rightArrow.SetText(">");
    s.subText = this.Text(s.box, 22, n"Regular", "text", 20.0, 74.0, false);
    s.distText = this.Text(s.box, 26, n"Semi-Bold", "value", 20.0, 71.0, true);
    s.bar = this.Rect(s.box, 0.0, h - 4.0, w, 4.0, "accent", 0.9);
    s.warned = false;
  }

  public func ShowToast(kicker: String, title: String, line: String, highlight: String, text: String, items: array<String>, secs: Float, bad: Bool) -> Void {
    if !this.Build() {
      return;
    }
    if !IsDefined(this.m_toast) {
      this.m_toast = this.Panel(880.0, 200.0);
    }
    let w = 880.0;
    let pad = 36.0;
    let tw = w - pad * 2.0;
    let c = this.m_toast;
    c.RemoveAllChildren();
    let back = this.Rect(c, 0.0, 0.0, w, 100.0, "", 0.93);
    let edge = this.Rect(c, 0.0, 0.0, 5.0, 100.0, "accent", 1.0);
    this.Text(c, 18, n"Medium", "text", pad, 18.0, false).SetText(kicker);
    let head = this.Text(c, 38, n"Semi-Bold", "title", pad, 42.0, false);
    head.SetText(title);
    if bad {
      this.Fixed(head, TKHud.Warning());
      this.Fixed(edge, TKHud.Warning());
    }
    let y = 94.0;
    if StrLen(line) > 0 {
      let t = this.Text(c, 24, n"Medium", "value", pad, y, false);
      t.SetText(line);
      t.SetWrapping(true, tw);
      y += 34.0 * TKInk.Lines(line, 24, tw);
    }
    if StrLen(highlight) > 0 {
      let m = this.Text(c, 24, n"Semi-Bold", "accent", pad, y, false);
      m.SetText(highlight);
      if bad {
        this.Fixed(m, TKHud.Warning());
      }
      y += 34.0;
    }
    if StrLen(text) > 0 {
      y += 10.0;
      let t = this.Text(c, 21, n"Regular", "text", pad, y, false);
      t.SetText(text);
      t.SetWrapping(true, tw);
      y += 29.0 * TKInk.Lines(text, 21, tw);
    }
    if ArraySize(items) > 0 {
      y += 10.0;
      for item in items {
        this.Rect(c, pad + 1.0, y + 12.0, 7.0, 7.0, "accent", 1.0).SetRotation(45.0);
        let t = this.Text(c, 22, n"Medium", "value", pad + 22.0, y, false);
        t.SetText(item);
        t.SetWrapping(true, tw - 22.0);
        y += 31.0 * TKInk.Lines(item, 22, tw - 22.0);
      }
    }
    let h = y + 28.0;
    back.SetSize(Vector2(w, h));
    edge.SetSize(Vector2(5.0, h));
    this.m_toastTime = this.Rect(c, 5.0, h - 4.0, w - 5.0, 4.0, "accent", 0.7);
    c.SetSize(Vector2(w, h));
    this.m_toastW = w - 5.0;
    this.m_length = MaxF(1.0, secs);
    this.m_hideAt = this.Now() + this.m_length;
    c.SetVisible(true);
    this.Poll();
  }

  public func Poll() -> Void {
    if this.m_ticking {
      return;
    }
    let any = this.m_hideAt > 0.0;
    for s in this.m_strips {
      if s.shown {
        any = true;
      }
    }
    if any {
      this.m_ticking = true;
      this.Step(this.m_generation);
    }
  }

  public func Step(generation: Int32) -> Void {
    if generation != this.m_generation {
      return;
    }
    if !this.Build() {
      this.m_ticking = false;
      return;
    }
    let y = 20.0;
    let busy = false;
    for s in this.m_strips {
      if s.shown {
        if !IsDefined(s.box) {
          this.BuildStrip(s);
        }
        this.DrawStrip(s, y);
        y += 124.0;
        busy = true;
      } else {
        if IsDefined(s.box) {
          s.box.SetVisible(false);
        }
      }
    }
    if this.StepToast(y) {
      busy = true;
    }
    this.m_ticking = busy;
    if busy {
      let cb = new TKHudTick();
      cb.hud = this;
      cb.generation = this.m_generation;
      GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, 0.1, false);
    }
  }

  private func DrawStrip(s: ref<TKHudStrip>, y: Float) -> Void {
    if !Equals(s.warn, s.warned) {
      if s.warn {
        this.Fixed(s.titleText, TKHud.Warning());
        this.Fixed(s.line, TKHud.Warning());
      } else {
        this.Paint(s.titleText, "accent");
        this.Paint(s.line, "accent");
      }
      s.warned = s.warn;
    }
    s.titleText.SetText(s.title);
    s.rightText.SetText(s.right);
    s.subText.SetText(s.sub);
    s.track.SetVisible(s.hasTarget);
    s.distText.SetVisible(s.hasTarget && s.showDistance);
    if s.hasTarget {
      let along = TKHud.Along(s.target);
      let tw = s.width - 80.0;
      s.marker.SetMargin(inkMargin(40.0 + along * (tw - 10.0), s.marker.GetMargin().top, 0.0, 0.0));
      s.leftArrow.SetVisible(along <= 0.0);
      s.rightArrow.SetVisible(along >= 1.0);
      let p = GetPlayer(this.GetGameInstance());
      if IsDefined(p) {
        let pos = p.GetWorldPosition();
        let dx = pos.X - s.target.X;
        let dy = pos.Y - s.target.Y;
        s.distText.SetText(TKGame.Distance(SqrtF(dx * dx + dy * dy)));
      }
    }
    s.bar.SetVisible(s.fraction >= 0.0);
    if s.fraction >= 0.0 {
      s.bar.SetSize(Vector2(s.width * ClampF(s.fraction, 0.0, 1.0), 4.0));
    }
    s.box.SetMargin(inkMargin(0.0, y, 0.0, 0.0));
    s.box.SetVisible(true);
  }

  private func StepToast(y: Float) -> Bool {
    if !IsDefined(this.m_toast) {
      return false;
    }
    let left = this.m_hideAt - this.Now();
    if this.m_hideAt <= 0.0 || left <= 0.0 {
      this.m_hideAt = 0.0;
      this.m_toast.SetVisible(false);
      return false;
    }
    this.m_toast.SetMargin(inkMargin(0.0, y, 0.0, 0.0));
    this.m_toastTime.SetSize(Vector2(this.m_toastW * left / this.m_length, 4.0));
    return true;
  }
}

public abstract class TKClock {

  public static func Now() -> Float = GameInstance.GetTimeSystem(GetGameInstance()).GetGameTimeStamp()

  public static func Left(secs: Float) -> String {
    let s = Max(0, CeilF(secs));
    if s >= 3600 {
      let m = (s % 3600) / 60;
      return IntToString(s / 3600) + "h " + (m < 10 ? "0" : "") + IntToString(m) + "m";
    }
    if s >= 60 {
      return IntToString(s / 60) + "m";
    }
    return IntToString(s) + "s";
  }
}

public class TKSheet extends IScriptable {
  public let head: String;
  public let cols: String;
  private let m_lines: array<String>;

  public static func Make(head: String, cols: String) -> ref<TKSheet> {
    let s = new TKSheet();
    s.head = head;
    s.cols = cols;
    return s;
  }

  public func Add(cells: String) -> Void { ArrayPush(this.m_lines, cells); }
  public func Count() -> Int32 = ArraySize(this.m_lines)
  public func Line(i: Int32) -> String = i >= 0 && i < ArraySize(this.m_lines) ? this.m_lines[i] : ""

  public func Sort(col: Int32, desc: Bool) -> Void {
    let n = ArraySize(this.m_lines);
    let i = 1;
    while i < n {
      let line = this.m_lines[i];
      let j = i - 1;
      while j >= 0 && TKSheet.After(this.m_lines[j], line, col, desc) {
        this.m_lines[j + 1] = this.m_lines[j];
        j -= 1;
      }
      this.m_lines[j + 1] = line;
      i += 1;
    }
  }

  public func Show(p: ref<TKPage>, col: Int32, desc: Bool, page: Int32, per: Int32, sortAction: String, pageAction: String, arg: String) -> Void {
    this.Sort(col, desc);
    p.SortHead(this.head, this.cols, col, desc, sortAction, arg);
    let n = ArraySize(this.m_lines);
    let pages = TKSheet.Pages(n, per);
    let at = Clamp(page, 0, pages - 1);
    let i = at * per;
    while i < n && i < (at + 1) * per {
      p.Ledger("line", this.m_lines[i], this.cols);
      i += 1;
    }
    if pages > 1 {
      p.Pager(at, pages, pageAction, arg);
    }
  }

  public static func Pages(count: Int32, per: Int32) -> Int32 = Max(1, (count + Max(1, per) - 1) / Max(1, per))

  private static func After(a: String, b: String, col: Int32, desc: Bool) -> Bool {
    let x = TKStr.Part(a, "|", col);
    let y = TKStr.Part(b, "|", col);
    let nx: Float;
    let ny: Float;
    let c: Int32;
    if TKSheet.Number(x, nx) && TKSheet.Number(y, ny) {
      c = nx > ny ? 1 : (nx < ny ? -1 : 0);
    } else {
      let d = StrCmp(StrLower(TKSheet.Bare(x)), StrLower(TKSheet.Bare(y)));
      c = d > 0 ? 1 : (d < 0 ? -1 : 0);
    }
    return desc ? c < 0 : c > 0;
  }

  private static func Bare(s: String) -> String {
    let m = StrLeft(s, 1);
    return Equals(m, "!") || Equals(m, "*") || Equals(m, "^") || Equals(m, "~") ? StrMid(s, 1, StrLen(s) - 1) : s;
  }

  private static func Number(s: String, out value: Float) -> Bool {
    let t = TKSheet.Bare(s);
    let digits = "";
    let seen = false;
    let i = 0;
    while i < StrLen(t) {
      let ch = StrMid(t, i, 1);
      if StrContains("0123456789", ch) {
        digits += ch;
        seen = true;
      } else {
        if Equals(ch, ".") || (Equals(ch, "-") && !seen) {
          digits += ch;
        }
      }
      i += 1;
    }
    if !seen {
      return false;
    }
    value = StringToFloat(digits, 0.0);
    return true;
  }
}

public class TKLogSystem extends ScriptableSystem {
  public let lines: array<String>;

  public static func Get() -> ref<TKLogSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"TerminalKit.TKLogSystem") as TKLogSystem
}

public abstract class TKLog {
  public static func Max() -> Int32 = 500

  public static func Add(tag: String, text: String) -> Void {
    let sys = TKLogSystem.Get();
    if !IsDefined(sys) {
      return;
    }
    ArrayPush(sys.lines, RedFunc.RealDate() + "  " + StrUpper(tag) + "  " + text);
    while ArraySize(sys.lines) > TKLog.Max() {
      ArrayErase(sys.lines, 0);
    }
  }

  public static func Lines() -> array<String> {
    let sys = TKLogSystem.Get();
    let none: array<String>;
    return IsDefined(sys) ? sys.lines : none;
  }

  public static func Clear() -> Void {
    let sys = TKLogSystem.Get();
    if IsDefined(sys) {
      ArrayClear(sys.lines);
    }
  }
}

public abstract class TKVersion {
  public static func Major() -> Int32 = 1
  public static func Minor() -> Int32 = 1
  public static func Text() -> String = "1.1"

  public static func AtLeast(major: Int32, minor: Int32) -> Bool {
    return TKVersion.Major() > major || (TKVersion.Major() == major && TKVersion.Minor() >= minor);
  }
}

public abstract class TKGame {
  public static func Player() -> ref<PlayerPuppet> = GetPlayer(GetGameInstance())

  public static func District() -> String {
    let rec = TKGame.DistrictRecord();
    return IsDefined(rec) ? GetLocalizedText(rec.LocalizedName()) : "";
  }

  public static func MainDistrict() -> String {
    let rec = TKGame.DistrictRecord();
    if !IsDefined(rec) {
      return "";
    }
    let parent = rec.ParentDistrict();
    return GetLocalizedText(IsDefined(parent) ? parent.LocalizedName() : rec.LocalizedName());
  }

  public static func DistrictRecord() -> ref<District_Record> {
    let player = TKGame.Player();
    if !IsDefined(player) {
      return null;
    }
    let prevention = GameInstance.GetScriptableSystemsContainer(player.GetGame()).Get(n"PreventionSystem") as PreventionSystem;
    if !IsDefined(prevention) {
      return null;
    }
    let district = prevention.GetCurrentDistrict();
    return IsDefined(district) ? district.GetDistrictRecord() : null;
  }

  public static func Money() -> Int32 {
    let player = TKGame.Player();
    return IsDefined(player) ? GameInstance.GetTransactionSystem(player.GetGame()).GetItemQuantity(player, MarketSystem.Money()) : 0;
  }

  public static func MoneyText(amount: Int32) -> String = TKGame.Group(amount) + " " + GetLocalizedText(UILocalizationKeys.Common_EuroDollar())

  public static func Group(n: Int32) -> String {
    let neg = n < 0;
    let digits = IntToString(neg ? -n : n);
    let out = "";
    let len = StrLen(digits);
    let i = 0;
    while i < len {
      if i > 0 && (len - i) % 3 == 0 {
        out += ",";
      }
      out += StrMid(digits, i, 1);
      i += 1;
    }
    return neg ? "-" + out : out;
  }

  public static func Level() -> Int32 = TKGame.Proficiency(gamedataProficiencyType.Level)
  public static func StreetCred() -> Int32 = TKGame.Proficiency(gamedataProficiencyType.StreetCred)

  private static func Proficiency(type: gamedataProficiencyType) -> Int32 {
    let player = TKGame.Player();
    if !IsDefined(player) {
      return 0;
    }
    let dev = PlayerDevelopmentSystem.GetInstance(player);
    return IsDefined(dev) ? dev.GetProficiencyLevel(player, type) : 0;
  }

  public static func Clock() -> String {
    let t = GameInstance.GetTimeSystem(GetGameInstance()).GetGameTime();
    return TKGame.Two(GameTime.Hours(t)) + ":" + TKGame.Two(GameTime.Minutes(t));
  }

  public static func Hour() -> Int32 = GameTime.Hours(GameInstance.GetTimeSystem(GetGameInstance()).GetGameTime())

  private static func Two(n: Int32) -> String = (n < 10 ? "0" : "") + IntToString(n)

  public static func Imperial() -> Bool = Equals(UILocalizationHelper.GetSystemBaseUnit(), EMeasurementUnit.Feet)

  public static func Distance(metres: Float) -> String {
    if TKGame.Imperial() {
      let feet = metres * 3.28084;
      return feet >= 5280.0 ? FloatToStringPrec(feet / 5280.0, 1) + " mi" : IntToString(RoundF(feet)) + " ft";
    }
    return metres >= 1000.0 ? FloatToStringPrec(metres / 1000.0, 1) + " km" : IntToString(RoundF(metres)) + " m";
  }

  public static func DistanceTo(pos: Vector4) -> Float {
    let player = TKGame.Player();
    return IsDefined(player) ? Vector4.Distance(player.GetWorldPosition(), pos) : 0.0;
  }
}

public abstract class TKNotify {

  public static func Warning(text: String, secs: Float, bad: Bool) -> Void {
    TKNotify.WarningOfType(text, secs, bad ? SimpleMessageType.Negative : SimpleMessageType.Neutral);
  }

  public static func WarningOfType(text: String, secs: Float, type: SimpleMessageType) -> Void {
    let msg: SimpleScreenMessage;
    msg.isShown = true;
    msg.duration = secs > 0.0 ? secs : 5.0;
    msg.message = text;
    msg.type = type;
    TKNotify.Post(GetAllBlackboardDefs().UI_Notifications.WarningMessage, msg);
  }

  public static func Onscreen(text: String, secs: Float) -> Void {
    let msg: SimpleScreenMessage;
    msg.isShown = true;
    msg.duration = secs > 0.0 ? secs : 4.0;
    msg.message = text;
    TKNotify.Post(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, msg);
  }

  public static func Side(title: String) -> Void {
    let evt = new UIInGameNotificationEvent();
    evt.m_notificationType = UIInGameNotificationType.GenericNotification;
    evt.m_title = title;
    GameInstance.GetUISystem(GetGameInstance()).QueueEvent(evt);
  }

  public static func Quest(header: String, text: String) -> Void {
    let data: CustomQuestNotificationData;
    data.header = header;
    data.desc = text;
    let bb = GameInstance.GetBlackboardSystem(GetGameInstance()).Get(GetAllBlackboardDefs().UI_CustomQuestNotification);
    if IsDefined(bb) {
      bb.SetVariant(GetAllBlackboardDefs().UI_CustomQuestNotification.data, ToVariant(data), true);
    }
  }

  private static func Post(id: BlackboardID_Variant, msg: SimpleScreenMessage) -> Void {
    let bb = GameInstance.GetBlackboardSystem(GetGameInstance()).Get(GetAllBlackboardDefs().UI_Notifications);
    if IsDefined(bb) {
      bb.SetVariant(id, ToVariant(msg), true);
    }
  }
}

public abstract class TKPins {
  public static func Get() -> ref<TKPinSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"TerminalKit.TKPinSystem") as TKPinSystem

  public static func Add(key: String, pos: Vector4) -> Void {
    TKPins.AddAs(key, pos, gamedataMappinVariant.CustomPositionVariant);
  }

  public static func AddAs(key: String, pos: Vector4, variant: gamedataMappinVariant) -> Void {
    let sys = TKPins.Get();
    if IsDefined(sys) {
      sys.Put(key, pos, variant);
    }
  }

  public static func Move(key: String, pos: Vector4) -> Void {
    let sys = TKPins.Get();
    if IsDefined(sys) {
      sys.Move(key, pos);
    }
  }

  public static func Show(key: String, on: Bool) -> Void {
    let sys = TKPins.Get();
    if IsDefined(sys) {
      sys.Show(key, on);
    }
  }

  public static func Remove(key: String) -> Void {
    let sys = TKPins.Get();
    if IsDefined(sys) {
      sys.Remove(key);
    }
  }

  public static func RemoveAll(prefix: String) -> Void {
    let sys = TKPins.Get();
    if IsDefined(sys) {
      sys.RemoveAll(prefix);
    }
  }

  public static func Has(key: String) -> Bool {
    let sys = TKPins.Get();
    return IsDefined(sys) && sys.Find(key) >= 0;
  }

  public static func Position(key: String, out pos: Vector4) -> Bool {
    let sys = TKPins.Get();
    return IsDefined(sys) && sys.Where(key, pos);
  }
}

public class TKPinSystem extends ScriptableSystem {
  private let m_keys: array<String>;
  private let m_ids: array<NewMappinID>;
  private let m_positions: array<Vector4>;

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    ArrayClear(this.m_keys);
    ArrayClear(this.m_ids);
    ArrayClear(this.m_positions);
  }

  private func Mappins() -> ref<MappinSystem> = GameInstance.GetMappinSystem(this.GetGameInstance())

  public func Find(key: String) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_keys) {
      if Equals(this.m_keys[i], key) {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func Put(key: String, pos: Vector4, variant: gamedataMappinVariant) -> Void {
    let i = this.Find(key);
    if i >= 0 {
      this.Mappins().ChangeMappinVariant(this.m_ids[i], variant);
      this.Move(key, pos);
      return;
    }
    let data: MappinData;
    data.mappinType = t"Mappins.QuestStaticMappinDefinition";
    data.variant = variant;
    data.active = true;
    data.visibleThroughWalls = true;
    ArrayPush(this.m_keys, key);
    ArrayPush(this.m_ids, this.Mappins().RegisterMappin(data, pos));
    ArrayPush(this.m_positions, pos);
  }

  public func Move(key: String, pos: Vector4) -> Void {
    let i = this.Find(key);
    if i >= 0 {
      this.Mappins().SetMappinPosition(this.m_ids[i], pos);
      this.m_positions[i] = pos;
    }
  }

  public func Show(key: String, on: Bool) -> Void {
    let i = this.Find(key);
    if i >= 0 {
      this.Mappins().SetMappinActive(this.m_ids[i], on);
    }
  }

  public func Remove(key: String) -> Void {
    let i = this.Find(key);
    if i >= 0 {
      this.Mappins().UnregisterMappin(this.m_ids[i]);
      ArrayErase(this.m_keys, i);
      ArrayErase(this.m_ids, i);
      ArrayErase(this.m_positions, i);
    }
  }

  public func RemoveAll(prefix: String) -> Void {
    let i = ArraySize(this.m_keys) - 1;
    while i >= 0 {
      if StrBeginsWith(this.m_keys[i], prefix) {
        this.Remove(this.m_keys[i]);
      }
      i -= 1;
    }
  }

  public func Where(key: String, out pos: Vector4) -> Bool {
    let i = this.Find(key);
    if i < 0 {
      return false;
    }
    pos = this.m_positions[i];
    return true;
  }
}
