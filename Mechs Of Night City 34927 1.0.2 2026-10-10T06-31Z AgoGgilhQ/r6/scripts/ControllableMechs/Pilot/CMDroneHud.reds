module ControllableMechs

import Codeware.UI.ScreenHelper
import ControllableMechs.Control.*

public class CMDroneHud extends CMPilotHud {
  private let m_kind: String;
  private let m_droot: ref<inkCanvas>;
  private let m_dparent: wref<inkCompoundWidget>;
  private let m_dhidden: array<wref<inkWidget>>;
  private let m_dhiddenOp: array<Float>;
  private let m_W: Float;
  private let m_bootLeft: Float;

  private let m_hdgTicks: array<ref<inkImage>>;
  private let m_hdgLabels: array<ref<inkText>>;
  private let m_hdgBox: ref<inkText>;
  private let m_speedText: ref<inkText>;
  private let m_altText: ref<inkText>;
  private let m_vsText: ref<inkText>;
  private let m_lrf: ref<inkText>;
  private let m_name: ref<inkText>;
  private let m_cross: ref<inkCanvas>;
  private let m_holdT: ref<inkText>;
  private let m_holdBox: ref<inkCanvas>;
  private let m_windT: ref<inkText>;
  private let m_warnT: ref<inkText>;
  private let m_schemParts: array<ref<inkWidget>>;
  private let m_flashT: Float;

  private let m_ocMts: ref<inkText>;
  private let m_ocSensor: String;
  private let m_ocZoomed: Bool;
  private let m_ocLinkPct: ref<inkText>;
  private let m_ocLinkRng: ref<inkText>;
  private let m_ocRecDot: ref<inkImage>;
  private let m_ocTime: ref<inkText>;
  private let m_ocClock: Float;

  private let m_ocTgtTag: ref<inkText>;
  private let m_ocSlant: ref<inkText>;
  private let m_ocBrg: ref<inkText>;
  private let m_ocDh: ref<inkText>;
  private let m_ocSpd: ref<inkText>;

  private let m_ocLcue: ref<inkCanvas>;
  private let m_ocDepNeedle: ref<inkImage>;
  private let m_ocDepT: ref<inkText>;
  private let m_ocSplash: array<ref<inkImage>>;
  private let m_ocLeader: array<ref<inkImage>>;
  private let m_ocSplashT: ref<inkText>;
  private let m_ocSplashT2: ref<inkText>;

  private let m_ocMap: ref<inkCanvas>;
  private let m_ocDots: array<ref<inkImage>>;
  private let m_ocSelf: ref<inkCanvas>;
  private let m_ocFoot: array<ref<inkRectangle>>;
  private let m_ocFan: array<ref<inkImage>>;
  private let m_ocFootEdge: array<ref<inkImage>>;
  private let m_ocOrbit: array<ref<inkImage>>;
  private let m_ocTgtMark: ref<inkCanvas>;
  private let m_ocTgtLbl: ref<inkText>;
  private let m_ocV: ref<inkImage>;
  private let m_ocVLbl: ref<inkText>;

  private let m_ocRowNames: array<ref<inkText>>;
  private let m_ocRowStats: array<ref<inkText>>;

  private let m_ocKills: Int32;
  private let m_ocThreat: ref<inkText>;
  private let m_ocThreatTick: ref<inkImage>;
  private let m_ocThreatT: Float;
  private let m_ocThreatB: Float;
  private let m_ocHeading: Float;

  private let m_ocLinkBars: array<ref<inkImage>>;
  private let m_ocLaserDia: ref<inkImage>;
  private let m_ocTrackRing: ref<inkImage>;
  private let m_ocChipOn: array<ref<inkImage>>;
  private let m_ocHeatS: ref<CMSlider>;
  private let m_ocRkPips: array<ref<inkImage>>;
  private let m_ocArm: ref<inkImage>;
  private let m_ocBdaV: array<ref<inkText>>;
  private let m_ocThrPips: array<ref<inkImage>>;
  private let m_ocHullS: ref<CMSlider>;

  private let HDG_PX: Float = 15.5;
  private let HDG_HALF: Float = 400.0;
  private let OC_MAP_R: Float = 160.0;
  private let OC_MPX: Float = 1.6;
  private let OC_DEP_R: Float = 93.0;

  public static func Atlas() -> ResRef = r"mnc\\hud\\drone_schematics.inkatlas"

  public func SetKind(kind: String) -> Void {
    this.m_kind = kind;
    this.m_dpal = null;
  }

  private let m_dpal: ref<CMDronePal>;

  protected func Pal() -> ref<CMDronePal> {
    if !IsDefined(this.m_dpal) {
      this.m_dpal = CMDronePal.Of(this.m_kind, CMPilotSystem.Get(GetGameInstance()).DronePalette(), this.m_dTypeB);
    }
    return this.m_dpal;
  }

  private let m_dTypeB: Bool;

  public func SetTypeB(on: Bool) -> Void {
    this.m_dTypeB = on;
    this.m_dpal = null;
  }

  protected func TypeB() -> Bool = this.m_dTypeB

  protected func PlatesB() -> Void {
    let W = this.m_W;
    let cx = W * 0.5;
    let cy = 1080.0;
    this.BFrame(this.m_dFace, W);

    this.BPlate(this.Rg(0, 0), 46.0, 30.0, 1000.0, 146.0, false);
    this.BHazard(this.Rg(0, 0), 56.0, 44.0, 22.0, 118.0);

    this.BPlate(this.Rg(1, 0), cx - 430.0, 30.0, 860.0, 90.0, true);
    this.BPlate(this.Rg(1, 0), cx - 80.0, 112.0, 160.0, 50.0, false);

    this.BPlate(this.Rg(2, 0), W - 640.0, 30.0, 580.0, 236.0, true);

    this.BPlate(this.Rg(1, 1), cx - 930.0 - 196.0, cy - 36.0, 170.0, 68.0, false);
    this.BPlate(this.Rg(1, 1), cx + 930.0 + 24.0, cy - 36.0, 170.0, 68.0, false);
    this.BPlate(this.Rg(1, 1), cx - 150.0, cy + 206.0, 300.0, 58.0, false);

    this.BPlate(this.Rg(0, 1), 60.0, 1110.0, 450.0, 410.0, true);
    this.BPlate(this.Rg(0, 2), 50.0, 1566.0, 830.0, 300.0, true);
    this.BPlate(this.Rg(1, 2), cx - 350.0, 2026.0, 700.0, 62.0, false);
    this.BPlate(this.Rg(2, 2), W - 590.0, 1630.0, 540.0, 400.0, false);
  }

  protected func BPlate(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, flip: Bool) -> Void {
    let g = CMKit.Nine(root, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), x, y, w, h, CMInk.Glass(), 0.72);
    let l = CMKit.Nine(root, n"cham_line", inkMargin(20.0, 20.0, 20.0, 20.0), x, y, w, h, this.Pal().label, 0.9);
    if flip {
      g.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
      l.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
    }
  }

  protected func PlateC(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, cut: Float, edge: HDRColor, flip: Bool) -> Void {
    let k = MaxF(1.0, cut / 16.0);
    let c = new inkCanvas();
    c.SetMargin(inkMargin(x, y, 0.0, 0.0));
    c.SetSize(Vector2(w / k, h / k));
    c.SetRenderTransformPivot(Vector2(0.0, 0.0));
    c.SetScale(Vector2(k, k));
    c.SetInteractive(false);
    c.Reparent(root);

    let fillOp = CMPilotSystem.Get(GetGameInstance()).PlateBlur() > 0 ? 0.12 : 0.42;
    let g = CMKit.Nine(c, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), 0.0, 0.0, w / k, h / k, new HDRColor(0.06, 0.075, 0.085, 1.0), fillOp);
    let l = CMKit.Nine(c, n"cham_line", inkMargin(20.0, 20.0, 20.0, 20.0), 0.0, 0.0, w / k, h / k, edge, 0.9);
    if flip {
      g.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
      l.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
    }
    this.BlurNote(root, x, y, w, h);
  }

  private let m_dBlur: array<Vector4>;

  private func BlurNote(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float) -> Void {
    if !this.m_dTypeB {
      return;
    }
    let i = 0;
    while i < ArraySize(this.m_dRg) {
      if this.m_dRg[i] == root {
        let col = i % 3;
        let row = i / 3;
        let mid = col == 1 && row == 1;
        let s = mid ? ClampF(this.m_dU, 0.9, 1.0) : this.m_dU;

        let W = this.m_W;
        if W < 1.0 {
          let screen = ScreenHelper.GetScreenSize(GetGameInstance());
          W = screen.Y > 100.0 ? screen.X / (screen.Y / 2160.0) : 3840.0;
        }
        let px = Cast<Float>(col) * 0.5 * W;
        let py = Cast<Float>(row) * 1080.0;
        let f = mid ? 1.0 : this.DRONE_SAFE;
        let cx = W * 0.5;

        let x0 = ((px + (x - px) * s) - cx) * f;
        let x1 = ((px + (x + w - px) * s) - cx) * f;
        let y0 = ((py + (y - py) * s) - 1080.0) * f;
        let y1 = ((py + (y + h - py) * s) - 1080.0) * f;
        ArrayPush(this.m_dBlur, new Vector4(x0, y0, x1, y1));
        return;
      }
      i += 1;
    }
  }

  public func BlurRects() -> array<Vector4> {
    let out: array<Vector4>;
    let left = this.m_dBlur;
    while ArraySize(left) > 0 && ArraySize(out) < CMBlurPanes.Count() {
      let best = 0;
      let bestA = -1.0;
      let i = 0;
      while i < ArraySize(left) {
        let a = (left[i].Z - left[i].X) * (left[i].W - left[i].Y);
        if a > bestA {
          bestA = a;
          best = i;
        }
        i += 1;
      }
      ArrayPush(out, left[best]);
      ArrayErase(left, best);
    }
    return out;
  }

  protected func PlateHead(root: ref<inkCanvas>, x: Float, y: Float, w: Float, title: String, tag: String, tagCol: HDRColor) -> ref<inkText> {
    CMPilotHud.Label(root, inkEAnchor.TopLeft, x + 31.0, y + 12.0, title, 36, n"Semi-Bold", this.Pal().ink);
    CMKit.Ln(root, x + 31.0, y + 66.0, w - 62.0, 2.0, this.Pal().label, 0.45);
    let t = CMPilotHud.Label(root, inkEAnchor.TopLeft, x + w - 31.0, y + 16.0, tag, 32, n"Semi-Bold", tagCol);
    t.SetAnchorPoint(Vector2(1.0, 0.0));
    return t;
  }

  protected func BHazard(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float) -> Void {
    let img = CMKit.Img(root, n"hazard", x + w * 0.5 - h * 0.5, y + h * 0.5 - w * 0.5, h, w, this.Pal().accent, 0.85);
    img.SetRenderTransformPivot(Vector2(0.5, 0.5));
    img.SetRotation(90.0);
  }

  protected func BFrame(root: ref<inkCanvas>, w: Float) -> Void {
    let xs = [0.0, w];
    let ys = [0.0, 2160.0];
    let i = 0;
    while i < 4 {
      let x = xs[i % 2];
      let y = ys[i / 2];
      let sx = i % 2 == 0 ? 1.0 : -1.0;
      let sy = i / 2 == 0 ? 1.0 : -1.0;
      let L1 = 330.0;
      let L2 = 200.0;
      let T = 18.0;
      CMKit.Fill(root, sx > 0.0 ? x : x - L1, sy > 0.0 ? y : y - T, L1, T, CMInk.Glass(), 0.9);
      CMKit.Fill(root, sx > 0.0 ? x : x - T, sy > 0.0 ? y : y - L2, T, L2, CMInk.Glass(), 0.9);
      CMKit.Ln(root, sx > 0.0 ? x + T : x - L1, sy > 0.0 ? y + T : y - T - 4.0, L1 - T, 4.0, this.Pal().ink, 0.85);
      CMKit.Ln(root, sx > 0.0 ? x + T : x - T - 4.0, sy > 0.0 ? y + T : y - L2, 4.0, L2 - T, this.Pal().ink, 0.85);
      CMKit.Ln(root, sx > 0.0 ? x + L1 + 20.0 : x - L1 - 150.0, sy > 0.0 ? y + 8.0 : y - 15.0, 130.0, 7.0, this.Pal().accent, 0.9);
      i += 1;
    }
  }

  protected func BDash(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, c: HDRColor, seed: Int32) -> Void {
    let dash = 22.0;
    let gap = 16.0;
    let side = 0;
    while side < 4 {
      let len = side % 2 == 0 ? w : h;
      let n = FloorF(len / (dash + gap));
      let k = 0;
      while k <= n {

        if (k * 7 + side * 3 + seed) % 11 != 0 {
          let a = Cast<Float>(k) * (dash + gap);
          let run = MinF(dash, len - a);
          if run > 2.0 {
            switch side {
              case 0: CMKit.Ln(root, x + a, y, run, 3.0, c, 0.85); break;
              case 1: CMKit.Ln(root, x + w - 3.0, y + a, 3.0, run, c, 0.85); break;
              case 2: CMKit.Ln(root, x + w - a - run, y + h - 3.0, run, 3.0, c, 0.85); break;
              default: CMKit.Ln(root, x, y + h - a - run, 3.0, run, c, 0.85); break;
            }
          }
        }
        k += 1;
      }
      side += 1;
    }
  }

  private let m_dRg: array<ref<inkCanvas>>;
  private let m_dU: Float;

  protected func EdgeScale(w: Float) -> Float = ClampF(w / 5160.0, 0.85, 1.0)

  private let m_dFace: ref<inkCanvas>;
  private let DRONE_SAFE: Float = 0.92;
  protected func Face() -> ref<inkCanvas> = this.m_dFace

  protected func MakeRegions(root: ref<inkCanvas>, w: Float) -> Void {
    ArrayClear(this.m_dRg);
    ArrayClear(this.m_dBlur);
    this.m_dU = this.EdgeScale(w);
    let face = new inkCanvas();
    face.SetAnchor(inkEAnchor.TopLeft);
    face.SetSize(Vector2(w, 2160.0));
    face.SetRenderTransformPivot(Vector2(0.5, 0.5));
    face.SetScale(Vector2(this.DRONE_SAFE, this.DRONE_SAFE));
    face.SetInteractive(false);
    face.Reparent(root);
    this.m_dFace = face;
    let row = 0;
    while row < 3 {
      let col = 0;
      while col < 3 {
        let mid = row == 1 && col == 1;
        let s = mid ? ClampF(this.m_dU, 0.9, 1.0) : this.m_dU;
        let c = new inkCanvas();
        c.SetAnchor(inkEAnchor.TopLeft);
        c.SetSize(Vector2(w, 2160.0));
        c.SetRenderTransformPivot(Vector2(Cast<Float>(col) * 0.5, Cast<Float>(row) * 0.5));
        c.SetScale(Vector2(s, s));
        c.SetInteractive(false);

        c.Reparent(mid ? root : face);
        ArrayPush(this.m_dRg, c);
        col += 1;
      }
      row += 1;
    }
  }

  protected func Rg(col: Int32, row: Int32) -> ref<inkCanvas> = this.m_dRg[row * 3 + col]

  public func Build() -> Bool {
    let layer = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
    if !IsDefined(layer) {
      return false;
    }
    let window = layer.GetVirtualWindow();
    if !IsDefined(window) {
      return false;
    }
    this.m_dparent = window;

    ArrayClear(this.m_dhidden);
    ArrayClear(this.m_dhiddenOp);
    let i = 0;
    while i < window.GetNumChildren() {
      let child = window.GetWidgetByIndex(i);
      if IsDefined(child) && NotEquals(child.GetName(), n"cm_drone_hud") {
        ArrayPush(this.m_dhidden, child);
        ArrayPush(this.m_dhiddenOp, child.GetOpacity());
        child.SetOpacity(0.0);
      }
      i += 1;
    }
    let root = new inkCanvas();
    root.SetName(n"cm_drone_hud");
    root.SetInteractive(false);
    let screen = ScreenHelper.GetScreenSize(GetGameInstance());
    this.m_W = 3840.0;
    if screen.Y > 100.0 {
      let k = screen.Y / 2160.0;
      this.m_W = screen.X / k;
      root.SetAnchor(inkEAnchor.TopLeft);
      root.SetSize(Vector2(this.m_W, 2160.0));
      root.SetRenderTransformPivot(Vector2(0.0, 0.0));
      root.SetScale(Vector2(k, k));
    } else {
      root.SetAnchor(inkEAnchor.Fill);
    }
    root.Reparent(window);
    this.m_droot = root;

    this.MakeRegions(root, this.m_W);
    if this.m_dTypeB {
      this.PlatesB();
    }
    this.BuildHeading(this.Rg(1, 0));
    this.BuildTapes(this.Rg(1, 1));
    this.BuildCentre(this.Rg(1, 1), root);
    this.BuildSensor(this.Rg(0, 0));
    this.BuildTarget(this.Rg(2, 0));
    this.BuildMap(this.Rg(0, 1));
    this.BuildStores(this.Rg(0, 2));
    this.BuildDamage(this.Rg(2, 2));
    return true;
  }

  public func Remove() -> Void {
    if IsDefined(this.m_droot) && IsDefined(this.m_dparent) {
      this.m_droot.StopAllAnimations();
      this.m_dparent.RemoveChild(this.m_droot);
    }
    this.m_droot = null;
    let i = 0;
    while i < ArraySize(this.m_dhidden) {
      let w = this.m_dhidden[i];
      if IsDefined(w) {
        w.SetOpacity(this.m_dhiddenOp[i]);
      }
      i += 1;
    }
    ArrayClear(this.m_dhidden);
    ArrayClear(this.m_dhiddenOp);
    ArrayClear(this.m_schemParts);
    ArrayClear(this.m_ocDots);
    ArrayClear(this.m_ocRowNames);
    ArrayClear(this.m_ocLinkBars);
    ArrayClear(this.m_ocChipOn);
    ArrayClear(this.m_ocRkPips);
    ArrayClear(this.m_ocBdaV);
    ArrayClear(this.m_ocThrPips);
    ArrayClear(this.m_ocRowStats);
    ArrayClear(this.m_ocSplash);
    ArrayClear(this.m_ocLeader);
    ArrayClear(this.m_ocFoot);
    ArrayClear(this.m_ocFootEdge);
    ArrayClear(this.m_ocOrbit);
  }

  private func G() -> HDRColor = this.Pal().accent
  private func Lbl() -> HDRColor = this.Pal().label
  private func Hi() -> HDRColor = this.Pal().ink

  private func Line(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, op: Float) -> ref<inkImage> = CMKit.Ln(root, x, y, w, h, this.G(), op)
  private func Txt(root: ref<inkCanvas>, x: Float, y: Float, text: String, size: Int32, centred: Bool) -> ref<inkText> {
    let t = CMPilotHud.Label(root, inkEAnchor.TopLeft, x, y, text, size, n"Medium", this.G());
    if centred {
      t.SetAnchorPoint(Vector2(0.5, 0.0));
    }
    return t;
  }
  private func TxtC(root: ref<inkCanvas>, x: Float, y: Float, text: String, size: Int32, c: HDRColor) -> ref<inkText> {
    let t = CMPilotHud.Label(root, inkEAnchor.TopLeft, x, y, text, size, n"Medium", c);
    return t;
  }
  private func OcRight(root: ref<inkCanvas>, x: Float, y: Float, text: String, size: Int32, c: HDRColor) -> ref<inkText> {
    let t = this.TxtC(root, x, y, text, size, c);
    t.SetAnchorPoint(Vector2(1.0, 0.0));
    return t;
  }

  private func BuildHeading(root: ref<inkCanvas>) -> Void {
    let cx = this.m_W * 0.5;
    let i = 0;
    while i < 41 {
      ArrayPush(this.m_hdgTicks, this.Line(root, cx, 86.0, 2.0, 18.0, 0.85));
      i += 1;
    }
    i = 0;
    while i < 13 {
      ArrayPush(this.m_hdgLabels, this.Txt(root, cx, 44.0, "00", 24, true));
      this.m_hdgLabels[i].SetTintColor(this.Lbl());
      i += 1;
    }
    CMKit.Img(root, n"tri", cx - 8.0, 104.0, 16.0, 14.0, this.G(), 1.0);
    this.m_hdgBox = this.Txt(root, cx, 120.0, "000", 30, true);
    this.m_hdgBox.SetTintColor(this.Hi());

    let hb = new inkCanvas();
    hb.SetMargin(inkMargin(cx - 320.0, 170.0, 0.0, 0.0));
    hb.SetSize(Vector2(640.0, 40.0));
    hb.Reparent(root);
    CMKit.Nine(hb, n"rrect_line_s", inkMargin(7.0, 7.0, 7.0, 7.0), 0.0, 0.0, 640.0, 40.0, this.Pal().warn, 0.9);
    this.m_holdBox = hb;
    this.m_holdT = this.Txt(root, cx, 174.0, "", 24, true);
    this.m_holdT.SetTintColor(this.Pal().warn);
    this.m_holdBox.SetVisible(false);

    this.m_ocThreatTick = CMKit.VPill(root, cx, 76.0, 6.0, 30.0, this.Pal().hostile, 1.0);
    this.m_ocThreatTick.SetVisible(false);
    this.m_ocThreat = this.Txt(root, cx + 430.0, 80.0, "", 26, false);
    this.m_ocThreat.SetTintColor(this.Pal().hostile);
    this.m_warnT = this.Txt(root, cx, 228.0, "", 30, true);
    this.m_warnT.SetTintColor(this.Pal().hostile);
  }

  public func SetAttitude(heading: Float, pitch: Float) -> Void {
    if !IsDefined(this.m_droot) {
      return;
    }
    let h = CMPilotRig.Wrap(heading);
    if h < 0.0 {
      h += 360.0;
    }
    this.m_ocHeading = h;
    let cx = this.m_W * 0.5;
    let base = FloorF(h / 5.0) * 5;
    let i = 0;
    while i < ArraySize(this.m_hdgTicks) {
      let deg = Cast<Float>(base + (i - 20) * 5);
      let x = cx + (deg - h) * this.HDG_PX;
      let t = this.m_hdgTicks[i];
      let long = (base + (i - 20) * 5) % 10 == 0;
      t.SetVisible(AbsF(x - cx) <= this.HDG_HALF);
      t.SetMargin(inkMargin(x - 1.0, long ? 80.0 : 92.0, 0.0, 0.0));
      t.SetSize(Vector2(2.0, long ? 24.0 : 12.0));
      i += 1;
    }

    let lbase = FloorF(h / 10.0) * 10;
    i = 0;
    while i < ArraySize(this.m_hdgLabels) {
      let deg = lbase + (i - 6) * 10;
      let x = cx + (Cast<Float>(deg) - h) * this.HDG_PX;
      let l = this.m_hdgLabels[i];
      l.SetVisible(AbsF(x - cx) <= this.HDG_HALF - 10.0);
      l.SetMargin(inkMargin(x, 44.0, 0.0, 0.0));
      let d = deg % 360;
      if d < 0 {
        d += 360;
      }
      let s = d / 10;
      CMInk.Text(l, d == 0 ? CMText.PhudN() : (d == 90 ? CMText.PhudE() : (d == 180 ? CMText.PhudS() : (d == 270 ? CMText.PhudW() : (s < 10 ? "0" : "") + IntToString(s)))));
      i += 1;
    }
    CMInk.Text(this.m_hdgBox, CMPilotHud.Pad3(RoundF(h) % 360));
  }

  private func BuildTapes(root: ref<inkCanvas>) -> Void {
    let cx = this.m_W * 0.5;
    let cy = 1080.0;
    let xl = cx - 930.0;
    let xr = cx + 930.0;
    this.Line(root, xl - 1.0, cy - 232.0, 2.0, 464.0, 0.8);
    this.Line(root, xr - 1.0, cy - 232.0, 2.0, 464.0, 0.8);
    let j = -4;
    while j <= 4 {
      let y = cy + Cast<Float>(j) * 52.0;
      let len = j % 2 == 0 ? 20.0 : 10.0;
      this.Line(root, xl, y - 1.0, len, 2.0, 0.8);
      this.Line(root, xr - len, y - 1.0, len, 2.0, 0.8);
      j += 1;
    }
    this.m_speedText = this.OcRight(root, xl - 36.0, cy - 26.0, "0.0", 40, this.Hi());
    this.OcRight(root, xl - 36.0, cy + 20.0, "M/S", 22, this.Lbl());
    this.m_altText = this.TxtC(root, xr + 36.0, cy - 26.0, "000", 40, this.Hi());
    this.m_vsText = this.TxtC(root, xr + 36.0, cy + 20.0, CMText.DhudVs("0.0"), 22, this.Lbl());
  }

  private func BuildCentre(root: ref<inkCanvas>, screen: ref<inkCanvas>) -> Void {
    let cx = this.m_W * 0.5;
    let cy = 1080.0;
    let c = new inkCanvas();
    c.SetMargin(inkMargin(cx - 130.0, cy - 130.0, 0.0, 0.0));
    c.SetSize(Vector2(260.0, 260.0));
    c.Reparent(root);
    this.m_cross = c;

    let o = 130.0;
    this.Line(c, o - 119.0, o - 1.5, 93.0, 3.0, 0.95);
    this.Line(c, o + 26.0, o - 1.5, 93.0, 3.0, 0.95);
    this.Line(c, o - 1.5, o - 119.0, 3.0, 93.0, 0.95);
    this.Line(c, o - 1.5, o + 26.0, 3.0, 93.0, 0.95);
    CMKit.Disc(c, o, o, 4.0, this.G(), 1.0);

    let l = new inkCanvas();
    l.SetMargin(inkMargin(cx - 132.0, cy + 224.0, 0.0, 0.0));
    l.SetSize(Vector2(26.0, 26.0));
    l.Reparent(root);
    CMKit.Img(l, n"diamond", 0.0, 0.0, 26.0, 26.0, this.Pal().warn, 1.0);
    this.m_ocLcue = l;
    this.m_lrf = this.TxtC(root, cx - 94.0, cy + 216.0, "---- M", 32, this.G());

    let ax = cx + 418.0;
    let ay = cy - 175.0;
    let r = this.OC_DEP_R;
    let ring = CMInk.Ring(root, ax, ay, r, 72, 2.0, this.G(), 0.8);
    let q = 0;
    while q < 72 {
      let a = Cast<Float>(q) * 5.0;
      ring[q].SetVisible(a >= 180.0 && a <= 270.0);
      q += 1;
    }
    let tk = 0;
    while tk <= 9 {
      let a = Deg2Rad(270.0 - Cast<Float>(tk) * 10.0);
      CMInk.Line(root, ax + SinF(a) * r, ay - CosF(a) * r, ax + SinF(a) * (r - 12.0), ay - CosF(a) * (r - 12.0), 2.0, this.G(), 0.7);
      tk += 1;
    }
    this.m_ocDepNeedle = CMKit.Stroke(root, this.Pal().warn, 1.0);
    this.m_ocDepT = this.TxtC(root, ax + 16.0, ay - r - 40.0, CMText.DhudDep("00"), 23, this.Lbl());

    let im = new inkCanvas();
    im.SetSize(Vector2(10.0, 10.0));
    im.SetVisible(false);
    im.Reparent(root);

    let a2 = this.Pal().warn;
    let n = 0;
    while n < 32 {
      let s = CMKit.Stroke(screen, a2, 1.0);
      s.SetVisible(false);
      ArrayPush(this.m_ocSplash, s);
      n += 1;
    }
    n = 0;
    while n < 2 {
      let s = CMKit.Stroke(screen, a2, 0.9);
      s.SetVisible(false);
      ArrayPush(this.m_ocLeader, s);
      n += 1;
    }
    this.m_ocSplashT = this.TxtC(screen, 0.0, 0.0, "", 26, a2);
    this.m_ocSplashT2 = this.TxtC(screen, 0.0, 0.0, "", 22, a2);
    this.m_ocSplashT.SetVisible(false);
    this.m_ocSplashT2.SetVisible(false);
  }

  public func SetImpact(on: Bool, x: Float, y: Float, tof: Float) -> Void {}

  private func BuildSensor(root: ref<inkCanvas>) -> Void {
    let x = 93.0;
    this.m_name = this.TxtC(root, x, 52.0, CMText.DhudDrone(), 34, this.Hi());
    let y = 112.0;
    this.m_ocMts = this.TxtC(root, x, y, "", 24, this.G());

    let b = 0;
    while b < 5 {
      let h = 10.0 + Cast<Float>(b) * 6.0;
      ArrayPush(this.m_ocLinkBars, CMKit.Img(root, n"pill_v", x + 260.0 + Cast<Float>(b) * 14.0, y + 32.0 - h, 8.0, h, this.G(), 1.0));
      b += 1;
    }
    this.m_ocLinkRng = this.TxtC(root, x + 340.0, y + 2.0, "", 22, this.Lbl());

    this.m_ocLaserDia = CMKit.Img(root, n"diamond", x + 470.0, y + 4.0, 24.0, 24.0, this.Pal().warn, 1.0);
    this.m_ocTrackRing = CMInk.Circle(root, x + 524.0, y + 16.0, 12.0, this.Lbl(), 1.0);
    this.m_ocRecDot = CMKit.Disc(root, x + 566.0, y + 16.0, 9.0, this.Pal().hostile, 1.0);
    this.m_ocTime = this.TxtC(root, x + 586.0, y + 2.0, "", 22, this.Lbl());

    this.m_ocLinkPct = this.TxtC(root, 0.0, 0.0, "", 10, this.Lbl());
    this.m_ocLinkPct.SetVisible(false);
  }

  private func BuildTarget(root: ref<inkCanvas>) -> Void {
    let xr = this.m_W - 93.0;
    this.m_ocTgtTag = this.OcRight(root, xr - 380.0, 58.0, "", 22, this.Pal().warn);
    let rows = [CMText.DhudSlt(), CMText.DhudBrg(), CMText.DhudDh(), CMText.DhudSpd()];
    let i = 0;
    while i < 4 {
      let ry = 58.0 + Cast<Float>(i) * 42.0;
      this.OcRight(root, xr - 200.0, ry + 4.0, rows[i], 22, this.Lbl());
      let v = this.OcRight(root, xr, ry, "", 28, this.Hi());
      switch i {
        case 0: this.m_ocSlant = v; break;
        case 1: this.m_ocBrg = v; break;
        case 2: this.m_ocDh = v; break;
        default: this.m_ocSpd = v; break;
      }
      i += 1;
    }
    this.m_windT = this.OcRight(root, xr, 232.0, "", 22, this.G());
    this.m_windT.SetOpacity(0.75);
  }

  private func BuildMap(root: ref<inkCanvas>) -> Void {
    let mx = 283.0;
    let my = 1337.0;
    let c = this.OC_MAP_R;
    this.TxtC(root, mx - c, my - c - 40.0, CMText.DhudNorthUp(), 22, this.Lbl());
    let m = new inkCanvas();
    m.SetMargin(inkMargin(mx - c, my - c, 0.0, 0.0));
    m.SetSize(Vector2(c * 2.0, c * 2.0));
    m.Reparent(root);
    this.m_ocMap = m;
    CMInk.Circle(m, c, c, c, this.G(), 0.8);
    CMInk.Circle(m, c, c, c * 0.5, this.G(), 0.35);
    this.Line(m, c - 1.0, 0.0, 2.0, c * 2.0, 0.12);
    this.Line(m, 0.0, c - 1.0, c * 2.0, 2.0, 0.12);

    this.m_ocFoot = CMInk.FillBars(m, 0, this.G(), 0.28);
    this.m_ocFan = CMInk.FanSegs(m, 70, this.G(), 0.16);
    let fe = 0;
    while fe < 3 {
      let b = CMKit.Stroke(m, this.G(), 0.9);
      b.SetVisible(false);
      ArrayPush(this.m_ocFootEdge, b);
      fe += 1;
    }

    let n = 0;
    while n < 32 {
      let s = CMKit.Stroke(m, this.Pal().warn, 1.0);
      s.SetVisible(false);
      ArrayPush(this.m_ocOrbit, s);
      n += 1;
    }

    let i = 0;
    while i < 32 {
      let d = CMKit.Disc(m, 0.0, 0.0, 6.0, this.G(), 1.0);
      d.SetVisible(false);
      d.SetRenderTransformPivot(Vector2(0.5, 0.5));
      ArrayPush(this.m_ocDots, d);
      i += 1;
    }

    this.m_ocV = CMKit.Disc(m, 0.0, 0.0, 7.0, this.Pal().friendly, 1.0);
    this.m_ocVLbl = this.TxtC(m, 0.0, 0.0, "V", 20, this.Pal().friendly);

    let tg = new inkCanvas();
    tg.SetSize(Vector2(20.0, 20.0));
    tg.SetRenderTransformPivot(Vector2(0.5, 0.5));
    tg.Reparent(m);
    CMKit.Img(tg, n"diamond", 0.0, 0.0, 20.0, 20.0, this.Pal().hostile, 1.0);
    this.m_ocTgtMark = tg;
    this.m_ocTgtLbl = this.TxtC(m, 0.0, 0.0, CMText.DhudTgt(), 20, this.Pal().hostile);

    this.m_ocSelf = CMInk.Chevron(m, 28.0, 5.0, this.Hi());
    this.m_ocSelf.SetMargin(inkMargin(c - 14.0, c - 14.0, 0.0, 0.0));
  }

  private func BuildStores(root: ref<inkCanvas>) -> Void {
    if this.m_dTypeB {
      this.BuildStoresB(root);
      return;
    }
    let x = 93.0;
    let y = 1645.0;
    this.m_ocArm = CMKit.Disc(root, x + 10.0, y + 22.0, 9.0, this.Pal().warn, 1.0);
    this.TxtC(root, x + 28.0, y + 8.0, CMText.DhudArm(), 24, this.Pal().warn);
    let names = [CMText.DhudSta1Short(), CMText.DhudSta2Short(), CMText.DhudSta3Short()];
    let i = 0;
    while i < 3 {
      let cx = x + 144.0 + Cast<Float>(i) * 172.0;
      CMKit.Nine(root, n"slant_h", inkMargin(0.0, 0.0, 12.0, 0.0), cx, y, 156.0, 44.0, this.G(), 0.16);
      let on = CMKit.Nine(root, n"slant_h", inkMargin(0.0, 0.0, 12.0, 0.0), cx, y, 156.0, 44.0, this.G(), 0.92);
      ArrayPush(this.m_ocChipOn, on);
      ArrayPush(this.m_ocRowNames, this.TxtC(root, cx + 18.0, y + 4.0, names[i], 30, this.G()));

      ArrayPush(this.m_ocRowStats, this.TxtC(root, cx + 4.0, y + 76.0, "", 20, this.Lbl()));
      i += 1;
    }
    this.m_ocHeatS = CMSlider.Make(root, x + 144.0 + 172.0 + 6.0, y + 56.0, 130.0, 6.0, false, this.Pal().warn);
    let p = 0;
    while p < 4 {
      let pip = CMKit.Disc(root, x + 144.0 + 344.0 + 20.0 + Cast<Float>(p) * 24.0, y + 62.0, 7.0, this.G(), 1.0);
      ArrayPush(this.m_ocRkPips, pip);
      p += 1;
    }
    this.TxtC(root, x, y + 112.0, CMText.DhudKeys(CMKeyName.FireMode(), CMKeyName.Fire(), CMKeyName.Secondary(), CMKeys.GunshipName(GetPlayer(GetGameInstance())), CMKeyName.Aim(), CMKeyName.Sensor()), 22, this.Lbl());

    let cxs = this.m_W * 0.5;
    let bda = this.Rg(1, 2);
    let labels = [CMText.DhudKia(), CMText.DhudRds(), CMText.DhudHit(), CMText.DhudAcc(), CMText.DhudHos()];
    let k = 0;
    while k < 5 {
      let bx = cxs - 320.0 + Cast<Float>(k) * 134.0;
      this.TxtC(bda, bx, 2044.0, labels[k], 20, this.Lbl());
      ArrayPush(this.m_ocBdaV, this.TxtC(bda, bx + 62.0, 2038.0, "0", 28, this.Hi()));
      k += 1;
    }
  }

  private func BuildStoresB(root: ref<inkCanvas>) -> Void {
    let x = 93.0;
    let y = 1586.0;
    this.TxtC(root, x, y, CMText.DhudStores(), 26, this.Hi());
    this.m_ocArm = CMKit.Disc(root, x + 560.0, y + 16.0, 8.0, this.Pal().warn, 1.0);
    this.OcRight(root, x + 740.0, y + 2.0, CMText.DhudMasterArm(), 24, this.Pal().warn);
    let names = [CMText.DhudSta1(), CMText.DhudSta2(), CMText.DhudSta3()];
    let i = 0;
    while i < 3 {
      let ry = y + 44.0 + Cast<Float>(i) * 62.0;
      let on = CMKit.Fill(root, x - 10.0, ry, 760.0, 54.0, this.G(), 0.92);
      ArrayPush(this.m_ocChipOn, on);
      let hz = CMKit.Img(root, n"hazard", x + 690.0, ry + 4.0, 56.0, 46.0, new HDRColor(0.02, 0.02, 0.01, 1.0), 0.85);
      ArrayPush(this.m_ocChipOn, hz);
      ArrayPush(this.m_ocRowNames, this.TxtC(root, x, ry + 8.0, names[i], 32, this.G()));
      ArrayPush(this.m_ocRowStats, this.OcRight(root, x + 670.0, ry + 14.0, "", 24, this.Lbl()));
      i += 1;
    }
    this.m_ocHeatS = CMSlider.Make(root, x + 300.0, y + 44.0 + 62.0 + 24.0, 200.0, 8.0, false, this.Pal().warn);
    let p = 0;
    while p < 4 {
      let pip = CMKit.Fill(root, x + 300.0 + Cast<Float>(p) * 30.0, y + 44.0 + 124.0 + 12.0, 20.0, 30.0, this.Hi(), 1.0);
      ArrayPush(this.m_ocRkPips, pip);
      p += 1;
    }
    this.TxtC(root, x, y + 238.0, CMText.DhudKeys(CMKeyName.FireMode(), CMKeyName.Fire(), CMKeyName.Secondary(), CMKeys.GunshipName(GetPlayer(GetGameInstance())), CMKeyName.Aim(), CMKeyName.Sensor()), 20, this.Lbl());
    let cxs = this.m_W * 0.5;
    let bda = this.Rg(1, 2);
    let labels = [CMText.DhudKia(), CMText.DhudRds(), CMText.DhudHit(), CMText.DhudAcc(), CMText.DhudHos()];
    let k = 0;
    while k < 5 {
      let bx = cxs - 320.0 + Cast<Float>(k) * 134.0;
      this.TxtC(bda, bx, 2044.0, labels[k], 20, this.Lbl());
      ArrayPush(this.m_ocBdaV, this.TxtC(bda, bx + 62.0, 2038.0, "0", 28, this.Hi()));
      k += 1;
    }
  }

  private func BuildDamage(root: ref<inkCanvas>) -> Void {
    let W = this.m_W;
    let k = 284.0 / 537.0;
    let x0 = W - 439.0;
    let y0 = 1660.0;
    if Equals(this.m_kind, "octant") {
      let box = new inkCanvas();
      box.SetMargin(inkMargin(x0, y0, 0.0, 0.0));
      box.SetSize(Vector2(537.0 * k, 560.0 * k));
      box.Reparent(root);

      this.Part(box, k, n"octant_body", 100.0, 16.0, 335.0, 539.0);
      this.Part(box, k, n"octant_thruster_fl", 5.0, 137.0, 132.0, 138.0);
      this.Part(box, k, n"octant_thruster_fr", 401.0, 137.0, 132.0, 138.0);
      this.Part(box, k, n"octant_thruster_bl", 11.0, 310.0, 126.0, 136.0);
      this.Part(box, k, n"octant_thruster_br", 400.0, 310.0, 127.0, 136.0);
      this.Part(box, k, n"octant_gun", 242.0, 5.0, 53.0, 56.0);
      this.Part(box, k, n"octant_rocket_l", 43.0, 225.0, 81.0, 109.0);
      this.Part(box, k, n"octant_rocket_r", 413.0, 225.0, 81.0, 109.0);
      this.Part(box, k, n"octant_mortar", 206.0, 348.0, 162.0, 202.0);
      this.Part(box, k, n"octant_sensor", 191.0, 15.0, 156.0, 102.0);
    }

    let px = W - 541.0;
    let py = 1773.0;
    let i = 0;
    while i < 4 {
      let tpx = px + Cast<Float>(i % 2) * 46.0;
      let tpy = py + Cast<Float>(i / 2) * 46.0;

      ArrayPush(this.m_ocThrPips, this.m_dTypeB ? CMKit.Fill(root, tpx - 17.0, tpy - 17.0, 34.0, 34.0, this.G(), 1.0) : CMKit.Disc(root, tpx, tpy, 11.0, this.G(), 1.0));
      i += 1;
    }
    this.TxtC(root, px - 18.0, py + 72.0, CMText.DhudThr(), 20, this.Lbl());
    this.TxtC(root, x0, 1980.0, CMText.MhudHull(), 20, this.Lbl());
    this.m_ocHullS = CMSlider.Make(root, x0 + 64.0, 1992.0, 220.0, 6.0, false, this.G());
  }

  private func Part(box: ref<inkCanvas>, k: Float, name: CName, x: Float, y: Float, w: Float, h: Float) -> Void {
    let img = new inkImage();
    img.SetAtlasResource(CMDroneHud.Atlas());
    img.SetTexturePart(name);
    img.SetMargin(inkMargin(x * k, y * k, 0.0, 0.0));
    img.SetSize(Vector2(w * k, h * k));
    img.SetTintColor(this.G());
    img.SetInteractive(false);
    img.Reparent(box);
    ArrayPush(this.m_schemParts, img);
  }

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.m_droot) {
      return;
    }
    CMInk.Text(this.m_name, CMText.DhudGunship(s.title));

    let sig = ClampF(s.signal, 0.0, 1.0);
    let lb = 0;
    while lb < ArraySize(this.m_ocLinkBars) {
      this.m_ocLinkBars[lb].SetOpacity(sig * 5.0 > Cast<Float>(lb) + 0.5 ? 1.0 : 0.2);
      this.m_ocLinkBars[lb].SetTintColor(sig < 0.35 ? this.Pal().hostile : this.G());
      lb += 1;
    }
    CMInk.Text(this.m_ocLinkRng, "C  " + FloatToStringPrec(s.distance / 1000.0, 2) + " KM");

    let gt = GameInstance.GetTimeSystem(GetGameInstance()).GetGameTime();
    let hh = GameTime.Hours(gt);
    let mi = GameTime.Minutes(gt);
    CMInk.Text(this.m_ocTime, CMText.DhudTime(CMInk.Clock(this.m_ocClock), IntToString(GameTime.Days(gt)), (hh < 10 ? "0" : "") + IntToString(hh) + ":" + (mi < 10 ? "0" : "") + IntToString(mi)));
    CMInk.Text(this.m_lrf, s.range > 0.0 && s.range < 2000.0 ? CMPilotHud.Pad4(RoundF(s.range)) + " M" : "---- M");

    let dark = new HDRColor(0.01, 0.06, 0.03, 1.0);
    let i = 0;

    let per = this.m_dTypeB ? 2 : 1;
    while i < ArraySize(this.m_ocRowNames) {
      let on = s.weapon == i;
      let st = i < ArraySize(s.wStat) ? s.wStat[i] : "";
      let ci = 0;
      while ci < per && i * per + ci < ArraySize(this.m_ocChipOn) {
        this.m_ocChipOn[i * per + ci].SetVisible(on);
        ci += 1;
      }
      this.m_ocRowNames[i].SetTintColor(on ? dark : this.G());
      CMInk.Text(this.m_ocRowStats[i], CMDroneHud.StatText(st));
      this.m_ocRowStats[i].SetTintColor(CMDroneHud.StatWarn(st) ? this.StatColor(st) : this.Lbl());
      i += 1;
    }
    let heat = ClampF(s.secHeat, 0.0, 1.0);
    this.m_ocHeatS.Set(heat, heat >= 0.99 ? this.Pal().hostile : this.Pal().warn);
    let p = 0;
    while p < ArraySize(this.m_ocRkPips) {
      this.m_ocRkPips[p].SetVisible(p < s.rkMax);
      this.m_ocRkPips[p].SetOpacity(p < s.rkLeft ? 1.0 : 0.25);
      p += 1;
    }

    this.m_holdBox.SetVisible(StrLen(s.holdText) > 0);
    CMInk.Text(this.m_holdT, s.holdText);
    CMInk.Text(this.m_windT, s.windText);

    let hull = ClampF(s.integrity, 0.0, 1.0);
    this.m_ocHullS.Set(hull, this.Health(hull));
    if ArraySize(s.droneParts) >= 5 {
      let k = 0;
      while k < ArraySize(this.m_ocThrPips) {
        let hp = s.droneParts[k + 1];
        this.m_ocThrPips[k].SetTintColor(hp <= 0.0 ? this.Pal().broken : this.Health(hp));
        this.m_ocThrPips[k].SetOpacity(hp <= 0.0 ? 0.5 : 1.0);
        k += 1;
      }
    }    i = 0;
    while i < ArraySize(this.m_schemParts) {
      let hp = i < ArraySize(s.droneParts) ? s.droneParts[i] : 1.0;
      let img = this.m_schemParts[i];
      img.SetTintColor(hp <= 0.0 ? this.Pal().broken : this.Health(hp));
      img.SetOpacity(hp <= 0.0 ? 0.45 : 1.0);
      i += 1;
    }
    this.m_ocSensor = Equals(s.sensor, "DAY") ? "DAY-TV" : "IR " + CMThermal.Label(s.sensor);
    this.m_ocZoomed = s.zoomed;
    CMInk.Text(this.m_warnT, s.warning);
  }

  public static func StatText(st: String) -> String {
    switch st {
      case "": return "";
      case "LOST": return CMText.DrnLost();
      case "RDY": return CMText.DrnRdy();
      case "NO SOLN": return CMText.DrnNoSoln();
      case "OVERHEAT": return CMText.DrnOverheat();
      case "OFF ARC": return CMText.DrnOffArc();
      case "HOT": return CMText.DrnHot();
    }
    if StrBeginsWith(st, "RLD ") && StrEndsWith(st, " S") {
      return CMText.DrnRld(StrMid(st, 4, StrLen(st) - 6));
    }
    if StrBeginsWith(st, "ARC ") {
      return CMText.DhudArc(StrAfterFirst(st, "ARC "));
    }
    return st;
  }

  public static func StatWarn(st: String) -> Bool = Equals(st, "LOST") || Equals(st, "OVERHEAT") || StrBeginsWith(st, "RLD") || Equals(st, "OFF ARC") || Equals(st, "NO SOLN") || Equals(st, "HOT")

  public func StatColor(st: String) -> HDRColor {
    if Equals(st, "LOST") || Equals(st, "OVERHEAT") {
      return this.Pal().hostile;
    }
    if StrBeginsWith(st, "RLD") || Equals(st, "OFF ARC") || Equals(st, "NO SOLN") || Equals(st, "HOT") {
      return this.Pal().warn;
    }
    return this.Pal().accent;
  }

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.m_droot) || !IsDefined(this.m_ocMap) {
      return;
    }
    let cx = this.m_W * 0.5;
    let cy = 1080.0;

    this.m_ocLaserDia.SetOpacity(t.aimOk ? 1.0 : 0.25);
    let locked = IsDefined(t.lock);
    this.m_ocTrackRing.SetTintColor(locked ? this.Pal().warn : this.Lbl());
    this.m_ocTrackRing.SetOpacity(locked ? 1.0 : 0.5);
    this.m_ocLcue.SetVisible(t.aimOk);

    if t.aimOk {
      let dx = t.aim.X - t.pos.X;
      let dy = t.aim.Y - t.pos.Y;
      let brg = Rad2Deg(AtanF(dx, dy));
      CMHudText.Set(this.m_ocSlant, CMPilotHud.Pad4(RoundF(Vector4.Distance(t.pos, t.aim))) + " M");
      CMHudText.Set(this.m_ocBrg, CMPilotHud.Pad3(CMInk.Hdg(brg)));
      let dh = RoundF(t.aim.Z - t.pos.Z);
      CMHudText.Set(this.m_ocDh, (dh >= 0 ? "+" : "") + IntToString(dh) + " M");
      let spd = locked ? Vector4.Length(t.lock.vel) * 3.6 : 0.0;
      CMHudText.Set(this.m_ocSpd, (spd < 10.0 ? "0" : "") + IntToString(RoundF(spd)) + " KM/H");
      CMHudText.Set(this.m_ocTgtTag, spd > 3.0 ? CMText.DhudMoving() : CMText.DhudStatic());
    } else {
      CMHudText.Set(this.m_ocSlant, "---- M");
      CMHudText.Set(this.m_ocBrg, "---");
      CMHudText.Set(this.m_ocDh, "--- M");
      CMHudText.Set(this.m_ocSpd, "-- KM/H");
      CMHudText.Set(this.m_ocTgtTag, CMText.DhudNoLase());
    }

    let dep = ClampF(-t.camPitch, 0.0, 90.0);
    let ax = cx + 560.0;
    let ay = cy - 250.0;
    let a = Deg2Rad(270.0 - dep);
    let r = this.OC_DEP_R;
    CMInk.Seg(this.m_ocDepNeedle, ax + SinF(a) * (r - 34.0), ay - CosF(a) * (r - 34.0), ax + SinF(a) * (r + 10.0), ay - CosF(a) * (r + 10.0), 6.0);
    CMHudText.Set(this.m_ocDepT, CMText.DhudDep(IntToString(RoundF(dep))));

    let sp = t.ringOk && t.blastR > 0.0 && ArraySize(t.ring) == ArraySize(this.m_ocSplash);
    let topR = Vector2(0.0, 0.0);
    let best = -99999.0;
    let n = 0;
    while n < ArraySize(this.m_ocSplash) {
      let s = this.m_ocSplash[n];
      s.SetVisible(sp && n % 2 == 0);
      if sp {
        let p0 = t.ring[n];
        let p1 = t.ring[(n + 1) % ArraySize(t.ring)];
        CMInk.Seg(s, cx + p0.X, cy + p0.Y, cx + p1.X, cy + p1.Y, 3.0);
        let score = p0.X - p0.Y;
        if score > best {
          best = score;
          topR = Vector2(cx + p0.X, cy + p0.Y);
        }
      }
      n += 1;
    }
    this.m_ocLeader[0].SetVisible(sp);
    this.m_ocLeader[1].SetVisible(sp);
    this.m_ocSplashT.SetVisible(sp);
    this.m_ocSplashT2.SetVisible(sp);
    if sp {
      let kx = topR.X + 50.0;
      let ky = topR.Y - 50.0;
      CMInk.Seg(this.m_ocLeader[0], topR.X, topR.Y, kx, ky, 2.0);
      CMInk.Seg(this.m_ocLeader[1], kx, ky, kx + 170.0, ky, 2.0);
      this.m_ocSplashT.SetMargin(inkMargin(kx + 6.0, ky - 34.0, 0.0, 0.0));
      CMHudText.Set(this.m_ocSplashT, "x4   " + IntToString(RoundF(t.blastR)) + " M");
      this.m_ocSplashT2.SetMargin(inkMargin(kx + 6.0, ky + 8.0, 0.0, 0.0));
      CMHudText.Set(this.m_ocSplashT2, CMText.DhudTof(FloatToStringPrec(t.tof, 1)));
    }

    if !t.slow {
      return;
    }

    let c = this.OC_MAP_R;
    let k = this.OC_MPX;
    let lim = c - 8.0;
    this.m_ocSelf.SetRotation(-t.yaw);

    let fp: array<Vector2>;
    if t.footOk && ArraySize(t.foot) == 4 {
      ArrayPush(fp, Vector2(c, c));
      let f = 0;
      while f < 2 {
        let fx = (t.foot[f].X - t.pos.X) * k;
        let fy = -(t.foot[f].Y - t.pos.Y) * k;
        let len = SqrtF(fx * fx + fy * fy);
        if len > lim {
          fx *= lim / len;
          fy *= lim / len;
        }
        ArrayPush(fp, Vector2(c + fx, c + fy));
        f += 1;
      }
    }
    CMInk.FillFan(this.m_ocFan, ArraySize(fp) == 3, ArraySize(fp) == 3 ? fp[0] : Vector2(0.0, 0.0), ArraySize(fp) == 3 ? fp[1] : Vector2(0.0, 0.0), ArraySize(fp) == 3 ? fp[2] : Vector2(0.0, 0.0), 6.0);
    let ei = 0;
    while ei < ArraySize(this.m_ocFootEdge) {
      let eb = this.m_ocFootEdge[ei];
      eb.SetVisible(ArraySize(fp) == 3);
      if ArraySize(fp) == 3 {
        let p0 = fp[ei];
        let p1 = fp[(ei + 1) % 3];
        CMInk.Seg(eb, p0.X, p0.Y, p1.X, p1.Y, 3.0);
      }
      ei += 1;
    }

    CMHudText.Set(this.m_ocMts, this.m_ocSensor + "   " + (this.m_ocZoomed ? "NFOV " : "WFOV ") + FloatToStringPrec(t.fov, 1));

    let tx = 0.0;
    let ty = 0.0;
    let tOn = false;
    let standoff = 0.0;
    if t.aimOk {
      tx = (t.aim.X - t.pos.X) * k;
      ty = -(t.aim.Y - t.pos.Y) * k;
      standoff = SqrtF(tx * tx + ty * ty);
      tOn = standoff < lim;
    }
    this.m_ocTgtMark.SetVisible(tOn);
    this.m_ocTgtLbl.SetVisible(tOn);
    if tOn {
      this.m_ocTgtMark.SetMargin(inkMargin(c + tx - 12.0, c + ty - 12.0, 0.0, 0.0));
      this.m_ocTgtLbl.SetMargin(inkMargin(c + tx + 16.0, c + ty - 30.0, 0.0, 0.0));
    }
    let o = 0;
    while o < ArraySize(this.m_ocOrbit) {
      let s = this.m_ocOrbit[o];
      let show = tOn && t.hold && standoff > 6.0 && o % 2 == 0;
      s.SetVisible(show);
      if show {
        let a0 = Deg2Rad(Cast<Float>(o) * 11.25);
        let a1 = Deg2Rad(Cast<Float>(o + 1) * 11.25);
        CMInk.Seg(s, c + tx + SinF(a0) * standoff, c + ty - CosF(a0) * standoff, c + tx + SinF(a1) * standoff, c + ty - CosF(a1) * standoff, 3.0);
      }
      o += 1;
    }

    this.m_ocV.SetVisible(false);
    this.m_ocVLbl.SetVisible(false);
    let i = 0;
    let nn = Min(ArraySize(t.contacts), ArraySize(this.m_ocDots));
    while i < nn {
      let ct = t.contacts[i];
      let dx = (ct.pos.X - t.pos.X) * k;
      let dy = -(ct.pos.Y - t.pos.Y) * k;
      let show = SqrtF(dx * dx + dy * dy) < lim;
      let d = this.m_ocDots[i];
      if ct.kind == 0 {
        d.SetVisible(false);
        this.m_ocV.SetVisible(show);
        this.m_ocVLbl.SetVisible(show);
        this.m_ocV.SetMargin(inkMargin(c + dx - 8.0, c + dy - 8.0, 0.0, 0.0));
        this.m_ocVLbl.SetMargin(inkMargin(c + dx + 12.0, c + dy - 14.0, 0.0, 0.0));
      } else {
        d.SetVisible(show);
        if show {
          d.SetMargin(inkMargin(c + dx - 7.0, c + dy - 7.0, 0.0, 0.0));
          d.SetTintColor(this.MapColor(ct.kind));
        }
      }
      i += 1;
    }
    while i < ArraySize(this.m_ocDots) {
      this.m_ocDots[i].SetVisible(false);
      i += 1;
    }

    let acc = t.rounds > 0 ? RoundF(Cast<Float>(t.hits) * 100.0 / Cast<Float>(t.rounds)) : 0;
    if ArraySize(this.m_ocBdaV) >= 5 {
      CMHudText.Set(this.m_ocBdaV[0], IntToString(this.m_ocKills));
      CMHudText.Set(this.m_ocBdaV[1], IntToString(t.rounds));
      CMHudText.Set(this.m_ocBdaV[2], IntToString(t.hits));
      CMHudText.Set(this.m_ocBdaV[3], IntToString(acc) + "%");
      CMHudText.Set(this.m_ocBdaV[4], IntToString(t.hostiles));
      this.m_ocBdaV[4].SetTintColor(t.hostiles > 0 ? this.Pal().hostile : this.Hi());
    }
  }

  public func MapColor(kind: Int32) -> HDRColor {
    switch kind {
      case 0: return this.Pal().friendly;
      case 1: return this.Pal().broken;
      case 2: return this.Pal().hostile;
      case 4: return this.Pal().accent;
    }
    return this.Pal().neutral;
  }

  public func SetFlight(pitch: Float, roll: Float, speed: Float, alt: Float, vs: Float) -> Void {
    if !IsDefined(this.m_droot) {
      return;
    }
    CMInk.Text(this.m_speedText, FloatToStringPrec(speed, 1));
    CMInk.Text(this.m_altText, alt >= 0.0 ? CMPilotHud.Pad3(RoundF(alt)) : "---");
    CMInk.Text(this.m_vsText, CMText.DhudVs((vs >= 0.0 ? "+" : "") + FloatToStringPrec(vs, 1)));
  }

  public func Health(hp: Float) -> HDRColor {
    if hp < 0.3 {
      return this.Pal().hostile;
    }
    if hp < 0.6 {
      return this.Pal().warn;
    }
    return this.Pal().accent;
  }

  public static func Signed(v: Float) -> String {
    let n = RoundF(v);
    let a = Abs(n);
    return (n < 0 ? "-" : "+") + (a < 10 ? "0" : "") + IntToString(a);
  }

  public func StartBoot() -> Void {
    this.m_bootLeft = 1.0;
    if IsDefined(this.m_droot) {
      this.m_droot.SetOpacity(0.0);
    }
  }

  public func Boot(dt: Float) -> Void {
    if IsDefined(this.m_droot) && this.m_bootLeft > 0.0 {
      this.m_bootLeft -= dt;
      this.m_droot.SetOpacity(ClampF(1.0 - this.m_bootLeft, 0.0, 1.0) * RandRangeF(0.7, 1.0));
      if this.m_bootLeft <= 0.0 {
        this.m_droot.SetOpacity(1.0);
      }
    }

    if this.m_flashT > 0.0 && IsDefined(this.m_cross) {
      this.m_flashT -= dt;
      this.m_cross.SetTintColor(this.m_flashT > 0.0 ? this.Pal().warn : new HDRColor(1.0, 1.0, 1.0, 1.0));
    }
    if !IsDefined(this.m_droot) {
      return;
    }
    this.m_ocClock += dt;
    let ph = this.m_ocClock - Cast<Float>(FloorF(this.m_ocClock));
    this.m_ocRecDot.SetOpacity(ph < 0.5 ? 1.0 : 0.15);

    if this.m_ocThreatT > 0.0 {
      this.m_ocThreatT -= dt;
      let rel = this.m_ocThreatB - this.m_ocHeading;
      rel = CMPilotRig.Wrap(rel);
      let x = this.m_W * 0.5 + rel * this.HDG_PX;
      this.m_ocThreatTick.SetVisible(this.m_ocThreatT > 0.0 && AbsF(rel * this.HDG_PX) <= this.HDG_HALF);
      this.m_ocThreatTick.SetMargin(inkMargin(x - 3.0, 76.0, 0.0, 0.0));
      CMInk.Text(this.m_ocThreat, this.m_ocThreatT > 0.0 ? CMText.DhudThreat(CMPilotHud.Pad3(CMInk.Hdg(this.m_ocThreatB))) : "");
      let tp = this.m_ocThreatT * 2.0;
      this.m_ocThreat.SetOpacity(tp - Cast<Float>(FloorF(tp)) < 0.6 ? 1.0 : 0.4);
    } else {
      this.m_ocThreatTick.SetVisible(false);
      CMInk.Text(this.m_ocThreat, "");
    }
  }

  public func Tags(dt: Float) -> Void {}
  public func TagFlash(i: Int32) -> Void {}
  public func SetOptics(on: Bool) -> Void {}

  public func HitFrom(off: Float) -> Void {
    this.m_ocThreatT = 3.0;
    this.m_ocThreatB = this.m_ocHeading - off;
  }

  public func Hit(kill: Bool) -> Void {
    this.m_flashT = kill ? 0.5 : 0.15;
    if kill {
      this.m_ocKills += 1;
    }
  }

  public func PartHit(i: Int32) -> Void {}
  public func Damage(lost: Float) -> Void {}
}

public class CMDronePal {
  public let accent: HDRColor;
  public let ink: HDRColor;
  public let label: HDRColor;
  public let neutral: HDRColor;
  public let warn: HDRColor;
  public let hostile: HDRColor;
  public let friendly: HDRColor;
  public let broken: HDRColor;

  public static func Count() -> Int32 = 1

  public static func Of(kind: String, palette: Int32, opt typeB: Bool) -> ref<CMDronePal> {
    if typeB {
      return CMDronePal.OfB(kind);
    }
    let p = new CMDronePal();
    p.warn = new HDRColor(1.10, 0.64, 0.14, 1.0);
    p.hostile = new HDRColor(1.18, 0.30, 0.22, 1.0);
    p.friendly = new HDRColor(0.45, 0.85, 1.15, 1.0);
    p.broken = new HDRColor(0.40, 0.43, 0.41, 1.0);
    p.neutral = new HDRColor(0.80, 0.96, 0.82, 1.0);
    p.ink = new HDRColor(1.0, 1.0, 1.0, 1.0);
    switch kind {
      case "octant":
        p.accent = new HDRColor(0.34, 1.02, 0.46, 1.0);
        p.ink = new HDRColor(0.82, 1.05, 0.86, 1.0);
        p.label = new HDRColor(0.22, 0.70, 0.32, 1.0);
        break;
      case "griffin":
        p.accent = new HDRColor(0.40, 1.05, 0.52, 1.0);
        break;
      case "wyvern":
        p.accent = new HDRColor(0.62, 1.05, 1.00, 1.0);
        break;
      default:
        p.accent = new HDRColor(0.30, 1.00, 1.10, 1.0);
    }
    if !Equals(kind, "octant") {
      p.label = p.accent;
    }
    return p;
  }

  public static func OfB(kind: String) -> ref<CMDronePal> {
    let p = new CMDronePal();
    p.warn = new HDRColor(1.0, 0.69, 0.20, 1.0);
    p.hostile = new HDRColor(1.0, 0.20, 0.19, 1.0);
    p.friendly = new HDRColor(0.43, 0.94, 0.51, 1.0);
    p.broken = new HDRColor(0.36, 0.38, 0.36, 1.0);

    switch kind {
      case "octant":
        p.ink = new HDRColor(0.91, 0.89, 0.78, 1.0);
        p.accent = new HDRColor(0.88, 0.70, 0.14, 1.0);
        p.label = new HDRColor(0.54, 0.55, 0.44, 1.0);
        p.neutral = new HDRColor(0.70, 0.70, 0.62, 1.0);
        break;
      case "wyvern":
        p.ink = new HDRColor(0.89, 0.93, 0.93, 1.0);
        p.accent = new HDRColor(0.35, 0.84, 0.86, 1.0);
        p.label = new HDRColor(0.47, 0.54, 0.56, 1.0);
        p.neutral = new HDRColor(0.60, 0.67, 0.69, 1.0);
        break;
      case "griffin":
        p.ink = new HDRColor(0.93, 0.93, 0.90, 1.0);
        p.accent = new HDRColor(0.59, 1.0, 0.38, 1.0);
        p.label = new HDRColor(0.50, 0.55, 0.48, 1.0);
        p.neutral = new HDRColor(0.66, 0.70, 0.64, 1.0);
        break;
      default:
        p.ink = new HDRColor(0.93, 0.96, 0.96, 1.0);
        p.accent = new HDRColor(0.24, 0.90, 1.0, 1.0);
        p.label = new HDRColor(1.0, 0.24, 0.78, 1.0);
        p.neutral = new HDRColor(0.47, 0.59, 0.63, 1.0);
    }
    return p;
  }
}

public abstract class CMHudText {
  public static func Set(w: wref<inkText>, s: String) -> Void {
    if IsDefined(w) && NotEquals(w.GetText(), s) {
      CMInk.Text(w, s);
    }
  }
}

public abstract class CMDroneBHud extends CMBombusHud {

  protected func BPlateXY(root: ref<inkCanvas>, x0: Float, y0: Float, x1: Float, y1: Float, cutPx: Float, edge: HDRColor, flip: Bool) -> Void {
    this.PlateC(root, x0, y0, x1 - x0, y1 - y0, cutPx * 2.58, edge, flip);
  }

  protected func PlatesB() -> Void {}
}
