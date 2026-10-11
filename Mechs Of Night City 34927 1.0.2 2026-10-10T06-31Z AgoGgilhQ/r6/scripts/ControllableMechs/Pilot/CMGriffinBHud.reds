module ControllableMechs

public class CMGriffinBHud extends CMDroneBHud {
  private let m_gbKillsT: ref<inkText>;
  private let m_gbMarks: array<ref<inkImage>>;
  private let m_gbStreak: ref<inkText>;
  private let m_gbHold: ref<inkText>;
  private let m_gbHoldChev: array<ref<inkImage>>;
  private let m_gbTicks: array<ref<inkImage>>;
  private let m_gbTickL: array<ref<inkText>>;
  private let m_gbHdg: ref<inkText>;
  private let m_gbBars: array<ref<inkImage>>;
  private let m_gbLink: ref<inkText>;
  private let m_gbClock: ref<inkText>;
  private let m_gbHeatArc: array<ref<inkWidget>>;
  private let m_gbHeatL: ref<inkText>;
  private let m_gbHeatR: ref<inkText>;
  private let m_gbRockets: array<ref<inkCanvas>>;
  private let m_gbRng: ref<inkText>;
  private let m_gbLockBars: array<ref<inkImage>>;
  private let m_gbLockPlate: ref<inkCanvas>;
  private let m_gbLockT: ref<inkText>;
  private let m_gbLockD: ref<inkText>;
  private let m_gbLockHp: ref<CMMtMeter>;
  private let m_gbLead: ref<inkCanvas>;
  private let m_gbHostBars: array<ref<inkImage>>;
  private let m_gbThreat: array<ref<inkCanvas>>;
  private let m_gbThreatT: array<Float>;
  private let m_gbThreatA: array<Float>;
  private let m_gbSpd: ref<inkText>;
  private let m_gbSpool: ref<CMMtMeter>;
  private let m_gbAlt: ref<inkText>;
  private let m_gbVs: ref<inkText>;
  private let m_gbAtt: ref<inkText>;
  private let m_gbNeedle: ref<inkImage>;
  private let m_gbTab: array<ref<inkImage>>;
  private let m_gbTabT: array<ref<inkText>>;
  private let m_gbBand: array<ref<inkImage>>;
  private let m_gbWpnT: array<ref<inkText>>;
  private let m_gbWpnSt: array<ref<inkText>>;
  private let m_gbRk: array<ref<inkImage>>;
  private let m_gbPodTag: ref<inkText>;
  private let m_gbSprite: array<ref<inkImage>>;
  private let m_gbPodS: array<ref<CMSlider>>;
  private let m_gbHull: ref<CMMtMeter>;
  private let m_gbWarn: ref<inkText>;
  private let m_gbT: Float;
  private let m_gbBoot: Float;
  private let m_gbKills: Int32;
  private let m_gbStreakN: Int32;
  private let m_gbLastKill: Float;

  private let GB_PX: Float = 15.5;
  private let GB_HALF: Float = 464.0;
  private let GB_HEAT_N: Int32 = 11;
  private let GB_GAUGE_R: Float = 83.0;

  private func Cy() -> Float = this.BY(418.0)

  protected func BuildFeed(root: ref<inkCanvas>) -> Void {
    CMKit.Vignette(root, this.FW(), 2160.0, 160.0, 0.3);
    let y = 0.0;
    while y < 2160.0 {
      CMPilotHud.Bar(root, 0.0, y, this.FW(), 2.0, new HDRColor(0.0, 0.0, 0.0, 1.0), 0.04);
      y += 7.7;
    }
  }

  protected func BuildOsd(root: ref<inkCanvas>) -> Void {
    let W = this.FW();
    let cx = W * 0.5;
    let cy = this.Cy();
    let tl = this.Rg(0, 0);
    let tc = this.Rg(1, 0);
    let tr = this.Rg(2, 0);
    let mc = this.Rg(1, 1);
    let bl = this.Rg(0, 2);
    this.BFrame(this.Face(), W);

    this.BPlateXY(tl, this.BL(26.0), this.BY(20.0), this.BL(372.0), this.BY(92.0), 14.0, this.BDim(), false);
    this.BHazard(tl, this.BL(30.0), this.BY(26.0), this.BL(14.0), this.BY(60.0));
    this.BT(tl, this.BL(54.0), this.BY(22.0), "MT-GRF  GRIFFIN", 30.0, this.BInk(), 0);
    this.BT(tl, this.BL(56.0), this.BY(60.0), CMText.GrfBRole(), 13.0, this.BDim(), 0);
    this.BT(tl, this.BL(362.0), this.BY(26.0), CMText.GrfBKills(), 11.0, this.BDim(), 2);
    this.m_gbKillsT = this.BT(tl, this.BL(362.0), this.BY(42.0), "00", 20.0, this.BAcc(), 2);
    this.BPlateXY(tl, this.BL(26.0), this.BY(98.0), this.BL(372.0), this.BY(124.0), 8.0, this.BDim(), false);
    let i = 0;
    while i < 10 {
      ArrayPush(this.m_gbMarks, CMKit.Nine(tl, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), this.BL(36.0 + Cast<Float>(i) * 22.0), this.BY(104.0), this.BL(16.0), this.BY(14.0), this.BAcc(), 1.0));
      i += 1;
    }
    this.m_gbStreak = this.BT(tl, this.BL(362.0), this.BY(102.0), "", 12.0, this.Pal().warn, 2);

    this.BPlateXY(tc, this.BC(850.0), this.BY(14.0), this.BC(1150.0), this.BY(46.0), 10.0, this.Pal().warn, false);
    let side = -1;
    while side <= 1 {
      let k = 0;
      while k < 3 {
        let x = this.BC(1000.0 + Cast<Float>(side) * (100.0 + Cast<Float>(k) * 12.0));
        let chev = CMKit.Img(tc, n"chev_r", side > 0 ? x : x - 26.0, this.BY(22.0), 26.0, 41.0, this.Pal().warn, 1.0);
        if side < 0 {
          chev.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
        }
        ArrayPush(this.m_gbHoldChev, chev);
        k += 1;
      }
      side += 2;
    }
    this.m_gbHold = this.BT(tc, cx, this.BY(17.0), CMText.GrfWeaponsHold(), 20.0, this.Pal().warn, 1);
    i = 0;
    while i < 15 {
      ArrayPush(this.m_gbTicks, CMKit.Img(tc, n"pill_v", cx, this.BY(74.0), 4.0, 31.0, this.BInk(), 0.85));
      i += 1;
    }
    i = 0;
    while i < 6 {
      ArrayPush(this.m_gbTickL, this.BT(tc, cx, this.BY(54.0), "", 13.0, this.BInk(), 1));
      i += 1;
    }
    this.BPlateXY(tc, this.BC(956.0), this.BY(92.0), this.BC(1044.0), this.BY(118.0), 8.0, this.BAcc(), false);
    this.m_gbHdg = this.BT(tc, cx, this.BY(94.0), "", 17.0, this.BInk(), 1);

    this.BPlateXY(tr, this.BR(1760.0), this.BY(20.0), this.BR(1972.0), this.BY(74.0), 14.0, this.BDim(), true);
    i = 0;
    while i < 5 {
      let h = (6.0 + Cast<Float>(i) * 4.0) * 2.571;
      ArrayPush(this.m_gbBars, CMKit.Img(tr, n"pill_v", this.BR(1776.0 + Cast<Float>(i) * 8.0), this.BY(52.0) - h, 13.0, h, this.BAcc(), 1.0));
      i += 1;
    }
    this.m_gbLink = this.BT(tr, this.BR(1824.0), this.BY(26.0), "", 16.0, this.BInk(), 0);
    this.m_gbClock = this.BT(tr, this.BR(1958.0), this.BY(48.0), "", 15.0, this.BDim(), 2);

    CMInk.Circle(mc, cx, cy, 62.0, this.BInk(), 1.0);
    CMKit.Disc(mc, cx, cy, 8.0, this.BInk(), 1.0);
    let track = CMInk.Ring(mc, cx, cy, 113.0, 36, 13.0, this.BDim(), 0.5);
    let lit = CMInk.Ring(mc, cx, cy, 113.0, 36, 13.0, this.Pal().warn, 1.0);
    let q = 0;
    while q < 36 {
      let a = Cast<Float>(q) * 10.0;
      track[q].SetVisible((a >= 220.0 && a <= 320.0) || (a >= 40.0 && a <= 140.0));
      lit[q].SetVisible(false);
      q += 1;
    }
    for j in [22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4] {
      ArrayPush(this.m_gbHeatArc, lit[j]);
    }
    this.m_gbHeatL = this.BT(mc, this.BC(944.0), cy + this.BY(34.0), "", 11.0, this.BDim(), 2);
    this.m_gbHeatR = this.BT(mc, this.BC(1056.0), cy + this.BY(34.0), "", 11.0, this.BDim(), 0);
    let rk = 0;
    while rk < 2 {
      let rc = new inkCanvas();
      rc.SetMargin(inkMargin(this.BC(990.0 + Cast<Float>(rk) * 20.0) - 8.0, cy + this.BY(58.0), 0.0, 0.0));
      rc.SetSize(Vector2(16.0, 62.0));
      rc.Reparent(mc);
      CMKit.Img(rc, n"tri", 0.0, 0.0, 16.0, 21.0, new HDRColor(1.0, 1.0, 1.0, 1.0), 1.0);
      CMKit.Fill(rc, 0.0, 20.0, 16.0, 42.0, new HDRColor(1.0, 1.0, 1.0, 1.0), 1.0);
      rc.SetTintColor(this.BInk());
      ArrayPush(this.m_gbRockets, rc);
      rk += 1;
    }
    this.BPlateXY(mc, this.BC(950.0), cy + this.BY(92.0), this.BC(1050.0), cy + this.BY(114.0), 6.0, this.BDim(), false);
    this.m_gbRng = this.BT(mc, cx, cy + this.BY(94.0), "", 13.0, this.BInk(), 1);
    this.m_gbWarn = this.BT(mc, cx, this.BY(250.0), "", 18.0, this.Pal().hostile, 1);

    this.BPlateXY(mc, this.BC(700.0), cy - this.BY(22.0), this.BC(786.0), cy + this.BY(22.0), 8.0, this.BInk(), false);
    this.m_gbSpd = this.BT(mc, this.BC(743.0), cy - this.BY(20.0), "", 26.0, this.BInk(), 1);
    this.BT(mc, this.BC(743.0), cy + this.BY(26.0), "KM/H", 11.0, this.BDim(), 1);
    this.m_gbSpool = CMMtMeter.Make(mc, this.BC(700.0), cy + this.BY(46.0), this.BL(86.0), 15.0, this.BAcc(), CMHudPal.Of(0), true);
    this.BT(mc, this.BC(700.0), cy + this.BY(56.0), CMText.GrfBSpool(), 10.0, this.BDim(), 0);
    this.BPlateXY(mc, this.BC(1214.0), cy - this.BY(22.0), this.BC(1300.0), cy + this.BY(22.0), 8.0, this.BInk(), false);
    this.m_gbAlt = this.BT(mc, this.BC(1257.0), cy - this.BY(20.0), "", 26.0, this.BInk(), 1);
    this.m_gbVs = this.BT(mc, this.BC(1257.0), cy + this.BY(26.0), "", 11.0, this.BDim(), 1);

    this.m_gbLockBars = CMKit.Corners(root, this.Pal().hostile, 1.0, false);
    let lp = new inkCanvas();
    lp.SetSize(Vector2(392.0, 103.0));
    lp.Reparent(root);
    this.PlateC(lp, 0.0, 0.0, 392.0, 103.0, 21.0, this.Pal().hostile, false);
    this.m_gbLockT = this.BT(lp, 21.0, 5.0, "", 13.0, this.Pal().hostile, 0);
    this.m_gbLockD = this.BT(lp, 371.0, 5.0, "", 13.0, this.BInk(), 2);
    this.m_gbLockHp = CMMtMeter.Make(lp, 21.0, 57.0, 351.0, 18.0, this.Pal().hostile, CMHudPal.Of(0));
    this.m_gbLockPlate = lp;
    let lead = new inkCanvas();
    lead.SetSize(Vector2(40.0, 40.0));
    lead.Reparent(root);
    CMInk.Circle(lead, 20.0, 20.0, 18.0, this.Pal().warn, 1.0);
    this.m_gbLead = lead;
    let hb = 0;
    while hb < 12 {
      for b in CMKit.Corners(root, this.Pal().hostile, 0.85, false) {
        b.SetVisible(false);
        ArrayPush(this.m_gbHostBars, b);
      }
      hb += 1;
    }
    let tc4 = 0;
    while tc4 < 4 {
      let ch = CMInk.Chevron(root, 70.0, 7.0, this.Pal().hostile);
      ch.SetVisible(false);
      ArrayPush(this.m_gbThreat, ch);
      ArrayPush(this.m_gbThreatT, 0.0);
      ArrayPush(this.m_gbThreatA, 0.0);
      tc4 += 1;
    }
    this.GbLockShow(false);

    this.BPlateXY(bl, this.BL(24.0), this.BY(600.0), this.BL(380.0), this.BY(680.0), 14.0, this.BDim(), true);
    this.m_gbAtt = this.PlateHead(bl, this.BL(24.0), this.BY(600.0), this.BL(356.0), CMText.GrfBFlight(), "", this.BDim());
    let gr = CMInk.Ring(bl, this.BL(80.0), this.BY(668.0), this.GB_GAUGE_R, 48, 5.0, this.BInk(), 0.9);
    q = 0;
    while q < 48 {
      let a = Cast<Float>(q) * 7.5;
      gr[q].SetVisible(a >= 290.0 || a <= 70.0);
      q += 1;
    }
    this.m_gbNeedle = CMKit.Stroke(bl, this.BAcc(), 1.0);
    let tabs = [CMText.GrfHover(), CMText.GrfCruise()];
    let tx = [140.0, 248.0];
    let tw = [100.0, 112.0];
    i = 0;
    while i < 2 {
      this.BPlateXY(bl, this.BL(tx[i]), this.BY(640.0), this.BL(tx[i] + tw[i]), this.BY(666.0), 6.0, this.BDim(), false);
      ArrayPush(this.m_gbTab, CMKit.Nine(bl, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), this.BL(tx[i]), this.BY(640.0), this.BL(tw[i]), this.BY(26.0), this.BAcc(), 0.9));
      ArrayPush(this.m_gbTabT, this.BT(bl, this.BL(tx[i] + tw[i] * 0.5), this.BY(642.0), tabs[i], 16.0, this.BDim(), 1));
      i += 1;
    }

    this.BPlateXY(bl, this.BL(24.0), this.BY(690.0), this.BL(380.0), this.BY(800.0), 14.0, this.BDim(), true);
    this.PlateHead(bl, this.BL(24.0), this.BY(690.0), this.BL(356.0), CMText.GrfBWeapons(), CMText.GrfBSelect(CMKeyName.FireMode()), this.BDim());
    i = 0;
    while i < 2 {
      let ry = this.BY(722.0 + Cast<Float>(i) * 36.0);
      ArrayPush(this.m_gbBand, CMKit.Nine(bl, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), this.BL(32.0), ry, this.BL(340.0), this.BY(30.0), this.BAcc(), 0.9));
      ArrayPush(this.m_gbBand, CMKit.Img(bl, n"hazard", this.BL(342.0), ry + this.BY(4.0), this.BL(26.0), this.BY(22.0), this.BDark(), 0.85));
      ArrayPush(this.m_gbWpnT, this.BT(bl, this.BL(42.0), ry + this.BY(2.0), "", i == 0 ? 20.0 : 18.0, this.BInk(), 0));
      ArrayPush(this.m_gbWpnSt, this.BT(bl, this.BL(i == 0 ? 300.0 : 368.0), ry + this.BY(6.0), "", 14.0, this.Pal().friendly, 2));
      i += 1;
    }
    let p = 0;
    while p < 2 {
      ArrayPush(this.m_gbRk, CMKit.Nine(bl, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), this.BL(270.0 + Cast<Float>(p) * 18.0), this.BY(760.0), this.BL(12.0), this.BY(18.0), this.BInk(), 1.0));
      p += 1;
    }
    this.BT(bl, this.BL(32.0), this.BY(782.0), CMText.GrfKeys(CMKeyName.Fire(), CMKeyName.FireMode(), CMKeyName.Secondary(), CMKeyName.Aim(), CMKeyName.Sensor()), 10.0, this.BDim(), 0);
  }

  protected func BuildSprite(root: ref<inkCanvas>) -> Void {
    let br = this.Rg(2, 2);
    this.BPlateXY(br, this.BR(1720.0), this.BY(560.0), this.BR(1976.0), this.BY(800.0), 14.0, this.BDim(), false);
    this.m_gbPodTag = this.PlateHead(br, this.BR(1720.0), this.BY(560.0), this.BL(256.0), CMText.WyvAirframe(), "", this.Pal().warn);
    let k = this.BL(112.0) / 311.0;
    let box = new inkCanvas();
    box.SetMargin(inkMargin(this.BR(1790.0), this.BY(598.0), 0.0, 0.0));
    box.SetSize(Vector2(311.0 * k, 360.0 * k));
    box.Reparent(br);
    this.GbPart(box, k, n"griffin_body", 31.0, 46.0, 250.0, 309.0);
    this.GbPart(box, k, n"griffin_wing_l", 6.0, 5.0, 79.0, 246.0);
    this.GbPart(box, k, n"griffin_wing_r", 227.0, 5.0, 80.0, 246.0);
    ArrayPush(this.m_gbPodS, CMSlider.Make(br, this.BR(1756.0), this.BY(600.0), 36.0, this.BY(130.0), true, this.BAcc()));
    ArrayPush(this.m_gbPodS, CMSlider.Make(br, this.BR(1936.0), this.BY(600.0), 36.0, this.BY(130.0), true, this.BAcc()));
    this.BT(br, this.BR(1763.0), this.BY(734.0), "L", 11.0, this.BDim(), 1);
    this.BT(br, this.BR(1943.0), this.BY(734.0), "R", 11.0, this.BDim(), 1);
    this.BT(br, this.BR(1736.0), this.BY(760.0), CMText.OctBHull(), 13.0, this.BDim(), 0);
    this.m_gbHull = CMMtMeter.Make(br, this.BR(1780.0), this.BY(764.0), this.BL(180.0), 31.0, this.BInk(), CMHudPal.Of(0));
  }

  private func GbPart(box: ref<inkCanvas>, k: Float, name: CName, x: Float, y: Float, w: Float, h: Float) -> Void {
    let img = new inkImage();
    img.SetAtlasResource(CMDroneHud.Atlas());
    img.SetTexturePart(name);
    img.SetMargin(inkMargin(x * k, y * k, 0.0, 0.0));
    img.SetSize(Vector2(w * k, h * k));
    img.SetTintColor(this.BInk());
    img.SetInteractive(false);
    img.Reparent(box);
    ArrayPush(this.m_gbSprite, img);
  }

  private func GbCol(hp: Float) -> HDRColor = hp <= 0.0 ? this.Pal().hostile : (hp < 0.6 ? this.Pal().warn : this.BAcc())

  private func GbLockShow(on: Bool) -> Void {
    for b in this.m_gbLockBars {
      b.SetVisible(on);
    }
    this.m_gbLockPlate.SetVisible(on);
    if !on {
      this.m_gbLead.SetVisible(false);
    }
  }

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    let km = 0;
    while km < ArraySize(this.m_gbMarks) {
      this.m_gbMarks[km].SetTintColor(km < this.m_gbKills ? this.BAcc() : new HDRColor(0.24, 0.26, 0.23, 1.0));
      km += 1;
    }
    CMInk.Text(this.m_gbKillsT, (this.m_gbKills < 10 ? "0" : "") + IntToString(this.m_gbKills));
    CMInk.Text(this.m_gbStreak, this.m_gbStreakN > 1 ? CMText.GrfBStreak(IntToString(this.m_gbStreakN)) : "");
    let sig = ClampF(s.signal, 0.0, 1.0);
    let b = 0;
    while b < ArraySize(this.m_gbBars) {
      this.m_gbBars[b].SetOpacity(sig * 5.0 > Cast<Float>(b) + 0.5 ? 1.0 : 0.2);
      this.m_gbBars[b].SetTintColor(sig < 0.35 ? this.Pal().hostile : this.BAcc());
      b += 1;
    }
    CMInk.Text(this.m_gbLink, CMText.GrfBLink(IntToString(RoundF(sig * 100.0))));
    CMInk.Text(this.m_gbRng, CMText.GrfBRng(s.range > 0.0 && s.range < 2000.0 ? IntToString(RoundF(s.range)) : "---"));
    this.m_gbSpool.Set(ClampF(s.spool, 0.0, 1.0), this.BAcc());
    let warn = s.warning;
    if sig < 0.35 {
      warn = CMText.BmbLinkWeak();
    } else {
      if s.integrity < 0.3 {
        warn = CMText.BmbHullCritical();
      }
    }
    CMInk.Text(this.m_gbWarn, warn);
    let hull = ClampF(s.integrity, 0.0, 1.0);
    this.m_gbHull.Set(hull, hull < 0.3 ? this.Pal().hostile : (hull < 0.6 ? this.Pal().warn : this.BInk()));

    let pl = ArraySize(s.droneParts) >= 3 ? s.droneParts[1] : 1.0;
    let pr = ArraySize(s.droneParts) >= 3 ? s.droneParts[2] : 1.0;
    if ArraySize(this.m_gbPodS) >= 2 {
      this.m_gbPodS[0].Set(pl > 0.0 ? 0.35 + 0.65 * pl : 0.0, this.GbCol(pl));
      this.m_gbPodS[1].Set(pr > 0.0 ? 0.35 + 0.65 * pr : 0.0, this.GbCol(pr));
    }
    let worst = MinF(pl, pr);
    CMInk.Text(this.m_gbPodTag, worst < 1.0 ? CMText.GrfPod(pl <= pr ? "L" : "R", worst <= 0.0 ? CMText.GrfLost() : IntToString(RoundF(worst * 100.0)) + "%") : "");
    this.m_gbPodTag.SetTintColor(worst <= 0.0 ? this.Pal().hostile : this.Pal().warn);
    let k = 0;
    for img in this.m_gbSprite {
      img.SetTintColor(k == 1 ? this.GbCol(pl) : (k == 2 ? this.GbCol(pr) : (hull < 0.3 ? this.Pal().hostile : this.BInk())));
      k += 1;
    }

    let heat = ClampF(s.secHeat, 0.0, 1.0);
    let n = 0;
    while n < ArraySize(this.m_gbHeatArc) {
      this.m_gbHeatArc[n].SetVisible(heat * Cast<Float>(this.GB_HEAT_N) > Cast<Float>(n % this.GB_HEAT_N) + 0.05);
      this.m_gbHeatArc[n].SetTintColor(heat >= 0.99 ? this.Pal().hostile : this.Pal().warn);
      n += 1;
    }
    let hp = IntToString(RoundF(heat * 100.0)) + "%";
    CMInk.Text(this.m_gbHeatL, "L " + hp);
    CMInk.Text(this.m_gbHeatR, "R " + hp);

    let gs = ArraySize(s.wStat) > 0 ? s.wStat[0] : "RDY";
    let rs = ArraySize(s.wStat) > 1 ? s.wStat[1] : "";
    CMInk.Text(this.m_gbWpnT[0], ArraySize(s.wSub) > 0 ? s.wSub[0] : "LMG 7.62 x2");
    CMInk.Text(this.m_gbWpnT[1], CMText.GrfBRktLaser());
    CMInk.Text(this.m_gbWpnSt[0], CMDroneHud.StatText(gs));
    CMInk.Text(this.m_gbWpnSt[1], CMDroneHud.StatText(rs));
    let w = 0;
    while w < 2 {
      let on = s.weapon == w;
      let st = w == 0 ? gs : rs;
      this.m_gbBand[w * 2].SetVisible(on);
      this.m_gbBand[w * 2 + 1].SetVisible(on);
      this.m_gbWpnT[w].SetTintColor(on ? this.BDark() : this.BInk());
      this.m_gbWpnSt[w].SetTintColor(on ? this.BDark() : (CMDroneHud.StatWarn(st) ? this.Pal().warn : this.Pal().friendly));
      w += 1;
    }
    let r = 0;
    while r < 2 {
      this.m_gbRk[r].SetOpacity(r < s.rkLeft ? 1.0 : 0.22);
      this.m_gbRockets[r].SetOpacity(r < s.rkLeft ? 1.0 : 0.22);
      r += 1;
    }
  }

  public func SetFlight(pitch: Float, roll: Float, speed: Float, alt: Float, vs: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    CMInk.Text(this.m_gbSpd, IntToString(RoundF(speed * 3.6)));
    CMInk.Text(this.m_gbAlt, alt >= 0.0 ? FloatToStringPrec(alt, 1) : "---");
    CMInk.Text(this.m_gbVs, CMText.WyvBVs((vs >= 0.0 ? "+" : "") + FloatToStringPrec(vs, 1)));
    CMInk.Text(this.m_gbAtt, CMText.GrfBAtt(CMDroneHud.Signed(pitch), CMDroneHud.Signed(roll)));

    let nose = ClampF(-pitch, 0.0, 90.0);
    let a = Deg2Rad(270.0 + nose);
    let gx = this.BL(80.0);
    let gy = this.BY(668.0);
    CMInk.Seg(this.m_gbNeedle, gx, gy, gx + SinF(a) * this.GB_GAUGE_R, gy - CosF(a) * this.GB_GAUGE_R, 8.0);
    let hover = speed < 3.0;
    this.m_gbTab[0].SetVisible(hover);
    this.m_gbTab[1].SetVisible(!hover);
    this.m_gbTabT[0].SetTintColor(hover ? this.BDark() : this.BDim());
    this.m_gbTabT[1].SetTintColor(hover ? this.BDim() : this.BDark());
  }

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    let cx = this.FW() * 0.5;
    let cy = 1080.0;
    let hot = t.hostiles > 0;
    let hc = hot ? this.Pal().hostile : this.Pal().warn;
    CMInk.Text(this.m_gbHold, hot ? CMText.GrfWeaponsFree() : CMText.GrfWeaponsHold());
    this.m_gbHold.SetTintColor(hc);
    for ch in this.m_gbHoldChev {
      ch.SetTintColor(hc);
    }

    let h = -t.yaw;
    while h < 0.0 {
      h += 360.0;
    }
    while h >= 360.0 {
      h -= 360.0;
    }
    let base = FloorF(h / 5.0) * 5;
    let i = 0;
    while i < ArraySize(this.m_gbTicks) {
      let deg = base + (i - 7) * 5;
      let x = cx + (Cast<Float>(deg) - h) * this.GB_PX;
      let big = ((deg % 15) + 15) % 15 == 0;
      let tk = this.m_gbTicks[i];
      tk.SetVisible(AbsF(x - cx) <= this.GB_HALF);
      tk.SetMargin(inkMargin(x - 2.0, this.BY(86.0) - (big ? 31.0 : 15.0), 0.0, 0.0));
      tk.SetSize(Vector2(big ? 5.0 : 3.0, big ? 31.0 : 15.0));
      i += 1;
    }
    let lbase = FloorF(h / 15.0) * 15;
    i = 0;
    while i < ArraySize(this.m_gbTickL) {
      let deg = lbase + (i - 2) * 15;
      let x = cx + (Cast<Float>(deg) - h) * this.GB_PX;
      let l = this.m_gbTickL[i];
      l.SetVisible(AbsF(x - cx) <= this.GB_HALF - 20.0);
      l.SetMargin(inkMargin(x, this.BY(54.0), 0.0, 0.0));
      let d = (deg % 360 + 360) % 360;
      CMInk.Text(l, d == 0 ? "N" : (d == 90 ? "E" : (d == 180 ? "S" : (d == 270 ? "W" : IntToString(d)))));
      i += 1;
    }
    let hi = RoundF(h) % 360;
    CMInk.Text(this.m_gbHdg, CMPilotHud.Pad3(hi) + "  " + CMPilotHud.Cardinal(hi));

    let scale = 1080.0 / TanF(Deg2Rad(MaxF(1.0, t.fov) * 0.5));
    let n = 0;
    for c in t.contacts {
      let isLock = IsDefined(t.lock) && Equals(c.id, t.lock.id);
      if n < 12 && c.kind == 2 && !isLock && c.OnScreen() {
        let hh = ClampF(1.9 / MaxF(1.0, c.dist) * scale, 50.0, 420.0);
        let hw = MaxF(44.0, hh * 0.5);
        CMKit.PlaceCorners(this.m_gbHostBars, n * 4, cx + c.scr.X - hw * 0.5, cy + c.scr.Y - hh * 0.5, hw, hh, MinF(26.0, hw * 0.35));
        CMKit.ShowCorners(this.m_gbHostBars, n * 4, true, this.Pal().hostile);
        n += 1;
      }
    }
    while n < 12 {
      CMKit.ShowCorners(this.m_gbHostBars, n * 4, false, this.Pal().hostile);
      n += 1;
    }

    let c = t.lock;
    if !IsDefined(c) || !c.OnScreen() {
      this.GbLockShow(false);
      return;
    }
    this.GbLockShow(true);
    let col = c.kind == 2 ? this.Pal().hostile : CMInk.KindColor(c.kind, this.BAcc());
    let hh = ClampF(1.9 / MaxF(1.0, c.dist) * scale, 100.0, 520.0);
    let hw = MaxF(100.0, hh * 0.5);
    let x = cx + c.scr.X - hw * 0.5;
    let y = cy + c.scr.Y - hh * 0.5;
    CMKit.PlaceCorners(this.m_gbLockBars, 0, x, y, hw, hh, MinF(41.0, hw * 0.4));
    CMKit.ShowCorners(this.m_gbLockBars, 0, true, col);
    this.m_gbLockPlate.SetMargin(inkMargin(x + hw + 26.0, y + hh * 0.5 - 82.0, 0.0, 0.0));
    CMInk.Text(this.m_gbLockT, c.kind == 2 ? CMText.GrfLock(c.Label()) : CMText.GrfTrack(c.Label()));
    CMInk.Text(this.m_gbLockD, IntToString(RoundF(c.dist)) + " M");
    this.m_gbLockHp.Set(ClampF(c.hp, 0.0, 1.0), col);
    if t.leadOn {
      this.m_gbLead.SetVisible(true);
      this.m_gbLead.SetMargin(inkMargin(cx + t.lead.X - 20.0, cy + t.lead.Y - 20.0, 0.0, 0.0));
    } else {
      this.m_gbLead.SetVisible(false);
    }
  }

  public func HitFrom(off: Float) -> Void {
    let best = 0;
    let i = 1;
    while i < ArraySize(this.m_gbThreatT) {
      if this.m_gbThreatT[i] < this.m_gbThreatT[best] {
        best = i;
      }
      i += 1;
    }
    if ArraySize(this.m_gbThreatT) > 0 {
      this.m_gbThreatT[best] = 2.0;
      this.m_gbThreatA[best] = -off;
    }
  }

  public func StartBoot() -> Void {
    this.m_gbBoot = 0.8;
    this.m_gbT = 0.0;
    if IsDefined(this.FRoot()) {
      this.FRoot().SetOpacity(0.0);
    }
  }

  public func Boot(dt: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_gbT += dt;
    if this.m_gbBoot > 0.0 {
      this.m_gbBoot = MaxF(0.0, this.m_gbBoot - dt);
      this.FRoot().SetOpacity(1.0 - this.m_gbBoot / 0.8);
    }
    CMInk.Text(this.m_gbClock, "T+ " + CMInk.Clock(this.m_gbT));
    if this.m_gbStreakN > 0 && this.m_gbT - this.m_gbLastKill > 10.0 {
      this.m_gbStreakN = 0;
    }

    let cx = this.FW() * 0.5;
    let i = 0;
    while i < ArraySize(this.m_gbThreat) {
      let ch = this.m_gbThreat[i];
      if this.m_gbThreatT[i] > 0.0 {
        this.m_gbThreatT[i] -= dt;
        let a = Deg2Rad(this.m_gbThreatA[i]);
        ch.SetVisible(true);
        ch.SetMargin(inkMargin(cx + SinF(a) * 780.0 - 35.0, 1080.0 - CosF(a) * 780.0 - 35.0, 0.0, 0.0));
        ch.SetRotation(this.m_gbThreatA[i]);
        ch.SetOpacity(ClampF(this.m_gbThreatT[i], 0.0, 1.0));
      } else {
        ch.SetVisible(false);
      }
      i += 1;
    }
  }

  public func Hit(kill: Bool) -> Void {
    if kill {
      this.m_gbKills += 1;
      this.m_gbStreakN = this.m_gbT - this.m_gbLastKill <= 10.0 ? this.m_gbStreakN + 1 : 1;
      this.m_gbLastKill = this.m_gbT;
    }
  }
}
