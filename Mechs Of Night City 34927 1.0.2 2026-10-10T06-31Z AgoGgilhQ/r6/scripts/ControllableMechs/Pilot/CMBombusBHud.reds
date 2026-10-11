module ControllableMechs

public class CMBombusBHud extends CMDroneBHud {
  private let m_bbName: array<ref<inkText>>;
  private let m_bbCells: array<ref<inkImage>>;
  private let m_bbVolt: ref<inkText>;
  private let m_bbBars: array<ref<inkImage>>;
  private let m_bbLink: ref<inkText>;
  private let m_bbCmp: ref<inkText>;
  private let m_bbHdg: ref<inkText>;
  private let m_bbTime: ref<inkText>;
  private let m_bbMode: ref<inkText>;
  private let m_bbRec: ref<inkImage>;
  private let m_bbSpd: ref<inkText>;
  private let m_bbRaw: ref<inkText>;
  private let m_bbAlt: ref<inkText>;
  private let m_bbVs: ref<inkText>;
  private let m_bbHome: ref<inkText>;
  private let m_bbHomeA: ref<inkCanvas>;
  private let m_bbWarn: ref<inkText>;
  private let m_bbTgtBars: array<ref<inkImage>>;
  private let m_bbTgtT: ref<inkText>;
  private let m_bbTgtD: ref<inkText>;
  private let m_bbRingSegs: array<ref<inkImage>>;
  private let m_bbRingFill: array<ref<inkRectangle>>;
  private let m_bbRingT: ref<inkText>;
  private let m_bbAhi: ref<inkCanvas>;
  private let m_bbMot: array<ref<CMSlider>>;
  private let m_bbThr: ref<CMSlider>;
  private let m_bbPr: ref<inkText>;
  private let m_bbTti: ref<inkText>;
  private let m_bbArm: ref<CMSlider>;
  private let m_bbPay: ref<inkText>;
  private let m_bbArmed: array<ref<inkText>>;
  private let m_bbKeys: ref<inkText>;
  private let m_bbSprite: array<ref<inkImage>>;
  private let m_bbHullB: array<ref<inkImage>>;
  private let m_bbHullT: ref<inkText>;
  private let m_bbT: Float;
  private let m_bbBoot: Float;
  private let m_bbRingOn: Bool;
  private let m_bbFire: String;
  private let m_bbThrV: Float;

  private func Cyn() -> HDRColor = this.Pal().accent
  private func Mag() -> HDRColor = this.Pal().label
  private func Lim() -> HDRColor = new HDRColor(0.80, 1.10, 0.30, 1.0)
  private func Gry() -> HDRColor = this.Pal().neutral

  private func Broken(root: ref<inkCanvas>, x0: Float, y0: Float, x1: Float, y1: Float, c: HDRColor, cut: Int32) -> Void {
    let x0s = x0 + 26.0;
    let x1s = x1 - 77.0;
    CMKit.Ln(root, x0s, y0, (cut == 0 ? 0.55 : 1.0) * (x1s - x0s), 3.0, c, 0.85);
    CMKit.Ln(root, x1 - 3.0, y0 + 36.0, 3.0, (cut == 1 ? 0.55 : 1.0) * (y1 - y0 - 51.0), c, 0.85);
    let bw = (cut == 2 ? 0.55 : 1.0) * (x1 - 21.0 - x0 - 103.0);
    CMKit.Ln(root, x1 - 21.0 - bw, y1 - 3.0, bw, 3.0, c, 0.85);
    let lh = (cut == 3 || cut == 0 ? 0.55 : 1.0) * (y1 - y0 - 87.0);
    CMKit.Ln(root, x0, y1 - 31.0 - lh, 3.0, lh, c, 0.85);
  }

  private func Glitch(root: ref<inkCanvas>, x: Float, y: Float, text: String, size: Float, align: Int32) -> Void {

    ArrayPush(this.m_bbName, this.BT(root, x + 3.0, y - 1.0, text, size, this.Cyn(), align));
    ArrayPush(this.m_bbName, this.BT(root, x, y, text, size, this.BInk(), align));
  }

  protected func BuildFeed(root: ref<inkCanvas>) -> Void {
    let y = 0.0;
    while y < 2160.0 {
      CMPilotHud.Bar(root, 0.0, y, this.FW(), 2.0, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.10);
      y += 5.1;
    }
    CMKit.Vignette(root, this.FW(), 2160.0, 220.0, 0.55);

    for ty in [this.BY(212.0), this.BY(506.0), this.BY(640.0)] {
      CMPilotHud.Bar(root, 0.0, ty, this.FW(), 3.0, new HDRColor(1.0, 1.0, 1.0, 1.0), 0.09);
      CMPilotHud.Bar(root, this.FW() * 0.2, ty + 4.0, this.FW() * 0.45, 2.0, this.Cyn(), 0.12);
    }
  }

  protected func BuildOsd(root: ref<inkCanvas>) -> Void {
    let tl = this.Rg(0, 0);
    let tc = this.Rg(1, 0);
    let tr = this.Rg(2, 0);
    let mc = this.Rg(1, 1);
    let bl = this.Rg(0, 2);
    let bc = this.Rg(1, 2);
    let cx = this.FW() * 0.5;
    let cy = 1080.0;

    let wm = this.BT(tc, cx, this.BY(4.0), CMText.BmbPirated(), 9.0, this.BInk(), 1);
    wm.SetOpacity(0.7);
    this.m_bbCmp = this.BT(tc, this.BC(1004.0), this.BY(30.0), "", 12.0, this.Gry(), 1);
    this.m_bbHdg = this.BT(tc, this.BC(998.0), this.BY(48.0), "", 15.0, this.Cyn(), 1);
    this.BT(tc, this.BC(1060.0), this.BY(50.0), "#", 12.0, this.Mag(), 0);

    this.Broken(tl, this.BC(318.0), this.BY(28.0), this.BC(640.0), this.BY(128.0), this.Cyn(), 0);
    this.Glitch(tl, this.BC(332.0), this.BY(34.0), "BMBS-7  ZETATECH", 22.0, 0);
    this.BT(tl, this.BC(332.0), this.BY(62.0), CMText.BmbBPatched(), 10.0, this.Mag(), 0);
    let i = 0;
    while i < 4 {
      ArrayPush(this.m_bbCells, CMKit.Fill(tl, this.BC(332.0 + Cast<Float>(i) * 15.0), this.BY(82.0), this.BL(11.0), this.BY(16.0), this.Cyn(), 1.0));
      i += 1;
    }
    CMKit.Fill(tl, this.BC(394.0), this.BY(86.0), 8.0, this.BY(8.0), this.BInk(), 1.0);
    this.m_bbVolt = this.BT(tl, this.BC(404.0), this.BY(80.0), "", 15.0, this.BInk(), 0);
    this.BT(tl, this.BC(458.0), this.BY(84.0), "4S/1300MAH", 9.0, this.Gry(), 0);
    i = 0;
    while i < 5 {
      let h = (4.0 + Cast<Float>(i) * 3.0) * 2.571;
      ArrayPush(this.m_bbBars, CMKit.Fill(tl, this.BC(544.0 + Cast<Float>(i) * 6.0), this.BY(98.0) - h, 8.0, h, this.Cyn(), 1.0));
      i += 1;
    }
    this.m_bbLink = this.BT(tl, this.BC(332.0), this.BY(106.0), "", 9.0, this.Gry(), 0);

    this.Broken(tr, this.BC(1500.0), this.BY(28.0), this.BC(1694.0), this.BY(128.0), this.Cyn(), 2);
    this.m_bbTime = this.BT(tr, this.BC(1684.0), this.BY(34.0), "", 20.0, this.BInk(), 2);
    this.m_bbMode = this.BT(tr, this.BC(1684.0), this.BY(58.0), "", 11.0, this.Gry(), 2);
    CMKit.Ln(tr, this.BC(1610.0), this.BY(64.0), this.BL(70.0), 5.0, this.Mag(), 0.9);
    this.BT(tr, this.BC(1684.0), this.BY(66.0), CMText.BmbBAcroNo(), 11.0, this.Lim(), 2);
    this.m_bbRec = CMKit.Disc(tr, this.BC(1519.0), this.BY(95.0), 13.0, this.Pal().hostile, 1.0);
    this.BT(tr, this.BC(1684.0), this.BY(88.0), "REC  R7 5917 600MW", 10.0, this.Mag(), 2);
    this.BT(tr, this.BC(1684.0), this.BY(106.0), "VTX.TEMP 61C  !", 9.0, this.Pal().warn, 2);

    this.BT(mc, this.BC(1001.0), this.BY(407.0), "-[+]-", 18.0, this.BInk(), 1);
    CMInk.Line(mc, this.BC(870.0), cy, this.BC(920.0), cy + 5.0, 5.0, this.Cyn(), 1.0);
    CMInk.Line(mc, this.BC(1080.0), cy + 3.0, this.BC(1132.0), cy - 3.0, 5.0, this.Cyn(), 1.0);
    this.m_bbHome = this.BT(mc, cx, this.BY(442.0), "", 12.0, this.Lim(), 1);
    let ha = new inkCanvas();
    ha.SetMargin(inkMargin(this.BC(1060.0) - 20.0, this.BY(450.0) - 20.0, 0.0, 0.0));
    ha.SetSize(Vector2(40.0, 40.0));
    ha.SetRenderTransformPivot(Vector2(0.5, 0.5));
    ha.Reparent(mc);
    CMKit.Img(ha, n"tri", 8.0, 2.0, 24.0, 22.0, this.Lim(), 1.0);
    CMKit.Fill(ha, 16.0, 20.0, 8.0, 18.0, this.Lim(), 1.0);
    this.m_bbHomeA = ha;
    this.m_bbSpd = this.BT(mc, this.BC(700.0), this.BY(408.0), "", 15.0, this.BInk(), 2);
    this.m_bbRaw = this.BT(mc, this.BC(704.0), this.BY(428.0), "", 9.0, this.Gry(), 2);
    this.m_bbAlt = this.BT(mc, this.BC(1296.0), this.BY(410.0), "", 15.0, this.BInk(), 0);
    this.m_bbVs = this.BT(mc, this.BC(1300.0), this.BY(430.0), "", 10.0, this.Gry(), 0);
    this.m_bbWarn = this.BT(mc, cx, this.BY(330.0), "", 18.0, this.Pal().hostile, 1);

    this.m_bbTgtBars = CMKit.Corners(root, this.Mag(), 1.0, false);
    this.m_bbTgtT = this.BT(root, 0.0, 0.0, "", 11.0, this.Mag(), 1);
    this.m_bbTgtT.SetAnchorPoint(Vector2(0.5, 1.0));
    this.m_bbTgtD = this.BT(root, 0.0, 0.0, "", 10.0, this.Mag(), 1);
    this.m_bbRingFill = CMInk.FillBars(root, 64, this.Pal().warn, 0.2);
    i = 0;
    while i < 32 {
      ArrayPush(this.m_bbRingSegs, CMKit.Stroke(root, this.Pal().warn, 0.9));
      i += 1;
    }
    this.m_bbRingT = this.BT(root, 0.0, 0.0, "", 10.0, this.Pal().warn, 1);
    this.m_bbRingT.SetAnchorPoint(Vector2(0.5, 1.0));

    this.Broken(bl, this.BC(326.0), this.BY(686.0), this.BC(444.0), this.BY(782.0), this.Cyn(), 1);
    let box = new inkCanvas();
    box.SetMargin(inkMargin(this.BC(326.0), this.BY(686.0), 0.0, 0.0));
    box.SetSize(Vector2(this.BL(118.0), this.BY(96.0)));
    box.Reparent(bl);
    let bar = new inkCanvas();
    bar.SetMargin(inkMargin(this.BL(14.0), this.BY(48.0) - 3.0, 0.0, 0.0));
    bar.SetSize(Vector2(this.BL(90.0), 6.0));
    bar.SetRenderTransformPivot(Vector2(0.5, 0.5));
    bar.Reparent(box);
    CMKit.Pill(bar, 0.0, 0.0, this.BL(90.0), 6.0, this.Cyn(), 1.0);
    this.m_bbAhi = bar;
    CMKit.Ln(box, this.BL(46.0), this.BY(50.0) - 2.5, this.BL(26.0), 5.0, this.BInk(), 1.0);
    i = 0;
    while i < 4 {
      let mx = this.BC(462.0 + Cast<Float>(i) * 16.0);
      ArrayPush(this.m_bbMot, CMSlider.Make(bl, mx, this.BY(706.0), 23.0, this.BY(74.0), true, this.Cyn()));
      this.BT(bl, mx + 11.0, this.BY(688.0), "M" + IntToString(i + 1), 8.0, this.Gry(), 1);
      i += 1;
    }
    this.m_bbThr = CMSlider.Make(bl, this.BC(532.0), this.BY(706.0), 15.0, this.BY(74.0), true, this.Lim());
    this.m_bbPr = this.BT(bl, this.BC(326.0), this.BY(788.0), "", 9.0, this.Gry(), 0);

    this.Broken(bc, this.BC(826.0), this.BY(646.0), this.BC(1174.0), this.BY(780.0), this.Mag(), 3);
    this.m_bbTti = this.BT(bc, cx, this.BY(654.0), "", 12.0, this.BInk(), 1);
    this.m_bbArm = CMSlider.Make(bc, this.BC(850.0), this.BY(674.0), this.BL(300.0), 15.0, false, this.Pal().warn);
    this.m_bbPay = this.BT(bc, cx, this.BY(688.0), "", 12.0, this.Lim(), 1);
    ArrayPush(this.m_bbArmed, this.BT(bc, this.BC(924.0) - 3.0, this.BY(708.0) + 1.0, "", 24.0, this.Mag(), 0));
    ArrayPush(this.m_bbArmed, this.BT(bc, this.BC(924.0) + 3.0, this.BY(708.0) - 1.0, "", 24.0, this.Cyn(), 0));
    ArrayPush(this.m_bbArmed, this.BT(bc, this.BC(924.0), this.BY(708.0), "", 24.0, this.BInk(), 0));
    this.BT(bc, cx, this.BY(740.0), CMText.BmbInterlock(), 10.0, this.Pal().warn, 1);
    this.m_bbKeys = this.BT(bc, cx, this.BY(758.0), "", 10.0, this.Gry(), 1);

    let cols = [this.Cyn(), this.Mag(), this.Lim(), this.BInk()];
    i = 0;
    while i < 18 {
      let top = i % 2 == 0;
      let bx = this.BC(top ? 560.0 : 1120.0) + Cast<Float>((i * 37) % 160);
      let by = this.BY(top ? 104.0 : 700.0) + Cast<Float>((i * 23) % (top ? 40 : 76));
      CMPilotHud.Bar(top ? tl : bc, bx, by, Cast<Float>(5 + (i * 7) % 9), 3.0, cols[i % 4], 0.6);
      i += 1;
    }
  }

  protected func BuildSprite(root: ref<inkCanvas>) -> Void {
    let br = this.Rg(2, 2);
    let k = this.BL(76.0) / 408.0;
    let box = new inkCanvas();
    box.SetMargin(inkMargin(this.BC(1588.0), this.BY(676.0), 0.0, 0.0));
    box.SetSize(Vector2(408.0 * k, 360.0 * k));
    box.Reparent(br);
    this.BbPart(box, k, n"bombus_arm_back", 81.0, 5.0, 137.0, 99.0);
    this.BbPart(box, k, n"bombus_arm_l", 297.0, 69.0, 107.0, 119.0);
    this.BbPart(box, k, n"bombus_arm_r", 5.0, 156.0, 139.0, 112.0);
    this.BbPart(box, k, n"bombus_body", 82.0, 40.0, 253.0, 253.0);
    this.BbPart(box, k, n"bombus_payload", 191.0, 205.0, 130.0, 150.0);
    let i = 0;
    while i < 5 {
      ArrayPush(this.m_bbHullB, CMKit.Fill(br, this.BC(1580.0 + Cast<Float>(i) * 18.0), this.BY(758.0), this.BL(14.0), this.BY(8.0), this.Cyn(), 1.0));
      i += 1;
    }
    this.m_bbHullT = this.BT(br, this.BC(1580.0), this.BY(772.0), "", 9.0, this.Gry(), 0);
  }

  private func BbPart(box: ref<inkCanvas>, k: Float, name: CName, x: Float, y: Float, w: Float, h: Float) -> Void {
    let img = new inkImage();
    img.SetAtlasResource(CMDroneHud.Atlas());
    img.SetTexturePart(name);
    img.SetMargin(inkMargin(x * k, y * k, 0.0, 0.0));
    img.SetSize(Vector2(w * k, h * k));
    img.SetTintColor(this.Cyn());
    img.SetInteractive(false);
    img.Reparent(box);
    ArrayPush(this.m_bbSprite, img);
  }

  private static func Pt(h: Int32) -> String {
    let p = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    let i = ((h + 22) / 45) % 8;
    return p[i];
  }

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    let sig = ClampF(s.signal, 0.0, 1.0);
    CMInk.Text(this.m_bbLink, "RSSI " + IntToString(RoundF(sig * 99.0)) + "  LQ " + IntToString(Clamp(RoundF(sig * 100.0) + 1, 0, 100)) + "  0X5F  CRC:OK");
    let n = 0;
    while n < ArraySize(this.m_bbBars) {
      this.m_bbBars[n].SetOpacity(sig * 5.0 > Cast<Float>(n) + 0.5 ? 1.0 : 0.2);
      n += 1;
    }
    let h = (s.heading % 360 + 360) % 360;
    CMInk.Text(this.m_bbCmp, CMBombusBHud.Pt((h + 270) % 360) + " . . | . . " + CMBombusBHud.Pt(h) + " . . | . . " + CMBombusBHud.Pt((h + 90) % 360));
    CMInk.Text(this.m_bbHdg, ">>" + CMPilotHud.Pad3(h) + CMBombusBHud.Pt(h) + "<<");
    CMInk.Text(this.m_bbMode, CMText.BmbBMode(s.terText));
    if s.home < 900.0 {
      this.m_bbHomeA.SetVisible(true);
      this.m_bbHomeA.SetRotation(s.home + 180.0);
      CMInk.Text(this.m_bbHome, CMText.BmbBHome(IntToString(RoundF(s.distance))));
    } else {
      this.m_bbHomeA.SetVisible(false);
      CMInk.Text(this.m_bbHome, "");
    }
    let warn = s.warning;
    if sig < 0.35 {
      warn = CMText.BmbLinkWeak();
    } else {
      if s.integrity < 0.3 {
        warn = CMText.BmbHullCritical();
      }
    }
    CMInk.Text(this.m_bbWarn, warn);
    CMInk.Text(this.m_bbPay, s.priText);
    let ai = 0;
    for t in this.m_bbArmed {
      CMInk.Text(t, "> " + s.secText + "_");
      if ai < 2 {
        t.SetOpacity(0.35);
      }
      ai += 1;
    }
    let pl = GetPlayer(GetGameInstance());
    this.m_bbRingOn = CMPilotSystem.Get(GetGameInstance()).Flag("blastRing", true);
    if StrLen(this.m_bbFire) == 0 {
      this.m_bbFire = CMKeyName.Game(n"ShootPrimary", "LMB");
    }
    CMInk.Text(this.m_bbKeys, CMText.BmbBHint(this.m_bbFire, CMKeys.DeclutterName(pl), this.m_bbRingOn ? CMText.BmbOn() : CMText.BmbOff()));

    let hull = ClampF(s.integrity, 0.0, 1.0);
    let c = hull < 0.3 ? this.Pal().hostile : (hull < 0.6 ? this.Pal().warn : this.Cyn());
    let b = 0;
    while b < ArraySize(this.m_bbHullB) {
      this.m_bbHullB[b].SetOpacity(hull * 5.0 > Cast<Float>(b) + 0.15 ? 1.0 : 0.15);
      this.m_bbHullB[b].SetTintColor(b == 3 && hull > 0.6 ? this.Mag() : c);
      b += 1;
    }
    CMInk.Text(this.m_bbHullT, CMText.BmbBHull(IntToString(RoundF(hull * 100.0))) + "  CHK 0XA1");
    for img in this.m_bbSprite {
      img.SetTintColor(c);
    }
    this.m_bbThrV = ClampF(s.spool, 0.0, 1.0);
    this.m_bbThr.Set(this.m_bbThrV, this.Lim());
  }

  public func SetFlight(pitch: Float, roll: Float, speed: Float, alt: Float, vs: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_bbAhi.SetRotation(-roll);
    this.m_bbAhi.SetMargin(inkMargin(this.BL(14.0), this.BY(48.0) - 3.0 + ClampF(pitch, -45.0, 45.0) * 1.6, 0.0, 0.0));
    CMInk.Text(this.m_bbSpd, CMText.BmbBSpd(IntToString(RoundF(speed * 3.6))));
    CMInk.Text(this.m_bbRaw, CMText.BmbRaw(FloatToStringPrec(speed, 2)));
    CMInk.Text(this.m_bbAlt, CMText.BmbBAlt(alt >= 0.0 ? FloatToStringPrec(alt, 1) : "---"));
    CMInk.Text(this.m_bbVs, CMText.BmbBVs((vs >= 0.0 ? "+" : "") + FloatToStringPrec(vs, 1)));
    this.m_bbPrPitch = pitch;
    this.m_bbPrRoll = roll;
  }

  private let m_bbPrPitch: Float;
  private let m_bbPrRoll: Float;

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.FRoot()) || ArraySize(this.m_bbTgtBars) < 4 {
      return;
    }
    let cx = this.FW() * 0.5;
    let cy = 1080.0;
    let c = t.lock;
    let show = IsDefined(c) && c.OnScreen();
    for bb in this.m_bbTgtBars {
      bb.SetVisible(show);
    }
    this.m_bbTgtT.SetVisible(show);
    this.m_bbTgtD.SetVisible(show);
    if show {
      let scale = 1080.0 / TanF(Deg2Rad(MaxF(1.0, t.fov) * 0.5));
      let hh = ClampF(1.9 / MaxF(1.0, c.dist) * scale, 100.0, 600.0);
      let hw = MaxF(80.0, hh * 0.55);
      let x = cx + c.scr.X - hw * 0.5;
      let y = cy + c.scr.Y - hh * 0.5;
      CMKit.PlaceCorners(this.m_bbTgtBars, 0, x, y, hw, hh, MinF(31.0, hw * 0.4));

      this.m_bbTgtT.SetMargin(inkMargin(x + hw * 0.5 + 15.0, y - 8.0, 0.0, 0.0));
      CMInk.Text(this.m_bbTgtT, CMText.BmbBTgt(c.Label()));
      this.m_bbTgtD.SetMargin(inkMargin(x + hw * 0.5 - 10.0, y + hh + 8.0, 0.0, 0.0));
      CMInk.Text(this.m_bbTgtD, IntToString(RoundF(c.dist)) + "M  ID:0X" + StrUpper(CMBombusBHud.Hex4(RoundF(c.dist * 977.0) + 4096)));
    }

    let ring = this.m_bbRingOn && t.armed && t.ringOk && ArraySize(t.ring) == ArraySize(this.m_bbRingSegs);
    let vIn = false;
    if ArraySize(t.contacts) > 0 && t.contacts[0].kind == 0 && t.aimOk {
      vIn = Vector4.Distance(t.contacts[0].pos, t.aim) <= t.blastR + 1.0;
    }
    let rc = vIn ? this.Pal().hostile : this.Pal().warn;
    let top = 99999.0;
    let topX = cx;
    let i = 0;
    while i < ArraySize(this.m_bbRingSegs) {
      let b = this.m_bbRingSegs[i];
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
    CMInk.FillPoly(this.m_bbRingFill, fill);
    for fb in this.m_bbRingFill {
      fb.SetTintColor(rc);
    }
    this.m_bbRingT.SetVisible(ring);
    if ring {
      this.m_bbRingT.SetMargin(inkMargin(cx + topX, cy + top - 8.0, 0.0, 0.0));
      CMInk.Text(this.m_bbRingT, vIn ? CMText.BmbDangerClose() : CMText.BmbBBlast(IntToString(RoundF(t.blastR))));
      this.m_bbRingT.SetTintColor(rc);
    }

    if !t.slow {
      return;
    }

    let ph = t.now * 4.0 - Cast<Float>(FloorF(t.now * 4.0));
    let close = t.armed && t.tti >= 0.0 && t.tti < 2.0;
    this.m_bbArm.Set(t.armed ? 1.0 : 0.0, close || vIn ? this.Pal().hostile : this.Pal().warn);
    this.m_bbArm.fill.SetOpacity(close && ph > 0.5 ? 0.3 : 1.0);
    if !t.armed {
      CMInk.Text(this.m_bbTti, t.blastR > 0.0 ? "" : CMText.BmbNoPayload());
    } else {
      CMInk.Text(this.m_bbTti, t.tti >= 0.0 ? CMText.BmbImpact(FloatToStringPrec(t.tti, 1)) : CMText.BmbBImpactNone());
    }
    this.m_bbTti.SetTintColor(close ? this.Pal().hostile : this.BInk());

    let pwm = "";
    let m = 0;
    while m < ArraySize(this.m_bbMot) {
      let v = m < ArraySize(t.motors) ? ClampF(t.motors[m], 0.0, 1.0) : 0.0;
      this.m_bbMot[m].Set(v, v > 0.95 ? this.Pal().hostile : this.Cyn());
      pwm = pwm + (m > 0 ? "/" : "") + IntToString(1000 + RoundF(v * 1000.0));
      m += 1;
    }
    CMInk.Text(this.m_bbPr, CMText.BmbBPr(CMDroneHud.Signed(this.m_bbPrPitch), CMDroneHud.Signed(this.m_bbPrRoll), IntToString(RoundF(this.m_bbThrV * 100.0)), pwm));
  }

  private static func Hex4(v: Int32) -> String {
    let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];
    let s = "";
    let i = 0;
    let n = v;
    while i < 4 {
      s = digits[n % 16] + s;
      n = n / 16;
      i += 1;
    }
    return s;
  }

  public func StartBoot() -> Void {
    this.m_bbBoot = 1.2;
    this.m_bbT = 0.0;
    if IsDefined(this.FRoot()) {
      this.FRoot().SetOpacity(0.0);
    }
  }

  public func Boot(dt: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_bbT += dt;
    if this.m_bbBoot > 0.0 {
      this.m_bbBoot = MaxF(0.0, this.m_bbBoot - dt);
      this.FRoot().SetOpacity(1.0 - this.m_bbBoot / 1.2);
    }
    let secs = FloorF(this.m_bbT);
    let mm = secs / 60;
    let ss = secs % 60;
    CMInk.Text(this.m_bbTime, (mm < 10 ? "0" : "") + IntToString(mm) + ":" + (ss < 10 ? "0" : "") + IntToString(ss));
    let cell = MaxF(3.3, 4.2 - this.m_bbT / 240.0 * 0.8);
    CMInk.Text(this.m_bbVolt, FloatToStringPrec(cell * 4.0, 1) + "V");
    let frac = ClampF((cell - 3.3) / 0.9, 0.0, 1.0);
    let i = 0;
    while i < ArraySize(this.m_bbCells) {
      this.m_bbCells[i].SetOpacity(frac * 4.0 > Cast<Float>(i) + 0.15 ? 1.0 : 0.15);
      this.m_bbCells[i].SetTintColor(frac < 0.25 ? this.Pal().hostile : this.Cyn());
      i += 1;
    }
    let ph = this.m_bbT - Cast<Float>(FloorF(this.m_bbT));
    this.m_bbRec.SetOpacity(ph < 0.5 ? 1.0 : 0.15);

    let g = this.m_bbT * 7.0 - Cast<Float>(FloorF(this.m_bbT * 7.0));
    let k = 0;
    while k < ArraySize(this.m_bbName) {
      if k % 3 != 2 {
        this.m_bbName[k].SetOpacity(g < 0.1 ? 0.15 : 0.35);
      }
      k += 1;
    }
  }

  public func Hit(kill: Bool) -> Void {}
}
