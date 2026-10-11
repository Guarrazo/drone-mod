module ControllableMechs

public class CMGriffinHud extends CMBombusHud {
  private let m_grSprite: array<ref<inkImage>>;
  private let m_grClock: Float;
  private let m_grBoot: Float;
  private let m_grLockBars: array<ref<inkImage>>;
  private let m_grLockHp: ref<inkImage>;
  private let m_grLockHpBg: ref<inkImage>;
  private let m_grLockT: ref<inkText>;
  private let m_grLockD: ref<inkText>;
  private let m_grLead: ref<inkCanvas>;
  private let m_grHostBars: array<ref<inkImage>>;
  private let m_grHostD: array<ref<inkText>>;
  private let m_grLeadLine: ref<inkImage>;
  private let m_grHeatArc: array<ref<inkWidget>>;
  private let m_grSpool: ref<CMSlider>;
  private let m_grNeedle: ref<inkImage>;
  private let m_grThreat: array<ref<inkCanvas>>;
  private let m_grThreatT: array<Float>;
  private let m_grThreatA: array<Float>;
  private let m_grThreatTxt: ref<inkText>;
  private let m_grKills: Int32;
  private let m_grStreak: Int32;
  private let m_grLastKill: Float;

  private let m_grBars: array<ref<inkImage>>;
  private let m_grMarks: array<ref<inkImage>>;
  private let m_grTape: array<ref<inkImage>>;
  private let m_grTapeL: array<ref<inkText>>;
  private let m_grRockets: array<ref<inkCanvas>>;
  private let m_grRkPips: array<ref<inkImage>>;
  private let m_grTabs: array<ref<inkImage>>;
  private let m_grTabT: array<ref<inkText>>;
  private let m_grPodS: array<ref<CMSlider>>;
  private let m_grHullS: ref<CMSlider>;
  private let m_grHaz: array<ref<inkImage>>;

  private let GR_BANNER: Int32 = 0;
  private let GR_HDG: Int32 = 1;
  private let GR_NAME: Int32 = 2;
  private let GR_ROLE: Int32 = 3;
  private let GR_TIME: Int32 = 5;
  private let GR_LGUN: Int32 = 6;
  private let GR_LAMMO: Int32 = 7;
  private let GR_RGUN: Int32 = 8;
  private let GR_RAMMO: Int32 = 9;
  private let GR_SPD: Int32 = 12;
  private let GR_SPOOL: Int32 = 13;
  private let GR_ALT: Int32 = 14;
  private let GR_VS: Int32 = 15;
  private let GR_ATT: Int32 = 16;
  private let GR_HULL: Int32 = 20;
  private let GR_PODS: Int32 = 21;
  private let GR_WARN: Int32 = 22;
  private let GR_RNG: Int32 = 23;
  private let GR_KEYS: Int32 = 24;
  private let GR_KILLS: Int32 = 25;

  private let GR_GAUGE_R: Float = 87.0;
  private let GR_HEAT_N: Int32 = 11;
  private let GR_TAPE_PX: Float = 13.0;

  private func GrR() -> Float = this.FW() - 40.0

  private func Hot() -> HDRColor = this.Pal().hostile

  private func GaugeX() -> Float = 180.0
  private func GaugeY() -> Float = 1790.0

  protected func BuildFeed(root: ref<inkCanvas>) -> Void {
    CMKit.Vignette(root, this.FW(), 2160.0, 160.0, 0.3);
  }

  protected func PlatesB() -> Void {
    let W = this.FW();
    let cx = W * 0.5;
    let cy = 1080.0;
    this.BFrame(this.Face(), W);
    this.BPlate(this.Rg(0, 0), 46.0, 30.0, 700.0, 160.0, false);
    this.BHazard(this.Rg(0, 0), 56.0, 44.0, 22.0, 90.0);
    this.BPlate(this.Rg(1, 0), cx - 290.0, 30.0, 580.0, 62.0, true);
    let c = 0;
    while c < 3 {
      let ox = 210.0 + Cast<Float>(c) * 30.0;
      CMKit.Img(this.Rg(1, 0), n"chev_r", cx + ox, 42.0, 24.0, 30.0, this.Pal().warn, 0.95);
      let l = CMKit.Img(this.Rg(1, 0), n"chev_r", cx - ox - 24.0, 42.0, 24.0, 30.0, this.Pal().warn, 0.95);
      l.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
      c += 1;
    }
    this.BPlate(this.Rg(1, 0), cx - 100.0, 152.0, 200.0, 46.0, false);
    this.BPlate(this.Rg(2, 0), W - 490.0, 30.0, 440.0, 120.0, true);
    this.BPlate(this.Rg(0, 1), cx - 790.0, cy - 40.0, 220.0, 120.0, false);
    this.BPlate(this.Rg(2, 1), cx + 572.0, cy - 40.0, 220.0, 92.0, false);
    this.BPlate(this.Rg(1, 1), cx - 120.0, cy + 160.0, 240.0, 52.0, false);
    this.BPlate(this.Rg(0, 2), 50.0, 1640.0, 620.0, 186.0, true);
    this.BPlate(this.Rg(0, 2), 50.0, 1826.0, 700.0, 150.0, true);
    this.BPlate(this.Rg(2, 2), W - 500.0, 1620.0, 460.0, 380.0, false);
  }

  protected func BuildOsd(root: ref<inkCanvas>) -> Void {
    let x1 = this.GrR();
    let cx = this.FW() * 0.5;
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

    this.Osd(tc, cx, 44.0, 30, 1);
    this.Osd(tc, cx, 160.0, 22, 1);
    this.Osd(tl, 93.0, 52.0, 34, 0);
    this.Osd(tl, 93.0, 100.0, 24, 0);
    this.Osd(tr, x1, 0.0, 10, 2);
    this.Osd(tr, x1 - 53.0, 104.0, 22, 2);
    this.Osd(mc, cx - 113.0, cy + 66.0, 22, 2);
    this.Osd(mc, cx - 113.0, cy - 30.0, 24, 2);
    this.Osd(mc, cx + 113.0, cy + 66.0, 22, 0);
    this.Osd(mc, cx + 113.0, cy - 30.0, 24, 0);
    this.Osd(mc, cx, 0.0, 10, 1);
    this.Osd(mc, cx, 0.0, 10, 1);
    this.Osd(ml, cx - 591.0, cy - 30.0, 40, 2);
    this.Osd(ml, cx - 591.0, cy + 20.0, 22, 2);
    this.Osd(mr, cx + 591.0, cy - 30.0, 40, 0);
    this.Osd(mr, cx + 591.0, cy + 20.0, 22, 0);
    this.Osd(bl, 93.0, 1660.0, 20, 0);
    this.Osd(bl, 93.0, 0.0, 10, 0);
    this.Osd(bl, 93.0, 0.0, 10, 0);
    this.Osd(bl, 93.0, 0.0, 10, 0);
    this.Osd(br, x1 - 372.0, 1969.0, 20, 0);
    this.Osd(br, x1 - 156.0, 1969.0, 20, 2);
    this.Osd(mc, cx, 820.0, 44, 1);
    this.Osd(mc, cx, cy + 172.0, 24, 1);
    this.Osd(bl, 93.0, 1932.0, 20, 0);
    this.Osd(tl, 93.0 + 10.0 * 31.0 + 8.0, 140.0, 24, 0);
    for i in [this.GR_ROLE, this.GR_TIME, this.GR_HDG, this.GR_LGUN, this.GR_RGUN, this.GR_SPOOL, this.GR_VS, this.GR_ATT, this.GR_HULL, this.GR_RNG, this.GR_KEYS, this.GR_KILLS] {
      this.Tint(i, this.Acc());
    }
    this.Tint(this.GR_WARN, this.Hot());
    this.Tint(this.GR_LAMMO, this.Hot());
    this.Tint(this.GR_RAMMO, this.Hot());
    this.SetT(this.GR_LGUN, "L");
    this.SetT(this.GR_RGUN, "R");
    this.SetT(this.GR_SPOOL, "KMH");
    this.SetT(this.GR_HULL, CMText.WyvAirframe());
    this.SetT(this.GR_KEYS, CMText.GrfKeys(CMKeyName.Fire(), CMKeyName.FireMode(), CMKeyName.Secondary(), CMKeyName.Aim(), CMKeyName.Sensor()));

    let km = 0;
    while km < 10 {
      ArrayPush(this.m_grMarks, CMKit.Nine(tl, n"slant_h", inkMargin(0.0, 0.0, 8.0, 0.0), 93.0 + Cast<Float>(km) * 31.0, 146.0, 24.0, 18.0, this.Acc(), 0.18));
      km += 1;
    }

    let b = 0;
    while b < 5 {
      let h = 10.0 + Cast<Float>(b) * 8.0;
      ArrayPush(this.m_grBars, CMKit.Img(tr, n"pill_v", x1 - 133.0 + Cast<Float>(b) * 15.0, 92.0 - h, 9.0, h, this.Acc(), 1.0));
      b += 1;
    }

    let tk = 0;
    while tk < 13 {
      ArrayPush(this.m_grTape, CMKit.Img(tc, n"pill_v", cx, 132.0, 2.0, 14.0, this.Acc(), 0.85));
      tk += 1;
    }
    let tlb = 0;
    while tlb < 7 {
      let l = CMPilotHud.Label(tc, inkEAnchor.TopLeft, cx, 98.0, "", 20, n"Medium", this.Acc());
      l.SetAnchorPoint(Vector2(0.5, 0.0));
      ArrayPush(this.m_grTapeL, l);
      tlb += 1;
    }
    CMKit.Img(tc, n"tri", cx - 7.0, 148.0, 14.0, 12.0, this.Acc(), 1.0);

    CMInk.Circle(mc, cx, cy, 51.0, this.Acc(), 1.0);
    CMKit.Disc(mc, cx, cy, 5.0, this.Acc(), 1.0);

    let track = CMInk.Ring(mc, cx, cy, 92.0, 36, 8.0, this.Acc(), 0.22);
    let lit = CMInk.Ring(mc, cx, cy, 92.0, 36, 8.0, this.Pal().warn, 1.0);
    let j = 0;
    while j < 36 {
      let a = Cast<Float>(j) * 10.0;
      track[j].SetVisible((a >= 220.0 && a <= 320.0) || (a >= 40.0 && a <= 140.0));
      lit[j].SetVisible(false);
      j += 1;
    }
    for k in [22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4] {
      ArrayPush(this.m_grHeatArc, lit[k]);
    }

    let rk = 0;
    while rk < 2 {
      let rc = new inkCanvas();
      rc.SetMargin(inkMargin(cx - 28.0 + Cast<Float>(rk) * 40.0, cy + 112.0, 0.0, 0.0));
      rc.SetSize(Vector2(16.0, 46.0));
      rc.Reparent(mc);
      CMKit.Img(rc, n"tri", 0.0, 0.0, 16.0, 12.0, new HDRColor(1.0, 1.0, 1.0, 1.0), 1.0);
      CMKit.Fill(rc, 2.0, 12.0, 12.0, 34.0, new HDRColor(1.0, 1.0, 1.0, 1.0), 1.0);
      rc.SetTintColor(this.Acc());
      ArrayPush(this.m_grRockets, rc);
      rk += 1;
    }

    this.m_grSpool = CMSlider.Make(ml, cx - 771.0, cy + 66.0, 180.0, 6.0, false, this.Acc());

    this.m_grLockBars = CMKit.Corners(root, this.Hot(), 1.0, false);

    let hb = 0;
    while hb < 12 {
      for bb in CMKit.Corners(root, this.Hot(), 0.85, false) {
        bb.SetVisible(false);
        ArrayPush(this.m_grHostBars, bb);
      }
      hb += 1;
    }
    hb = 0;
    while hb < 12 {
      let d = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, "", 22, n"Medium", this.Hot());
      d.SetAnchorPoint(Vector2(0.5, 0.0));
      d.SetVisible(false);
      ArrayPush(this.m_grHostD, d);
      hb += 1;
    }
    this.m_grLockHpBg = CMKit.Pill(root, 0.0, 0.0, 10.0, 10.0, this.Hot(), 0.25);
    this.m_grLockHp = CMKit.Pill(root, 0.0, 0.0, 10.0, 10.0, this.Hot(), 0.95);
    this.m_grLockT = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, "", 26, n"Semi-Bold", this.Hot());
    this.m_grLockT.SetAnchorPoint(Vector2(0.5, 1.0));
    this.m_grLockD = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, "", 24, n"Medium", this.Hot());
    this.m_grLockD.SetAnchorPoint(Vector2(0.5, 0.0));
    this.m_grLeadLine = CMKit.Stroke(root, this.Pal().warn, 0.6);
    let lead = new inkCanvas();
    lead.SetSize(Vector2(40.0, 40.0));
    lead.Reparent(root);
    CMInk.Circle(lead, 20.0, 20.0, 18.0, this.Pal().warn, 1.0);
    this.m_grLead = lead;
    this.GrLockShow(false);

    let c = 0;
    while c < 4 {
      let ch = CMInk.Chevron(root, 70.0, 7.0, this.Hot());
      ch.SetVisible(false);
      ArrayPush(this.m_grThreat, ch);
      ArrayPush(this.m_grThreatT, 0.0);
      ArrayPush(this.m_grThreatA, 0.0);
      c += 1;
    }
    this.m_grThreatTxt = CMPilotHud.Label(root, inkEAnchor.TopLeft, 0.0, 0.0, CMText.GrfTakingFire(), 24, n"Semi-Bold", this.Hot());
    this.m_grThreatTxt.SetAnchorPoint(Vector2(0.5, 0.0));
    this.m_grThreatTxt.SetVisible(false);

    let gx = this.GaugeX();
    let gy = this.GaugeY();
    let gr = CMInk.Ring(bl, gx, gy, this.GR_GAUGE_R, 48, 3.0, this.Acc(), 0.6);
    let q = 0;
    while q < 48 {
      let a = Cast<Float>(q) * 7.5;
      gr[q].SetVisible(a >= 270.0);
      q += 1;
    }
    this.m_grNeedle = CMKit.Stroke(bl, this.Ink(), 1.0);

    let tabs = [CMText.GrfHover(), CMText.GrfCruise(), "", ""];
    let tx = [303.0, 459.0, 93.0, 420.0];
    let ty = [1737.0, 1737.0, 1846.0, 1846.0];
    let tw = [146.0, 156.0, 316.0, 200.0];

    if this.TypeB() {
      tx = [303.0, 459.0, 83.0, 83.0];
      ty = [1737.0, 1737.0, 1836.0, 1882.0];
      tw = [146.0, 156.0, 620.0, 620.0];
    }
    let ti = 0;
    while ti < 4 {
      CMKit.Nine(bl, n"slant_h", inkMargin(0.0, 0.0, 12.0, 0.0), tx[ti], ty[ti], tw[ti], 44.0, this.Acc(), 0.16);
      ArrayPush(this.m_grTabs, CMKit.Nine(bl, n"slant_h", inkMargin(0.0, 0.0, 12.0, 0.0), tx[ti], ty[ti], tw[ti], 44.0, this.Acc(), 0.92));
      ArrayPush(this.m_grTabT, CMPilotHud.Label(bl, inkEAnchor.TopLeft, tx[ti] + 18.0, ty[ti] + 6.0, tabs[ti], 26, n"Semi-Bold", this.Acc()));
      if this.TypeB() && ti >= 2 {
        let hz = CMKit.Img(bl, n"hazard", tx[ti] + tw[ti] - 60.0, ty[ti] + 4.0, 50.0, 36.0, new HDRColor(0.02, 0.03, 0.02, 1.0), 0.85);
        ArrayPush(this.m_grHaz, hz);
      }
      ti += 1;
    }

    let rp = 0;
    while rp < 2 {
      ArrayPush(this.m_grRkPips, this.TypeB() ? CMKit.Fill(bl, 560.0 + Cast<Float>(rp) * 22.0, 1890.0, 14.0, 26.0, this.Ink(), 1.0) : CMKit.Disc(bl, 650.0 + Cast<Float>(rp) * 24.0, 1868.0, 8.0, this.Acc(), 1.0));
      rp += 1;
    }
  }

  protected func BuildSprite(root: ref<inkCanvas>) -> Void {
    let br = this.Rg(2, 2);
    let x1 = this.GrR();
    let k = 216.0 / 311.0;
    let bx = x1 - 372.0;
    let by = 1645.0;
    let box = new inkCanvas();
    box.SetMargin(inkMargin(bx, by, 0.0, 0.0));
    box.SetSize(Vector2(311.0 * k, 360.0 * k));
    box.Reparent(br);
    this.GrPart(box, k, n"griffin_body", 31.0, 46.0, 250.0, 309.0);
    this.GrPart(box, k, n"griffin_wing_l", 6.0, 5.0, 79.0, 246.0);
    this.GrPart(box, k, n"griffin_wing_r", 227.0, 5.0, 80.0, 246.0);
    ArrayPush(this.m_grPodS, CMSlider.Make(br, bx - 36.0, by + 52.0, 13.0, 180.0, true, this.Acc()));
    ArrayPush(this.m_grPodS, CMSlider.Make(br, bx + 216.0 + 22.0, by + 52.0, 13.0, 180.0, true, this.Acc()));
    let l = CMPilotHud.Label(br, inkEAnchor.TopLeft, bx - 30.0, by + 240.0, "L", 20, n"Medium", this.Acc());
    l.SetAnchorPoint(Vector2(0.5, 0.0));
    let r = CMPilotHud.Label(br, inkEAnchor.TopLeft, bx + 244.0, by + 240.0, "R", 20, n"Medium", this.Acc());
    r.SetAnchorPoint(Vector2(0.5, 0.0));
    this.m_grHullS = CMSlider.Make(br, bx, 1954.0, 216.0, 6.0, false, this.Acc());
  }

  private func GrPartCol(hp: Float, crit: Float) -> HDRColor = hp <= crit ? this.Pal().hostile : (hp < 0.6 ? this.Pal().warn : this.Acc())
  private func GrPodText(hp: Float) -> String = hp <= 0.0 ? CMText.GrfLost() : (hp < 0.6 ? IntToString(RoundF(hp * 100.0)) + "%" : "")

  private func GrPart(box: ref<inkCanvas>, k: Float, name: CName, x: Float, y: Float, w: Float, h: Float) -> Void {
    let img = new inkImage();
    img.SetAtlasResource(CMDroneHud.Atlas());
    img.SetTexturePart(name);
    img.SetMargin(inkMargin(x * k, y * k, 0.0, 0.0));
    img.SetSize(Vector2(w * k, h * k));
    img.SetTintColor(this.Acc());
    img.SetInteractive(false);
    img.Reparent(box);
    ArrayPush(this.m_grSprite, img);
  }

  private func GrLockShow(on: Bool) -> Void {
    for b in this.m_grLockBars {
      b.SetVisible(on);
    }
    this.m_grLockHp.SetVisible(on);
    this.m_grLockHpBg.SetVisible(on);
    this.m_grLockT.SetVisible(on);
    this.m_grLockD.SetVisible(on);
    if !on {
      this.m_grLead.SetVisible(false);
      this.m_grLeadLine.SetVisible(false);
    }
  }

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.SetT(this.GR_NAME, CMText.GrfName(s.title));
    this.SetT(this.GR_ROLE, this.m_grStreak > 1 ? CMText.GrfRoleStreak(IntToString(this.m_grStreak)) : CMText.GrfRole());

    let km = 0;
    while km < ArraySize(this.m_grMarks) {
      this.m_grMarks[km].SetOpacity(km < this.m_grKills ? 1.0 : 0.18);
      km += 1;
    }
    this.SetT(this.GR_KILLS, (this.m_grKills < 10 ? "0" : "") + IntToString(this.m_grKills));
    let sig = ClampF(s.signal, 0.0, 1.0);
    let b = 0;
    while b < ArraySize(this.m_grBars) {
      this.m_grBars[b].SetOpacity(sig * 5.0 > Cast<Float>(b) + 0.5 ? 1.0 : 0.2);
      this.m_grBars[b].SetTintColor(sig < 0.35 ? this.Hot() : this.Acc());
      b += 1;
    }
    this.SetT(this.GR_RNG, s.range > 0.0 && s.range < 2000.0 ? IntToString(RoundF(s.range)) + " M" : "--- M");
    let spool = ClampF(s.spool, 0.0, 1.0);
    this.m_grSpool.Set(spool, this.Acc());
    let warn = s.warning;
    if sig < 0.35 {
      warn = CMText.BmbLinkWeak();
    } else {
      if s.integrity < 0.3 {
        warn = CMText.BmbHullCritical();
      }
    }
    this.SetT(this.GR_WARN, warn);
    let hull = ClampF(s.integrity, 0.0, 1.0);
    this.m_grHullS.Set(hull, this.GrPartCol(hull, 0.3));

    let pl = ArraySize(s.droneParts) >= 3 ? s.droneParts[1] : 1.0;
    let pr = ArraySize(s.droneParts) >= 3 ? s.droneParts[2] : 1.0;
    if ArraySize(this.m_grPodS) >= 2 {
      this.m_grPodS[0].Set(pl > 0.0 ? 0.35 + 0.65 * pl : 0.0, this.GrPartCol(pl, 0.0));
      this.m_grPodS[1].Set(pr > 0.0 ? 0.35 + 0.65 * pr : 0.0, this.GrPartCol(pr, 0.0));
    }
    let worst = pl < pr ? CMText.GrfPod("L", this.GrPodText(pl)) : CMText.GrfPod("R", this.GrPodText(pr));
    this.SetT(this.GR_PODS, MinF(pl, pr) < 0.6 ? worst : "");
    this.Tint(this.GR_PODS, MinF(pl, pr) <= 0.0 ? this.Hot() : this.Pal().warn);
    let c = this.GrPartCol(hull, 0.3);

    let k = 0;
    for img in this.m_grSprite {
      img.SetTintColor(k == 1 ? this.GrPartCol(pl, 0.0) : (k == 2 ? this.GrPartCol(pr, 0.0) : c));
      k += 1;
    }

    let heat = ClampF(s.secHeat, 0.0, 1.0);
    let n = 0;
    while n < ArraySize(this.m_grHeatArc) {
      let lit = heat * Cast<Float>(this.GR_HEAT_N) > Cast<Float>(n % this.GR_HEAT_N) + 0.05;
      this.m_grHeatArc[n].SetVisible(lit);
      this.m_grHeatArc[n].SetTintColor(heat >= 0.99 ? this.Hot() : this.Pal().warn);
      n += 1;
    }
    let gs = ArraySize(s.wStat) > 0 ? s.wStat[0] : "RDY";
    let over = Equals(gs, "OVERHEAT");
    this.SetT(this.GR_LAMMO, over ? CMText.GrfOvht() : "");
    this.SetT(this.GR_RAMMO, over ? CMText.GrfOvht() : "");

    let rk = 0;
    while rk < ArraySize(this.m_grRockets) {
      this.m_grRockets[rk].SetOpacity(rk < s.rkLeft ? 1.0 : 0.22);
      this.m_grRkPips[rk].SetOpacity(rk < s.rkLeft ? 1.0 : 0.22);
      rk += 1;
    }
    let rkStat = ArraySize(s.wStat) > 1 ? s.wStat[1] : "";
    let dark = new HDRColor(0.01, 0.06, 0.03, 1.0);
    if ArraySize(this.m_grTabs) >= 4 {
      CMInk.Text(this.m_grTabT[2], ArraySize(s.wSub) > 0 ? s.wSub[0] : "LMG 7.62 x2");
      CMInk.Text(this.m_grTabT[3], StrBeginsWith(rkStat, "RLD") ? CMDroneHud.StatText(rkStat) : CMText.GrfRktLsr());
      let w = 0;
      while w < 2 {
        let on = s.weapon == w;
        this.m_grTabs[2 + w].SetVisible(on);
        if w < ArraySize(this.m_grHaz) {
          this.m_grHaz[w].SetVisible(on);
        }
        this.m_grTabT[2 + w].SetTintColor(on ? dark : (w == 1 && StrBeginsWith(rkStat, "RLD") ? this.Pal().warn : this.Acc()));
        w += 1;
      }
      this.m_grTabs[2].SetTintColor(over ? this.Hot() : this.Acc());
    }
  }

  public func SetFlight(pitch: Float, roll: Float, speed: Float, alt: Float, vs: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.SetT(this.GR_SPD, IntToString(RoundF(speed * 3.6)));
    this.SetT(this.GR_ALT, alt >= 0.0 ? FloatToStringPrec(alt, 1) + " M" : "--- M");
    this.SetT(this.GR_VS, CMText.OctBVs((vs >= 0.0 ? "+" : "") + FloatToStringPrec(vs, 1)));

    let nose = ClampF(-pitch, 0.0, 90.0);
    let a = Deg2Rad(270.0 + nose);
    let gx = this.GaugeX();
    let gy = this.GaugeY();
    CMInk.Seg(this.m_grNeedle, gx, gy, gx + SinF(a) * this.GR_GAUGE_R, gy - CosF(a) * this.GR_GAUGE_R, 4.0);
    this.SetT(this.GR_ATT, CMText.GrfAtt(CMDroneHud.Signed(pitch), CMDroneHud.Signed(roll)));

    if ArraySize(this.m_grTabs) >= 2 {
      let hover = speed < 3.0;
      let dark = new HDRColor(0.01, 0.06, 0.03, 1.0);
      this.m_grTabs[0].SetVisible(hover);
      this.m_grTabs[1].SetVisible(!hover);
      this.m_grTabT[0].SetTintColor(hover ? dark : this.Acc());
      this.m_grTabT[1].SetTintColor(hover ? this.Acc() : dark);
    }
  }

  private func GrTape(h: Float) -> Void {
    let cx = this.FW() * 0.5;
    let base = FloorF(h / 5.0) * 5;
    let i = 0;
    while i < ArraySize(this.m_grTape) {
      let deg = base + (i - 6) * 5;
      let x = cx + (Cast<Float>(deg) - h) * this.GR_TAPE_PX;
      let tk = this.m_grTape[i];
      let long = deg % 10 == 0;
      tk.SetVisible(AbsF(x - cx) <= 300.0);
      tk.SetMargin(inkMargin(x - 1.0, long ? 128.0 : 134.0, 0.0, 0.0));
      tk.SetSize(Vector2(2.0, long ? 18.0 : 12.0));
      i += 1;
    }
    let lbase = FloorF(h / 10.0) * 10;
    i = 0;
    while i < ArraySize(this.m_grTapeL) {
      let deg = lbase + (i - 3) * 10;
      let x = cx + (Cast<Float>(deg) - h) * this.GR_TAPE_PX;
      let l = this.m_grTapeL[i];
      l.SetVisible(AbsF(x - cx) <= 290.0);
      l.SetMargin(inkMargin(x, 98.0, 0.0, 0.0));
      let d = (deg % 360 + 360) % 360;
      let s = d / 10;
      CMInk.Text(l, d == 0 ? "N" : (d == 90 ? "E" : (d == 180 ? "S" : (d == 270 ? "W" : (s < 10 ? "0" : "") + IntToString(s)))));
      i += 1;
    }
    let hi = RoundF(h) % 360;
    this.SetT(this.GR_HDG, CMPilotHud.Pad3(hi) + "  " + CMPilotHud.Cardinal(hi));
  }

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    let cx = this.FW() * 0.5;
    let cy = 1080.0;

    let hot = t.hostiles > 0;
    this.Tint(this.GR_BANNER, hot ? this.Hot() : this.Pal().warn);

    this.SetT(this.GR_BANNER, this.TypeB() ? (hot ? CMText.GrfWeaponsFree() : CMText.GrfWeaponsHold()) : "<<   " + (hot ? CMText.GrfFree() : CMText.GrfHold()) + "   >>");

    let hdg = -t.yaw;
    while hdg < 0.0 {
      hdg += 360.0;
    }
    while hdg >= 360.0 {
      hdg -= 360.0;
    }
    this.GrTape(hdg);
    this.GrHostiles(t, cx, cy);
    let c = t.lock;
    if !IsDefined(c) || !c.OnScreen() {
      this.GrLockShow(false);
      return;
    }
    this.GrLockShow(true);
    let col = c.kind == 2 ? this.Hot() : CMInk.KindColor(c.kind, this.Acc());
    let scale = 1080.0 / TanF(Deg2Rad(MaxF(1.0, t.fov) * 0.5));
    let hh = ClampF(1.9 / MaxF(1.0, c.dist) * scale, 70.0, 520.0);
    let hw = MaxF(60.0, hh * 0.5);
    let x = cx + c.scr.X - hw * 0.5;
    let y = cy + c.scr.Y - hh * 0.5;
    let L = MinF(34.0, hw * 0.4);

    CMKit.PlaceCorners(this.m_grLockBars, 0, x, y, hw, hh, L);
    CMKit.ShowCorners(this.m_grLockBars, 0, true, col);
    this.m_grLockT.SetMargin(inkMargin(x + hw * 0.5, y - 10.0, 0.0, 0.0));
    CMInk.Text(this.m_grLockT, c.kind == 2 ? CMText.GrfLock(c.Label()) : CMText.GrfTrack(c.Label()));
    this.m_grLockT.SetTintColor(col);
    this.m_grLockHpBg.SetMargin(inkMargin(x, y + hh + 12.0, 0.0, 0.0));
    this.m_grLockHpBg.SetSize(Vector2(hw, 10.0));
    this.m_grLockHpBg.SetTintColor(col);
    this.m_grLockHp.SetMargin(inkMargin(x, y + hh + 12.0, 0.0, 0.0));

    this.m_grLockHp.SetSize(Vector2(MaxF(20.0, hw * ClampF(c.hp, 0.0, 1.0)), 10.0));
    this.m_grLockHp.SetVisible(c.hp > 0.01);
    this.m_grLockHp.SetTintColor(col);
    this.m_grLockD.SetMargin(inkMargin(x + hw * 0.5, y + hh + 30.0, 0.0, 0.0));
    CMInk.Text(this.m_grLockD, IntToString(RoundF(c.dist)) + " M");
    this.m_grLockD.SetTintColor(col);

    if t.leadOn {
      let lx = cx + t.lead.X;
      let ly = cy + t.lead.Y;
      this.m_grLead.SetVisible(true);
      this.m_grLead.SetMargin(inkMargin(lx - 20.0, ly - 20.0, 0.0, 0.0));
      this.m_grLeadLine.SetVisible(true);
      CMInk.Seg(this.m_grLeadLine, cx + c.scr.X, cy + c.scr.Y, lx, ly, 2.0);
    } else {
      this.m_grLead.SetVisible(false);
      this.m_grLeadLine.SetVisible(false);
    }
  }

  private func GrHostiles(t: ref<CMDroneTrack>, cx: Float, cy: Float) -> Void {
    let scale = 1080.0 / TanF(Deg2Rad(MaxF(1.0, t.fov) * 0.5));
    let n = 0;
    for c in t.contacts {
      let isLock = IsDefined(t.lock) && Equals(c.id, t.lock.id);
      if n < ArraySize(this.m_grHostD) && c.kind == 2 && !isLock && c.OnScreen() {
        let hh = ClampF(1.9 / MaxF(1.0, c.dist) * scale, 50.0, 420.0);
        let hw = MaxF(44.0, hh * 0.5);
        let x = cx + c.scr.X - hw * 0.5;
        let y = cy + c.scr.Y - hh * 0.5;
        let L = MinF(26.0, hw * 0.35);
        CMKit.PlaceCorners(this.m_grHostBars, n * 4, x, y, hw, hh, L);
        CMKit.ShowCorners(this.m_grHostBars, n * 4, true, this.Hot());
        let d = this.m_grHostD[n];
        d.SetVisible(true);
        d.SetMargin(inkMargin(x + hw * 0.5, y + hh + 6.0, 0.0, 0.0));
        CMInk.Text(d, IntToString(RoundF(c.dist)) + " M");
        n += 1;
      }
    }
    while n < ArraySize(this.m_grHostD) {
      CMKit.ShowCorners(this.m_grHostBars, n * 4, false, this.Hot());
      this.m_grHostD[n].SetVisible(false);
      n += 1;
    }
  }

  public func HitFrom(off: Float) -> Void {
    let best = 0;
    let i = 1;
    while i < ArraySize(this.m_grThreatT) {
      if this.m_grThreatT[i] < this.m_grThreatT[best] {
        best = i;
      }
      i += 1;
    }
    if ArraySize(this.m_grThreatT) > 0 {
      this.m_grThreatT[best] = 2.0;
      this.m_grThreatA[best] = -off;
    }
  }

  public func StartBoot() -> Void {
    this.m_grBoot = 0.8;
    this.m_grClock = 0.0;
    if IsDefined(this.FRoot()) {
      this.FRoot().SetOpacity(0.0);
    }
  }

  public func Boot(dt: Float) -> Void {
    if !IsDefined(this.FRoot()) {
      return;
    }
    this.m_grClock += dt;
    if this.m_grBoot > 0.0 {
      this.m_grBoot = MaxF(0.0, this.m_grBoot - dt);
      this.FRoot().SetOpacity(1.0 - this.m_grBoot / 0.8);
    }
    this.SetT(this.GR_TIME, "T+ " + CMInk.Clock(this.m_grClock));
    if this.m_grStreak > 0 && this.m_grClock - this.m_grLastKill > 10.0 {
      this.m_grStreak = 0;
    }

    let cx = this.FW() * 0.5;
    let any = false;
    let txtX = cx;
    let txtY = 1080.0;
    let i = 0;
    while i < ArraySize(this.m_grThreat) {
      let ch = this.m_grThreat[i];
      if this.m_grThreatT[i] > 0.0 {
        this.m_grThreatT[i] -= dt;
        let a = Deg2Rad(this.m_grThreatA[i]);
        let px = cx + SinF(a) * 780.0;
        let py = 1080.0 - CosF(a) * 780.0;
        ch.SetVisible(true);
        ch.SetMargin(inkMargin(px - 40.0, py - 40.0, 0.0, 0.0));
        ch.SetRotation(this.m_grThreatA[i]);
        ch.SetOpacity(ClampF(this.m_grThreatT[i], 0.0, 1.0));
        any = true;
        txtX = px;
        txtY = py + 50.0;
      } else {
        ch.SetVisible(false);
      }
      i += 1;
    }
    this.m_grThreatTxt.SetVisible(any);
    this.m_grThreatTxt.SetMargin(inkMargin(txtX, txtY, 0.0, 0.0));
  }

  public func Hit(kill: Bool) -> Void {
    if kill {
      this.m_grKills += 1;
      this.m_grStreak = this.m_grClock - this.m_grLastKill <= 10.0 ? this.m_grStreak + 1 : 1;
      this.m_grLastKill = this.m_grClock;
    }
  }
}
