module ControllableMechs

import ControllableMechs.Control.*

public class CMWyvernHud extends CMBombusHud {
  private let m_wyClock: Float;
  private let m_wyBoot: Float;
  private let m_wyBlink: Float;
  private let m_wyRec: ref<inkImage>;
  private let m_wyZoomMark: ref<inkText>;
  private let m_wyRing: array<ref<inkWidget>>;
  private let m_wyDia: array<ref<inkCanvas>>;
  private let m_wyDiaTag: array<ref<inkText>>;
  private let m_wyDiaLine: array<ref<inkText>>;
  private let m_wyDots: array<ref<inkImage>>;
  private let m_wyV: ref<inkCanvas>;
  private let m_wySweep: ref<inkImage>;
  private let m_wySpool: Float;
  private let m_wySpeed: Float;
  private let m_wyFocus: String;
  private let m_wyGunHeat: Float;

  private let m_wyBars: array<ref<inkImage>>;
  private let m_wyAf: array<ref<inkImage>>;
  private let m_wyRowBar: array<ref<inkImage>>;
  private let m_wyPing: array<ref<inkWidget>>;
  private let m_wyGunDot: ref<inkImage>;
  private let m_wyHeatArc: array<ref<inkWidget>>;
  private let m_wySteps: array<ref<inkImage>>;
  private let m_wyEyeShut: ref<inkImage>;
  private let m_wyEyeOpen: ref<inkCanvas>;
  private let m_wyRotor: array<ref<inkCanvas>>;
  private let m_wyRotorImg: array<ref<inkImage>>;
  private let m_wyHullS: ref<CMSlider>;

  private let WY_NAME: Int32 = 0;
  private let WY_ROLE: Int32 = 1;
  private let WY_EO: Int32 = 2;
  private let WY_FOV: Int32 = 3;
  private let WY_REC: Int32 = 4;
  private let WY_GRID: Int32 = 5;
  private let WY_ZOOM: Int32 = 6;
  private let WY_SCAN: Int32 = 7;
  private let WY_RNG: Int32 = 8;
  private let WY_LOG: Int32 = 9;
  private let WY_ROW0: Int32 = 10;
  private let WY_PING: Int32 = 22;
  private let WY_RADAR: Int32 = 23;
  private let WY_SIG: Int32 = 24;
  private let WY_DET: Int32 = 26;
  private let WY_SPD: Int32 = 28;
  private let WY_ALT: Int32 = 29;
  private let WY_VS: Int32 = 30;
  private let WY_HULL: Int32 = 31;
  private let WY_ROTORS: Int32 = 32;
  private let WY_WARN: Int32 = 33;
  private let WY_GUN: Int32 = 34;
  private let WY_KEYS: Int32 = 35;
  private let WY_TAGS: Int32 = 36;
  private let WY_SPDU: Int32 = 37;

  private let WY_RING_R: Float = 231.0;
  private let WY_RING_N: Int32 = 60;
  private let WY_RADAR_R: Float = 150.0;
  private let WY_RADAR_M: Float = 100.0;
  private let WY_PING_COOL: Float = 20.0;

  private func WyR() -> Float = this.FW() - 40.0

  private func Amb() -> HDRColor = this.Pal().warn

  private func RadarX() -> Float = 283.0
  private func RadarY() -> Float = 1773.0

  protected func BuildFeed(root: ref<inkCanvas>) -> Void {
    CMPilotHud.Bar(root, 0.0, 0.0, this.FW(), 2160.0, new HDRColor(0.08, 0.16, 0.20, 1.0), 0.12);
    CMKit.Vignette(root, this.FW(), 2160.0, 160.0, 0.3);
    CMKit.Brackets(root, 77.0, 51.0, this.FW() - 154.0, 2058.0, 56.0, this.Acc(), 0.8);
  }

  protected func PlatesB() -> Void {
    let W = this.FW();
    let cx = W * 0.5;
    let cy = 1080.0;
    this.BFrame(this.Face(), W);
    this.BPlate(this.Rg(0, 0), 100.0, 40.0, 690.0, 128.0, false);
    this.BHazard(this.Rg(0, 0), 108.0, 54.0, 20.0, 100.0);
    this.BPlate(this.Rg(1, 0), cx - 270.0, 36.0, 540.0, 108.0, true);
    this.BPlate(this.Rg(2, 0), W - 480.0, 36.0, 400.0, 108.0, true);
    this.BPlate(this.Rg(0, 1), 100.0, 470.0, 590.0, 340.0, true);
    this.BPlate(this.Rg(0, 1), 100.0, 1180.0, 420.0, 64.0, true);
    this.BPlate(this.Rg(0, 2), 100.0, 1590.0, 380.0, 380.0, true);
    this.BPlate(this.Rg(1, 2), cx - 270.0, 1978.0, 560.0, 70.0, false);
    this.BPlate(this.Rg(2, 1), W - 176.0, 600.0, 92.0, 660.0, false);
    this.BPlate(this.Rg(2, 2), W - 470.0, 1696.0, 360.0, 280.0, false);
    this.BPlate(this.Rg(0, 1), cx - 960.0, cy - 40.0, 210.0, 92.0, false);
    this.BPlate(this.Rg(2, 1), cx + 750.0, cy - 40.0, 210.0, 92.0, false);
    this.BPlate(this.Rg(1, 1), cx - 170.0, cy + 238.0, 340.0, 50.0, false);
  }

  protected func BuildOsd(root: ref<inkCanvas>) -> Void {
    let x1 = this.WyR();
    let cx = this.FW() * 0.5;
    let cy = 1080.0;
    let lx = 134.0;
    let ly = 514.0;
    let tl = this.Rg(0, 0);
    let tc = this.Rg(1, 0);
    let tr = this.Rg(2, 0);
    let ml = this.Rg(0, 1);
    let mc = this.Rg(1, 1);
    let mr = this.Rg(2, 1);
    let bl = this.Rg(0, 2);
    let bc = this.Rg(1, 2);
    let br = this.Rg(2, 2);

    this.Osd(tl, 134.0, 60.0, 34, 0);
    this.Osd(tl, 134.0, 108.0, 24, 0);
    this.Osd(tc, cx, 56.0, 34, 1);
    this.Osd(tc, cx, 104.0, 22, 1);
    this.Osd(tr, x1 - 99.0, 56.0, 34, 2);
    this.Osd(tr, x1 - 99.0, 104.0, 22, 2);
    this.Osd(mr, x1 - 89.0, 618.0, 20, 1);
    this.Osd(mc, cx + 247.0, cy - 270.0, 26, 0);
    this.Osd(mc, cx, cy + 250.0, 24, 1);
    this.Osd(ml, lx, ly - 20.0, 22, 0);
    let r = 0;
    while r < 4 {
      let ry = ly + 40.0 + Cast<Float>(r) * 46.0;
      this.Osd(ml, lx + 20.0, ry, 24, 0);
      this.Osd(ml, lx + 123.0, ry, 24, 0);
      this.Osd(ml, lx + 514.0, ry, 24, 2);
      r += 1;
    }
    this.Osd(ml, lx + 77.0, ly + 230.0, 24, 0);
    this.Osd(bl, this.RadarX(), this.RadarY() + this.WY_RADAR_R + 10.0, 20, 1);
    this.Osd(bc, cx - 172.0, 2000.0, 22, 2);
    this.Osd(bc, cx, 0.0, 10, 0);
    this.Osd(bc, cx + 214.0, 1996.0, 30, 0);
    this.Osd(bc, cx, 0.0, 10, 0);
    this.Osd(ml, cx - 771.0, cy - 30.0, 40, 2);
    this.Osd(mr, cx + 771.0, cy - 30.0, 40, 0);
    this.Osd(mr, cx + 771.0, cy + 22.0, 22, 0);
    this.Osd(br, x1 - 371.0, 1928.0, 20, 0);
    this.Osd(br, x1 - 165.0, 1928.0, 20, 2);
    this.Osd(mc, cx, 820.0, 44, 1);
    this.Osd(ml, lx, 1196.0, 24, 0);
    this.Osd(bc, cx, 2060.0, 20, 1);
    this.Osd(ml, lx + 180.0, ly - 26.0, 30, 0);
    this.Osd(ml, cx - 771.0, cy + 22.0, 22, 2);
    for i in [this.WY_ROLE, this.WY_FOV, this.WY_GRID, this.WY_ZOOM, this.WY_SCAN, this.WY_PING, this.WY_RADAR, this.WY_SIG, this.WY_VS, this.WY_LOG, this.WY_SPDU, this.WY_HULL] {
      this.Tint(i, this.Acc());
    }
    this.Tint(this.WY_TAGS, this.Amb());
    this.Tint(this.WY_KEYS, this.Acc());
    this.Tint(this.WY_ROTORS, this.Pal().hostile);
    this.SetT(this.WY_KEYS, CMText.WyvKeys(CMKeyName.Fire(), CMKeyName.Secondary(), CMKeyName.Aim(), CMKeyName.Sensor()));
    this.Tint(this.WY_WARN, this.Pal().hostile);
    this.SetT(this.WY_ZOOM, CMText.WyvZoom());
    this.SetT(this.WY_SIG, CMText.WyvSig());
    this.SetT(this.WY_HULL, CMText.WyvAirframe());
    this.SetT(this.WY_SPDU, "KMH");
    this.SetT(this.WY_LOG, CMText.WyvContacts());
    this.SetT(this.WY_RADAR, CMText.WyvRadar(IntToString(RoundF(this.WY_RADAR_M))));

    let b = 0;
    while b < 5 {
      let h = 10.0 + Cast<Float>(b) * 8.0;
      ArrayPush(this.m_wyBars, CMKit.Img(tl, n"pill_v", 643.0 + Cast<Float>(b) * 15.0, 149.0 - h, 9.0, h, this.Acc(), 1.0));
      b += 1;
    }

    this.m_wyAf = CMKit.Corners(tc, this.Acc(), 1.0, false);
    CMKit.PlaceCorners(this.m_wyAf, 0, cx + 170.0, 70.0, 36.0, 30.0, 12.0);

    this.m_wyRec = CMKit.Disc(tr, x1 - 378.0, 85.0, 10.0, this.Pal().hostile, 1.0);

    let zx = x1 - 89.0;
    let z = 0;
    while z < 9 {
      let len = z % 2 == 0 ? 16.0 : 8.0;
      CMKit.Ln(mr, zx - len, 668.0 + Cast<Float>(z) * 71.0, len, 3.0, this.Acc(), 0.8);
      z += 1;
    }
    CMKit.Ln(mr, zx - 1.0, 668.0, 2.0, 568.0, this.Acc(), 0.6);
    this.m_wyZoomMark = CMPilotHud.Label(mr, inkEAnchor.TopLeft, zx - 22.0, 1234.0, "> X1", 26, n"Semi-Bold", this.Amb());
    this.m_wyZoomMark.SetAnchorPoint(Vector2(1.0, 0.5));

    CMKit.Brackets(mc, cx - 103.0, cy - 72.0, 206.0, 144.0, 20.0, this.Acc(), 0.9);
    CMKit.Ln(mc, cx - 18.0, cy - 1.5, 36.0, 3.0, this.Ink(), 1.0);
    CMKit.Ln(mc, cx - 1.5, cy - 18.0, 3.0, 36.0, this.Ink(), 1.0);

    CMInk.Circle(mc, cx, cy, this.WY_RING_R, this.Acc(), 0.22);
    this.m_wyRing = CMInk.Ring(mc, cx, cy, this.WY_RING_R, this.WY_RING_N, 5.0, this.Acc(), 1.0);
    for w in this.m_wyRing {
      w.SetVisible(false);
    }

    let track = CMInk.Ring(mc, cx, cy, this.WY_RING_R + 36.0, 72, 6.0, this.Acc(), 0.18);
    let lit = CMInk.Ring(mc, cx, cy, this.WY_RING_R + 36.0, 72, 6.0, this.Amb(), 1.0);
    let q = 0;
    while q < 72 {
      let a = Cast<Float>(q) * 5.0;
      track[q].SetVisible(a >= 200.0 && a <= 250.0);
      lit[q].SetVisible(false);
      q += 1;
    }
    let hq = 50;
    while hq >= 40 {
      ArrayPush(this.m_wyHeatArc, lit[hq]);
      hq -= 1;
    }

    CMKit.Ln(ml, lx - 20.0, ly, 3.0, 308.0, this.Acc(), 0.7);
    let rb = 0;
    while rb < 4 {

      let bar = this.TypeB() ? CMKit.Fill(ml, lx + 8.0, ly + 38.0 + Cast<Float>(rb) * 46.0, 96.0, 36.0, this.Acc(), 1.0) : CMKit.Fill(ml, lx, ly + 46.0 + Cast<Float>(rb) * 46.0, 8.0, 26.0, this.Acc(), 1.0);
      bar.SetVisible(false);
      ArrayPush(this.m_wyRowBar, bar);
      rb += 1;
    }

    this.m_wyPing = CMInk.Ring(ml, lx + 31.0, ly + 246.0, 24.0, 36, 4.0, this.Acc(), 1.0);

    this.m_wyGunDot = CMKit.Disc(ml, lx + 270.0, 1212.0, 9.0, this.Pal().friendly, 1.0);

    let rx = this.RadarX();
    let ry = this.RadarY();
    let rr = this.WY_RADAR_R;
    CMInk.Circle(bl, rx, ry, rr, this.Acc(), 0.7);
    CMInk.Circle(bl, rx, ry, rr * 0.66, this.Acc(), 0.35);
    CMInk.Circle(bl, rx, ry, rr * 0.33, this.Acc(), 0.35);
    CMKit.Ln(bl, rx - rr, ry - 1.0, rr * 2.0, 2.0, this.Acc(), 0.2);
    CMKit.Ln(bl, rx - 1.0, ry - rr, 2.0, rr * 2.0, this.Acc(), 0.2);
    this.m_wySweep = CMKit.Stroke(bl, this.Acc(), 0.85);
    let d = 0;
    while d < 32 {
      let dot = CMKit.Disc(bl, rx, ry, 7.0, this.Acc(), 1.0);
      dot.SetVisible(false);
      ArrayPush(this.m_wyDots, dot);
      d += 1;
    }
    this.m_wyV = CMInk.Chevron(bl, 24.0, 4.0, CMInk.KindColor(0, this.Acc()));
    CMKit.Disc(bl, rx, ry, 5.0, this.Ink(), 1.0);

    let s = 0;
    while s < 3 {
      ArrayPush(this.m_wySteps, CMKit.Nine(bc, n"slant_h", inkMargin(0.0, 0.0, 10.0, 0.0), cx - 154.0 + Cast<Float>(s) * 77.0, 2000.0, 62.0, 22.0, this.Amb(), 1.0));
      s += 1;
    }

    this.m_wyEyeShut = CMKit.Ln(bc, cx + 150.0, 2010.0, 50.0, 4.0, this.Pal().friendly, 1.0);
    let eye = new inkCanvas();
    eye.SetMargin(inkMargin(cx + 150.0, 1986.0, 0.0, 0.0));
    eye.SetSize(Vector2(50.0, 50.0));
    eye.Reparent(bc);
    CMInk.Circle(eye, 25.0, 25.0, 20.0, this.Pal().hostile, 1.0);
    CMKit.Disc(eye, 25.0, 25.0, 8.0, this.Pal().hostile, 1.0);
    this.m_wyEyeOpen = eye;
    eye.SetVisible(false);

    let t = 0;
    while t < 12 {
      let dia = CMInk.Diamond(root, 36.0, this.Ink());
      dia.SetVisible(false);
      ArrayPush(this.m_wyDia, dia);
      let tg = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, "", 24, n"Semi-Bold", this.Acc());
      tg.SetVisible(false);
      ArrayPush(this.m_wyDiaTag, tg);
      let ln = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, "", 22, n"Medium", this.Acc());
      ln.SetVisible(false);
      ArrayPush(this.m_wyDiaLine, ln);
      t += 1;
    }
  }

  protected func BuildSprite(root: ref<inkCanvas>) -> Void {
    let br = this.Rg(2, 2);
    let bx = this.WyR() - 268.0;
    let by = 1800.0;
    CMKit.Fill(br, bx - 7.0, by - 62.0, 14.0, 124.0, this.Acc(), 0.75);
    let side = -1;
    while side <= 1 {
      let i = 0;
      while i < 3 {
        let ox = bx + Cast<Float>(side) * (i == 1 ? 36.0 : 51.0);
        let oy = by + Cast<Float>(i - 1) * 51.0;
        let rc = new inkCanvas();
        rc.SetMargin(inkMargin(ox - 20.0, oy - 20.0, 0.0, 0.0));
        rc.SetSize(Vector2(40.0, 40.0));
        rc.Reparent(br);

        ArrayPush(this.m_wyRotorImg, CMInk.Circle(rc, 20.0, 20.0, 17.0, this.Acc(), 1.0));
        ArrayPush(this.m_wyRotorImg, CMKit.Ln(rc, 6.0, 18.5, 28.0, 3.0, this.Acc(), 1.0));
        ArrayPush(this.m_wyRotor, rc);
        i += 1;
      }
      side += 2;
    }
    this.m_wyHullS = CMSlider.Make(br, this.WyR() - 371.0, 1912.0, 206.0, 6.0, false, this.Acc());
  }

  private func WyPartCol(hp: Float, crit: Float) -> HDRColor = hp <= crit ? this.Pal().hostile : (hp < 0.6 ? this.Pal().warn : this.Acc())

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_wySpool = ClampF(s.spool, 0.0, 1.0);
    this.SetT(this.WY_NAME, s.title);
    this.SetT(this.WY_ROLE, CMText.WyvRole());
    let sig = ClampF(s.signal, 0.0, 1.0);
    let n = 0;
    while n < ArraySize(this.m_wyBars) {
      this.m_wyBars[n].SetOpacity(sig * 5.0 > Cast<Float>(n) + 0.5 ? 1.0 : 0.2);
      this.m_wyBars[n].SetTintColor(sig < 0.35 ? this.Pal().hostile : this.Acc());
      n += 1;
    }
    let warn = s.warning;
    if sig < 0.35 {
      warn = CMText.BmbLinkWeak();
    } else {
      if s.integrity < 0.3 {
        warn = CMText.BmbHullCritical();
      }
    }
    this.SetT(this.WY_WARN, warn);
    let hull = ClampF(s.integrity, 0.0, 1.0);
    this.m_wyHullS.Set(hull, this.WyPartCol(hull, 0.3));

    let lost = "";
    if ArraySize(s.droneParts) >= 7 && ArraySize(this.m_wyRotor) >= 6 {
      let i = 0;
      while i < 6 {
        let hp = s.droneParts[i + 1];
        let col = this.WyPartCol(hp, 0.0);
        this.m_wyRotorImg[i * 2].SetTintColor(col);
        this.m_wyRotorImg[i * 2 + 1].SetTintColor(col);
        this.m_wyRotorImg[i * 2 + 1].SetRotation(hp <= 0.0 ? 45.0 : 0.0);
        this.m_wyRotor[i].SetOpacity(hp <= 0.0 ? 0.6 : 1.0);
        if hp <= 0.0 {
          lost = lost + (StrLen(lost) > 0 ? " " : "") + (i < 3 ? "L" : "R") + IntToString(i % 3 + 1);
        }
        i += 1;
      }
    }
    this.SetT(this.WY_ROTORS, StrLen(lost) > 0 ? CMText.WyvLost(lost) : "");
    this.m_wyFocus = CMText.WyvSns(CMThermal.Label(s.sensor));
    let af = s.range > 0.0 && s.range < 2000.0;
    for c in this.m_wyAf {
      c.SetOpacity(af ? 1.0 : 0.3);
    }

    let gs = ArraySize(s.wStat) > 0 ? s.wStat[0] : "RDY";
    this.SetT(this.WY_GUN, ArraySize(s.wSub) > 0 ? s.wSub[0] : "LMG 7.62 x2");
    this.m_wyGunDot.SetTintColor(Equals(gs, "OVERHEAT") ? this.Pal().hostile : (Equals(gs, "HOT") ? this.Amb() : this.Pal().friendly));
    this.m_wyGunHeat = ClampF(s.secHeat, 0.0, 1.0);
    let lit = RoundF(this.m_wyGunHeat * Cast<Float>(ArraySize(this.m_wyHeatArc)));
    let h = 0;
    while h < ArraySize(this.m_wyHeatArc) {
      this.m_wyHeatArc[h].SetVisible(h < lit);
      this.m_wyHeatArc[h].SetTintColor(this.m_wyGunHeat >= 0.99 ? this.Pal().hostile : this.Amb());
      h += 1;
    }
  }

  public func SetFlight(pitch: Float, roll: Float, speed: Float, alt: Float, vs: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_wySpeed = speed;
    this.SetT(this.WY_SPD, IntToString(RoundF(speed * 3.6)));
    this.SetT(this.WY_ALT, alt >= 0.0 ? FloatToStringPrec(alt, 1) + " M" : "--- M");
    this.SetT(this.WY_VS, CMText.OctBVs((vs >= 0.0 ? "+" : "") + FloatToStringPrec(vs, 1)));
  }

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    let cx = this.FW() * 0.5;
    let cy = 1080.0;

    let zoom = ClampF(TanF(Deg2Rad(35.0)) / TanF(Deg2Rad(MaxF(1.0, t.fov) * 0.5)), 1.0, 9.0);
    this.SetT(this.WY_EO, "EO / IR   X" + FloatToStringPrec(zoom, 1));
    this.SetT(this.WY_GRID, CMText.WyvGrid(FloatToStringPrec(t.pos.X, 1), FloatToStringPrec(t.pos.Y, 1)));
    let zi = ClampF((zoom - 1.0) / 8.0, 0.0, 1.0);
    this.m_wyZoomMark.SetMargin(inkMargin(this.WyR() - 111.0, 668.0 + (1.0 - zi) * 568.0, 0.0, 0.0));
    CMInk.Text(this.m_wyZoomMark, "> X" + FloatToStringPrec(zoom, 1));

    let lit = t.scan < 0.0 ? 0 : RoundF(t.scan * Cast<Float>(this.WY_RING_N));
    let i = 0;
    while i < ArraySize(this.m_wyRing) {
      this.m_wyRing[i].SetVisible(i < lit);
      this.m_wyRing[i].SetTintColor(t.scan >= 1.0 ? this.Amb() : this.Acc());
      i += 1;
    }
    if t.scan < 0.0 || !IsDefined(t.lock) {
      this.SetT(this.WY_SCAN, "");
    } else {
      this.SetT(this.WY_SCAN, t.scan >= 1.0 ? CMText.WyvTagged(t.lock.Tag(), t.lock.Label()) : CMText.WyvScan(IntToString(RoundF(t.scan * 100.0))));
    }
    this.SetT(this.WY_RNG, (t.aimOk ? IntToString(RoundF(Vector4.Distance(t.pos, t.aim))) + " M" : "--- M") + "   " + CMDroneHud.Signed(t.camPitch));

    let n = 0;
    for c in t.contacts {
      if n < ArraySize(this.m_wyDia) && c.tag > 0 && c.kind != 0 && c.OnScreen() {
        let col = CMInk.KindColor(c.kind, this.Acc());
        let x = cx + c.scr.X;
        let y = cy + c.scr.Y;
        let d = this.m_wyDia[n];
        d.SetVisible(true);
        d.SetMargin(inkMargin(x - 18.0, y - 18.0, 0.0, 0.0));
        d.SetTintColor(col);
        let tg = this.m_wyDiaTag[n];
        tg.SetVisible(true);
        tg.SetMargin(inkMargin(x + 28.0, y - 36.0, 0.0, 0.0));
        CMInk.Text(tg, c.Tag());
        tg.SetTintColor(col);
        let ln = this.m_wyDiaLine[n];
        ln.SetVisible(true);
        ln.SetMargin(inkMargin(x + 28.0, y - 8.0, 0.0, 0.0));
        CMInk.Text(ln, c.Label() + "  " + IntToString(RoundF(c.dist)) + " M");
        ln.SetTintColor(col);
        n += 1;
      }
    }
    while n < ArraySize(this.m_wyDia) {
      this.m_wyDia[n].SetVisible(false);
      this.m_wyDiaTag[n].SetVisible(false);
      this.m_wyDiaLine[n].SetVisible(false);
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
    this.SetT(this.WY_TAGS, IntToString(t.tagged) + " / " + IntToString(ArraySize(t.contacts)));
    let r = 0;
    while r < 4 {
      let b = this.WY_ROW0 + r * 3;
      if r < ArraySize(rows) {
        let c = rows[r];
        let col = CMInk.KindColor(c.kind, this.Acc());
        this.SetT(b, c.Tag());
        this.SetT(b + 1, c.Label());
        this.SetT(b + 2, IntToString(RoundF(c.dist)) + " M");
        this.Tint(b, this.TypeB() ? new HDRColor(0.03, 0.04, 0.05, 1.0) : col);
        this.Tint(b + 1, this.Ink());
        this.Tint(b + 2, this.Acc());
        this.m_wyRowBar[r].SetVisible(true);
        this.m_wyRowBar[r].SetTintColor(col);
      } else {
        this.SetT(b, "");
        this.SetT(b + 1, "");
        this.SetT(b + 2, "");
        this.m_wyRowBar[r].SetVisible(false);
      }
      r += 1;
    }

    let ready = 1.0 - ClampF(t.pingLeft / this.WY_PING_COOL, 0.0, 1.0);
    let pl = RoundF(ready * Cast<Float>(ArraySize(this.m_wyPing)));
    let p = 0;
    while p < ArraySize(this.m_wyPing) {
      this.m_wyPing[p].SetOpacity(p < pl ? 1.0 : 0.2);
      p += 1;
    }
    this.SetT(this.WY_PING, t.pingLeft > 0.0 ? CMText.WyvPingCool(CMKeyName.Secondary(), IntToString(CeilF(t.pingLeft))) : CMText.WyvPing(CMKeyName.Secondary()));

    let rx = this.RadarX();
    let ry = this.RadarY();
    let rr = this.WY_RADAR_R;
    let view = -t.yaw;
    n = 0;
    for c in t.contacts {
      if n < ArraySize(this.m_wyDots) {
        let dx = c.pos.X - t.pos.X;
        let dy = c.pos.Y - t.pos.Y;
        let flat = SqrtF(dx * dx + dy * dy);
        let rel = Deg2Rad(Rad2Deg(AtanF(dx, dy)) - view);
        let rad = flat / this.WY_RADAR_M * rr;
        let px = rx + SinF(rel) * rad;
        let py = ry - CosF(rel) * rad;
        if c.kind == 0 {
          this.m_wyV.SetVisible(rad <= rr);
          this.m_wyV.SetMargin(inkMargin(px - 12.0, py - 12.0, 0.0, 0.0));
        } else {
          let dot = this.m_wyDots[n];
          dot.SetVisible(rad <= rr);
          dot.SetMargin(inkMargin(px - 7.0, py - 7.0, 0.0, 0.0));
          dot.SetTintColor(CMInk.KindColor(c.kind, this.Acc()));
          dot.SetOpacity(c.tag > 0 ? 1.0 : 0.4);
          n += 1;
        }
      }
    }
    while n < ArraySize(this.m_wyDots) {
      this.m_wyDots[n].SetVisible(false);
      n += 1;
    }

    let sg = ClampF(0.1 + this.m_wySpool * 0.4 + this.m_wySpeed / 25.0 * 0.5 + this.m_wyGunHeat * 0.6, 0.0, 1.0);
    let steps = sg < 0.35 ? 1 : (sg < 0.7 ? 2 : 3);
    let k = 0;
    while k < ArraySize(this.m_wySteps) {
      this.m_wySteps[k].SetOpacity(k < steps ? 1.0 : 0.18);
      this.m_wySteps[k].SetTintColor(steps == 3 ? this.Pal().hostile : this.Amb());
      k += 1;
    }
    let seen = t.detected > 0;
    this.m_wyEyeShut.SetVisible(!seen);
    this.m_wyEyeOpen.SetVisible(seen);
    this.SetT(this.WY_DET, IntToString(t.detected));
    this.Tint(this.WY_DET, seen ? this.Pal().hostile : this.Pal().friendly);
    this.SetT(this.WY_FOV, CMText.WyvFov(FloatToStringPrec(t.fov, 1), this.m_wyFocus));
  }

  public func StartBoot() -> Void {
    this.m_wyBoot = 0.8;
    this.m_wyClock = 0.0;
    if IsDefined(this.FRoot()) {
      this.FRoot().SetOpacity(0.0);
    }
  }

  public func Boot(dt: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_wyClock += dt;
    this.m_wyBlink += dt;
    if this.m_wyBoot > 0.0 {
      this.m_wyBoot = MaxF(0.0, this.m_wyBoot - dt);
      this.FRoot().SetOpacity(1.0 - this.m_wyBoot / 0.8);
    }
    this.SetT(this.WY_REC, CMInk.Clock(this.m_wyClock));
    let ph = this.m_wyBlink - Cast<Float>(FloorF(this.m_wyBlink));
    this.m_wyRec.SetOpacity(ph < 0.5 ? 1.0 : 0.15);

    let a = Deg2Rad((this.m_wyBlink / 3.0 - Cast<Float>(FloorF(this.m_wyBlink / 3.0))) * 360.0);
    let rx = this.RadarX();
    let ry = this.RadarY();
    let rr = this.WY_RADAR_R;
    CMInk.Seg(this.m_wySweep, rx, ry, rx + SinF(a) * rr, ry - CosF(a) * rr, 3.0);
  }

  public func Hit(kill: Bool) -> Void {}
}
