module ControllableMechs

import ControllableMechs.Control.*

public class CMWyvernBHud extends CMDroneBHud {
  private let m_wbLink: ref<inkText>;
  private let m_wbZoom: ref<inkText>;
  private let m_wbFov: ref<inkText>;
  private let m_wbAf: ref<inkText>;
  private let m_wbRec: ref<inkImage>;
  private let m_wbClock: ref<inkText>;
  private let m_wbGrid: ref<inkText>;
  private let m_wbTags: ref<inkText>;
  private let m_wbChip: array<ref<inkImage>>;
  private let m_wbRowTag: array<ref<inkText>>;
  private let m_wbRowLab: array<ref<inkText>>;
  private let m_wbRowDist: array<ref<inkText>>;
  private let m_wbRowSep: array<ref<inkImage>>;
  private let m_wbRowRole: array<ref<inkText>>;
  private let m_wbPing: array<ref<inkWidget>>;
  private let m_wbPingT: ref<inkText>;
  private let m_wbGun: ref<inkText>;
  private let m_wbGunSt: ref<inkText>;
  private let m_wbHeat: ref<CMMtMeter>;
  private let m_wbRing: array<ref<inkWidget>>;
  private let m_wbScan: ref<inkText>;
  private let m_wbRng: ref<inkText>;
  private let m_wbDia: array<ref<inkCanvas>>;
  private let m_wbDiaChip: array<ref<inkImage>>;
  private let m_wbDiaImg: array<ref<inkImage>>;
  private let m_wbDiaTag: array<ref<inkText>>;
  private let m_wbDiaLine: array<ref<inkText>>;
  private let m_wbSpd: ref<inkText>;
  private let m_wbAlt: ref<inkText>;
  private let m_wbVs: ref<inkText>;
  private let m_wbZoomMark: ref<inkImage>;
  private let m_wbZoomT: ref<inkText>;
  private let m_wbDots: array<ref<inkImage>>;
  private let m_wbV: ref<inkImage>;
  private let m_wbSweep: ref<inkImage>;
  private let m_wbSelf: ref<inkCanvas>;
  private let m_wbSig: ref<CMMtMeter>;
  private let m_wbSigT: ref<inkText>;
  private let m_wbDet: ref<inkText>;
  private let m_wbWarn: ref<inkText>;
  private let m_wbRotorsT: ref<inkText>;
  private let m_wbSprite: array<ref<inkImage>>;
  private let m_wbRotor: array<ref<inkCanvas>>;
  private let m_wbRotorImg: array<ref<inkImage>>;
  private let m_wbLost: ref<inkText>;
  private let m_wbHull: ref<CMMtMeter>;
  private let m_wbT: Float;
  private let m_wbBoot: Float;
  private let m_wbSpool: Float;
  private let m_wbSpeed: Float;
  private let m_wbGunHeat: Float;
  private let m_wbSensor: String;
  private let m_wbAfOn: Bool;

  private let WB_RING_R: Float = 284.0;
  private let WB_RING_N: Int32 = 72;
  private let WB_RADAR_R: Float = 196.0;
  private let WB_PING_COOL: Float = 20.0;

  private func RadarX() -> Float = this.BL(152.0)
  private func RadarY() -> Float = this.BY(712.0)

  protected func BuildFeed(root: ref<inkCanvas>) -> Void {
    CMPilotHud.Bar(root, 0.0, 0.0, this.FW(), 2160.0, new HDRColor(0.08, 0.16, 0.20, 1.0), 0.10);
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
    let mr = this.Rg(2, 1);
    let bl = this.Rg(0, 2);
    let bc = this.Rg(1, 2);
    this.BFrame(this.Face(), W);

    this.BPlateXY(tl, this.BL(26.0), this.BY(20.0), this.BL(372.0), this.BY(92.0), 14.0, this.BDim(), false);
    this.BHazard(tl, this.BL(30.0), this.BY(26.0), this.BL(14.0), this.BY(60.0));
    this.BT(tl, this.BL(54.0), this.BY(22.0), "MT-WYV  WYVERN", 30.0, this.BInk(), 0);
    this.BT(tl, this.BL(56.0), this.BY(60.0), CMText.WyvBRole(), 13.0, this.BDim(), 0);
    this.BT(tl, this.BL(362.0), this.BY(26.0), CMText.OctBLink(), 11.0, this.BDim(), 2);
    this.m_wbLink = this.BT(tl, this.BL(362.0), this.BY(42.0), "", 20.0, this.BInk(), 2);

    this.BPlateXY(tc, this.BC(830.0), this.BY(16.0), this.BC(1170.0), this.BY(74.0), 12.0, this.BDim(), false);
    this.BT(tc, this.BC(844.0), this.BY(22.0), "EO / IR", 22.0, this.BInk(), 0);
    this.m_wbZoom = this.BT(tc, this.BC(1156.0), this.BY(20.0), "", 26.0, this.BAcc(), 2);
    this.m_wbFov = this.BT(tc, this.BC(844.0), this.BY(50.0), "", 12.0, this.BDim(), 0);
    this.BPlateXY(tc, this.BC(1040.0), this.BY(50.0), this.BC(1156.0), this.BY(68.0), 5.0, this.BAcc(), false);
    this.m_wbAf = this.BT(tc, this.BC(1098.0), this.BY(51.0), "", 11.0, this.BAcc(), 1);

    this.BPlateXY(tr, this.BR(1700.0), this.BY(20.0), this.BR(1972.0), this.BY(92.0), 14.0, this.BDim(), true);
    this.m_wbRec = CMKit.Disc(tr, this.BR(1716.0), this.BY(40.0), 15.0, this.Pal().hostile, 1.0);
    this.BT(tr, this.BR(1730.0), this.BY(26.0), "REC ISR", 16.0, this.BInk(), 0);
    this.m_wbClock = this.BT(tr, this.BR(1958.0), this.BY(24.0), "", 24.0, this.BInk(), 2);
    this.m_wbGrid = this.BT(tr, this.BR(1716.0), this.BY(62.0), "", 12.0, this.BDim(), 0);

    this.BPlateXY(ml, this.BL(24.0), this.BY(180.0), this.BL(360.0), this.BY(380.0), 14.0, this.BDim(), true);
    this.m_wbTags = this.PlateHead(ml, this.BL(24.0), this.BY(180.0), this.BL(336.0), CMText.WyvContacts(), "", this.Pal().warn);
    let i = 0;
    while i < 4 {
      let y = this.BY(216.0 + Cast<Float>(i) * 30.0);

      let chip = CMKit.Nine(ml, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), this.BL(34.0), y, this.BL(62.0), this.BY(24.0), this.BAcc(), 1.0);
      ArrayPush(this.m_wbChip, chip);
      ArrayPush(this.m_wbRowTag, this.BT(ml, this.BL(65.0), y + 2.0, "", 17.0, this.BDark(), 1));
      CMKit.Ln(ml, this.BL(100.0), y + 6.0, 3.0, this.BY(24.0) - 12.0, this.BDim(), 0.8);
      ArrayPush(this.m_wbRowLab, this.BT(ml, this.BL(106.0), y + 2.0, "", 17.0, this.BInk(), 0));
      ArrayPush(this.m_wbRowDist, this.BT(ml, this.BL(350.0), y + 2.0, "", 17.0, this.BInk(), 2));

      let sep = CMKit.Disc(ml, 0.0, y + this.BY(12.0), 4.0, this.BDim(), 1.0);
      sep.SetVisible(false);
      ArrayPush(this.m_wbRowSep, sep);
      ArrayPush(this.m_wbRowRole, this.BT(ml, 0.0, y + 2.0, "", 17.0, this.BDim(), 0));
      i += 1;
    }
    CMInk.Circle(ml, this.BL(46.0), this.BY(352.0), 26.0, this.BDim(), 0.8);
    this.m_wbPing = CMInk.Ring(ml, this.BL(46.0), this.BY(352.0), 26.0, 36, 5.0, this.BAcc(), 1.0);
    this.m_wbPingT = this.BT(ml, this.BL(64.0), this.BY(343.0), "", 13.0, this.BAcc(), 0);

    this.BPlateXY(ml, this.BL(24.0), this.BY(392.0), this.BL(360.0), this.BY(450.0), 10.0, this.BDim(), true);
    this.m_wbGun = this.BT(ml, this.BL(36.0), this.BY(398.0), "", 18.0, this.BInk(), 0);
    this.m_wbGunSt = this.BT(ml, this.BL(350.0), this.BY(400.0), "", 15.0, this.Pal().friendly, 2);
    this.BT(ml, this.BL(36.0), this.BY(424.0), CMText.OctBHeat(), 11.0, this.BDim(), 0);
    this.m_wbHeat = CMMtMeter.Make(ml, this.BL(80.0), this.BY(428.0), this.BL(200.0), 23.0, this.Pal().warn, CMHudPal.Of(0));

    CMInk.Circle(mc, cx, cy, this.WB_RING_R, this.BDim(), 0.6);
    this.m_wbRing = CMInk.Ring(mc, cx, cy, this.WB_RING_R, this.WB_RING_N, 10.0, this.BAcc(), 1.0);
    for w in this.m_wbRing {
      w.SetVisible(false);
    }
    this.m_wbScan = this.BT(mc, this.BC(1112.0), this.BY(300.0), "", 15.0, this.BAcc(), 0);
    CMKit.Brackets(mc, this.BC(950.0), this.BY(384.0), 100.0 * 2.58, 72.0 * 2.571, 31.0, this.BInk(), 1.0);
    CMKit.Ln(mc, cx - 26.0, cy - 2.5, 52.0, 5.0, this.BInk(), 1.0);
    CMKit.Ln(mc, cx - 2.5, cy - 26.0, 5.0, 52.0, this.BInk(), 1.0);
    this.BPlateXY(mc, this.BC(908.0), this.BY(546.0), this.BC(1092.0), this.BY(572.0), 8.0, this.BDim(), false);
    this.m_wbRng = this.BT(mc, cx, this.BY(548.0), "", 14.0, this.BInk(), 1);
    this.m_wbWarn = this.BT(mc, cx, this.BY(250.0), "", 18.0, this.Pal().hostile, 1);

    this.BPlateXY(mc, this.BC(670.0), this.BY(398.0), this.BC(756.0), this.BY(442.0), 8.0, this.BInk(), false);
    this.m_wbSpd = this.BT(mc, this.BC(713.0), this.BY(400.0), "", 26.0, this.BInk(), 1);
    this.BT(mc, this.BC(713.0), this.BY(446.0), "KM/H", 11.0, this.BDim(), 1);
    this.BPlateXY(mc, this.BC(1244.0), this.BY(398.0), this.BC(1330.0), this.BY(442.0), 8.0, this.BInk(), false);
    this.m_wbAlt = this.BT(mc, this.BC(1287.0), this.BY(400.0), "", 26.0, this.BInk(), 1);
    this.m_wbVs = this.BT(mc, this.BC(1287.0), this.BY(446.0), "", 11.0, this.BDim(), 1);

    this.BPlateXY(mr, this.BR(1930.0), this.BY(230.0), this.BR(1966.0), this.BY(520.0), 8.0, this.BDim(), true);
    i = 0;
    while i < 9 {
      let len = (i % 2 == 0 ? 14.0 : 7.0) * 2.58;
      CMKit.Ln(mr, this.BR(1958.0) - len, this.BY(246.0 + Cast<Float>(i) * 33.0) - 2.5, len, 5.0, this.BInk(), 1.0);
      i += 1;
    }
    this.BT(mr, this.BR(1948.0), this.BY(210.0), CMText.WyvZoom(), 11.0, this.BDim(), 1);
    this.m_wbZoomMark = CMKit.Img(mr, n"tri", this.BR(1918.0), this.BY(506.0), 31.0, 31.0, this.Pal().warn, 1.0);
    this.m_wbZoomMark.SetRenderTransformPivot(Vector2(0.5, 0.5));
    this.m_wbZoomMark.SetRotation(90.0);
    this.m_wbZoomT = this.BT(mr, this.BR(1914.0), this.BY(503.0), "", 14.0, this.Pal().warn, 2);

    this.BPlateXY(bl, this.BL(24.0), this.BY(600.0), this.BL(280.0), this.BY(800.0), 14.0, this.BDim(), true);
    this.PlateHead(bl, this.BL(24.0), this.BY(600.0), this.BL(256.0), CMText.WyvBSweep(), CMText.WyvBSweepScale(), this.BDim());
    let rx = this.RadarX();
    let ry = this.RadarY();
    let rr = this.WB_RADAR_R;
    CMInk.Circle(bl, rx, ry, rr, this.BDim(), 0.9);
    CMInk.Circle(bl, rx, ry, rr * 0.5, this.BDim(), 0.7);
    this.m_wbSweep = CMKit.Stroke(bl, this.BAcc(), 1.0);
    i = 0;
    while i < 32 {
      let d = CMKit.Disc(bl, rx, ry, 10.0, this.BDim(), 1.0);
      d.SetVisible(false);
      ArrayPush(this.m_wbDots, d);
      i += 1;
    }
    this.m_wbV = CMKit.Disc(bl, rx, ry, 10.0, this.Pal().friendly, 1.0);
    this.m_wbSelf = new inkCanvas();
    this.m_wbSelf.SetMargin(inkMargin(rx - 16.0, ry - 21.0, 0.0, 0.0));
    this.m_wbSelf.SetSize(Vector2(32.0, 34.0));
    this.m_wbSelf.Reparent(bl);
    CMKit.Img(this.m_wbSelf, n"tri", 0.0, 0.0, 32.0, 34.0, this.BInk(), 1.0);

    this.BPlateXY(bc, this.BC(780.0), this.BY(740.0), this.BC(1220.0), this.BY(800.0), 12.0, this.BDim(), false);
    this.BT(bc, this.BC(794.0), this.BY(746.0), CMText.WyvBSignature(), 13.0, this.BDim(), 0);
    this.m_wbSig = CMMtMeter.Make(bc, this.BC(794.0), this.BY(772.0), this.BL(220.0), 31.0, this.Pal().warn, CMHudPal.Of(0));
    this.m_wbSigT = this.BT(bc, this.BC(1024.0), this.BY(766.0), "", 20.0, this.Pal().warn, 0);
    this.BT(bc, this.BC(1206.0), this.BY(746.0), CMText.WyvBDetectedBy(), 13.0, this.BDim(), 2);
    this.m_wbDet = this.BT(bc, this.BC(1206.0), this.BY(766.0), "", 20.0, this.Pal().friendly, 2);
    this.BT(bc, cx, this.BY(812.0), CMText.WyvKeys(CMKeyName.Fire(), CMKeyName.Secondary(), CMKeyName.Aim(), CMKeyName.Sensor()), 11.0, this.BDim(), 1);

    i = 0;
    while i < 12 {
      let dia = new inkCanvas();
      dia.SetSize(Vector2(46.0, 46.0));
      dia.Reparent(root);
      ArrayPush(this.m_wbDiaImg, CMKit.Img(dia, n"diamond_line", 0.0, 0.0, 46.0, 46.0, this.BAcc(), 1.0));
      dia.SetVisible(false);
      ArrayPush(this.m_wbDia, dia);
      let chip = CMKit.Nine(root, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), 0.0, 0.0, 119.0, 51.0, this.BAcc(), 0.9);
      chip.SetVisible(false);
      ArrayPush(this.m_wbDiaChip, chip);
      let tg = this.BT(root, 0.0, 0.0, "", 13.0, this.BDark(), 1);
      tg.SetVisible(false);
      ArrayPush(this.m_wbDiaTag, tg);
      let ln = this.BT(root, 0.0, 0.0, "", 13.0, this.BAcc(), 0);
      ln.SetVisible(false);
      ArrayPush(this.m_wbDiaLine, ln);
      i += 1;
    }
  }

  protected func BuildSprite(root: ref<inkCanvas>) -> Void {
    let br = this.Rg(2, 2);
    this.BPlateXY(br, this.BR(1700.0), this.BY(580.0), this.BR(1976.0), this.BY(800.0), 14.0, this.BDim(), false);
    this.m_wbRotorsT = this.PlateHead(br, this.BR(1700.0), this.BY(580.0), 276.0 * 2.58, CMText.WyvAirframe(), "", this.Pal().warn);
    let k = this.BL(110.0) / 273.0;
    let box = new inkCanvas();
    box.SetMargin(inkMargin(this.BR(1714.0), this.BY(616.0), 0.0, 0.0));
    box.SetSize(Vector2(273.0 * k, 360.0 * k));
    box.Reparent(br);
    this.WbPart(box, k, n"wyvern_arm_l", 146.0, 52.0, 123.0, 205.0);
    this.WbPart(box, k, n"wyvern_arm_r", 5.0, 101.0, 145.0, 189.0);
    this.WbPart(box, k, n"wyvern_body", 42.0, 5.0, 189.0, 337.0);
    this.WbPart(box, k, n"wyvern_gun", 170.0, 324.0, 28.0, 31.0);
    let bx = this.BR(1900.0);
    let by = this.BY(680.0);
    CMKit.Nine(br, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), bx - 15.0, by - 103.0, 31.0, 206.0, this.BInk(), 0.8);
    let side = -1;
    while side <= 1 {
      let j = 0;
      while j < 3 {
        let ox = bx + Cast<Float>(side) * (j == 1 ? 24.0 : 30.0) * 2.58;
        let oy = by + Cast<Float>(j - 1) * 30.0 * 2.571;
        let rc = new inkCanvas();
        rc.SetMargin(inkMargin(ox - 28.0, oy - 28.0, 0.0, 0.0));
        rc.SetSize(Vector2(56.0, 56.0));
        rc.Reparent(br);

        ArrayPush(this.m_wbRotorImg, CMInk.Circle(rc, 28.0, 28.0, 26.0, this.BAcc(), 1.0));
        ArrayPush(this.m_wbRotorImg, CMKit.Ln(rc, 10.0, 25.5, 36.0, 5.0, this.BAcc(), 1.0));
        ArrayPush(this.m_wbRotor, rc);
        j += 1;
      }
      side += 2;
    }
    this.m_wbLost = this.BT(br, bx, this.BY(726.0), "", 12.0, this.Pal().hostile, 1);
    this.BT(br, this.BR(1714.0), this.BY(760.0), CMText.OctBHull(), 13.0, this.BDim(), 0);
    this.m_wbHull = CMMtMeter.Make(br, this.BR(1758.0), this.BY(764.0), this.BL(196.0), 31.0, this.BInk(), CMHudPal.Of(0));
  }

  private func WbPart(box: ref<inkCanvas>, k: Float, name: CName, x: Float, y: Float, w: Float, h: Float) -> Void {
    let img = new inkImage();
    img.SetAtlasResource(CMDroneHud.Atlas());
    img.SetTexturePart(name);
    img.SetMargin(inkMargin(x * k, y * k, 0.0, 0.0));
    img.SetSize(Vector2(w * k, h * k));
    img.SetTintColor(this.BInk());
    img.SetInteractive(false);
    img.Reparent(box);
    ArrayPush(this.m_wbSprite, img);
  }

  private func WbCol(hp: Float) -> HDRColor = hp <= 0.0 ? this.Pal().hostile : (hp < 0.6 ? this.Pal().warn : this.BAcc())

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_wbSpool = ClampF(s.spool, 0.0, 1.0);
    let sig = ClampF(s.signal, 0.0, 1.0);
    CMInk.Text(this.m_wbLink, IntToString(RoundF(sig * 100.0)) + "%");
    this.m_wbLink.SetTintColor(sig < 0.35 ? this.Pal().hostile : this.BInk());
    let warn = s.warning;
    if sig < 0.35 {
      warn = CMText.BmbLinkWeak();
    } else {
      if s.integrity < 0.3 {
        warn = CMText.BmbHullCritical();
      }
    }
    CMInk.Text(this.m_wbWarn, warn);
    let hull = ClampF(s.integrity, 0.0, 1.0);
    this.m_wbHull.Set(hull, hull < 0.3 ? this.Pal().hostile : (hull < 0.6 ? this.Pal().warn : this.BInk()));

    let up = 6;
    let lost = "";
    let worstL = 1.0;
    let worstR = 1.0;
    if ArraySize(s.droneParts) >= 7 && ArraySize(this.m_wbRotor) >= 6 {
      up = 0;
      let i = 0;
      while i < 6 {
        let hp = s.droneParts[i + 1];

        let col = this.WbCol(hp);
        this.m_wbRotorImg[i * 2].SetTintColor(col);
        this.m_wbRotorImg[i * 2 + 1].SetTintColor(col);
        this.m_wbRotorImg[i * 2 + 1].SetRotation(hp <= 0.0 ? 45.0 : 0.0);
        this.m_wbRotor[i].SetOpacity(hp <= 0.0 ? 0.6 : 1.0);
        if hp > 0.0 {
          up += 1;
        } else {
          lost = lost + (StrLen(lost) > 0 ? " " : "") + (i < 3 ? "L" : "R") + IntToString(i % 3 + 1);
        }
        if i < 3 {
          worstL = MinF(worstL, hp);
        } else {
          worstR = MinF(worstR, hp);
        }
        i += 1;
      }
    }
    CMInk.Text(this.m_wbRotorsT, CMText.WyvBRotors(IntToString(up)));
    this.m_wbRotorsT.SetTintColor(up < 6 ? this.Pal().warn : this.BAcc());
    CMInk.Text(this.m_wbLost, StrLen(lost) > 0 ? CMText.WyvLost(lost) : "");
    let k = 0;
    for img in this.m_wbSprite {
      img.SetTintColor(k == 0 ? this.WbCol(worstL) : (k == 1 ? this.WbCol(worstR) : (hull < 0.3 ? this.Pal().hostile : this.BInk())));
      k += 1;
    }
    this.m_wbSensor = CMThermal.Label(s.sensor);
    this.m_wbAfOn = s.range > 0.0 && s.range < 2000.0;
    CMInk.Text(this.m_wbAf, this.m_wbAfOn ? CMText.WyvBAfLock() : CMText.WyvBAfHunt());

    let gs = ArraySize(s.wStat) > 0 ? s.wStat[0] : "RDY";

    let gname = ArraySize(s.wSub) > 0 ? "SMG 5.56 x2" : "LMG 7.62 x2";
    CMInk.Text(this.m_wbGun, gname);
    CMInk.Text(this.m_wbGunSt, CMDroneHud.StatText(gs));
    this.m_wbGunSt.SetTintColor(Equals(gs, "OVERHEAT") ? this.Pal().hostile : (Equals(gs, "HOT") ? this.Pal().warn : this.Pal().friendly));
    this.m_wbGunHeat = ClampF(s.secHeat, 0.0, 1.0);
    this.m_wbHeat.Set(this.m_wbGunHeat, this.m_wbGunHeat >= 0.99 ? this.Pal().hostile : this.Pal().warn);
  }

  public func SetFlight(pitch: Float, roll: Float, speed: Float, alt: Float, vs: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_wbSpeed = speed;
    CMInk.Text(this.m_wbSpd, IntToString(RoundF(speed * 3.6)));
    CMInk.Text(this.m_wbAlt, alt >= 0.0 ? FloatToStringPrec(alt, 1) : "---");
    CMInk.Text(this.m_wbVs, CMText.WyvBVs((vs >= 0.0 ? "+" : "") + FloatToStringPrec(vs, 1)));
  }

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    let cx = this.FW() * 0.5;
    let cy = 1080.0;

    let zoom = ClampF(TanF(Deg2Rad(35.0)) / TanF(Deg2Rad(MaxF(1.0, t.fov) * 0.5)), 1.0, 9.0);
    CMInk.Text(this.m_wbZoom, "X" + FloatToStringPrec(zoom, 1));
    CMInk.Text(this.m_wbFov, CMText.WyvBFov(IntToString(RoundF(t.fov)), this.m_wbSensor));
    CMInk.Text(this.m_wbGrid, CMText.WyvBGrid(FloatToStringPrec(t.pos.X, 1), FloatToStringPrec(t.pos.Y, 1)));
    let zi = ClampF((zoom - 1.0) / 8.0, 0.0, 1.0);
    let zy = this.BY(512.0) - zi * (this.BY(512.0) - this.BY(246.0));
    this.m_wbZoomMark.SetMargin(inkMargin(this.BR(1918.0), zy - 15.0, 0.0, 0.0));
    this.m_wbZoomT.SetMargin(inkMargin(this.BR(1914.0), zy - 22.0, 0.0, 0.0));
    CMInk.Text(this.m_wbZoomT, "X" + FloatToStringPrec(zoom, 1));

    let lit = t.scan < 0.0 ? 0 : RoundF(t.scan * Cast<Float>(this.WB_RING_N));
    let i = 0;
    while i < ArraySize(this.m_wbRing) {
      this.m_wbRing[i].SetVisible(i < lit);
      this.m_wbRing[i].SetTintColor(t.scan >= 1.0 ? this.Pal().warn : this.BAcc());
      i += 1;
    }
    if t.scan < 0.0 || !IsDefined(t.lock) {
      CMInk.Text(this.m_wbScan, "");
    } else {
      CMInk.Text(this.m_wbScan, t.scan >= 1.0 ? CMText.WyvBTagged(t.lock.Tag()) : CMText.WyvScan(IntToString(RoundF(t.scan * 100.0))));
    }
    CMInk.Text(this.m_wbRng, CMText.WyvBRng(t.aimOk ? IntToString(RoundF(Vector4.Distance(t.pos, t.aim))) : "---", CMDroneHud.Signed(t.camPitch)));

    let n = 0;
    for c in t.contacts {
      if n < ArraySize(this.m_wbDia) && c.tag > 0 && c.kind != 0 && c.OnScreen() {
        let col = c.kind == 2 ? this.Pal().hostile : CMInk.KindColor(c.kind, this.BAcc());
        let x = cx + c.scr.X;
        let y = cy + c.scr.Y;
        let d = this.m_wbDia[n];
        d.SetVisible(true);
        d.SetMargin(inkMargin(x - 23.0, y - 23.0, 0.0, 0.0));
        this.m_wbDiaImg[n].SetTintColor(col);
        let chip = this.m_wbDiaChip[n];
        chip.SetVisible(true);
        chip.SetMargin(inkMargin(x + 36.0, y - 28.0, 0.0, 0.0));
        chip.SetTintColor(col);
        let tg = this.m_wbDiaTag[n];
        tg.SetVisible(true);
        tg.SetMargin(inkMargin(x + 95.0, y - 26.0, 0.0, 0.0));
        CMInk.Text(tg, c.Tag());
        let ln = this.m_wbDiaLine[n];
        ln.SetVisible(true);
        ln.SetMargin(inkMargin(x + 170.0, y - 26.0, 0.0, 0.0));
        CMInk.Text(ln, c.Label() + "  " + IntToString(RoundF(c.dist)) + " M");
        ln.SetTintColor(col);
        n += 1;
      }
    }
    while n < ArraySize(this.m_wbDia) {
      this.m_wbDia[n].SetVisible(false);
      this.m_wbDiaChip[n].SetVisible(false);
      this.m_wbDiaTag[n].SetVisible(false);
      this.m_wbDiaLine[n].SetVisible(false);
      n += 1;
    }

    if !t.slow {
      return;
    }

    let rows: array<ref<CMDroneContact>>;
    for c in t.contacts {
      if c.tag > 0 {
        let at = ArraySize(rows);
        let j = 0;
        while j < ArraySize(rows) {
          if c.kind == 0 || (rows[j].kind != 0 && c.dist < rows[j].dist) {
            at = j;
            j = ArraySize(rows);
          }
          j += 1;
        }
        ArrayInsert(rows, at, c);
      }
    }
    CMInk.Text(this.m_wbTags, CMText.WyvBTags(IntToString(t.tagged), IntToString(ArraySize(t.contacts))));
    let r = 0;
    while r < 4 {
      if r < ArraySize(rows) {
        let c = rows[r];
        let col = c.kind == 0 ? this.Pal().friendly : (c.kind == 2 ? this.Pal().hostile : CMInk.KindColor(c.kind, this.BAcc()));
        this.m_wbChip[r].SetVisible(true);
        this.m_wbChip[r].SetTintColor(col);
        CMInk.Text(this.m_wbRowTag[r], c.Tag());

        let name = c.LabelName();
        let role = c.LabelRole();
        CMInk.Text(this.m_wbRowLab[r], name);
        let rx = this.BL(106.0) + Cast<Float>(StrLen(name)) * 25.0 + 22.0;
        this.m_wbRowSep[r].SetVisible(StrLen(role) > 0);
        this.m_wbRowSep[r].SetMargin(inkMargin(rx - 4.0, this.BY(216.0 + Cast<Float>(r) * 30.0) + this.BY(12.0) - 4.0, 0.0, 0.0));
        this.m_wbRowRole[r].SetMargin(inkMargin(rx + 18.0, this.BY(216.0 + Cast<Float>(r) * 30.0) + 2.0, 0.0, 0.0));
        CMInk.Text(this.m_wbRowRole[r], role);
        CMInk.Text(this.m_wbRowDist[r], IntToString(RoundF(c.dist)) + " M");
      } else {
        this.m_wbChip[r].SetVisible(false);
        CMInk.Text(this.m_wbRowTag[r], "");
        CMInk.Text(this.m_wbRowLab[r], "");
        CMInk.Text(this.m_wbRowRole[r], "");
        this.m_wbRowSep[r].SetVisible(false);
        CMInk.Text(this.m_wbRowDist[r], "");
      }
      r += 1;
    }

    let ready = 1.0 - ClampF(t.pingLeft / this.WB_PING_COOL, 0.0, 1.0);
    let pl = RoundF(ready * Cast<Float>(ArraySize(this.m_wbPing)));
    let p = 0;
    while p < ArraySize(this.m_wbPing) {
      this.m_wbPing[p].SetVisible(p < pl);
      p += 1;
    }
    CMInk.Text(this.m_wbPingT, t.pingLeft > 0.0 ? CMText.WyvBPingCool(CMKeyName.Secondary(), IntToString(CeilF(t.pingLeft))) : CMText.WyvBPingReady(CMKeyName.Secondary()));

    let rx = this.RadarX();
    let ry = this.RadarY();
    let rr = this.WB_RADAR_R;
    let view = -t.yaw;
    n = 0;
    this.m_wbV.SetVisible(false);
    for c in t.contacts {
      let dx = c.pos.X - t.pos.X;
      let dy = c.pos.Y - t.pos.Y;
      let rad = SqrtF(dx * dx + dy * dy) / 100.0 * rr;
      let rel = Deg2Rad(Rad2Deg(AtanF(dx, dy)) - view);
      let px = rx + SinF(rel) * rad;
      let py = ry - CosF(rel) * rad;
      if c.kind == 0 {
        this.m_wbV.SetVisible(rad <= rr);
        this.m_wbV.SetMargin(inkMargin(px - 10.0, py - 10.0, 0.0, 0.0));
      } else {
        if n < ArraySize(this.m_wbDots) {
          let dot = this.m_wbDots[n];
          dot.SetVisible(rad <= rr);
          dot.SetMargin(inkMargin(px - 10.0, py - 10.0, 0.0, 0.0));
          dot.SetTintColor(c.kind == 2 ? this.Pal().hostile : (c.tag > 0 ? this.BAcc() : this.BDim()));
          n += 1;
        }
      }
    }
    while n < ArraySize(this.m_wbDots) {
      this.m_wbDots[n].SetVisible(false);
      n += 1;
    }

    let sg = ClampF(0.1 + this.m_wbSpool * 0.4 + this.m_wbSpeed / 25.0 * 0.5 + this.m_wbGunHeat * 0.6, 0.0, 1.0);
    this.m_wbSig.Set(sg, sg >= 0.7 ? this.Pal().hostile : this.Pal().warn);
    CMInk.Text(this.m_wbSigT, sg < 0.35 ? CMText.WyvBLow() : (sg < 0.7 ? CMText.WyvBMed() : CMText.WyvBHigh()));
    this.m_wbSigT.SetTintColor(sg >= 0.7 ? this.Pal().hostile : this.Pal().warn);
    CMInk.Text(this.m_wbDet, t.detected > 0 ? CMText.WyvBHostile(IntToString(t.detected)) : CMText.WyvBNone());
    this.m_wbDet.SetTintColor(t.detected > 0 ? this.Pal().hostile : this.Pal().friendly);
  }

  public func StartBoot() -> Void {
    this.m_wbBoot = 0.8;
    this.m_wbT = 0.0;
    if IsDefined(this.FRoot()) {
      this.FRoot().SetOpacity(0.0);
    }
  }

  public func Boot(dt: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_wbT += dt;
    if this.m_wbBoot > 0.0 {
      this.m_wbBoot = MaxF(0.0, this.m_wbBoot - dt);
      this.FRoot().SetOpacity(1.0 - this.m_wbBoot / 0.8);
    }
    CMInk.Text(this.m_wbClock, CMInk.Clock(this.m_wbT));
    let ph = this.m_wbT - Cast<Float>(FloorF(this.m_wbT));
    this.m_wbRec.SetOpacity(ph < 0.5 ? 1.0 : 0.15);

    let a = Deg2Rad((this.m_wbT / 3.0 - Cast<Float>(FloorF(this.m_wbT / 3.0))) * 360.0);
    let rx = this.RadarX();
    let ry = this.RadarY();
    CMInk.Seg(this.m_wbSweep, rx, ry, rx + SinF(a) * this.WB_RADAR_R, ry - CosF(a) * this.WB_RADAR_R, 5.0);
  }

  public func Hit(kill: Bool) -> Void {}
}
