module ControllableMechs

import ControllableMechs.Control.*

public class CMOctantBHud extends CMBombusHud {
  private let m_obName: ref<inkText>;
  private let m_obLink: ref<inkText>;
  private let m_obMts: ref<inkText>;
  private let m_obLaser: ref<inkText>;
  private let m_obTrack: ref<inkText>;
  private let m_obRec: ref<inkImage>;
  private let m_obTicks: array<ref<inkImage>>;
  private let m_obTickL: array<ref<inkText>>;
  private let m_obThreatTick: ref<inkImage>;
  private let m_obHdg: ref<inkText>;
  private let m_obHold: ref<inkText>;
  private let m_obWarn: ref<inkText>;
  private let m_obTgtTag: ref<inkText>;
  private let m_obTgtV: array<ref<inkText>>;
  private let m_obWind: ref<inkText>;
  private let m_obCross: ref<inkCanvas>;
  private let m_obDepNeedle: ref<inkImage>;
  private let m_obDep: ref<inkText>;
  private let m_obSplash: array<ref<inkImage>>;
  private let m_obLeader: array<ref<inkImage>>;
  private let m_obSplashT: ref<inkText>;
  private let m_obSplashT2: ref<inkText>;
  private let m_obSpd: ref<inkText>;
  private let m_obAlt: ref<inkText>;
  private let m_obVs: ref<inkText>;
  private let m_obLrf: ref<inkText>;
  private let m_obLcue: ref<inkCanvas>;
  private let m_obMap: ref<inkCanvas>;
  private let m_obDots: array<ref<inkImage>>;
  private let m_obFoot: array<ref<inkRectangle>>;
  private let m_obFan: array<ref<inkImage>>;
  private let m_obFootEdge: array<ref<inkImage>>;
  private let m_obSelf: ref<inkCanvas>;
  private let m_obV: ref<inkImage>;
  private let m_obTgtMark: ref<inkCanvas>;
  private let m_obBand: array<ref<inkWidget>>;
  private let m_obRowSta: array<ref<inkText>>;
  private let m_obRowName: array<ref<inkText>>;
  private let m_obRowStat: array<ref<inkText>>;
  private let m_obSub: ref<inkText>;
  private let m_obHeatL: ref<inkText>;
  private let m_obHeat: ref<CMSlider>;
  private let m_obRk: array<ref<inkImage>>;
  private let m_obArmour: ref<inkText>;
  private let m_obSchem: array<ref<inkImage>>;
  private let m_obThr: array<ref<inkImage>>;
  private let m_obThrT: ref<inkText>;
  private let m_obHull: ref<CMMtMeter>;
  private let m_obBda: array<ref<inkText>>;
  private let m_obClock: Float;
  private let m_obBoot: Float;
  private let m_obFlash: Float;
  private let m_obKills: Int32;
  private let m_obSlowAt: Float;
  private let m_obHeading: Float;
  private let m_obThreatT: Float;
  private let m_obThreatB: Float;
  private let m_obSensor: String;

  private let OB_PX: Float = 15.5;
  private let OB_HALF: Float = 713.0;
  private let OB_MAP_R: Float = 248.0;
  private let OB_DEP_R: Float = 103.0;

  private func ODark() -> HDRColor = new HDRColor(0.03, 0.03, 0.01, 1.0)

  protected func PlatesB() -> Void {}

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
    let cy = 1080.0;
    let tl = this.Rg(0, 0);
    let tc = this.Rg(1, 0);
    let tr = this.Rg(2, 0);
    let ml = this.Rg(0, 1);
    let mc = this.Rg(1, 1);
    let bl = this.Rg(0, 2);
    let bc = this.Rg(1, 2);
    let br = this.Rg(2, 2);
    this.BFrame(this.Face(), W);

    this.PlateC(tl, this.BL(26.0), this.BY(20.0), this.BL(346.0), this.BY(72.0), 36.0, this.BDim(), false);
    this.BHazard(tl, this.BL(30.0), this.BY(26.0), this.BL(14.0), this.BY(60.0));
    this.m_obName = this.BT(tl, this.BL(54.0), this.BY(22.0), "ZTC-08  OCTANT", 30.0, this.BInk(), 0);
    this.BT(tl, this.BL(56.0), this.BY(60.0), CMText.OctBRole() + "   SN ZT-4471", 13.0, this.BDim(), 0);
    this.BT(tl, this.BL(362.0), this.BY(26.0), CMText.OctBLink(), 11.0, this.BDim(), 2);
    this.m_obLink = this.BT(tl, this.BL(362.0), this.BY(42.0), "", 20.0, this.BInk(), 2);
    this.PlateC(tl, this.BL(26.0), this.BY(98.0), this.BL(346.0), this.BY(26.0), 21.0, this.BDim(), false);
    this.BT(tl, this.BL(36.0), this.BY(102.0), CMText.OctBMts(), 11.0, this.BDim(), 0);
    this.m_obMts = this.BT(tl, this.BL(70.0), this.BY(101.0), "", 13.0, this.BInk(), 0);
    this.BT(tl, this.BL(152.0), this.BY(102.0), CMText.OctBLaser(), 11.0, this.BDim(), 0);
    this.m_obLaser = this.BT(tl, this.BL(196.0), this.BY(101.0), "", 13.0, this.BAcc(), 0);
    this.BT(tl, this.BL(268.0), this.BY(102.0), CMText.OctBTrack(), 11.0, this.BDim(), 0);
    this.m_obTrack = this.BT(tl, this.BL(312.0), this.BY(101.0), "", 13.0, this.BDim(), 0);
    this.m_obRec = CMKit.Disc(tl, this.BL(355.0), this.BY(111.0), 10.0, this.Pal().hostile, 1.0);

    this.PlateC(tc, this.BC(700.0), this.BY(16.0), 600.0 * 2.58, this.BY(40.0), 26.0, this.BDim(), false);
    let i = 0;
    while i < 21 {
      ArrayPush(this.m_obTicks, CMKit.Img(tc, n"pill_v", cx, this.BY(38.0), 4.0, 31.0, this.BInk(), 0.85));
      i += 1;
    }
    i = 0;
    while i < 8 {
      let l = this.BT(tc, cx, this.BY(18.0), "", 13.0, this.BInk(), 1);
      ArrayPush(this.m_obTickL, l);
      i += 1;
    }
    this.m_obThreatTick = CMKit.Img(tc, n"tri", cx, this.BY(34.0), 31.0, 26.0, this.Pal().hostile, 1.0);
    this.m_obThreatTick.SetRenderTransformPivot(Vector2(0.5, 0.5));
    this.m_obThreatTick.SetRotation(180.0);
    this.m_obThreatTick.SetVisible(false);
    this.PlateC(tc, this.BC(946.0), this.BY(62.0), 108.0 * 2.58, this.BY(34.0), 26.0, this.BAcc(), false);
    this.m_obHdg = this.BT(tc, cx, this.BY(64.0), "", 22.0, this.BInk(), 1);
    this.m_obHold = this.BT(tc, cx, this.BY(104.0), "", 14.0, this.Pal().warn, 1);
    this.m_obWarn = this.BT(mc, cx, this.BY(160.0), "", 18.0, this.Pal().hostile, 1);

    let tx = this.BR(1640.0);
    this.PlateC(tr, tx, this.BY(20.0), 332.0 * 2.58, this.BY(130.0), 36.0, this.BDim(), true);
    this.m_obTgtTag = this.PlateHead(tr, tx, this.BY(20.0), 332.0 * 2.58, CMText.OctBTarget(), "", this.BAcc());
    let rows = [CMText.OctBSlant(), CMText.OctBBrg(), CMText.OctBDh(), CMText.OctBTgtSpd()];
    i = 0;
    while i < 4 {
      this.BT(tr, this.BR(1654.0), this.BY(52.0 + Cast<Float>(i) * 23.0), rows[i], 13.0, this.BDim(), 0);
      ArrayPush(this.m_obTgtV, this.BT(tr, this.BR(1958.0), this.BY(50.0 + Cast<Float>(i) * 23.0), "", 17.0, this.BInk(), 2));
      i += 1;
    }
    this.m_obWind = this.BT(tr, this.BR(1972.0), this.BY(156.0), "", 11.0, this.BDim(), 2);

    let c = new inkCanvas();
    c.SetMargin(inkMargin(cx - 300.0, cy - 300.0, 0.0, 0.0));
    c.SetSize(Vector2(600.0, 600.0));
    c.Reparent(mc);
    this.m_obCross = c;
    let r1 = CMInk.Ring(c, 300.0, 300.0, 150.0, 72, 5.0, this.BInk(), 1.0);
    let r2 = CMInk.Ring(c, 300.0, 300.0, 191.0, 72, 8.0, this.BAcc(), 1.0);
    let q = 0;
    while q < 72 {
      let a = Cast<Float>(q) * 5.0;

      r1[q].SetVisible((a >= 290.0 || a <= 70.0) || (a >= 110.0 && a <= 250.0));
      r2[q].SetVisible(a >= 330.0 || a <= 30.0);
      q += 1;
    }
    CMKit.Ln(c, 300.0 + 180.0, 297.5, 88.0, 5.0, this.BInk(), 1.0);
    CMKit.Ln(c, 300.0 - 268.0, 297.5, 88.0, 5.0, this.BInk(), 1.0);
    CMKit.Ln(c, 297.5, 300.0 + 180.0, 5.0, 88.0, this.BInk(), 1.0);
    CMKit.Disc(c, 300.0, 300.0, 8.0, this.BInk(), 1.0);

    let ax = this.BC(1162.0);
    let ay = this.BY(350.0);
    let dr = CMInk.Ring(mc, ax, ay, this.OB_DEP_R, 72, 5.0, this.BDim(), 1.0);
    q = 0;
    while q < 72 {
      let a = Cast<Float>(q) * 5.0;
      dr[q].SetVisible(a >= 180.0 && a <= 270.0);
      q += 1;
    }
    this.m_obDepNeedle = CMKit.Stroke(mc, this.BAcc(), 1.0);
    this.m_obDep = this.BT(mc, this.BC(1118.0), this.BY(300.0), CMText.OctBDep("00"), 13.0, this.BInk(), 0);

    i = 0;
    while i < 32 {
      let s = CMKit.Stroke(root, this.BAcc(), 1.0);
      s.SetVisible(false);
      ArrayPush(this.m_obSplash, s);
      i += 1;
    }
    i = 0;
    while i < 2 {
      let s = CMKit.Stroke(root, this.BAcc(), 0.95);
      s.SetVisible(false);
      ArrayPush(this.m_obLeader, s);
      i += 1;
    }
    this.m_obSplashT = this.BT(root, 0.0, 0.0, "", 14.0, this.BAcc(), 0);
    this.m_obSplashT2 = this.BT(root, 0.0, 0.0, "", 13.0, this.BInk(), 0);
    this.m_obSplashT.SetVisible(false);
    this.m_obSplashT2.SetVisible(false);

    let side = -1;
    while side <= 1 {
      let lx = this.BC(1000.0 + Cast<Float>(side) * 380.0);
      CMKit.Ln(mc, lx - 1.0, this.BY(270.0), 3.0, this.BY(300.0), this.BDim(), 0.9);
      let j = -6;
      while j <= 6 {
        let len = j % 2 == 0 ? 31.0 : 15.0;
        CMKit.Ln(mc, side < 0 ? lx : lx - len, this.BY(420.0 + Cast<Float>(j) * 25.0) - 1.0, len, 3.0, this.BDim(), 0.9);
        j += 1;
      }
      let px = side < 0 ? this.BC(522.0) : this.BC(1392.0);
      this.PlateC(mc, px, this.BY(402.0), 86.0 * 2.58, this.BY(36.0), 21.0, this.BInk(), false);
      let v = this.BT(mc, px + 111.0, this.BY(405.0), "", 24.0, this.BInk(), 1);
      if side < 0 {
        this.m_obSpd = v;
        this.BT(mc, lx, this.BY(244.0), "M/S", 12.0, this.BDim(), 1);
      } else {
        this.m_obAlt = v;
        this.BT(mc, lx, this.BY(244.0), CMText.OctBAltM(), 12.0, this.BDim(), 1);
      }
      side += 2;
    }
    this.m_obVs = this.BT(mc, this.BC(1435.0), this.BY(444.0), "", 12.0, this.BDim(), 1);

    this.PlateC(mc, this.BC(908.0), this.BY(520.0), 184.0 * 2.58, this.BY(28.0), 21.0, this.BDim(), false);
    this.BT(mc, this.BC(920.0), this.BY(523.0), CMText.OctBLrf(), 13.0, this.BDim(), 0);
    this.m_obLrf = this.BT(mc, this.BC(1002.0), this.BY(521.0), "", 19.0, this.BInk(), 1);
    let lc = new inkCanvas();
    lc.SetMargin(inkMargin(this.BC(1052.0), this.BY(526.0), 0.0, 0.0));
    lc.SetSize(Vector2(41.0, 41.0));
    lc.Reparent(mc);
    CMKit.Fill(lc, 0.0, 0.0, 41.0, 41.0, this.BAcc(), 1.0);
    let lt = CMPilotHud.Label(lc, inkEAnchor.TopLeft, 20.5, 1.0, "L", 33, n"Semi-Bold", this.ODark());
    lt.SetAnchorPoint(Vector2(0.5, 0.0));
    this.m_obLcue = lc;

    this.PlateC(ml, this.BL(24.0), this.BY(300.0), 256.0 * 2.58, this.BY(260.0), 36.0, this.BDim(), true);
    this.PlateHead(ml, this.BL(24.0), this.BY(300.0), 256.0 * 2.58, CMText.OctBSituation(), CMText.OctBNorthUp(), this.BDim());
    let mr = this.OB_MAP_R;
    let m = new inkCanvas();
    m.SetMargin(inkMargin(this.BL(152.0) - mr, this.BY(440.0) - mr, 0.0, 0.0));
    m.SetSize(Vector2(mr * 2.0, mr * 2.0));
    m.Reparent(ml);
    this.m_obMap = m;
    CMInk.Circle(m, mr, mr, mr, this.BDim(), 0.9);
    CMInk.Circle(m, mr, mr, mr * 0.5, this.BDim(), 0.7);
    this.m_obFoot = CMInk.FillBars(m, 0, this.BAcc(), 0.27);
    this.m_obFan = CMInk.FanSegs(m, 80, this.BAcc(), 0.15);
    i = 0;
    while i < 3 {
      let b = CMKit.Stroke(m, this.BAcc(), 0.6);
      b.SetVisible(false);
      ArrayPush(this.m_obFootEdge, b);
      i += 1;
    }
    i = 0;
    while i < 32 {
      let d = CMKit.Disc(m, 0.0, 0.0, 10.0, this.BDim(), 1.0);
      d.SetVisible(false);
      ArrayPush(this.m_obDots, d);
      i += 1;
    }
    this.m_obV = CMKit.Disc(m, 0.0, 0.0, 10.0, this.Pal().friendly, 1.0);
    let tg = new inkCanvas();
    tg.SetSize(Vector2(26.0, 26.0));
    tg.Reparent(m);
    CMKit.Img(tg, n"diamond", 0.0, 0.0, 26.0, 26.0, this.Pal().hostile, 1.0);
    this.m_obTgtMark = tg;
    this.m_obSelf = CMInk.Chevron(m, 36.0, 6.0, this.BInk());
    this.m_obSelf.SetMargin(inkMargin(mr - 18.0, mr - 18.0, 0.0, 0.0));

    this.PlateC(bl, this.BL(24.0), this.BY(596.0), 356.0 * 2.58, this.BY(194.0), 36.0, this.BDim(), true);
    this.PlateHead(bl, this.BL(24.0), this.BY(596.0), 356.0 * 2.58, CMText.OctBStores(), CMText.OctBMasterArm(), this.BAcc());
    let names = [CMText.OctBMortar(), "LMG X2", CMText.OctBRockets()];
    i = 0;
    while i < 3 {
      let ry = this.BY(632.0 + Cast<Float>(i) * 44.0);
      let band = CMKit.Nine(bl, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), this.BL(32.0), ry - 5.0, 340.0 * 2.58, this.BY(38.0), this.BAcc(), 0.88);
      ArrayPush(this.m_obBand, band);
      ArrayPush(this.m_obBand, CMKit.Img(bl, n"hazard", this.BL(340.0), ry + 5.0, this.BL(28.0), this.BY(30.0), this.ODark(), 0.85));
      ArrayPush(this.m_obRowSta, this.BT(bl, this.BL(42.0), ry + 21.0, CMText.OctBSta(IntToString(i + 1)), 12.0, this.BDim(), 0));
      ArrayPush(this.m_obRowName, this.BT(bl, this.BL(86.0), ry + 5.0, names[i], 22.0, this.BInk(), 0));
      ArrayPush(this.m_obRowStat, this.BT(bl, this.BL(330.0), ry + 21.0, "", 13.0, this.Pal().friendly, 2));
      i += 1;
    }
    let r0 = this.BY(632.0);
    this.m_obSub = this.BT(bl, this.BL(196.0), r0 + 21.0, CMText.OctBUnltd(), 12.0, this.ODark(), 0);
    let r1y = this.BY(676.0);
    this.m_obHeatL = this.BT(bl, this.BL(196.0), r1y + 10.0, CMText.OctBHeat(), 10.0, this.BDim(), 0);

    this.m_obHeat = CMSlider.Make(bl, this.BL(196.0), r1y + 46.0, this.BL(90.0), 14.0, false, this.BAcc());
    let r2y = this.BY(720.0);
    let p = 0;
    while p < 4 {
      ArrayPush(this.m_obRk, CMKit.Nine(bl, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), this.BL(196.0 + Cast<Float>(p) * 18.0), r2y + 21.0, 31.0, 57.0, this.BInk(), 1.0));
      p += 1;
    }
    this.BT(bl, this.BL(32.0), this.BY(768.0), CMText.OctBKeys(CMKeyName.FireMode(), CMKeyName.Fire(), CMKeyName.Secondary(), CMKeys.GunshipName(GetPlayer(GetGameInstance())), CMKeyName.Aim(), CMKeyName.Sensor()), 10.0, this.BDim(), 0);

    this.PlateC(bc, this.BC(760.0), this.BY(790.0), 480.0 * 2.58, this.BY(30.0), 21.0, this.BDim(), false);
    let labels = [CMText.OctBKia(), CMText.OctBRds(), CMText.OctBHits(), CMText.OctBAcc(), CMText.OctBHostiles()];
    i = 0;
    while i < 5 {
      let bx = this.BC(774.0 + Cast<Float>(i) * 94.0);
      this.BT(bc, bx, this.BY(795.0), labels[i], 11.0, this.BDim(), 0);
      ArrayPush(this.m_obBda, this.BT(bc, bx + (i < 4 ? 139.0 : 155.0), this.BY(793.0), "0", 16.0, this.BInk(), i < 4 ? 2 : 0));
      i += 1;
    }
  }

  protected func BuildSprite(root: ref<inkCanvas>) -> Void {
    let br = this.Rg(2, 2);
    let px = this.BR(1700.0);
    this.PlateC(br, px, this.BY(560.0), 276.0 * 2.58, this.BY(240.0), 36.0, this.BDim(), false);
    this.m_obArmour = this.PlateHead(br, px, this.BY(560.0), 276.0 * 2.58, CMText.OctBAirframe(), "", this.BInk());
    let k = this.BL(150.0) / 537.0;
    let box = new inkCanvas();
    box.SetMargin(inkMargin(this.BR(1716.0), this.BY(596.0), 0.0, 0.0));
    box.SetSize(Vector2(537.0 * k, 560.0 * k));
    box.Reparent(br);
    this.ObPart(box, k, n"octant_body", 100.0, 16.0, 335.0, 539.0);
    this.ObPart(box, k, n"octant_thruster_fl", 5.0, 137.0, 132.0, 138.0);
    this.ObPart(box, k, n"octant_thruster_fr", 401.0, 137.0, 132.0, 138.0);
    this.ObPart(box, k, n"octant_thruster_bl", 11.0, 310.0, 126.0, 136.0);
    this.ObPart(box, k, n"octant_thruster_br", 400.0, 310.0, 127.0, 136.0);
    this.ObPart(box, k, n"octant_gun", 242.0, 5.0, 53.0, 56.0);
    this.ObPart(box, k, n"octant_rocket_l", 43.0, 225.0, 81.0, 109.0);
    this.ObPart(box, k, n"octant_rocket_r", 413.0, 225.0, 81.0, 109.0);
    this.ObPart(box, k, n"octant_mortar", 206.0, 348.0, 162.0, 202.0);
    this.ObPart(box, k, n"octant_sensor", 191.0, 15.0, 156.0, 102.0);
    let i = 0;
    while i < 4 {
      let cx = this.BR(1904.0 + Cast<Float>(i % 2) * 40.0);
      let cy = this.BY(620.0 + Cast<Float>(i / 2) * 40.0);
      ArrayPush(this.m_obThr, CMKit.Nine(br, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), cx - 31.0, cy - 31.0, 62.0, 62.0, this.BInk(), 0.92));
      i += 1;
    }
    this.BT(br, this.BR(1924.0), this.BY(680.0), CMText.OctBThr(), 11.0, this.BDim(), 1);
    this.m_obThrT = this.BT(br, this.BR(1880.0), this.BY(700.0), "", 12.0, this.BAcc(), 0);
    this.BT(br, this.BR(1716.0), this.BY(760.0), CMText.OctBHull(), 13.0, this.BDim(), 0);
    this.m_obHull = CMMtMeter.Make(br, this.BR(1760.0), this.BY(764.0), 196.0 * 2.58, 31.0, this.BInk(), CMHudPal.Of(0));
  }

  private func ObPart(box: ref<inkCanvas>, k: Float, name: CName, x: Float, y: Float, w: Float, h: Float) -> Void {
    let img = new inkImage();
    img.SetAtlasResource(CMDroneHud.Atlas());
    img.SetTexturePart(name);
    img.SetMargin(inkMargin(x * k, y * k, 0.0, 0.0));
    img.SetSize(Vector2(w * k, h * k));
    img.SetTintColor(this.BInk());
    img.SetInteractive(false);
    img.Reparent(box);
    ArrayPush(this.m_obSchem, img);
  }

  private func ObHealth(hp: Float) -> HDRColor = hp <= 0.0 ? this.Pal().broken : (hp < 0.3 ? this.Pal().hostile : (hp < 0.6 ? this.BAcc() : this.BInk()))

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    let sig = ClampF(s.signal, 0.0, 1.0);
    CMInk.Text(this.m_obLink, IntToString(RoundF(sig * 100.0)) + "%");
    this.m_obLink.SetTintColor(sig < 0.35 ? this.Pal().hostile : this.BInk());
    this.m_obSensor = Equals(s.sensor, "DAY") ? "DAY-TV" : "IR " + CMThermal.Label(s.sensor);
    CMInk.Text(this.m_obLrf, s.range > 0.0 && s.range < 2000.0 ? CMPilotHud.Pad4(RoundF(s.range)) + " M" : "---- M");

    let i = 0;
    while i < ArraySize(this.m_obRowName) {
      let on = s.weapon == i;
      let st = i < ArraySize(s.wStat) ? s.wStat[i] : "";
      this.m_obBand[i * 2].SetVisible(on);
      this.m_obBand[i * 2 + 1].SetVisible(on);
      this.m_obRowSta[i].SetTintColor(on ? this.ODark() : this.BDim());
      this.m_obRowName[i].SetTintColor(on ? this.ODark() : this.BInk());
      CMInk.Text(this.m_obRowStat[i], CMDroneHud.StatText(st));
      this.m_obRowStat[i].SetTintColor(on ? this.ODark() : (CMDroneHud.StatWarn(st) ? this.Pal().warn : this.Pal().friendly));
      i += 1;
    }
    this.m_obSub.SetVisible(s.weapon == 0);
    let heat = ClampF(s.secHeat, 0.0, 1.0);
    this.m_obHeat.Set(heat, heat >= 0.99 ? this.Pal().hostile : this.BAcc());
    let p = 0;
    while p < ArraySize(this.m_obRk) {
      this.m_obRk[p].SetVisible(p < s.rkMax);
      this.m_obRk[p].SetOpacity(p < s.rkLeft ? 1.0 : 0.25);
      p += 1;
    }
    CMInk.Text(this.m_obHold, s.holdText);
    CMInk.Text(this.m_obWind, s.windText);
    CMInk.Text(this.m_obWarn, s.warning);

    let hull = ClampF(s.integrity, 0.0, 1.0);
    this.m_obHull.Set(hull, this.ObHealth(hull));
    CMInk.Text(this.m_obArmour, CMText.OctBArmour(IntToString(RoundF(hull * 100.0))));
    i = 0;
    while i < ArraySize(this.m_obSchem) {
      let hp = i == 0 ? hull : (i < ArraySize(s.droneParts) ? s.droneParts[i] : 1.0);
      this.m_obSchem[i].SetTintColor(this.ObHealth(hp));
      this.m_obSchem[i].SetOpacity(hp <= 0.0 ? 0.45 : 1.0);
      i += 1;
    }
    let worst = "";
    let worstHp = 1.0;
    let names = ["FL", "FR", "BL", "BR"];
    if ArraySize(s.droneParts) >= 5 {
      let k = 0;
      while k < 4 {
        let hp = s.droneParts[k + 1];
        this.m_obThr[k].SetTintColor(this.ObHealth(hp));
        this.m_obThr[k].SetOpacity(hp <= 0.0 ? 0.4 : 0.92);
        if hp < worstHp {
          worstHp = hp;
          worst = names[k];
        }
        k += 1;
      }
    }
    CMInk.Text(this.m_obThrT, worstHp < 1.0 ? (worstHp <= 0.0 ? CMText.OctBThrLost(worst) : CMText.OctBThrPct(worst, IntToString(RoundF(worstHp * 100.0)))) : "");
    this.m_obThrT.SetTintColor(worstHp <= 0.0 ? this.Pal().hostile : this.BAcc());
  }

  public func SetFlight(pitch: Float, roll: Float, speed: Float, alt: Float, vs: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    CMInk.Text(this.m_obSpd, FloatToStringPrec(speed, 1));
    CMInk.Text(this.m_obAlt, alt >= 0.0 ? CMPilotHud.Pad3(RoundF(alt)) : "---");
    CMInk.Text(this.m_obVs, CMText.OctBVs((vs >= 0.0 ? "+" : "") + FloatToStringPrec(vs, 1)));
  }

  public func SetAttitude(heading: Float, pitch: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    let h = CMPilotRig.Wrap(heading);
    if h < 0.0 {
      h += 360.0;
    }
    this.m_obHeading = h;
    let cx = this.FW() * 0.5;
    let base = FloorF(h / 5.0) * 5;
    let i = 0;
    while i < ArraySize(this.m_obTicks) {
      let deg = base + (i - 10) * 5;
      let x = cx + (Cast<Float>(deg) - h) * this.OB_PX;
      let big = ((deg % 15) + 15) % 15 == 0;
      let t = this.m_obTicks[i];
      t.SetVisible(AbsF(x - cx) <= this.OB_HALF);
      t.SetMargin(inkMargin(x - 2.0, this.BY(50.0) - (big ? 31.0 : 15.0), 0.0, 0.0));
      t.SetSize(Vector2(big ? 5.0 : 3.0, big ? 31.0 : 15.0));
      i += 1;
    }
    let lbase = FloorF(h / 15.0) * 15;
    i = 0;
    while i < ArraySize(this.m_obTickL) {
      let deg = lbase + (i - 3) * 15;
      let x = cx + (Cast<Float>(deg) - h) * this.OB_PX;
      let l = this.m_obTickL[i];
      l.SetVisible(AbsF(x - cx) <= this.OB_HALF - 20.0);
      l.SetMargin(inkMargin(x, this.BY(18.0), 0.0, 0.0));
      let d = (deg % 360 + 360) % 360;
      CMInk.Text(l, d == 0 ? "N" : (d == 90 ? "E" : (d == 180 ? "S" : (d == 270 ? "W" : IntToString(d)))));
      i += 1;
    }
    let hi = RoundF(h) % 360;
    CMInk.Text(this.m_obHdg, CMPilotHud.Pad3(hi) + "  " + CMPilotHud.Cardinal(hi));
  }

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.FRoot()) || !IsDefined(this.m_obMap) {
      return;
    }
    let cx = this.FW() * 0.5;
    let cy = 1080.0;
    CMInk.Text(this.m_obLaser, t.aimOk ? CMText.OctBArmed() : CMText.OctBSafe());
    this.m_obLaser.SetTintColor(t.aimOk ? this.BAcc() : this.BDim());
    let locked = IsDefined(t.lock);
    CMInk.Text(this.m_obTrack, locked ? CMText.OctBOn() : CMText.OctBOff());
    this.m_obTrack.SetTintColor(locked ? this.BAcc() : this.BDim());
    this.m_obLcue.SetVisible(t.aimOk);
    CMInk.Text(this.m_obMts, this.m_obSensor + " " + IntToString(RoundF(t.fov)));

    let slow = t.now >= this.m_obSlowAt;
    if slow {
      this.m_obSlowAt = t.now + 0.066;
    }

    if !slow {
    } else if t.aimOk {
      let dx = t.aim.X - t.pos.X;
      let dy = t.aim.Y - t.pos.Y;
      let dh = RoundF(t.aim.Z - t.pos.Z);
      let spd = locked ? Vector4.Length(t.lock.vel) * 3.6 : 0.0;
      CMInk.Text(this.m_obTgtV[0], CMPilotHud.Pad4(RoundF(Vector4.Distance(t.pos, t.aim))) + " M");
      CMInk.Text(this.m_obTgtV[1], CMPilotHud.Pad3(CMInk.Hdg(Rad2Deg(AtanF(dx, dy)))));
      CMInk.Text(this.m_obTgtV[2], (dh >= 0 ? "+" : "") + IntToString(dh) + " M");
      CMInk.Text(this.m_obTgtV[3], (spd < 10.0 ? "0" : "") + IntToString(RoundF(spd)) + " KM/H");
      CMInk.Text(this.m_obTgtTag, spd > 3.0 ? CMText.OctBMoving() : CMText.OctBStatic());
    } else {
      CMInk.Text(this.m_obTgtV[0], "---- M");
      CMInk.Text(this.m_obTgtV[1], "---");
      CMInk.Text(this.m_obTgtV[2], "--- M");
      CMInk.Text(this.m_obTgtV[3], "-- KM/H");
      CMInk.Text(this.m_obTgtTag, CMText.OctBNoLase());
    }

    let dep = ClampF(-t.camPitch, 0.0, 90.0);
    let ax = this.BC(1162.0);
    let ay = this.BY(350.0);
    let a = Deg2Rad(270.0 - dep);
    let r = this.OB_DEP_R;
    CMInk.Seg(this.m_obDepNeedle, ax + SinF(a) * (r - 40.0), ay - CosF(a) * (r - 40.0), ax + SinF(a) * (r + 8.0), ay - CosF(a) * (r + 8.0), 8.0);
    CMInk.Text(this.m_obDep, CMText.OctBDep(IntToString(RoundF(dep))));

    let sp = t.ringOk && t.blastR > 0.0 && ArraySize(t.ring) == ArraySize(this.m_obSplash);
    let topR = Vector2(0.0, 0.0);
    let best = -99999.0;
    let n = 0;
    while n < ArraySize(this.m_obSplash) {
      let s = this.m_obSplash[n];
      s.SetVisible(sp && n % 2 == 0);
      if sp {
        let p0 = t.ring[n];
        let p1 = t.ring[(n + 1) % ArraySize(t.ring)];
        CMInk.Seg(s, cx + p0.X, cy + p0.Y, cx + p1.X, cy + p1.Y, 8.0);
        if p0.X - p0.Y > best {
          best = p0.X - p0.Y;
          topR = Vector2(cx + p0.X, cy + p0.Y);
        }
      }
      n += 1;
    }
    this.m_obLeader[0].SetVisible(sp);
    this.m_obLeader[1].SetVisible(sp);
    this.m_obSplashT.SetVisible(sp);
    this.m_obSplashT2.SetVisible(sp);
    if sp {
      let kx = topR.X + 103.0;
      let ky = topR.Y - 82.0;
      CMInk.Seg(this.m_obLeader[0], topR.X, topR.Y, kx, ky, 5.0);
      CMInk.Seg(this.m_obLeader[1], kx, ky, kx + 253.0, ky, 5.0);
      this.m_obSplashT.SetMargin(inkMargin(kx + 10.0, ky - 57.0, 0.0, 0.0));
      CMInk.Text(this.m_obSplashT, CMText.OctBSpread(IntToString(RoundF(t.blastR))));
      this.m_obSplashT2.SetMargin(inkMargin(kx + 10.0, ky + 10.0, 0.0, 0.0));
      CMInk.Text(this.m_obSplashT2, CMText.OctBTof(FloatToStringPrec(t.tof, 1)));
    }
    if !slow {
      return;
    }

    let c = this.OB_MAP_R;
    let k = c / 100.0;
    let lim = c - 10.0;
    this.m_obSelf.SetRotation(-t.yaw);
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
    CMInk.FillFan(this.m_obFan, ArraySize(fp) == 3, ArraySize(fp) == 3 ? fp[0] : Vector2(0.0, 0.0), ArraySize(fp) == 3 ? fp[1] : Vector2(0.0, 0.0), ArraySize(fp) == 3 ? fp[2] : Vector2(0.0, 0.0), 8.0);
    let e = 0;
    while e < ArraySize(this.m_obFootEdge) {
      let eb = this.m_obFootEdge[e];
      eb.SetVisible(ArraySize(fp) == 3);
      if ArraySize(fp) == 3 {
        let p0 = fp[e];
        let p1 = fp[(e + 1) % 3];
        CMInk.Seg(eb, p0.X, p0.Y, p1.X, p1.Y, 3.0);
      }
      e += 1;
    }
    let tOn = false;
    if t.aimOk {
      let tx = (t.aim.X - t.pos.X) * k;
      let ty = -(t.aim.Y - t.pos.Y) * k;
      tOn = SqrtF(tx * tx + ty * ty) < lim;
      this.m_obTgtMark.SetMargin(inkMargin(c + tx - 13.0, c + ty - 13.0, 0.0, 0.0));
    }
    this.m_obTgtMark.SetVisible(tOn);
    this.m_obV.SetVisible(false);
    let i = 0;
    let nn = Min(ArraySize(t.contacts), ArraySize(this.m_obDots));
    while i < nn {
      let ct = t.contacts[i];
      let dx = (ct.pos.X - t.pos.X) * k;
      let dy = -(ct.pos.Y - t.pos.Y) * k;
      let show = SqrtF(dx * dx + dy * dy) < lim;
      let d = this.m_obDots[i];
      if ct.kind == 0 {
        d.SetVisible(false);
        this.m_obV.SetVisible(show);
        this.m_obV.SetMargin(inkMargin(c + dx - 10.0, c + dy - 10.0, 0.0, 0.0));
      } else {
        d.SetVisible(show);
        if show {
          d.SetMargin(inkMargin(c + dx - 10.0, c + dy - 10.0, 0.0, 0.0));
          d.SetTintColor(ct.kind == 2 ? this.Pal().hostile : (ct.kind == 4 ? this.BAcc() : this.BDim()));
        }
      }
      i += 1;
    }
    while i < ArraySize(this.m_obDots) {
      this.m_obDots[i].SetVisible(false);
      i += 1;
    }

    let acc = t.rounds > 0 ? RoundF(Cast<Float>(t.hits) * 100.0 / Cast<Float>(t.rounds)) : 0;
    if ArraySize(this.m_obBda) >= 5 {
      CMInk.Text(this.m_obBda[0], IntToString(this.m_obKills));
      CMInk.Text(this.m_obBda[1], IntToString(t.rounds));
      CMInk.Text(this.m_obBda[2], IntToString(t.hits));
      CMInk.Text(this.m_obBda[3], IntToString(acc) + "%");
      CMInk.Text(this.m_obBda[4], IntToString(t.hostiles));
      this.m_obBda[4].SetTintColor(t.hostiles > 0 ? this.Pal().hostile : this.BInk());
    }
  }

  public func StartBoot() -> Void {
    this.m_obBoot = 0.8;
    this.m_obClock = 0.0;
    if IsDefined(this.FRoot()) {
      this.FRoot().SetOpacity(0.0);
    }
  }

  public func Boot(dt: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_obClock += dt;
    if this.m_obBoot > 0.0 {
      this.m_obBoot = MaxF(0.0, this.m_obBoot - dt);
      this.FRoot().SetOpacity(1.0 - this.m_obBoot / 0.8);
    }
    let ph = this.m_obClock - Cast<Float>(FloorF(this.m_obClock));
    this.m_obRec.SetOpacity(ph < 0.5 ? 1.0 : 0.15);

    if this.m_obFlash > 0.0 {
      this.m_obFlash -= dt;
      this.m_obCross.SetTintColor(this.m_obFlash > 0.0 ? this.BAcc() : new HDRColor(1.0, 1.0, 1.0, 1.0));
    }

    if this.m_obThreatT > 0.0 {
      this.m_obThreatT -= dt;
      let rel = CMPilotRig.Wrap(this.m_obThreatB - this.m_obHeading);
      let x = this.FW() * 0.5 + rel * this.OB_PX;
      this.m_obThreatTick.SetVisible(this.m_obThreatT > 0.0 && AbsF(rel * this.OB_PX) <= this.OB_HALF);
      this.m_obThreatTick.SetMargin(inkMargin(x - 15.0, this.BY(34.0), 0.0, 0.0));
    } else {
      this.m_obThreatTick.SetVisible(false);
    }
  }

  public func HitFrom(off: Float) -> Void {
    this.m_obThreatT = 3.0;
    this.m_obThreatB = this.m_obHeading - off;
  }

  public func Hit(kill: Bool) -> Void {
    this.m_obFlash = kill ? 0.5 : 0.15;
    if kill {
      this.m_obKills += 1;
    }
  }
}
