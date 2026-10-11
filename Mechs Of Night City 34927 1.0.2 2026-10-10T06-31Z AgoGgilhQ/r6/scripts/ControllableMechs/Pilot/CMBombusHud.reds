module ControllableMechs

import Codeware.UI.ScreenHelper

public class CMBombusHud extends CMDroneHud {
  private let m_fRoot: ref<inkCanvas>;
  private let m_fParent: wref<inkCompoundWidget>;
  private let m_fHidden: array<wref<inkWidget>>;
  private let m_fHiddenOp: array<Float>;
  private let m_fW: Float;
  private let m_fX0: Float;
  private let m_fTexts: array<ref<inkText>>;
  private let m_fShadows: array<ref<inkText>>;
  private let m_fSet: array<String>;
  private let m_fAhi: ref<inkCanvas>;
  private let m_fHome: ref<inkCanvas>;
  private let m_fSprite: array<ref<inkImage>>;
  private let m_fRec: ref<inkImage>;
  private let m_fCells: array<ref<inkImage>>;
  private let m_fBars: array<ref<inkImage>>;
  private let m_fThrS: ref<CMSlider>;
  private let m_fBand: ref<inkImage>;
  private let m_fClock: Float;
  private let m_fBlink: Float;
  private let m_fHitT: Float;
  private let m_fBoot: Float;

  private let m_fTgtBars: array<ref<inkImage>>;
  private let m_fTgtT: ref<inkText>;
  private let m_fTgtD: ref<inkText>;
  private let m_fRingSegs: array<ref<inkImage>>;
  private let m_fRingT: ref<inkText>;
  private let m_fRingFill: array<ref<inkRectangle>>;
  private let m_fArmS: ref<CMSlider>;
  private let m_fRingOn: Bool;
  private let m_fFireKey: String;
  private let m_fTti: ref<inkText>;
  private let m_fMotS: array<ref<CMSlider>>;
  private let m_fHullB: array<ref<inkImage>>;
  private let m_fRaw: ref<inkText>;
  private let m_fPwm: ref<inkText>;

  private let T_NAME: Int32 = 0;
  private let T_BAT: Int32 = 1;
  private let T_LINK: Int32 = 2;
  private let T_TIME: Int32 = 3;
  private let T_MODE: Int32 = 4;
  private let T_SPD: Int32 = 5;
  private let T_ALT: Int32 = 6;
  private let T_THR: Int32 = 7;
  private let T_PAY: Int32 = 8;
  private let T_ARM: Int32 = 9;
  private let T_WARN: Int32 = 10;
  private let T_HINT: Int32 = 11;
  private let T_REC: Int32 = 12;
  private let T_VS: Int32 = 13;
  private let T_HDG: Int32 = 14;
  private let T_CMPL: Int32 = 15;
  private let T_CMPR: Int32 = 16;
  private let T_HOME: Int32 = 17;
  private let T_HULL: Int32 = 19;
  private let T_PIT: Int32 = 20;

  protected func Ink() -> HDRColor = this.Pal().ink
  protected func Acc() -> HDRColor = this.Pal().accent
  protected func Blk() -> HDRColor = new HDRColor(0.0, 0.0, 0.0, 1.0)

  protected func FW() -> Float = this.m_fW
  protected func FRoot() -> ref<inkCanvas> = this.m_fRoot

  protected func BL(x: Float) -> Float = x * 2.58
  protected func BR(x: Float) -> Float = this.FW() - (2000.0 - x) * 2.58
  protected func BC(x: Float) -> Float = this.FW() * 0.5 + (x - 1000.0) * 2.58
  protected func BY(y: Float) -> Float = y * 2.571
  protected func BZ(s: Float) -> Int32 = RoundF(s * 2.58)
  protected func BInk() -> HDRColor = this.Pal().ink
  protected func BAcc() -> HDRColor = this.Pal().accent
  protected func BDim() -> HDRColor = this.Pal().label
  protected func BDark() -> HDRColor = new HDRColor(0.03, 0.04, 0.05, 1.0)
  protected func BT(root: ref<inkCanvas>, x: Float, y: Float, text: String, size: Float, c: HDRColor, align: Int32) -> ref<inkText> {
    let t = CMPilotHud.Label(root, inkEAnchor.TopLeft, x, y, text, this.BZ(size), n"Semi-Bold", c);
    if align != 0 {
      t.SetAnchorPoint(Vector2(align == 1 ? 0.5 : 1.0, 0.0));
    }
    return t;
  }

  public func Build() -> Bool {
    let layer = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
    if !IsDefined(layer) {
      return false;
    }
    let window = layer.GetVirtualWindow();
    if !IsDefined(window) {
      return false;
    }
    this.m_fParent = window;
    ArrayClear(this.m_fHidden);
    ArrayClear(this.m_fHiddenOp);
    let i = 0;
    while i < window.GetNumChildren() {
      let child = window.GetWidgetByIndex(i);
      if IsDefined(child) && NotEquals(child.GetName(), n"cm_bombus_hud") {
        ArrayPush(this.m_fHidden, child);
        ArrayPush(this.m_fHiddenOp, child.GetOpacity());
        child.SetOpacity(0.0);
      }
      i += 1;
    }
    let root = new inkCanvas();
    root.SetName(n"cm_bombus_hud");
    root.SetInteractive(false);
    let screen = ScreenHelper.GetScreenSize(GetGameInstance());
    this.m_fW = 3840.0;
    if screen.Y > 100.0 {
      let k = screen.Y / 2160.0;
      this.m_fW = screen.X / k;
      root.SetAnchor(inkEAnchor.TopLeft);
      root.SetSize(Vector2(this.m_fW, 2160.0));
      root.SetRenderTransformPivot(Vector2(0.0, 0.0));
      root.SetScale(Vector2(k, k));
    } else {
      root.SetAnchor(inkEAnchor.Fill);
    }
    root.Reparent(window);
    this.m_fRoot = root;

    this.m_fX0 = MaxF(0.0, this.m_fW * 0.5 - 1920.0);
    this.BuildFeed(root);

    this.MakeRegions(root, this.m_fW);
    if this.TypeB() {
      this.PlatesB();
    }
    this.BuildOsd(root);
    this.BuildSprite(root);
    return true;
  }

  public func Remove() -> Void {
    if IsDefined(this.m_fRoot) && IsDefined(this.m_fParent) {
      this.m_fRoot.StopAllAnimations();
      this.m_fParent.RemoveChild(this.m_fRoot);
    }
    this.m_fRoot = null;
    let i = 0;
    while i < ArraySize(this.m_fHidden) {
      let w = this.m_fHidden[i];
      if IsDefined(w) {
        w.SetOpacity(this.m_fHiddenOp[i]);
      }
      i += 1;
    }
    ArrayClear(this.m_fHidden);
    ArrayClear(this.m_fHiddenOp);
    ArrayClear(this.m_fTexts);
    ArrayClear(this.m_fShadows);
    ArrayClear(this.m_fSet);
    ArrayClear(this.m_fSprite);
    ArrayClear(this.m_fCells);
    ArrayClear(this.m_fBars);
    ArrayClear(this.m_fTgtBars);
    ArrayClear(this.m_fRingSegs);
    ArrayClear(this.m_fMotS);
    ArrayClear(this.m_fHullB);
  }

  protected func PlatesB() -> Void {
    let x0 = this.m_fX0;
    let x1 = x0 + MinF(3840.0, this.m_fW);
    let cx = this.m_fW * 0.5;
    let mag = this.Pal().label;
    let cyn = this.Acc();
    let dim = this.Pal().neutral;

    for ty in [560.0, 1292.0, 1650.0] {
      CMPilotHud.Bar(this.m_fRoot, 0.0, ty, this.m_fW, 2.0, this.Ink(), 0.10);
      CMPilotHud.Bar(this.m_fRoot, 120.0, ty + 3.0, this.m_fW * 0.4, 1.0, cyn, 0.12);
    }
    let wm = CMPilotHud.Label(this.Rg(1, 0), inkEAnchor.TopLeft, cx, 14.0, CMText.BmbPirated(), 22, n"Medium", this.Ink());
    wm.SetAnchorPoint(Vector2(0.5, 0.0));
    wm.SetOpacity(0.6);

    this.BDash(this.Rg(0, 0), x0 + 170.0, 80.0, 560.0, 180.0, cyn, 1);
    this.BDash(this.Rg(2, 0), x1 - 470.0, 80.0, 300.0, 170.0, cyn, 4);
    this.BDash(this.Rg(1, 2), cx - 400.0, 1690.0, 800.0, 300.0, mag, 2);
    this.BDash(this.Rg(0, 2), x0 + 170.0, 1756.0, 430.0, 230.0, cyn, 7);

    CMPilotHud.Label(this.Rg(0, 0), inkEAnchor.TopLeft, x0 + 194.0, 102.0, "BMBS-7  ZETATECH", 30, n"Semi-Bold", mag).SetOpacity(0.8);
    CMPilotHud.Label(this.Rg(0, 0), inkEAnchor.TopLeft, x0 + 206.0, 98.0, "BMBS-7  ZETATECH", 30, n"Semi-Bold", cyn).SetOpacity(0.8);

    CMPilotHud.Label(this.Rg(0, 0), inkEAnchor.TopLeft, x0 + 480.0, 110.0, CMText.BmbPatched(), 18, n"Medium", mag);
    CMPilotHud.Label(this.Rg(0, 0), inkEAnchor.TopLeft, x0 + 480.0, 152.0, "4S / 1300MAH", 18, n"Medium", dim);
    CMPilotHud.Label(this.Rg(0, 0), inkEAnchor.TopLeft, x0 + 500.0, 206.0, "0X5F  CRC:OK", 18, n"Medium", dim);
    let vt = CMPilotHud.Label(this.Rg(2, 0), inkEAnchor.TopLeft, x1 - 200.0, 230.0, "VTX.TEMP 61C  !", 18, n"Medium", this.Pal().warn);
    vt.SetAnchorPoint(Vector2(1.0, 0.0));
    let ib = CMPilotHud.Label(this.Rg(1, 2), inkEAnchor.TopLeft, cx, 1956.0, CMText.BmbInterlock(), 20, n"Medium", this.Pal().warn);
    ib.SetAnchorPoint(Vector2(0.5, 0.0));
    CMPilotHud.Label(this.Rg(2, 2), inkEAnchor.TopLeft, x1 - 412.0, 1962.0, "CHK 0XA1", 16, n"Medium", dim);
    this.m_fRaw = CMPilotHud.Label(this.Rg(0, 1), inkEAnchor.TopLeft, cx - 771.0, 1104.0, "", 20, n"Medium", dim);
    this.m_fRaw.SetAnchorPoint(Vector2(1.0, 0.0));
    this.m_fPwm = CMPilotHud.Label(this.Rg(0, 2), inkEAnchor.TopLeft, x0 + 200.0, 2024.0, "", 18, n"Medium", dim);

    let cols = [cyn, mag, this.Ink(), cyn, mag];
    let i = 0;
    while i < 14 {
      let bx = (i % 2 == 0 ? x0 + 640.0 : cx + 300.0) + Cast<Float>((i * 37) % 90);
      let by = (i % 2 == 0 ? 230.0 : 1800.0) + Cast<Float>((i * 23) % 60);
      let rg = i % 2 == 0 ? this.Rg(0, 0) : this.Rg(1, 2);
      CMPilotHud.Bar(rg, bx, by, Cast<Float>(6 + (i * 5) % 12), 3.0, cols[i % 5], 0.6);
      i += 1;
    }
  }

  protected func BuildFeed(root: ref<inkCanvas>) -> Void {
    let y = 0.0;
    while y < 2160.0 {
      CMPilotHud.Bar(root, 0.0, y, this.m_fW, 2.0, this.Blk(), 0.10);
      y += 7.0;
    }

    CMKit.Vignette(root, this.m_fW, 2160.0, 220.0, 0.55);
    this.m_fBand = CMKit.Img(root, n"pill_glow_h", 0.0, 0.0, this.m_fW, 40.0, this.Ink(), 0.05);
  }

  protected func Osd(root: ref<inkCanvas>, x: Float, y: Float, size: Int32, align: Int32) -> Void {
    let sh = CMPilotHud.Label(root, inkEAnchor.TopLeft, x + 3.0, y + 3.0, "", size, n"Semi-Bold", this.Blk());
    let t = CMPilotHud.Label(root, inkEAnchor.TopLeft, x, y, "", size, n"Semi-Bold", this.Ink());
    sh.SetOpacity(0.85);
    if align != 0 {
      let a = align == 1 ? 0.5 : 1.0;
      sh.SetAnchorPoint(Vector2(a, 0.0));
      t.SetAnchorPoint(Vector2(a, 0.0));
    }
    ArrayPush(this.m_fTexts, t);
    ArrayPush(this.m_fShadows, sh);
    ArrayPush(this.m_fSet, "");
  }

  protected func SetT(i: Int32, text: String) -> Void {
    if i < ArraySize(this.m_fTexts) && NotEquals(this.m_fSet[i], text) {
      this.m_fSet[i] = text;
      CMInk.Text(this.m_fTexts[i], text);
      CMInk.Text(this.m_fShadows[i], text);
    }
  }

  protected func Tint(i: Int32, c: HDRColor) -> Void {
    if i < ArraySize(this.m_fTexts) {
      this.m_fTexts[i].SetTintColor(c);
    }
  }

  protected func Brackets(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float) -> Void {
    let L = 26.0;
    let c = this.Acc();
    CMKit.Brackets(root, x, y, w, h, L, c, 0.8);
  }

  protected func BuildOsd(root: ref<inkCanvas>) -> Void {
    let x0 = this.m_fX0;
    let x1 = x0 + MinF(3840.0, this.m_fW);
    let cx = this.m_fW * 0.5;
    let cy = 1080.0;

    let tl = this.Rg(0, 0);
    let tc = this.Rg(1, 0);
    let tr = this.Rg(2, 0);
    let ml = this.Rg(0, 1);
    let mc = this.Rg(1, 1);
    let mr = this.Rg(2, 1);
    let bl = this.Rg(0, 2);
    let bc = this.Rg(1, 2);
    let br = this.Rg(2, 2);

    this.Osd(tl, x0 + 200.0, 100.0, 30, 0);
    this.Osd(tl, x0 + 340.0, 142.0, 34, 0);
    this.Osd(tl, x0 + 300.0, 202.0, 26, 0);
    this.Osd(tr, x1 - 200.0, 100.0, 38, 2);
    this.Osd(tr, x1 - 200.0, 148.0, 26, 2);
    this.Osd(ml, cx - 771.0, 1050.0, 40, 2);
    this.Osd(mr, cx + 771.0, 1050.0, 40, 0);
    this.Osd(bl, x0 + 330.0, 1990.0, 24, 0);
    this.Osd(bc, cx, 1800.0, 30, 1);
    this.Osd(bc, cx, 1840.0, 50, 1);
    this.Osd(mc, cx, 820.0, 46, 1);
    this.Osd(bc, cx, 1926.0, 24, 1);
    this.Osd(tr, x1 - 200.0, 194.0, 24, 2);
    this.Osd(mr, cx + 771.0, 1100.0, 26, 0);
    this.Osd(tc, cx, 128.0, 30, 1);
    this.Osd(tc, cx - 280.0, 96.0, 26, 1);
    this.Osd(tc, cx + 280.0, 96.0, 26, 1);
    this.Osd(mc, cx + 10.0, 1136.0, 26, 0);
    this.Osd(tr, 0.0, 0.0, 10, 2);
    this.Osd(br, x1 - 412.0, 1934.0, 20, 0);
    this.Osd(bl, x0 + 200.0, 1990.0, 22, 0);

    let c = 0;
    while c < 4 {
      ArrayPush(this.m_fCells, CMKit.Fill(tl, x0 + 200.0 + Cast<Float>(c) * 30.0, 148.0, 24.0, 32.0, this.Acc(), 1.0));
      c += 1;
    }
    CMKit.Img(tl, n"pill_v", x0 + 320.0, 156.0, 7.0, 16.0, this.Ink(), 0.9);
    let b = 0;
    while b < 5 {
      let h = 10.0 + Cast<Float>(b) * 8.0;
      ArrayPush(this.m_fBars, CMKit.VPill(tl, x0 + 200.0 + Cast<Float>(b) * 18.0, 236.0 - h, 11.0, h, this.Ink(), 1.0));
      b += 1;
    }

    let k = -6;
    while k <= 6 {
      let tall = k % 3 == 0;
      CMKit.Ln(tc, cx + Cast<Float>(k) * 40.0 - 1.5, 166.0, 3.0, tall ? 18.0 : 10.0, this.Ink(), 0.7);
      k += 1;
    }
    CMKit.Img(tc, n"tri", cx - 7.0, 188.0, 14.0, 12.0, this.Acc(), 1.0);

    CMKit.Ln(mc, cx - 54.0, cy - 2.0, 34.0, 4.0, this.Ink(), 0.95);
    CMKit.Ln(mc, cx + 20.0, cy - 2.0, 34.0, 4.0, this.Ink(), 0.95);
    CMKit.Ln(mc, cx - 2.0, cy - 11.0, 4.0, 22.0, this.Ink(), 0.95);
    CMKit.Ln(mc, cx - 334.0, cy - 2.0, 104.0, 4.0, this.Ink(), 0.8);
    CMKit.Ln(mc, cx + 230.0, cy - 2.0, 104.0, 4.0, this.Ink(), 0.8);

    let home = new inkCanvas();
    home.SetMargin(inkMargin(cx - 46.0, 1124.0, 0.0, 0.0));
    home.SetSize(Vector2(52.0, 52.0));
    home.SetRenderTransformPivot(Vector2(0.5, 0.5));
    home.Reparent(mc);
    CMKit.Img(home, n"tri", 14.0, 4.0, 24.0, 22.0, this.Acc(), 1.0);
    CMKit.VPill(home, 22.0, 22.0, 7.0, 24.0, this.Acc(), 1.0);
    this.m_fHome = home;

    let ax = x0 + 200.0;
    let ay = 1800.0;
    let box = new inkCanvas();
    box.SetMargin(inkMargin(ax, ay, 0.0, 0.0));
    box.SetSize(Vector2(200.0, 160.0));
    box.Reparent(bl);
    CMKit.Disc(box, 4.0, 4.0, 3.0, this.Ink(), 1.0);
    CMKit.Disc(box, 196.0, 4.0, 3.0, this.Ink(), 1.0);
    CMKit.Disc(box, 4.0, 156.0, 3.0, this.Ink(), 1.0);
    CMKit.Disc(box, 196.0, 156.0, 3.0, this.Ink(), 1.0);
    let bar = new inkCanvas();
    bar.SetMargin(inkMargin(25.0, 78.0, 0.0, 0.0));
    bar.SetSize(Vector2(150.0, 4.0));
    bar.SetRenderTransformPivot(Vector2(0.5, 0.5));
    bar.Reparent(box);
    CMKit.Pill(bar, 0.0, -1.0, 150.0, 5.0, this.Acc(), 1.0);
    CMKit.VPill(bar, 71.0, 4.0, 7.0, 12.0, this.Acc(), 0.7);
    this.m_fAhi = bar;

    CMKit.Ln(box, 56.0, 77.0, 30.0, 5.0, this.Ink(), 1.0);
    CMKit.Ln(box, 114.0, 77.0, 30.0, 5.0, this.Ink(), 1.0);
    CMKit.Disc(box, 100.0, 80.0, 5.0, this.Ink(), 1.0);

    let tx = ax + 230.0;
    this.m_fThrS = CMSlider.Make(bl, tx, ay, 10.0, 164.0, true, this.Acc());
    this.m_fRec = CMKit.Disc(tr, x1 - 430.0, 208.0, 9.0, this.Pal().hostile, 1.0);
    this.m_fFireKey = CMKeyName.Game(n"ShootPrimary", "LMB");
    this.SetT(this.T_HINT, CMText.BmbDetonate(this.m_fFireKey));
    this.SetT(this.T_REC, "R7  600MW");
    this.SetT(this.T_HULL, CMText.BmbHull());
    this.Tint(this.T_REC, this.Acc());
    this.Tint(this.T_MODE, this.Acc());
    this.Tint(this.T_HULL, this.Acc());
    this.Tint(this.T_ARM, this.Acc());
    this.Tint(this.T_WARN, this.Pal().hostile);
    this.BuildStrike(root, ax, ay, tx);
  }

  private func BuildStrike(root: ref<inkCanvas>, ax: Float, ay: Float, tx: Float) -> Void {
    let cx = this.m_fW * 0.5;
    this.m_fTgtBars = CMKit.Corners(root, this.Ink(), 1.0, false);
    let n = 0;
    this.m_fTgtT = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, "", 28, n"Semi-Bold", this.Ink());
    this.m_fTgtT.SetAnchorPoint(Vector2(0.5, 1.0));
    this.m_fTgtD = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, "", 28, n"Semi-Bold", this.Ink());
    this.m_fTgtD.SetAnchorPoint(Vector2(0.5, 0.0));
    this.m_fRingFill = CMInk.FillBars(root, 64, this.Pal().warn, 0.2);
    n = 0;
    while n < 32 {
      ArrayPush(this.m_fRingSegs, CMKit.Stroke(root, this.Pal().warn, 0.9));
      n += 1;
    }
    this.m_fRingT = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, "", 26, n"Semi-Bold", this.Pal().warn);
    this.m_fRingT.SetAnchorPoint(Vector2(0.5, 1.0));

    let bc = this.Rg(1, 2);
    let bl = this.Rg(0, 2);
    this.m_fArmS = CMSlider.Make(bc, cx - 360.0, 1770.0, 720.0, 8.0, false, this.Pal().warn);
    this.m_fTti = CMPilotHud.Label(bc, inkEAnchor.TopLeft, cx, 1716.0, "", 28, n"Semi-Bold", this.Ink());
    this.m_fTti.SetAnchorPoint(Vector2(0.5, 0.0));

    let m = 0;
    while m < 4 {
      let mx = tx + 40.0 + Cast<Float>(m) * 24.0;
      ArrayPush(this.m_fMotS, CMSlider.Make(bl, mx, ay, 12.0, 164.0, true, this.Acc()));
      let l = CMPilotHud.Label(bl, inkEAnchor.TopLeft, mx + 6.0, ay - 30.0, IntToString(m + 1), 18, n"Semi-Bold", this.Ink());
      l.SetAnchorPoint(Vector2(0.5, 0.0));
      m += 1;
    }    this.FTgtShow(false);
  }

  private func FTgtShow(on: Bool) -> Void {
    for b in this.m_fTgtBars {
      b.SetVisible(on);
    }
    this.m_fTgtT.SetVisible(on);
    this.m_fTgtD.SetVisible(on);
  }

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.m_fRoot) || ArraySize(this.m_fTgtBars) < 4 {
      return;
    }
    let cx = this.m_fW * 0.5;
    let cy = 1080.0;

    let c = t.lock;
    if IsDefined(c) && c.OnScreen() {
      this.FTgtShow(true);
      let col = c.kind == 2 ? this.Pal().hostile : CMInk.KindColor(c.kind, this.Acc());
      let scale = 1080.0 / TanF(Deg2Rad(MaxF(1.0, t.fov) * 0.5));
      let hh = ClampF(1.9 / MaxF(1.0, c.dist) * scale, 70.0, 600.0);
      let hw = MaxF(60.0, hh * 0.55);
      let x = cx + c.scr.X - hw * 0.5;
      let y = cy + c.scr.Y - hh * 0.5;
      let L = MinF(40.0, hw * 0.4);
      CMKit.PlaceCorners(this.m_fTgtBars, 0, x, y, hw, hh, L);
      CMKit.ShowCorners(this.m_fTgtBars, 0, true, col);
      this.m_fTgtT.SetMargin(inkMargin(x + hw * 0.5, y - 8.0, 0.0, 0.0));
      CMInk.Text(this.m_fTgtT, CMText.BmbTgt(c.Label()));
      this.m_fTgtT.SetTintColor(col);
      this.m_fTgtD.SetMargin(inkMargin(x + hw * 0.5, y + hh + 8.0, 0.0, 0.0));
      CMInk.Text(this.m_fTgtD, IntToString(RoundF(c.dist)) + " M");
      this.m_fTgtD.SetTintColor(col);
    } else {
      this.FTgtShow(false);
    }

    let ring = this.m_fRingOn && t.armed && t.ringOk && ArraySize(t.ring) == ArraySize(this.m_fRingSegs);
    let vIn = false;
    if ArraySize(t.contacts) > 0 && t.contacts[0].kind == 0 && t.aimOk {
      vIn = Vector4.Distance(t.contacts[0].pos, t.aim) <= t.blastR + 1.0;
    }
    let rc = vIn ? this.Pal().hostile : this.Pal().warn;
    let top = 99999.0;
    let topX = cx;
    let i = 0;
    while i < ArraySize(this.m_fRingSegs) {
      let b = this.m_fRingSegs[i];
      b.SetVisible(ring);
      if ring {
        let p = t.ring[i];
        let q = t.ring[(i + 1) % ArraySize(t.ring)];
        CMInk.Seg(b, cx + p.X, cy + p.Y, cx + q.X, cy + q.Y, 4.0);
        b.SetTintColor(rc);
        if p.Y < top {
          top = p.Y;
          topX = p.X;
        }
      }
      i += 1;
    }
    let fill: array<Vector2>;
    if ring {
      for o in t.ring {
        ArrayPush(fill, Vector2(cx + o.X, cy + o.Y));
      }
    }
    CMInk.FillPoly(this.m_fRingFill, fill);
    for fb in this.m_fRingFill {
      fb.SetTintColor(rc);
    }
    this.m_fRingT.SetVisible(ring);
    if ring {
      this.m_fRingT.SetMargin(inkMargin(cx + topX, cy + top - 8.0, 0.0, 0.0));
      CMInk.Text(this.m_fRingT, vIn ? CMText.BmbDangerClose() : CMText.BmbBlast(IntToString(RoundF(t.blastR))));
      this.m_fRingT.SetTintColor(rc);
    }

    if !t.slow {
      return;
    }

    let ph = t.now * 4.0 - Cast<Float>(FloorF(t.now * 4.0));
    let close = t.armed && t.tti >= 0.0 && t.tti < 2.0;
    this.m_fArmS.Set(t.armed ? 1.0 : 0.0, close || vIn ? this.Pal().hostile : this.Pal().warn);
    this.m_fArmS.fill.SetOpacity(close && ph > 0.5 ? 0.3 : 1.0);
    if !t.armed {
      CMInk.Text(this.m_fTti, t.blastR > 0.0 ? "" : CMText.BmbNoPayload());
    } else {
      CMInk.Text(this.m_fTti, t.tti >= 0.0 ? CMText.BmbImpact(FloatToStringPrec(t.tti, 1)) : CMText.BmbImpactNone());
    }
    this.m_fTti.SetTintColor(close ? this.Pal().hostile : this.Ink());

    let pwm = "PWM";
    let m = 0;
    while m < ArraySize(this.m_fMotS) {
      let v = m < ArraySize(t.motors) ? ClampF(t.motors[m], 0.0, 1.0) : 0.0;
      this.m_fMotS[m].Set(v, v > 0.95 ? this.Pal().hostile : this.Acc());
      pwm = pwm + " " + IntToString(1000 + RoundF(v * 1000.0));
      m += 1;
    }
    if IsDefined(this.m_fPwm) {
      CMInk.Text(this.m_fPwm, pwm);
    }
  }

  protected func BuildSprite(root: ref<inkCanvas>) -> Void {

    let x1 = this.m_fX0 + MinF(3840.0, this.m_fW);

    let k = 206.0 / 408.0;
    let bx = x1 - 200.0 - 408.0 * k;
    let by = 1750.0;
    let br = this.Rg(2, 2);
    let box = new inkCanvas();
    box.SetMargin(inkMargin(bx, by, 0.0, 0.0));
    box.SetSize(Vector2(408.0 * k, 360.0 * k));
    box.Reparent(br);
    let hb = 0;
    while hb < 5 {
      ArrayPush(this.m_fHullB, CMKit.Fill(br, x1 - 412.0 + 66.0 + Cast<Float>(hb) * 30.0, 1940.0, 24.0, 12.0, this.Acc(), 1.0));
      hb += 1;
    }
    this.Layer(box, k, n"bombus_arm_back", 81.0, 5.0, 137.0, 99.0);
    this.Layer(box, k, n"bombus_arm_l", 297.0, 69.0, 107.0, 119.0);
    this.Layer(box, k, n"bombus_arm_r", 5.0, 156.0, 139.0, 112.0);
    this.Layer(box, k, n"bombus_body", 82.0, 40.0, 253.0, 253.0);
    this.Layer(box, k, n"bombus_payload", 191.0, 205.0, 130.0, 150.0);
  }

  protected func Layer(box: ref<inkCanvas>, k: Float, name: CName, x: Float, y: Float, w: Float, h: Float) -> Void {
    let img = new inkImage();
    img.SetAtlasResource(CMDroneHud.Atlas());
    img.SetTexturePart(name);
    img.SetMargin(inkMargin(x * k, y * k, 0.0, 0.0));
    img.SetSize(Vector2(w * k, h * k));
    img.SetTintColor(this.Acc());
    img.SetInteractive(false);
    img.Reparent(box);
    ArrayPush(this.m_fSprite, img);
  }

  private static func Point(h: Int32) -> String {
    let p = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    let i = ((h + 22) / 45) % 8;
    return p[i];
  }

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.m_fRoot) {
      return;
    }
    this.SetT(this.T_NAME, this.TypeB() ? "BMBS-7  ZETATECH" : s.title);
    let sig = ClampF(s.signal, 0.0, 1.0);
    this.SetT(this.T_LINK, "RSSI " + IntToString(RoundF(sig * 99.0)) + "  LQ " + IntToString(Clamp(RoundF(sig * 100.0) + 1, 0, 100)));
    let n = 0;
    while n < ArraySize(this.m_fBars) {
      this.m_fBars[n].SetOpacity(sig * 5.0 > Cast<Float>(n) + 0.5 ? 1.0 : 0.2);
      n += 1;
    }
    this.SetT(this.T_PAY, s.priText);
    let pl = GetPlayer(GetGameInstance());
    this.m_fRingOn = CMPilotSystem.Get(GetGameInstance()).Flag("blastRing", true);
    this.SetT(this.T_HINT, CMText.BmbHint(this.m_fFireKey, CMKeys.DeclutterName(pl), this.m_fRingOn ? CMText.BmbOn() : CMText.BmbOff()));
    this.SetT(this.T_ARM, s.secText);
    this.SetT(this.T_MODE, s.terText);

    let h = (s.heading % 360 + 360) % 360;
    this.SetT(this.T_HDG, (h < 100 ? (h < 10 ? "00" : "0") : "") + IntToString(h) + " " + CMBombusHud.Point(h));
    this.SetT(this.T_CMPL, CMBombusHud.Point((h + 270) % 360));
    this.SetT(this.T_CMPR, CMBombusHud.Point((h + 90) % 360));

    if s.home < 900.0 {
      this.m_fHome.SetVisible(true);
      this.m_fHome.SetRotation(s.home + 180.0);
      this.SetT(this.T_HOME, CMText.BmbHome(IntToString(RoundF(s.distance))));
    } else {
      this.m_fHome.SetVisible(false);
      this.SetT(this.T_HOME, "");
    }

    let warn = s.warning;
    if sig < 0.35 {
      warn = CMText.BmbLinkWeak();
    } else {
      if s.integrity < 0.3 {
        warn = CMText.BmbHullCritical();
      }
    }
    this.SetT(this.T_WARN, warn);

    let hull = ClampF(s.integrity, 0.0, 1.0);
    let c = hull < 0.3 ? this.Pal().hostile : (hull < 0.6 ? this.Pal().warn : this.Acc());
    let hb = 0;
    while hb < ArraySize(this.m_fHullB) {
      this.m_fHullB[hb].SetOpacity(hull * 5.0 > Cast<Float>(hb) + 0.15 ? 1.0 : 0.15);
      this.m_fHullB[hb].SetTintColor(c);
      hb += 1;
    }
    for img in this.m_fSprite {
      img.SetTintColor(c);
    }

    let thr = ClampF(s.spool, 0.0, 1.0);
    this.m_fThrS.Set(thr, this.Acc());
    this.SetT(this.T_THR, CMText.BmbThr(IntToString(RoundF(thr * 100.0))));
  }

  public func SetFlight(pitch: Float, roll: Float, speed: Float, alt: Float, vs: Float) -> Void {
    if !IsDefined(this.m_fRoot) {
      return;
    }

    this.m_fAhi.SetRotation(-roll);
    this.m_fAhi.SetMargin(inkMargin(25.0, 108.0 + ClampF(pitch, -45.0, 45.0) * 2.0, 0.0, 0.0));
    this.SetT(this.T_PIT, CMText.BmbPitchRoll(IntToString(RoundF(pitch)), IntToString(RoundF(roll))));
    this.SetT(this.T_SPD, IntToString(RoundF(speed * 3.6)) + " KMH");
    if IsDefined(this.m_fRaw) {
      CMInk.Text(this.m_fRaw, CMText.BmbRaw(FloatToStringPrec(speed, 2)));
    }
    this.SetT(this.T_ALT, alt >= 0.0 ? FloatToStringPrec(alt, 1) + " M" : "--- M");
    this.SetT(this.T_VS, (vs >= 0.0 ? "+" : "") + FloatToStringPrec(vs, 1) + " M/S");
  }

  public func SetAttitude(heading: Float, pitch: Float) -> Void {}
  public func SetImpact(on: Bool, x: Float, y: Float, tof: Float) -> Void {}

  public func StartBoot() -> Void {
    this.m_fBoot = 1.2;
    this.m_fClock = 0.0;
    if IsDefined(this.m_fRoot) {
      this.m_fRoot.SetOpacity(0.0);
    }
  }

  public func Boot(dt: Float) -> Void {
    if !IsDefined(this.m_fRoot) {
      return;
    }
    this.m_fClock += dt;
    this.m_fBlink += dt;
    if this.m_fBoot > 0.0 {
      this.m_fBoot = MaxF(0.0, this.m_fBoot - dt);
      this.m_fRoot.SetOpacity(1.0 - this.m_fBoot / 1.2);
    }
    let secs = FloorF(this.m_fClock);
    let mm = secs / 60;
    let ss = secs % 60;
    this.SetT(this.T_TIME, (mm < 10 ? "0" : "") + IntToString(mm) + ":" + (ss < 10 ? "0" : "") + IntToString(ss));
    let cell = MaxF(3.3, 4.2 - this.m_fClock / 240.0 * 0.8);
    this.SetT(this.T_BAT, FloatToStringPrec(cell * 4.0, 1) + "V");
    let frac = ClampF((cell - 3.3) / 0.9, 0.0, 1.0);
    let i = 0;
    while i < ArraySize(this.m_fCells) {

      let on = frac * 4.0 > Cast<Float>(i) + 0.15;
      this.m_fCells[i].SetOpacity(on ? 1.0 : 0.12);
      this.m_fCells[i].SetTintColor(frac < 0.25 ? this.Pal().hostile : this.Acc());
      i += 1;
    }
    let ph = this.m_fBlink - Cast<Float>(FloorF(this.m_fBlink));
    this.m_fRec.SetOpacity(ph < 0.5 ? 1.0 : 0.15);

    let roll = this.m_fBlink / 3.5;
    this.m_fBand.SetMargin(inkMargin(0.0, (roll - Cast<Float>(FloorF(roll))) * 2160.0, 0.0, 0.0));
    if this.m_fHitT > 0.0 {
      this.m_fHitT = MaxF(0.0, this.m_fHitT - dt);
      this.m_fBand.SetOpacity(this.m_fHitT > 0.0 ? 0.25 : 0.05);
    }
  }

  public func Hit(kill: Bool) -> Void {
    this.m_fHitT = kill ? 0.25 : 0.1;
  }
}
