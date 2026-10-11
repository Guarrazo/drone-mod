module ControllableMechs

import Codeware.UI.ScreenHelper
import ControllableMechs.Control.*

public abstract class CMMechPalette {
  public static func Primary() -> HDRColor = new HDRColor(1.02, 0.98, 0.86, 1.0)
  public static func Accent() -> HDRColor = new HDRColor(1.18, 0.46, 0.10, 1.0)
  public static func Dim() -> HDRColor = new HDRColor(0.58, 0.56, 0.48, 1.0)
  public static func Hostile() -> HDRColor = new HDRColor(1.22, 0.20, 0.18, 1.0)
  public static func Friendly() -> HDRColor = new HDRColor(0.45, 1.05, 0.55, 1.0)
  public static func Broken() -> HDRColor = new HDRColor(0.36, 0.36, 0.34, 1.0)
  public static func Glass() -> HDRColor = new HDRColor(0.012, 0.012, 0.010, 1.0)
  public static func GlassOp() -> Float = 0.74
  public static func Alarm() -> HDRColor = new HDRColor(0.22, 0.025, 0.02, 1.0)
}

public class CMHudPal {
  public let primary: HDRColor;
  public let accent: HDRColor;
  public let warn: HDRColor;
  public let dim: HDRColor;
  public let hostile: HDRColor;
  public let friendly: HDRColor;
  public let broken: HDRColor;
  public let glass: HDRColor;
  public let glassOp: Float;
  public let alarm: HDRColor;

  public static func Of(style: Int32) -> ref<CMHudPal> {
    let p = new CMHudPal();
    if style == 0 {
      p.primary = CMMechPalette.Primary();
      p.accent = CMMechPalette.Accent();
      p.warn = CMMechPalette.Accent();
      p.dim = CMMechPalette.Dim();
      p.hostile = CMMechPalette.Hostile();
      p.friendly = CMMechPalette.Friendly();
      p.broken = CMMechPalette.Broken();
      p.glass = CMMechPalette.Glass();
      p.glassOp = CMMechPalette.GlassOp();
      p.alarm = CMMechPalette.Alarm();
      return p;
    }
    p.primary = new HDRColor(0.92, 0.98, 1.02, 1.0);
    p.accent = new HDRColor(0.40, 0.88, 1.12, 1.0);
    p.warn = new HDRColor(1.15, 0.70, 0.27, 1.0);
    p.dim = style == 2 ? new HDRColor(0.56, 0.62, 0.65, 1.0) : new HDRColor(0.52, 0.59, 0.63, 1.0);
    p.hostile = new HDRColor(1.16, 0.26, 0.22, 1.0);
    p.friendly = new HDRColor(0.45, 1.05, 0.55, 1.0);
    p.broken = new HDRColor(0.36, 0.38, 0.40, 1.0);
    p.glass = new HDRColor(0.010, 0.014, 0.018, 1.0);
    p.glassOp = 0.6;
    p.alarm = new HDRColor(0.22, 0.03, 0.02, 1.0);
    return p;
  }

  public static func StyleName(style: Int32) -> String {
    switch style {
      case 1: return CMText.MhudTypeA();
      case 2: return CMText.MhudTypeA();
    }
    return CMText.MhudTypeB();
  }
}

public class CMMtMeter {
  public let track: ref<inkImage>;
  public let fill: ref<inkImage>;
  public let segs: array<ref<inkWidget>>;
  public let w: Float;
  public let h: Float;
  public let frac: Float;

  public static func Make(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, c: HDRColor, pal: ref<CMHudPal>, opt thin: Bool) -> ref<CMMtMeter> {
    let m = new CMMtMeter();
    m.w = w;
    m.h = h;
    m.frac = -1.0;
    if thin {
      m.track = CMKit.Ln(root, x, y, w, h, pal.dim, 0.35);
      m.fill = CMKit.Ln(root, x, y, w, h, c, 0.95);
      m.Set(1.0, c);
      return m;
    }
    m.track = CMKit.Nine(root, n"slant_h", inkMargin(0.0, 0.0, 12.0, 0.0), x, y, w, h, pal.glass, 0.75);
    m.fill = CMKit.Nine(root, n"slant_h", inkMargin(0.0, 0.0, 12.0, 0.0), x, y, w, h, c, 0.95);

    let i = 1;
    while i < 4 {
      CMPilotHud.Bar(root, x + w * Cast<Float>(i) / 4.0 - 2.0, y - 14.0, 4.0, 10.0, pal.dim, 0.9);
      i += 1;
    }
    CMPilotHud.Bar(root, x, y - 6.0, w, 2.0, pal.dim, 0.6);
    m.Set(1.0, c);
    return m;
  }

  public static func MakeArc(root: ref<inkCanvas>, cx: Float, cy: Float, r: Float, a0: Float, a1: Float, n: Int32, c: HDRColor, pal: ref<CMHudPal>) -> ref<CMMtMeter> {
    let m = new CMMtMeter();
    m.frac = -1.0;
    let i = 0;
    while i < n {
      let p = Deg2Rad(a0 + (a1 - a0) * Cast<Float>(i) / Cast<Float>(n));
      let q = Deg2Rad(a0 + (a1 - a0) * Cast<Float>(i + 1) / Cast<Float>(n));
      CMInk.Line(root, cx + SinF(p) * r, cy - CosF(p) * r, cx + SinF(q) * r, cy - CosF(q) * r, 3.0, pal.dim, 0.5);
      i += 1;
    }
    i = 0;
    while i < n {
      let p = Deg2Rad(a0 + (a1 - a0) * Cast<Float>(i) / Cast<Float>(n));
      let q = Deg2Rad(a0 + (a1 - a0) * Cast<Float>(i + 1) / Cast<Float>(n));
      ArrayPush(m.segs, CMInk.Line(root, cx + SinF(p) * r, cy - CosF(p) * r, cx + SinF(q) * r, cy - CosF(q) * r, 8.0, c, 0.95));
      i += 1;
    }
    m.Set(0.0, c);
    return m;
  }

  public let col: HDRColor;
  public let colSet: Bool;

  public func Set(f: Float, c: HDRColor) -> Void {
    let v = ClampF(f, 0.0, 1.0);
    let same = this.colSet && this.col.Red == c.Red && this.col.Green == c.Green && this.col.Blue == c.Blue;
    if same && AbsF(v - this.frac) < 0.002 {
      return;
    }
    this.col = c;
    this.colSet = true;
    if ArraySize(this.segs) > 0 {
      let lit = RoundF(v * Cast<Float>(ArraySize(this.segs)));
      let i = 0;
      while i < ArraySize(this.segs) {
        this.segs[i].SetVisible(i < lit);
        this.segs[i].SetTintColor(c);
        i += 1;
      }
      this.frac = v;
      return;
    }
    this.fill.SetTintColor(c);
    this.frac = v;
    let fw = v * this.w;
    this.fill.SetVisible(fw >= 14.0);
    this.fill.SetSize(Vector2(MaxF(14.0, fw), this.h));
  }
}

public class CMMtMark {
  public let lastTag: Int32;
  public let lastRng: Int32;
  public let box: ref<inkCanvas>;
  public let corners: array<ref<inkImage>>;
  public let tag: ref<inkText>;
  public let rng: ref<inkText>;
  public let hpTrack: ref<inkImage>;
  public let hpFill: ref<inkImage>;
  public let on: Bool;
}

public class CMMinotaurHud extends CMPilotHud {
  private let m_mtRoot: ref<inkCanvas>;
  private let m_mtFace: ref<inkCanvas>;
  private let m_mtParent: wref<inkCompoundWidget>;
  private let m_mtHidden: array<wref<inkWidget>>;
  private let m_mtHiddenOp: array<Float>;
  private let m_mtW: Float;
  private let m_mtScreen: Vector2;
  private let m_mtPoll: Float;
  private let m_mtLast: ref<CMPilotHudState>;
  private let m_mtLog: Bool;

  private let m_mtStyle: Int32;
  private let m_mtPal: ref<CMHudPal>;

  private let m_mtRing: ref<inkCanvas>;
  private let m_mtZoneMarks: array<ref<inkCanvas>>;
  private let m_mtArmourArc: ref<CMMtMeter>;

  private let m_mtPromptBox: array<ref<inkCanvas>>;
  private let m_mtPromptAct: array<ref<inkText>>;
  private let m_mtPromptTick: array<ref<inkImage>>;
  private let m_mtPromptRight: array<Bool>;
  private let m_mtRainWas: Bool;
  private let m_mtJetsWas: Bool;
  private let m_mtCntrNext: Float;
  private let m_mtShieldNext: Float;
  private let m_mtShield: ref<CMMtMeter>;
  private let m_mtShieldTxt: ref<inkText>;
  private let m_mtSysVals: array<ref<inkText>>;
  private let m_mtSysLabs: array<ref<inkText>>;
  private let m_mtClock: Float;
  private let m_mtTcT: Float;
  private let m_mtTc: ref<inkText>;
  private let m_mtLat: ref<inkText>;
  private let m_mtSigBars: array<ref<inkRectangle>>;
  private let m_mtRec: ref<inkImage>;
  private let m_mtRecPulse: ref<inkAnimProxy>;
  private let m_mtBlocks: array<ref<inkRectangle>>;
  private let m_mtTear: ref<inkRectangle>;
  private let m_mtGlitchT: Float;
  private let m_mtGlitchNext: Float;
  private let m_mtSignal: Float;

  private let m_mtTitle: ref<inkText>;
  private let m_mtLink: ref<inkText>;
  private let m_mtOp: ref<inkText>;

  private let m_mtTape: ref<inkCanvas>;
  private let m_mtTapeLabels: array<ref<inkText>>;
  private let m_mtTapeBase: Int32;
  private let m_mtTapeX: Float;
  private let m_mtHdg: ref<inkText>;
  private let m_mtGnd: ref<inkText>;
  private let m_mtBearings: array<ref<inkImage>>;
  private let m_mtBand: ref<inkCanvas>;
  private let m_mtBandText: ref<inkText>;
  private let m_mtBandT: Float;
  private let m_mtWarning: String;
  private let m_mtBandOn: Bool;
  private let m_mtBandPulse: ref<inkAnimProxy>;

  private let m_mtRange: ref<inkText>;
  private let m_mtZoom: ref<inkText>;
  private let m_mtHitBars: array<ref<inkWidget>>;
  private let m_mtHitT: Float;
  private let m_mtPipL: ref<inkCanvas>;
  private let m_mtPipR: ref<inkCanvas>;
  private let m_mtPipLX: Float;
  private let m_mtPipLY: Float;
  private let m_mtPipRX: Float;
  private let m_mtPipRY: Float;
  private let m_mtFlashL: Bool;
  private let m_mtFlashR: Bool;
  private let m_mtLaidL: Bool;
  private let m_mtLaidR: Bool;
  private let m_mtHitDirs: array<ref<inkCanvas>>;
  private let m_mtHitNext: Int32;
  private let m_mtHurt: ref<inkImage>;
  private let m_mtOptics: ref<inkCanvas>;
  private let m_mtSensor: Float;

  private let m_mtMarks: array<ref<CMMtMark>>;
  private let m_mtLock: ref<inkCanvas>;
  private let m_mtLockRing: ref<inkImage>;
  private let m_mtLockA: ref<inkText>;
  private let m_mtLockB: ref<inkText>;
  private let m_mtLead: ref<inkImage>;
  private let m_mtLockHint: ref<inkText>;
  private let m_mtTracking: Bool;
  private let m_mtTrackKey: String;
  private let m_mtLockKey: Int32;
  private let m_mtLockId: EntityID;
  private let m_mtThreatL: ref<inkCanvas>;
  private let m_mtThreatR: ref<inkCanvas>;
  private let m_mtThreatLT: ref<inkText>;
  private let m_mtThreatRT: ref<inkText>;

  private let m_mtParts: array<ref<CMHudPart>>;
  private let m_mtZoneBars: array<ref<CMMtMeter>>;
  private let m_mtArmour: ref<inkText>;
  private let m_mtHullPct: ref<inkText>;
  private let m_mtHull: ref<CMMtMeter>;

  private let m_mtGunPlates: array<ref<inkImage>>;
  private let m_mtHeatPct: array<ref<inkText>>;
  private let m_mtHeat: array<ref<CMMtMeter>>;
  private let m_mtHeatKey: array<Int32>;
  private let m_mtAim: array<ref<inkText>>;
  private let m_mtGunState: array<ref<inkText>>;
  private let m_mtGunNames: array<ref<inkText>>;
  private let m_mtSecName: ref<inkText>;
  private let m_mtMode: ref<inkText>;
  private let m_mtMsl: ref<inkText>;

  private let m_mtTags: array<ref<inkText>>;
  private let m_mtTagT: array<Float>;
  private let m_mtSplit: Bool;
  private let m_mtKeysAt: Float;

  private let m_mtBoot: ref<inkText>;
  private let m_mtBootT: Float;
  private let m_mtBootStage: Int32;

  private let MT_PX: Float = 18.3;
  private let MT_MARKS: Int32 = 12;
  private let MT_TAG_DIM: Float = 0.55;
  private let MT_TAG_INTRO: Float = 7.0;
  private let MT_TAG_FLASH: Float = 1.2;
  private let MT_BOOT: Float = 1.8;
  private let MT_BAND: Float = 1.6;
  private let MT_SAFE: Float = 0.92;
  private let m_mtUi: Float;

  public static func Schematic34() -> ResRef = r"mnc\\hud\\minotaur_schematic34.inkatlas"

  public func Build() -> Bool {
    let layer = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
    if !IsDefined(layer) {
      return false;
    }
    let window = layer.GetVirtualWindow();
    if !IsDefined(window) {
      return false;
    }
    this.m_mtParent = window;
    this.m_mtStyle = CMPilotSystem.Get(GetGameInstance()).MechHudStyle();
    this.m_mtPal = CMHudPal.Of(this.m_mtStyle);
    ArrayClear(this.m_mtHidden);
    ArrayClear(this.m_mtHiddenOp);
    let i = 0;
    while i < window.GetNumChildren() {
      let child = window.GetWidgetByIndex(i);
      if IsDefined(child) && NotEquals(child.GetName(), n"cm_mech_hud") {
        ArrayPush(this.m_mtHidden, child);
        ArrayPush(this.m_mtHiddenOp, child.GetOpacity());
        child.SetOpacity(0.0);
      }
      i += 1;
    }
    let root = new inkCanvas();
    root.SetName(n"cm_mech_hud");
    root.SetInteractive(false);
    let screen = ScreenHelper.GetScreenSize(GetGameInstance());
    this.m_mtScreen = screen;
    this.m_mtW = 3840.0;
    if screen.Y > 100.0 {
      let k = screen.Y / 2160.0;
      this.m_mtW = screen.X / k;
      root.SetAnchor(inkEAnchor.TopLeft);
      root.SetSize(Vector2(this.m_mtW, 2160.0));
      root.SetRenderTransformPivot(Vector2(0.0, 0.0));
      root.SetScale(Vector2(k, k));
    } else {
      root.SetAnchor(inkEAnchor.Fill);
    }
    root.Reparent(window);
    this.m_mtRoot = root;

    let face = new inkCanvas();
    face.SetAnchor(inkEAnchor.TopLeft);
    face.SetSize(Vector2(this.m_mtW, 2160.0));
    face.SetRenderTransformPivot(Vector2(0.5, 0.5));
    face.SetScale(Vector2(this.MT_SAFE, this.MT_SAFE));
    face.SetInteractive(false);
    face.Reparent(root);
    this.m_mtFace = face;

    ArrayClear(this.m_mtTags);
    ArrayClear(this.m_mtTagT);
    this.m_mtSensor = 1.0;
    this.m_mtTapeBase = -999;
    this.m_mtKeysAt = 0.0;

    let u = ClampF(this.m_mtW / 5800.0, 0.55, 0.9);
    this.m_mtUi = u;
    if this.m_mtStyle == 0 {
      this.MtCorners(face, u);
      this.MtUnit(this.MtRegion(face, 0.0, 0.0, u));
      this.MtHeading(this.MtRegion(face, 0.5, 0.0, u));
      this.MtReticle(this.MtRegion(root, 0.5, 0.5, ClampF(u / 0.9, 0.75, 1.0)), root);
      this.MtTracking(root);
      this.MtChassis(this.MtRegion(face, 0.0, 1.0, u));
      this.MtGuns(this.MtRegion(face, 1.0, 1.0, u));
    } else {

      let e = ClampF(this.m_mtW / 5160.0, 0.8, 1.0);
      this.MnPromptSlots(9);
      if this.m_mtStyle == 2 {
        this.MnFeed(root);
        this.MnFrame(face);
      }
      this.MnEdges(this.MtRegion(face, 0.0, 0.0, e), this.MtRegion(face, 1.0, 0.0, e), this.MtRegion(face, 0.0, 1.0, e));
      this.MnCentre(this.MtRegion(root, 0.5, 0.5, ClampF(u / 0.9, 0.8, 1.0)), root);
      this.MtTracking(root);
      this.MnSystems(this.MtRegion(face, 1.0, 1.0, e));
    }
    this.MtEffects(root);
    this.MtKeys();
    let ws = window.GetSize();
    if !this.m_mtLog {
      this.m_mtLog = true;
    }
    return true;
  }

  public func Remove() -> Void {
    if IsDefined(this.m_mtRoot) && IsDefined(this.m_mtParent) {
      this.m_mtRoot.StopAllAnimations();
      if IsDefined(this.m_mtFace) {
        this.m_mtFace.StopAllAnimations();
      }
      for p in this.m_mtParts {
        if IsDefined(p) && IsDefined(p.canvas) {
          p.canvas.StopAllAnimations();
        }
      }
      for m in this.m_mtHitDirs {
        if IsDefined(m) {
          m.StopAllAnimations();
        }
      }
      if IsDefined(this.m_mtBandPulse) {
        this.m_mtBandPulse.Stop();
      }
      if IsDefined(this.m_mtHurt) {
        this.m_mtHurt.StopAllAnimations();
      }
      if IsDefined(this.m_mtRecPulse) {
        this.m_mtRecPulse.Stop();
      }
      this.m_mtParent.RemoveChild(this.m_mtRoot);
    }
    this.m_mtRecPulse = null;
    this.m_mtRing = null;
    this.m_mtTc = null;
    this.m_mtLat = null;
    this.m_mtRec = null;
    this.m_mtTear = null;
    ArrayClear(this.m_mtZoneMarks);
    this.m_mtArmourArc = null;
    this.m_mtShield = null;
    this.m_mtShieldTxt = null;
    ArrayClear(this.m_mtPromptBox);
    ArrayClear(this.m_mtPromptAct);
    ArrayClear(this.m_mtPromptTick);
    ArrayClear(this.m_mtPromptRight);
    ArrayClear(this.m_mtSysVals);
    ArrayClear(this.m_mtSysLabs);
    ArrayClear(this.m_mtSigBars);
    ArrayClear(this.m_mtBlocks);
    ArrayClear(this.m_mtGunNames);
    this.m_mtRoot = null;
    this.m_mtFace = null;
    this.m_mtBandPulse = null;
    this.m_mtBandOn = false;
    ArrayClear(this.m_mtParts);
    ArrayClear(this.m_mtHitDirs);
    ArrayClear(this.m_mtMarks);
    ArrayClear(this.m_mtBearings);
    ArrayClear(this.m_mtTapeLabels);
    ArrayClear(this.m_mtHitBars);
    ArrayClear(this.m_mtZoneBars);
    ArrayClear(this.m_mtGunPlates);
    ArrayClear(this.m_mtHeatPct);
    ArrayClear(this.m_mtHeat);
    ArrayClear(this.m_mtHeatKey);
    this.m_mtLockKey = -1;
    ArrayClear(this.m_mtAim);
    ArrayClear(this.m_mtGunState);
    this.m_mtOptics = null;
    let i = 0;
    while i < ArraySize(this.m_mtHidden) {
      let w = this.m_mtHidden[i];
      if IsDefined(w) {
        w.SetOpacity(this.m_mtHiddenOp[i]);
      }
      i += 1;
    }
    ArrayClear(this.m_mtHidden);
    ArrayClear(this.m_mtHiddenOp);
  }

  private func MtRelayout() -> Void {
    let optics = IsDefined(this.m_mtOptics) && this.m_mtOptics.IsVisible();
    this.Remove();
    if this.Build() {
      this.m_mtBootT = 0.0;
      if IsDefined(this.m_mtLast) {
        this.Refresh(this.m_mtLast);
      }
      if optics {
        this.SetOptics(true);
      }
    }
  }

  private func MtT(root: ref<inkCanvas>, x: Float, y: Float, text: String, size: Int32, c: HDRColor, ax: Float) -> ref<inkText> {
    let t = CMPilotHud.Label(root, inkEAnchor.TopLeft, x, y, text, size, n"Semi-Bold", c);
    t.SetAnchorPoint(Vector2(ax, 0.0));
    return t;
  }

  private func MtPlate(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, line: HDRColor, glass: HDRColor, flip: Bool) -> ref<inkImage> {
    let g = CMKit.Nine(root, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), x, y, w, h, glass, this.m_mtPal.glassOp);
    let l = CMKit.Nine(root, n"cham_line", inkMargin(20.0, 20.0, 20.0, 20.0), x, y, w, h, line, 0.9);
    if flip {
      g.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
      l.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
    }
    return l;
  }

  private func MtHazard(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, standing: Bool) -> Void {
    if standing {
      let img = CMKit.Img(root, n"hazard", x + w * 0.5 - h * 0.5, y + h * 0.5 - w * 0.5, h, w, this.m_mtPal.accent, 0.85);
      img.SetRenderTransformPivot(Vector2(0.5, 0.5));
      img.SetRotation(90.0);
    } else {
      CMKit.Img(root, n"hazard", x, y, w, h, this.m_mtPal.accent, 0.85);
    }
  }

  private func MtArc(root: ref<inkCanvas>, cx: Float, cy: Float, r: Float, a0: Float, a1: Float, steps: Int32, thick: Float, c: HDRColor, op: Float) -> Void {
    let i = 0;
    while i < steps {
      let p = Deg2Rad(a0 + (a1 - a0) * Cast<Float>(i) / Cast<Float>(steps));
      let q = Deg2Rad(a0 + (a1 - a0) * Cast<Float>(i + 1) / Cast<Float>(steps));
      CMInk.Line(root, cx + SinF(p) * r, cy - CosF(p) * r, cx + SinF(q) * r, cy - CosF(q) * r, thick, c, op);
      i += 1;
    }
  }

  private func MtChevrons(root: ref<inkCanvas>, x: Float, y: Float, n: Int32, s: Float, step: Float, left: Bool, c: HDRColor) -> Void {
    let i = 0;
    while i < n {
      let img = CMKit.Img(root, n"chev_r", left ? x - Cast<Float>(i) * step - 40.0 * s : x + Cast<Float>(i) * step, y, 40.0 * s, 48.0 * s, c, 0.95);
      if left {
        img.SetBrushMirrorType(inkBrushMirrorType.Horizontal);
      }
      i += 1;
    }
  }

  private func MtTag(row: ref<inkHorizontalPanel>, size: Int32) -> ref<inkText> {
    let t = new inkText();
    t.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    t.SetFontStyle(n"Semi-Bold");
    t.SetFontSize(size);
    t.SetLetterCase(textLetterCase.UpperCase);
    t.SetTintColor(this.m_mtPal.primary);
    t.SetMargin(inkMargin(0.0, 0.0, 44.0, 0.0));
    t.Reparent(row);
    ArrayPush(this.m_mtTags, t);
    ArrayPush(this.m_mtTagT, this.MT_TAG_INTRO);
    return t;
  }

  private func MtRow(root: ref<inkCanvas>, x: Float, y: Float) -> ref<inkHorizontalPanel> {
    let row = new inkHorizontalPanel();
    row.SetMargin(inkMargin(x, y, 0.0, 0.0));
    row.SetInteractive(false);
    row.Reparent(root);
    return row;
  }

  private func MtRegion(parent: ref<inkCanvas>, px: Float, py: Float, s: Float) -> ref<inkCanvas> {
    let c = new inkCanvas();
    c.SetAnchor(inkEAnchor.TopLeft);
    c.SetSize(Vector2(this.m_mtW, 2160.0));
    c.SetRenderTransformPivot(Vector2(px, py));
    c.SetScale(Vector2(s, s));
    c.SetInteractive(false);
    c.Reparent(parent);
    return c;
  }

  private func MtCorners(root: ref<inkCanvas>, u: Float) -> Void {
    let W = this.m_mtW;
    let L1 = 386.0 * u;
    let L2 = 232.0 * u;
    let T = 23.0 * u;
    let ink = this.m_mtPal.glass;
    let bone = this.m_mtPal.primary;
    let org = this.m_mtPal.accent;

    for sx in [0.0, 1.0] {
      for sy in [0.0, 1.0] {
        let x0 = sx > 0.5 ? W - L1 : 0.0;
        let y0 = sy > 0.5 ? 2160.0 - T : 0.0;
        CMPilotHud.Bar(root, x0, y0, L1, T, ink, 0.9);
        let vx = sx > 0.5 ? W - T : 0.0;
        let vy = sy > 0.5 ? 2160.0 - L2 : 0.0;
        CMPilotHud.Bar(root, vx, vy, T, L2, ink, 0.9);

        CMPilotHud.Bar(root, sx > 0.5 ? W - L1 + T : T, sy > 0.5 ? 2160.0 - T - 5.0 : T, L1 - 2.0 * T, 5.0, bone, 0.85);
        CMPilotHud.Bar(root, sx > 0.5 ? W - T - 5.0 : T, sy > 0.5 ? 2160.0 - L2 : T, 5.0, L2 - T, bone, 0.85);

        CMPilotHud.Bar(root, sx > 0.5 ? W - L1 - 175.0 * u : L1 + 20.0 * u, sy > 0.5 ? 2160.0 - 14.0 * u : 6.0 * u, 155.0 * u, 8.0 * u, org, 0.95);
      }
    }
  }

  private func MtUnit(root: ref<inkCanvas>) -> Void {
    this.MtPlate(root, 72.0, 57.0, 876.0, 180.0, this.m_mtPal.dim, this.m_mtPal.glass, false);
    this.MtHazard(root, 78.0, 96.0, 36.0, 135.0, true);
    this.m_mtTitle = this.MtT(root, 144.0, 58.0, CMText.MhudMinotaur(), 72, this.m_mtPal.primary, 0.0);
    this.MtT(root, 147.0, 150.0, CMText.MhudHeavyFrontal(), 38, this.m_mtPal.dim, 0.0);
    this.MtT(root, 926.0, 70.0, CMText.MhudLink(), 33, this.m_mtPal.dim, 1.0);
    this.m_mtLink = this.MtT(root, 926.0, 108.0, "---%", 50, this.m_mtPal.primary, 1.0);
    this.m_mtOp = this.MtT(root, 77.0, 258.0, CMText.MhudOperatorV(), 33, this.m_mtPal.dim, 0.0);
  }

  private func MtHeading(root: ref<inkCanvas>) -> Void {
    let cx = this.m_mtW * 0.5;
    CMKit.Nine(root, n"cham_fill", inkMargin(20.0, 20.0, 20.0, 20.0), cx - 824.0, 36.0, 1648.0, 98.0, this.m_mtPal.glass, 0.5);
    let tape = new inkCanvas();
    tape.SetSize(Vector2(2.0, 2.0));
    tape.SetMargin(inkMargin(cx, 0.0, 0.0, 0.0));
    tape.SetInteractive(false);
    tape.Reparent(root);
    this.m_mtTape = tape;
    let k = -3;
    while k <= 3 {
      let t = this.MtT(tape, Cast<Float>(k) * 15.0 * this.MT_PX, 40.0, "000", 38, this.m_mtPal.dim, 0.5);
      ArrayPush(this.m_mtTapeLabels, t);
      k += 1;
    }
    let m = -9;
    while m <= 9 {
      let major = m % 3 == 0;
      CMPilotHud.Bar(tape, Cast<Float>(m) * 5.0 * this.MT_PX - 2.0, major ? 88.0 : 106.0, 4.0, major ? 36.0 : 18.0, major ? this.m_mtPal.primary : this.m_mtPal.dim, 0.9);
      m += 1;
    }

    let i = 0;
    while i < 8 {
      let b = CMKit.Img(root, n"tri", 0.0, 134.0, 30.0, 24.0, this.m_mtPal.hostile, 1.0);
      b.SetRenderTransformPivot(Vector2(0.5, 0.5));
      b.SetRotation(180.0);
      b.SetVisible(false);
      ArrayPush(this.m_mtBearings, b);
      i += 1;
    }
    CMKit.Img(root, n"tri", cx - 22.0, 134.0, 44.0, 32.0, this.m_mtPal.accent, 1.0);
    this.MtPlate(root, cx - 150.0, 170.0, 300.0, 72.0, this.m_mtPal.accent, this.m_mtPal.glass, false);
    this.m_mtHdg = this.MtT(root, cx, 168.0, "---", 56, this.m_mtPal.primary, 0.5);
    this.MtT(root, cx - 211.0, 188.0, CMText.MhudHdg(), 33, this.m_mtPal.dim, 1.0);
    this.m_mtGnd = this.MtT(root, cx + 211.0, 188.0, CMText.MhudGnd("0.0"), 33, this.m_mtPal.dim, 0.0);

    let band = new inkCanvas();
    band.SetSize(Vector2(2.0, 2.0));
    band.SetMargin(inkMargin(cx, 288.0, 0.0, 0.0));
    band.SetVisible(false);
    band.SetInteractive(false);
    band.Reparent(root);
    this.MtPlate(band, -386.0, 0.0, 772.0, 67.0, this.m_mtPal.hostile, this.m_mtPal.alarm, false);
    this.MtChevrons(band, -366.0, 10.0, 3, 1.0, 28.0, false, this.m_mtPal.hostile);
    this.MtChevrons(band, 366.0, 10.0, 3, 1.0, 28.0, true, this.m_mtPal.hostile);
    this.m_mtBandText = this.MtT(band, 0.0, 8.0, CMText.MhudIncomingFrontal(), 38, this.m_mtPal.primary, 0.5);
    this.m_mtBand = band;
  }

  private func MtReticle(root: ref<inkCanvas>, view: ref<inkCanvas>) -> Void {
    let cx = this.m_mtW * 0.5;
    let cy = 1080.0;
    let bone = this.m_mtPal.primary;
    this.MtArc(root, cx, cy, 118.0, -70.0, 70.0, 18, 7.0, bone, 0.95);
    this.MtArc(root, cx, cy, 118.0, 110.0, 250.0, 18, 7.0, bone, 0.95);
    this.MtArc(root, cx, cy, 155.0, -35.0, 35.0, 10, 5.0, this.m_mtPal.accent, 0.95);
    CMKit.Ln(root, cx - 247.0, cy - 4.0, 97.0, 8.0, bone, 0.95);
    CMKit.Ln(root, cx + 150.0, cy - 4.0, 97.0, 8.0, bone, 0.95);
    CMKit.Img(root, n"tri", cx - 26.0, cy + 139.0, 52.0, 41.0, this.m_mtPal.accent, 1.0);
    CMKit.Disc(root, cx, cy, 8.0, bone, 1.0);

    for sx in [-1.0, 1.0] {
      for sy in [-1.0, 1.0] {
        let d = CMInk.Line(root, cx + sx * 44.0, cy + sy * 44.0, cx + sx * 76.0, cy + sy * 76.0, 7.0, bone, 0.0);
        ArrayPush(this.m_mtHitBars, d);
      }
    }

    this.m_mtPipL = this.MtPip(view, "L");
    this.m_mtPipR = this.MtPip(view, "R");
    this.m_mtRange = this.MtT(root, cx, cy + 196.0, CMText.MhudRng("----"), 41, bone, 0.5);
    this.m_mtZoom = this.MtT(root, cx, cy + 248.0, "", 30, this.m_mtPal.dim, 0.5);
  }

  private func MtPip(root: ref<inkCanvas>, side: String) -> ref<inkCanvas> {
    let c = new inkCanvas();
    c.SetSize(Vector2(60.0, 60.0));
    c.SetRenderTransformPivot(Vector2(0.5, 0.5));
    c.SetInteractive(false);
    c.SetVisible(false);
    c.Reparent(root);
    if this.m_mtStyle != 0 {

      CMKit.Img(c, n"ring_s", 15.0, 15.0, 30.0, 30.0, this.m_mtPal.accent, 1.0);
      CMKit.Disc(c, 30.0, 30.0, 3.0, this.m_mtPal.accent, 1.0);
      c.SetOpacity(0.55);
      return c;
    }
    CMKit.Img(c, n"ring_s", 12.0, 12.0, 36.0, 36.0, this.m_mtPal.primary, 1.0);
    CMKit.Disc(c, 30.0, 30.0, 4.0, this.m_mtPal.primary, 1.0);
    this.MtT(c, Equals(side, "L") ? 4.0 : 56.0, 38.0, Equals(side, "L") ? CMText.PhudSideL() : CMText.PhudSideR(), 26, this.m_mtPal.dim, 0.5);
    c.SetOpacity(0.55);
    return c;
  }

  private func MtTracking(root: ref<inkCanvas>) -> Void {
    let i = 0;
    while i < this.MT_MARKS {
      let m = new CMMtMark();
      m.box = new inkCanvas();
      m.box.SetSize(Vector2(2.0, 2.0));
      m.box.SetInteractive(false);
      m.box.SetVisible(false);
      m.box.Reparent(root);
      m.corners = CMKit.Corners(m.box, this.m_mtPal.hostile, 1.0, false);
      m.tag = this.MtT(m.box, 0.0, 0.0, "H-00", 33, this.m_mtPal.hostile, 0.5);
      m.rng = this.MtT(m.box, 0.0, 0.0, "000 M", 33, this.m_mtPal.primary, 0.5);
      m.hpTrack = CMKit.Nine(m.box, n"slant_h", inkMargin(0.0, 0.0, 12.0, 0.0), 0.0, 0.0, 40.0, 10.0, this.m_mtPal.glass, 0.75);
      m.hpFill = CMKit.Nine(m.box, n"slant_h", inkMargin(0.0, 0.0, 12.0, 0.0), 0.0, 0.0, 40.0, 10.0, this.m_mtPal.hostile, 0.95);
      ArrayPush(this.m_mtMarks, m);
      i += 1;
    }
    let lock = new inkCanvas();
    lock.SetSize(Vector2(2.0, 2.0));
    lock.SetInteractive(false);
    lock.SetVisible(false);
    lock.Reparent(root);
    if this.m_mtStyle != 0 {

      this.m_mtLockRing = CMKit.Img(lock, n"ring_s", -44.0, -44.0, 88.0, 88.0, this.m_mtPal.hostile, 1.0);
      CMInk.Line(lock, 40.0, -56.0, 102.0, -118.0, 3.0, this.m_mtPal.hostile, 0.8);
      CMInk.Line(lock, 102.0, -118.0, 386.0, -118.0, 3.0, this.m_mtPal.hostile, 0.8);
      this.m_mtLockA = this.MtT(lock, 112.0, -212.0, CMText.MhudLock(), 34, this.m_mtPal.primary, 0.0);
      this.m_mtLockB = this.MtT(lock, 112.0, -164.0, CMText.MhudHostile(), 28, this.m_mtPal.hostile, 0.0);
      this.m_mtLockHint = this.MtT(lock, 112.0, -108.0, "", 26, this.m_mtPal.accent, 0.0);
      this.m_mtLock = lock;
      this.m_mtLead = CMKit.Img(root, n"ring_s", 0.0, 0.0, 24.0, 24.0, this.m_mtPal.accent, 1.0);
      this.m_mtLead.SetVisible(false);
      this.m_mtThreatL = this.MtThreat(this.MtRegion(root, 0.0, 0.5, this.m_mtUi), true);
      this.m_mtThreatR = this.MtThreat(this.MtRegion(root, 1.0, 0.5, this.m_mtUi), false);
      return;
    }
    this.m_mtLockRing = CMKit.Img(lock, n"diamond_line", -70.0, -70.0, 140.0, 140.0, this.m_mtPal.hostile, 1.0);
    CMInk.Line(lock, 68.0, 0.0, 88.0, -16.0, 5.0, this.m_mtPal.hostile, 0.9);
    this.MtPlate(lock, 88.0, -118.0, 464.0, 103.0, this.m_mtPal.hostile, this.m_mtPal.glass, false);
    this.m_mtLockA = this.MtT(lock, 114.0, -114.0, CMText.MhudLock(), 41, this.m_mtPal.primary, 0.0);
    this.m_mtLockB = this.MtT(lock, 114.0, -64.0, CMText.MhudHostile(), 31, this.m_mtPal.hostile, 0.0);
    this.m_mtLockHint = this.MtT(lock, 114.0, -8.0, "", 29, this.m_mtPal.accent, 0.0);
    this.m_mtLock = lock;
    this.m_mtLead = CMKit.Img(root, n"ring_s", 0.0, 0.0, 30.0, 30.0, this.m_mtPal.accent, 1.0);
    this.m_mtLead.SetVisible(false);

    this.m_mtThreatL = this.MtThreat(this.MtRegion(root, 0.0, 0.5, this.m_mtUi), true);
    this.m_mtThreatR = this.MtThreat(this.MtRegion(root, 1.0, 0.5, this.m_mtUi), false);
  }

  private func MtThreat(root: ref<inkCanvas>, left: Bool) -> ref<inkCanvas> {
    let c = new inkCanvas();
    c.SetSize(Vector2(340.0, 170.0));
    c.SetMargin(inkMargin(left ? 46.0 : this.m_mtW - 386.0, 995.0, 0.0, 0.0));
    c.SetInteractive(false);
    c.SetVisible(false);
    c.Reparent(root);
    this.MtPlate(c, 0.0, 0.0, 340.0, 170.0, this.m_mtPal.hostile, this.m_mtPal.glass, true);
    this.MtChevrons(c, left ? 136.0 : 204.0, 37.0, 3, 1.9, 46.0, left, this.m_mtPal.hostile);
    let t = this.MtT(c, left ? 160.0 : 180.0, 20.0, CMText.MhudThreat(), 36, this.m_mtPal.hostile, left ? 0.0 : 1.0);
    let txt = this.MtT(c, left ? 160.0 : 180.0, 66.0, "", 36, this.m_mtPal.primary, left ? 0.0 : 1.0);
    if left {
      this.m_mtThreatLT = txt;
    } else {
      this.m_mtThreatRT = txt;
    }
    return c;
  }

  private func MtChassis(root: ref<inkCanvas>) -> Void {
    let x0 = 57.0;
    let y0 = 1210.0;
    this.MtPlate(root, x0, y0, 840.0, 880.0, this.m_mtPal.dim, this.m_mtPal.glass, true);
    this.MtHazard(root, x0 + 8.0, 2058.0, 300.0, 24.0, false);
    this.MtT(root, x0 + 36.0, y0 + 16.0, CMText.PhudChassis(), 41, this.m_mtPal.primary, 0.0);
    this.m_mtArmour = this.MtT(root, x0 + 804.0, y0 + 16.0, CMText.MhudArmour("---"), 41, this.m_mtPal.accent, 1.0);

    ArrayClear(this.m_mtParts);
    ArrayResize(this.m_mtParts, CMPart.Count());
    let box = new inkCanvas();
    box.SetMargin(inkMargin(x0 + 22.0, y0 + 92.0, 0.0, 0.0));
    box.SetSize(Vector2(552.0, 608.0));
    box.SetInteractive(false);
    box.Reparent(root);
    let k = 0.95;
    this.MtLayer(box, k, CMPart.Pods(), n"pods", 275.0, 107.0, 223.0, 126.0);
    this.MtLayer(box, k, CMPart.LegR(), n"leg_r", 245.0, 231.0, 211.0, 404.0);
    this.MtLayer(box, k, CMPart.LegL(), n"leg_l", 125.0, 254.0, 198.0, 360.0);
    this.MtLayer(box, k, CMPart.ArmR(), n"arm_r", 352.0, 93.0, 225.0, 156.0);
    this.MtLayer(box, k, CMPart.Torso(), n"torso", 109.0, 39.0, 344.0, 374.0);
    this.MtLayer(box, k, CMPart.ArmL(), n"arm_l", 5.0, 33.0, 224.0, 165.0);
    this.MtLayer(box, k, CMPart.Sensor(), n"sensor", 209.0, 5.0, 252.0, 155.0);

    let names = [CMText.MhudZoneSensor(), CMText.MhudZoneTorso(), CMText.MhudZoneLArm(), CMText.MhudZoneRArm(), CMText.MhudZoneLLeg(), CMText.MhudZoneRLeg(), CMText.MhudZonePods()];
    ArrayClear(this.m_mtZoneBars);
    let i = 0;
    while i < 7 {
      let y = y0 + 118.0 + Cast<Float>(i) * 77.0;
      this.MtT(root, x0 + 804.0, y, names[i], 31, this.m_mtPal.dim, 1.0);
      ArrayPush(this.m_mtZoneBars, CMMtMeter.Make(root, x0 + 670.0, y + 42.0, 134.0, 10.0, this.m_mtPal.primary, this.m_mtPal));
      i += 1;
    }

    this.MtPlate(root, x0, 1910.0, 840.0, 180.0, this.m_mtPal.primary, this.m_mtPal.glass, true);
    this.MtT(root, x0 + 36.0, 1920.0, CMText.MhudHull(), 41, this.m_mtPal.dim, 0.0);
    this.m_mtHullPct = this.MtT(root, x0 + 804.0, 1906.0, "---%", 67, this.m_mtPal.primary, 1.0);
    this.m_mtHull = CMMtMeter.Make(root, x0 + 36.0, 2000.0, 768.0, 28.0, this.m_mtPal.primary, this.m_mtPal);
    let row = this.MtRow(root, x0 + 36.0, 2040.0);

    this.m_mtChassisRow = row;
  }
  private let m_mtChassisRow: ref<inkHorizontalPanel>;

  private func MtLayer(box: ref<inkCanvas>, k: Float, i: Int32, texture: CName, x: Float, y: Float, w: Float, h: Float) -> Void {
    let p = new CMHudPart();
    p.hp = -1.0;
    p.canvas = new inkCanvas();
    p.canvas.SetMargin(inkMargin(x * k, y * k, 0.0, 0.0));
    p.canvas.SetSize(Vector2(w * k, h * k));
    p.canvas.SetInteractive(false);
    p.canvas.Reparent(box);
    p.image = CMPilotHud.Img(p.canvas, inkEAnchor.TopLeft, 0.0, 0.0, w * k, h * k, CMMinotaurHud.Schematic34(), texture, this.m_mtPal.primary, 1.0);
    this.m_mtParts[i] = p;
  }

  private func MtGuns(root: ref<inkCanvas>) -> Void {
    let x0 = this.m_mtW - 850.0;
    let ys = [1442.0, 1653.0];
    let sides = [CMText.PhudSideL() + "  ", CMText.PhudSideR() + "  "];
    ArrayClear(this.m_mtGunNames);
    let i = 0;
    while i < 2 {
      let y = ys[i];
      ArrayPush(this.m_mtGunPlates, this.MtPlate(root, x0, y, 793.0, 190.0, this.m_mtPal.primary, this.m_mtPal.glass, false));

      ArrayPush(this.m_mtGunNames, this.MtT(root, x0 + 36.0, y + 14.0, sides[i] + "MK.31  HMG", 46, this.m_mtPal.primary, 0.0));
      ArrayPush(this.m_mtHeatPct, this.MtT(root, x0 + 757.0, y + 6.0, "0%", 57, this.m_mtPal.primary, 1.0));
      this.MtT(root, x0 + 36.0, y + 86.0, CMText.MhudHeat(), 28, this.m_mtPal.dim, 0.0);
      ArrayPush(this.m_mtHeat, CMMtMeter.Make(root, x0 + 134.0, y + 96.0, 438.0, 22.0, this.m_mtPal.primary, this.m_mtPal));
      ArrayPush(this.m_mtAim, this.MtT(root, x0 + 757.0, y + 86.0, CMText.MhudLaying(), 28, this.m_mtPal.dim, 1.0));
      ArrayPush(this.m_mtGunState, this.MtT(root, x0 + 36.0, y + 136.0, CMText.PhudArmed(), 28, this.m_mtPal.dim, 0.0));
      i += 1;
    }
    let y = 1864.0;
    this.MtPlate(root, x0, y, 793.0, 226.0, this.m_mtPal.accent, this.m_mtPal.glass, false);
    this.MtHazard(root, x0 + 760.0, y + 30.0, 26.0, 170.0, true);
    this.MtT(root, x0 + 36.0, y + 10.0, CMText.MhudMode(), 28, this.m_mtPal.dim, 0.0);
    this.m_mtMode = this.MtT(root, x0 + 36.0, y + 42.0, CMText.PhudStaggered(), 54, this.m_mtPal.accent, 0.0);
    this.m_mtSecName = this.MtT(root, x0 + 410.0, y + 10.0, CMText.MhudMissile(), 28, this.m_mtPal.dim, 0.0);
    this.m_mtMsl = this.MtT(root, x0 + 410.0, y + 42.0, "", 54, this.m_mtPal.primary, 0.0);
    let row = this.MtRow(root, x0 + 36.0, y + 144.0);
    this.MtTag(row, 31);
    this.MtTag(row, 31);
    this.MtTag(row, 31);
    this.MtTag(row, 31);
    this.MtTag(this.m_mtChassisRow, 33);
    this.MtTag(this.m_mtChassisRow, 33);
  }

  private func MtEffects(root: ref<inkCanvas>) -> Void {
    this.m_mtHurt = CMPilotHud.Img(root, inkEAnchor.Fill, 0.0, 0.0, 0.0, 0.0, CMPilotHud.Blobs(), n"vignette", this.m_mtPal.hostile, 0.0);
    ArrayClear(this.m_mtHitDirs);
    let i = 0;
    while i < 4 {
      let c = new inkCanvas();
      c.SetSize(Vector2(80.0, 96.0));
      c.SetRenderTransformPivot(Vector2(0.5, 0.5));
      c.SetOpacity(0.0);
      c.SetInteractive(false);
      c.Reparent(root);
      CMKit.Img(c, n"chev_r", 0.0, 0.0, 80.0, 96.0, this.m_mtPal.hostile, 1.0);
      ArrayPush(this.m_mtHitDirs, c);
      i += 1;
    }
    this.m_mtBoot = this.MtT(root, this.m_mtW * 0.5, 750.0, "", 34, this.m_mtPal.primary, 0.5);
    this.m_mtBoot.SetVisible(false);
  }

  private func MnText(row: ref<inkHorizontalPanel>, text: String, size: Int32, c: HDRColor) -> ref<inkText> {
    let t = new inkText();
    t.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    t.SetFontStyle(n"Semi-Bold");
    t.SetFontSize(size);
    t.SetLetterCase(textLetterCase.UpperCase);
    t.SetTintColor(c);
    CMInk.Text(t, text);
    t.Reparent(row);
    return t;
  }

  private func MnEdges(tl: ref<inkCanvas>, tr: ref<inkCanvas>, bl: ref<inkCanvas>) -> Void {
    let W = this.m_mtW;
    let p = this.m_mtPal;
    if this.m_mtStyle == 2 {
      this.m_mtRec = CMKit.Disc(tl, 129.0, 135.0, 15.0, p.hostile, 1.0);
      this.m_mtRecPulse = CMPilotHud.Loop(this.m_mtRec, 1.0, 0.2, 0.7);
      let row = this.MtRow(tl, 165.0, 108.0);
      this.MnText(row, CMText.MhudRec() + "   ", 36, p.primary);
      this.m_mtTitle = this.MnText(row, CMText.MhudMinotaur(), 36, p.primary);
      this.MnText(row, "  ·  " + CMText.MhudCamFwd(), 36, p.primary);
      this.m_mtTc = this.MtT(tl, 165.0, 160.0, CMText.MhudTimecode("00:00:00:00", "000000"), 29, p.dim, 0.0);
      this.m_mtLink = this.MtT(tr, W - 113.0, 108.0, CMText.MhudUplinkAcquiring(), 36, p.warn, 1.0);
      this.m_mtLat = this.MtT(tr, W - 113.0, 160.0, CMText.MhudLatIdle(), 29, p.dim, 1.0);
      ArrayClear(this.m_mtSigBars);
      let i = 0;
      while i < 5 {
        let h = 15.0 + Cast<Float>(i) * 10.0;
        ArrayPush(this.m_mtSigBars, CMPilotHud.Bar(tr, W - 113.0 - 309.0 - Cast<Float>(4 - i) * 23.0, 258.0 - h, 15.0, h, p.dim, 0.4));
        i += 1;
      }
      this.MnPrompt(4, tl, 165.0, 206.0, false);
      this.MnPrompt(5, tr, W - 113.0, 270.0, true);
      this.m_mtGnd = this.MtT(bl, 113.0, 1990.0, CMText.MhudGnd("0.0"), 29, p.dim, 0.0);
      this.m_mtOp = this.MtT(bl, 113.0, 2036.0, CMText.MhudOperatorRemote(), 29, p.dim, 0.0);
      this.MnZones(bl, 113.0, 1500.0);
      return;
    }
    this.m_mtTitle = this.MtT(tl, 103.0, 66.0, CMText.MhudMinotaur(), 38, p.primary, 0.0);
    let row = this.MtRow(tl, 103.0, 120.0);
    this.MnText(row, CMText.MhudHeavyAssaultLink() + " ", 29, p.dim);
    this.m_mtLink = this.MnText(row, "---%", 29, p.primary);
    this.m_mtOp = this.MtT(tl, 103.0, 164.0, CMText.MhudOperatorV(), 27, p.dim, 0.0);
    this.m_mtGnd = this.MtT(tr, W - 103.0, 76.0, CMText.MhudGnd("0.0"), 29, p.dim, 1.0);
    this.MnPrompt(4, tr, W - 103.0, 124.0, true);
    this.MnPrompt(5, tr, W - 103.0, 170.0, true);
    this.MnZones(bl, 88.0, 1571.0);
  }

  private func MnZones(root: ref<inkCanvas>, x: Float, y: Float) -> Void {
    let p = this.m_mtPal;
    ArrayClear(this.m_mtParts);
    ArrayResize(this.m_mtParts, CMPart.Count());
    let k = 0.684;
    let box = new inkCanvas();
    box.SetMargin(inkMargin(x, y, 0.0, 0.0));
    box.SetSize(Vector2(400.0, 440.0));
    box.SetOpacity(0.8);
    box.SetInteractive(false);
    box.Reparent(root);
    this.MtLayer(box, k, CMPart.Pods(), n"pods", 275.0, 107.0, 223.0, 126.0);
    this.MtLayer(box, k, CMPart.LegR(), n"leg_r", 245.0, 231.0, 211.0, 404.0);
    this.MtLayer(box, k, CMPart.LegL(), n"leg_l", 125.0, 254.0, 198.0, 360.0);
    this.MtLayer(box, k, CMPart.ArmR(), n"arm_r", 352.0, 93.0, 225.0, 156.0);
    this.MtLayer(box, k, CMPart.Torso(), n"torso", 109.0, 39.0, 344.0, 374.0);
    this.MtLayer(box, k, CMPart.ArmL(), n"arm_l", 5.0, 33.0, 224.0, 165.0);
    this.MtLayer(box, k, CMPart.Sensor(), n"sensor", 209.0, 5.0, 252.0, 155.0);

    ArrayClear(this.m_mtZoneMarks);
    ArrayResize(this.m_mtZoneMarks, CMPart.Count());
    this.MnMark(root, CMPart.Pods(), x + 386.0 * k, y + 170.0 * k);
    this.MnMark(root, CMPart.LegR(), x + 350.0 * k, y + 433.0 * k);
    this.MnMark(root, CMPart.LegL(), x + 224.0 * k, y + 434.0 * k);
    this.MnMark(root, CMPart.ArmR(), x + 464.0 * k, y + 171.0 * k);
    this.MnMark(root, CMPart.Torso(), x + 281.0 * k, y + 226.0 * k);
    this.MnMark(root, CMPart.ArmL(), x + 117.0 * k, y + 115.0 * k);
    this.MnMark(root, CMPart.Sensor(), x + 335.0 * k, y + 82.0 * k);

    let cx = x + 200.0;
    let cy = y + 219.0;
    let r = 262.0;
    this.m_mtArmourArc = CMMtMeter.MakeArc(root, cx, cy, r, 150.0, 30.0, 20, p.primary, p);
    this.m_mtArmour = this.MtT(root, cx + SinF(Deg2Rad(30.0)) * r + 16.0, cy - CosF(Deg2Rad(30.0)) * r - 40.0, "---", 30, p.primary, 0.0);
  }

  private func MnMark(root: ref<inkCanvas>, i: Int32, cx: Float, cy: Float) -> Void {
    let c = new inkCanvas();
    c.SetSize(Vector2(34.0, 34.0));
    c.SetMargin(inkMargin(cx - 17.0, cy - 17.0, 0.0, 0.0));
    c.SetInteractive(false);
    c.SetVisible(false);
    c.Reparent(root);
    CMKit.Img(c, n"diamond_line", 0.0, 0.0, 34.0, 34.0, new HDRColor(1.0, 1.0, 1.0, 1.0), 1.0);
    CMKit.Disc(c, 17.0, 17.0, 7.0, new HDRColor(1.0, 1.0, 1.0, 1.0), 1.0);
    this.m_mtZoneMarks[i] = c;
  }

  private func MnCentre(root: ref<inkCanvas>, view: ref<inkCanvas>) -> Void {
    let cx = this.m_mtW * 0.5;
    let cy = 1080.0;
    let p = this.m_mtPal;
    let R1 = 160.0;
    let R2 = 304.0;

    CMInk.Line(root, cx + 26.0, cy, cx + 67.0, cy, 3.0, p.primary, 0.92);
    CMInk.Line(root, cx - 26.0, cy, cx - 67.0, cy, 3.0, p.primary, 0.92);
    CMInk.Line(root, cx, cy + 26.0, cx, cy + 67.0, 3.0, p.primary, 0.92);
    CMInk.Line(root, cx, cy - 26.0, cx, cy - 67.0, 3.0, p.primary, 0.92);
    CMKit.Disc(root, cx, cy, 5.0, p.primary, 1.0);
    for sx in [-1.0, 1.0] {
      for sy in [-1.0, 1.0] {
        ArrayPush(this.m_mtHitBars, CMInk.Line(root, cx + sx * 36.0, cy + sy * 36.0, cx + sx * 60.0, cy + sy * 60.0, 4.0, p.primary, 0.0));
      }
    }
    this.m_mtPipL = this.MtPip(view, "L");
    this.m_mtPipR = this.MtPip(view, "R");
    this.m_mtRange = this.MtT(root, cx + 31.0, cy + 27.0, "---", 31, p.primary, 0.0);

    ArrayClear(this.m_mtHeat);
    ArrayClear(this.m_mtHeatPct);
    ArrayClear(this.m_mtGunNames);
    ArrayClear(this.m_mtGunState);
    ArrayClear(this.m_mtAim);
    ArrayPush(this.m_mtHeat, CMMtMeter.MakeArc(root, cx, cy, R1, 210.0, 330.0, 16, p.accent, p));
    ArrayPush(this.m_mtHeat, CMMtMeter.MakeArc(root, cx, cy, R1, 150.0, 30.0, 16, p.accent, p));
    let i = 0;
    while i < 2 {
      let left = i == 0;
      let x = left ? cx - R1 - 26.0 : cx + R1 + 26.0;
      let ax = left ? 1.0 : 0.0;
      ArrayPush(this.m_mtHeatPct, this.MtT(root, x, cy + 104.0, (left ? CMText.PhudSideL() : CMText.PhudSideR()) + " 0", 31, p.primary, ax));
      ArrayPush(this.m_mtGunNames, this.MtT(root, x, cy + 142.0, "", 26, p.dim, ax));
      ArrayPush(this.m_mtGunState, this.MtT(root, x, cy + 174.0, "", 26, p.dim, ax));
      let aim = this.MtT(root, x, cy + 174.0, "", 26, p.dim, ax);
      aim.SetVisible(false);
      ArrayPush(this.m_mtAim, aim);
      i += 1;
    }

    this.MtArc(root, cx, cy, R2, 0.0, 360.0, 72, 3.0, p.primary, 0.2);
    let ring = new inkCanvas();
    ring.SetSize(Vector2(R2 * 2.0, R2 * 2.0));
    ring.SetMargin(inkMargin(cx - R2, cy - R2, 0.0, 0.0));
    ring.SetRenderTransformPivot(Vector2(0.5, 0.5));
    ring.SetInteractive(false);
    ring.Reparent(root);
    let a = 0;
    while a < 360 {
      let major = a % 30 == 0;
      let rad = Deg2Rad(Cast<Float>(a));
      let r1 = R2 - (major ? 18.0 : 8.0);
      CMInk.Line(ring, R2 + SinF(rad) * R2, R2 - CosF(rad) * R2, R2 + SinF(rad) * r1, R2 - CosF(rad) * r1, 3.0, p.primary, major ? 0.75 : 0.45);
      a += 10;
    }
    this.m_mtRing = ring;
    this.m_mtTape = ring;
    let ptr = CMKit.Img(root, n"tri", cx - 11.0, cy - R2 - 16.0, 22.0, 16.0, p.primary, 0.9);
    ptr.SetRenderTransformPivot(Vector2(0.5, 0.5));
    ptr.SetRotation(180.0);
    this.m_mtHdg = this.MtT(root, cx, cy - R2 - 62.0, "---", 34, p.primary, 0.5);

    ArrayClear(this.m_mtBearings);
    i = 0;
    while i < 8 {
      let b = CMKit.Img(root, n"pill_h", 0.0, 0.0, 44.0, 8.0, p.hostile, 1.0);
      b.SetRenderTransformPivot(Vector2(0.5, 0.5));
      b.SetVisible(false);
      ArrayPush(this.m_mtBearings, b);
      i += 1;
    }

    let band = new inkCanvas();
    band.SetSize(Vector2(2.0, 2.0));
    band.SetMargin(inkMargin(cx, cy, 0.0, 0.0));
    band.SetVisible(false);
    band.SetInteractive(false);
    band.Reparent(root);
    for s in [-1.0, 1.0] {
      let a0 = Deg2Rad(s * 14.0);
      let a1 = Deg2Rad(s * 20.0);
      CMInk.Line(band, SinF(a0) * (R2 + 20.0), -CosF(a0) * (R2 + 20.0), SinF(a1) * (R2 + 57.0), -CosF(a1) * (R2 + 57.0), 5.0, p.hostile, 1.0);
    }
    this.m_mtBandText = this.MtT(band, 0.0, -R2 - 122.0, CMText.MhudIncoming(), 28, p.hostile, 0.5);
    this.m_mtBand = band;

    let hy = cy + R2 + 88.0;
    this.MtT(root, cx - 252.0, hy - 20.0, CMText.MhudHull(), 28, p.dim, 1.0);
    this.m_mtHull = CMMtMeter.Make(root, cx - 232.0, hy - 3.0, 464.0, 6.0, p.primary, p, true);
    this.m_mtHullPct = this.MtT(root, cx + 252.0, hy - 20.0, "---", 28, p.primary, 0.0);
    this.m_mtShield = CMMtMeter.Make(root, cx - 232.0, hy + 18.0, 464.0, 4.0, p.accent, p, true);
    this.m_mtShieldTxt = this.MtT(root, cx + 252.0, hy + 6.0, CMText.MhudShd(), 26, p.accent, 0.0);
    this.MnShieldShow(false);
    this.MnPrompt(8, root, cx + 340.0, hy + 4.0, false);
    this.MnPrompt(0, root, cx - R1 - 26.0, cy + 214.0, true);
    this.MnPrompt(3, root, cx + R1 + 26.0, cy + 214.0, false);
    this.m_mtZoom = this.MtT(root, cx, hy + 56.0, "", 27, p.dim, 0.5);
  }

  private func MnShieldShow(on: Bool) -> Void {
    if !IsDefined(this.m_mtShield) {
      return;
    }
    this.m_mtShield.track.SetVisible(on);
    this.m_mtShield.fill.SetVisible(on && this.m_mtShield.frac > 0.03);
    this.m_mtShieldTxt.SetVisible(on);
    if ArraySize(this.m_mtPromptBox) > 8 && IsDefined(this.m_mtPromptBox[8]) {
      this.m_mtPromptBox[8].SetVisible(on);
    }
  }

  private func MnSystems(root: ref<inkCanvas>) -> Void {
    let p = this.m_mtPal;
    let xr = this.m_mtW - 103.0;
    let xl = xr - 330.0;
    let y = 1500.0;
    this.MtT(root, xl, y + 4.0, CMText.MhudMode(), 28, p.dim, 0.0);
    this.m_mtMode = this.MtT(root, xr, y, CMText.PhudStaggered(), 34, p.primary, 1.0);
    this.m_mtSecName = this.MtT(root, xl, y + 71.0, CMText.MhudRain(), 28, p.dim, 0.0);
    this.m_mtMsl = this.MtT(root, xr, y + 67.0, "", 34, p.accent, 1.0);
    ArrayClear(this.m_mtSysLabs);
    ArrayClear(this.m_mtSysVals);
    let labs = [CMText.MhudJets(), CMText.MhudCntr(), CMText.MhudShield(), CMText.MhudLights()];
    let i = 0;
    while i < 4 {
      let yy = y + 134.0 + Cast<Float>(i) * 67.0;
      let l = this.MtT(root, xl, yy + 4.0, labs[i], 28, p.dim, 0.0);
      let v = this.MtT(root, xr, yy, "", 34, p.accent, 1.0);
      l.SetVisible(false);
      v.SetVisible(false);
      ArrayPush(this.m_mtSysLabs, l);
      ArrayPush(this.m_mtSysVals, v);
      i += 1;
    }

    this.MnPrompt(1, root, xl - 24.0, y + 4.0, true);
    this.MnPrompt(6, root, xl - 24.0, y + 71.0, true);
    this.MnPrompt(7, root, xl - 24.0, y + 138.0, true);
    this.MnPrompt(2, root, xl - 24.0, y + 205.0, true);
  }

  private func MnPromptSlots(n: Int32) -> Void {
    ArrayClear(this.m_mtTags);
    ArrayClear(this.m_mtTagT);
    ArrayResize(this.m_mtTags, n);
    ArrayResize(this.m_mtTagT, n);
    ArrayResize(this.m_mtPromptBox, n);
    ArrayResize(this.m_mtPromptAct, n);
    ArrayResize(this.m_mtPromptTick, n);
    ArrayResize(this.m_mtPromptRight, n);
    let i = 0;
    while i < n {
      this.m_mtTagT[i] = this.MT_TAG_INTRO;
      i += 1;
    }
  }

  private func MnPrompt(i: Int32, root: ref<inkCanvas>, x: Float, y: Float, right: Bool) -> Void {
    let p = this.m_mtPal;
    let c = new inkCanvas();
    c.SetSize(Vector2(2.0, 2.0));
    c.SetMargin(inkMargin(x, y, 0.0, 0.0));
    c.SetInteractive(false);
    c.SetOpacity(0.0);
    c.Reparent(root);
    this.m_mtPromptBox[i] = c;
    this.m_mtPromptTick[i] = CMKit.Ln(c, 0.0, 15.0, 12.0, 4.0, p.accent, 0.9);
    this.m_mtTags[i] = this.MtT(c, 0.0, 0.0, "", 27, p.accent, right ? 1.0 : 0.0);
    this.m_mtPromptAct[i] = this.MtT(c, 0.0, 0.0, "", 27, p.primary, right ? 1.0 : 0.0);
    this.m_mtPromptRight[i] = right;
  }

  private func MnPromptSet(i: Int32, key: String, act: String) -> Void {
    if i >= ArraySize(this.m_mtPromptBox) || !IsDefined(this.m_mtPromptBox[i]) {
      return;
    }
    CMInk.Text(this.m_mtTags[i], key);
    CMInk.Text(this.m_mtPromptAct[i], act);
    let em = 27.0 * 0.56;
    if this.m_mtPromptRight[i] {
      this.m_mtPromptAct[i].SetMargin(inkMargin(0.0, 0.0, 0.0, 0.0));
      this.m_mtTags[i].SetMargin(inkMargin(-em * Cast<Float>(StrLen(act)) - 16.0, 0.0, 0.0, 0.0));
      this.m_mtPromptTick[i].SetMargin(inkMargin(10.0, 15.0, 0.0, 0.0));
    } else {
      this.m_mtTags[i].SetMargin(inkMargin(0.0, 0.0, 0.0, 0.0));
      this.m_mtPromptAct[i].SetMargin(inkMargin(em * Cast<Float>(StrLen(key)) + 16.0, 0.0, 0.0, 0.0));
      this.m_mtPromptTick[i].SetMargin(inkMargin(-22.0, 15.0, 0.0, 0.0));
    }
  }

  private func MnRaise(i: Int32, t: Float) -> Void {
    if i < ArraySize(this.m_mtTagT) {
      this.m_mtTagT[i] = MaxF(this.m_mtTagT[i], t);
    }
  }

  private func MnFeed(root: ref<inkCanvas>) -> Void {
    let W = this.m_mtW;
    CMPilotHud.Bar(root, 0.0, 0.0, W, 2160.0, new HDRColor(0.16, 0.27, 0.31, 1.0), 0.08);
    CMPilotHud.Img(root, inkEAnchor.Fill, 0.0, 0.0, 0.0, 0.0, CMPilotHud.Blobs(), n"vignette", CMPilotHud.Black(), 0.7);
    let y = 0.0;
    while y < 2160.0 {
      CMPilotHud.Bar(root, 0.0, y, W, 2.0, CMPilotHud.Black(), 0.14);
      y += 6.0;
    }
    ArrayClear(this.m_mtBlocks);
    let i = 0;
    while i < 6 {
      let b = CMPilotHud.Bar(root, 0.0, 0.0, 41.0, 41.0, new HDRColor(0.36, 0.42, 0.45, 1.0), 0.55);
      b.SetVisible(false);
      ArrayPush(this.m_mtBlocks, b);
      i += 1;
    }
    this.m_mtTear = CMPilotHud.Bar(root, 0.0, 0.0, W, 15.0, this.m_mtPal.accent, 0.14);
    this.m_mtTear.SetVisible(false);
    this.m_mtGlitchNext = 2.0;
    this.m_mtGlitchT = 0.0;
    this.m_mtSignal = 1.0;
    this.m_mtClock = 0.0;
  }

  private func MnFrame(root: ref<inkCanvas>) -> Void {
    let W = this.m_mtW;
    let c = this.m_mtPal.primary;
    let m = 62.0;
    let L = 154.0;
    let t = 5.0;
    CMKit.Ln(root, m, m, L, t, c, 0.82);
    CMKit.Ln(root, m, m, t, L, c, 0.82);
    CMKit.Ln(root, W - m - L, m, L, t, c, 0.82);
    CMKit.Ln(root, W - m - t, m, t, L, c, 0.82);
    CMKit.Ln(root, m, 2160.0 - m - t, L, t, c, 0.82);
    CMKit.Ln(root, m, 2160.0 - m - L, t, L, c, 0.82);
    CMKit.Ln(root, W - m - L, 2160.0 - m - t, L, t, c, 0.82);
    CMKit.Ln(root, W - m - t, 2160.0 - m - L, t, L, c, 0.82);
    CMKit.Ln(root, W * 0.5 - 2.5, m, t, 26.0, c, 0.6);
    CMKit.Ln(root, W * 0.5 - 2.5, 2160.0 - m - 26.0, t, 26.0, c, 0.6);
    CMKit.Ln(root, m, 1077.5, 26.0, t, c, 0.6);
    CMKit.Ln(root, W - m - 26.0, 1077.5, 26.0, t, c, 0.6);
  }

  private func MnGlitch(dt: Float) -> Void {
    this.m_mtClock += dt;
    this.m_mtTcT -= dt;
    if IsDefined(this.m_mtTc) && this.m_mtTcT <= 0.0 {
      this.m_mtTcT = 0.1;
      let fr = RoundF(this.m_mtClock * 60.0);
      let secs = FloorF(this.m_mtClock);
      let tc = CMMinotaurHud.Two(secs / 3600) + ":" + CMMinotaurHud.Two((secs / 60) % 60) + ":" + CMMinotaurHud.Two(secs % 60) + ":" + CMMinotaurHud.Two(fr % 60);
      CMInk.Text(this.m_mtTc, CMText.MhudTimecode(tc, CMPilotHud.Pad3(fr / 1000) + CMPilotHud.Pad3(fr % 1000)));
    }
    if ArraySize(this.m_mtBlocks) == 0 {
      return;
    }
    if this.m_mtGlitchT > 0.0 {
      this.m_mtGlitchT -= dt;
      if this.m_mtGlitchT <= 0.0 {
        for b in this.m_mtBlocks {
          b.SetVisible(false);
        }
        this.m_mtTear.SetVisible(false);
      }
      return;
    }
    this.m_mtGlitchNext -= dt;
    if this.m_mtGlitchNext > 0.0 {
      return;
    }
    let weak = 1.0 - ClampF(this.m_mtSignal, 0.0, 1.0);
    this.m_mtGlitchNext = RandRangeF(1.2, 4.5) * (1.0 - 0.75 * weak);
    this.m_mtGlitchT = RandRangeF(0.06, 0.16);
    let n = RandRange(1, 3 + RoundF(weak * 4.0));
    let i = 0;
    while i < ArraySize(this.m_mtBlocks) {
      let b = this.m_mtBlocks[i];
      if i < n {
        let w = 41.0 * Cast<Float>(RandRange(1, 5));
        let h = 41.0 * Cast<Float>(RandRange(1, 3));
        b.SetMargin(inkMargin(RandRangeF(0.0, this.m_mtW - w), RandRangeF(150.0, 2000.0), 0.0, 0.0));
        b.SetSize(Vector2(w, h));
        b.SetVisible(true);
      } else {
        b.SetVisible(false);
      }
      i += 1;
    }
    if RandF() < 0.5 + weak * 0.5 {
      this.m_mtTear.SetMargin(inkMargin(RandRangeF(-30.0, 30.0), RandRangeF(300.0, 1900.0), 0.0, 0.0));
      this.m_mtTear.SetVisible(true);
    }
  }

  private static func Two(n: Int32) -> String = (n < 10 ? "0" : "") + IntToString(n)

  public func SetSystems(jets: String, cntr: String, shield: Float, shieldUp: Bool, lights: Bool) -> Void {
    if !IsDefined(this.m_mtRoot) || this.m_mtStyle == 0 || ArraySize(this.m_mtSysVals) < 4 {
      return;
    }
    let p = this.m_mtPal;
    let vals = [jets, cntr, shield < 0.0 ? "" : (shieldUp ? CMText.MhudShieldUp(IntToString(RoundF(shield * 100.0))) : IntToString(RoundF(shield * 100.0))), lights ? CMText.MhudOn() : CMText.MhudOff()];
    let prompts = [7, 2, -1, -1];
    let y = 1634.0;
    let i = 0;
    while i < 4 {
      let on = StrLen(vals[i]) > 0;
      this.m_mtSysLabs[i].SetVisible(on);
      this.m_mtSysVals[i].SetVisible(on);
      let k = prompts[i];
      if k >= 0 && k < ArraySize(this.m_mtPromptBox) && IsDefined(this.m_mtPromptBox[k]) {
        this.m_mtPromptBox[k].SetVisible(on);
        this.m_mtPromptBox[k].SetMargin(inkMargin(this.m_mtW - 457.0, y + 4.0, 0.0, 0.0));
      }
      if on {
        CMInk.Text(this.m_mtSysVals[i], Equals(vals[i], "READY") ? CMText.MhudReady() : vals[i]);
        let ready = Equals(vals[i], "READY") || (i == 2 && shieldUp) || (i == 3 && lights);

        let calm = i == 3 || (i == 2 && shield >= 0.2);
        this.m_mtSysVals[i].SetTintColor(ready ? p.accent : (calm ? (i == 3 ? p.dim : p.primary) : p.warn));
        this.m_mtSysLabs[i].SetMargin(inkMargin(this.m_mtW - 433.0, y + 4.0, 0.0, 0.0));
        this.m_mtSysVals[i].SetMargin(inkMargin(this.m_mtW - 103.0, y, 0.0, 0.0));
        y += 67.0;
      }
      i += 1;
    }
    if IsDefined(this.m_mtShield) {
      if shield >= 0.0 {
        this.m_mtShield.Set(shield, shieldUp ? p.accent : p.dim);
      }
      this.MnShieldShow(shield >= 0.0);
      this.m_mtShieldTxt.SetTintColor(shieldUp ? p.accent : p.dim);
    }
    let jetsReady = Equals(jets, "READY");
    if jetsReady && !this.m_mtJetsWas {
      this.MnRaise(7, 3.0);
    }
    this.m_mtJetsWas = jetsReady;
    if Equals(cntr, "READY") && this.m_mtBandOn && this.m_mtCntrNext <= 0.0 {
      this.m_mtCntrNext = 10.0;
      this.MnRaise(2, 3.0);
    }
    if shield >= 0.2 && !shieldUp && this.m_mtBandOn && this.m_mtShieldNext <= 0.0 {
      this.m_mtShieldNext = 10.0;
      this.MnRaise(8, 3.0);
    }
  }

  private func MtKeys() -> Void {
    if ArraySize(this.m_mtTags) < 6 {
      return;
    }
    let p = GetPlayer(GetGameInstance());
    let fire = CMKeyName.Game(n"ShootPrimary", "LMB");
    let aim = CMKeyName.Game(n"CameraAim", "RMB");
    if ArraySize(this.m_mtPromptBox) >= 8 {

      let mode = CMKeyName.Of(CMKeys.FireMode(p));
      this.MnPromptSet(0, fire, this.m_mtSplit ? CMText.MhudLGun() : CMText.MhudFire());
      this.MnPromptSet(3, aim, this.m_mtSplit ? CMText.MhudRGun() : CMText.MhudOptics());
      this.MnPromptSet(1, mode, CMText.MhudMode());
      this.MnPromptSet(6, CMText.MhudHold(mode), CMText.MhudRain());
      this.MnPromptSet(2, CMText.MhudTap(CMKeyName.Of(CMKeys.Defence(p))), CMText.MhudCntr());
      this.MnPromptSet(7, CMKeyName.Of(CMKeys.Jump(p)), CMText.MhudJets());
      this.MnPromptSet(8, CMText.MhudHold(CMKeyName.Of(CMKeys.Defence(p))), CMText.MhudShield());
      this.MnPromptSet(4, CMKeyName.Of(CMKeys.View(p)), CMText.MhudView());
      this.MnPromptSet(5, CMKeyName.Of(CMKeys.Pilot(p)), this.m_mtStyle == 2 ? CMText.MhudDropLink() : CMText.MhudDisconnect());
      this.m_mtTrackKey = CMKeyName.Of(CMKeys.Track(p));
      return;
    }
    if this.m_mtSplit {
      CMInk.Text(this.m_mtTags[0], CMText.PhudKeysSplit("[" + fire + "]", "[" + aim + "]"));
      CMInk.Text(this.m_mtTags[3], CMText.MhudKeyOptics(CMKeyName.Tag(CMKeys.SplitOptics(p))));
    } else {
      CMInk.Text(this.m_mtTags[0], CMText.PhudKeyFire("[" + fire + "]"));
      CMInk.Text(this.m_mtTags[3], CMText.MhudKeyOptics("[" + aim + "]"));
    }

    CMInk.Text(this.m_mtTags[1], CMText.MhudKeyModeRain(CMKeyName.Tag(CMKeys.FireMode(p))));
    CMInk.Text(this.m_mtTags[2], CMText.MhudKeyDefence(CMKeyName.Tag(CMKeys.Defence(p))));
    CMInk.Text(this.m_mtTags[4], CMText.PhudKeyView(CMKeyName.Tag(CMKeys.View(p))));
    CMInk.Text(this.m_mtTags[5], CMText.PhudKeyDisconnect(CMKeyName.Tag(CMKeys.Pilot(p))));
    this.m_mtTrackKey = CMKeyName.Of(CMKeys.Track(p));
  }

  public func TagFlash(i: Int32) -> Void {
    if i >= 0 && i < ArraySize(this.m_mtTagT) {
      this.m_mtTagT[i] = MaxF(this.m_mtTagT[i], this.MT_TAG_FLASH);
      if ArraySize(this.m_mtPromptBox) > 0 {
        return;
      }
      this.m_mtTags[i].SetOpacity(1.0);
      this.m_mtTags[i].SetTintColor(this.m_mtPal.accent);
    }
  }

  public func Tags(dt: Float) -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    let prompts = ArraySize(this.m_mtPromptBox) > 0;
    let i = 0;
    while i < ArraySize(this.m_mtTagT) {
      if this.m_mtTagT[i] > 0.0 {
        this.m_mtTagT[i] -= dt;
        let t = MaxF(0.0, this.m_mtTagT[i]);
        if prompts {

          if IsDefined(this.m_mtPromptBox[i]) {
            this.m_mtPromptBox[i].SetOpacity(t > 0.5 ? 1.0 : t / 0.5);
          }
        } else {
          let dim = this.MT_TAG_DIM;
          this.m_mtTags[i].SetOpacity(t > 0.5 ? 1.0 : dim + (1.0 - dim) * t / 0.5);
          if t <= 0.0 {
            this.m_mtTags[i].SetTintColor(this.m_mtPal.primary);
          }
        }
      }
      i += 1;
    }
    if this.m_mtCntrNext > 0.0 {
      this.m_mtCntrNext -= dt;
    }
    if this.m_mtShieldNext > 0.0 {
      this.m_mtShieldNext -= dt;
    }
    if this.m_mtBandT > 0.0 {
      this.m_mtBandT -= dt;
      if this.m_mtBandT <= 0.0 {
        this.MtBand();
      }
    }
    this.m_mtKeysAt -= dt;
    if this.m_mtKeysAt <= 0.0 {
      this.m_mtKeysAt = 1.0;
      this.MtKeys();
    }
    this.m_mtPoll -= dt;
    if this.m_mtPoll <= 0.0 {
      this.m_mtPoll = 0.5;
      let screen = ScreenHelper.GetScreenSize(GetGameInstance());
      if screen.Y > 100.0 && (AbsF(screen.X - this.m_mtScreen.X) > 1.0 || AbsF(screen.Y - this.m_mtScreen.Y) > 1.0) {
        this.MtRelayout();
        return;
      }

      if CMPilotSystem.Get(GetGameInstance()).MechHudStyle() != this.m_mtStyle {
        this.MtRelayout();
        return;
      }
    }
    if this.m_mtStyle == 2 {
      this.MnGlitch(dt);
    }
  }

  public func SetAttitude(heading: Float, pitch: Float) -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    let h = heading < 0.0 ? heading + 360.0 : heading;
    if IsDefined(this.m_mtRing) {

      this.m_mtRing.SetRotation(-h);
      return;
    }
    let base = FloorF(h / 15.0) * 15;
    if base != this.m_mtTapeBase {
      this.m_mtTapeBase = base;
      let i = 0;
      while i < ArraySize(this.m_mtTapeLabels) {
        let b = (base + (i - 3) * 15 + 720) % 360;
        let lab = CMMinotaurHud.MtBearing(b);
        CMInk.Text(this.m_mtTapeLabels[i], lab);
        this.m_mtTapeLabels[i].SetTintColor(b % 45 == 0 ? this.m_mtPal.primary : this.m_mtPal.dim);
        i += 1;
      }
    }
    let x = -(h - Cast<Float>(base)) * this.MT_PX;
    if AbsF(x - this.m_mtTapeX) > 1.0 {
      this.m_mtTapeX = x;
      this.m_mtTape.SetMargin(inkMargin(this.m_mtW * 0.5 + x, 0.0, 0.0, 0.0));
    }
  }

  private static func MtBearing(b: Int32) -> String {
    switch b {
      case 0: return CMText.PhudN();
      case 45: return CMText.PhudNE();
      case 90: return CMText.PhudE();
      case 135: return CMText.PhudSE();
      case 180: return CMText.PhudS();
      case 225: return CMText.PhudSW();
      case 270: return CMText.PhudW();
      case 315: return CMText.PhudNW();
    }
    return CMPilotHud.Pad3(b);
  }

  public func SetTracking(on: Bool) -> Void {
    this.m_mtTracking = on;
  }

  public func Track(t: ref<CMDroneTrack>) -> Void {
    if !IsDefined(this.m_mtRoot) || !IsDefined(t) {
      return;
    }
    let cx = this.m_mtW * 0.5;
    let halfW = cx - 80.0;
    let used = 0;
    let bearings = 0;
    let bestL: ref<CMDroneContact>;
    let bestR: ref<CMDroneContact>;
    let offL = 0.0;
    let offR = 0.0;
    let n = 0;
    for c in t.contacts {
      let show = (c.kind == 2 || c.kind == 4) && c.hp > 0.0;
      if show {
        n += 1;
        let off = CMMinotaurHud.MtOff(t.pos, c.pos, t.yaw);
        let on = AbsF(c.scr.X) < halfW && AbsF(c.scr.Y) < 1020.0;
        if on && used < ArraySize(this.m_mtMarks) {
          this.MtMark(this.m_mtMarks[used], c, cx + c.scr.X, 1080.0 + c.scr.Y, n);
          used += 1;
        }
        if c.kind == 2 && this.m_mtStyle != 0 {

          if bearings < ArraySize(this.m_mtBearings) && this.m_mtSensor > 0.0 {
            let b = this.m_mtBearings[bearings];
            let a = Deg2Rad(-off);
            b.SetMargin(inkMargin(cx + SinF(a) * 304.0 - 22.0, 1080.0 - CosF(a) * 304.0 - 4.0, 0.0, 0.0));
            b.SetRotation(-off);
            b.SetOpacity(AbsF(off) > 60.0 ? 1.0 : 0.75);
            b.SetVisible(true);
            bearings += 1;
          }
        } else if c.kind == 2 {
          if AbsF(off) <= 47.0 && bearings < ArraySize(this.m_mtBearings) && this.m_mtSensor > 0.0 {
            let b = this.m_mtBearings[bearings];
            b.SetMargin(inkMargin(cx - off * this.MT_PX - 15.0, 134.0, 0.0, 0.0));
            b.SetVisible(true);
            bearings += 1;
          }
          if !on {
            if off > 0.0 && (!IsDefined(bestL) || c.dist < bestL.dist) {
              bestL = c;
              offL = off;
            }
            if off <= 0.0 && (!IsDefined(bestR) || c.dist < bestR.dist) {
              bestR = c;
              offR = off;
            }
          }
        }
      }
    }
    while used < ArraySize(this.m_mtMarks) {
      let m = this.m_mtMarks[used];
      if m.on {
        m.on = false;
        m.box.SetVisible(false);
      }
      used += 1;
    }
    while bearings < ArraySize(this.m_mtBearings) {
      this.m_mtBearings[bearings].SetVisible(false);
      bearings += 1;
    }
    this.MtThreatSet(this.m_mtThreatL, this.m_mtThreatLT, bestL, offL);
    this.MtThreatSet(this.m_mtThreatR, this.m_mtThreatRT, bestR, offR);

    let l = t.lock;
    if IsDefined(l) && l.kind != 0 && AbsF(l.scr.X) < halfW && AbsF(l.scr.Y) < 1020.0 {
      let x = cx + l.scr.X;
      let y = 1080.0 + l.scr.Y;
      this.m_mtLock.SetMargin(inkMargin(x, y, 0.0, 0.0));
      this.m_mtLock.SetVisible(true);
      let col = l.kind == 2 ? this.m_mtPal.hostile : (l.kind == 4 ? this.m_mtPal.friendly : this.m_mtPal.primary);
      this.m_mtLockRing.SetTintColor(col);

      let key = RoundF(l.dist) * 8 + (this.m_mtTracking ? 4 : 0) + (l.combat ? 2 : 0);
      if key != this.m_mtLockKey || NotEquals(l.id, this.m_mtLockId) {
        this.m_mtLockKey = key;
        this.m_mtLockId = l.id;
        CMInk.Text(this.m_mtLockA, this.m_mtTracking ? CMText.MhudTrackingDist(IntToString(RoundF(l.dist))) : CMText.MhudLockDist(IntToString(RoundF(l.dist))));
        this.m_mtLockA.SetTintColor(this.m_mtTracking ? this.m_mtPal.accent : this.m_mtPal.primary);
        if this.m_mtStyle != 0 {
          CMInk.Text(this.m_mtLockHint, this.m_mtTrackKey + "  " + (this.m_mtTracking ? CMText.MhudRelease() : CMText.MhudTrack()));
        } else {
          CMInk.Text(this.m_mtLockHint, "[" + this.m_mtTrackKey + "] " + (this.m_mtTracking ? CMText.MhudRelease() : CMText.MhudTrack()));
        }
        CMInk.Text(this.m_mtLockB, l.Label() + (l.combat && l.kind == 2 ? "   " + CMText.MhudInCombat() : ""));
        this.m_mtLockB.SetTintColor(col);
      }
      if t.leadOn {
        this.m_mtLead.SetMargin(inkMargin(cx + t.lead.X - 15.0, 1080.0 + t.lead.Y - 15.0, 0.0, 0.0));
        this.m_mtLead.SetVisible(true);
      } else {
        this.m_mtLead.SetVisible(false);
      }
    } else {
      this.m_mtLock.SetVisible(false);
      this.m_mtLead.SetVisible(false);
    }
  }

  private static func MtOff(from: Vector4, to: Vector4, yaw: Float) -> Float {
    let dx = to.X - from.X;
    let dy = to.Y - from.Y;
    let a = Rad2Deg(AtanF(-dx, dy)) - yaw;
    while a > 180.0 {
      a -= 360.0;
    }
    while a < -180.0 {
      a += 360.0;
    }
    return a;
  }

  private func MtMark(m: ref<CMMtMark>, c: ref<CMDroneContact>, x: Float, y: Float, n: Int32) -> Void {
    let col = c.kind == 2 ? this.m_mtPal.hostile : this.m_mtPal.friendly;

    let h = ClampF(5200.0 / MaxF(c.dist, 1.0), 44.0, 240.0);
    let w = h * 0.55;
    let L = ClampF(h * 0.3, 16.0, 40.0);
    if !m.on {
      m.on = true;
      m.box.SetVisible(true);
    }
    m.box.SetMargin(inkMargin(x, y, 0.0, 0.0));
    CMKit.PlaceCorners(m.corners, 0, -w * 0.5, -h * 0.5, w, h, L);
    CMKit.ShowCorners(m.corners, 0, true, col);
    let tagKey = c.kind * 1000 + n;
    if tagKey != m.lastTag {
      m.lastTag = tagKey;
      CMInk.Text(m.tag, (c.kind == 2 ? "H-" : "F-") + (n < 10 ? "0" : "") + IntToString(n));
      m.tag.SetTintColor(col);
    }
    m.tag.SetMargin(inkMargin(0.0, -h * 0.5 - 44.0, 0.0, 0.0));
    let rng = RoundF(c.dist);
    if rng != m.lastRng {
      m.lastRng = rng;
      CMInk.Text(m.rng, IntToString(rng) + " M");
    }
    m.rng.SetMargin(inkMargin(0.0, h * 0.5 + 24.0, 0.0, 0.0));
    let bw = MaxF(w, 40.0);
    m.hpTrack.SetMargin(inkMargin(-bw * 0.5, h * 0.5 + 8.0, 0.0, 0.0));
    m.hpTrack.SetSize(Vector2(bw, 10.0));
    let fw = bw * ClampF(c.hp, 0.0, 1.0);
    m.hpFill.SetVisible(fw >= 14.0);
    m.hpFill.SetMargin(inkMargin(-bw * 0.5, h * 0.5 + 8.0, 0.0, 0.0));
    m.hpFill.SetSize(Vector2(MaxF(14.0, fw), 10.0));
    m.hpFill.SetTintColor(col);
  }

  private func MtThreatSet(plate: ref<inkCanvas>, txt: ref<inkText>, c: ref<CMDroneContact>, off: Float) -> Void {

    if !IsDefined(c) || this.m_mtSensor <= 0.0 || this.m_mtStyle != 0 {
      plate.SetVisible(false);
      return;
    }

    let clock = RoundF(-off / 30.0);
    while clock <= 0 {
      clock += 12;
    }
    while clock > 12 {
      clock -= 12;
    }
    CMInk.Text(txt, CMText.MhudClockDist(IntToString(clock), IntToString(RoundF(c.dist))));
    plate.SetVisible(true);
  }

  public func Refresh(s: ref<CMPilotHudState>) -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    this.m_mtLast = s;
    let mn = this.m_mtStyle != 0;
    CMInk.Text(this.m_mtTitle, s.title);
    this.m_mtSignal = s.signal;
    if this.m_mtStyle == 2 {
      this.MnUplink(s.signal);
      CMInk.Text(this.m_mtOp, CMText.MhudOperatorRange(FloatToStringPrec(s.distance / 1000.0, 1)));
    } else {
      CMInk.Text(this.m_mtLink, IntToString(RoundF(s.signal * 100.0)) + "%");
      this.m_mtLink.SetTintColor(s.signal < 0.25 ? this.m_mtPal.hostile : this.m_mtPal.primary);
      CMInk.Text(this.m_mtOp, CMText.MhudOperatorDist(IntToString(RoundF(s.distance))));
    }
    if ArraySize(s.parts) > 0 {
      this.MtSensor(s.parts[CMPart.Sensor()]);
    }
    CMInk.Text(this.m_mtHdg, this.m_mtSensor <= 0.0 ? "---" : (mn ? CMPilotHud.Pad3(s.heading) : CMPilotHud.Pad3(s.heading) + "  " + CMPilotHud.Cardinal(s.heading)));
    CMInk.Text(this.m_mtGnd, CMText.MhudGnd(FloatToStringPrec(s.speed * 3.6, 1)));
    if this.m_mtSensor < 0.5 && RandF() < (this.m_mtSensor <= 0.0 ? 0.05 : 0.025) {
      this.MtStatic();
    }
    if mn {
      CMInk.Text(this.m_mtRange, s.range > 0.0 ? CMPilotHud.Pad3(RoundF(s.range)) : "---");
    } else {
      CMInk.Text(this.m_mtRange, s.range > 0.0 ? CMText.MhudRng(CMPilotHud.Pad4(RoundF(s.range))) : CMText.MhudRng("----"));
    }
    CMInk.Text(this.m_mtZoom, s.zoomed ? CMText.PhudOptics25() : "");

    let low = s.integrity < 0.3;
    CMInk.Text(this.m_mtHullPct, IntToString(RoundF(s.integrity * 100.0)) + (mn ? "" : "%") + (low ? "  " + CMText.PhudCritical() : ""));
    this.m_mtHullPct.SetTintColor(low ? this.m_mtPal.hostile : this.m_mtPal.primary);
    this.m_mtHull.Set(s.integrity, low ? this.m_mtPal.hostile : (s.integrity < 0.6 ? this.m_mtPal.warn : this.m_mtPal.primary));

    if ArraySize(s.parts) == CMPart.Count() {
      let sum = 0.0;
      let i = 0;
      while i < ArraySize(s.parts) {
        this.MtPart(i, s.parts[i]);
        sum += ClampF(s.parts[i], 0.0, 1.0);
        i += 1;
      }
      let mean = sum / Cast<Float>(CMPart.Count());
      if IsDefined(this.m_mtArmourArc) {

        let ac = mean < 0.5 ? this.m_mtPal.hostile : (mean < 0.8 ? this.m_mtPal.warn : this.m_mtPal.primary);
        this.m_mtArmourArc.Set(mean, ac);
        CMInk.Text(this.m_mtArmour, IntToString(RoundF(mean * 100.0)));
        this.m_mtArmour.SetTintColor(ac);
        this.MnZoneMarks(s.parts);
      } else {
        CMInk.Text(this.m_mtArmour, CMText.MhudArmour(IntToString(RoundF(mean * 100.0))));
      }
    }

    if ArraySize(this.m_mtGunNames) == 2 {
      if StrLen(s.gunNameL) > 0 {
        CMInk.Text(this.m_mtGunNames[0], mn ? s.gunNameL : CMText.PhudSideL() + "  " + s.gunNameL);
      }
      if StrLen(s.gunNameR) > 0 {
        CMInk.Text(this.m_mtGunNames[1], mn ? s.gunNameR : CMText.PhudSideR() + "  " + s.gunNameR);
      }
    }
    if IsDefined(this.m_mtSecName) && !mn {
      CMInk.Text(this.m_mtSecName, StrLen(s.secName) > 0 ? s.secName : CMText.MhudSecondary());
    }
    this.MtGun(0, s.heatL, s.lockedL, s.hasL, s.lostL, s.range);
    this.MtGun(1, s.heatR, s.lockedR, s.hasR, s.lostR, s.range);
    CMInk.Text(this.m_mtMode, CMFireMode.Name(s.fireMode));
    let split = s.fireMode == CMFireMode.Split();
    if NotEquals(split, this.m_mtSplit) {
      this.m_mtSplit = split;
      this.MtKeys();
    }
    CMInk.Text(this.m_mtMsl, StrLen(s.missile) > 0 ? CMPilotHud.MslText(s.missile, mn) : CMText.MhudNone());
    if mn {
      let rain = StrContains(s.missile, "READY");
      if rain && !this.m_mtRainWas {
        this.MnRaise(6, 4.0);
      }
      this.m_mtRainWas = rain;
      if s.signal < 0.25 {
        this.MnRaise(5, 1.0);
      }
      this.m_mtMsl.SetTintColor(StrContains(s.missile, "READY") ? this.m_mtPal.accent : this.m_mtPal.warn);
    } else {
      this.m_mtMsl.SetTintColor(StrContains(s.missile, "READY") ? this.m_mtPal.primary : this.m_mtPal.accent);
    }

    this.m_mtWarning = s.warning;
    this.MtBand();
  }

  private func MnZoneMarks(parts: array<Float>) -> Void {
    let i = 0;
    while i < ArraySize(parts) && i < ArraySize(this.m_mtZoneMarks) {
      let m = this.m_mtZoneMarks[i];
      if IsDefined(m) {
        let hp = ClampF(parts[i], 0.0, 1.0);
        m.SetVisible(hp < 0.8);
        if hp < 0.8 {
          m.SetTintColor(hp <= 0.0 ? this.m_mtPal.broken : (hp < 0.5 ? this.m_mtPal.hostile : this.m_mtPal.warn));
          let fill = m.GetWidgetByIndex(1);
          if IsDefined(fill) {
            fill.SetVisible(hp < 0.5);
          }
        }
      }
      i += 1;
    }
  }

  private func MnUplink(signal: Float) -> Void {
    let q = ClampF(signal, 0.0, 1.0);
    let p = this.m_mtPal;
    if q < 0.25 {
      CMInk.Text(this.m_mtLink, CMText.MhudUplinkWeak());
      this.m_mtLink.SetTintColor(p.hostile);
    } else if q < 0.5 {
      CMInk.Text(this.m_mtLink, CMText.MhudUplinkDegraded());
      this.m_mtLink.SetTintColor(p.warn);
    } else {
      CMInk.Text(this.m_mtLink, CMText.MhudUplinkLocked());
      this.m_mtLink.SetTintColor(p.primary);
    }
    if IsDefined(this.m_mtLat) {
      let lat = RoundF(28.0 + (1.0 - q) * 140.0 + RandRangeF(0.0, 9.0));
      let loss = (1.0 - q) * 5.0 + RandRangeF(0.0, 0.4);
      CMInk.Text(this.m_mtLat, CMText.MhudLat(CMPilotHud.Pad3(lat), FloatToStringPrec(loss, 1), FloatToStringPrec(2.0 + 6.0 * q, 1)));
    }
    let lit = CeilF(q * 5.0);
    let i = 0;
    while i < ArraySize(this.m_mtSigBars) {
      let on = i < lit;
      this.m_mtSigBars[i].SetTintColor(on ? (q < 0.25 ? p.hostile : p.accent) : p.dim);
      this.m_mtSigBars[i].SetOpacity(on ? 0.9 : 0.35);
      i += 1;
    }
  }

  private func MtGun(i: Int32, heat: Float, locked: Bool, has: Bool, lost: Bool, range: Float) -> Void {
    if i >= ArraySize(this.m_mtGunState) {
      return;
    }
    let hot = heat > 0.6;
    let st = this.m_mtGunState[i];
    if this.m_mtStyle != 0 {
      if !has {
        CMInk.Text(st, lost ? CMText.MhudOffline() : CMText.PhudNoWeapon());
        st.SetTintColor(this.m_mtPal.hostile);
      } else if locked {
        CMInk.Text(st, CMText.MhudOvertemp());
        st.SetTintColor(this.m_mtPal.hostile);
      } else if hot {
        CMInk.Text(st, CMText.MhudHot());
        st.SetTintColor(this.m_mtPal.warn);
      } else {
        CMInk.Text(st, this.m_mtTracking ? CMText.MhudTracking() : "");
        st.SetTintColor(this.m_mtPal.accent);
      }
      return;
    }
    if !has {
      CMInk.Text(st, lost ? CMText.PhudMk31Offline() : CMText.PhudNoWeapon());
      st.SetTintColor(this.m_mtPal.hostile);
      this.m_mtGunPlates[i].SetTintColor(this.m_mtPal.hostile);
      return;
    }
    if locked {
      CMInk.Text(st, CMText.MhudOvertempLocked());
      st.SetTintColor(this.m_mtPal.hostile);
      this.m_mtGunPlates[i].SetTintColor(this.m_mtPal.hostile);
    } else {
      if hot {
        CMInk.Text(st, CMText.MhudHeatWarning());
        st.SetTintColor(this.m_mtPal.accent);
      } else {
        CMInk.Text(st, this.m_mtTracking ? CMText.MhudGunsOnTarget() : (range > 0.0 ? CMText.MhudConverged(IntToString(RoundF(range))) : CMText.PhudArmed()));
        st.SetTintColor(this.m_mtPal.dim);
      }
      this.m_mtGunPlates[i].SetTintColor(hot ? this.m_mtPal.accent : this.m_mtPal.primary);
    }
  }

  private func MtPart(i: Int32, hp: Float) -> Void {
    if i >= ArraySize(this.m_mtParts) || !IsDefined(this.m_mtParts[i]) {
      return;
    }
    let p = this.m_mtParts[i];
    if AbsF(hp - p.hp) < 0.01 {
      return;
    }
    let broke = hp <= 0.0 && p.hp > 0.0;
    p.hp = hp;
    let color = hp <= 0.0 ? this.m_mtPal.broken : (hp < 0.5 ? this.m_mtPal.hostile : (hp < 0.8 ? this.m_mtPal.warn : this.m_mtPal.primary));
    p.image.SetTintColor(color);
    p.image.SetOpacity(hp <= 0.0 ? 0.7 : 1.0);
    if i < ArraySize(this.m_mtZoneBars) {
      this.m_mtZoneBars[i].Set(hp, color);
    }
    if broke {
      let blink = new inkAnimDef();
      let t = 0.0;
      while t < 2.0 {
        blink.AddInterpolator(CMPilotHud.Fade(1.0, 0.2, 0.2, t));
        blink.AddInterpolator(CMPilotHud.Fade(0.2, 1.0, 0.2, t + 0.2));
        t += 0.4;
      }
      p.canvas.PlayAnimation(blink);
    }
  }

  private func MtSensor(hp: Float) -> Void {
    let was = this.m_mtSensor;
    this.m_mtSensor = hp;
    if NotEquals(hp <= 0.0, was <= 0.0) {
      this.m_mtTape.SetVisible(hp > 0.0);
    }
  }

  private func MtStatic() -> Void {
    let def = new inkAnimDef();
    def.AddInterpolator(CMPilotHud.Fade(1.0, 0.15, 0.03, 0.0));
    def.AddInterpolator(CMPilotHud.Fade(0.15, 0.8, 0.05, 0.03));
    def.AddInterpolator(CMPilotHud.Fade(0.8, 0.3, 0.04, 0.08));
    def.AddInterpolator(CMPilotHud.Fade(0.3, 1.0, 0.1, 0.12));
    let move = new inkAnimTranslation();
    move.SetStartTranslation(Vector2(RandRangeF(-18.0, 18.0), RandRangeF(-6.0, 6.0)));
    move.SetEndTranslation(Vector2(0.0, 0.0));
    move.SetDuration(0.2);
    def.AddInterpolator(move);
    this.m_mtRoot.PlayAnimation(def);
  }

  private func MtBand() -> Void {
    let warn = StrLen(this.m_mtWarning) > 0;
    let on = warn || this.m_mtBandT > 0.0;
    if on {
      CMInk.Text(this.m_mtBandText, warn ? this.m_mtWarning : (this.m_mtStyle != 0 ? CMText.MhudIncoming() : CMText.MhudIncomingFrontal()));
    }
    if Equals(on, this.m_mtBandOn) {
      return;
    }
    this.m_mtBandOn = on;
    this.m_mtBand.SetVisible(on);
    if on {
      this.m_mtBandPulse = CMPilotHud.Loop(this.m_mtBand, 1.0, 0.6, 0.35);
    } else {
      if IsDefined(this.m_mtBandPulse) {
        this.m_mtBandPulse.Stop();
      }
      this.m_mtBandPulse = null;
      this.m_mtBand.SetOpacity(1.0);
    }
  }

  public func Damage(lost: Float) -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    let k = ClampF(lost * 12.0, 0.25, 1.0);
    let jolt = new inkAnimDef();
    let move = new inkAnimTranslation();
    move.SetStartTranslation(Vector2(RandRangeF(-30.0, 30.0) * k, RandRangeF(-12.0, 12.0) * k));
    move.SetEndTranslation(Vector2(0.0, 0.0));
    move.SetDuration(0.14 + 0.12 * k);
    move.SetType(inkanimInterpolationType.Quadratic);
    move.SetMode(inkanimInterpolationMode.EasyOut);
    jolt.AddInterpolator(move);
    this.m_mtFace.PlayAnimation(jolt);
    let flash = new inkAnimDef();
    flash.AddInterpolator(CMPilotHud.Fade(0.25 + 0.5 * k, 0.0, 0.35 + 0.35 * k, 0.0));
    this.m_mtHurt.PlayAnimation(flash);
    this.m_mtBandT = this.MT_BAND;
    this.MtBand();
  }

  public func HitFrom(off: Float) -> Void {
    if !IsDefined(this.m_mtRoot) || ArraySize(this.m_mtHitDirs) == 0 || this.m_mtSensor <= 0.0 {
      return;
    }
    let m = this.m_mtHitDirs[this.m_mtHitNext];
    this.m_mtHitNext = (this.m_mtHitNext + 1) % ArraySize(this.m_mtHitDirs);
    let a = Deg2Rad(off);
    let dx = -SinF(a);
    let dy = -CosF(a);
    m.SetMargin(inkMargin(this.m_mtW * 0.5 + dx * 330.0 - 40.0, 1080.0 + dy * 330.0 - 48.0, 0.0, 0.0));
    m.SetRotation(Rad2Deg(AtanF(dy, dx)));
    let fade = new inkAnimDef();
    fade.AddInterpolator(CMPilotHud.Fade(1.0, 1.0, 0.35, 0.0));
    fade.AddInterpolator(CMPilotHud.Fade(1.0, 0.0, 0.8, 0.35));
    m.PlayAnimation(fade);
  }

  public func StartBoot() -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    this.m_mtBootT = this.MT_BOOT;
    this.m_mtBootStage = -1;
    this.m_mtBoot.SetVisible(true);
  }

  public func Boot(dt: Float) -> Void {
    if this.m_mtBootT <= 0.0 || !IsDefined(this.m_mtRoot) {
      return;
    }
    this.m_mtBootT -= dt;
    let elapsed = this.MT_BOOT - this.m_mtBootT;
    if this.m_mtBootT <= 0.0 {
      this.m_mtBoot.SetVisible(false);
      this.m_mtRoot.SetOpacity(1.0);
      return;
    }
    this.m_mtRoot.SetOpacity(elapsed < 0.5 ? RandRangeF(0.3, 1.0) : 1.0);
    let stage = FloorF(elapsed / 0.3);
    if stage != this.m_mtBootStage {
      this.m_mtBootStage = stage;
      if this.m_mtStyle == 2 {

        let feed = CMText.MhudFeedEstablishing();
        if stage >= 1 { feed += "\n" + CMText.MhudFeedHandshake(); }
        if stage >= 2 { feed += "\n" + CMText.MhudFeedCamera(); }
        if stage >= 3 { feed += "\n" + CMText.MhudFeedActuators(); }
        if stage >= 4 { feed += "\n" + CMText.MhudFeedArms(); }
        if stage >= 5 { feed += "\n" + CMText.MhudFeedLocked(); }
        CMInk.Text(this.m_mtBoot, feed);
        return;
      }
      let text = this.m_mtStyle == 1 ? CMText.MhudBootTactical() : CMText.PhudBootColdStart();
      if stage >= 1 { text += "\n" + CMText.PhudBootUplink(); }
      if stage >= 2 { text += "\n" + CMText.PhudBootChassis(); }
      if stage >= 3 { text += "\n" + CMText.PhudBootGuns(); }
      if stage >= 4 { text += "\n" + CMText.MhudBootTracking(); }
      if stage >= 5 { text += "\n" + CMText.PhudBootControl(); }
      CMInk.Text(this.m_mtBoot, text);
    }
  }

  public func PartHit(i: Int32) -> Void {
    if !IsDefined(this.m_mtRoot) || i < 0 || i >= ArraySize(this.m_mtParts) || !IsDefined(this.m_mtParts[i]) {
      return;
    }
    let flash = new inkAnimDef();
    flash.AddInterpolator(CMPilotHud.Fade(0.2, 1.0, 0.3, 0.0));
    this.m_mtParts[i].canvas.PlayAnimation(flash);
  }

  public func Flash(left: Bool, right: Bool) -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    if NotEquals(left, this.m_mtFlashL) {
      this.m_mtFlashL = left;
      this.MtPipLook(this.m_mtPipL, this.m_mtLaidL, left);
    }
    if NotEquals(right, this.m_mtFlashR) {
      this.m_mtFlashR = right;
      this.MtPipLook(this.m_mtPipR, this.m_mtLaidR, right);
    }
  }

  private func MtPipLook(pip: ref<inkCanvas>, laid: Bool, firing: Bool) -> Void {
    pip.SetOpacity(firing ? 1.0 : (laid ? 0.9 : 0.5));
    pip.SetScale(laid ? Vector2(1.0, 1.0) : Vector2(1.3, 1.3));
    pip.SetTintColor(firing ? this.m_mtPal.accent : new HDRColor(1.0, 1.0, 1.0, 1.0));
  }

  public func SetOptics(on: Bool) -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    if !IsDefined(this.m_mtOptics) {
      if !on {
        return;
      }
      let o = new inkCanvas();
      o.SetAnchor(inkEAnchor.Fill);
      o.SetInteractive(false);
      o.Reparent(this.m_mtRoot);
      let cx = this.m_mtW * 0.5;
      let side = MaxF(0.0, cx - 1240.0);
      CMPilotHud.Bar(o, 0.0, 0.0, side, 2160.0, CMPilotHud.Black(), 0.8);
      CMPilotHud.Bar(o, this.m_mtW - side, 0.0, side, 2160.0, CMPilotHud.Black(), 0.8);
      CMKit.Ln(o, cx - 720.0, 1078.0, 460.0, 4.0, this.m_mtPal.primary, 0.6);
      CMKit.Ln(o, cx + 260.0, 1078.0, 460.0, 4.0, this.m_mtPal.primary, 0.6);
      let i = 1;
      while i <= 4 {
        CMPilotHud.Bar(o, cx - 2.0, 1080.0 + 300.0 + Cast<Float>(i) * 40.0, 4.0, 20.0 - Cast<Float>(i) * 2.0, this.m_mtPal.primary, 0.9);
        i += 1;
      }
      this.m_mtOptics = o;
    }
    this.m_mtOptics.SetVisible(on);
  }

  public func Hit(kill: Bool) -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    this.m_mtHitT = kill ? 0.45 : 0.25;
    for d in this.m_mtHitBars {
      d.SetTintColor(kill ? this.m_mtPal.hostile : this.m_mtPal.primary);
      d.SetOpacity(1.0);
    }
  }

  public func FadeHit(dt: Float) -> Void {
    if this.m_mtHitT <= 0.0 {
      return;
    }
    this.m_mtHitT = MaxF(0.0, this.m_mtHitT - dt);
    let a = ClampF(this.m_mtHitT / 0.25, 0.0, 1.0);
    for d in this.m_mtHitBars {
      d.SetOpacity(a);
    }
  }

  public func SetPips(lx: Float, ly: Float, lOn: Bool, rx: Float, ry: Float, rOn: Bool) -> Void {
    if !IsDefined(this.m_mtRoot) {
      return;
    }
    this.m_mtPipL.SetVisible(lOn);
    this.m_mtPipR.SetVisible(rOn);
    let cx = this.m_mtW * 0.5;
    if lOn && (AbsF(lx - this.m_mtPipLX) > 2.0 || AbsF(ly - this.m_mtPipLY) > 2.0) {
      this.m_mtPipLX = lx;
      this.m_mtPipLY = ly;
      this.m_mtPipL.SetMargin(inkMargin(cx + lx - 30.0, 1080.0 + ly - 30.0, 0.0, 0.0));
    }
    if rOn && (AbsF(rx - this.m_mtPipRX) > 2.0 || AbsF(ry - this.m_mtPipRY) > 2.0) {
      this.m_mtPipRX = rx;
      this.m_mtPipRY = ry;
      this.m_mtPipR.SetMargin(inkMargin(cx + rx - 30.0, 1080.0 + ry - 30.0, 0.0, 0.0));
    }
  }

  public func SetGunState(lockedL: Bool, heatL: Float, lockedR: Bool, heatR: Float) -> Void {
    if !IsDefined(this.m_mtRoot) || ArraySize(this.m_mtHeat) < 2 {
      return;
    }
    if NotEquals(lockedL, this.m_mtLaidL) {
      this.m_mtLaidL = lockedL;
      this.MtPipLook(this.m_mtPipL, lockedL, this.m_mtFlashL);
      CMInk.Text(this.m_mtAim[0], lockedL ? CMText.MhudOnTarget() : CMText.MhudLaying());
      this.m_mtAim[0].SetTintColor(lockedL ? this.m_mtPal.primary : this.m_mtPal.dim);
    }
    if NotEquals(lockedR, this.m_mtLaidR) {
      this.m_mtLaidR = lockedR;
      this.MtPipLook(this.m_mtPipR, lockedR, this.m_mtFlashR);
      CMInk.Text(this.m_mtAim[1], lockedR ? CMText.MhudOnTarget() : CMText.MhudLaying());
      this.m_mtAim[1].SetTintColor(lockedR ? this.m_mtPal.primary : this.m_mtPal.dim);
    }
    this.MtHeat(0, heatL);
    this.MtHeat(1, heatR);
  }

  private func MtHeat(i: Int32, heat: Float) -> Void {
    let hot = heat > 0.6;
    let mn = this.m_mtStyle != 0;
    let c = heat > 0.85 ? this.m_mtPal.hostile : (hot ? this.m_mtPal.warn : (mn ? this.m_mtPal.accent : this.m_mtPal.primary));
    this.m_mtHeat[i].Set(heat, c);
    let n = RoundF(ClampF(heat, 0.0, 1.0) * 100.0);
    let key = n * 4 + (heat > 0.85 ? 2 : (hot ? 1 : 0));
    if ArraySize(this.m_mtHeatKey) < 2 {
      ArrayResize(this.m_mtHeatKey, 2);
      this.m_mtHeatKey[0] = -1;
      this.m_mtHeatKey[1] = -1;
    }
    if key == this.m_mtHeatKey[i] {
      return;
    }
    this.m_mtHeatKey[i] = key;
    let pct = IntToString(n);
    CMInk.Text(this.m_mtHeatPct[i], mn ? (i == 0 ? CMText.PhudSideL() : CMText.PhudSideR()) + " " + pct : pct + "%");
    this.m_mtHeatPct[i].SetTintColor(c);
  }
}
