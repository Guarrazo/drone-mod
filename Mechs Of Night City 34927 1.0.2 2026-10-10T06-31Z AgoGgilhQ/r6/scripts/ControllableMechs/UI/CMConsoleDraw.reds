module ControllableMechs

import TerminalKit.*

public abstract class CMConPal {
  public static func C(r: Int32, g: Int32, b: Int32) -> HDRColor = new HDRColor(Cast<Float>(r) / 255.0, Cast<Float>(g) / 255.0, Cast<Float>(b) / 255.0, 1.0)
  public static func Bg() -> HDRColor = CMConPal.C(6, 8, 9)
  public static func Panel() -> HDRColor = CMConPal.C(12, 17, 18)
  public static func Panel2() -> HDRColor = CMConPal.C(17, 24, 25)
  public static func Line() -> HDRColor = CMConPal.C(36, 49, 47)
  public static func Line2() -> HDRColor = CMConPal.C(53, 72, 74)
  public static func Steel() -> HDRColor = CMConPal.C(142, 161, 158)
  public static func Ink() -> HDRColor = CMConPal.C(223, 231, 227)
  public static func Amber() -> HDRColor = CMConPal.C(242, 181, 27)
  public static func Cyan() -> HDRColor = CMConPal.C(63, 221, 230)
  public static func Red() -> HDRColor = CMConPal.C(255, 74, 61)
  public static func Green() -> HDRColor = CMConPal.C(134, 227, 107)
  public static func Tag() -> HDRColor = CMConPal.C(11, 16, 17)

  public static func State(st: String) -> HDRColor {
    switch st {
      case "ok": return CMConPal.Green();
      case "live": return CMConPal.Cyan();
      case "warn": return CMConPal.Amber();
      case "crit": return CMConPal.Red();
    }
    return CMConPal.Steel();
  }

  public static func Health(h: Float) -> HDRColor {
    if h < 0.35 {
      return CMConPal.Red();
    }
    if h < 0.8 {
      return CMConPal.Amber();
    }
    return CMConPal.Cyan();
  }
}

public class CMRobotLinkPalette extends TKPalette {
  public func Id() -> String = "cm_robotlink"
  public func Color(role: String) -> HDRColor {
    switch role {
      case "title": return CMConPal.Amber();
      case "accent": return CMConPal.Amber();
      case "text": return CMConPal.Ink();
      case "rule": return CMConPal.Line();
      case "frame": return CMConPal.Line2();
    }
    return CMConPal.Cyan();
  }
}

public class CMConScale extends TKScaleSource {
  public func Value(key: String, def: Float) -> Float {
    switch key {
      case "region.pad": return 0.0;
      case "region.fill": return 0.0;
      case "region.gap": return 18.0;
      case "layout.top": return 30.0;
      case "layout.foot": return 30.0;
      case "tip.w": return 400.0;
    }
    return def;
  }
}

public class CMHoverGlow extends IScriptable {
  public let frame: array<ref<inkRectangle>>;
  public let glow: ref<inkRectangle>;
  public let base: HDRColor;

  public static func Attach(area: ref<inkWidget>, frame: array<ref<inkRectangle>>, glow: ref<inkRectangle>, base: HDRColor) -> ref<CMHoverGlow> {
    let g = new CMHoverGlow();
    g.frame = frame;
    g.glow = glow;
    g.base = base;
    area.RegisterToCallback(n"OnHoverOver", g, n"OnOver");
    area.RegisterToCallback(n"OnHoverOut", g, n"OnOut");
    return g;
  }

  protected cb func OnOver(e: ref<inkPointerEvent>) -> Bool {
    CMCon.Tint(this.frame, CMConPal.Cyan());
    if IsDefined(this.glow) {
      this.glow.SetOpacity(0.12);
    }
    return false;
  }

  protected cb func OnOut(e: ref<inkPointerEvent>) -> Bool {
    CMCon.Tint(this.frame, this.base);
    if IsDefined(this.glow) {
      this.glow.SetOpacity(0.0);
    }
    return false;
  }
}

public abstract class CMCon {
  public static func Body() -> String = "base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily"
  public static func Data() -> String = "base\\gameplay\\gui\\fonts\\industry\\industry.inkfontfamily"

  public static func Txt(root: ref<inkCanvas>, x: Float, y: Float, text: String, font: Int32, size: Int32, c: HDRColor, align: Int32) -> ref<inkText> {
    let t = new inkText();
    switch font {

      case 0:
        t.SetFontFamily(CMCon.Body());
        t.SetFontStyle(n"Semi-Bold");
        break;
      case 2:
        t.SetFontFamily(CMCon.Data());
        t.SetFontStyle(n"Demi");
        break;
      default:
        t.SetFontFamily(CMCon.Body());
        t.SetFontStyle(n"Semi-Bold");
        break;
    }
    t.SetFontSize(size);
    t.SetLetterCase(textLetterCase.UpperCase);
    t.SetTintColor(c);
    t.SetText(text);
    t.SetAnchor(inkEAnchor.TopLeft);
    t.SetAnchorPoint(Vector2(align == 1 ? 0.5 : (align == 2 ? 1.0 : 0.0), 0.0));
    t.SetMargin(inkMargin(x, y, 0.0, 0.0));
    t.SetInteractive(false);
    t.Reparent(root);
    return t;
  }

  public static func Note(root: ref<inkCanvas>, x: Float, y: Float, w: Float, text: String, size: Int32, c: HDRColor) -> ref<inkText> {
    let t = CMCon.Txt(root, x, y, text, 1, size, c, 0);
    t.SetLetterCase(textLetterCase.OriginalCase);
    t.SetWrapping(true, w);
    return t;
  }

  public static func Rect(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, c: HDRColor, op: Float) -> ref<inkRectangle> {
    let r = new inkRectangle();
    r.SetMargin(inkMargin(x, y, 0.0, 0.0));
    r.SetSize(Vector2(MaxF(w, 0.0), MaxF(h, 0.0)));
    r.SetTintColor(c);
    r.SetOpacity(op);
    r.SetInteractive(false);
    r.Reparent(root);
    return r;
  }

  public static func Frame(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, t: Float, c: HDRColor, op: Float) -> array<ref<inkRectangle>> {
    let out: array<ref<inkRectangle>>;
    ArrayPush(out, CMCon.Rect(root, x, y, w, t, c, op));
    ArrayPush(out, CMCon.Rect(root, x, y + h - t, w, t, c, op));
    ArrayPush(out, CMCon.Rect(root, x, y, t, h, c, op));
    ArrayPush(out, CMCon.Rect(root, x + w - t, y, t, h, c, op));
    return out;
  }

  public static func Tint(ws: array<ref<inkRectangle>>, c: HDRColor) -> Void {
    for w in ws {
      w.SetTintColor(c);
    }
  }

  public static func Dashed(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, c: HDRColor, op: Float) -> Void {
    let dash = 16.0;
    let gap = 10.0;
    let a = 0.0;
    while a < w {
      let l = MinF(dash, w - a);
      CMCon.Rect(root, x + a, y, l, 2.0, c, op);
      CMCon.Rect(root, x + a, y + h - 2.0, l, 2.0, c, op);
      a += dash + gap;
    }
    a = 0.0;
    while a < h {
      let l = MinF(dash, h - a);
      CMCon.Rect(root, x, y + a, 2.0, l, c, op);
      CMCon.Rect(root, x + w - 2.0, y + a, 2.0, l, c, op);
      a += dash + gap;
    }
  }

  public static func Fill() -> Float = 0.5
  public static func Fill2() -> Float = 0.65

  public static func Pane(root: ref<inkCanvas>, w: Float, h: Float, cut: Bool) -> Void {
    CMCon.Rect(root, 0.0, 0.0, w, h, CMConPal.Panel(), CMCon.Fill());
    CMCon.Frame(root, 0.0, 0.0, w, h, 2.0, CMConPal.Line(), 1.0);
  }

  public static func Scan(root: ref<inkCanvas>, w: Float, h: Float) -> Void {
  }

  public static func Segs(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, v: Float, c: HDRColor) -> array<ref<inkRectangle>> {
    let out: array<ref<inkRectangle>>;
    let gap = 4.0;
    let cw = (w - gap * 9.0) / 10.0;
    let lit = RoundF(ClampF(v, 0.0, 1.0) * 10.0);
    let i = 0;
    while i < 10 {
      ArrayPush(out, CMCon.Rect(root, x + Cast<Float>(i) * (cw + gap), y, cw, h, i < lit ? c : CMConPal.Line2(), 1.0));
      i += 1;
    }
    return out;
  }

  public static func SetSegs(cells: array<ref<inkRectangle>>, v: Float, c: HDRColor) -> Void {
    let lit = RoundF(ClampF(v, 0.0, 1.0) * Cast<Float>(ArraySize(cells)));
    let i = 0;
    while i < ArraySize(cells) {
      cells[i].SetTintColor(i < lit ? c : CMConPal.Line2());
      i += 1;
    }
  }

  public static func Stamp(root: ref<inkCanvas>, x: Float, y: Float, text: String, c: HDRColor, size: Int32) -> Float {
    let w = CMCon.TextW(text, size) + 24.0;
    let h = Cast<Float>(size) + 12.0;
    CMCon.Frame(root, x, y, w, h, 2.0, c, 1.0);
    CMCon.Txt(root, x + 12.0, y + 4.0, text, 2, size, c, 0);
    return w;
  }

  public static func TextW(text: String, size: Int32) -> Float = Cast<Float>(StrLen(text)) * Cast<Float>(size) * 0.56

  public static func Ring(root: ref<inkCanvas>, cx: Float, cy: Float, r: Float, thick: Float, v: Float, c: HDRColor) -> Void {
    let segs = CMInk.Ring(root, cx, cy, r, 72, thick, CMConPal.Line(), 1.0);
    let lit = RoundF(ClampF(v, 0.0, 1.0) * 72.0);
    let i = 0;
    while i < ArraySize(segs) {
      if i < lit {
        segs[i].SetTintColor(c);
      }
      i += 1;
    }
  }

  public static func Key(root: ref<inkCanvas>, x: Float, y: Float, key: String, c: HDRColor) -> Float {
    let w = MaxF(60.0, CMCon.TextW(key, 26) + 28.0);
    CMCon.Rect(root, x, y, w, 60.0, CMConPal.Panel(), CMCon.Fill());
    CMCon.Frame(root, x, y, w, 60.0, 2.0, CMConPal.Steel(), 1.0);
    CMCon.Rect(root, x, y + 54.0, w, 6.0, CMConPal.Steel(), 1.0);
    CMCon.Txt(root, x + w * 0.5, y + 12.0, key, 2, 26, c, 1);
    return w;
  }

  public static func Box(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float) -> ref<inkCanvas> {
    let b = new inkCanvas();
    b.SetMargin(inkMargin(x, y, 0.0, 0.0));
    b.SetSize(Vector2(w, h));
    b.Reparent(root);
    return b;
  }

  public static func HitArea(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float) -> ref<inkRectangle> {
    let r = CMCon.Rect(root, x, y, w, h, CMConPal.Bg(), 0.001);
    r.SetInteractive(true);
    return r;
  }

  public static func Money(n: Int32) -> String {
    let s = IntToString(Abs(n));
    let out = "";
    let i = StrLen(s);
    let k = 0;
    while i > 0 {
      out = StrMid(s, i - 1, 1) + out;
      k += 1;
      i -= 1;
      if k % 3 == 0 && i > 0 {
        out = "," + out;
      }
    }
    return (n < 0 ? "-" : "") + out;
  }

  public static func Pct(h: Float) -> String = IntToString(RoundF(ClampF(h, 0.0, 1.0) * 100.0)) + "%"
}
