module ControllableMechs

import TerminalKit.*
import ControllableMechs.Control.*
import Codeware.UI.*

public abstract class CMConLive extends TKCustom {
  protected let m_alive: Bool;
  protected let m_gen: Int32;
  protected let m_view: wref<TKView>;
  protected let m_con: wref<CMContent>;

  protected func Begin(period: Float) -> Void {
    this.m_alive = true;
    this.m_gen += 1;
    this.Later(period);
  }

  protected func Later(period: Float) -> Void {
    let cb = new CMConTick();
    cb.live = this;
    cb.gen = this.m_gen;
    cb.period = period;
    GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(cb, period, false);
  }

  public func Fire(gen: Int32, period: Float) -> Void {
    if !this.m_alive || gen != this.m_gen {
      return;
    }
    this.Tick();
    if this.m_alive {
      this.Later(period);
    }
  }

  protected func Tick() -> Void {}

  public func Stop() -> Void {
    this.m_alive = false;
    this.m_gen += 1;
  }
}

public class CMConTick extends DelayCallback {
  public let live: wref<CMConLive>;
  public let gen: Int32;
  public let period: Float;

  public func Call() -> Void {
    if IsDefined(this.live) {
      this.live.Fire(this.gen, this.period);
    }
  }
}

public abstract class CMConRoot {
  public static func Make(parent: ref<inkCompoundWidget>, w: Float, h: Float) -> ref<inkCanvas> {
    let root = new inkCanvas();
    root.SetSize(Vector2(w, h));
    root.SetAnchor(inkEAnchor.TopLeft);
    root.Reparent(parent);
    return root;
  }
}

public class CMConRibbon extends CMConLive {
  private let m_funds: wref<inkText>;
  private let m_wave: array<wref<inkRectangle>>;
  private let m_phase: Float;
  private let m_keysOn: Bool;
  private let m_upText: wref<inkText>;
  private let m_upDot: wref<inkRectangle>;

  public static func Uplink(link: ref<CMLinkSystem>) -> String {
    if !link.IsLinked() {
      return CMText.ViewStandby();
    }
    return CMText.ViewUplinkSecure(IntToString(RoundF(ClampF(link.SignalFraction(), 0.0, 1.0) * 100.0)));
  }

  public static func Make(c: ref<CMContent>, v: ref<TKView>, parent: ref<inkCompoundWidget>, w: Float, h: Float) -> ref<CMConRibbon> {
    let r = new CMConRibbon();
    r.m_view = v;
    r.m_con = c;
    r.Draw(c, CMConRoot.Make(parent, w, h), w, h);
    r.Begin(0.1);
    r.Keys(true);
    return r;
  }

  private func Draw(c: ref<CMContent>, root: ref<inkCanvas>, w: Float, h: Float) -> Void {
    let game = c.game;
    CMCon.Rect(root, 0.0, 0.0, w, h, CMConPal.Panel(), CMCon.Fill());
    CMCon.Scan(root, w, h);
    CMCon.Frame(root, 0.0, 0.0, w, h, 2.0, CMConPal.Line(), 1.0);

    let plateW = 760.0;
    let plate = CMInk.FillBars(root, 48, CMConPal.Panel2(), 1.0);
    CMInk.FillPoly(plate, [Vector2(0.0, 0.0), Vector2(plateW, 0.0), Vector2(plateW - 48.0, h), Vector2(0.0, h)]);
    CMInk.Line(root, plateW, 0.0, plateW - 48.0, h, 5.0, CMConPal.Amber(), 1.0);
    CMCon.Txt(root, 40.0, h * 0.5 - 40.0, CMText.ViewRegisSoftware(), 0, 50, CMConPal.Ink(), 0);
    let tri = CMInk.FillBars(root, 8, CMConPal.Amber(), 1.0);
    CMInk.FillPoly(tri, [Vector2(42.0, h * 0.5 + 22.0), Vector2(56.0, h * 0.5 + 31.0), Vector2(42.0, h * 0.5 + 40.0)]);
    CMCon.Txt(root, 68.0, h * 0.5 + 18.0, CMText.ViewPropertyOfMilitech(), 2, 24, CMConPal.Amber(), 0);

    let x = plateW + 10.0;

    x = this.Cell(root, x, h, 340.0, CMText.ViewFunds());
    let player = GetPlayer(game);
    this.m_funds = CMCon.Txt(root, x - 340.0 + 28.0, 62.0, CMCon.Money(CMFleet.Eddies(player)) + " E$", 2, 40, CMConPal.Ink(), 0);

    x = this.Cell(root, x, h, 340.0, CMText.ViewUplink());
    let link = CMLinkSystem.Get(game);
    ArrayClear(this.m_wave);
    let ux = x - 340.0 + 28.0;
    this.m_upDot = CMCon.Rect(root, ux, 80.0, 14.0, 14.0, link.IsLinked() ? CMConPal.Cyan() : CMConPal.Steel(), 1.0);
    this.m_upText = CMCon.Txt(root, ux + 26.0, 66.0, CMConRibbon.Uplink(link), 2, 34, link.IsLinked() ? CMConPal.Cyan() : CMConPal.Steel(), 0);

    x = this.Cell(root, x, h, 300.0, CMText.ViewFleet());
    let bays = CMConsole.Bays(game);
    let owned = 0;
    let ready = 0;
    for b in bays {
      if b.owned {
        owned += 1;
        if Equals(b.st, "ok") || Equals(b.st, "live") {
          ready += 1;
        }
      }
    }
    let cellX = x - 300.0 + 28.0;
    let segW = owned > 0 ? MinF(40.0, (244.0 - Cast<Float>(owned - 1) * 6.0) / Cast<Float>(owned)) : 40.0;
    let sx = cellX;
    for b in bays {
      if b.owned {
        let col = Equals(b.st, "ok") || Equals(b.st, "live") ? CMConPal.Green() : CMConPal.State(b.st);
        CMCon.Rect(root, sx, 66.0, segW, 14.0, col, 1.0);
        sx += segW + 6.0;
      }
    }
    CMCon.Txt(root, cellX, 88.0, CMText.ViewFleetReady(IntToString(ready), IntToString(owned)), 2, 24, CMConPal.Ink(), 0);

    x = this.Cell(root, x, h, 280.0, CMText.ViewLink());
    CMCon.Txt(root, x - 280.0 + 28.0, 62.0, link.IsLinked() ? CMText.ViewOnline() : CMText.ViewOffline(), 2, 40, link.IsLinked() ? CMConPal.Cyan() : CMConPal.Steel(), 0);

    CMCon.Txt(root, x + 28.0, 30.0, CMText.ViewOpsFeed(), 2, 22, CMConPal.Steel(), 0);
    let feed = "";
    let con = c.Con();
    for line in con.feed {
      feed += (StrLen(feed) > 0 ? "     ·     " : "") + line;
    }
    if StrLen(feed) == 0 {
      feed = CMText.ViewFeedIdle(IntToString(ArraySize(bays)));
    }
    let clipW = w - x - 40.0;
    let clip = new inkScrollArea();
    clip.SetAnchor(inkEAnchor.TopLeft);
    clip.SetFitToContentDirection(inkFitToContentDirection.None);
    clip.SetConstrainContentPosition(false);
    clip.SetUseInternalMask(true);
    clip.SetSize(Vector2(clipW, 44.0));
    clip.SetMargin(inkMargin(x + 28.0, 66.0, 0.0, 0.0));
    clip.Reparent(root);
    let inner = new inkCanvas();
    inner.SetSize(Vector2(clipW, 44.0));
    inner.Reparent(clip);
    let run = CMCon.Txt(inner, 0.0, 0.0, feed, 2, 28, CMConPal.Amber(), 0);
    let tw = CMCon.TextW(feed, 28);
    let move = new inkAnimTranslation();
    move.SetStartTranslation(Vector2(clipW * 0.3, 0.0));
    move.SetEndTranslation(Vector2(-tw, 0.0));
    move.SetDuration((tw + clipW * 0.3) / 110.0);
    move.SetType(inkanimInterpolationType.Linear);
    let def = new inkAnimDef();
    def.AddInterpolator(move);
    let opt: inkAnimOptions;
    opt.loopType = inkanimLoopType.Cycle;
    opt.loopInfinite = true;
    run.PlayAnimationWithOptions(def, opt);
  }

  private func Cell(root: ref<inkCanvas>, x: Float, h: Float, w: Float, cap: String) -> Float {
    CMCon.Txt(root, x + 28.0, 30.0, cap, 2, 22, CMConPal.Steel(), 0);
    CMCon.Rect(root, x + w - 2.0, 0.0, 2.0, h, CMConPal.Line(), 1.0);
    return x + w;
  }

  protected func Tick() -> Void {
    let game = GetGameInstance();
    let link = CMLinkSystem.Get(game);
    let sig = link.IsLinked() ? MaxF(0.15, link.SignalFraction()) : 0.04;
    this.m_phase += 0.45;
    let i = 0;
    while i < ArraySize(this.m_wave) {
      let b = this.m_wave[i];
      if IsDefined(b) {
        let f = Cast<Float>(i);
        let a = AbsF(SinF(f * 0.55 + this.m_phase) * SinF(f * 0.13 + this.m_phase * 0.31));
        let hh = 4.0 + 44.0 * a * sig;
        b.SetMargin(inkMargin(b.GetMargin().left, 92.0 - hh * 0.5, 0.0, 0.0));
        b.SetSize(Vector2(4.0, hh));
      }
      i += 1;
    }
    if IsDefined(this.m_funds) {
      this.m_funds.SetText(CMCon.Money(CMFleet.Eddies(GetPlayer(game))) + " E$");
    }
    if IsDefined(this.m_upText) {
      this.m_upText.SetText(CMConRibbon.Uplink(link));
      let on = link.IsLinked();
      this.m_upText.SetTintColor(on ? CMConPal.Cyan() : CMConPal.Steel());
      this.m_upDot.SetTintColor(on ? CMConPal.Cyan() : CMConPal.Steel());
      this.m_upDot.SetOpacity(on ? 0.55 + 0.45 * AbsF(SinF(this.m_phase * 0.6)) : 1.0);
    }
  }

  private func Keys(on: Bool) -> Void {
    if Equals(on, this.m_keysOn) {
      return;
    }
    this.m_keysOn = on;
    let cbs = GameInstance.GetCallbackSystem();
    if on {
      cbs.RegisterCallback(n"Input/Key", this, n"OnConKey");
    } else {
      cbs.UnregisterCallback(n"Input/Key", this, n"OnConKey");
    }
  }

  protected cb func OnConKey(event: ref<KeyInputEvent>) -> Void {
    if !this.m_alive || !Equals(event.GetAction(), EInputAction.IACT_Press) || !IsDefined(this.m_view) {
      return;
    }
    let state = CMTerminalState.Get(GetGameInstance());
    if IsDefined(state) && IsDefined(state.open) && state.open.IsTyping() {
      return;
    }
    let player = GetPlayer(GetGameInstance());
    let k = event.GetKey();
    if Equals(k, CMKeys.ConDeploy(player)) {
      this.m_view.Act("con_deploy", "");
    } else {
      if Equals(k, CMKeys.ConRecall(player)) {
        this.m_view.Act("con_recall", "");
      } else {
        if Equals(k, CMKeys.ConMap(player)) {
          this.m_view.Act("con_map", "");
        } else {
          if Equals(k, CMKeys.ConReq(player)) {
            this.m_view.Act("con_req", "");
          }
        }
      }
    }
  }

  public func Stop() -> Void {
    this.Keys(false);
    super.Stop();
  }
}

public class CMConRack extends TKCustom {
  public static func Make(c: ref<CMContent>, v: ref<TKView>, parent: ref<inkCompoundWidget>, w: Float, h: Float) -> ref<CMConRack> {
    let r = new CMConRack();
    let root = CMConRoot.Make(parent, w, h);
    let game = c.game;
    let con = c.Con();
    CMCon.Pane(root, w, h, true);
    CMCon.Txt(root, 26.0, 22.0, CMText.ViewBays(), 2, 22, CMConPal.Steel(), 0);
    let bays = CMConsole.Bays(game);
    con.sel = Clamp(con.sel, 0, ArraySize(bays) - 1);
    let y = 64.0;
    let cardH = 156.0;
    let i = 0;
    while i < ArraySize(bays) {
      r.Card(v, root, bays[i], i, 22.0, y, w - 44.0, cardH, i == con.sel);
      y += cardH + 14.0;
      i += 1;
    }

    if y + cardH * 0.7 < h - 20.0 {
      let ey = y;
      CMCon.Rect(root, 22.0, ey, w - 44.0, cardH * 0.7, CMConPal.Panel2(), 0.6);
      CMCon.Dashed(root, 22.0, ey, w - 44.0, cardH * 0.7, CMConPal.Line2(), 1.0);
      CMCon.Txt(root, w * 0.5, ey + 18.0, CMText.ViewBayEmpty(IntToString(ArraySize(bays) + 1)), 2, 22, CMConPal.Steel(), 1);
      CMCon.Txt(root, w * 0.5, ey + 52.0, CMText.ViewOpenRequisition(), 1, 28, CMConPal.Steel(), 1);
      v.Hit(CMCon.HitArea(root, 22.0, ey, w - 44.0, cardH * 0.7), "con_req", "units", "");
    }
    return r;
  }

  private func Card(v: ref<TKView>, root: ref<inkCanvas>, b: ref<CMConBay>, i: Int32, x: Float, y: Float, w: Float, h: Float, sel: Bool) -> Void {
    let col = CMConPal.State(b.st);
    CMCon.Rect(root, x, y, w, h, CMConPal.Panel2(), CMCon.Fill2());
    CMCon.Frame(root, x, y, w, h, 2.0, sel ? CMConPal.Amber() : CMConPal.Line(), 1.0);
    if sel {
      CMCon.Rect(root, x, y, 7.0, h, CMConPal.Amber(), 1.0);
    }

    let t = h - 32.0;
    CMCon.Frame(root, x + 16.0, y + 16.0, t, t, 2.0, CMConPal.Line(), 1.0);
    CMPilotHud.Img(root, inkEAnchor.TopLeft, x + 22.0, y + 22.0, t - 12.0, t - 12.0, CMApi.WireframeAtlas(), StringToName(b.kind), col, 1.0);
    let tx = x + t + 36.0;
    CMCon.Txt(root, tx, y + 14.0, b.id + "  ·  " + StrUpper(b.kind), 2, 20, CMConPal.Steel(), 0);
    CMCon.Txt(root, tx, y + 40.0, b.name, 0, 30, CMConPal.Ink(), 0);
    CMCon.Stamp(root, tx, y + 84.0, b.stamp, col, 18);
    CMCon.Segs(root, tx, y + h - 24.0, w - (tx - x) - 20.0, 8.0, b.hull, col);
    v.Hit(CMCon.HitArea(root, x, y, w, h), "con_sel", IntToString(i), "");
  }
}

public class CMConStage extends CMConLive {
  private let m_ids: array<String>;
  private let m_layers: array<wref<inkImage>>;
  private let m_layerPart: array<String>;
  private let m_layerCol: array<HDRColor>;
  private let m_tagEdges: array<ref<inkRectangle>>;
  private let m_sel: String;

  public static func Make(c: ref<CMContent>, v: ref<TKView>, parent: ref<inkCompoundWidget>, w: Float, h: Float) -> ref<CMConStage> {
    let s = new CMConStage();
    s.m_view = v;
    s.m_con = c;
    let con = c.Con();
    con.stage = s;
    s.Draw(c, v, CMConRoot.Make(parent, w, h), w, h);
    return s;
  }

  private func Draw(c: ref<CMContent>, v: ref<TKView>, root: ref<inkCanvas>, w: Float, h: Float) -> Void {
    let game = c.game;
    let con = c.Con();
    let b = CMConsole.Selected(game, con);
    CMCon.Rect(root, 0.0, 0.0, w, h, CMConPal.Panel(), CMCon.Fill());
    CMCon.Frame(root, 0.0, 0.0, w, h, 2.0, CMConPal.Line(), 1.0);

    let crumbH = 64.0;
    CMCon.Rect(root, 0.0, crumbH - 2.0, w, 2.0, CMConPal.Line(), 1.0);
    if !IsDefined(b) {

      CMCon.Txt(root, 28.0, 18.0, CMText.ViewMotorPool(), 2, 24, CMConPal.Steel(), 0);
      CMCon.Txt(root, w * 0.5, crumbH + (h - crumbH) * 0.5 - 34.0, CMText.ViewNoUnitsYet(), 0, 52, CMConPal.Ink(), 1);
      return;
    }
    let modes = [CMText.ViewStatus(), CMText.ViewLoadout(), CMText.ViewService(), CMText.ViewDeploy()];
    let crumbs: array<String>;
    ArrayPush(crumbs, b.owned ? b.id : CMText.ViewWild());
    ArrayPush(crumbs, StrUpper(b.kind) + " " + b.name);
    ArrayPush(crumbs, modes[Clamp(con.mode, 0, 3)]);
    if StrLen(con.hp) > 0 {
      for part in CMConsole.Parts(game, b) {
        if Equals(part.id, con.hp) {
          ArrayPush(crumbs, part.key);
        }
      }
    }
    let cx = 28.0;
    let i = 0;
    while i < ArraySize(crumbs) {
      if i > 0 {
        let chev = CMKit.Img(root, n"chev_r", cx, 22.0, 14.0, 20.0, CMConPal.Steel(), 1.0);
        chev.SetVisible(true);
        cx += 32.0;
      }
      CMCon.Txt(root, cx, 18.0, crumbs[i], 2, 24, i == 1 ? CMConPal.Ink() : CMConPal.Steel(), 0);
      cx += CMCon.TextW(crumbs[i], 24) + 24.0;
      i += 1;
    }

    let by = crumbH;
    let bh = h - crumbH;
    let bay = CMCon.Box(root, 0.0, by, w, bh);
    CMCon.Rect(bay, 0.0, 0.0, w, bh, CMConPal.C(7, 11, 12), 1.0);
    let gx = 0.0;
    while gx < w {
      CMCon.Rect(bay, gx, 0.0, 2.0, bh, CMConPal.Line(), 0.7);
      gx += 80.0;
    }
    let gy = 0.0;
    while gy < bh {
      CMCon.Rect(bay, 0.0, gy, w, 2.0, CMConPal.Line(), 0.7);
      gy += 80.0;
    }
    CMKit.Vignette(bay, w, bh, 260.0, 0.75);
    let sweep = CMKit.Img(bay, n"fade", 0.0, -160.0, w, 160.0, CMConPal.Cyan(), 0.10);
    sweep.SetRenderTransformPivot(Vector2(0.5, 0.5));
    sweep.SetRotation(180.0);
    let move = new inkAnimTranslation();
    move.SetStartTranslation(Vector2(0.0, 0.0));
    move.SetEndTranslation(Vector2(0.0, bh + 160.0));
    move.SetDuration(5.0);
    move.SetType(inkanimInterpolationType.Linear);
    let def = new inkAnimDef();
    def.AddInterpolator(move);
    let opt: inkAnimOptions;
    opt.loopType = inkanimLoopType.Cycle;
    opt.loopInfinite = true;
    sweep.PlayAnimationWithOptions(def, opt);

    let parts = CMConsole.Parts(game, b);
    let tagW = 330.0;
    let tagH = 80.0;
    let size = CMConsole.Size(b.kind);
    let room = Vector2(w - (tagW + 90.0) * 2.0, bh - 200.0);
    let k = MinF(room.X / size.X, room.Y / size.Y);
    let sx = (w - size.X * k) * 0.5;
    let sy = by + 60.0 + (room.Y - size.Y * k) * 0.5;
    let unit = CMCon.Box(root, sx, sy, size.X * k, size.Y * k);
    ArrayClear(this.m_layers);
    ArrayClear(this.m_layerPart);
    ArrayClear(this.m_layerCol);
    let atlas = CMConsole.Atlas(b.kind);
    let podOn = b.bay == 0 && CMPartLab.On(CMPilotSystem.Get(game), 0);
    for l in CMConsole.Layers(b.kind) {
      if !l.own || podOn {
      let hp = this.HpOf(parts, l.part, b.hull);
      let col = CMConPal.Health(hp);
      let img = CMPilotHud.Img(unit, inkEAnchor.TopLeft, l.x * k, l.y * k, l.w * k, l.h * k, l.own ? CMConsole.PodAtlas() : atlas, l.tex, col, hp <= 0.0 ? 0.35 : 0.92);
      if hp <= 0.0 {
        CMPilotHud.Loop(img, 0.35, 0.12, 0.9);
      }
      ArrayPush(this.m_layers, img);
      ArrayPush(this.m_layerPart, l.part);
      ArrayPush(this.m_layerCol, col);
      let tip = this.TipOf(parts, l.part);

      if StrLen(tip) > 0 && !Equals(l.part, "body") {
        v.Hit(img, "con_hp", this.TagFor(b.kind, l.part), "", !b.owned);
      }
      }
    }

    let left: array<ref<CMConPart>>;
    let right: array<ref<CMConPart>>;
    let lys: array<Float>;
    let rys: array<Float>;
    for part in parts {
      let l = CMConsole.LayerFor(b.kind, part.id);
      if IsDefined(l) {
        let ay = sy + (l.y + l.h * 0.5) * k;
        if l.x + l.w * 0.5 < size.X * 0.5 {
          ArrayPush(left, part);
          ArrayPush(lys, ay);
        } else {
          ArrayPush(right, part);
          ArrayPush(rys, ay);
        }
      }
    }

    let si = 0;
    while si < ArraySize(lys) {
      let sj = si + 1;
      while sj < ArraySize(lys) {
        if lys[sj] < lys[si] {
          let ty = lys[si];
          lys[si] = lys[sj];
          lys[sj] = ty;
          let tp = left[si];
          left[si] = left[sj];
          left[sj] = tp;
        }
        sj += 1;
      }
      si += 1;
    }
    si = 0;
    while si < ArraySize(rys) {
      let sj = si + 1;
      while sj < ArraySize(rys) {
        if rys[sj] < rys[si] {
          let ty = rys[si];
          rys[si] = rys[sj];
          rys[sj] = ty;
          let tp = right[si];
          right[si] = right[sj];
          right[sj] = tp;
        }
        sj += 1;
      }
      si += 1;
    }
    ArrayClear(this.m_ids);
    ArrayClear(this.m_tagEdges);
    this.m_sel = con.hp;
    this.Column(v, root, b, left, lys, 40.0, tagW, tagH, by + 30.0, h - 120.0, sx, sy, k, true);
    this.Column(v, root, b, right, rys, w - 40.0 - tagW, tagW, tagH, by + 30.0, h - 120.0, sx, sy, k, false);

    CMCon.Txt(root, w - 30.0, by + 22.0, CMText.ViewHullPct(CMCon.Pct(b.hull)), 2, 24, CMConPal.Steel(), 2);
    CMCon.Txt(root, w - 30.0, by + 56.0, b.bay == 0 ? CMText.ViewLiveryName(CMConsole.LiveryName(CMPilotSystem.Get(game).Text("livery", "mnc_default"))) : StrUpper(b.kind), 2, 24, CMConPal.Steel(), 2);
    CMCon.Txt(root, w - 30.0, by + 90.0, this.Where(game, b), 2, 24, CMConPal.Steel(), 2);

    let lx = 30.0;
    let ly = h - 56.0;
    lx = this.Key(root, lx, ly, CMConPal.Cyan(), CMText.ViewNominal(), false);
    lx = this.Key(root, lx, ly, CMConPal.Amber(), CMText.ViewWorn(), false);
    lx = this.Key(root, lx, ly, CMConPal.Red(), CMText.ViewCritical(), false);
    lx = this.Key(root, lx, ly, CMConPal.Red(), CMText.ViewLost(), true);

    if !b.owned {
      CMCon.Txt(root, lx + 10.0, ly, CMText.ViewWildNoRefit(), 2, 22, CMConPal.Steel(), 0);
    }
  }

  private func Column(v: ref<TKView>, root: ref<inkCanvas>, b: ref<CMConBay>, parts: array<ref<CMConPart>>, ys: array<Float>, x: Float, tw: Float, th: Float,
    top: Float, bottom: Float, sx: Float, sy: Float, k: Float, onLeft: Bool) -> Void {
    let n = ArraySize(parts);
    if n == 0 {
      return;
    }
    let gap = MinF(th + 26.0, (bottom - top) / Cast<Float>(n));
    let prev = top - gap;
    let i = 0;
    while i < n {
      let part = parts[i];

      let ty = MaxF(ys[i] - th * 0.5, prev + gap);
      ty = MinF(ty, bottom - Cast<Float>(n - i) * gap);
      ty = MaxF(ty, prev + gap);
      prev = ty;
      let l = CMConsole.LayerFor(b.kind, part.id);
      let ax = sx + (l.x + l.w * 0.5) * k;
      let ay = ys[i];
      let col = part.hp <= 0.0 ? CMConPal.Red() : CMConPal.Health(part.hp);
      let ex = onLeft ? x + tw : x;
      CMInk.Line(root, ax, ay, ex, ty + th * 0.5, 2.0, CMConPal.Steel(), 0.8);
      CMKit.Disc(root, ax, ay, 7.0, col, 1.0);
      CMCon.Rect(root, x, ty, tw, th, CMConPal.Tag(), 1.0);
      let on = Equals(part.id, this.m_sel);
      let edges = CMCon.Frame(root, x, ty, tw, th, 2.0, on ? CMConPal.Amber() : CMConPal.Line2(), 1.0);
      for e in edges {
        ArrayPush(this.m_tagEdges, e);
      }
      ArrayPush(this.m_ids, part.id);
      CMCon.Rect(root, x, ty, 6.0, th, col, 1.0);
      CMCon.Txt(root, x + 22.0, ty + 10.0, part.key, 2, 20, CMConPal.Steel(), 0);
      CMCon.Txt(root, x + 22.0, ty + 38.0, part.name + "  " + (part.hp <= 0.0 ? CMText.ViewLost() : CMCon.Pct(part.hp)), 2, 26, CMConPal.Ink(), 0);
      v.Hit(CMCon.HitArea(root, x, ty, tw, th), "con_hp", part.id, "", !b.owned);
      i += 1;
    }
  }

  private func Key(root: ref<inkCanvas>, x: Float, y: Float, c: HDRColor, label: String, dashed: Bool) -> Float {
    if dashed {
      CMCon.Rect(root, x, y + 4.0, 8.0, 2.0, c, 1.0);
      CMCon.Rect(root, x + 14.0, y + 4.0, 8.0, 2.0, c, 1.0);
      CMCon.Rect(root, x, y + 20.0, 8.0, 2.0, c, 1.0);
      CMCon.Rect(root, x + 14.0, y + 20.0, 8.0, 2.0, c, 1.0);
    } else {
      CMCon.Frame(root, x, y + 4.0, 22.0, 18.0, 2.0, c, 1.0);
    }
    CMCon.Txt(root, x + 32.0, y, label, 2, 22, CMConPal.Steel(), 0);
    return x + 32.0 + CMCon.TextW(label, 22) + 30.0;
  }

  private func HpOf(parts: array<ref<CMConPart>>, id: String, hull: Float) -> Float {
    for p in parts {
      if Equals(p.id, id) {
        return p.hp;
      }
    }

    return hull;
  }

  private func TipOf(parts: array<ref<CMConPart>>, id: String) -> String {
    for p in parts {
      if Equals(p.id, id) {
        return p.key + ": " + p.name;
      }
    }
    return "";
  }

  private func TagFor(kind: String, part: String) -> String = part

  private func Where(game: GameInstance, b: ref<CMConBay>) -> String {
    if !b.out {
      return CMText.ViewMotorPool();
    }
    let unit = b.unit;
    let player = GetPlayer(game);
    if !IsDefined(unit) || !IsDefined(player) {
      return CMText.ViewOutOfRange();
    }
    let dist = IntToString(RoundF(Vector4.Distance(player.GetWorldPosition(), unit.GetWorldPosition())));
    return b.linked ? CMText.ViewLinkedDistFromV(dist) : CMText.ViewDistFromV(dist);
  }

  public func Hover(id: String, over: Bool) -> Void {
    let i = 0;
    while i < ArraySize(this.m_ids) {
      let lit = Equals(this.m_ids[i], id) && over || Equals(this.m_ids[i], this.m_sel);
      let c = lit ? CMConPal.Amber() : CMConPal.Line2();
      let j = 0;
      while j < 4 {
        let e = this.m_tagEdges[i * 4 + j];
        if IsDefined(e) {
          e.SetTintColor(c);
        }
        j += 1;
      }
      i += 1;
    }
    i = 0;
    while i < ArraySize(this.m_layers) {
      let img = this.m_layers[i];
      if IsDefined(img) {
        img.SetTintColor(over && Equals(this.m_layerPart[i], id) ? CMConPal.Amber() : this.m_layerCol[i]);
      }
      i += 1;
    }
  }
}

public class CMConOps extends CMConLive {
  private let m_glows: array<ref<CMHoverGlow>>;
  private let m_timer: wref<inkText>;
  private let m_timerSegs: array<ref<inkRectangle>>;
  private let m_bay: Int32;

  private let m_hold: wref<inkRectangle>;
  private let m_holdW: Float;
  private let m_holding: Bool;
  private let m_holdT: Float;
  private let m_holdOk: Bool;

  public static func Make(c: ref<CMContent>, v: ref<TKView>, parent: ref<inkCompoundWidget>, w: Float, h: Float) -> ref<CMConOps> {
    let o = new CMConOps();
    o.m_view = v;
    o.m_con = c;
    o.Draw(c, v, CMConRoot.Make(parent, w, h), w, h);
    o.Begin(0.05);
    return o;
  }

  private func Draw(c: ref<CMContent>, v: ref<TKView>, root: ref<inkCanvas>, w: Float, h: Float) -> Void {
    let game = c.game;
    let con = c.Con();
    CMCon.Pane(root, w, h, true);
    let b = CMConsole.Selected(game, con);
    if !IsDefined(b) {
      CMCon.Txt(root, w * 0.5, h * 0.5 - 20.0, CMText.ViewNoUnitSelected(), 0, 30, CMConPal.Steel(), 1);
      return;
    }
    this.m_bay = b.bay;

    let names = [CMText.ViewStatus(), CMText.ViewLoadout(), CMText.ViewService(), CMText.ViewDeploy()];
    let tw = w / 4.0;
    let i = 0;
    while i < 4 {
      let off = !b.owned && (i == 1 || i == 2);
      let on = con.mode == i;
      if on {
        CMCon.Rect(root, Cast<Float>(i) * tw, 0.0, tw, 88.0, CMConPal.Panel2(), CMCon.Fill2());
        CMCon.Rect(root, Cast<Float>(i) * tw, 84.0, tw, 4.0, CMConPal.Amber(), 1.0);
      }
      let t = CMCon.Txt(root, Cast<Float>(i) * tw + tw * 0.5, 28.0, names[i], 0, 24, on ? CMConPal.Amber() : CMConPal.Steel(), 1);
      if off {
        t.SetOpacity(0.35);
      }
      v.Hit(CMCon.HitArea(root, Cast<Float>(i) * tw, 0.0, tw, 88.0), "con_mode", IntToString(i), off ? CMText.ViewTipWildPiloted() : "", off);
      i += 1;
    }
    CMCon.Rect(root, 0.0, 88.0, w, 2.0, CMConPal.Line(), 1.0);
    let x = 30.0;
    let y = 118.0;
    let iw = w - 60.0;
    switch con.mode {
      case 1:
        this.Loadout(c, v, root, b, x, y, iw);
        break;
      case 2:
        this.Service(c, v, root, b, x, y, iw);
        break;
      case 3:
        this.Deploy(c, v, root, b, x, y, iw);
        break;
      default:
        this.Status(c, root, b, x, y, iw, h);
        break;
    }
  }

  private func H5(root: ref<inkCanvas>, x: Float, y: Float, text: String) -> Void {
    CMCon.Txt(root, x, y, text, 0, 22, CMConPal.Steel(), 0);
  }

  private func Status(c: ref<CMContent>, root: ref<inkCanvas>, b: ref<CMConBay>, x: Float, y: Float, w: Float, h: Float) -> Void {
    let game = c.game;
    let col = CMConPal.State(b.st);
    CMCon.Ring(root, x + 86.0, y + 86.0, 76.0, 12.0, b.hull, col);
    CMCon.Txt(root, x + 86.0, y + 66.0, CMCon.Pct(b.hull), 2, 34, CMConPal.Ink(), 1);
    CMCon.Txt(root, x + 196.0, y + 14.0, StrUpper(b.kind), 2, 22, CMConPal.Steel(), 0);
    CMCon.Txt(root, x + 196.0, y + 44.0, b.name, 0, 44, CMConPal.Ink(), 0);
    CMCon.Stamp(root, x + 196.0, y + 110.0, b.stamp, col, 20);
    let py = y + 210.0;
    this.H5(root, x, py, CMText.ViewPartHealth());
    py += 46.0;
    let parts = CMConsole.Parts(game, b);
    let row = MinF(74.0, (h - py - 260.0) / Cast<Float>(Max(1, ArraySize(parts))));
    for p in parts {
      CMCon.Txt(root, x, py, p.key, 1, 26, CMConPal.Ink(), 0);
      CMCon.Txt(root, x + w, py + 2.0, p.hp <= 0.0 ? CMText.ViewLost() : CMCon.Pct(p.hp), 2, 24, CMConPal.Ink(), 2);
      CMCon.Segs(root, x, py + 36.0, w, 10.0, p.hp, CMConPal.Health(p.hp));
      py += row;
    }

    let cy = h - 120.0;
    CMCon.Rect(root, x, cy, w, 84.0, CMConPal.Panel2(), CMCon.Fill2());
    CMCon.Rect(root, x, cy, 4.0, 84.0, b.owned ? CMConPal.Cyan() : CMConPal.Steel(), 1.0);
    CMCon.Txt(root, x + 22.0, cy + 28.0, b.owned ? (b.bay == 0 ? CMText.ViewBayMech(b.id) : CMText.ViewBayMotorPool(b.id)) : CMText.ViewWildUnit(), 2, 22, CMConPal.Ink(), 0);
  }

  private func Slot(v: ref<TKView>, root: ref<inkCanvas>, x: Float, y: Float, w: Float, key: String, name: String, act: String, why: String, on: Bool,
    action: String, arg: String, tip: String) -> Float {
    let h = 96.0;
    CMCon.Rect(root, x, y, w, h, CMConPal.Panel2(), CMCon.Fill2());
    let glow = CMCon.Rect(root, x, y, w, h, CMConPal.Cyan(), 0.0);
    let frame = CMCon.Frame(root, x, y, w, h, 2.0, on ? CMConPal.Amber() : CMConPal.Line(), 1.0);
    if StrLen(key) > 0 {
      CMCon.Txt(root, x + 20.0, y + 12.0, key, 2, 20, CMConPal.Steel(), 0);
    }
    CMCon.Txt(root, x + 20.0, StrLen(key) > 0 ? y + 42.0 : y + 30.0, name, 0, 26, StrLen(why) > 0 ? CMConPal.Steel() : CMConPal.Ink(), 0);
    if StrLen(why) > 0 {
      CMCon.Txt(root, x + w - 20.0, y + 38.0, why, 2, 20, CMConPal.Red(), 2);
    } else {
      CMCon.Txt(root, x + w - 20.0, y + 36.0, act, 2, 22, on ? CMConPal.Amber() : CMConPal.Steel(), 2);
    }
    let area = CMCon.HitArea(root, x, y, w, h);
    v.Hit(area, action, arg, tip, StrLen(why) > 0);

    ArrayPush(this.m_glows, CMHoverGlow.Attach(area, frame, glow, on ? CMConPal.Amber() : CMConPal.Line()));
    return y + h + 14.0;
  }

  private func Loadout(c: ref<CMContent>, v: ref<TKView>, root: ref<inkCanvas>, b: ref<CMConBay>, x: Float, y: Float, w: Float) -> Void {
    let game = c.game;
    let cfg = CMPilotSystem.Get(game);
    let fleet = CMFleet.Get(game);
    let con = c.Con();
    if b.bay == 0 {
      this.H5(root, x, y, CMText.ViewHardpoints());
      y += 44.0;
      y = this.Slot(v, root, x, y, w, CMText.ViewLArm(), CMConsole.GunName(CMLoadout.ArmGun(cfg, n"arm_l")), CMText.ViewChange(), "", Equals(con.hp, "arm_l"), "con_req", "arm_l", "");
      y = this.Slot(v, root, x, y, w, CMText.ViewRArm(), CMConsole.GunName(CMLoadout.ArmGun(cfg, n"arm_r")), CMText.ViewChange(), "", Equals(con.hp, "arm_r"), "con_req", "arm_r", "");
      y = this.Part(v, root, fleet, x, y, w, CMText.ViewBackSlot(), CMText.ViewBags(), "bags", Equals(con.hp, "pods"), "");
      y = this.Part(v, root, fleet, x, y, w, CMText.ViewShoulder(), CMText.ViewRocketRainPod(), "hullpod", Equals(con.hp, "torso") || Equals(con.hp, "pod"), "");
      y = this.Part(v, root, fleet, x, y, w, CMText.ViewFlanks(), CMText.ViewCountermeasures(), "counter", false, "");
      y += 10.0;
      this.H5(root, x, y, CMText.ViewUpgrades());
      y += 44.0;
      let half = (w - 14.0) * 0.5;
      let ups = ["cooling", "feed", "jets", "shield"];
      let i = 0;
      while i < 4 {
        let ux = x + Cast<Float>(i % 2) * (half + 14.0);
        let uy = y + Cast<Float>(i / 2) * 110.0;
        let item = "up_" + ups[i];
        let on = fleet.Fitted(item);
        this.Slot(v, root, ux, uy, half, on ? CMText.ViewFitted() : (fleet.Has(item) ? CMText.ViewOwned() : CMText.ViewNotOwned()), CMConsole.UpName(ups[i]), CMConsole.Offer(fleet, item, on), CMConsole.OfferWhy(fleet, item), on, "con_toggle", item, "");
        i += 1;
      }
      y += 230.0;
      this.H5(root, x, y, CMText.ViewLivery());
      y += 44.0;
      this.Slot(v, root, x, y, w, CMText.ViewPaint(), CMConsole.LiveryName(cfg.Text("livery", "mnc_default")), CMText.ViewChange(), "", false, "con_req", "livery", "");
      return;
    }
    if Equals(b.kind, "bombus") {
      this.H5(root, x, y, CMText.ViewPayload());
      y += 44.0;
      y = this.Slot(v, root, x, y, w, CMText.ViewPayload(), CMConsole.PayloadName(cfg.BombusPayload()), CMText.ViewChange(), "", Equals(con.hp, "payload"), "con_req", "payload", "");
      y += 10.0;
      this.DronePaint(v, root, fleet, b, x, y, w);
      return;
    }
    if b.owned {
      this.DronePaint(v, root, fleet, b, x, y, w);
    }
  }

  private func DronePaint(v: ref<TKView>, root: ref<inkCanvas>, fleet: ref<CMFleet>, b: ref<CMConBay>, x: Float, y: Float, w: Float) -> Void {
    this.H5(root, x, y, CMText.ViewLivery());
    this.Slot(v, root, x, y + 44.0, w, CMText.ViewPaint(), CMConsole.DroneLiveryName(fleet.FitOf("dlivery_" + b.kind)), CMText.ViewChange(), "", false, "con_req", "dlivery", "");
  }

  private func Part(v: ref<TKView>, root: ref<inkCanvas>, fleet: ref<CMFleet>, x: Float, y: Float, w: Float, key: String, name: String, item: String, sel: Bool, tip: String) -> Float {
    let on = fleet.Fitted(item);
    return this.Slot(v, root, x, y, w, key, on ? name : (fleet.Has(item) ? CMText.ViewNameOff(name) : CMText.ViewNone()), CMConsole.Offer(fleet, item, on), CMConsole.OfferWhy(fleet, item), sel || on, "con_toggle", item, tip);
  }

  private func Service(c: ref<CMContent>, v: ref<TKView>, root: ref<inkCanvas>, b: ref<CMConBay>, x: Float, y: Float, w: Float) -> Void {
    let game = c.game;
    let fleet = CMFleet.Get(game);
    if b.bay < 0 {
      return;
    }
    let left = fleet.RepairLeft(b.bay);
    if left > 0.0 {
      this.H5(root, x, y, fleet.Dead(b.bay) ? CMText.ViewRebuildInProgress() : CMText.ViewRepairInProgress());
      this.m_timer = CMCon.Txt(root, x, y + 50.0, CMConOps.Clock(left), 0, 60, CMConPal.Cyan(), 0);
      this.m_timerSegs = CMCon.Segs(root, x, y + 150.0, w, 14.0, 1.0 - left / MaxF(1.0, fleet.RepairTotal(b.bay)), CMConPal.Cyan());
      return;
    }
    this.H5(root, x, y, fleet.Dead(b.bay) ? CMText.ViewWreckReport() : CMText.ViewDamageReport());
    y += 50.0;
    if !fleet.Damaged(b.bay) {
      CMCon.Note(root, x, y, w, CMText.ViewNothingToRepair(), 26, CMConPal.Steel());
      this.Parts(v, root, fleet, b, x, y + 70.0, w);
      return;
    }
    if fleet.Dead(b.bay) {
      y = this.Line(root, x, y, w, CMText.ViewRebuildUnit(), CMText.ViewDestroyed(), CMConPal.Red(), CMFleet.RebuildPrice(b.bay));
    } else {
      let i = 0;
      while i < CMFleet.Parts(b.bay) {
        let hp = fleet.Hp(b.bay, i);
        if hp < 0.995 {
          y = this.Line(root, x, y, w, CMConOps.PartName(b, i), hp <= 0.0 ? CMText.ViewLost() : CMCon.Pct(hp), hp <= 0.0 ? CMConPal.Red() : CMConPal.Amber(), fleet.PartCost(b.bay, i));
        }
        i += 1;
      }
      if fleet.Hull(b.bay) < 0.995 {
        y = this.Line(root, x, y, w, CMText.ViewHull(), CMCon.Pct(fleet.Hull(b.bay)), CMConPal.Amber(), fleet.HullCost(b.bay));
      }
    }
    let hours = fleet.RepairTime(b.bay) / 3600.0;
    CMCon.Txt(root, x, y + 6.0, CMText.ViewTotalGameTime(FloatToStringPrec(hours, 1)), 1, 26, CMConPal.Ink(), 0);
    CMCon.Txt(root, x + w, y + 6.0, CMCon.Money(fleet.RepairCost(b.bay)) + " E$", 2, 28, CMConPal.Amber(), 2);
    y += 70.0;

    let why = fleet.CantRepair(b.bay);
    let bh = 110.0;
    CMCon.Frame(root, x, y, w, bh, 2.0, StrLen(why) > 0 ? CMConPal.Line2() : CMConPal.Amber(), 1.0);
    let fill = CMCon.Rect(root, x + 2.0, y + 2.0, 0.0, bh - 4.0, CMConPal.Amber(), 0.25);
    this.m_hold = fill;
    this.m_holdW = w - 4.0;
    this.m_holdOk = StrLen(why) == 0;
    CMCon.Txt(root, x + w * 0.5, y + 22.0, fleet.Dead(b.bay) ? CMText.ViewHoldToRebuild() : CMText.ViewHoldToRepairAll(), 0, 28, StrLen(why) > 0 ? CMConPal.Steel() : CMConPal.Amber(), 1);
    CMCon.Txt(root, x + w * 0.5, y + 66.0, StrLen(why) > 0 ? why : CMText.ViewHoldHint(), 2, 20, StrLen(why) > 0 ? CMConPal.Red() : CMConPal.Steel(), 1);
    let area = CMCon.HitArea(root, x, y, w, bh);
    area.RegisterToCallback(n"OnPress", this, n"OnHoldPress");
    area.RegisterToCallback(n"OnRelease", this, n"OnHoldRelease");
    area.RegisterToCallback(n"OnHoverOut", this, n"OnHoldRelease");
    this.Parts(v, root, fleet, b, x, y + bh + 30.0, w);
  }

  private func Parts(v: ref<TKView>, root: ref<inkCanvas>, fleet: ref<CMFleet>, b: ref<CMConBay>, x: Float, y: Float, w: Float) -> Void {
    let id = CMFleet.FabItem(b.kind);
    if b.bay <= 0 || b.bay >= 4 || !TDBID.IsValid(id) {
      return;
    }
    fleet.LearnRecipes();
    this.H5(root, x, y, CMText.ViewFabHeld(CMFleet.FabName(b.kind), IntToString(fleet.Held(id))));
    CMCon.Txt(root, x + w, y + 2.0, CMText.ViewOneTakes(CMFleet.FabCost(b.kind)), 2, 20, CMConPal.Steel(), 2);
    y += 40.0;
    let half = (w - 20.0) * 0.5;
    let fx = x;
    if fleet.Damaged(b.bay) {
      let n = fleet.PartsNeed(b.bay);
      this.Btn(v, root, x, y, half, (n == 1 ? CMText.ViewRepairWithPart(IntToString(n)) : CMText.ViewRepairWithParts(IntToString(n))), fleet.CantRepairParts(b.bay), "con_partsrepair", "");
      fx = x + half + 20.0;
    } else {
      half = w;
    }
    this.Btn(v, root, fx, y, half, CMText.ViewFabricateOne(), fleet.CantFab(b.kind), "con_fab", b.kind);
  }

  private func Btn(v: ref<TKView>, canvas: ref<inkCanvas>, x: Float, y: Float, w: Float, label: String, why: String, action: String, arg: String) -> Void {
    let off = StrLen(why) > 0;
    let h = 56.0;
    CMCon.Frame(canvas, x, y, w, h, 2.0, off ? CMConPal.Line2() : CMConPal.Amber(), 1.0);
    CMCon.Txt(canvas, x + w * 0.5, y + 14.0, off ? why : label, 2, 22, off ? CMConPal.Steel() : CMConPal.Amber(), 1);
    v.Hit(CMCon.HitArea(canvas, x, y, w, h), action, arg, "", off);
  }

  private func Line(root: ref<inkCanvas>, x: Float, y: Float, w: Float, name: String, state: String, c: HDRColor, cost: Int32) -> Float {
    CMCon.Txt(root, x, y, name, 1, 26, CMConPal.Ink(), 0);
    CMCon.Txt(root, x + CMCon.TextW(name, 26) + 24.0, y + 2.0, state, 2, 22, c, 0);
    CMCon.Txt(root, x + w, y + 2.0, CMCon.Money(cost) + " E$", 2, 24, CMConPal.Ink(), 2);
    CMCon.Rect(root, x, y + 44.0, w, 2.0, CMConPal.Line(), 1.0);
    return y + 60.0;
  }

  private static func PartName(b: ref<CMConBay>, i: Int32) -> String {
    if b.bay == 0 {
      return CMPart.Name(i);
    }
    return CMUDrone.PartName(b.kind, i);
  }

  public static func Clock(secs: Float) -> String {
    let m = CeilF(secs / 60.0);
    let hh = m / 60;
    let mm = m % 60;
    return CMText.ViewClock(IntToString(hh), (mm < 10 ? "0" : "") + IntToString(mm));
  }

  protected cb func OnHoldPress(e: ref<inkPointerEvent>) -> Bool {
    if !e.IsAction(n"click") || !this.m_holdOk {
      if !this.m_holdOk && e.IsAction(n"click") {
        GameObject.PlaySound(GetPlayer(GetGameInstance()), n"ui_hacking_press_fail");
      }
      return false;
    }
    this.m_holding = true;
    this.m_holdT = 0.0;
    return false;
  }

  protected cb func OnHoldRelease(e: ref<inkPointerEvent>) -> Bool {
    this.m_holding = false;
    this.m_holdT = 0.0;
    if IsDefined(this.m_hold) {
      this.m_hold.SetSize(Vector2(0.0, this.m_hold.GetHeight()));
    }
    return false;
  }

  protected func Tick() -> Void {
    if this.m_holding && IsDefined(this.m_hold) {
      this.m_holdT += 0.05;
      let f = ClampF(this.m_holdT / 1.2, 0.0, 1.0);
      this.m_hold.SetSize(Vector2(this.m_holdW * f, this.m_hold.GetHeight()));
      if f >= 1.0 {
        this.m_holding = false;
        if IsDefined(this.m_view) {
          this.m_view.Act("con_repair", "");
        }
        return;
      }
    }

    if IsDefined(this.m_timer) && this.m_bay >= 0 {
      let fleet = CMFleet.Get(GetGameInstance());
      let left = fleet.RepairLeft(this.m_bay);
      this.m_timer.SetText(CMConOps.Clock(left));
      CMCon.SetSegs(this.m_timerSegs, 1.0 - left / MaxF(1.0, fleet.RepairTotal(this.m_bay)), CMConPal.Cyan());
      if left <= 0.0 && IsDefined(this.m_view) {
        this.m_timer = null;
        this.m_view.Act("con_mode", "2");
      }
    }
  }

  private func Deploy(c: ref<CMContent>, v: ref<TKView>, canvas: ref<inkCanvas>, b: ref<CMConBay>, x: Float, y: Float, w: Float) -> Void {
    let game = c.game;
    let fleet = CMFleet.Get(game);
    let link = CMLinkSystem.Get(game);
    this.H5(canvas, x, y, CMText.ViewDeployRoute());
    y += 44.0;
    let pool = b.bay < 0 ? CMText.ViewNotYours() : fleet.CantDeploy(b.bay);
    y = this.Slot(v, canvas, x, y, w, CMText.ViewRoute("1"), Equals(b.kind, "minotaur") ? CMText.ViewBehemothDelivery() : CMText.ViewLaunchFromPool(), CMText.ViewSelect(), pool, false, "con_deploy", "", Equals(b.kind, "minotaur") ? CMText.ViewTipBehemoth() : CMText.ViewTipDroneLaunch());

    let drop = "";
    if !Equals(b.kind, "minotaur") {
      drop = CMText.ViewMechsOnly();
    } else {
      if b.bay < 0 {
        drop = CMText.ViewNotYours();
      } else {
        drop = fleet.Dropping() ? CMText.ViewDropUnderWay() : fleet.CantDeploy(b.bay);
      }
    }
    y = this.Slot(v, canvas, x, y, w, CMText.ViewRoute("2"), CMText.ViewOrbitalDrop(), CMText.ViewPickSpot(), drop, false, "con_dropmap", "", CMText.ViewTipOrbitalDrop());    y += 10.0;
    this.H5(canvas, x, y, CMText.ViewOrders());
    y += 44.0;
    let order = link.Order();
    let none = b.linked ? "" : CMText.ViewNotDeployed();
    let escort = fleet.Escorting() && fleet.IsOut(b.bay);
    if b.owned && !Equals(b.kind, "minotaur") {
      y = this.Slot(v, canvas, x, y, w, "", CMText.ViewCircleOverhead(), CMText.ViewOrder(), none, b.linked && escort && !fleet.Autopilot().OnPoint(), "con_order", "circle", CMText.ViewTipCircle());
    }
    if b.owned && !Equals(b.kind, "minotaur") {
      y = this.Slot(v, canvas, x, y, w, "", CMText.ViewLoiterOrHold(), CMText.ViewPickSpot(), none, b.linked && fleet.Autopilot().OnPoint(), "con_ordermap", "", CMText.ViewTipLoiterOrHold());
    }
    y = this.Slot(v, canvas, x, y, w, "", CMText.ViewFollowV(), CMText.ViewOrder(), none, b.linked && !escort && order == CMOrder.Follow(), "con_order", "follow", CMText.ViewTipFollow());
    y = this.Slot(v, canvas, x, y, w, "", CMText.ViewHoldPosition(), CMText.ViewOrder(), none, b.linked && !escort && order == CMOrder.Hold(), "con_order", "hold", CMText.ViewTipHold());
    y = this.Slot(v, canvas, x, y, w, "", CMText.ViewMoveToTarget(), CMText.ViewOrder(), none, b.linked && !escort && order == CMOrder.MoveTo(), "con_order", "move", CMText.ViewTipMove());
    if b.linked {
      y += 10.0;
      this.Slot(v, canvas, x, y, w, CMText.ViewLink(), b.owned ? CMText.ViewCloseLink() : CMText.ViewReleaseUnit(), CMText.ViewClose(), "", false, "con_unlink", "", b.owned ? CMText.ViewTipCloseLink() : CMText.ViewTipRelease());
    }
  }
}

public class CMConDeck extends TKCustom {
  public static func Make(c: ref<CMContent>, v: ref<TKView>, parent: ref<inkCompoundWidget>, w: Float, h: Float, page: String) -> ref<CMConDeck> {
    let d = new CMConDeck();
    let root = CMConRoot.Make(parent, w, h);
    let game = c.game;
    let con = c.Con();
    CMCon.Rect(root, 0.0, 0.0, w, h, CMConPal.Panel(), CMCon.Fill());
    CMCon.Scan(root, w, h);
    CMCon.Frame(root, 0.0, 0.0, w, h, 2.0, CMConPal.Line(), 1.0);
    let b = CMConsole.Selected(game, con);
    let fleet = CMFleet.Get(game);
    let player = GetPlayer(game);
    let deployWhy = !IsDefined(b) ? CMText.ViewNoUnit() : (b.bay < 0 ? CMText.ViewNotYours() : fleet.CantDeploy(b.bay));
    let pilotWhy = !IsDefined(b) || !b.linked ? CMText.ViewNotDeployed() : "";
    let recallWhy = !IsDefined(b) ? CMText.ViewNoUnit() : (b.bay < 0 ? CMText.ViewNotYours() : (b.out ? "" : CMText.ViewAtMotorPool()));
    let reqWhy = "";
    let x = 24.0;
    let y = (h - 92.0) * 0.5;
    x = d.Cap(v, root, x, y, CMKeyName.Of(CMKeys.ConDeploy(player)), CMText.ViewDeploy(), deployWhy, true, "con_deploy", "");
    x = d.Cap(v, root, x, y, CMKeys.PilotName(player), CMText.ViewPilot(), pilotWhy, false, "con_pilot", "");
    x = d.Cap(v, root, x, y, CMKeyName.Of(CMKeys.ConRecall(player)), CMText.ViewRecall(), recallWhy, false, "con_recall", "");
    x = d.Cap(v, root, x, y, CMKeyName.Of(CMKeys.ConMap(player)), CMText.ViewTacMap(), "", false, "con_map", "");
    x = d.Cap(v, root, x, y, CMKeyName.Of(CMKeys.ConReq(player)), CMText.ViewRequisition(), reqWhy, false, "con_req", "");
    x = d.Cap(v, root, x, y, "", CMText.ViewBack(), "", false, "con_back", "");
    x = d.Cap(v, root, x, y, "", Equals(page, "settings") ? CMText.ViewConsole() : CMText.ViewSettings(), "", Equals(page, "settings"), "con_settings", "");

    if StrLen(con.msg) > 0 {
      let bad = StrBeginsWith(con.msg, "!");
      CMCon.Txt(root, w - 34.0, h * 0.5 - 18.0, CMLinkSystem.Plain(con.msg), 2, 28, bad ? CMConPal.Red() : CMConPal.Green(), 2);
    }
    return d;
  }

  private func Cap(v: ref<TKView>, root: ref<inkCanvas>, x: Float, y: Float, key: String, label: String, why: String, primary: Bool, action: String, arg: String) -> Float {
    let off = StrLen(why) > 0;
    let h = 92.0;
    let kw = StrLen(key) > 0 ? MaxF(60.0, CMCon.TextW(key, 26) + 28.0) : 0.0;
    let lw = MaxF(Cast<Float>(StrLen(label)) * 28.0 * 0.82, off ? CMCon.TextW(why, 18) : 0.0);
    let w = 16.0 + kw + (kw > 0.0 ? 20.0 : 4.0) + lw + 30.0;
    let lit = primary && !off;
    CMCon.Rect(root, x, y, w, h, CMConPal.Panel2(), CMCon.Fill2());
    CMCon.Frame(root, x, y, w, h, 2.0, lit ? CMConPal.Amber() : CMConPal.Line2(), 1.0);
    if kw > 0.0 {
      CMCon.Key(root, x + 16.0, y + 14.0, key, CMConPal.Ink());
    }
    let tx = x + 16.0 + kw + (kw > 0.0 ? 20.0 : 4.0);
    let t = CMCon.Txt(root, tx, off ? y + 16.0 : y + 28.0, label, 0, 28, lit ? CMConPal.Amber() : CMConPal.Ink(), 0);
    if off {
      t.SetOpacity(0.45);
      CMCon.Txt(root, tx, y + 56.0, why, 2, 18, CMConPal.Red(), 0);
    }
    v.Hit(CMCon.HitArea(root, x, y, w, h), action, arg, "", off);
    return x + w + 16.0;
  }
}

public class CMConMap extends CMConLive {
  private let m_cx: Float;
  private let m_cy: Float;
  private let m_scale: Float;
  private let m_r: Float;
  private let m_v: wref<inkImage>;
  private let m_dots: array<wref<inkImage>>;
  private let m_labels: array<wref<inkText>>;
  private let m_root: wref<inkCanvas>;
  private let m_pick: Bool;
  private let m_drone: Bool;

  public static func Make(c: ref<CMContent>, v: ref<TKView>, parent: ref<inkCompoundWidget>, w: Float, h: Float, mode: String) -> ref<CMConMap> {
    let m = new CMConMap();
    m.m_view = v;
    m.m_con = c;
    m.m_pick = Equals(mode, "drop") || Equals(mode, "drone");
    m.m_drone = Equals(mode, "drone");
    let root = CMConRoot.Make(parent, w, h);
    m.m_root = root;
    m.Draw(root, w, h);
    if m.m_pick {
      m.Pick(c, v, root, w, h);
    }
    m.Tick();
    m.Begin(0.5);
    return m;
  }

  private func Draw(root: ref<inkCanvas>, w: Float, h: Float) -> Void {
    CMCon.Rect(root, 0.0, 0.0, w, h, CMConPal.C(5, 8, 9), 1.0);
    this.m_cx = w * 0.5;
    this.m_cy = h * 0.5;
    this.m_r = MinF(w, h) * 0.5 - 50.0;
    this.m_scale = this.m_r / 500.0;

    this.Scan(root, w, h);

    let step = 100.0 * this.m_scale;
    let gx = this.m_cx - step * Cast<Float>(FloorF(this.m_cx / step));
    while gx < w {
      CMCon.Rect(root, gx, 0.0, 2.0, h, CMConPal.Line(), 0.7);
      gx += step;
    }
    let gy = this.m_cy - step * Cast<Float>(FloorF(this.m_cy / step));
    while gy < h {
      CMCon.Rect(root, 0.0, gy, w, 2.0, CMConPal.Line(), 0.7);
      gy += step;
    }

    for m in [100.0, 250.0, 500.0] {
      let r = m * this.m_scale;
      CMInk.Circle(root, this.m_cx, this.m_cy, r, CMConPal.Line2(), 1.0);
      CMCon.Txt(root, this.m_cx + r * 0.71 + 8.0, this.m_cy - r * 0.71 - 30.0, IntToString(RoundF(m)) + " M", 2, 20, CMConPal.Steel(), 0);
    }
    CMCon.Txt(root, this.m_cx, this.m_cy - this.m_r - 40.0, "N", 0, 26, CMConPal.Steel(), 1);

    this.m_v = CMKit.Img(root, n"tri", this.m_cx - 16.0, this.m_cy - 18.0, 32.0, 36.0, CMConPal.Amber(), 1.0);
    this.m_v.SetRenderTransformPivot(Vector2(0.5, 0.5));
    CMCon.Txt(root, this.m_cx + 26.0, this.m_cy - 14.0, "V", 2, 24, CMConPal.Amber(), 0);

    let i = 0;
    while i < 2 {
      let d = CMKit.Disc(root, 0.0, 0.0, 12.0, CMConPal.Cyan(), 1.0);
      d.SetVisible(false);
      ArrayPush(this.m_dots, d);
      let t = CMCon.Txt(root, 0.0, 0.0, "", 2, 24, CMConPal.Cyan(), 0);
      t.SetVisible(false);
      ArrayPush(this.m_labels, t);
      i += 1;
    }

    let lx = 30.0;
    let ly = h - 50.0;
    CMKit.Img(root, n"tri", lx, ly, 20.0, 22.0, CMConPal.Amber(), 1.0);
    CMCon.Txt(root, lx + 32.0, ly - 2.0, "V", 2, 22, CMConPal.Steel(), 0);
    CMKit.Disc(root, lx + 110.0, ly + 11.0, 10.0, CMConPal.Cyan(), 1.0);
    CMCon.Txt(root, lx + 132.0, ly - 2.0, CMText.ViewYourUnit(), 2, 22, CMConPal.Steel(), 0);
    CMKit.Disc(root, lx + 330.0, ly + 11.0, 10.0, CMConPal.Steel(), 1.0);
    CMCon.Txt(root, lx + 352.0, ly - 2.0, CMText.ViewWildUnit(), 2, 22, CMConPal.Steel(), 0);
  }

  public static func Tiles() -> String = "0111111100000000011111110000000001111111110000000111111111000000011111111100001001111111110001100111111111000111011111111111011100111111111101110011111111111111011111111110111101111111111011111111111111111111111111111111001011111111111100001111111111100000"

  public static func FineTiles() -> String = "0001111111111100000000000000000000011111111111110000000000000000000111111111111100000000000000000001111111111111000000000000000000111111111111110000000000000000011111111111111100000000000000000111111111111111110100000000000001111111111111111101100000000000010011111111111111011000000000000000011111111111110110000000000100010111111111111101100000000101000111111111111110000000000001010001111111111111100000000011010100011111111111111100000000110100000111111111111111110000001111110001111111111111111110010011111100001111111111111111101101111111000011111111111111111011011111110000111111111111111110110111011100001111111111111111101101100011000011111111111111111101011000110001111111111111111111011110101100011111111111111111010011101001000111111111111111110100111010010101111111111111111000001111100111111111111111111111111100111000111111111111111101111111000110001111111111111111111111110001100011111111111101111111111100000000111111111110011111111100000000001111111111100111101011000000000011111111110001110010100000000000"

  private func Scan(root: ref<inkCanvas>, w: Float, h: Float) -> Void {
    let tiles = CMConMap.Tiles();
    let player = GetPlayer(GetGameInstance());
    if StrLen(tiles) < 256 || !IsDefined(player) {
      return;
    }
    let me = player.GetWorldPosition();
    let clip = new inkScrollArea();
    clip.SetAnchor(inkEAnchor.TopLeft);
    clip.SetFitToContentDirection(inkFitToContentDirection.None);
    clip.SetConstrainContentPosition(false);
    clip.SetUseInternalMask(true);
    clip.SetSize(Vector2(w, h));
    clip.Reparent(root);
    let inner = new inkCanvas();
    inner.SetSize(Vector2(w, h));
    inner.Reparent(clip);

    this.Layer(inner, w, h, me, tiles, 16, 462.5, "t2");
    let fine = CMConMap.FineTiles();
    if StrLen(fine) >= 1024 {
      this.Layer(inner, w, h, me, fine, 32, 231.25, "t3");
    }
  }

  private func Layer(inner: ref<inkCanvas>, w: Float, h: Float, me: Vector4, tiles: String, n: Int32, span: Float, dir: String) -> Void {
    let size = span * this.m_scale;
    let r = 0;
    while r < n {
      let c = 0;
      while c < n {
        if Equals(StrMid(tiles, r * n + c, 1), "1") {
          let x = this.m_cx + (-3600.0 + Cast<Float>(c) * span - me.X) * this.m_scale;
          let y = this.m_cy - (3800.0 - Cast<Float>(r) * span - me.Y) * this.m_scale;
          if x + size > 0.0 && x < w && y + size > 0.0 && y < h {
            let img = new inkImage();
            img.SetAtlasResource(ResRef.FromString("mnc\\ui\\map\\city\\" + dir + "\\" + IntToString(c) + "_" + IntToString(r) + ".inkatlas"));
            img.SetTexturePart(n"t");
            img.SetMargin(inkMargin(x, y, 0.0, 0.0));
            img.SetSize(Vector2(size + 1.0, size + 1.0));
            img.SetOpacity(0.7);
            img.SetInteractive(false);
            img.Reparent(inner);
          }
        }
        c += 1;
      }
      r += 1;
    }
  }

  private func Pick(c: ref<CMContent>, v: ref<TKView>, root: ref<inkCanvas>, w: Float, h: Float) -> Void {
    let r = (this.m_drone ? 400.0 : 250.0) * this.m_scale;
    CMInk.Circle(root, this.m_cx, this.m_cy, r, CMConPal.Amber(), 0.6);
    let catcher = CMCon.HitArea(root, 0.0, 0.0, w, h - 110.0);
    catcher.RegisterToCallback(n"OnRelease", this, n"OnMapClick");

    catcher.RegisterToCallback(n"OnRelative", this, n"OnMapMove");
    let aim = new inkCanvas();
    aim.SetSize(Vector2(1.0, 1.0));
    aim.SetInteractive(false);
    aim.Reparent(root);
    CMInk.Circle(aim, 0.0, 0.0, 14.0, CMConPal.Cyan(), 0.9);
    CMCon.Rect(aim, -22.0, -1.0, 44.0, 2.0, CMConPal.Cyan(), 0.9);
    CMCon.Rect(aim, -1.0, -22.0, 2.0, 44.0, CMConPal.Cyan(), 0.9);
    aim.SetVisible(false);
    this.m_aim = aim;
    let con = c.Con();
    let player = GetPlayer(c.game);
    if con.dropOk && IsDefined(player) {
      let me = player.GetWorldPosition();
      let sx = this.m_cx + (con.dropAt.X - me.X) * this.m_scale;
      let sy = this.m_cy - (con.dropAt.Y - me.Y) * this.m_scale;
      CMInk.Circle(root, sx, sy, 22.0, CMConPal.Amber(), 1.0);
      CMCon.Rect(root, sx - 30.0, sy - 1.0, 60.0, 3.0, CMConPal.Amber(), 1.0);
      CMCon.Rect(root, sx - 1.0, sy - 30.0, 3.0, 60.0, CMConPal.Amber(), 1.0);
      CMCon.Txt(root, sx + 30.0, sy - 44.0, this.m_drone ? CMText.ViewPoint() : "LZ", 2, 24, CMConPal.Amber(), 0);
    }
    let bw = 420.0;
    let bx = w - bw - 30.0;
    let by = h - 92.0;
    let off = !con.dropOk;
    if this.m_drone {

      this.MapButton(v, root, bx - bw - 24.0, by, bw, off ? CMText.ViewClickMapFirst() : CMText.ViewLoiterHere(), off, "con_dloiter", CMText.ViewTipLoiterHere());
      this.MapButton(v, root, bx, by, bw, off ? CMText.ViewClickMapFirst() : CMText.ViewHoldHere(), off, "con_dhold", CMText.ViewTipHoldHere());
      return;
    }
    CMCon.Rect(root, bx, by, bw, 70.0, CMConPal.Panel2(), CMCon.Fill2());
    CMCon.Frame(root, bx, by, bw, 70.0, 2.0, off ? CMConPal.Line2() : CMConPal.Amber(), 1.0);
    CMCon.Txt(root, bx + bw * 0.5, by + 18.0, off ? CMText.ViewClickMapFirst() : CMText.ViewDropHere(), 0, 28, off ? CMConPal.Steel() : CMConPal.Amber(), 1);
    v.Hit(CMCon.HitArea(root, bx, by, bw, 70.0), "con_drop", "", off ? CMText.ViewTipClickMap() : CMText.ViewTipDropHere(), off);
  }

  private let m_aim: wref<inkCanvas>;

  protected cb func OnMapMove(e: ref<inkPointerEvent>) -> Bool {
    if !IsDefined(this.m_aim) || !IsDefined(this.m_root) {
      return false;
    }
    let local = WidgetUtils.GlobalToLocal(this.m_root, e.GetScreenSpacePosition());
    this.m_aim.SetMargin(inkMargin(local.X, local.Y, 0.0, 0.0));
    this.m_aim.SetVisible(true);
    return false;
  }

  private func MapButton(v: ref<TKView>, root: ref<inkCanvas>, bx: Float, by: Float, bw: Float, label: String, off: Bool, action: String, tip: String) -> Void {
    CMCon.Rect(root, bx, by, bw, 70.0, CMConPal.Panel2(), CMCon.Fill2());
    CMCon.Frame(root, bx, by, bw, 70.0, 2.0, off ? CMConPal.Line2() : CMConPal.Amber(), 1.0);
    CMCon.Txt(root, bx + bw * 0.5, by + 18.0, label, 0, 28, off ? CMConPal.Steel() : CMConPal.Amber(), 1);
    v.Hit(CMCon.HitArea(root, bx, by, bw, 70.0), action, "", tip, off);
  }

  protected cb func OnMapClick(e: ref<inkPointerEvent>) -> Bool {
    if !e.IsAction(n"click") || !IsDefined(this.m_root) || !IsDefined(this.m_view) {
      return false;
    }
    let local = WidgetUtils.GlobalToLocal(this.m_root, e.GetScreenSpacePosition());
    let scr = e.GetScreenSpacePosition();
    let sz = this.m_root.GetSize();
    let dx = (local.X - this.m_cx) / this.m_scale;
    let dy = (this.m_cy - local.Y) / this.m_scale;
    this.m_view.Act("con_droppick", FloatToStringPrec(dx, 1) + "," + FloatToStringPrec(dy, 1));
    return true;
  }

  protected func Tick() -> Void {
    let game = GetGameInstance();
    let player = GetPlayer(game);
    if !IsDefined(player) || !IsDefined(this.m_v) {
      return;
    }
    let fwd = player.GetWorldForward();
    this.m_v.SetRotation(Rad2Deg(AtanF(fwd.X, fwd.Y)));
    let units: array<ref<NPCPuppet>>;
    let wild: array<Bool>;
    let fleet = CMFleet.Get(game);
    let out = fleet.OutUnit();
    if IsDefined(out) {
      ArrayPush(units, out);
      ArrayPush(wild, false);
    }
    let linked = CMLinkSystem.Get(game).Unit();
    if IsDefined(linked) && (!IsDefined(out) || linked.GetEntityID() != out.GetEntityID()) {
      ArrayPush(units, linked);
      ArrayPush(wild, true);
    }
    let me = player.GetWorldPosition();
    let i = 0;
    while i < 2 {
      let d = this.m_dots[i];
      let t = this.m_labels[i];
      if i < ArraySize(units) && IsDefined(d) && IsDefined(t) {
        let p = units[i].GetWorldPosition();
        let dx = p.X - me.X;
        let dy = p.Y - me.Y;
        let dist = SqrtF(dx * dx + dy * dy);
        let k = dist * this.m_scale > this.m_r ? this.m_r / (dist * this.m_scale) : 1.0;
        let sx = this.m_cx + dx * this.m_scale * k;
        let sy = this.m_cy - dy * this.m_scale * k;
        let c = wild[i] ? CMConPal.Steel() : CMConPal.Cyan();
        CMKit.Place(d, sx, sy, 12.0);
        d.SetTintColor(c);
        d.SetVisible(true);
        t.SetMargin(inkMargin(sx + 22.0, sy - 14.0, 0.0, 0.0));
        t.SetText(CMConsole.KindOf(units[i]) + "  " + IntToString(RoundF(dist)) + " M");
        t.SetTintColor(c);
        t.SetVisible(true);
      } else {
        if IsDefined(d) {
          d.SetVisible(false);
        }
        if IsDefined(t) {
          t.SetVisible(false);
        }
      }
      i += 1;
    }
  }
}

public class CMConReq extends TKCustom {
  public static func Make(c: ref<CMContent>, v: ref<TKView>, parent: ref<inkCompoundWidget>, w: Float, h: Float, slot: String) -> ref<CMConReq> {
    let q = new CMConReq();
    let root = CMConRoot.Make(parent, w, h);
    let game = c.game;
    let con = c.Con();
    let cfg = CMPilotSystem.Get(game);
    let fleet = CMFleet.Get(game);
    CMCon.Rect(root, 0.0, 0.0, w, h, CMConPal.C(5, 8, 9), 1.0);
    let b = CMConsole.Selected(game, con);
    let cols = 3;
    let gap = 24.0;
    let cw = (w - 60.0 - gap * Cast<Float>(cols - 1)) / Cast<Float>(cols);
    let ch = 330.0;
    let n = 0;

    if Equals(slot, "units") || !IsDefined(b) || !b.owned {
      let ui = 0;
      while ui < CMFleet.Count() {
        q.Unit(v, root, fleet, ui, 30.0 + Cast<Float>(n % cols) * (cw + gap), 24.0 + Cast<Float>(n / cols) * (ch + gap), cw, ch);
        n += 1;
        ui += 1;
      }
      return q;
    }
    if b.bay == 0 {

      let arms: array<String>;
      if Equals(slot, "arm_l") || Equals(slot, "arm_r") {
        ArrayPush(arms, slot);
      } else {
        if !Equals(slot, "livery") {
          ArrayPush(arms, "arm_l");
          ArrayPush(arms, "arm_r");
        }
      }
      let top = 24.0;
      let na = ArraySize(arms);
      if na > 0 {
        let gi = 0;
        while gi < CMWeaponSpecs.ArmGunCount() {
          if CMWeaponSpecs.ArmGunReleased(gi) {
            q.Gun(v, root, cfg, fleet, gi, arms, 30.0 + Cast<Float>(n % cols) * (cw + gap), top + Cast<Float>(n / cols) * (ch + gap), cw, ch);
            n += 1;
          }
          gi += 1;
        }
        top += Cast<Float>((n + cols - 1) / cols) * (ch + gap);
      }
      if Equals(slot, "livery") || StrLen(slot) == 0 {
        let lh = 200.0;
        let li = 0;
        let ids = CMConsole.Liveries();
        for id in ids {
          q.Livery(v, root, cfg, fleet, id, 30.0 + Cast<Float>(li % cols) * (cw + gap), top + Cast<Float>(li / cols) * (lh + gap), cw, lh);
          li += 1;
        }
      }
      return q;
    }
    if Equals(slot, "dlivery") && b.bay > 0 {
      let lh = 200.0;
      let li = 0;
      let ids = CMConsole.DroneLiveries(b.kind);
      for id in ids {
        q.DroneLivery(v, root, fleet, b.kind, id, 30.0 + Cast<Float>(li % cols) * (cw + gap), 24.0 + Cast<Float>(li / cols) * (lh + gap), cw, lh);
        li += 1;
      }
      return q;
    }
    if Equals(b.kind, "bombus") {
      let pi = 1;
      while pi <= 4 {
        q.Payload(v, root, cfg, fleet, pi, 30.0 + Cast<Float>(n % cols) * (cw + gap), 24.0 + Cast<Float>(n / cols) * (ch + gap), cw, ch);
        n += 1;
        pi += 1;
      }
      return q;
    }
    CMCon.Note(root, 30.0, 40.0, w - 60.0, CMText.ViewNothingToFit(), 28, CMConPal.Steel());
    return q;
  }

  private func Card(root: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, cap: String, name: String, on: Bool) -> Void {
    CMCon.Rect(root, x, y, w, h, CMConPal.Panel2(), CMCon.Fill2());
    CMCon.Frame(root, x, y, w, h, 2.0, on ? CMConPal.Amber() : CMConPal.Line(), 1.0);
    CMCon.Txt(root, x + 24.0, y + 18.0, cap, 2, 20, CMConPal.Steel(), 0);
    CMCon.Txt(root, x + 24.0, y + 46.0, name, 0, 30, CMConPal.Ink(), 0);
  }

  private func Bar(root: ref<inkCanvas>, x: Float, y: Float, w: Float, label: String, v: Float, cur: Float) -> Void {
    CMCon.Txt(root, x, y - 4.0, label, 2, 20, CMConPal.Steel(), 0);
    let tx = x + 130.0;
    let tw = w - 130.0 - 60.0;
    CMCon.Rect(root, tx, y + 6.0, tw, 12.0, CMConPal.Line(), 1.0);
    CMCon.Rect(root, tx, y + 6.0, tw * ClampF(v, 0.0, 1.0), 12.0, CMConPal.Cyan(), 1.0);
    CMCon.Rect(root, tx + tw * ClampF(cur, 0.0, 1.0) - 2.0, y - 2.0, 4.0, 28.0, CMConPal.Amber(), 1.0);
    CMCon.Txt(root, x + w, y - 4.0, IntToString(RoundF(v * 100.0)), 2, 20, CMConPal.Steel(), 2);
  }

  private func Button(v: ref<TKView>, canvas: ref<inkCanvas>, x: Float, y: Float, w: Float, label: String, why: String, action: String, arg: String) -> Void {
    let off = StrLen(why) > 0;
    let h = 56.0;
    CMCon.Frame(canvas, x, y, w, h, 2.0, off ? CMConPal.Line2() : CMConPal.Amber(), 1.0);
    CMCon.Txt(canvas, x + w * 0.5, y + 14.0, off ? why : label, 2, 22, off ? CMConPal.Steel() : CMConPal.Amber(), 1);
    v.Hit(CMCon.HitArea(canvas, x, y, w, h), action, arg, "", off);
  }

  private static func Act(fleet: ref<CMFleet>, item: String, verb: String) -> String {
    return fleet.Has(item) ? verb : CMText.ViewBuyAnd(verb, CMCon.Money(CMFleet.Price(item)));
  }

  private func Unit(v: ref<TKView>, root: ref<inkCanvas>, fleet: ref<CMFleet>, bay: Int32, x: Float, y: Float, w: Float, h: Float) -> Void {
    let owned = fleet.Owned(bay);
    this.Card(root, x, y, w, h, StrUpper(CMFleet.Kind(bay)), CMFleet.Name(bay), owned);
    CMPilotHud.Img(root, inkEAnchor.TopLeft, x + w - 190.0, y + 90.0, 160.0, 160.0, CMApi.WireframeAtlas(), StringToName(CMFleet.Kind(bay)), owned ? CMConPal.Green() : CMConPal.Cyan(), 1.0);
    CMCon.Note(root, x + 24.0, y + 100.0, w - 240.0, CMConReq.Blurb(bay), 22, CMConPal.Steel());
    let item = "unit_" + IntToString(bay);
    let why = owned ? CMText.ViewInYourFleet() : fleet.CantBuy(item);
    if Equals(why, "CAN'T AFFORD") {
      why = CMText.ViewCantAffordPrice(CMCon.Money(CMFleet.Price(item)));
    }
    this.Button(v, root, x + 24.0, y + h - 80.0, w - 48.0, CMText.ViewBuyPrice(CMCon.Money(CMFleet.Price(item))), why, "con_buyunit", IntToString(bay));

    if bay == 4 && !owned {
      fleet.LearnRecipes();
      let kits = fleet.Held(CMFleet.FabItem("bombus"));
      this.Button(v, root, x + 24.0, y + h - 146.0, w - 48.0, CMText.ViewBuildFromKit(IntToString(kits)), fleet.CantAssemble(), "con_assemble", "");
    }
  }

  private static func Blurb(bay: Int32) -> String {
    switch bay {
      case 1: return CMText.ViewBlurbOctant();
      case 2: return CMText.ViewBlurbWyvern();
      case 3: return CMText.ViewBlurbGriffin();
      case 4: return CMText.ViewBlurbBombus();
    }
    return CMText.ViewBlurbMinotaur();
  }

  private static func GunRating(id: String, stat: Int32) -> Float {
    switch id {
      case "plasma": return stat == 0 ? 0.95 : (stat == 1 ? 0.25 : 0.80);
      case "fieldhmg": return stat == 0 ? 0.75 : (stat == 1 ? 0.55 : 0.55);
    }
    return stat == 0 ? 0.45 : (stat == 1 ? 0.90 : 0.35);
  }

  private func Gun(v: ref<TKView>, root: ref<inkCanvas>, cfg: ref<CMPilotSystem>, fleet: ref<CMFleet>, gi: Int32, arms: array<String>, x: Float, y: Float, w: Float, h: Float) -> Void {
    let id = CMWeaponSpecs.ArmGunId(gi);
    let item = "gun_" + id;
    let cur = CMLoadout.ArmGun(cfg, StringToName(arms[0]));
    let fittedL = Equals(CMLoadout.ArmGun(cfg, n"arm_l"), id);
    let fittedR = Equals(CMLoadout.ArmGun(cfg, n"arm_r"), id);
    let one = ArraySize(arms) == 1;
    this.Card(root, x, y, w, h, fleet.Has(item) ? CMText.ViewArmGunOwned() : CMText.ViewArmGunPrice(CMCon.Money(CMFleet.Price(item))), CMConsole.GunName(id), one && Equals(cur, id));
    this.Bar(root, x + 24.0, y + 110.0, w - 48.0, CMText.ViewPower(), CMConReq.GunRating(id, 0), CMConReq.GunRating(cur, 0));
    this.Bar(root, x + 24.0, y + 150.0, w - 48.0, CMText.ViewRate(), CMConReq.GunRating(id, 1), CMConReq.GunRating(cur, 1));
    this.Bar(root, x + 24.0, y + 190.0, w - 48.0, CMText.ViewHeat(), CMConReq.GunRating(id, 2), CMConReq.GunRating(cur, 2));
    let afford = CMConsole.OfferWhy(fleet, item);
    let by = y + h - 80.0;
    if one {
      let fitted = Equals(arms[0], "arm_l") ? fittedL : fittedR;
      this.Button(v, root, x + 24.0, by, w - 48.0, CMConReq.Act(fleet, item, Equals(arms[0], "arm_l") ? CMText.ViewFitToLArm() : CMText.ViewFitToRArm()), fitted ? CMText.ViewFitted() : afford, "con_fit", arms[0] + ":" + IntToString(gi));
    } else {
      let half = (w - 48.0 - 14.0) * 0.5;
      this.Button(v, root, x + 24.0, by, half, fleet.Has(item) ? CMText.ViewFitLArm() : CMText.ViewBuyFitL(), fittedL ? CMText.ViewOnLArm() : afford, "con_fit", "arm_l:" + IntToString(gi));
      this.Button(v, root, x + 24.0 + half + 14.0, by, half, fleet.Has(item) ? CMText.ViewFitRArm() : CMText.ViewBuyFitR(), fittedR ? CMText.ViewOnRArm() : afford, "con_fit", "arm_r:" + IntToString(gi));
    }
  }

  private func DroneLivery(v: ref<TKView>, root: ref<inkCanvas>, fleet: ref<CMFleet>, kind: String, id: String, x: Float, y: Float, w: Float, h: Float) -> Void {
    let item = "dlivery_" + kind + "_" + id;
    let free = StrLen(id) == 0;
    let on = Equals(fleet.FitOf("dlivery_" + kind), id);
    let owned = free || fleet.Has(item);
    this.Card(root, x, y, w, h, owned ? CMText.ViewPaintOwned() : CMText.ViewPaintPrice(CMCon.Money(CMFleet.Price(item))), CMConsole.DroneLiveryName(id), on);
    this.Button(v, root, x + 24.0, y + h - 80.0, w - 48.0, owned ? CMText.ViewPaint() : CMText.ViewBuyAndPaint(), on ? CMText.ViewFitted() : (owned ? "" : CMConsole.OfferWhy(fleet, item)), "con_dlivery", id);
  }

  private func Livery(v: ref<TKView>, root: ref<inkCanvas>, cfg: ref<CMPilotSystem>, fleet: ref<CMFleet>, id: String, x: Float, y: Float, w: Float, h: Float) -> Void {
    let item = "livery_" + id;
    let on = Equals(cfg.Text("livery", "mnc_default"), id);
    this.Card(root, x, y, w, h, fleet.Has(item) ? CMText.ViewLiveryOwned() : CMText.ViewLiveryPrice(CMCon.Money(CMFleet.Price(item))), CMConsole.LiveryName(id), on);
    this.Button(v, root, x + 24.0, y + h - 80.0, w - 48.0, CMConReq.Act(fleet, item, CMText.ViewPaint()), on ? CMText.ViewFitted() : CMConsole.OfferWhy(fleet, item), "con_livery", id);
  }

  private func Payload(v: ref<TKView>, root: ref<inkCanvas>, cfg: ref<CMPilotSystem>, fleet: ref<CMFleet>, pi: Int32, x: Float, y: Float, w: Float, h: Float) -> Void {
    let item = "payload_" + IntToString(pi);
    let cur = cfg.BombusPayload();
    this.Card(root, x, y, w, h, fleet.Has(item) ? CMText.ViewPayloadOwned() : CMText.ViewPayloadPrice(CMCon.Money(CMFleet.Price(item))), CMConsole.PayloadName(pi), cur == pi);

    let blast = [0.45, 0.95, 0.20, 0.35];
    let area = [0.50, 0.75, 0.80, 0.60];
    let linger = [0.10, 0.10, 0.95, 0.40];
    this.Bar(root, x + 24.0, y + 110.0, w - 48.0, CMText.ViewBlast(), blast[pi - 1], blast[cur - 1]);
    this.Bar(root, x + 24.0, y + 150.0, w - 48.0, CMText.ViewArea(), area[pi - 1], area[cur - 1]);
    this.Bar(root, x + 24.0, y + 190.0, w - 48.0, CMText.ViewLinger(), linger[pi - 1], linger[cur - 1]);
    this.Button(v, root, x + 24.0, y + h - 80.0, w - 48.0, CMConReq.Act(fleet, item, CMText.ViewLoad()), cur == pi ? CMText.ViewLoaded() : CMConsole.OfferWhy(fleet, item), "con_payload", IntToString(pi));
  }
}
