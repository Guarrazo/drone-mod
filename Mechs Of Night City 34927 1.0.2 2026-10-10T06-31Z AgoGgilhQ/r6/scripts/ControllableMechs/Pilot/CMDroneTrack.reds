module ControllableMechs

public class CMDroneContact {
  public let ent: wref<GameObject>;
  public let id: EntityID;
  public let kind: Int32;
  public let machine: Bool;
  public let armed: Bool;
  public let combat: Bool;
  public let pos: Vector4;
  public let vel: Vector4;
  public let dist: Float;
  public let scr: Vector2;
  public let tag: Int32;
  public let hp: Float;
  public let seen: Float;

  public static func KindName(k: Int32) -> String {
    switch k {
      case 0: return CMText.TrkOperator();
      case 1: return CMText.TrkCivilian();
      case 2: return CMText.TrkHostile();
      case 4: return CMText.TrkFriendly();
    }
    return CMText.TrkNeutral();
  }

  public func Label() -> String {
    if this.kind == 0 {
      return CMText.TrkVOperator();
    }
    let s = CMDroneContact.KindName(this.kind);
    if this.machine {
      return CMText.TrkMachine(s);
    }
    if this.armed && this.kind != 1 {
      return CMText.TrkArmed(s);
    }
    return s;
  }

  public func LabelName() -> String = this.kind == 0 ? CMText.TrkV() : CMDroneContact.KindName(this.kind)

  public func LabelRole() -> String {
    if this.kind == 0 {
      return CMText.TrkOperatorRole();
    }
    if this.machine {
      return CMText.TrkMachineRole();
    }
    return this.armed && this.kind != 1 ? CMText.TrkArmedRole() : "";
  }

  public func Tag() -> String = this.tag <= 0 ? "C-??" : "C-" + (this.tag < 10 ? "0" : "") + IntToString(this.tag)

  public func OnScreen() -> Bool = AbsF(this.scr.X) < 1880.0 && AbsF(this.scr.Y) < 1040.0
}

public class CMDroneTrack {
  public let contacts: array<ref<CMDroneContact>>;
  public let lock: ref<CMDroneContact>;
  public let lead: Vector2;
  public let leadOn: Bool;
  public let scan: Float;
  public let tagged: Int32;
  public let hostiles: Int32;
  public let detected: Int32;
  public let pos: Vector4;
  public let aim: Vector4;
  public let aimOk: Bool;
  public let yaw: Float;
  public let camPitch: Float;
  public let fov: Float;
  public let hold: Bool;
  public let pingLeft: Float;
  public let rounds: Int32;
  public let hits: Int32;
  public let now: Float;
  public let slow: Bool;
  public let slowAt: Float;

  public let blastR: Float;
  public let armed: Bool;
  public let ring: array<Vector2>;
  public let ringOk: Bool;
  public let tti: Float;
  public let motors: array<Float>;

  public let tof: Float;
  public let foot: array<Vector4>;
  public let footOk: Bool;
}

@addField(inkWidget)
public let cmSegKey: Vector4;

@addField(inkWidget)
public let cmSegThick: Float;

@addField(inkText)
public let cmTextKey: String;

public abstract class CMInk {

  public static func Text(t: ref<inkText>, s: String) -> Void {
    if !IsDefined(t) {
      return;
    }
    if StrLen(s) > 0 && Equals(t.cmTextKey, s) {
      return;
    }
    t.cmTextKey = s;
    t.SetText(s);
  }

  public static func Glass() -> HDRColor = new HDRColor(0.004, 0.018, 0.012, 1.0)
  public static func GlassOp() -> Float = 0.82

  public static func FillBars(root: ref<inkCanvas>, n: Int32, c: HDRColor, op: Float) -> array<ref<inkRectangle>> {
    let out: array<ref<inkRectangle>>;
    let i = 0;
    while i < n {
      let b = CMPilotHud.Bar(root, 0.0, 0.0, 1.0, 1.0, c, op);
      b.SetVisible(false);
      ArrayPush(out, b);
      i += 1;
    }
    return out;
  }

  public static func FanSegs(root: ref<inkCanvas>, n: Int32, c: HDRColor, op: Float) -> array<ref<inkImage>> {
    let out: array<ref<inkImage>>;
    let i = 0;
    while i < n {
      let s = CMKit.Img(root, n"pill_h", 0.0, 0.0, 4.0, 3.0, c, op);
      s.SetVisible(false);
      ArrayPush(out, s);
      i += 1;
    }
    return out;
  }

  public static func FillFan(segs: array<ref<inkImage>>, on: Bool, a: Vector2, b: Vector2, c: Vector2, thick: Float) -> Void {
    let n = ArraySize(segs);
    let i = 0;
    while i < n {
      let s = segs[i];
      s.SetVisible(on);
      if on {
        let t = n > 1 ? Cast<Float>(i) / Cast<Float>(n - 1) : 0.5;
        CMInk.Seg(s, a.X, a.Y, b.X + (c.X - b.X) * t, b.Y + (c.Y - b.Y) * t, thick);
      }
      i += 1;
    }
  }
  public static func FillPoly(bars: array<ref<inkRectangle>>, pts: array<Vector2>) -> Void {
    let n = ArraySize(bars);
    let m = ArraySize(pts);
    if n == 0 || m < 3 {
      for b in bars {
        b.SetVisible(false);
      }
      return;
    }
    let y0 = pts[0].Y;
    let y1 = pts[0].Y;
    for p in pts {
      y0 = MinF(y0, p.Y);
      y1 = MaxF(y1, p.Y);
    }
    let h = (y1 - y0) / Cast<Float>(n);
    let i = 0;
    while i < n {
      let y = y0 + (Cast<Float>(i) + 0.5) * h;
      let lo = 99999.0;
      let hi = -99999.0;
      let j = 0;
      while j < m {
        let a = pts[j];
        let b = pts[(j + 1) % m];
        if (a.Y <= y && b.Y > y) || (b.Y <= y && a.Y > y) {
          let x = a.X + (y - a.Y) / (b.Y - a.Y) * (b.X - a.X);
          lo = MinF(lo, x);
          hi = MaxF(hi, x);
        }
        j += 1;
      }
      let bar = bars[i];
      if hi > lo {
        bar.SetVisible(true);
        bar.SetMargin(inkMargin(lo, y0 + Cast<Float>(i) * h, 0.0, 0.0));
        bar.SetSize(Vector2(hi - lo, h + 0.6));
      } else {
        bar.SetVisible(false);
      }
      i += 1;
    }
  }

  public static func Ring(root: ref<inkCanvas>, cx: Float, cy: Float, r: Float, segs: Int32, thick: Float, c: HDRColor, op: Float) -> array<ref<inkWidget>> {
    let out: array<ref<inkWidget>>;
    let len = 6.2832 * r / Cast<Float>(segs);
    let i = 0;
    while i < segs {
      let a0 = Deg2Rad(Cast<Float>(i) / Cast<Float>(segs) * 360.0);
      let a1 = Deg2Rad(Cast<Float>(i + 1) / Cast<Float>(segs) * 360.0);
      let b = CMKit.Stroke(root, c, op);
      CMInk.Seg(b, cx + SinF(a0) * r, cy - CosF(a0) * r, cx + SinF(a1) * r, cy - CosF(a1) * r, thick);
      ArrayPush(out, b);
      i += 1;
    }
    return out;
  }

  public static func Circle(root: ref<inkCanvas>, cx: Float, cy: Float, r: Float, c: HDRColor, op: Float) -> ref<inkImage> {
    let part = r <= 40.0 ? n"ring_s" : (r <= 170.0 ? n"ring_m" : n"ring_l");
    return CMKit.Img(root, part, cx - r, cy - r, r * 2.0, r * 2.0, c, op);
  }

  public static func Seg(b: ref<inkWidget>, x1: Float, y1: Float, x2: Float, y2: Float, thick: Float) -> Void {
    let k = b.cmSegKey;
    if b.cmSegThick == thick && AbsF(k.X - x1) < 0.5 && AbsF(k.Y - y1) < 0.5 && AbsF(k.Z - x2) < 0.5 && AbsF(k.W - y2) < 0.5 {
      return;
    }
    b.cmSegKey = Vector4(x1, y1, x2, y2);
    b.cmSegThick = thick;
    let dx = x2 - x1;
    let dy = y2 - y1;
    let len = SqrtF(dx * dx + dy * dy) + thick;
    b.SetRenderTransformPivot(Vector2(0.5, 0.5));
    b.SetMargin(inkMargin((x1 + x2) * 0.5 - len * 0.5, (y1 + y2) * 0.5 - thick * 0.5, 0.0, 0.0));
    b.SetSize(Vector2(len, thick));
    b.SetRotation(Rad2Deg(AtanF(dy, dx)));
  }

  public static func Line(root: ref<inkCanvas>, x1: Float, y1: Float, x2: Float, y2: Float, thick: Float, c: HDRColor, op: Float) -> ref<inkWidget> {
    let b = CMKit.Stroke(root, c, op);
    CMInk.Seg(b, x1, y1, x2, y2, thick);
    return b;
  }

  public static func Diamond(root: ref<inkCanvas>, s: Float, c: HDRColor) -> ref<inkCanvas> {
    let d = new inkCanvas();
    d.SetSize(Vector2(s, s));
    d.SetRenderTransformPivot(Vector2(0.5, 0.5));
    d.Reparent(root);
    CMKit.Img(d, n"diamond_line", 0.0, 0.0, s, s, c, 1.0);
    return d;
  }

  public static func Chevron(root: ref<inkCanvas>, s: Float, thick: Float, c: HDRColor) -> ref<inkCanvas> {
    let v = new inkCanvas();
    v.SetSize(Vector2(s, s));
    v.SetRenderTransformPivot(Vector2(0.5, 0.5));
    v.Reparent(root);
    CMKit.Img(v, n"chevron", 0.0, s * 0.2, s, s * 0.625, c, 1.0);
    return v;
  }

  public static func KindColor(k: Int32, acc: HDRColor) -> HDRColor {
    switch k {
      case 0: return new HDRColor(0.60, 1.10, 0.66, 1.0);
      case 2: return CMPilotHud.Caution();
      case 4: return new HDRColor(0.45, 0.85, 1.15, 1.0);
      case 3: return new HDRColor(0.85, 0.88, 0.86, 1.0);
    }
    return acc;
  }

  public static func Clock(t: Float) -> String {
    let secs = FloorF(t);
    let mm = secs / 60;
    let ss = secs % 60;
    return (mm < 10 ? "0" : "") + IntToString(mm) + ":" + (ss < 10 ? "0" : "") + IntToString(ss);
  }

  public static func Hdg(h: Float) -> Int32 {
    let d = RoundF(h) % 360;
    return d < 0 ? d + 360 : d;
  }
}

public abstract class CMKit {
  public static func Atlas() -> ResRef = r"mnc\\hud\\ui_kit.inkatlas"

  public static func Img(root: ref<inkCanvas>, part: CName, x: Float, y: Float, w: Float, h: Float, c: HDRColor, op: Float) -> ref<inkImage> {
    let img = new inkImage();
    img.SetAtlasResource(CMKit.Atlas());
    img.SetTexturePart(part);
    img.SetMargin(inkMargin(x, y, 0.0, 0.0));
    img.SetSize(Vector2(w, h));
    img.SetTintColor(c);
    img.SetOpacity(op);
    img.SetInteractive(false);
    img.Reparent(root);
    return img;
  }

  public static func Nine(root: ref<inkCanvas>, part: CName, grid: inkMargin, x: Float, y: Float, w: Float, h: Float, c: HDRColor, op: Float) -> ref<inkImage> {
    let img = CMKit.Img(root, part, x, y, w, h, c, op);
    img.SetNineSliceScale(true);
    img.SetNineSliceGrid(grid);
    return img;
  }

  public static func Pill(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, c: HDRColor, op: Float) -> ref<inkImage> = CMKit.Nine(root, n"pill_h", inkMargin(8.0, 0.0, 8.0, 0.0), x, y, w, h, c, op)
  public static func VPill(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, c: HDRColor, op: Float) -> ref<inkImage> = CMKit.Nine(root, n"pill_v", inkMargin(0.0, 8.0, 0.0, 8.0), x, y, w, h, c, op)

  public static func Stroke(root: ref<inkCanvas>, c: HDRColor, op: Float) -> ref<inkImage> = CMKit.Img(root, n"pill_h", 0.0, 0.0, 4.0, 3.0, c, op)

  public static func Panel(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, line: HDRColor, lineOp: Float) -> Void {
    CMKit.Nine(root, n"rrect_fill", inkMargin(14.0, 14.0, 14.0, 14.0), x, y, w, h, CMInk.Glass(), CMInk.GlassOp());
    CMKit.Nine(root, n"rrect_line", inkMargin(14.0, 14.0, 14.0, 14.0), x, y, w, h, line, lineOp);
  }
  public static func Box(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, line: HDRColor, lineOp: Float) -> ref<inkImage> {
    CMKit.Nine(root, n"rrect_fill_s", inkMargin(7.0, 7.0, 7.0, 7.0), x, y, w, h, CMInk.Glass(), CMInk.GlassOp());
    return CMKit.Nine(root, n"rrect_line_s", inkMargin(7.0, 7.0, 7.0, 7.0), x, y, w, h, line, lineOp);
  }
  public static func Fill(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, c: HDRColor, op: Float) -> ref<inkImage> = CMKit.Nine(root, n"rrect_fill_s", inkMargin(7.0, 7.0, 7.0, 7.0), x, y, w, h, c, op)

  public static func Disc(root: ref<inkCanvas>, cx: Float, cy: Float, r: Float, c: HDRColor, op: Float) -> ref<inkImage> = CMKit.Img(root, n"disc", cx - r, cy - r, r * 2.0, r * 2.0, c, op)

  public static func Place(img: ref<inkWidget>, cx: Float, cy: Float, r: Float) -> Void {
    img.SetMargin(inkMargin(cx - r, cy - r, 0.0, 0.0));
    img.SetSize(Vector2(r * 2.0, r * 2.0));
  }

  public static func Ln(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, c: HDRColor, op: Float) -> ref<inkImage> {
    if MaxF(w, h) < 24.0 {

      return CMKit.Img(root, w >= h ? n"pill_h" : n"pill_v", x, y, w, h, c, op);
    }
    if w >= h {
      return CMKit.Pill(root, x, y, w, h, c, op);
    }
    return CMKit.VPill(root, x, y, w, h, c, op);
  }

  public static func Corners(root: ref<inkCanvas>, c: HDRColor, op: Float, big: Bool) -> array<ref<inkImage>> {
    let out: array<ref<inkImage>>;
    let i = 0;
    while i < 4 {
      let img = CMKit.Img(root, big ? n"corner_l" : n"corner", 0.0, 0.0, 26.0, 26.0, c, op);
      img.SetRenderTransformPivot(Vector2(0.5, 0.5));
      img.SetRotation(Cast<Float>(i) * 90.0);
      ArrayPush(out, img);
      i += 1;
    }
    return out;
  }

  public static func PlaceCorners(cs: array<ref<inkImage>>, at: Int32, x: Float, y: Float, w: Float, h: Float, L: Float) -> Void {
    if at + 3 >= ArraySize(cs) {
      return;
    }
    let xs = [x, x + w - L, x + w - L, x];
    let ys = [y, y, y + h - L, y + h - L];
    let i = 0;
    while i < 4 {
      let img = cs[at + i];
      img.SetMargin(inkMargin(xs[i], ys[i], 0.0, 0.0));
      img.SetSize(Vector2(L, L));
      i += 1;
    }
  }

  public static func ShowCorners(cs: array<ref<inkImage>>, at: Int32, on: Bool, c: HDRColor) -> Void {
    let i = 0;
    while i < 4 && at + i < ArraySize(cs) {
      cs[at + i].SetVisible(on);
      cs[at + i].SetTintColor(c);
      i += 1;
    }
  }

  public static func Brackets(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, L: Float, c: HDRColor, op: Float) -> Void {
    let cs = CMKit.Corners(root, c, op, L > 60.0);
    CMKit.PlaceCorners(cs, 0, x, y, w, h, L);
  }

  public static func Vignette(root: ref<inkCanvas>, W: Float, H: Float, depth: Float, op: Float) -> Void {
    let k = new HDRColor(0.0, 0.0, 0.0, 1.0);
    CMKit.Img(root, n"fade", 0.0, 0.0, W, depth, k, op);
    let b = CMKit.Img(root, n"fade", 0.0, H - depth, W, depth, k, op);
    b.SetRenderTransformPivot(Vector2(0.5, 0.5));
    b.SetRotation(180.0);

    let l = CMKit.Img(root, n"fade", depth * 0.5 - H * 0.5, H * 0.5 - depth * 0.5, H, depth, k, op);
    l.SetRenderTransformPivot(Vector2(0.5, 0.5));
    l.SetRotation(-90.0);
    let r = CMKit.Img(root, n"fade", W - depth * 0.5 - H * 0.5, H * 0.5 - depth * 0.5, H, depth, k, op);
    r.SetRenderTransformPivot(Vector2(0.5, 0.5));
    r.SetRotation(90.0);
  }
}

public class CMSlider {
  public let track: ref<inkImage>;
  public let fill: ref<inkImage>;
  private let x: Float;
  private let y: Float;
  private let w: Float;
  private let h: Float;
  private let vertical: Bool;

  public static func Make(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, vertical: Bool, c: HDRColor) -> ref<CMSlider> {
    let s = new CMSlider();
    s.x = x;
    s.y = y;
    s.w = w;
    s.h = h;
    s.vertical = vertical;
    s.track = vertical ? CMKit.VPill(root, x, y, w, h, c, 0.18) : CMKit.Pill(root, x, y, w, h, c, 0.18);
    s.fill = vertical ? CMKit.VPill(root, x, y, w, h, c, 1.0) : CMKit.Pill(root, x, y, w, h, c, 1.0);
    return s;
  }

  public func Set(f: Float, c: HDRColor) -> Void {
    let v = ClampF(f, 0.0, 1.0);
    this.fill.SetVisible(v > 0.005);
    this.fill.SetTintColor(c);
    this.track.SetTintColor(c);
    if this.vertical {
      let len = MaxF(this.w, this.h * v);
      this.fill.SetMargin(inkMargin(this.x, this.y + this.h - len, 0.0, 0.0));
      this.fill.SetSize(Vector2(this.w, len));
    } else {
      let len = MaxF(this.h, this.w * v);
      this.fill.SetMargin(inkMargin(this.x, this.y, 0.0, 0.0));
      this.fill.SetSize(Vector2(len, this.h));
    }
  }
}
