module ControllableMechs.Control

import ControllableMechs.*

public class CMUMinotaur extends CMCUnit {
  private let m_game: GameInstance;
  private let m_mechID: EntityID;
  private let m_guns: ref<CMPilotGuns>;

  private let m_markerID: EntityID;
  private let m_marker: wref<Entity>;
  private let m_lookAts: array<ref<LookAtAddEvent>>;

  private let m_moveCmd: ref<AICommand>;
  private let m_turnCmd: ref<AICommand>;
  private let m_moving: Bool;
  private let m_moveDir: Vector4;
  private let m_moveTarget: Vector4;
  private let m_moveSent: Float;
  private let m_moveYaw: Float;
  private let m_calmResets: Int32;
  private let m_threatClears: Int32;
  private let m_gunsLost: Bool;
  private let m_mtRefitAt: Float;
  private let m_mtSlots: String;
  private let m_stoodAt: Float;
  private let m_triggerWas: Bool;

  private let m_parts: ref<CMPartState>;
  private let m_partsOn: Bool;
  private let m_partNote: String;
  private let m_partNoteUntil: Float;
  private let m_limpHalt: Bool;
  private let m_limpNext: Float;
  private let m_gait: Float;
  private let m_critFx: Bool;
  private let m_mech: wref<NPCPuppet>;
  private let m_sensorUp: Float;
  private let m_sensorFwd: Float;

  private let m_bodyYaw: Float;
  private let m_turnVel: Float;
  private let m_air: Bool;
  private let m_combatWatch: Int32;
  private let m_lookAtsFrom: Float;
  private let m_combatWatchAt: Float;
  private let m_airTime: Float;
  private let m_airLogs: Int32;
  private let m_sentOpen: Bool;
  private let m_sentYaw: Float;
  private let m_sentAt: Float;
  private let m_lookMiss: Int32;
  private let m_lookSent: Float;
  private let m_turning: Bool;
  private let m_body: ref<CMMechBody>;
  private let m_bodyLed: Bool;
  private let m_reachZ: Float;
  private let m_blockUntil: Float;
  private let m_blockDir: Vector4;
  private let m_legs: Int32;
  private let TURN_RATE: Float = 35.0;
  private let TURN_ACCEL: Float = 60.0;
  private let m_turnRate: Float;
  private let m_turnAccel: Float;
  private let TURN_K: Float = 2.5;
  private let TURN_START_DEG: Float = 20.0;
  private let TURN_START_SWEEP_DEG: Float = 8.0;
  private let LOOKAT_FOLLOW: Float = 3.0;
  private let LOOKAT_BLEND: Float = 3.0;

  private let m_load: array<ref<CMHardpoint>>;
  private let m_missile: ref<CMWeaponSpec>;
  private let m_spin: Float;
  private let START_LURCH: Float = 9.0;
  private let STOP_ROCK: Float = 7.0;

  private let m_servoOn: Bool;
  private let m_servoHit: Float;
  private let m_missileReady: Float;
  private let m_audioTrigger: Bool;
  private let m_fireLoop: Bool;
  private let m_heatWarned: Bool;
  private let m_audioLocked: Bool;
  private let m_lowAlarm: Bool;
  private let m_hull: Float;
  private let m_beepNext: Float;
  private let m_armour: ref<gameStatModifierData>;
  private let m_markerAt: Vector4;
  private let m_markerOk: Bool;
  private let MARKER_EASE: Float = 7.0;

  private let GATE_DEG: Float = 4.0;
  private let m_gate: Bool;
  private let m_sense: ref<CMDroneSense>;
  private let m_trackEnt: wref<GameObject>;
  private let TRACK_RANGE: Float = 150.0;
  private let m_roundLogAt: Float;
  private let m_traceN: Int32;

  public func Track(s: ref<CMCSession>) -> Void {
    if IsDefined(this.m_trackEnt) {
      this.StopTrack("released");
      return;
    }
    let target: ref<GameObject>;
    if IsDefined(this.m_sense) && IsDefined(this.m_sense.track.lock) && this.m_sense.track.lock.kind != 0 {
      target = this.m_sense.track.lock.ent;
    }
    if !IsDefined(target) {
      let npc = s.aimEntity as NPCPuppet;
      if IsDefined(npc) && !npc.IsDead() {
        target = npc;
      }
    }
    if !IsDefined(target) || Equals(target.GetEntityID(), this.Mech().GetEntityID()) {
      return;
    }
    this.m_trackEnt = target;
  }

  private func StopTrack(why: String) -> Void {
    if IsDefined(this.m_trackEnt) {
    }
    this.m_trackEnt = null;
  }

  private func RoundTrace(s: ref<CMCSession>, mech: ref<NPCPuppet>, from: Vector4, to: Vector4) -> Void {
    let dir = Vector4.Normalize(to - from);
    let a = from + dir * 0.05;
    a.W = 1.0;
    let first = "nothing";
    let firstAt = Vector4.Distance(from, to);
    let w: TraceResult;
    if CMGround.World(this.m_game, a, to, w) {
      firstAt = Vector4.Distance(from, Cast<Vector4>(w.position));
      first = "world";
    }
    let m: TraceResult;
    if CMGround.Movers(this.m_game, a, to, m) {
      let d = Vector4.Distance(from, Cast<Vector4>(m.position));
      if d <= firstAt {
        firstAt = d;
        let e = TraceResult.GetHitEntity(m);
        first = "an entity with no id";
        if IsDefined(e) {
          first = CMCHits.Describe(e as GameObject);
          if IsDefined(this.m_body) && Equals(e.GetEntityID(), this.m_body.Id()) {
            first = "THE MECH'S OWN PHYSICS BOX";
          }
          if IsDefined(mech) && Equals(e.GetEntityID(), mech.GetEntityID()) {
            first = "THE MECH ITSELF";
          }
        }
      }
    }
    let box = "no physics box";
    if IsDefined(this.m_body) && this.m_body.Live() {
      let be = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_body.Id());
      if IsDefined(be) {
        let o = from - be.GetWorldPosition();
        box = "barrel " + FloatToStringPrec(SqrtF(o.X * o.X + o.Y * o.Y), 2) + " m out, " + FloatToStringPrec(o.Z, 2) + " m up from the box's centre";
      }
    }
    let on = "the reticle on nothing";
    let it = s.aimEntity as GameObject;
    if IsDefined(it) && IsDefined(mech) {
      on = "the reticle on " + CMCHits.Describe(it) + ", mech->it " + EnumValueToString("EAIAttitude", Cast<Int64>(EnumInt(GameObject.GetAttitudeBetween(mech, it)))) + ", it->mech " + EnumValueToString("EAIAttitude", Cast<Int64>(EnumInt(GameObject.GetAttitudeBetween(it, mech))));
    }
  }

  private func Through(s: ref<CMCSession>, aim: Vector4, homing: Bool) -> Vector4 {
    if !homing {
      return s.aimWorld;
    }
    let d = aim - s.rig.pos;
    let len = Vector4.Length(d);
    if len < 0.5 {
      return s.aimWorld;
    }
    let dir = d * (1.0 / len);
    let from = aim + dir * 0.5;
    from.W = 1.0;
    let to = aim + dir * 300.0;
    to.W = 1.0;
    let hit: TraceResult;
    if CMGround.World(this.m_game, from, to, hit) {
      let p = Cast<Vector4>(hit.position);
      p.W = 1.0;
      return p;
    }
    return to;
  }

  private func TrackPoint(mech: ref<NPCPuppet>, out at: Vector4) -> Bool {
    let e = this.m_trackEnt;
    if !IsDefined(e) || !IsDefined(mech) {
      return false;
    }
    let pup = e as ScriptedPuppet;
    if IsDefined(pup) && !ScriptedPuppet.IsAlive(pup) {
      this.StopTrack("target down");
      return false;
    }
    let p = e.GetWorldPosition();
    p.Z += 1.1;
    let v = new Vector4(0.0, 0.0, 0.0, 0.0);
    if IsDefined(this.m_sense) {
      for c in this.m_sense.track.contacts {
        if Equals(c.id, e.GetEntityID()) && c.pos.W > 0.5 {
          p = c.pos;
          v = c.vel;
        }
      }
    }
    let d = Vector4.Distance(mech.GetWorldPosition(), p);
    if d > this.TRACK_RANGE {
      this.StopTrack("out of range");
      return false;
    }
    at = p + v * (d / 320.0);
    at.W = 1.0;
    return true;
  }

  public func NewHud() -> ref<CMPilotHud> = new CMMinotaurHud()

  public func Name() -> String {
    let mech = this.Mech();
    if !IsDefined(mech) {
      return CMText.MinoName();
    }
    let look = NameToString(mech.GetCurrentAppearanceName());
    if StrContains(look, "arasaka") {
      return CMText.MinoArasaka();
    }
    if StrContains(look, "police") {
      return CMText.MinoNcpd();
    }
    if StrContains(look, "kurt") {
      return CMText.MinoKurt();
    }
    return CMText.MinoMilitech();
  }
  public func LostReason() -> String = "!" + CMText.MinoDestroyed()

  private func Mech() -> ref<NPCPuppet> {
    if !IsDefined(this.m_mech) {
      this.m_mech = GameInstance.FindEntityByID(this.m_game, this.m_mechID) as NPCPuppet;
    }
    return this.m_mech;
  }

  public func Begin(s: ref<CMCSession>) -> String {
    this.m_game = s.GetGameInstance();
    let link = CMLinkSystem.Get(this.m_game);
    let mech = link.Unit();
    if !link.IsLinked() || !IsDefined(mech) {
      return "!" + CMText.UnitNoUnitLinked();
    }
    if NotEquals(mech.GetNPCType(), gamedataNPCType.Mech) {
      return "!" + CMText.MinoNeedsMech();
    }
    if !ScriptedPuppet.IsAlive(mech) {
      return "!" + CMText.MinoIsDestroyed();
    }
    this.m_mechID = mech.GetEntityID();
    this.m_mech = mech;
    let cfg = CMPilotSystem.Get(this.m_game);
    this.m_sensorUp = Cast<Float>(cfg.CamUpCm()) / 100.0;
    this.m_sensorFwd = Cast<Float>(cfg.CamFwdCm()) / 100.0;
    link.Hold();
    link.SetOrder(CMOrder.Pilot());
    this.m_guns = new CMPilotGuns();
    this.m_load = CMLoadout.For(mech);
    this.m_missile = CMLoadout.On(this.m_load, n"pods");
    this.m_guns.Init(mech, this.m_load);

    if IsDefined(this.m_missile) && TDBID.IsValid(this.m_missile.item) && CMPartLab.IsPlayerMech(mech) {
      this.FitPods(mech, this.m_missile.item);
    }

    if this.HasCounter() {
      this.FitCounter(mech);
    }

    CMPartLab.Apply(mech);
    this.m_mtRefitAt = 0.0;
    this.m_mtSlots = "";
    this.m_moving = false;
    this.m_triggerWas = false;
    this.m_bodyYaw = CMPilotRig.YawOf(mech.GetWorldForward());
    this.m_turnVel = 0.0;
    this.m_turning = false;
    this.m_sentOpen = false;
    let turn = Cast<Float>(cfg.TurnPct()) / 100.0;
    this.m_turnRate = this.TURN_RATE * turn;
    this.m_turnAccel = this.TURN_ACCEL * turn;
    this.m_gate = cfg.FireGate();
    this.m_mtDebug = cfg.ShowDebug();
    this.m_mtRoundTest = cfg.RoundTest();
    this.m_mtFitAt = 0.0;
    this.m_lookMiss = 0;
    ArrayClear(this.m_lookAts);

    let spec = new StaticEntitySpec();
    spec.templatePath = r"base\\entities\\cameras\\simple_free_camera.ent";
    spec.position = mech.GetWorldPosition() + mech.GetWorldForward() * 30.0 + new Vector4(0.0, 0.0, 2.0, 0.0);
    spec.orientation = CMCSession.Identity();
    spec.attached = true;
    this.m_markerID = GameInstance.GetStaticEntitySystem().SpawnEntity(spec);
    this.m_marker = null;

    let fighting = NPCPuppet.IsInCombat(mech) || Equals(mech.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat);
    this.Pacify(mech, true);
    if fighting {
      this.Reboot(mech);

      this.m_lookAtsFrom = s.Now() + 1.0;
    }
    this.m_combatWatch = fighting ? 10 : 0;
    GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_q110_personal_link_01");
    this.LogInventory(mech);
    this.SetFlags(true, s.CreditV());
    this.m_missileReady = 0.0;
    this.m_hull = -1.0;
    this.Armour(mech, s.HullMult());
    this.ReadHull(mech);
    this.m_partsOn = cfg.PartDamage();
    this.m_parts = CMCParts.Get(this.m_game).State(mech.GetEntityID());
    this.m_partNote = "";
    this.m_gait = 1.0;
    this.m_critFx = false;
    this.ApplyParts(s, mech);
    this.m_body = null;
    this.m_bodyLed = false;
    if cfg.MechPhysics() {
      if CMPhysStep.Present() {
        this.m_body = CMMechBody.Make(this.m_game);
        this.m_body.Start(mech, s.Now());
      } else {
      }
    } else {

    }
    return "";
  }

  private func Pacify(mech: ref<NPCPuppet>, on: Bool) -> Void {
    if !IsDefined(mech) {
      return;
    }
    mech.m_cmPiloted = on;
    this.Shield(mech, on);
    let reactions = mech.GetStimReactionComponent();
    if IsDefined(reactions) {
      reactions.Toggle(!on);
    }
    let senses = mech.GetSensesComponent();
    if IsDefined(senses) {
      senses.Toggle(!on);
    }
    let tracker = mech.GetTargetTrackerComponent();
    if IsDefined(tracker) {
      if on {
        tracker.ClearThreats();
      }
      tracker.Toggle(!on);
    }
    if on {
      NPCPuppet.ChangeHighLevelState(mech, gamedataNPCHighLevelState.Relaxed);
    }
    this.m_calmResets = 0;
    this.m_threatClears = 0;
  }

  private func Reboot(mech: ref<NPCPuppet>) -> Void {
    let ai = mech.GetAIControllerComponent();
    if !IsDefined(ai) {
      return;
    }
    ai.Toggle(false);
    ai.Toggle(true);
  }

  private func KeepCalm(s: ref<CMCSession>, mech: ref<NPCPuppet>, now: Float) -> Void {

    if this.m_combatWatch > 0 && now - this.m_combatWatchAt >= 1.0 {
      this.m_combatWatchAt = now;
      this.m_combatWatch -= 1;
      let still = NPCPuppet.IsInCombat(mech);
      if !still {
        this.m_combatWatch = 0;
      }
    }
    let state = mech.GetHighLevelStateFromBlackboard();
    if Equals(state, gamedataNPCHighLevelState.Combat) || Equals(state, gamedataNPCHighLevelState.Alerted) {
      NPCPuppet.ChangeHighLevelState(mech, gamedataNPCHighLevelState.Relaxed);
      let tracker = mech.GetTargetTrackerComponent();
      if IsDefined(tracker) {
        tracker.ClearThreats();
      }
      this.m_calmResets += 1;
      if this.m_calmResets <= 20 {
      }
    }

    let threats = mech.GetTargetTrackerComponent();
    if IsDefined(threats) && threats.HasHostileThreat(false) {
      threats.ClearThreats();
      this.m_threatClears += 1;
      if this.m_threatClears <= 20 {
      }
    }
    this.WatchGuns(s, mech);
    this.ShieldTick(s, mech);

    let reactions = mech.GetStimReactionComponent();
    if IsDefined(reactions) && reactions.IsEnabled() {
      reactions.Toggle(false);
    }
    if this.m_moving {
      this.m_stoodAt = now;
    }
  }

  private func Shield(mech: ref<NPCPuppet>, on: Bool) -> Void {
    let comp = mech.GetWeakspotComponent();
    if !IsDefined(comp) {
      return;
    }
    let spots: array<wref<WeakspotObject>>;
    comp.GetWeakspots(spots);
    let gods = GameInstance.GetGodModeSystem(this.m_game);
    for spot in spots {
      if IsDefined(spot) {
        if on {
          gods.AddGodMode(spot.GetEntityID(), gameGodModeType.Invulnerable, n"ControllableMechs");
        } else {
          gods.RemoveGodMode(spot.GetEntityID(), gameGodModeType.Invulnerable, n"ControllableMechs");
        }
      }
    }
  }

  private func WatchGuns(s: ref<CMCSession>, mech: ref<NPCPuppet>) -> Void {

    let slots = this.m_guns.SlotsNow(mech);
    if NotEquals(slots, this.m_mtSlots) {
      this.m_mtSlots = slots;
    }

    let ready = (this.m_guns.left.Ready() || this.m_guns.left.destroyed ? 1 : 0) + (this.m_guns.right.Ready() || this.m_guns.right.destroyed ? 1 : 0);
    if ready == 2 {
      this.m_gunsLost = false;
      return;
    }
    if !this.m_gunsLost {
      this.m_gunsLost = true;
      this.LogInventory(mech);
    }

    let now = EngineTime.ToFloat(GameInstance.GetSimTime(this.m_game));
    if this.m_mtRefitAt <= 0.0 {
      this.m_mtRefitAt = now + 1.0;
    } else {
      if now >= this.m_mtRefitAt {
        this.m_mtRefitAt = now + 1.0;
        this.m_guns.Refit(mech);
        CMPartLab.Apply(mech);
      }
    }
    if this.m_guns.Refresh(mech) {
      this.m_mtRefitAt = 0.0;
      this.m_gunsLost = false;
      this.SetFlags(true, s.CreditV());
    }
  }

  public func End(s: ref<CMCSession>, hard: Bool) -> Void {
    let mech = this.Mech();
    this.m_sense = null;
    this.m_trackEnt = null;
    this.m_markerOk = false;
    if IsDefined(this.m_body) {
      this.m_body.Stop(mech);
      this.m_body = null;
    }
    this.StopServo(mech);
    this.StopFireLoop(mech);
    if IsDefined(mech) {
      this.Armour(mech, 1.0);
    }
    GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"q110_sc_08c_personal_link_disconnected");
    if IsDefined(mech) && this.m_critFx {
      GameObjectEffectHelper.StopEffectEvent(mech, n"hacks_overheat_lvl2");
    }
    this.m_critFx = false;

    if IsDefined(mech) && !ScriptedPuppet.IsAlive(mech) {
      CMCParts.Get(this.m_game).DropFx(mech);
      GameObjectEffectHelper.StartEffectEvent(mech, n"explode_death");
    }
    if IsDefined(mech) && this.m_gait != 1.0 {
      mech.UnsetIndividualTimeDilation();
    }
    this.m_gait = 1.0;
    this.Pacify(mech, false);

    if CMPartLab.IsPlayerMech(mech) {
      let again = new CMPartLabReapply();
      again.unit = mech;
      GameInstance.GetDelaySystem(this.m_game).DelayCallback(again, 1.0, false);
      let later = new CMPartLabReapply();
      later.unit = mech;
      GameInstance.GetDelaySystem(this.m_game).DelayCallback(later, 4.0, false);
    }
    if IsDefined(mech) {
      this.CancelCmd(mech, this.m_moveCmd);
      this.CancelCmd(mech, this.m_turnCmd);
      for ev in this.m_lookAts {
        let r = new LookAtRemoveEvent();
        r.lookAtRef = ev.outLookAtRef;
        mech.QueueEvent(r);
      }
    }
    ArrayClear(this.m_lookAts);
    this.m_moveCmd = null;
    this.m_turnCmd = null;
    this.m_marker = null;
    if EntityID.IsDefined(this.m_markerID) {
      GameInstance.GetStaticEntitySystem().DespawnEntity(this.m_markerID);
    }
    let empty: EntityID;
    this.m_markerID = empty;

    if IsDefined(this.m_guns) {
      this.SetFlags(false, false);
      this.m_guns.SlowDown(this.m_game);
    }
    let link = CMLinkSystem.Get(this.m_game);
    if IsDefined(link) && link.IsLinked() {
      link.Hold();
    }
    this.m_guns = null;
  }

  public func IsAlive() -> Bool {
    let mech = this.Mech();
    return IsDefined(mech) && ScriptedPuppet.IsAlive(mech);
  }

  public func Ground() -> Vector4 = this.Mech().GetWorldPosition()
  public func Facing() -> Float = CMPilotRig.YawOf(this.Mech().GetWorldForward())
  public func SensorUp() -> Float = this.m_sensorUp
  public func SensorFwd() -> Float = this.m_sensorFwd
  public func AimSkip() -> Float = 4.5

  public func Tick(s: ref<CMCSession>, dt: Float, now: Float) -> Void {
    let mech = this.Mech();

    let aim = s.aim;
    let tracked: Vector4;
    let tracking = this.TrackPoint(mech, tracked);

    let homing = tracking;
    if tracking {
      aim = tracked;
    }

    let shotAim = this.Through(s, aim, homing);
    this.MoveMarker(this.EaseMarker(mech, aim, dt));
    this.BodyTick(s, mech, dt, now);
    this.TurnChassis(s, mech, dt);
    let split = s.FireMode() == CMFireMode.Split();
    let trigger = s.Key(CMCKey.Lmb()) || (split && s.Key(CMCKey.Rmb()));

    if trigger {
      this.m_spin = MinF(1.0, this.m_spin + dt / this.m_guns.left.spec.spinUp);
    } else {
      this.m_spin = MaxF(0.0, this.m_spin - dt / this.m_guns.left.spec.spinDown);
    }
    this.m_guns.rate = 0.35 + 0.65 * this.m_spin;
    let spun = this.m_spin >= this.m_guns.left.spec.spinFire;
    let lmb = spun && s.Key(CMCKey.Lmb());
    let rmb = spun && split && s.Key(CMCKey.Rmb());

    let offL = CMCSession.AimError(this.m_guns.left.weapon, aim) > this.GATE_DEG;
    let offR = CMCSession.AimError(this.m_guns.right.weapon, aim) > this.GATE_DEG;

    this.m_guns.left.offAim = this.m_gate && offL;
    this.m_guns.right.offAim = this.m_gate && offR;
    this.OwnTarget(this.m_guns.left, !this.m_gate && offL && trigger && !homing, now, dt);
    this.OwnTarget(this.m_guns.right, !this.m_gate && offR && trigger && !homing, now, dt);
    let flashL = this.m_guns.left.flash;
    let flashR = this.m_guns.right.flash;
    this.m_guns.ownerV = this.m_mtRoundTest == 1;
    this.m_guns.trace = this.m_mtDebug;
    let shots = this.m_guns.Update(mech, now, dt, lmb, rmb, s.FireMode(), shotAim, s.rig.pos);

    if ArraySize(this.m_guns.roundFrom) > 0 {
      if this.m_mtDebug {
        let k = 0;
        while k < ArraySize(this.m_guns.roundFrom) {
          this.m_traceN += 1;
          if this.m_traceN % 6 == 1 {
            this.RoundTrace(s, mech, this.m_guns.roundFrom[k], this.m_guns.roundTo[k]);
          }
          k += 1;
        }
      }
      ArrayClear(this.m_guns.roundFrom);
      ArrayClear(this.m_guns.roundTo);
    }

    if this.m_guns.fired > 0 && now >= this.m_roundLogAt {
      this.m_roundLogAt = now + 2.0;
      this.m_guns.fired = 0;
    }
    if shots > 0 {
      s.rig.Recoil(this.m_guns.left.spec.kick * Cast<Float>(shots));

      if this.m_guns.left.flash > flashL {
        this.RoundFx(this.m_guns.left, this.m_guns.left.ownTarget ? this.m_guns.left.target : shotAim);
      }
      if this.m_guns.right.flash > flashR && this.m_guns.right.weapon != this.m_guns.left.weapon {
        this.RoundFx(this.m_guns.right, this.m_guns.right.ownTarget ? this.m_guns.right.target : shotAim);
      }
    }
    if trigger && !this.m_triggerWas {
      s.FlashTag(CMPilotHud.TagFire());
    }
    this.m_triggerWas = trigger;
    this.Servo(s, mech, now);
    this.GunAudio(mech, trigger, shots > 0);
    let hud = s.Hud();
    if IsDefined(hud) {
      hud.FadeHit(dt);
      hud.SetGunState(!offL, this.m_guns.left.heat, !offR, this.m_guns.right.heat);
      hud.Flash(this.m_guns.left.flash > 0.0, this.m_guns.right.flash > 0.0);
      let range = tracking ? Vector4.Distance(s.rig.pos, aim) : (s.aimDist > 1.0 ? s.aimDist : 150.0);
      let l = s.PipOffset(this.m_guns.BarrelPoint(this.m_guns.left, range));
      let r = s.PipOffset(this.m_guns.BarrelPoint(this.m_guns.right, range));
      hud.SetPips(l.X, l.Y, this.m_guns.left.Ready() && AbsF(l.X) < 1900.0 && AbsF(l.Y) < 1050.0, r.X, r.Y, this.m_guns.right.Ready() && AbsF(r.X) < 1900.0 && AbsF(r.Y) < 1050.0);

      let mhud = hud as CMMinotaurHud;
      if IsDefined(mhud) && IsDefined(mech) {
        if !IsDefined(this.m_sense) {
          this.m_sense = CMDroneSense.Make(false);
        }
        this.m_sense.Tick(s, this, mech, mech.GetWorldPosition(), now, dt);

        if tracking && IsDefined(this.m_trackEnt) {
          for c in this.m_sense.track.contacts {
            if Equals(c.id, this.m_trackEnt.GetEntityID()) {
              this.m_sense.track.lock = c;
            }
          }
        }
        mhud.SetTracking(tracking);
        mhud.Track(this.m_sense.track);

        if now >= this.m_mtSysAt {
          this.m_mtSysAt = now + 0.25;

          if now >= this.m_mtFitAt {
            this.m_mtFitAt = now + 2.0;
            let cfg = CMPilotSystem.Get(this.m_game);
            let mine = CMPartLab.IsPlayerMech(mech);
            this.m_mtFitJets = mine && CMPartLab.Up(cfg, "jets");
            this.m_mtFitShield = mine && CMPartLab.Up(cfg, "shield");
            this.m_mtFitCounter = this.HasCounter();
            this.m_mtDebug = cfg.ShowDebug();
          }
          let at = s.Now();
          let jets = this.m_mtFitJets ? (at < this.m_mtJumpAt ? IntToString(CeilF(this.m_mtJumpAt - at)) + " S" : "READY") : "";
          let cntr = this.m_mtFitCounter ? (at < this.m_mtCounterAt ? IntToString(CeilF(this.m_mtCounterAt - at)) + " S" : "READY") : "";
          let shield = this.m_mtFitShield ? mech.m_cmShieldCharge : -1.0;
          mhud.SetSystems(jets, cntr, shield, mech.m_cmShieldUp, this.m_mtLightsOn);
        }
      }
    }
  }

  private func TurnChassis(s: ref<CMCSession>, mech: ref<NPCPuppet>, dt: Float) -> Void {
    let real = CMPilotRig.YawOf(mech.GetWorldForward());
    let now = s.Now();

    let bodied = IsDefined(this.m_body) && this.m_body.Live();
    if this.m_moving && bodied && !this.m_air {

      this.SwingHeading(s, mech, dt);
      this.m_sentOpen = false;
      return;
    }
    if this.m_moving || this.m_air || now - this.m_stoodAt < 0.8 {

      this.m_bodyYaw = real;
      this.m_turnVel = 0.0;
      this.m_turning = false;
      this.m_sentOpen = false;
      return;
    }

    if this.m_sentOpen && AbsF(CMPilotRig.Wrap(real - this.m_sentYaw)) < 3.5 {
      this.m_sentOpen = false;
    }
    this.SwingHeading(s, mech, dt);

    if AbsF(CMPilotRig.Wrap(real - this.m_bodyYaw)) > 0.7 && (!this.m_sentOpen || now - this.m_sentAt > 0.45) {
      let world: WorldPosition;
      WorldPosition.SetVector4(world, mech.GetWorldPosition() + CMPilotRig.Dir(this.m_bodyYaw, 0.0) * 20.0);
      let spec: AIPositionSpec;
      AIPositionSpec.SetWorldPosition(spec, world);
      let cmd = new AIRotateToCommand();
      cmd.target = spec;
      cmd.angleTolerance = 1.0;
      this.Send(mech, cmd, false);
      this.m_sentYaw = this.m_bodyYaw;
      this.m_sentAt = now;
      this.m_sentOpen = true;
    }
  }

  private func SwingHeading(s: ref<CMCSession>, mech: ref<NPCPuppet>, dt: Float) -> Void {
    let off = CMPilotRig.Wrap(s.rig.yaw - this.m_bodyYaw);
    if !this.m_turning {

      let start = AbsF(s.rig.YawRate()) > 15.0 ? this.TURN_START_SWEEP_DEG : this.TURN_START_DEG;
      if AbsF(off) >= start {
        this.m_turning = true;
        if !this.m_moving {
          GameObject.PlaySoundEvent(mech, AbsF(off) > 120.0 ? n"enm_mech_minotaur_loco_idle_to_idle_180_l" : n"enm_mech_minotaur_loco_idle_to_idle_90");
        }
      }
    }
    if this.m_turning {

      let still = this.m_moving ? 1.0 : 0.55;
      let want = ClampF(off * this.TURN_K, -this.m_turnRate * still, this.m_turnRate * still);
      let step = this.m_turnAccel * (this.m_moving ? 1.0 : 0.6) * dt;
      this.m_turnVel += ClampF(want - this.m_turnVel, -step, step);
      if AbsF(off) < 1.0 && AbsF(this.m_turnVel) < 3.0 {
        this.m_turnVel = 0.0;
        this.m_turning = false;
      } else {
        this.m_bodyYaw = CMPilotRig.Wrap(this.m_bodyYaw + this.m_turnVel * dt);
      }
    }
  }

  private func OwnTarget(g: ref<CMGun>, off: Bool, now: Float, dt: Float) -> Void {
    g.ownTarget = false;
    if !off || !g.Ready() || now < g.nextShot - dt {
      return;
    }
    let fwd = g.weapon.GetWorldForward();
    let from = g.weapon.GetWorldPosition() + fwd * 2.0;
    let to = from + fwd * 300.0;
    let at = from + fwd * 150.0;
    let hit: TraceResult;

    if CMGround.World(this.m_game, from, to, hit) {
      at = Cast<Vector4>(hit.position);
    }
    at.W = 1.0;
    g.target = at;
    g.ownTarget = true;
  }

  private func RoundFx(g: ref<CMGun>, aim: Vector4) -> Void {
    let weapon = g.weapon;
    if !IsDefined(weapon) {
      return;
    }
    if !g.spec.addedFx {
      return;
    }
    let fx = GameInstance.GetFxSystem(this.m_game);
    let dir = Vector4.Normalize(aim - weapon.GetWorldPosition());
    let muzzle = weapon.GetWorldPosition() + dir * g.spec.muzzleAhead;
    fx.SpawnEffect(CMUMinotaur.Fx(g.spec.muzzleFx), CMUMinotaur.At(muzzle, dir), true);
    fx.SpawnEffect(CMUMinotaur.Fx(g.spec.trailFx), CMUMinotaur.At(muzzle, dir), true);
  }

  public static func Fx(path: ResRef) -> FxResource {
    let ref: ResourceAsyncRef;
    ResourceAsyncRef.SetPath(ref, path);
    let fx: FxResource;
    fx.effect = ref;
    return fx;
  }

  public static func At(p: Vector4, dir: Vector4) -> WorldTransform {
    let wp: WorldPosition;
    WorldPosition.SetVector4(wp, p);
    let wt: WorldTransform;
    WorldTransform.SetWorldPosition(wt, wp);
    WorldTransform.SetOrientationFromDir(wt, dir);
    return wt;
  }

  public func Secondary(s: ref<CMCSession>) -> Void {
    let mech = this.Mech();
    let now = s.Now();
    let w = this.m_missile;
    if !IsDefined(mech) {
      return;
    }
    if !IsDefined(w) || now < this.m_missileReady || this.PartHp(CMPart.Pods()) <= 0.0 {
      GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_hacking_press_fail");
      return;
    }

    if TDBID.IsValid(w.item) {
      this.FireLauncher(s, mech, w, now);
      return;
    }

    this.m_missileReady = now + w.cooldown * (this.PartHp(CMPart.Pods()) < 0.5 ? 1.5 : 1.0);
    let at = s.aim;

    let flight = ClampF(Vector4.Distance(mech.GetWorldPosition(), at) / w.speed, 0.25, 2.5);
    GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_wpn_missile_fire_single");
    s.rig.Recoil(0.9);
    let cb = new CMUMinotaurMissileCb();
    cb.unit = this;
    cb.at = at;
    GameInstance.GetDelaySystem(this.m_game).DelayCallback(cb, flight, false);
  }

  private let m_mtPodSlot: TweakDBID;

  private func FitPods(mech: ref<NPCPuppet>, item: TweakDBID) -> Void {
    let slots: array<TweakDBID>;

    ArrayPush(slots, t"AttachmentSlots.MNC_Pod");
    ArrayPush(slots, t"AttachmentSlots.Chest");
    ArrayPush(slots, t"AttachmentSlots.Head");
    ArrayPush(slots, t"AttachmentSlots.LeftArm");
    ArrayPush(slots, t"AttachmentSlots.RightArm");
    let i = 0;
    while i < ArraySize(slots) {
      if ItemID.IsValid(CMPilotGuns.FitSlot(mech, slots[i], item, ItemID.None(), "pods")) {
        this.m_mtPodSlot = slots[i];
        return;
      }
      i += 1;
    }
  }

  private func Launcher(mech: ref<NPCPuppet>) -> ref<WeaponObject> {
    if !TDBID.IsValid(this.m_mtPodSlot) {
      return null;
    }
    return GameInstance.GetTransactionSystem(this.m_game).GetItemInSlot(mech, this.m_mtPodSlot) as WeaponObject;
  }

  private func FireLauncher(s: ref<CMCSession>, mech: ref<NPCPuppet>, w: ref<CMWeaponSpec>, now: Float) -> Void {
    let launcher = this.Launcher(mech);
    if !IsDefined(launcher) || !launcher.IsAttached() || ItemID.GetTDBID(launcher.GetItemID()) != w.item {
      GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_hacking_press_fail");
      this.FitPods(mech, w.item);
      return;
    }
    this.m_missileReady = now + w.cooldown * (this.PartHp(CMPart.Pods()) < 0.5 ? 1.5 : 1.0);
    launcher.m_cmPiloted = true;
    launcher.m_cmCreditV = s.CreditV();
    GameObject.PlaySoundEvent(launcher, n"nme_boss_smasher_wpn_missile_fire");
    s.rig.Recoil(0.9);
    let at = s.aim;
    let n = Max(1, w.salvo);
    let i = 0;
    while i < n {
      let p = at;
      if n > 1 {
        let r = w.scatter * SqrtF(RandF());
        let ang = RandRangeF(0.0, 6.2832);
        p = new Vector4(at.X + r * CosF(ang), at.Y + r * SinF(ang), at.Z, 1.0);
        let hit: TraceResult;
        if CMGround.World(this.m_game, p + new Vector4(0.0, 0.0, 12.0, 0.0), p - new Vector4(0.0, 0.0, 12.0, 0.0), hit) {
          p = Cast<Vector4>(hit.position);
          p.W = 1.0;
        }
      }
      let cb = new CMUMinotaurRainCb();
      cb.unit = this;
      cb.at = p;
      GameInstance.GetDelaySystem(this.m_game).DelayCallback(cb, 0.01 + Cast<Float>(i) * w.salvoGap, false);
      i += 1;
    }
  }

  public func FireRain(at: Vector4) -> Void {
    let mech = this.Mech();
    if !IsDefined(mech) {
      return;
    }
    let launcher = this.Launcher(mech);
    if IsDefined(launcher) && launcher.IsAttached() {
      AIWeapon.Fire(mech, launcher, EngineTime.ToFloat(GameInstance.GetSimTime(this.m_game)), 0.0, gamedataTriggerMode.FullAuto, at);

      GameObject.PlaySoundEvent(launcher, n"nme_boss_smasher_wpn_missile_fire_single");
    }
  }

  private let m_mtCounterAt: Float;
  private let COUNTER_COOLDOWN: Float = 20.0;
  private let COUNTER_RADIUS: Float = 30.0;

  public func HasExtras() -> Bool = true

  private let m_mtLightsOn: Bool;
  private let m_mtSysAt: Float;
  private let m_mtFitAt: Float;
  private let m_mtFitJets: Bool;
  private let m_mtFitShield: Bool;
  private let m_mtFitCounter: Bool;
  private let m_mtDebug: Bool;
  private let m_mtRoundTest: Int32;
  public func Lights(s: ref<CMCSession>) -> Bool {
    let mech = this.Mech();
    if !IsDefined(mech) {
      return false;
    }
    this.m_mtLightsOn = !this.m_mtLightsOn;
    let n = 0;
    for c in mech.GetComponents() {
      let l = c as gameLightComponent;
      if IsDefined(l) {
        l.ToggleLight(this.m_mtLightsOn);
        n += 1;
      }
    }
    GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_menu_onpress");
    return true;
  }

  private let m_mtJumpAt: Float;
  private let JUMP_UP: Float = 9.0;
  private let JUMP_FORWARD: Float = 5.0;
  private let JUMP_COOLDOWN: Float = 5.0;

  public func Jump(s: ref<CMCSession>) -> Bool {
    let mech = this.Mech();
    if !CMPartLab.IsPlayerMech(mech) || !CMPartLab.Up(CMPilotSystem.Get(this.m_game), "jets") {
      return false;
    }
    let now = s.Now();
    if now < this.m_mtJumpAt {
      GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_hacking_press_fail");
      return true;
    }
    if !IsDefined(this.m_body) {
      GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_hacking_press_fail");
      return true;
    }
    this.m_mtJumpAt = now + this.JUMP_COOLDOWN;
    let fwd = mech.GetWorldForward();
    let dv = new Vector4(0.0, 0.0, this.JUMP_UP, 0.0) + fwd * (this.m_moving ? this.JUMP_FORWARD : 0.0);
    this.m_body.Push(mech, dv, now, "jump jets");
    let fx = GameInstance.GetFxSystem(this.m_game);
    let down = new Vector4(0.0, 0.0, -1.0, 0.0);
    let side = new Vector4(fwd.Y, -fwd.X, 0.0, 0.0);
    let base = mech.GetWorldPosition() + new Vector4(0.0, 0.0, 1.0, 0.0);
    fx.SpawnEffect(CMUMinotaur.Fx(r"mnc\\fx\\octant_thruster_one.effect"), CMUMinotaur.At(base + side * 0.9, down), true);
    fx.SpawnEffect(CMUMinotaur.Fx(r"mnc\\fx\\octant_thruster_one.effect"), CMUMinotaur.At(base - side * 0.9, down), true);
    GameObject.PlaySoundEvent(mech, n"v_av_panzer_wea_countermeasures_fire");
    s.rig.Nudge(6.0, -0.6);
    return true;
  }

  private let SHIELD_RECHARGE: Float = 0.08;
  private let m_mtShieldTickAt: Float;

  public func ShieldKey(s: ref<CMCSession>) -> Bool {
    let mech = this.Mech();
    if !CMPartLab.IsPlayerMech(mech) || !CMPartLab.Up(CMPilotSystem.Get(this.m_game), "shield") {
      return false;
    }
    if !mech.m_cmShieldUp && mech.m_cmShieldCharge < 0.2 {
      GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_hacking_press_fail");
      return true;
    }
    this.SetShield(mech, !mech.m_cmShieldUp, "the key");
    return true;
  }

  private func SetShield(mech: ref<NPCPuppet>, up: Bool, why: String) -> Void {

    mech.m_cmShieldUp = up;
    GameObject.PlaySoundEvent(mech, up ? n"nme_ability_camo_activate" : n"nme_ability_camo_deactivate");
  }

  private func ShieldTick(s: ref<CMCSession>, mech: ref<NPCPuppet>) -> Void {
    let now = s.Now();
    let dt = this.m_mtShieldTickAt > 0.0 ? ClampF(now - this.m_mtShieldTickAt, 0.0, 1.0) : 0.0;
    this.m_mtShieldTickAt = now;
    if !this.m_mtFitShield {
      return;
    }
    if mech.m_cmShieldUp {
      if mech.m_cmShieldCharge <= 0.0 {
        this.SetShield(mech, false, "spent");
      }
    } else {
      mech.m_cmShieldCharge = MinF(1.0, mech.m_cmShieldCharge + this.SHIELD_RECHARGE * dt);
    }
  }

  public func HasCounter() -> Bool {
    let mech = this.Mech();
    if !CMPartLab.IsPlayerMech(mech) {
      return false;
    }
    let cfg = CMPilotSystem.Get(this.m_game);
    return CMPartLab.On(cfg, 12) || CMPartLab.On(cfg, 13);
  }

  private let m_mtCounterSlot: TweakDBID;
  private let COUNTER_ROUNDS: Int32 = 6;

  private func FitCounter(mech: ref<NPCPuppet>) -> Void {
    let slots: array<TweakDBID>;
    ArrayPush(slots, t"AttachmentSlots.Head");
    ArrayPush(slots, t"AttachmentSlots.LeftArm");
    ArrayPush(slots, t"AttachmentSlots.RightArm");
    let i = 0;
    while i < ArraySize(slots) {
      if slots[i] != this.m_mtPodSlot && ItemID.IsValid(CMPilotGuns.FitSlot(mech, slots[i], t"Items.Panzer_Counter_Measures_Launcher", ItemID.None(), "countermeasures")) {
        this.m_mtCounterSlot = slots[i];
        return;
      }
      i += 1;
    }
  }

  private func FireCounter(s: ref<CMCSession>, mech: ref<NPCPuppet>) -> Int32 {
    if !TDBID.IsValid(this.m_mtCounterSlot) {
      return 0;
    }
    let launcher = GameInstance.GetTransactionSystem(this.m_game).GetItemInSlot(mech, this.m_mtCounterSlot) as WeaponObject;
    if !IsDefined(launcher) || !launcher.IsAttached() {
      return 0;
    }
    launcher.m_cmPiloted = true;
    launcher.m_cmCreditV = s.CreditV();
    let at = mech.GetWorldPosition();
    let now = s.Now();
    let k = 0;
    while k < this.COUNTER_ROUNDS {
      let a = Cast<Float>(k) * 6.2832 / Cast<Float>(this.COUNTER_ROUNDS);
      let p = new Vector4(at.X + 15.0 * CosF(a), at.Y + 15.0 * SinF(a), at.Z + 18.0, 1.0);
      AIWeapon.Fire(mech, launcher, now, 0.0, gamedataTriggerMode.FullAuto, p);
      k += 1;
    }
    GameObject.PlaySoundEvent(mech, n"v_av_panzer_wea_countermeasures_fire");
    return this.COUNTER_ROUNDS;
  }

  public func Counter(s: ref<CMCSession>) -> Void {
    let mech = this.Mech();
    let now = s.Now();
    if !IsDefined(mech) || now < this.m_mtCounterAt {
      GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_hacking_press_fail");
      return;
    }
    this.m_mtCounterAt = now + this.COUNTER_COOLDOWN;
    let fired = this.FireCounter(s, mech);
    let at = mech.GetWorldPosition();
    let fx = GameInstance.GetFxSystem(this.m_game);
    let up = new Vector4(0.0, 0.0, 1.0, 0.0);
    let k = 0;
    while k < 4 {
      let a = Cast<Float>(k) * 1.5708;
      let p = new Vector4(at.X + 4.0 * CosF(a), at.Y + 4.0 * SinF(a), at.Z, 1.0);
      fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\smoke_grenade\\w_explosives_001_smoke_grenade_01.effect"), CMUMinotaur.At(p, up), true);
      k += 1;
    }
    fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\environment\\flares\\maxtac_prevention_system_av_flare.effect"), CMUMinotaur.At(at + new Vector4(0.0, 0.0, 4.0, 0.0), up), true);

    let pl = GetPlayer(this.m_game);
    let blinded = 0;
    if IsDefined(pl) {
      let q: TargetSearchQuery;
      q.testedSet = TargetingSet.Complete;
      q.searchFilter = TSF_All(TSFMV.Obj_Puppet | TSFMV.St_AliveAndActive);
      q.maxDistance = MinF(400.0, this.COUNTER_RADIUS + Vector4.Distance(pl.GetWorldPosition(), at));
      q.filterObjectByDistance = true;
      q.includeSecondaryTargets = false;
      q.ignoreInstigator = true;
      let parts: array<TS_TargetPartInfo>;
      GameInstance.GetTargetingSystem(this.m_game).GetTargetParts(pl, q, parts);
      for p in parts {
        let comp = TS_TargetPartInfo.GetComponent(p);
        let npc: ref<NPCPuppet>;
        if IsDefined(comp) {
          npc = comp.GetEntity() as NPCPuppet;
        }
        if IsDefined(npc) && !npc.IsDead() && npc != mech && Vector4.Distance(npc.GetWorldPosition(), at) <= this.COUNTER_RADIUS
          && Equals(GameObject.GetAttitudeTowards(npc, mech), EAIAttitude.AIA_Hostile) {
          StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.Blind", mech.GetEntityID());
          blinded += 1;
        }
      }
    }
    s.FlashTag(CMPilotHud.TagFire());
  }

  public func Detonate(at: Vector4) -> Void {
    let player = GetPlayer(this.m_game);
    let w = this.m_missile;
    if !IsDefined(player) || !IsDefined(w) {
      return;
    }

    GameInstance.GetFxSystem(this.m_game).SpawnEffect(CMUMinotaur.Fx(w.blastFx), CMUMinotaur.At(at, new Vector4(0.0, 0.0, 1.0, 0.0)), true);

    let used = "Attacks.CM_Missile";
    let record = TweakDBInterface.GetAttackRecord(t"Attacks.CM_Missile") as Attack_GameEffect_Record;
    if !IsDefined(record) {
      used = "Attacks.FragGrenade";
      record = TweakDBInterface.GetAttackRecord(t"Attacks.FragGrenade") as Attack_GameEffect_Record;
    }
    if !IsDefined(record) {
      return;
    }
    let ctx: AttackInitContext;
    ctx.record = record;
    ctx.instigator = player;
    ctx.source = player;
    let attack = IAttack.Create(ctx) as Attack_GameEffect;
    if !IsDefined(attack) {
      return;
    }
    attack.AddStatModifier(RPGManager.CreateStatModifier(gamedataStatType.PhysicalDamage, gameStatModifierType.Additive, w.damage));
    let statMods: array<ref<gameStatModifierData>>;
    attack.GetStatModList(statMods);
    let flags: array<SHitFlag>;
    let effect = attack.PrepareAttack(player);
    EffectData.SetFloat(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.radius, w.radius);
    EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.position, at);
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attack, ToVariant(attack));
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attackStatModList, ToVariant(statMods));
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.flags, ToVariant(flags));

    let mech = this.Mech();
    if IsDefined(mech) {
      CMCHits.Blame(mech, 0.6);
    }
    attack.StartAttack();
  }

  private func LogInventory(mech: ref<NPCPuppet>) -> Void {
    let items: array<wref<gameItemData>>;
    GameInstance.GetTransactionSystem(this.m_game).GetItemList(mech, items);
    let names = "";
    for item in items {
      names += (StrLen(names) > 0 ? ", " : "") + TDBID.ToStringDEBUG(ItemID.GetTDBID(item.GetID()));
    }
  }

  private func GunAudio(mech: ref<NPCPuppet>, trigger: Bool, fired: Bool) -> Void {

    let hmg = this.m_guns.left.spec.hmgSound || this.m_guns.right.spec.hmgSound;
    if hmg && trigger && !this.m_audioTrigger {
      GameObject.PlaySoundEvent(mech, n"w_gun_hmg_militech_init");
    }
    if hmg && !trigger && this.m_audioTrigger && this.m_spin > this.m_guns.left.spec.spinFire {
      GameObject.PlaySoundEvent(mech, n"w_gun_hmg_militech_shutdown");
    }
    this.m_audioTrigger = trigger;
    if hmg && fired && !this.m_fireLoop {
      this.m_fireLoop = true;
      GameObject.PlaySoundEvent(mech, n"w_gun_hmg_militech_fire_auto");
    }
    let locked = this.m_guns.left.locked && this.m_guns.right.locked;
    if this.m_fireLoop && (!trigger || locked) {
      this.StopFireLoop(mech);
    }
    let heat = MaxF(this.m_guns.left.heat, this.m_guns.right.heat);
    if heat > 0.8 && !this.m_heatWarned {
      this.m_heatWarned = true;
      GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_hacking_press_fail");
    }
    if heat < 0.6 {
      this.m_heatWarned = false;
    }
    let anyLocked = this.m_guns.left.locked || this.m_guns.right.locked;
    if anyLocked && !this.m_audioLocked {
      GameObject.PlaySoundEvent(mech, n"w_gun_hmg_militech_overheat_open");
      GameObject.PlaySoundEvent(mech, n"w_gun_hmg_militech_overheat_steam");
    }
    if !anyLocked && this.m_audioLocked {
      GameObject.PlaySoundEvent(mech, n"w_gun_hmg_militech_overheat_close");
    }
    this.m_audioLocked = anyLocked;
  }

  private func StopFireLoop(mech: ref<NPCPuppet>) -> Void {
    if !this.m_fireLoop {
      return;
    }
    this.m_fireLoop = false;
    if IsDefined(mech) {
      GameObject.StopSoundEvent(mech, n"w_gun_hmg_militech_fire_auto");
      GameObject.PlaySoundEvent(mech, n"w_gun_hmg_militech_fire_auto_stop");
    }
  }

  private func ReadHull(mech: ref<NPCPuppet>) -> Float {
    let pools = GameInstance.GetStatPoolsSystem(this.m_game);
    let id = Cast<StatsObjectID>(mech.GetEntityID());
    let points = pools.GetStatPoolValue(id, gamedataStatPoolType.Health, false);
    let max = pools.GetStatPoolMaxPointValue(id, gamedataStatPoolType.Health);
    let frac = max > 0.0 ? ClampF(points / max, 0.0, 1.0) : 0.0;
    if AbsF(frac - this.m_hull) >= 0.01 {
    }

    if this.m_hull >= 0.0 && frac < this.m_hull - 0.002 {
      let hud = CMCSession.Get(this.m_game).Hud();
      if IsDefined(hud) {
        hud.Damage(this.m_hull - frac);
      }
    }
    this.m_hull = frac;
    return frac;
  }

  private func Armour(mech: ref<NPCPuppet>, mult: Float) -> Void {
    let stats = GameInstance.GetStatsSystem(this.m_game);
    let pools = GameInstance.GetStatPoolsSystem(this.m_game);
    let id = Cast<StatsObjectID>(mech.GetEntityID());
    let before = pools.GetStatPoolMaxPointValue(id, gamedataStatPoolType.Health);
    if IsDefined(this.m_armour) {
      stats.RemoveModifier(id, this.m_armour);
      this.m_armour = null;
    }
    if mult > 1.01 {
      this.m_armour = RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Multiplier, mult);
      stats.AddModifier(id, this.m_armour);
    }
  }

  private func IntegrityAlarm(mech: ref<NPCPuppet>, now: Float) -> Void {
    let hp = this.m_hull;
    if hp < 0.3 {
      if !this.m_lowAlarm {
        this.m_lowAlarm = true;

        GameObject.PlaySoundEvent(mech, n"dev_alarm_02");
        GameObject.PlaySoundEvent(mech, n"dev_drone_octant_default_sgn_reprimand_final_warning");
      }
      if now >= this.m_beepNext {
        this.m_beepNext = now + 0.25 + 0.95 * (hp / 0.3);

        GameObject.PlaySoundEvent(mech, n"dev_drone_griffin_default_sgn_idle_beep");
        GameObject.PlaySoundEvent(mech, n"dev_drone_octant_default_sgn_idle_beep");
      }
    }
    if hp > 0.4 {
      this.m_lowAlarm = false;
    }
  }

  private func Servo(s: ref<CMCSession>, mech: ref<NPCPuppet>, now: Float) -> Void {
    let rate = AbsF(s.rig.YawRate());
    if !this.m_servoOn && (rate > 8.0 || this.m_turning) {
      this.m_servoOn = true;
      GameObject.PlaySoundEvent(mech, n"dev_surveillance_camera_rotating");
      if now - this.m_servoHit > 0.6 {
        this.m_servoHit = now;
        GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_lcm_servo_short");
      }
    } else {
      if this.m_servoOn && rate < 3.0 && !this.m_turning {
        this.StopServo(mech);
      }
    }
  }

  private func StopServo(mech: ref<NPCPuppet>) -> Void {
    if !this.m_servoOn {
      return;
    }
    this.m_servoOn = false;
    if IsDefined(mech) {
      GameObject.StopSoundEvent(mech, n"dev_surveillance_camera_rotating");
      GameObject.PlaySoundEvent(mech, n"dev_surveillance_camera_rotating_stop");
    }
  }

  private func SetFlags(piloted: Bool, credit: Bool) -> Void {
    let weapons: array<wref<WeaponObject>> = [this.m_guns.left.weapon, this.m_guns.right.weapon];
    for w in weapons {
      if IsDefined(w) {
        w.m_cmPiloted = piloted;
        w.m_cmCreditV = piloted && credit;
        w.m_cmHmg = piloted;
        w.m_cmPlasma = ItemID.GetTDBID(w.GetItemID()) == CMWeaponSpecs.Plasma().item;
        w.m_cmFieldHmg = ItemID.GetTDBID(w.GetItemID()) == CMWeaponSpecs.FieldHmg().item;
      }
    }
  }

  private func EaseMarker(mech: ref<NPCPuppet>, aim: Vector4, dt: Float) -> Vector4 {
    if !IsDefined(mech) {
      return aim;
    }
    let chest = mech.GetWorldPosition() + new Vector4(0.0, 0.0, 2.2, 0.0);
    if !this.m_markerOk {
      this.m_markerOk = true;
      this.m_markerAt = aim;
      return aim;
    }
    let k = 1.0 - ExpF(-this.MARKER_EASE * dt);
    let d0 = this.m_markerAt - chest;
    let d1 = aim - chest;
    let r0 = Vector4.Length(d0);
    let r1 = Vector4.Length(d1);
    if r0 < 0.5 || r1 < 0.5 {
      this.m_markerAt = aim;
      return aim;
    }
    let dir = Vector4.Normalize(Vector4.Normalize(d0) * (1.0 - k) + Vector4.Normalize(d1) * k);
    let r = r0 + (r1 - r0) * k;
    this.m_markerAt = chest + dir * r;
    this.m_markerAt.W = 1.0;
    return this.m_markerAt;
  }

  private func MoveMarker(at: Vector4) -> Void {
    if !IsDefined(this.m_marker) {
      return;
    }
    let world: WorldPosition;
    WorldPosition.SetVector4(world, at);
    let wt: WorldTransform;
    WorldTransform.SetWorldPosition(wt, world);
    WorldTransform.SetOrientation(wt, CMCSession.Identity());
    this.m_marker.SetWorldTransform(wt);
  }

  public func SlowTick(s: ref<CMCSession>, now: Float) -> String {
    let link = CMLinkSystem.Get(this.m_game);
    let mech = this.Mech();
    if !link.IsLinked() || !IsDefined(mech) {
      return "!" + CMText.UnitLinkLost();
    }
    if !ScriptedPuppet.IsAlive(mech) {
      return "!" + CMText.MinoDestroyed();
    }
    if link.Distance() > CMLinkSystem.SignalRange() {
      return "!" + CMText.UnitSignalLost();
    }
    this.SendLookAts(mech);
    this.KeepCalm(s, mech, now);
    if this.m_mtDebug {
      this.WatchLookAts(s, mech, now);
    }
    this.ReadHull(mech);
    this.IntegrityAlarm(mech, now);
    if IsDefined(this.m_body) && this.m_body.Live() {

      this.m_air = this.m_body.led;
    } else {
      this.m_air = this.Airborne(s, mech);
    }
    if !this.m_air {
      this.Drive(s, mech, now);
      this.Gait(mech);
    }
    return "";
  }

  private func SendLookAts(mech: ref<NPCPuppet>) -> Void {
    if ArraySize(this.m_lookAts) > 0 || !EntityID.IsDefined(this.m_markerID) || EngineTime.ToFloat(GameInstance.GetEngineTime(this.m_game)) < this.m_lookAtsFrom {
      return;
    }
    if !IsDefined(this.m_marker) {
      this.m_marker = GameInstance.FindEntityByID(this.m_game, this.m_markerID);
      if !IsDefined(this.m_marker) {
        return;
      }
    }
    for part in [n"RightWeapon", n"LeftWeapon", n"Weapon", n"Chassis"] {
      let ev = new LookAtAddEvent();
      ev.SetEntityTarget(this.m_marker, n"", new Vector4(0.0, 0.0, 0.0, 0.0));
      ev.bodyPart = part;
      ev.SetStyle(animLookAtStyle.Normal);
      ev.SetLimits(animLookAtLimitDegreesType.Wide, animLookAtLimitDegreesType.Wide, animLookAtLimitDistanceType.None, animLookAtLimitDegreesType.Wide);

      ev.request.followingSpeedFactorOverride = this.LOOKAT_FOLLOW;
      ev.request.transitionSpeed = this.LOOKAT_BLEND;
      mech.QueueEvent(ev);
      ArrayPush(this.m_lookAts, ev);
    }
  }

  private func WatchLookAts(s: ref<CMCSession>, mech: ref<NPCPuppet>, now: Float) -> Void {
    if ArraySize(this.m_lookAts) == 0 || !this.m_guns.left.Ready() || !this.m_guns.right.Ready() {
      return;
    }
    let body = AbsF(CMPilotRig.Wrap(s.rig.yaw - CMPilotRig.YawOf(mech.GetWorldForward())));
    let errL = CMCSession.AimError(this.m_guns.left.weapon, s.aim);
    let errR = CMCSession.AimError(this.m_guns.right.weapon, s.aim);
    if body < 35.0 && errL > 12.0 && errR > 12.0 && s.aimDist > 15.0 {
      this.m_lookMiss += 1;
    } else {
      this.m_lookMiss = 0;
    }
    if this.m_lookMiss >= 15 && now - this.m_lookSent > 5.0 {
      this.m_lookSent = now;
    }
  }

  private func SafeReach(pos: Vector4, dir: Vector4, reach: Float) -> Float {
    let drop = IsDefined(this.m_body) && this.m_body.Live() ? 100000.0 : 2.5;
    let lastZ = pos.Z;
    let lift = -1.0;
    let dropped = false;
    this.m_reachZ = pos.Z;
    let d = 0.5;
    while d <= reach {
      let p = pos + dir * d;
      let hit: TraceResult;
      let ground = CMGround.Down(this.m_game, new Vector4(p.X, p.Y, lastZ + 3.0, 1.0), new Vector4(p.X, p.Y, lastZ - 6.0, 1.0), hit);
      let dz = ground ? Cast<Vector4>(hit.position).Z - lastZ : -10.0;
      if dz < -drop || dz > 2.0 {
        return d - 1.5;
      }
      lastZ += dz;
      if lift < 0.0 {
        lift = ClampF(pos.Z - lastZ, 0.0, 0.5);
      }

      if dz < -1.2 {
        dropped = true;
      }
      if !dropped {
        this.m_reachZ = lastZ + MaxF(lift, 0.0);
      }
      d += 0.5;
    }
    return reach;
  }

  private func Airborne(s: ref<CMCSession>, mech: ref<NPCPuppet>) -> Bool {
    let pos = mech.GetWorldPosition();
    let hit: TraceResult;
    let gap = 0.0;

    if CMGround.Down(this.m_game, new Vector4(pos.X, pos.Y, pos.Z + 0.5, 1.0), new Vector4(pos.X, pos.Y, pos.Z - 60.0, 1.0), hit) {
      gap = pos.Z - Cast<Vector4>(hit.position).Z;
    }
    if gap < 1.0 {
      this.m_airTime = 0.0;
      return false;
    }
    if this.m_airTime == 0.0 {
      this.CancelCmd(mech, this.m_moveCmd);
      this.CancelCmd(mech, this.m_turnCmd);
      this.m_moveCmd = null;
      this.m_turnCmd = null;
      this.m_moving = false;
    }
    this.m_airTime += 0.1;

    if this.m_airTime >= 1.5 && gap < 60.0 {
      CMGround.SetDown(mech, Cast<Vector4>(hit.position));
      this.m_airLogs += 1;
      if this.m_airLogs <= 6 {
      }
      s.rig.Nudge(12.0, -1.2);
      this.m_airTime = -1.5;
    }
    return true;
  }

  private func BodyTick(s: ref<CMCSession>, mech: ref<NPCPuppet>, dt: Float, now: Float) -> Void {
    if !IsDefined(this.m_body) {
      return;
    }

    if !this.m_moving {
      this.m_legs = 0;
    }

    let speed = CMAnimDriver.Speed(this.m_legs) * this.m_gait;
    this.m_body.SetWalk(this.m_moving && this.m_legs > 0 ? this.m_moveDir : new Vector4(0.0, 0.0, 0.0, 0.0), speed);
    this.m_body.SetLegs(this.m_legs);
    this.m_body.SetFacing(CMPilotRig.Dir(this.m_bodyYaw, 0.0));
    this.m_body.Tick(mech, dt, now);
    if this.m_body.failed {
      this.m_body = null;
      return;
    }
    let led = this.m_body.led;
    if led && !this.m_bodyLed {
      this.CancelCmd(mech, this.m_moveCmd);
      this.CancelCmd(mech, this.m_turnCmd);
      this.m_moveCmd = null;
      this.m_turnCmd = null;
      this.m_moving = false;
      this.m_air = true;
    }
    if !led && this.m_bodyLed {

      this.m_bodyYaw = CMPilotRig.YawOf(mech.GetWorldForward());
      this.m_turnVel = 0.0;
      this.m_turning = false;
      this.m_sentOpen = false;
      this.m_stoodAt = now;
      this.m_air = false;
    }
    this.m_bodyLed = led;

    if this.m_body.blocked && !led {
      if this.m_moving || now >= this.m_blockUntil {
        this.CancelCmd(mech, this.m_moveCmd);
        this.m_moveCmd = null;
        this.m_moving = false;
        let ai = mech.GetAIControllerComponent();
        if IsDefined(ai) {
          let tp = new AITeleportCommand();
          tp.position = this.m_body.blockAt;
          tp.rotation = CMPilotRig.YawOf(mech.GetWorldForward());
          tp.doNavTest = false;
          ai.SendCommand(tp);
        }
        s.rig.Nudge(this.STOP_ROCK, -0.25);
      }
      this.m_blockDir = this.m_body.blockDir;
      this.m_blockUntil = now + 0.6;
    }
    if this.m_body.knock > 0.0 {
      s.rig.Nudge(MinF(30.0, this.m_body.knock * 4.0), -MinF(2.0, this.m_body.knock * 0.3));
    }
    if this.m_body.landing > 0.0 {
      this.Land(s, mech, this.m_body.landing);
    }
  }

  private func OnWalkMesh(pos: Vector4) -> Bool {
    let nav = GameInstance.GetNavigationSystem(this.m_game).GetNearestNavmeshPointBelowOnlyHumanNavmesh(new Vector4(pos.X, pos.Y, pos.Z + 1.5, 1.0), 1.0, 4);
    return !Vector4.IsZero(nav) && Vector4.Distance(nav, pos) < 0.8;
  }

  private func Land(s: ref<CMCSession>, mech: ref<NPCPuppet>, speed: Float) -> Void {

    s.rig.Nudge(MinF(60.0, 6.0 + speed * 3.5), -MinF(4.0, 0.6 + speed * 0.3));
    s.rig.Shake(MinF(7.0, 0.8 + speed * 0.4), 0.3 + MinF(0.6, speed * 0.04));
    GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_lcm_servo_short");

    GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_lcm_land");
    if speed >= 7.0 {
      GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_melee_stomp_heavy");
      GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_fbk_bodyfall");
    }
    if speed >= 2.5 {
      let up = new Vector4(0.0, 0.0, 1.0, 0.0);
      let feet = mech.GetWorldPosition();
      GameInstance.GetFxSystem(this.m_game).SpawnEffect(CMUMinotaur.Fx(speed >= 7.0 ? r"base\\fx\\characters\\boss_adam_shasher\\ch_adam_smasher_land_heavy.effect" : r"base\\fx\\characters\\boss_adam_shasher\\ch_adam_smasher_jump_land.effect"), CMUMinotaur.At(feet, up), true);
    }

    if speed < 12.0 {
      return;
    }
    let over = speed - 12.0;
    let pct = MinF(15.0, over * over * 0.25);
    GameInstance.GetStatPoolsSystem(this.m_game).RequestChangingStatPoolValue(Cast<StatsObjectID>(mech.GetEntityID()), gamedataStatPoolType.Health, -pct, null, false, true);
    GameObject.PlaySoundEvent(mech, n"dev_generic_impact_metal");
    this.m_partNote = speed >= 18.0 ? CMText.MinoHardLandingDamaged() : CMText.MinoHardLanding();
    this.m_partNoteUntil = s.Now() + 3.0;
    if speed >= 18.0 && this.m_partsOn && IsDefined(this.m_parts) {
      let wear = MinF(0.2, (speed - 18.0) * 0.02 + 0.05);
      for leg in [CMPart.LegL(), CMPart.LegR()] {
        if this.m_parts.hp[leg] > 0.0 {
          this.m_parts.hp[leg] = MaxF(0.0, this.m_parts.hp[leg] - wear);
          if this.m_parts.hp[leg] <= 0.0 {
            this.BreakPart(s, mech, leg);
          }
        }
      }
    }
  }

  private func Drive(s: ref<CMCSession>, mech: ref<NPCPuppet>, now: Float) -> Void {
    let f = (s.Key(CMCKey.W()) ? 1.0 : 0.0) - (s.Key(CMCKey.S()) ? 1.0 : 0.0);
    let side = (s.Key(CMCKey.D()) ? 1.0 : 0.0) - (s.Key(CMCKey.A()) ? 1.0 : 0.0);

    if f != 0.0 {
      side = 0.0;
    }
    let dir = CMPilotRig.Dir(s.rig.yaw, 0.0) * f + CMPilotRig.Dir(s.rig.yaw - 90.0, 0.0) * side;
    let pos = mech.GetWorldPosition();
    if Vector4.Length(dir) < 0.1 {
      if this.m_moving {
        this.CancelCmd(mech, this.m_moveCmd);
        this.m_moveCmd = null;
        this.m_moving = false;
        s.rig.Nudge(this.STOP_ROCK, -0.25);
      }
      return;
    }
    dir = Vector4.Normalize(dir);
    if now < this.m_blockUntil && Vector4.Dot(dir, this.m_blockDir) > 0.3 {
      return;
    }
    if this.Limp(s, mech, now) {
      return;
    }

    if IsDefined(this.m_body) && this.m_body.Live() {
      let rel = CMPilotRig.Wrap(CMPilotRig.YawOf(dir) - this.m_bodyYaw);

      let fwdLine = this.m_legs == CMAnimDriver.Forward() ? 58.0 : (this.m_legs > 0 ? 42.0 : 50.0);
      let backLine = this.m_legs == CMAnimDriver.Back() ? 122.0 : (this.m_legs > 0 ? 138.0 : 130.0);
      let legs = AbsF(rel) <= fwdLine ? CMAnimDriver.Forward() : (AbsF(rel) > backLine ? CMAnimDriver.Back() : (rel < 0.0 ? CMAnimDriver.Right() : CMAnimDriver.Left()));
      if IsDefined(this.m_moveCmd) {
        this.CancelCmd(mech, this.m_moveCmd);
        this.m_moveCmd = null;
      }
      if !this.m_moving {
        s.rig.Nudge(-this.START_LURCH, -0.3);
      }
      this.m_moving = true;
      this.m_moveDir = dir;
      this.m_legs = legs;
      return;
    }
    let turned =!this.m_moving || Vector4.Dot(dir, this.m_moveDir) < 0.94;
    let close = Vector4.Distance(pos, this.m_moveTarget) < 4.0;
    let stale = now - this.m_moveSent > 1.5;
    let swung = AbsF(CMPilotRig.Wrap(s.rig.yaw - this.m_moveYaw)) > 25.0;
    if !(turned || close || stale || swung) {
      return;
    }

    let reach = 9.0;
    let from = new Vector4(pos.X, pos.Y, pos.Z + 1.2, 1.0);
    let hit: TraceResult;
    if GameInstance.GetSpatialQueriesSystem(this.m_game).SyncRaycastByCollisionGroup(from + dir * 2.0, from + dir * (reach + 2.5), n"Static", hit, true, false) {
      reach = Vector4.Distance(from, Cast<Vector4>(hit.position)) - 2.5;
    }

    let bodied = IsDefined(this.m_body) && this.m_body.Live();
    let wall = reach;
    reach = this.SafeReach(pos, dir, reach);
    if reach < 1.5 {
      if this.m_moving {
        this.CancelCmd(mech, this.m_moveCmd);
        this.m_moveCmd = null;
        this.m_moving = false;
      }
      return;
    }
    if !this.m_moving {
      s.rig.Nudge(-this.START_LURCH, -0.3);
    }
    let target = pos + dir * reach;

    let onMesh = this.OnWalkMesh(pos);
    if bodied && !onMesh {
      target.Z = this.m_reachZ;
    }
    let world: WorldPosition;
    WorldPosition.SetVector4(world, target);
    let spec: AIPositionSpec;
    AIPositionSpec.SetWorldPosition(spec, world);
    let face: WorldPosition;
    WorldPosition.SetVector4(face, pos + CMPilotRig.Dir(s.rig.yaw, 0.0) * 30.0);
    let faceSpec: AIPositionSpec;
    AIPositionSpec.SetWorldPosition(faceSpec, face);
    let cmd = new AIMoveToCommand();
    cmd.movementTarget = spec;
    cmd.facingTarget = faceSpec;
    cmd.rotateEntityTowardsFacingTarget = true;
    cmd.movementType = moveMovementType.Walk;
    cmd.ignoreNavigation = bodied && !onMesh;
    cmd.useStart = !this.m_moving;

    cmd.useStop = !bodied;
    cmd.finishWhenDestinationReached = true;
    cmd.desiredDistanceFromTarget = 0.5;
    this.Send(mech, cmd, true);
    this.m_moveYaw = s.rig.yaw;
    this.m_moving = true;
    this.m_moveDir = dir;
    this.m_moveTarget = target;
    this.m_moveSent = now;
  }

  private func Send(mech: ref<NPCPuppet>, cmd: ref<AICommand>, move: Bool) -> Void {
    let ai = mech.GetAIControllerComponent();
    if !IsDefined(ai) {
      return;
    }
    this.CancelCmd(mech, this.m_moveCmd);
    this.CancelCmd(mech, this.m_turnCmd);
    this.m_moveCmd = null;
    this.m_turnCmd = null;
    ai.SendCommand(cmd);
    if move {
      this.m_moveCmd = cmd;
    } else {
      this.m_turnCmd = cmd;
    }
  }

  private func CancelCmd(mech: ref<NPCPuppet>, cmd: ref<AICommand>) -> Void {
    if !IsDefined(cmd) {
      return;
    }
    let ai = mech.GetAIControllerComponent();
    if IsDefined(ai) {
      ai.CancelCommand(cmd);
    }
  }

  private func PartHp(i: Int32) -> Float = this.m_partsOn && IsDefined(this.m_parts) ? this.m_parts.hp[i] : 1.0

  public func OpticsOnline() -> Bool = this.PartHp(CMPart.Sensor()) > 0.0

  private func ApplyParts(s: ref<CMCSession>, mech: ref<NPCPuppet>) -> Void {
    let armL = this.PartHp(CMPart.ArmL()) <= 0.0;
    let armR = this.PartHp(CMPart.ArmR()) <= 0.0;
    this.m_guns.left.destroyed = armL;
    this.m_guns.right.destroyed = armR;
    if this.m_partsOn {
      CMCParts.Get(this.m_game).Effects(mech);
    }
    CMCParts.ShowGun(mech, true, !armL);
    CMCParts.ShowGun(mech, false, !armR);
    if !this.OpticsOnline() {
      s.OpticsLost();
    }
  }

  public func TakeHit(s: ref<CMCSession>, hit: ref<gameHitEvent>) -> Void {
    let mech = this.Mech();
    if !IsDefined(mech) || !IsDefined(this.m_parts) {
      return;
    }
    if !IsDefined(hit) {
      this.ApplyParts(s, mech);
      return;
    }
    this.Blast(s, mech, hit);
    if !this.m_partsOn {
      return;
    }
    let r = CMCParts.Get(this.m_game).Hit(mech, hit);
    if !IsDefined(r) {
      return;
    }
    let hud = s.Hud();
    if IsDefined(hud) {
      hud.PartHit(r.part);
    }
    if r.broke {
      this.BreakPart(s, mech, r.part);
    }
  }

  private func Gait(mech: ref<NPCPuppet>) -> Void {
    let want = 1.0;
    if this.m_moving {
      let l = this.PartHp(CMPart.LegL());
      let r = this.PartHp(CMPart.LegR());
      let broken = (l <= 0.0 ? 1 : 0) + (r <= 0.0 ? 1 : 0);
      want = broken == 2 ? 0.4 : (broken == 1 ? 0.6 : (l < 0.5 || r < 0.5 ? 0.85 : 1.0));
    }
    if want == this.m_gait {
      return;
    }
    this.m_gait = want;
    if want < 1.0 {
      mech.SetIndividualTimeDilation(n"CMDamagedLeg", want);
    } else {
      mech.UnsetIndividualTimeDilation();
    }
  }

  private func Limp(s: ref<CMCSession>, mech: ref<NPCPuppet>, now: Float) -> Bool {
    let l = this.PartHp(CMPart.LegL());
    let r = this.PartHp(CMPart.LegR());
    let broken = (l <= 0.0 ? 1 : 0) + (r <= 0.0 ? 1 : 0);
    let stride = 0.0;
    let halt = 0.0;
    if broken == 2 {
      stride = 0.7;
      halt = 1.1;
    } else if broken == 1 {
      stride = 1.0;
      halt = 0.7;
    } else if l < 0.5 || r < 0.5 {
      stride = 1.8;
      halt = 0.35;
    } else {
      return false;
    }
    if now >= this.m_limpNext {
      this.m_limpHalt = !this.m_limpHalt;
      this.m_limpNext = now + (this.m_limpHalt ? halt : stride);
      if this.m_limpHalt {
        s.rig.Nudge(this.STOP_ROCK * 1.6, -0.45);
      }
    }
    if this.m_limpHalt && this.m_moving {
      this.CancelCmd(mech, this.m_moveCmd);
      this.m_moveCmd = null;
      this.m_moving = false;
    }
    return this.m_limpHalt;
  }

  private func Blast(s: ref<CMCSession>, mech: ref<NPCPuppet>, hit: ref<gameHitEvent>) -> Void {
    if !IsDefined(this.m_body) || !this.m_body.Live() || !IsDefined(hit.attackData) {
      return;
    }
    if NotEquals(hit.attackData.GetAttackType(), gamedataAttackType.Explosion) {
      return;
    }
    let from = hit.attackData.GetAttackPosition();
    let away = mech.GetWorldPosition() - from;
    away.Z = 0.0;
    away.W = 0.0;
    let dist = Vector4.Length(away);
    if dist > 12.0 {
      return;
    }
    let dir = dist > 0.2 ? away * (1.0 / dist) : mech.GetWorldForward() * -1.0;
    let k = ClampF(1.0 - dist / 12.0, 0.25, 1.0);
    let dv = dir * (4.5 * k) + new Vector4(0.0, 0.0, 1.2 * k, 0.0);
    this.m_body.Push(mech, dv, s.Now(), "a blast " + FloatToStringPrec(dist, 1) + " m away");
    s.rig.Nudge(MinF(30.0, 18.0 * k), -1.5 * k);
  }

  private func BreakPart(s: ref<CMCSession>, mech: ref<NPCPuppet>, part: Int32) -> Void {
    if (part == CMPart.ArmL() || part == CMPart.ArmR()) && !this.m_parts.killed[part] {
      this.m_parts.killed[part] = true;
      CMCParts.BlowGun(mech, part == CMPart.ArmL());
    }
    this.ApplyParts(s, mech);
    this.m_partNote = part == CMPart.Sensor() ? CMText.MinoOpticsOffline(CMPart.Name(part)) : (part == CMPart.LegL() || part == CMPart.LegR() ? CMText.MinoCrippled(CMPart.Name(part)) : CMText.MinoPartDestroyed(CMPart.Name(part)));
    this.m_partNoteUntil = s.Now() + 3.0;
    GameObject.PlaySoundEvent(mech, n"dev_alarm_02");
  }

  public func Hud(s: ref<CMCSession>, st: ref<CMPilotHudState>) -> Void {
    let link = CMLinkSystem.Get(this.m_game);
    let name = link.UnitName();
    if StrLen(name) > 0 {
      st.title = StrUpper(name);
    }
    st.integrity = this.m_hull;
    st.signal = link.SignalFraction();
    st.distance = link.Distance();
    st.gunNameL = this.m_guns.left.spec.name;
    st.gunNameR = this.m_guns.right.spec.name;
    st.secName = IsDefined(this.m_missile) ? this.m_missile.name : "";
    st.heatL = this.m_guns.left.heat;
    st.heatR = this.m_guns.right.heat;
    st.lockedL = this.m_guns.left.locked;
    st.lockedR = this.m_guns.right.locked;
    st.hasL = this.m_guns.left.Ready();
    st.hasR = this.m_guns.right.Ready();
    let wait = this.m_missileReady - s.Now();
    st.missile = this.PartHp(CMPart.Pods()) <= 0.0 ? "MSL OFFLINE" : (wait > 0.0 ? "MSL RELOAD " + IntToString(CeilF(wait)) + "S" : "MSL READY");

    if ArraySize(st.parts) != CMPart.Count() {
      ArrayResize(st.parts, CMPart.Count());
    }
    let i = 0;
    while i < CMPart.Count() {
      st.parts[i] = i == CMPart.Torso() ? this.m_hull : this.PartHp(i);
      i += 1;
    }
    st.lostL = this.m_guns.left.destroyed;
    st.lostR = this.m_guns.right.destroyed;

    let crit = this.m_hull >= 0.0 && this.m_hull < 0.3;
    if NotEquals(crit, this.m_critFx) {
      this.m_critFx = crit;
      let mech = this.Mech();
      if IsDefined(mech) {
        if crit {
          GameObjectEffectHelper.StartEffectEvent(mech, n"hacks_overheat_lvl2");
        } else {
          GameObjectEffectHelper.StopEffectEvent(mech, n"hacks_overheat_lvl2");
        }
      }
    }
    let sensor = this.PartHp(CMPart.Sensor());
    if sensor <= 0.0 || (sensor < 0.5 && RandF() < (0.5 - sensor) * 1.4) {
      st.range = -1.0;
    }
    if StrLen(this.m_partNote) > 0 && s.Now() < this.m_partNoteUntil {
      st.warning = this.m_partNote;
    } else if IsDefined(this.m_body) && this.m_body.led {
      st.warning = this.m_body.Gap() > 1.0 ? CMText.MinoAirborne() : CMText.MinoStaggered();
    } else if !st.hasL && !st.hasR {
      st.warning = CMText.MinoNoWeapons();
    } else if st.integrity < 0.3 {
      st.warning = CMText.MinoHullLow();
    } else {
      if st.signal < 0.2 {
        st.warning = CMText.MinoSignalDegraded();
      } else {
        if this.m_guns.left.offAim && this.m_guns.right.offAim && s.Key(CMCKey.Lmb()) {
          st.warning = CMText.MinoGunsTraversing();
        } else {
          if s.Key(CMCKey.Lmb()) && this.m_spin < 1.0 {
            st.warning = CMText.MinoSpinningUp();
          }
        }
      }
    }
  }
}

public class CMUMinotaurRainCb extends DelayCallback {
  public let unit: wref<CMUMinotaur>;
  public let at: Vector4;
  public func Call() -> Void {
    if IsDefined(this.unit) {
      this.unit.FireRain(this.at);
    }
  }
}

public class CMUMinotaurMissileCb extends DelayCallback {
  public let unit: wref<CMUMinotaur>;
  public let at: Vector4;
  public func Call() -> Void {
    if IsDefined(this.unit) {
      this.unit.Detonate(this.at);
    }
  }
}
