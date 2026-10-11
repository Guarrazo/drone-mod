module ControllableMechs.Control

import ControllableMechs.*
import Codeware.*

public class CMUDrone extends CMCUnit {
  private let m_game: GameInstance;
  private let m_drone: wref<NPCPuppet>;
  private let m_flight: ref<CMFlight>;
  private let m_seen: Vector4;
  private let m_kind: String;
  private let m_name: String;
  private let m_cmd: ref<AICommand>;
  private let m_logAt: Float;
  private let m_frames: Int32;
  private let m_gait: CName;
  private let m_ground: Float;
  private let m_stickF: Float;
  private let m_rayHits: Int32;
  private let m_rayMiss: Int32;
  private let m_hitS: Int32;
  private let m_hitD: Int32;
  private let m_hitV: Int32;

  private let m_tq: Quaternion;
  private let m_tt: Vector4;
  private let m_tqSeen: Quaternion;
  private let m_poseOk: Bool;
  private let m_poseFrom: String;
  private let m_poseFrames: Int32;
  private let m_hull: array<Vector4>;
  private let m_pts: array<Vector4>;
  private let m_c: Vector4;

  private let m_hidden: Bool;
  private let m_sight: Bool;
  private let m_rigYaw: Float;
  private let m_selfHits: Int32;
  private let m_hideInSight: Bool;
  private let m_sensUp: Float;
  private let m_sensFwd: Float;
  private let m_show: Float;
  private let m_bone: Vector4;
  private let m_boneOff: Vector4;
  private let m_placed: Vector4;
  private let m_heldWt: WorldTransform;
  private let m_heldOk: Bool;
  private let m_aiSyncAt: Float;
  private let m_aiOffAt: Float;
  private let m_groundFrom: String;
  private let m_stickS: Float;
  private let m_sense: ref<CMDroneSense>;
  private let m_stab: Int32;
  private let m_zoomed: Bool;
  private let m_killed: array<EntityID>;
  private let m_bdaRounds: Int32;
  private let m_bdaHits: Int32;

  public func Begin(s: ref<CMCSession>) -> String {
    this.m_game = s.GetGameInstance();
    this.m_sense = null;
    ArrayClear(this.m_killed);
    this.m_bdaRounds = 0;
    this.m_bdaHits = 0;
    let link = CMLinkSystem.Get(this.m_game);

    let drone = link.Unit();
    if IsDefined(this.forDrone) {
      drone = this.forDrone;
    }
    if !IsDefined(drone) {
      return "!" + CMText.DrnNoDroneLinked();
    }
    if !ScriptedPuppet.IsAlive(drone) {
      return "!" + CMText.DrnIsDestroyed();
    }

    if !CMPhysStep.Present() || !CMPhysColl.Present() || !CMPhysPlugin.HasVelocity() {
      return "!" + CMText.DrnNeedsPhysics();
    }
    this.m_drone = drone;
    this.m_kind = CMUDrone.Kind(drone);
    this.m_name = CMUDrone.TypeName(this.m_kind);
    if !IsDefined(this.forDrone) {
      link.Hold();
      link.SetOrder(CMOrder.Pilot());
    }
    let cfg = CMPilotSystem.Get(this.m_game);
    let prof = CMDroneProfiles.For(this.m_kind);
    prof.showTilt = Cast<Float>(cfg.DroneShowTilt(this.m_kind, RoundF(prof.showTilt)));
    prof.tilt = Cast<Float>(cfg.DroneTilt(this.m_kind, RoundF(prof.tilt)));
    prof.tiltRate = Cast<Float>(cfg.DroneRate(this.m_kind, RoundF(prof.tiltRate)));

    this.m_hull = CMDroneHull.Points(this.m_kind);
    this.ResetParts();
    this.m_hold = false;
    this.DropShots();
    this.StopWash();
    this.m_exposure = 1.0;
    this.m_exposureTo = 1.0;
    this.m_exposureAt = 0.0;
    this.m_tq = CMUDrone.QIdentity();
    this.m_tqSeen = CMUDrone.QIdentity();
    this.m_tt = new Vector4(0.0, 0.0, 0.0, 0.0);
    this.m_poseOk = false;
    this.m_poseFrames = 0;
    this.MeasurePose(drone, 1.0);
    this.UpdateHull();
    this.LoadSensor();
    let start = drone.GetWorldPosition() + CMFlight.QRot(drone.GetWorldOrientation(), this.m_tt + this.m_c);
    this.m_flight = CMFlight.Make(prof, start, CMPilotRig.YawOf(drone.GetWorldForward()));
    this.m_flight.level = Cast<Float>(cfg.DroneLevel(this.m_kind)) / 100.0;

    this.m_proxyLive = false;
    this.m_proxySpawned = false;
    this.m_proxyBody = null;
    this.StartPhys(drone, s.Now());
    this.m_hidden = false;
    this.m_show = prof.showTilt;
    this.m_placed = this.m_flight.pos;
    this.m_seen = drone.GetWorldPosition();
    this.m_logAt = s.Now() + 1.0;
    this.m_frames = 0;
    this.m_gait = n"";
    this.m_rockets = Equals(this.m_kind, "griffin") ? 2 : this.ROCKET_POD;
    this.m_podReady = 0.0;
    this.m_wpn = 0;
    this.m_heat = 0.0;
    this.m_overheat = false;
    this.ApplyParts(false);
    this.m_aiSyncAt = 0.0;
    this.m_aiOffAt = 0.0;
    this.m_payload = Equals(this.m_kind, "bombus") ? cfg.BombusPayload() : 0;
    this.m_detonated = false;
    this.Pacify(drone, true);

    let ai = drone.GetAIControllerComponent();
    if IsDefined(ai) {
      ai.Toggle(false);
    }
    this.LogLoadout(drone);
    return "";
  }

  public func End(s: ref<CMCSession>, hard: Bool) -> Void {

    if !hard && this.m_payload > 0 && !this.m_detonated && IsDefined(this.m_drone) && !ScriptedPuppet.IsAlive(this.m_drone) {
      this.Detonate(false);
    }
    if ArraySize(this.m_partHp) > 0 && IsDefined(this.m_drone) {
      CMLinkSystem.Get(this.m_game).SetDroneParts(this.m_drone.GetEntityID(), this.m_partHp);
    }
    this.StopPartFx();
    this.KeepLostPods();
    this.DropShots();
    this.StopWash();
    this.StopPhys(this.m_drone);
    if this.m_hold {

      this.m_hold = false;
      if this.m_holdChase {
        CMPilotSystem.Get(this.m_game).PutFlag("chaseView", true);
      }
    }
    let drone = this.m_drone;
    if IsDefined(drone) {
      if this.m_hidden {
        this.ShowModel(drone, true);
      }
      if this.m_lmgSound {
        GameObject.PlaySoundEvent(drone, n"w_gun_hmg_militech_fire_auto_stop");
        this.m_lmgSound = false;
      }
      this.Cancel(drone);
      this.SetGait(drone, n"Walk");

      let here = drone.GetWorldPosition();
      let face: EulerAngles;
      face.Yaw = IsDefined(this.m_flight) ? this.m_flight.yaw : CMPilotRig.YawOf(drone.GetWorldForward());
      let ai = drone.GetAIControllerComponent();
      if ScriptedPuppet.IsAlive(drone) && this.keepAiOff {
      } else {
      if ScriptedPuppet.IsAlive(drone) {
        GameInstance.GetTeleportationFacility(this.m_game).Teleport(drone, here, face);
        if IsDefined(ai) {
          ai.Toggle(true);
          let tp = new AITeleportCommand();
          tp.position = here;
          tp.rotation = face.Yaw;
          tp.doNavTest = false;
          ai.SendCommand(tp);
        }
      } else {
        if IsDefined(ai) {
          ai.Toggle(false);
        }
        let cb = new CMWreckLogCb();
        cb.drone = drone;
        cb.fell = here;
        GameInstance.GetDelaySystem(this.m_game).DelayCallback(cb, 2.0, false);

      }
      }
      this.Pacify(drone, false);
    }
    this.m_drone = null;
  }

  public func IsAlive() -> Bool {
    let drone = this.m_drone;
    return IsDefined(drone) && ScriptedPuppet.IsAlive(drone);
  }

  public func LostReason() -> String = "!" + CMText.DrnDestroyed()

  public func SlowTick(s: ref<CMCSession>, now: Float) -> String {
    let link = CMLinkSystem.Get(this.m_game);
    if !link.IsLinked() {
      return "!" + CMText.UnitLinkLost();
    }
    if link.Distance() > link.Range() {
      return "!" + CMText.UnitSignalLost();
    }
    this.LoadSensor();
    return "";
  }

  public func Name() -> String = this.m_name

  public func Ground() -> Vector4 {
    if !IsDefined(this.m_flight) {
      return this.m_seen;
    }
    let fl = this.m_flight;
    if this.m_hold && this.m_sight {

      let v = CMPilotRig.Dir(this.m_rigYaw, 0.0);
      return new Vector4(fl.pos.X - v.X * this.SensorFwd(), fl.pos.Y - v.Y * this.SensorFwd(), fl.pos.Z - fl.p.bottom - 0.25 - this.SensorUp(), 1.0);
    }
    let a = this.Anchor();
    if this.m_sight {

      let fwd = this.SensorFwd();
      let view = CMPilotRig.Dir(this.m_rigYaw, 0.0);
      let body = CMPilotRig.Dir(fl.yaw, 0.0);
      return new Vector4(a.X + (body.X - view.X) * fwd, a.Y + (body.Y - view.Y) * fwd, a.Z, 1.0);
    }
    return a;
  }

  public func TickFirst() -> Bool = true
  public func SignalLost() -> Bool = true
  public func Facing() -> Float = IsDefined(this.m_flight) ? this.m_flight.yaw : 0.0

  public func SensorUp() -> Float = this.m_sensUp
  public func SensorFwd() -> Float = this.m_sensFwd
  public func AimSkip() -> Float = 1.5

  public func CamTilt() -> Vector4 {

    if !IsDefined(this.m_flight) || (this.m_sight && (this.m_stab == 2 || (this.m_stab == 1 && this.m_zoomed))) {
      return new Vector4(0.0, 0.0, 0.0, 0.0);
    }
    return new Vector4(this.m_flight.pitch, this.m_flight.roll, 0.0, 0.0);
  }
  public func StepWeight() -> Float = 0.0
  public func LightLook() -> Bool = true
  public func CamProfile() -> String = this.m_kind

  public func Tick(s: ref<CMCSession>, dt: Float, now: Float) -> Void {
    let drone = this.m_drone;
    if !IsDefined(drone) || !IsDefined(this.m_flight) || dt <= 0.0 {
      return;
    }
    dt = MinF(dt, 0.1);
    this.m_frames += 1;

    let sndSpeed = IsDefined(this.m_flight) ? Vector4.Length(this.m_flight.vel) : 0.0;
    let sndAccel = AbsF(sndSpeed - this.m_sndLastSpeed) / MaxF(dt, 0.001);
    this.m_sndLastSpeed = sndSpeed;
    CMPhysSoundWatch.Watch(true, drone.GetWorldPosition(), sndSpeed, sndAccel);

    let actual = drone.GetWorldPosition();
    this.m_seen = actual;

    if this.m_poseFrames < 30 {
      this.m_poseFrames += 1;
      this.MeasurePose(drone, 0.2);
      this.UpdateHull();
    }

    let keyF = (s.Key(CMCKey.W()) ? 1.0 : 0.0) - (s.Key(CMCKey.S()) ? 1.0 : 0.0);
    let keyS = (s.Key(CMCKey.D()) ? 1.0 : 0.0) - (s.Key(CMCKey.A()) ? 1.0 : 0.0);
    if this.autoOn {

      keyF = this.autoF;
      keyS = this.autoS;
    }
    let k = MinF(1.0, dt / MaxF(0.01, this.m_flight.p.ramp));
    this.m_stickF += (keyF - this.m_stickF) * k;
    this.m_stickS += (keyS - this.m_stickS) * k;
    let f = CMUDrone.Expo(this.m_stickF, this.m_flight.p.expo);
    let side = CMUDrone.Expo(this.m_stickS, this.m_flight.p.expo);
    let climb = (s.Key(CMCKey.Up()) ? 1.0 : 0.0) - (s.Key(CMCKey.Down()) ? 1.0 : 0.0);
    if this.autoOn {
      this.AutoTick(drone, f, side, this.autoC, this.autoH, dt, now);
      return;
    }

    let heading = s.rig.yaw;
    if this.m_hold && !s.SightView() {
      this.SetHold(s, false);
    }
    if this.m_hold {
      this.HoldKeys(s, dt, f, side);
      heading = this.m_holdYaw;
    }

    this.m_flight.SetGround(this.m_ground);
    this.UpdateWind(now, dt);
    if !this.m_proxyLive {

      this.TryProxy(now);
      this.m_flight.vel = new Vector4(0.0, 0.0, 0.0, 0.0);
      this.m_flight.w = new Vector4(0.0, 0.0, 0.0, 0.0);
    }
    if this.m_proxyLive {

      CMWatch.Mark("drone " + this.m_kind + ": flight");
      this.PhysFly(s, drone, f, side, climb, heading, dt, now);
    }
    CMWatch.Mark("drone " + this.m_kind + ": place");

    let hide = this.m_hideInSight && s.SightView();
    if NotEquals(hide, this.m_hidden) {
      this.ShowModel(drone, !hide);
    }
    this.Place(drone, now);
    this.m_sight = s.SightView();
    this.m_zoomed = s.zoom;
    this.m_rigYaw = s.rig.yaw;
    let hud = s.Hud() as CMDroneHud;
    if IsDefined(hud) {
      let fl = this.m_flight;
      hud.SetFlight(fl.pitch, fl.roll, Vector4.Length(fl.vel), this.m_ground, fl.vel.Z);

      if !IsDefined(this.m_sense) {
        this.m_sense = CMDroneSense.Make(Equals(this.m_kind, "wyvern"));
      }
      CMWatch.Mark("drone " + this.m_kind + ": sensor sweep");
      this.m_sense.Tick(s, this, drone, fl.pos, now, dt);
      let t = this.m_sense.track;
      t.hold = this.m_hold;
      t.rounds = this.m_bdaRounds;
      t.hits = this.m_bdaHits;
      if Equals(this.m_kind, "bombus") {
        this.BombusTrack(s, t);
      }
      if Equals(this.m_kind, "octant") {
        this.OctantTrack(s, t);
      }
      CMWatch.Mark("drone " + this.m_kind + ": aggro");
      this.Aggro(t, now);
      CMWatch.Mark("drone " + this.m_kind + ": hud track");
      t.slow = now >= t.slowAt;
      if t.slow {
        t.slowAt = now + 0.066;
      }
      hud.Track(t);
    }
    CMWatch.Mark("drone " + this.m_kind + ": weapons");
    this.Weapons(s, now, dt, hud);
    CMWatch.Mark("drone " + this.m_kind + ": effects");
    this.Downwash(now);
    this.PartFx();
    this.SpinDeath(now);
    this.Lean(drone, dt);
    if now >= this.m_logAt {
      this.m_logAt = now + 1.0;

    }
  }

  public let autoOn: Bool;
  public let forDrone: wref<NPCPuppet>;
  public let autoF: Float;
  public let autoS: Float;
  public let autoC: Float;
  public let autoH: Float;

  public func FlightPos() -> Vector4 = IsDefined(this.m_flight) ? this.m_flight.pos : this.m_seen
  public func FlightVel() -> Vector4 = IsDefined(this.m_flight) ? this.m_flight.vel : new Vector4(0.0, 0.0, 0.0, 0.0)
  public func FlightYaw() -> Float = IsDefined(this.m_flight) ? this.m_flight.yaw : 0.0
  public func Live() -> Bool = this.m_proxyLive

  public func Probe(from: Vector4, to: Vector4, out hit: TraceResult) -> Bool = this.Ray(from, to, hit)
  public func GroundGap() -> Float = this.m_ground
  public func FlightTilt() -> Float = IsDefined(this.m_flight) ? MaxF(AbsF(this.m_flight.pitch), AbsF(this.m_flight.roll)) : 0.0
  public func Span() -> Float = IsDefined(this.m_flight) ? this.m_flight.p.span : 1.5

  public let keepAiOff: Bool;

  public let autoFire: Bool;
  public let autoAim: Vector4;
  public let autoTarget: wref<GameObject>;
  public func HasGun() -> Bool = !Equals(this.m_kind, "bombus")

  private func AutoTick(drone: ref<NPCPuppet>, f: Float, side: Float, climb: Float, heading: Float, dt: Float, now: Float) -> Void {
    this.m_flight.SetGround(this.m_ground);
    this.UpdateWind(now, dt);
    if !this.m_proxyLive {
      this.TryProxy(now);
      this.m_flight.vel = new Vector4(0.0, 0.0, 0.0, 0.0);
      this.m_flight.w = new Vector4(0.0, 0.0, 0.0, 0.0);
    }
    if this.m_proxyLive {
      this.PhysFly(null, drone, f, side, climb, heading, dt, now);
    }
    this.Place(drone, now);
    this.m_sight = false;
    this.m_zoomed = false;
    this.m_rigYaw = heading;
    this.Downwash(now);
    this.PartFx();
    this.SpinDeath(now);
    this.Lean(drone, dt);

    let firing = this.autoFire && IsDefined(this.autoTarget) && this.HasGun();
    if firing {
      this.AutoLmg(now);
    } else {
      this.m_lmgNext = MaxF(this.m_lmgNext, now);
    }
    if NotEquals(firing, this.m_lmgSound) {
      this.m_lmgSound = firing;
      GameObject.PlaySoundEvent(drone, firing ? n"w_gun_hmg_militech_fire_auto" : n"w_gun_hmg_militech_fire_auto_stop");
    }
    this.Fly(null, dt);
    this.AutoAggro(drone, now);
  }

  private func Root() -> Vector4 {
    let fl = this.m_flight;
    let q = fl.Shown(this.m_show);
    let r = this.Anchor() - CMFlight.QRot(q, this.m_tt);
    r.W = 1.0;
    return r;
  }

  private func Anchor() -> Vector4 {
    let fl = this.m_flight;
    let q = fl.Shown(this.m_show);
    let r = fl.pos - CMFlight.QRot(q, this.m_c);
    r.W = 1.0;
    return r;
  }

  private func MeasurePose(drone: ref<NPCPuppet>, k: Float) -> Void {
    let bindQ = CMUDrone.Q(0.0, 0.7071068, 0.7071068, 0.0);
    let comps: array<CName>;
    let slots: array<CName>;
    let relT: array<Vector4>;
    let relQ: array<Quaternion>;
    let bindT: array<Vector4>;
    let none = new Vector4(0.0, 0.0, 0.0, 0.0);
    switch this.m_kind {
      case "bombus":
        comps = [n"Item_Attachment_Slot"];
        slots = [n"Center"];
        relT = [none];
        relQ = [CMUDrone.Q(0.7071068, 0.0, 0.0, 0.7071068)];
        bindT = [new Vector4(0.0, -0.002, 0.127, 0.0)];
        break;
      case "wyvern":
        comps = [n"Item_Attachment_Slot"];
        slots = [n"Center"];
        relT = [new Vector4(0.0, 0.2, 0.0, 0.0)];
        relQ = [CMUDrone.QIdentity()];
        bindT = [none];
        break;
      case "octant":
        comps = [n"Slot8842", n"Slot8842"];
        slots = [n"l_front_01", n"r_front_01"];
        relT = [none, none];
        relQ = [bindQ, bindQ];
        bindT = [new Vector4(-0.75, 0.614, 0.761, 0.0), new Vector4(0.75, 0.614, 0.761, 0.0)];
        break;
      default:
        comps = [n"Item_Attachment_Slot"];
        slots = [n"Center"];
        relT = [none];
        relQ = [CMUDrone.QIdentity()];
        bindT = [none];
    }
    let qe = drone.GetWorldOrientation();
    let pe = drone.GetWorldPosition();
    let sumT = new Vector4(0.0, 0.0, 0.0, 0.0);
    let n = 0;
    let rot = CMUDrone.QIdentity();
    let i = 0;
    while i < ArraySize(comps) {
      let sc = drone.FindComponentByName(comps[i]) as SlotComponent;
      let wt: WorldTransform;
      if IsDefined(sc) && sc.GetSlotTransform(slots[i], wt) {
        let sq = WorldTransform.GetOrientation(wt);
        let st = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(wt));

        let bq1 = CMFlight.QMul(sq, CMUDrone.Conj(relQ[i]));
        let bq2 = CMFlight.QMul(CMUDrone.Conj(relQ[i]), sq);
        let tq1 = CMFlight.QMul(CMFlight.QMul(CMUDrone.Conj(qe), bq1), CMUDrone.Conj(bindQ));
        let tq2 = CMFlight.QMul(CMFlight.QMul(CMUDrone.Conj(qe), bq2), CMUDrone.Conj(bindQ));
        let bq = CMUDrone.QAngle(tq1) <= CMUDrone.QAngle(tq2) ? bq1 : bq2;
        let tq = CMUDrone.QAngle(tq1) <= CMUDrone.QAngle(tq2) ? tq1 : tq2;
        let bt = st - CMFlight.QRot(bq, relT[i]);
        let lt = CMFlight.QInvRot(qe, bt - pe);
        sumT += lt - CMFlight.QRot(tq, bindT[i]);
        n += 1;
        if i == 0 {
          rot = tq;
          this.m_bone = bt;
          this.m_boneOff = bt - this.m_placed;
        }
      }
      i += 1;
    }
    if n == 0 {
      return;
    }
    let t = sumT / Cast<Float>(n);
    t.W = 0.0;
    let len = Vector4.Length(t);
    if len > 4.0 {
      t = t * (4.0 / len);
    }
    if !this.m_poseOk {
      k = 1.0;
      this.m_poseFrom = NameToString(comps[0]) + "/" + NameToString(slots[0]);
    }
    this.m_tt += (t - this.m_tt) * k;
    this.m_tt.W = 0.0;

    this.m_tqSeen = CMUDrone.QBlend(this.m_tqSeen, rot, k);
    this.m_poseOk = true;
  }

  private func UpdateHull() -> Void {
    ArrayClear(this.m_pts);
    let lo = new Vector4(1000.0, 1000.0, 1000.0, 0.0);
    let hi = new Vector4(-1000.0, -1000.0, -1000.0, 0.0);
    for p in this.m_hull {
      let d = CMFlight.QRot(this.m_tq, p);
      ArrayPush(this.m_pts, d);
      lo = new Vector4(MinF(lo.X, d.X), MinF(lo.Y, d.Y), MinF(lo.Z, d.Z), 0.0);
      hi = new Vector4(MaxF(hi.X, d.X), MaxF(hi.Y, d.Y), MaxF(hi.Z, d.Z), 0.0);
    }
    if ArraySize(this.m_pts) == 0 {
      let com = IsDefined(this.m_flight) ? this.m_flight.p.com : CMDroneProfiles.For(this.m_kind).com;
      this.m_c = new Vector4(0.0, 0.0, com, 0.0);
      return;
    }
    this.m_c = (lo + hi) * 0.5;
    this.m_c.W = 0.0;
  }

  private func LoadSensor() -> Void {
    let cfg = CMPilotSystem.Get(this.m_game);
    this.m_hideInSight = cfg.DroneHideInSight(this.m_kind);
    this.m_stab = cfg.DroneStabilize(this.m_kind);
    this.m_lmgArc = Cast<Float>(cfg.OctantLmgArc());
    this.m_podsBreak = cfg.OctantPodsBreak();
    this.m_sensUp = Cast<Float>(cfg.DroneCamUpCm(this.m_kind)) / 100.0;
    this.m_sensFwd = Cast<Float>(cfg.DroneCamFwdCm(this.m_kind)) / 100.0;
    this.m_windK = Cast<Float>(cfg.WindPct()) / 100.0;
  }

  private let m_windK: Float;
  private let m_exposure: Float;
  private let m_exposureTo: Float;
  private let m_exposureAt: Float;

  private func UpdateWind(now: Float, dt: Float) -> Void {
    let fl = this.m_flight;
    let w = CMWind.Get(this.m_game);
    if this.m_windK <= 0.0 || fl.grounded || !IsDefined(w) {
      fl.wind = new Vector4(0.0, 0.0, 0.0, 0.0);
      return;
    }
    if now >= this.m_exposureAt {
      this.m_exposureAt = now + 0.25;
      this.m_exposureTo = w.Exposure(fl.pos);
    }
    this.m_exposure += (this.m_exposureTo - this.m_exposure) * MinF(1.0, dt * 2.0);
    fl.wind = w.At(fl.pos, this.m_ground) * (this.m_windK * this.m_exposure);
  }

  private func WindText() -> String {
    let w = CMWind.Get(this.m_game);
    if !IsDefined(w) || !IsDefined(this.m_flight) || this.m_windK <= 0.0 {
      return CMText.DrnWindOff();
    }
    let from = RoundF(CMPilotRig.Wrap(-(w.Heading() + 180.0)));
    if from < 0 {
      from += 360;
    }
    let v = this.m_flight.wind;
    return CMText.DrnWind(CMPilotHud.Pad3(from % 360), IntToString(RoundF(SqrtF(v.X * v.X + v.Y * v.Y))));
  }

  public static func Q(i: Float, j: Float, k: Float, r: Float) -> Quaternion {
    let q: Quaternion;
    q.i = i;
    q.j = j;
    q.k = k;
    q.r = r;
    return q;
  }
  public static func QIdentity() -> Quaternion = CMUDrone.Q(0.0, 0.0, 0.0, 1.0)
  public static func Conj(q: Quaternion) -> Quaternion = CMUDrone.Q(-q.i, -q.j, -q.k, q.r)

  public static func QAngle(q: Quaternion) -> Float = Rad2Deg(2.0 * AcosF(ClampF(AbsF(q.r), 0.0, 1.0)))

  public static func QBlend(a: Quaternion, b: Quaternion, k: Float) -> Quaternion {
    let s = a.i * b.i + a.j * b.j + a.k * b.k + a.r * b.r < 0.0 ? -1.0 : 1.0;
    let q = CMUDrone.Q(a.i + (b.i * s - a.i) * k, a.j + (b.j * s - a.j) * k, a.k + (b.k * s - a.k) * k, a.r + (b.r * s - a.r) * k);
    let n = SqrtF(q.i * q.i + q.j * q.j + q.k * q.k + q.r * q.r);
    return n > 0.0001 ? CMUDrone.Q(q.i / n, q.j / n, q.k / n, q.r / n) : CMUDrone.QIdentity();
  }

  private func IsSelf(hit: TraceResult) -> Bool {
    let e = TraceResult.GetHitEntity(hit);
    if !IsDefined(e) {
      return false;
    }
    let drone = this.m_drone;

    return (IsDefined(drone) && e.GetEntityID() == drone.GetEntityID()) || (this.m_proxySpawned && e.GetEntityID() == this.m_proxyId);
  }

  private func Ray(from: Vector4, to: Vector4, out hit: TraceResult) -> Bool {
    let a = from;
    let i = 0;
    while i < 4 {
      if !this.RayOnce(a, to, hit) {
        return false;
      }
      if !this.IsSelf(hit) {
        return true;
      }
      this.m_selfHits += 1;
      let dir = Vector4.Normalize(to - a);
      a = Cast<Vector4>(hit.position) + dir * 0.02;
      a.W = 1.0;
      if Vector4.Dot(to - a, dir) <= 0.0 {
        return false;
      }
      i += 1;
    }
    return false;
  }

  private func RayOnce(from: Vector4, to: Vector4, out hit: TraceResult) -> Bool {
    let sq = GameInstance.GetSpatialQueriesSystem(this.m_game);

    let hs: TraceResult;
    let hd: TraceResult;
    let hv: TraceResult;

    let gotS = sq.SyncRaycastByCollisionGroup(from, to, n"Static", hs, true, false);
    let ht: TraceResult;
    let gotT = sq.SyncRaycastByCollisionGroup(from, to, n"Terrain", ht, true, false);
    if gotT && (!gotS || CMUDrone.Dist2(from, ht) < CMUDrone.Dist2(from, hs)) {
      hs = ht;
      gotS = true;
    }
    let hx: TraceResult;
    let gotX = sq.SyncRaycastByCollisionGroup(from, to, n"Destructible", hx, true, false);
    if gotX && (!gotS || CMUDrone.Dist2(from, hx) < CMUDrone.Dist2(from, hs)) {
      hs = hx;
      gotS = true;
    }
    let gotD = sq.SyncRaycastByCollisionGroup(from, to, n"Dynamic", hd, true, false);
    let gotV = sq.SyncRaycastByCollisionGroup(from, to, n"Vehicle", hv, true, false);
    let gotG = false;
    let hg: TraceResult;
    let best = 1000000.0;
    let found = false;
    if gotS {
      best = CMUDrone.Dist2(from, hs);
      hit = hs;
      found = true;
    }
    if gotD && CMUDrone.Dist2(from, hd) < best {
      best = CMUDrone.Dist2(from, hd);
      hit = hd;
      found = true;
    }
    if gotV && CMUDrone.Dist2(from, hv) < best {
      best = CMUDrone.Dist2(from, hv);
      hit = hv;
      found = true;
    }
    if gotG && CMUDrone.Dist2(from, hg) < best {
      hit = hg;
      found = true;
    }
    if gotS {
      this.m_hitS += 1;
    }
    if gotD {
      this.m_hitD += 1;
    }
    if gotV {
      this.m_hitV += 1;
    }
    if found {
      this.m_rayHits += 1;
    } else {
      this.m_rayMiss += 1;
    }
    return found;
  }

  private static func Dist2(a: Vector4, h: TraceResult) -> Float {
    let x = h.position.X - a.X;
    let y = h.position.Y - a.Y;
    let z = h.position.Z - a.Z;
    return x * x + y * y + z * z;
  }

  private func LogLoadout(drone: ref<NPCPuppet>) -> Void {
    let items: array<wref<gameItemData>>;
    GameInstance.GetTransactionSystem(this.m_game).GetItemList(drone, items);
    let names = "";
    for item in items {
      names += (StrLen(names) > 0 ? ", " : "") + TDBID.ToStringDEBUG(ItemID.GetTDBID(item.GetID()));
    }
    let rec = TweakDBInterface.GetCharacterRecord(drone.GetRecordID());
    if IsDefined(rec) {
      let ab = "";
      let list: array<wref<GameplayAbility_Record>>;
      rec.Abilities(list);
      for a in list {
        ab += (StrLen(ab) > 0 ? ", " : "") + TDBID.ToStringDEBUG(a.GetID());
      }

    }
  }

  private let m_hideComps: array<wref<IComponent>>;
  private let m_hideMasks: array<Uint64>;

  private func ShowModel(drone: ref<NPCPuppet>, on: Bool) -> Void {
    if !on {
      ArrayClear(this.m_hideComps);
      ArrayClear(this.m_hideMasks);
      for c in drone.GetComponents() {
        let sk = c as entSkinnedMeshComponent;
        if IsDefined(sk) {
          ArrayPush(this.m_hideComps, c);
          ArrayPush(this.m_hideMasks, sk.chunkMask);
          sk.chunkMask = 0ul;
        } else {
          let m = c as MeshComponent;
          if IsDefined(m) {
            ArrayPush(this.m_hideComps, c);
            ArrayPush(this.m_hideMasks, m.chunkMask);
            m.chunkMask = 0ul;
          }
        }
      }
    } else {
      let i = 0;
      while i < ArraySize(this.m_hideComps) {
        let c = this.m_hideComps[i];
        let sk = c as entSkinnedMeshComponent;
        if IsDefined(sk) {
          sk.chunkMask = this.m_hideMasks[i];
        } else {
          let m = c as MeshComponent;
          if IsDefined(m) {
            m.chunkMask = this.m_hideMasks[i];
          }
        }
        i += 1;
      }
      ArrayClear(this.m_hideComps);
      ArrayClear(this.m_hideMasks);
    }
    this.m_hidden = !on;
  }

  public static func Expo(x: Float, e: Float) -> Float = x * (1.0 - e) + x * x * x * e

  private func Crippled() -> Bool = Equals(this.m_kind, "octant") && IsDefined(this.m_flight) && this.m_flight.failing >= 1

  private let m_crashTouch: Bool;

  private func CrippledGround(drone: ref<NPCPuppet>, dt: Float) -> Void {
    if !this.Crippled() || !IsDefined(drone) || !ScriptedPuppet.IsAlive(drone) {
      this.m_crashTouch = false;
      return;
    }
    let touching = this.m_ground >= 0.0 && this.m_ground < this.m_flight.p.bottom + 0.3;
    let pools = GameInstance.GetStatPoolsSystem(this.m_game);
    let id = Cast<StatsObjectID>(drone.GetEntityID());
    if touching && !this.m_crashTouch {
      pools.RequestChangingStatPoolValue(id, gamedataStatPoolType.Health, -25.0, null, false, true);
      GameObject.PlaySoundEvent(drone, n"dev_generic_impact_metal");
    }
    if touching {
      pools.RequestChangingStatPoolValue(id, gamedataStatPoolType.Health, -50.0 * dt, null, false, true);
    }
    this.m_crashTouch = touching;
  }

  private func ImpactLimit() -> Float = this.Crippled() ? MinF(2.5, this.m_flight.p.impact * 0.4) : this.m_flight.p.impact

  private func Impact(drone: ref<NPCPuppet>, speed: Float) -> Void {
    let limit = this.ImpactLimit();
    if speed <= limit {
      return;
    }
    let over = speed - limit;
    let pct = MinF(100.0, over * over * 4.0);
    if this.Crippled() {
      pct = MinF(100.0, 15.0 + over * over * 16.0);
    }
    GameInstance.GetStatPoolsSystem(this.m_game).RequestChangingStatPoolValue(Cast<StatsObjectID>(drone.GetEntityID()), gamedataStatPoolType.Health, -pct, null, false, true);
    GameObject.PlaySoundEvent(drone, n"dev_generic_impact_metal");
  }

  private func Place(drone: ref<NPCPuppet>, now: Float) -> Void {

    let fl = this.m_flight;
    let q = fl.Shown(this.m_show);
    let r = this.Root();
    let wt: WorldTransform;
    let world: WorldPosition;
    WorldPosition.SetVector4(world, r);
    WorldTransform.SetWorldPosition(wt, world);
    WorldTransform.SetOrientation(wt, q);
    this.m_placed = fl.pos;
    this.SyncMovement(drone, fl, now);

    if this.m_proxyLive {
      if this.m_heldOk {
        drone.SetWorldTransform(this.m_heldWt);
      } else {
        drone.SetWorldTransform(wt);
      }
      this.m_heldWt = wt;
      this.m_heldOk = true;
      return;
    }
    this.m_heldOk = false;
    drone.SetWorldTransform(wt);
  }

  private func SyncMovement(drone: ref<NPCPuppet>, fl: ref<CMFlight>, now: Float) -> Void {
    let ai = drone.GetAIControllerComponent();
    if !IsDefined(ai) || !this.m_proxyLive || !this.m_heldOk {
      return;
    }
    if this.m_aiOffAt > 0.0 && now >= this.m_aiOffAt {
      ai.Toggle(false);
      this.m_aiOffAt = 0.0;
      return;
    }
    if now < this.m_aiSyncAt || this.m_aiOffAt > 0.0 {
      return;
    }
    this.m_aiSyncAt = now + 1.0;
    ai.Toggle(true);
    let tp = new AITeleportCommand();
    tp.position = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(this.m_heldWt));
    tp.rotation = fl.yaw;
    tp.doNavTest = false;
    ai.SendCommand(tp);
    this.m_aiOffAt = now + 0.15;
  }

  private func Cancel(drone: ref<NPCPuppet>) -> Void {
    let ai = drone.GetAIControllerComponent();
    if IsDefined(ai) && IsDefined(this.m_cmd) {
      ai.CancelCommand(this.m_cmd);
    }
    this.m_cmd = null;
  }

  private func Lean(drone: ref<NPCPuppet>, dt: Float) -> Void {
    let fl = this.m_flight;
    let loco = new AnimFeature_DroneLocomotion();
    loco.speed = 0.0;
    loco.desiredSpeed = 0.0;
    loco.angularSpeed = 0.0;
    loco.lookAtAngle = 0.0;
    loco.pathCurvative = 0.0;
    AnimationControllerComponent.ApplyFeature(drone, n"DroneLocomotion", loco);

    let alt = new AnimFeature_DroneActionAltitudeOffset();
    alt.desiredOffset = 0.0;
    AnimationControllerComponent.ApplyFeature(drone, n"ActionAltitudeOffset", alt);
    this.SetGait(drone, n"Walk");
    this.HoldPose(drone);
  }

  private let m_poseAt: Float;
  private func HoldPose(drone: ref<NPCPuppet>) -> Void {
    let now = EngineTime.ToFloat(GameInstance.GetEngineTime(this.m_game));
    if now < this.m_poseAt {
      return;
    }
    this.m_poseAt = now + 1.0;
    let st = drone.GetHighLevelStateFromBlackboard();
    if NotEquals(st, gamedataNPCHighLevelState.Relaxed) && NotEquals(st, gamedataNPCHighLevelState.Dead) {

      let aic = drone.GetAIControllerComponent();
      let tt = drone.GetTargetTrackerComponent();
      let threats: array<TrackedLocation>;
      if IsDefined(tt) {
        threats = tt.GetThreats(false);
      }
      NPCPuppet.ChangeHighLevelState(drone, gamedataNPCHighLevelState.Relaxed);
      GameInstance.GetAnimationSystem(this.m_game).ExitCombatMode(drone.GetEntityID());
    }
  }

  private func SetGait(drone: ref<NPCPuppet>, gait: CName) -> Void {
    if Equals(gait, this.m_gait) {
      return;
    }
    this.m_gait = gait;
    AnimationControllerComponent.SetAnimWrapperWeight(drone, n"DroneLocomotion_Walk", Equals(gait, n"Walk") ? 1.0 : 0.0);
    AnimationControllerComponent.SetAnimWrapperWeight(drone, n"DroneLocomotion_Run", Equals(gait, n"Run") ? 1.0 : 0.0);
    AnimationControllerComponent.SetAnimWrapperWeight(drone, n"DroneLocomotion_Sprint", Equals(gait, n"Sprint") ? 1.0 : 0.0);
  }

  private func Report(drone: ref<NPCPuppet>) -> Void {
    let fl = this.m_flight;
    let real = Quaternion.ToEulerAngles(drone.GetWorldOrientation());

    let heights = "";
    if this.m_ground >= 0.0 {
      let gz = fl.pos.Z - this.m_ground;
      let eye = this.Anchor().Z + this.SensorUp();
      heights = ", above the road: sight-view eye " + FloatToStringPrec(eye - gz, 2) + " m, body centre " + FloatToStringPrec(fl.pos.Z - gz, 2) + " m";
    }
    if this.m_lmgRounds > 0 {
      heights += ", lmg " + IntToString(this.m_lmgRounds) + " rounds, " + IntToString(this.m_lmgHits) + " struck a target (last " + this.m_lmgLast + "), " + IntToString(this.m_shotSelf) + " steps past its own body";
      this.m_shotSelf = 0;
      this.m_lmgRounds = 0;
      this.m_lmgHits = 0;
    }
    let wv = fl.wind;
    let wname = IsDefined(CMWind.Get(this.m_game)) ? CMWind.Get(this.m_game).Weather() : "?";
    heights += ", wind " + FloatToStringPrec(SqrtF(wv.X * wv.X + wv.Y * wv.Y), 1) + " m/s (vert " + FloatToStringPrec(wv.Z, 1) + ", exposure " + FloatToStringPrec(this.m_exposure, 2) + ", weather " + wname + ")";
    heights += ", ground effect x" + FloatToStringPrec(fl.groundGain, 3) + (IsDefined(this.m_wash) ? " (downwash dust)" : "") + (this.m_hold ? ", gunship hold" : "");
    heights += ", own-body hits skipped " + IntToString(this.m_selfHits) + (this.m_hidden ? ", model hidden" : "");
    this.m_selfHits = 0;
    this.m_frames = 0;
    this.m_rayHits = 0;
    this.m_rayMiss = 0;
    this.m_hitS = 0;
    this.m_hitD = 0;
    this.m_hitV = 0;
  }

  public static func HasTypeB(kind: String) -> Bool = true

  public func NewHud() -> ref<CMPilotHud> {

    let typeB = CMPilotSystem.Get(this.m_game).DroneHudStyle(this.m_kind) == 1;
    if Equals(this.m_kind, "bombus") {

      if typeB {
        let bb = new CMBombusBHud();
        bb.SetKind(this.m_kind);
        bb.SetTypeB(true);
        return bb;
      }
      let b = new CMBombusHud();
      b.SetKind(this.m_kind);
      b.SetTypeB(typeB);
      return b;
    }
    if Equals(this.m_kind, "griffin") {

      if typeB {
        let gb = new CMGriffinBHud();
        gb.SetKind(this.m_kind);
        gb.SetTypeB(true);
        return gb;
      }
      let g = new CMGriffinHud();
      g.SetKind(this.m_kind);
      g.SetTypeB(typeB);
      return g;
    }
    if Equals(this.m_kind, "wyvern") {

      if typeB {
        let wb = new CMWyvernBHud();
        wb.SetKind(this.m_kind);
        wb.SetTypeB(true);
        return wb;
      }
      let w = new CMWyvernHud();
      w.SetKind(this.m_kind);
      w.SetTypeB(typeB);
      return w;
    }

    if typeB {
      let ob = new CMOctantBHud();
      ob.SetKind(this.m_kind);
      ob.SetTypeB(true);
      return ob;
    }
    let h = new CMDroneHud();
    h.SetKind(this.m_kind);
    h.SetTypeB(typeB);
    return h;
  }

  public func Hud(s: ref<CMCSession>, st: ref<CMPilotHudState>) -> Void {
    let drone = this.m_drone;
    if IsDefined(drone) {
      st.integrity = GameInstance.GetStatPoolsSystem(this.m_game).GetStatPoolValue(Cast<StatsObjectID>(drone.GetEntityID()), gamedataStatPoolType.Health, true) / 100.0;
    }
    ArrayClear(st.parts);
    st.hasL = false;
    st.hasR = false;
    st.missile = "";
    let link = CMLinkSystem.Get(this.m_game);
    st.signal = link.SignalFraction();
    st.distance = MaxF(0.0, link.Distance());
    st.title = this.m_name;
    st.role = CMUDrone.Role(this.m_kind);
    if IsDefined(this.m_flight) {
      let fl = this.m_flight;
      st.speed = Vector4.Length(fl.vel);
      st.alt = this.m_ground >= 0.0 ? this.m_ground : -1.0;
      st.vs = fl.vel.Z;
      st.pitch = fl.pitch;
      st.roll = fl.roll;
      st.spool = fl.Spool();
    }

    st.home = 999.0;
    let pl = GetPlayer(this.m_game);
    if IsDefined(pl) && IsDefined(this.m_flight) {
      st.home = CMPilotRig.Wrap(s.rig.yaw - CMPilotRig.YawOf(pl.GetWorldPosition() - this.m_flight.pos));
    }

    st.weapon = this.m_wpn;
    st.secHeat = this.m_heat;
    let standoff = s.aimDist > 0.0 && IsDefined(this.m_flight) ? CMText.DrnStandoff(IntToString(RoundF(CMUDrone.Flat(this.m_flight.pos, s.aim)))) : "";
    st.holdText = this.m_hold ? CMText.DrnHolding(standoff, CMKeys.GunshipName(GetPlayer(this.m_game))) : "";
    st.windText = this.WindText();
    if Equals(this.m_kind, "octant") && ArraySize(this.m_partHp) >= 6 {
      let now = s.Now();
      let gun = this.m_partHp[5] > 0.0;
      let mortar = this.m_partHp[8] > 0.0;
      let pods = this.RocketPods();
      st.priText = CMText.DrnMortarLine(IntToString(this.MORTAR_SHELLS), !mortar ? CMText.DrnLost() : (now >= this.m_mortarReady ? (this.m_impactOk ? CMText.DrnRdy() : CMText.DrnNoSoln()) : CMText.DrnRldShort(FloatToStringPrec(this.m_mortarReady - now, 1))));
      st.secText = CMText.DrnLmgLine(!gun ? CMText.DrnLost() : (this.m_overheat ? CMText.DrnOverheat() : (this.m_offArc ? CMText.DrnOffArc() : CMText.DrnHeat(IntToString(RoundF(this.m_heat * 100.0))))));
      st.terText = CMText.DrnRocketsLine(IntToString(this.m_rockets), IntToString(pods * 2), pods == 0 ? CMText.DrnLost() : (this.m_rockets > 0 ? CMText.DrnRdy() : CMText.DrnRldShort(FloatToStringPrec(MaxF(0.0, this.m_podReady - now), 1))));

      ArrayClear(st.wStat);
      ArrayClear(st.wSub);
      ArrayPush(st.wStat, !mortar ? "LOST" : (now >= this.m_mortarReady ? (this.m_impactOk ? "RDY" : "NO SOLN") : "RLD " + FloatToStringPrec(this.m_mortarReady - now, 1) + " S"));
      ArrayPush(st.wSub, this.m_impactOk ? CMText.DrnShellsTof(IntToString(this.MORTAR_SHELLS), FloatToStringPrec(this.m_tof, 1)) : CMText.DrnShells(IntToString(this.MORTAR_SHELLS)));
      ArrayPush(st.wStat, !gun ? "LOST" : (this.m_overheat ? "OVERHEAT" : (this.m_offArc ? "OFF ARC" : (this.m_lmgArc > 0.0 ? "ARC " + IntToString(RoundF(this.m_lmgArc)) : "RDY"))));
      ArrayPush(st.wSub, CMText.DrnLmgSub(IntToString(RoundF(this.m_heat * 100.0))));
      ArrayPush(st.wStat, pods == 0 ? "LOST" : (this.m_rockets > 0 ? "RDY" : "RLD " + FloatToStringPrec(MaxF(0.0, this.m_podReady - now), 1) + " S"));
      ArrayPush(st.wSub, CMText.DrnLaserSub(IntToString(this.m_rockets), IntToString(pods * 2)));
      st.rkLeft = this.m_rockets;
      st.rkMax = pods * 2;
    } else {
      if Equals(this.m_kind, "bombus") {

        st.priText = CMText.DrnPayloadLine(CMUDrone.PayloadName(this.m_payload));
        st.secText = this.m_payload > 0 ? (this.m_detonated ? CMText.DrnReleased() : CMText.DrnArmed()) : CMText.DrnDisarmed();
        st.terText = this.m_flight.level >= 0.8 ? CMText.DrnAngle() : (this.m_flight.level >= 0.3 ? CMText.DrnHorizon() : CMText.DrnAcro());
      } else {

        let now = s.Now();
        let gunStat = this.m_overheat ? "OVERHEAT" : (this.m_heat >= 0.7 ? "HOT" : "RDY");
        ArrayClear(st.wStat);
        ArrayClear(st.wSub);
        ArrayPush(st.wStat, gunStat);
        ArrayPush(st.wSub, CMText.DrnSmgSub(IntToString(RoundF(this.m_heat * 100.0))));
        st.priText = CMText.DrnSmgLine(this.m_overheat ? CMText.DrnOverheat() : (this.m_heat >= 0.7 ? CMText.DrnHot() : CMText.DrnRdy()));
        st.secText = "";
        st.terText = "";
        st.rkMax = this.RocketCap();
        st.rkLeft = this.m_rockets;
        if st.rkMax > 0 {
          let rkStat = this.m_rockets > 0 ? "RDY" : "RLD " + FloatToStringPrec(MaxF(0.0, this.m_podReady - now), 1) + " S";
          ArrayPush(st.wStat, rkStat);
          ArrayPush(st.wSub, CMText.DrnRocketsSub(IntToString(this.m_rockets), IntToString(st.rkMax)));
          st.secText = CMText.DrnRocketsShort(IntToString(this.m_rockets), IntToString(st.rkMax), this.m_rockets > 0 ? CMText.DrnRdy() : CMText.DrnRld(FloatToStringPrec(MaxF(0.0, this.m_podReady - now), 1)));
        }
      }
    }

    ArrayClear(st.droneParts);
    let pi = 0;
    for hp in this.m_partHp {
      ArrayPush(st.droneParts, pi == 0 ? st.integrity : hp);
      pi += 1;
    }

    st.warning = "";
  }

  public static func Role(kind: String) -> String {
    switch kind {
      case "octant": return "OVERWATCH";
      case "bombus": return "RECON";
      case "griffin": return "STRIKE";
    }
    return "ESCORT";
  }

  private let m_wpn: Int32;
  private let m_mortarReady: Float;
  private let m_missileReady: Float;
  private let m_heat: Float;
  private let m_overheat: Bool;
  private let m_lmgNext: Float;
  private let m_lmgLeft: Bool;
  private let m_lmgSound: Bool;
  private let m_impactAt: Vector4;
  private let m_impactOk: Bool;
  private let m_tof: Float;
  private let m_shots: array<ref<CMDroneShot>>;
  private let m_lmgRounds: Int32;
  private let m_lmgHits: Int32;
  private let m_lmgLast: String;
  private let m_shotSelf: Int32;
  private let m_lmgImpact: Bool;
  private let MORTAR_MIN: Float = 15.0;
  private let MORTAR_MAX: Float = 450.0;
  private let MORTAR_COOLDOWN: Float = 5.0;
  private let MORTAR_SHELLS: Int32 = 4;
  private let MORTAR_FALL: Float = 1.1;
  private let MORTAR_RADIUS: Float = 5.0;
  private let MORTAR_DAMAGE: Float = 450.0;
  private let MISSILE_SPEED: Float = 90.0;
  private let ROCKET_POD: Int32 = 4;
  private let ROCKET_GAP: Float = 0.22;
  private let ROCKET_RELOAD: Float = 6.0;
  private let m_rockets: Int32;
  private let m_podReady: Float;
  private let m_rocketSide: Bool;
  private let m_lmgArc: Float;
  private let m_offArc: Bool;
  private let MISSILE_RADIUS: Float = 4.5;
  private let MISSILE_DAMAGE: Float = 900.0;
  private let MISSILE_LIFE: Float = 7.0;
  private let LMG_RATE: Float = 0.075;
  private let BULLET_SPEED: Float = 320.0;
  private let ROUND_STREAK: Float = 9.0;
  private let LMG_DAMAGE: Float = 60.0;
  private let LMG_SHARE: Float = 0.05;
  private let LMG_CAP: Float = 400.0;
  private let LMG_HEAT: Float = 0.022;
  private let LMG_COOL: Float = 0.35;

  private let SMG_RATE: Float = 0.05;
  private let SMG_DAMAGE: Float = 22.0;
  private let SMG_SHARE: Float = 0.02;
  private let SMG_CAP: Float = 140.0;
  private let SMG_HEAT: Float = 0.012;
  private func Smg() -> Bool = Equals(this.m_kind, "griffin") || Equals(this.m_kind, "wyvern")
  private func GunRate() -> Float = this.Smg() ? this.SMG_RATE : this.LMG_RATE

  private func Weapons(s: ref<CMCSession>, now: Float, dt: Float, hud: ref<CMDroneHud>) -> Void {
    this.Fly(s, dt);

    if this.m_payload > 0 && !this.m_detonated && s.Key(CMCKey.Lmb()) {
      this.Detonate(true);
      return;
    }
    if !this.Armed() {
      return;
    }
    let octant = Equals(this.m_kind, "octant");
    if octant && ArraySize(this.m_partHp) < 6 {
      return;
    }
    let drone = this.m_drone;
    let gun = !octant || this.m_partHp[5] > 0.0;
    let mortar = octant && this.m_partHp[8] > 0.0;

    this.m_heat = MaxF(0.0, this.m_heat - this.LMG_COOL * dt);
    if this.m_overheat && this.m_heat < 0.33 {
      this.m_overheat = false;
      GameObject.PlaySoundEvent(drone, n"w_gun_hmg_militech_overheat_close");
    }

    if this.m_rockets <= 0 && this.m_podReady > 0.0 && now >= this.m_podReady {
      this.m_rockets = this.RocketCap();
      this.m_podReady = 0.0;
      GameObject.PlaySoundEvent(drone, n"w_gun_hmg_militech_overheat_close");
    }

    if octant {
      this.AimMortar(s);
      if IsDefined(hud) {
        let o = this.Screen(s, this.m_impactAt);
        hud.SetImpact(gun && this.m_wpn == 0 && this.m_impactOk && AbsF(o.X) < 1900.0 && AbsF(o.Y) < 1050.0, o.X, o.Y, this.m_tof);
      }
    }
    let firing = false;
    let wt = this.WpnType();
    if s.Key(CMCKey.Lmb()) {
      if wt == 1 {
        if gun {
          firing = this.FireLmg(s, now);
        }
      } else {
        if wt == 2 {
          this.FireMissile(s, now);
        } else {
          if mortar {
            this.FireMortar(s, now);
          }
        }
      }
    }
    if NotEquals(firing, this.m_lmgSound) {
      this.m_lmgSound = firing;
      GameObject.PlaySoundEvent(drone, firing ? n"w_gun_hmg_militech_fire_auto" : n"w_gun_hmg_militech_fire_auto_stop");
    }
  }

  public func Select(s: ref<CMCSession>) -> Bool {
    if Equals(this.m_kind, "octant") {
      this.m_wpn = (this.m_wpn + 1) % 3;
    } else {
      if !Equals(this.m_kind, "griffin") {
        return false;
      }
      this.m_wpn = (this.m_wpn + 1) % 2;
    }
    return true;
  }

  public func Secondary(s: ref<CMCSession>) -> Void {
    if Equals(this.m_kind, "wyvern") && IsDefined(this.m_sense) {
      if this.m_sense.Ping(this.m_drone, s.Now()) {
      }
      return;
    }
    if (Equals(this.m_kind, "octant") && ArraySize(this.m_partHp) >= 6) || Equals(this.m_kind, "griffin") {
      this.FireMissile(s, s.Now());
    }
  }

  private func AimMortar(s: ref<CMCSession>) -> Void {
    this.m_impactOk = false;
    if s.aimDist <= 0.0 {
      return;
    }
    let at = s.aim;
    at.W = 1.0;
    this.m_impactAt = at;
    let d = Vector4.Distance(this.m_flight.pos, at);
    this.m_impactOk = d >= this.MORTAR_MIN && d <= this.MORTAR_MAX;
    this.m_tof = this.CarrierTime(at) + this.MORTAR_FALL;
  }

  private func CarrierTime(at: Vector4) -> Float = 1.8 + CMUDrone.Flat(this.m_flight.pos, at) / 110.0

  public static func Flat(a: Vector4, b: Vector4) -> Float {
    let dx = b.X - a.X;
    let dy = b.Y - a.Y;
    return SqrtF(dx * dx + dy * dy);
  }

  private func FireMortar(s: ref<CMCSession>, now: Float) -> Void {
    if now < this.m_mortarReady {
      return;
    }
    if !this.m_impactOk {
      GameObject.PlaySoundEvent(GetPlayer(this.m_game), n"ui_hacking_press_fail");
      this.m_mortarReady = now + 0.4;
      return;
    }
    this.m_mortarReady = now + this.MORTAR_COOLDOWN;
    let target = this.m_impactAt;
    let flat = CMUDrone.Flat(this.m_flight.pos, target);

    let shot = new CMDroneShot();
    shot.kind = 0;
    shot.from = this.m_flight.pos + new Vector4(0.0, 0.0, 0.7, 0.0);
    shot.from.W = 1.0;
    shot.to = target + new Vector4(0.0, 0.0, MinF(60.0, 32.0 + flat * 0.06), 0.0);
    shot.to.W = 1.0;
    shot.via = new Vector4(shot.from.X * 0.8 + shot.to.X * 0.2, shot.from.Y * 0.8 + shot.to.Y * 0.2, MaxF(shot.from.Z, shot.to.Z) + 30.0 + flat * 0.25, 1.0);
    shot.target = target;
    shot.life = this.CarrierTime(target);
    shot.pos = shot.from;
    let up = new Vector4(0.0, 0.0, 1.0, 0.0);
    let fx = GameInstance.GetFxSystem(this.m_game);
    fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\vehicles\\av\\av_panzer\\weapons\\v_panzer_rocket_launcher_muzzle.effect"), CMUMinotaur.At(shot.from, up), true);
    shot.fx = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\trails\\smart\\w_trail_rocket_luncher.effect"), CMUMinotaur.At(shot.from, up), true);
    ArrayPush(this.m_shots, shot);
    GameObject.PlaySoundEvent(this.m_drone, n"nme_boss_smasher_wpn_missile_fire_single");
    s.rig.Recoil(0.5);
  }

  private func Burst(c: ref<CMDroneShot>) -> Void {
    let fx = GameInstance.GetFxSystem(this.m_game);
    fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\w_explosion_small.effect"), CMUMinotaur.At(c.to, new Vector4(0.0, 0.0, -1.0, 0.0)), true);
    let spread = 3.0 + CMUDrone.Flat(c.from, c.target) * 0.012;
    let i = 0;
    while i < this.MORTAR_SHELLS {
      let a = RandRangeF(0.0, 6.2832);
      let r = spread * SqrtF(RandRangeF(0.05, 1.0));
      let p = new Vector4(c.target.X + CosF(a) * r, c.target.Y + SinF(a) * r, c.target.Z, 1.0);

      let hit: TraceResult;
      if CMGround.World(this.m_game, p + new Vector4(0.0, 0.0, 12.0, 0.0), p - new Vector4(0.0, 0.0, 25.0, 0.0), hit) {
        p = Cast<Vector4>(hit.position);
        p.W = 1.0;
      }
      let r1 = new CMDroneShot();
      r1.kind = 1;
      r1.from = c.to;
      r1.to = p;
      r1.target = p;
      r1.pos = c.to;
      r1.age = -0.14 * Cast<Float>(i);
      r1.life = this.MORTAR_FALL;
      ArrayPush(this.m_shots, r1);
      i += 1;
    }
  }

  private func Land(p: Vector4) -> Void {
    GameInstance.GetFxSystem(this.m_game).SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\w_explosion_medium.effect"), CMUMinotaur.At(p, new Vector4(0.0, 0.0, 1.0, 0.0)), true);
    this.Blast(p, t"Attacks.CM_Mortar", this.MORTAR_RADIUS, this.MORTAR_DAMAGE);
  }

  private func FireMissile(s: ref<CMCSession>, now: Float) -> Void {
    let pods = this.RocketPods();
    if now < this.m_missileReady || this.m_rockets <= 0 || pods == 0 {
      return;
    }
    this.m_missileReady = now + this.ROCKET_GAP;
    this.m_rockets -= 1;
    if this.m_rockets == 0 {
      this.m_podReady = now + this.ROCKET_RELOAD;
    }
    this.m_rocketSide = !this.m_rocketSide;

    if ArraySize(this.m_partHp) >= CMUDrone.OctantParts() && pods == 1 {
      this.m_rocketSide = this.m_partHp[6] > 0.0;
    }
    let m = new CMDroneShot();
    m.kind = 2;
    m.pos = this.SlotPos(this.m_rocketSide ? n"Wing1" : n"Wing2", this.Muzzle(this.m_rocketSide ? -0.6 : 0.6));

    let local = CMFlight.QInvRot(this.m_flight.q, m.pos - this.m_flight.pos);
    if local.Z < -1.0 {
      m.pos += CMFlight.QRot(this.m_flight.q, this.m_tt);
      m.pos.W = 1.0;
    }
    let dir = Vector4.Normalize(s.aim - m.pos);
    m.vel = dir * 30.0 + this.m_flight.vel;
    m.life = this.MISSILE_LIFE;
    let fx = GameInstance.GetFxSystem(this.m_game);
    fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\firearms\\special\\vehicle_rocket_launcher\\w_special_vehicle_rocket_launcher.effect"), CMUMinotaur.At(m.pos, dir), true);
    m.fx = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\vehicles\\weapons\\v_vehicle_rocket_trail.effect"), CMUMinotaur.At(m.pos, dir), true);
    ArrayPush(this.m_shots, m);
    GameObject.PlaySoundEvent(this.m_drone, n"nme_boss_smasher_wpn_missile_fire_single");
    s.rig.Recoil(0.4);
  }

  private func MissileBurst(p: Vector4, dir: Vector4) -> Void {
    let fx = GameInstance.GetFxSystem(this.m_game);
    fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\vehicles\\weapons\\v_vehicle_rocket_impact.effect"), CMUMinotaur.At(p, -dir), true);
    fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\w_explosion_medium.effect"), CMUMinotaur.At(p, new Vector4(0.0, 0.0, 1.0, 0.0)), true);
    this.Blast(p, t"Attacks.CM_Missile", this.MISSILE_RADIUS, this.MISSILE_DAMAGE);
  }

  private func Fly(s: ref<CMCSession>, dt: Float) -> Void {
    let i = 0;
    while i < ArraySize(this.m_shots) {
      let sh = this.m_shots[i];
      sh.age += dt;
      let done = false;
      if sh.kind == 2 {
        done = this.FlyMissile(s, sh, dt);
      } else if sh.kind == 3 {
        done = this.FlyRound(s, sh);
      } else {
        if sh.age >= 0.0 {
          let u = ClampF(sh.age / sh.life, 0.0, 1.0);
          let p: Vector4;
          if sh.kind == 0 {

            let a = 1.0 - u;
            p = sh.from * (a * a) + sh.via * (2.0 * a * u) + sh.to * (u * u);
          } else {

            p = sh.from + (sh.to - sh.from) * (u * u);
          }
          p.W = 1.0;
          let dir = Vector4.Normalize(p - sh.pos);
          if !IsDefined(sh.fx) && sh.kind == 1 {
            sh.fx = GameInstance.GetFxSystem(this.m_game).SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\trails\\smart\\w_trail_rocket_luncher.effect"), CMUMinotaur.At(p, dir), true);
          }
          if IsDefined(sh.fx) && Vector4.Length(p - sh.pos) > 0.001 {
            sh.fx.UpdateTransform(CMUMinotaur.At(p, dir));
          }
          sh.pos = p;
          if u >= 1.0 {
            if sh.kind == 0 {
              this.Burst(sh);
            } else {
              this.Land(sh.to);
            }
            done = true;
          }
        }
      }
      if done {
        if IsDefined(sh.fx) {
          sh.fx.BreakLoop();
        }
        ArrayErase(this.m_shots, i);
      } else {
        i += 1;
      }
    }
  }

  private func FlyMissile(s: ref<CMCSession>, m: ref<CMDroneShot>, dt: Float) -> Bool {
    let speed = MinF(this.MISSILE_SPEED, Vector4.Length(m.vel) + 120.0 * dt);
    let dir = Vector4.Normalize(m.vel);

    if IsDefined(s) && m.age > 0.05 {
      let want = Vector4.Normalize(s.aim - m.pos);
      dir = Vector4.Normalize(dir + (want - dir) * MinF(1.0, 8.0 * dt));
    }
    m.vel = dir * speed;
    let next = m.pos + m.vel * dt;
    next.W = 1.0;
    let hit: TraceResult;
    if this.ShotRay(m.pos, next, hit) {
      let p = Cast<Vector4>(hit.position);
      p.W = 1.0;
      this.MissileBurst(p, dir);
      return true;
    }
    m.pos = next;
    if IsDefined(m.fx) {
      m.fx.UpdateTransform(CMUMinotaur.At(next, dir));
    }
    if m.age >= m.life {
      this.MissileBurst(next, dir);
      return true;
    }
    return false;
  }

  private func DropShots() -> Void {
    for sh in this.m_shots {
      if IsDefined(sh.fx) {
        sh.fx.Kill();
      }
    }
    ArrayClear(this.m_shots);
  }

  private func FireLmg(s: ref<CMCSession>, now: Float) -> Bool {
    if this.m_overheat {
      return false;
    }

    this.m_offArc = false;
    if this.m_lmgArc > 0.0 && Equals(this.m_kind, "octant") {
      let nose = CMFlight.QRot(this.m_flight.q, new Vector4(0.0, 1.0, 0.0, 0.0));
      let to = Vector4.Normalize(s.aim - this.m_flight.pos);
      if Rad2Deg(AcosF(ClampF(Vector4.Dot(nose, to), -1.0, 1.0))) > this.m_lmgArc {
        this.m_offArc = true;
        this.m_lmgNext = MaxF(this.m_lmgNext, now);
        return false;
      }
    }
    let fired = false;
    while now >= this.m_lmgNext {
      this.m_lmgNext = MaxF(this.m_lmgNext + this.GunRate(), now - this.GunRate());
      this.m_lmgLeft = !this.m_lmgLeft;
      let muzzle = this.LmgMuzzle(this.m_lmgLeft);
      let aim = s.aim;
      let dist = Vector4.Distance(muzzle, aim);
      let worn = ArraySize(this.m_partHp) >= CMUDrone.OctantParts() && this.m_partHp[5] < 0.5;
      let spread = dist * (worn ? 0.014 : (this.Smg() ? 0.009 : 0.006));
      aim += new Vector4(RandRangeF(-spread, spread), RandRangeF(-spread, spread), RandRangeF(-spread, spread), 0.0);
      let dir = Vector4.Normalize(aim - muzzle);
      let fx = GameInstance.GetFxSystem(this.m_game);

      if this.Smg() {

        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\firearms\\smgs\\darra_pulsar\\w_smg_pulsar_muzzle_tpp.effect"), CMUMinotaur.At(muzzle, dir), true);
        if s.SightView() {
          fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\firearms\\smgs\\militech_saratoga\\w_smg_saratoga_muzzle.effect"), CMUMinotaur.At(muzzle, dir), true);
        }
      } else {
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\firearms\\special\\militech_hmg\\w_special_hmg_muzzle_tpp.effect"), CMUMinotaur.At(muzzle, dir), true);
        if s.SightView() {
          fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\firearms\\special\\militech_hmg\\w_special_hmg_muzzle.effect"), CMUMinotaur.At(muzzle, dir), true);
        }
      }

      let hit: TraceResult;
      let far = muzzle + dir * (dist + 3.0);
      far.W = 1.0;
      let end = far;
      let struck = false;
      let target: wref<GameObject>;
      if this.ShotRay(muzzle, far, hit) {
        end = Cast<Vector4>(hit.position);
        end.W = 1.0;
        struck = true;
        target = TraceResult.GetHitEntity(hit) as GameObject;
      }

      let toAim = s.aim - muzzle;
      let along = Vector4.Dot(toAim, dir);
      let off = toAim - dir * along;
      off.W = 0.0;
      if !IsDefined(target) && IsDefined(s.aimEntity) && along > 0.0 && along <= Vector4.Distance(muzzle, end) + 2.0 && Vector4.Length(off) < 1.5 {
        target = s.aimEntity as GameObject;
        end = s.aim;
        end.W = 1.0;
        struck = true;
      }

      let round = new CMDroneShot();
      round.kind = 3;
      round.from = muzzle;
      round.to = end;
      round.pos = muzzle;
      round.vel = dir;
      round.life = MaxF(0.02, Vector4.Distance(muzzle, end) / this.BULLET_SPEED);
      round.struck = struck;
      round.hit = target;
      ArrayPush(this.m_shots, round);
      this.m_lmgRounds += 1;
      this.m_bdaRounds += 1;

      s.rig.Recoil(this.Smg() ? 0.06 : 0.26);
      this.m_heat += (this.Smg() ? this.SMG_HEAT : this.LMG_HEAT) * (ArraySize(this.m_partHp) >= CMUDrone.OctantParts() && this.m_partHp[5] < 0.5 ? 1.5 : 1.0);
      fired = true;
      if this.m_heat >= 1.0 {
        this.m_heat = 1.0;
        this.m_overheat = true;
        GameObject.PlaySoundEvent(this.m_drone, n"w_gun_hmg_militech_overheat_open");
        GameObject.PlaySoundEvent(this.m_drone, n"w_gun_hmg_militech_overheat_steam");
        return false;
      }
    }
    return fired || now < this.m_lmgNext;
  }

  private func AutoLmg(now: Float) -> Void {
    let n = 0;
    while now >= this.m_lmgNext && n < 4 {
      this.m_lmgNext = MaxF(this.m_lmgNext + this.GunRate(), now - this.GunRate());
      this.m_lmgLeft = !this.m_lmgLeft;
      let muzzle = this.LmgMuzzle(this.m_lmgLeft);
      let aim = this.autoAim;
      let dist = Vector4.Distance(muzzle, aim);
      let spread = dist * (this.Smg() ? 0.012 : 0.009);
      aim += new Vector4(RandRangeF(-spread, spread), RandRangeF(-spread, spread), RandRangeF(-spread, spread), 0.0);
      let dir = Vector4.Normalize(aim - muzzle);
      let fx = GameInstance.GetFxSystem(this.m_game);
      if this.Smg() {
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\firearms\\smgs\\darra_pulsar\\w_smg_pulsar_muzzle_tpp.effect"), CMUMinotaur.At(muzzle, dir), true);
      } else {
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\firearms\\special\\militech_hmg\\w_special_hmg_muzzle_tpp.effect"), CMUMinotaur.At(muzzle, dir), true);
      }
      let hit: TraceResult;
      let far = muzzle + dir * (dist + 3.0);
      far.W = 1.0;
      let end = far;
      let struck = false;
      let target: wref<GameObject>;
      if this.ShotRay(muzzle, far, hit) {
        end = Cast<Vector4>(hit.position);
        end.W = 1.0;
        struck = true;
        target = TraceResult.GetHitEntity(hit) as GameObject;
      }

      let toAim = this.autoAim - muzzle;
      let along = Vector4.Dot(toAim, dir);
      let off = toAim - dir * along;
      off.W = 0.0;
      if !IsDefined(target) && along > 0.0 && along <= Vector4.Distance(muzzle, end) + 2.0 && Vector4.Length(off) < 1.5 {
        target = this.autoTarget;
        end = this.autoAim;
        end.W = 1.0;
        struck = true;
      }
      let round = new CMDroneShot();
      round.kind = 3;
      round.from = muzzle;
      round.to = end;
      round.pos = muzzle;
      round.vel = dir;
      round.life = MaxF(0.02, Vector4.Distance(muzzle, end) / this.BULLET_SPEED);
      round.struck = struck;
      round.hit = target;
      ArrayPush(this.m_shots, round);
      this.m_lmgRounds += 1;
      n += 1;
    }
  }

  private func FlyRound(s: ref<CMCSession>, r: ref<CMDroneShot>) -> Bool {
    let u = ClampF(r.age / r.life, 0.0, 1.0);
    let head = r.from + (r.to - r.from) * u;
    head.W = 1.0;
    let back = MinF(this.ROUND_STREAK, Vector4.Distance(r.from, head));
    let tail = head - r.vel * back;
    tail.W = 1.0;
    let fx = GameInstance.GetFxSystem(this.m_game);
    if !IsDefined(r.fx) {
      r.fx = this.Smg()
        ? fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\trails\\_default\\w_tracer_default_npc.effect"), CMUMinotaur.At(tail, r.vel), true)
        : fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\trails\\power\\w_trail_power_hmg.effect"), CMUMinotaur.At(tail, r.vel), true);
    }
    if IsDefined(r.fx) {
      r.fx.UpdateTransform(CMUMinotaur.At(tail, r.vel));
      let wp: WorldPosition;
      WorldPosition.SetVector4(wp, head);
      r.fx.UpdateTargetPosition(wp);
    }
    if u < 1.0 {
      return false;
    }
    let end = r.to;
    let dir = r.vel;
    if r.struck {

      this.m_lmgImpact = !this.m_lmgImpact;
      if this.m_lmgImpact && !this.Smg() {
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\firearms\\special\\militech_hmg\\w_special_hmg_explosive_bullet.effect"), CMUMinotaur.At(end, -dir), true);
      } else {
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\impacts\\default\\imp_default_norm.effect"), CMUMinotaur.At(end, -dir), true);
      }
    }
    let target = r.hit;
    let drone = this.m_drone;
    if IsDefined(target) && (!IsDefined(drone) || target.GetEntityID() != drone.GetEntityID()) {

      let pools = GameInstance.GetStatPoolsSystem(this.m_game);
      let tid = Cast<StatsObjectID>(target.GetEntityID());
      let before = pools.GetStatPoolValue(tid, gamedataStatPoolType.Health, false);
      let dmg = this.RoundDamage(target);

      CMUDrone.RoundHit(this.m_game, target, drone, end, dir, dmg);

      let kill = before > 0.0 && dmg >= before - 0.01;

      let hitPuppet = target as ScriptedPuppet;
      if IsDefined(hitPuppet) && IsDefined(drone) && !kill {
        CMCCalm.DrawFire(drone, hitPuppet);
      }

      if kill {
        for k in this.m_killed {
          if Equals(k, target.GetEntityID()) {
            kill = false;
          }
        }
        if kill {
          ArrayPush(this.m_killed, target.GetEntityID());
          if ArraySize(this.m_killed) > 48 {
            ArrayErase(this.m_killed, 0);
          }
        }
      }
      if IsDefined(s) {
        s.RoundHit(kill);
      }
      if kill {
      }
      this.m_lmgHits += 1;
      this.m_bdaHits += 1;
      this.m_lmgLast = NameToString(target.GetClassName());
    }
    return true;
  }

  public static func RoundHit(game: GameInstance, target: wref<GameObject>, drone: wref<NPCPuppet>, at: Vector4, dir: Vector4, dmg: Float) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(target) || !IsDefined(player) {
      return;
    }
    let ctx: AttackInitContext;
    ctx.record = TweakDBInterface.GetAttackRecord(CMUDrone.FirstAttack(["Attacks.Bullet_GameEffect", "Attacks.PhysicalBullet"]));
    let src: ref<GameObject> = player;
    if IsDefined(drone) {
      src = drone;
    }

    ctx.instigator = src;
    ctx.source = src;
    let attack = IAttack.Create(ctx);
    let hit = new gameHitEvent();
    hit.attackData = new AttackData();
    hit.target = target;
    hit.hitPosition = at;
    hit.hitDirection = dir;
    hit.attackData.SetInstigator(src);
    hit.attackData.SetSource(src);
    hit.attackData.SetAttackDefinition(attack);
    hit.attackData.SetAttackPosition(at - dir * 2.0);
    target.m_cmRoundDmg += dmg;
    GameInstance.GetDamageSystem(game).QueueHitEvent(hit, target);
  }

  private func RoundDamage(obj: ref<GameObject>) -> Float {
    let max = GameInstance.GetStatPoolsSystem(this.m_game).GetStatPoolMaxPointValue(Cast<StatsObjectID>(obj.GetEntityID()), gamedataStatPoolType.Health);
    if this.Smg() {
      return ClampF(max * this.SMG_SHARE, this.SMG_DAMAGE, this.SMG_CAP);
    }
    return ClampF(max * this.LMG_SHARE, this.LMG_DAMAGE, this.LMG_CAP);
  }

  private func ShotRay(a: Vector4, b: Vector4, out hit: TraceResult) -> Bool {
    let best = -1.0;
    let w: TraceResult;
    if CMGround.World(this.m_game, a, b, w) {
      hit = w;
      best = Vector4.Distance(a, Cast<Vector4>(w.position));
    }
    let from = a;
    let dir = Vector4.Normalize(b - a);
    let i = 0;
    while i < 10 {
      let m: TraceResult;
      if !CMGround.Movers(this.m_game, from, b, m) {
        break;
      }
      let p = Cast<Vector4>(m.position);
      if !this.IsSelf(m) {
        let d = Vector4.Distance(a, p);
        if best < 0.0 || d < best {
          hit = m;
          best = d;
        }
        break;
      }
      this.m_shotSelf += 1;
      from = MaxF(Vector4.Dot(p - a, dir), Vector4.Dot(from - a, dir)) > 0.0 ? a + dir * (MaxF(Vector4.Dot(p - a, dir), Vector4.Dot(from - a, dir)) + 0.5) : a + dir * 0.5;
      from.W = 1.0;
      i += 1;
    }
    return best >= 0.0;
  }

  private let m_slotComp: wref<SlotComponent>;
  private func SlotPos(name: CName, fallback: Vector4) -> Vector4 {
    let drone = this.m_drone;
    if IsDefined(this.m_slotComp) {
      let wt0: WorldTransform;
      if this.m_slotComp.GetSlotTransform(name, wt0) {
        let p0 = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(wt0));
        if Vector4.Distance(p0, this.m_flight.pos) < 6.0 {
          p0.W = 1.0;
          return p0;
        }
      }
    }
    if IsDefined(drone) {
      for c in drone.GetComponents() {
        let sc = c as SlotComponent;
        let wt: WorldTransform;
        if IsDefined(sc) && sc.GetSlotTransform(name, wt) {
          let p = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(wt));
          if Vector4.Distance(p, this.m_flight.pos) < 6.0 {
            p.W = 1.0;
            this.m_slotComp = sc;
            return p;
          }
        }
      }
    }
    return fallback;
  }

  private func Muzzle(side: Float) -> Vector4 {
    let fl = this.m_flight;
    let at = new Vector4(side, 1.45, -0.45, 0.0);
    if Equals(this.m_kind, "griffin") {
      at = new Vector4(side, 0.72, -0.05, 0.0);
    } else {
      if Equals(this.m_kind, "wyvern") {
        at = new Vector4(side, 0.46, 0.04, 0.0);
      }
    }
    let p = fl.pos + CMFlight.QRot(fl.q, at - this.m_c);
    p.W = 1.0;
    return p;
  }

  private func LmgMuzzle(left: Bool) -> Vector4 {
    if Equals(this.m_kind, "griffin") {
      return this.Muzzle(left ? -0.46 : 0.46);
    }
    if Equals(this.m_kind, "wyvern") {
      return this.Muzzle(left ? -0.06 : 0.06);
    }
    return this.SlotPos(left ? n"front_weapon_l_barrel" : n"front_weapon_r_barrel", this.Muzzle(left ? -0.12 : 0.12));
  }

  private func Blast(at: Vector4, rec: TweakDBID, radius: Float, damage: Float) -> Void {
    CMUDrone.AreaAttack(this.m_game, at, rec, radius, damage, this.m_drone);
  }

  public static func AreaAttack(game: GameInstance, at: Vector4, rec: TweakDBID, radius: Float, damage: Float, blame: wref<NPCPuppet>) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let record = TweakDBInterface.GetAttackRecord(rec) as Attack_GameEffect_Record;
    if !IsDefined(record) {
      record = TweakDBInterface.GetAttackRecord(t"Attacks.FragGrenade") as Attack_GameEffect_Record;
    }
    if !IsDefined(record) {
      return;
    }

    let owner: ref<GameObject> = player;
    if IsDefined(blame) {
      owner = blame;
    }
    let ctx: AttackInitContext;
    ctx.record = record;
    ctx.instigator = owner;
    ctx.source = owner;
    let attack = IAttack.Create(ctx) as Attack_GameEffect;
    if !IsDefined(attack) {
      return;
    }
    attack.AddStatModifier(RPGManager.CreateStatModifier(gamedataStatType.PhysicalDamage, gameStatModifierType.Additive, damage));
    let statMods: array<ref<gameStatModifierData>>;
    attack.GetStatModList(statMods);
    let flags: array<SHitFlag>;
    let effect = attack.PrepareAttack(owner);
    EffectData.SetFloat(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.radius, radius);
    EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.position, at);
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attack, ToVariant(attack));
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attackStatModList, ToVariant(statMods));
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.flags, ToVariant(flags));
    if IsDefined(blame) {
      CMCHits.Blame(blame, 0.6);
    }
    attack.StartAttack();
  }

  public static func FirstAttack(names: array<String>) -> TweakDBID {
    for n in names {
      let id = TDBID.Create(n);
      if IsDefined(TweakDBInterface.GetAttackRecord(id)) {
        return id;
      }
    }
    return t"Attacks.FragGrenade";
  }

  private let m_payload: Int32;
  private let m_detonated: Bool;

  public static func PayloadRadius(i: Int32) -> Float {
    switch i {
      case 1: return 5.0;
      case 2: return 9.0;
      case 3: return 6.0;
      case 4: return 7.0;
    }
    return 0.0;
  }

  private let m_aggroAt: Float;
  private let AGGRO_COMBAT: Float = 80.0;
  private let NOTICE_MIN: Float = 10.0;
  private let NOTICE_MAX: Float = 60.0;

  private let m_aggroIdx: Int32;
  private let m_aggroNotice: Float;
  private func Aggro(t: ref<CMDroneTrack>, now: Float) -> Void {
    if !IsDefined(this.m_drone) || !IsDefined(this.m_flight) {
      return;
    }
    if now >= this.m_aggroAt {
      this.m_aggroAt = now + 1.0;
      this.m_aggroIdx = 0;
      let fl = this.m_flight;
      let sig = ClampF(0.1 + fl.Spool() * 0.4 + Vector4.Length(fl.vel) / 25.0 * 0.5 + this.m_heat * 0.6, 0.0, 1.0);
      this.m_aggroNotice = this.NOTICE_MIN + (this.NOTICE_MAX - this.NOTICE_MIN) * sig;
    }
    let done = 0;
    while this.m_aggroIdx < ArraySize(t.contacts) && done < 3 {
      let c = t.contacts[this.m_aggroIdx];
      this.m_aggroIdx += 1;
      let npc = c.ent as ScriptedPuppet;

      if IsDefined(npc) && c.dist <= this.AGGRO_COMBAT && ((c.kind == 2 && (c.dist <= this.m_aggroNotice || c.combat))
        || Equals(GameObject.GetAttitudeBetween(npc, this.m_drone), EAIAttitude.AIA_Hostile)) {
        CMCCalm.DrawFire(this.m_drone, npc);
        done += 1;
      }
    }
  }

  private let m_autoAggro: array<wref<NPCPuppet>>;
  private func AutoAggro(drone: ref<NPCPuppet>, now: Float) -> Void {
    if !IsDefined(drone) || !IsDefined(this.m_flight) {
      return;
    }
    let k = 0;
    while ArraySize(this.m_autoAggro) > 0 && k < 3 {
      let e = ArrayPop(this.m_autoAggro);
      if IsDefined(e) {
        CMCCalm.DrawFire(drone, e);
      }
      k += 1;
    }
    if now < this.m_aggroAt {
      return;
    }
    this.m_aggroAt = now + 1.0;
    let pl = GetPlayer(this.m_game);
    if !IsDefined(pl) {
      return;
    }
    let pos = this.m_flight.pos;
    let q: TargetSearchQuery;
    q.testedSet = TargetingSet.Complete;
    q.searchFilter = TSF_All(TSFMV.Obj_Puppet | TSFMV.St_AliveAndActive);
    q.maxDistance = MinF(400.0, this.AGGRO_COMBAT + Vector4.Distance(pl.GetWorldPosition(), pos));
    q.filterObjectByDistance = true;
    q.includeSecondaryTargets = false;
    q.ignoreInstigator = true;
    let parts: array<TS_TargetPartInfo>;
    GameInstance.GetTargetingSystem(this.m_game).GetTargetParts(pl, q, parts);
    let n = 0;
    let rays = 0;
    let tagged = 0;
    ArrayClear(this.m_autoAggro);
    for p in parts {
      let comp = TS_TargetPartInfo.GetComponent(p);
      let npc: ref<NPCPuppet>;
      if IsDefined(comp) {
        npc = comp.GetEntity() as NPCPuppet;
      }

      if Equals(this.m_kind, "wyvern") && rays < 3 && IsDefined(npc) && npc.GetEntityID() != drone.GetEntityID()
        && Vector4.Distance(npc.GetWorldPosition(), pos) <= this.WYVERN_TAG && !npc.IsTaggedinFocusMode()
        && Equals(GameObject.GetAttitudeBetween(npc, pl), EAIAttitude.AIA_Hostile) {
        rays += 1;
        let hit: TraceResult;
        if !CMGround.Down(this.m_game, pos - new Vector4(0.0, 0.0, 0.8, 0.0), npc.GetWorldPosition() + new Vector4(0.0, 0.0, 1.2, 0.0), hit) {
          GameObject.TagObject(npc);
          tagged += 1;
        }
      }
      if IsDefined(npc) && npc.GetEntityID() != drone.GetEntityID() && Vector4.Distance(npc.GetWorldPosition(), pos) <= this.AGGRO_COMBAT
        && Equals(npc.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat) {
        ArrayPush(this.m_autoAggro, npc);
        n += 1;
      }
    }
    if tagged > 0 {
    }
    if n > 0 && now >= this.m_aggroLogAt {
      this.m_aggroLogAt = now + 5.0;
    }
  }
  private let m_aggroLogAt: Float;
  private let WYVERN_TAG: Float = 45.0;

  private func BombusTrack(s: ref<CMCSession>, t: ref<CMDroneTrack>) -> Void {
    let fl = this.m_flight;
    t.armed = this.m_payload > 0 && !this.m_detonated;
    t.blastR = CMUDrone.PayloadRadius(this.m_payload);
    ArrayClear(t.motors);
    for m in fl.spool {
      ArrayPush(t.motors, m);
    }
    ArrayClear(t.ring);
    t.ringOk = false;
    t.tti = -1.0;
    if !t.aimOk || t.blastR <= 0.0 {
      return;
    }
    let to = t.aim - fl.pos;
    let dist = Vector4.Length(to);
    if dist > 0.5 {
      let closing = Vector4.Dot(fl.vel, to * (1.0 / dist));
      if closing > 1.5 && dist < 250.0 {
        t.tti = dist / closing;
      }
    }
    this.ProjectRing(s, t, t.aim, t.blastR);
  }

  private func ProjectRing(s: ref<CMCSession>, t: ref<CMDroneTrack>, at: Vector4, r: Float) -> Void {
    ArrayClear(t.ring);
    let n = 0;
    let shown = 0;
    while n < 32 {
      let a = Deg2Rad(Cast<Float>(n) * 11.25);
      let p = new Vector4(at.X + CosF(a) * r, at.Y + SinF(a) * r, at.Z + 0.1, 1.0);
      let o = this.Screen(s, p);
      if AbsF(o.X) < 4000.0 && AbsF(o.Y) < 3000.0 {
        shown += 1;
      }
      ArrayPush(t.ring, o);
      n += 1;
    }
    t.ringOk = shown == 32;
  }

  private func OctantTrack(s: ref<CMCSession>, t: ref<CMDroneTrack>) -> Void {
    let mortar = ArraySize(this.m_partHp) >= CMUDrone.OctantParts() && this.m_partHp[8] > 0.0;
    t.ringOk = false;
    t.blastR = 0.0;
    t.tof = this.m_tof;
    if this.m_wpn == 0 && mortar && this.m_impactOk {

      t.blastR = 3.0 + CMUDrone.Flat(this.m_flight.pos, this.m_impactAt) * 0.012;
      this.ProjectRing(s, t, this.m_impactAt, t.blastR);
    }
    ArrayClear(t.foot);
    t.footOk = false;
    let e: EulerAngles;
    e.Yaw = s.rig.yaw;
    e.Pitch = s.rig.pitch;
    let q = EulerAngles.ToQuat(e);
    let ty = TanF(Deg2Rad(MaxF(1.0, s.rig.fov) * 0.5));
    let tx = ty * 1920.0 / 1080.0;
    let gz = t.aimOk ? t.aim.Z : this.m_flight.pos.Z - MaxF(0.0, this.m_ground);
    let cam = s.rig.pos;
    for c in [new Vector2(-1.0, 1.0), new Vector2(1.0, 1.0), new Vector2(1.0, -1.0), new Vector2(-1.0, -1.0)] {
      let d = CMFlight.QRot(q, new Vector4(c.X * tx, 1.0, c.Y * ty, 0.0));
      let dist = 160.0;
      if d.Z < -0.01 {
        dist = MinF(160.0, (gz - cam.Z) / d.Z);
      }
      let p = cam + Vector4.Normalize(d) * (dist * Vector4.Length(d));
      p.W = 1.0;
      ArrayPush(t.foot, p);
    }
    t.footOk = true;
  }

  public static func PayloadName(i: Int32) -> String {
    switch i {
      case 1: return CMText.DrnPayExplosive();
      case 2: return CMText.DrnPayHighExplosive();
      case 3: return CMText.DrnPayToxicGas();
      case 4: return CMText.DrnPayShock();
    }
    return CMText.DrnPayNone();
  }

  private func Detonate(released: Bool) -> Void {
    if this.m_payload <= 0 || this.m_detonated {
      return;
    }
    this.m_detonated = true;
    let drone = this.m_drone;
    let at = IsDefined(this.m_flight) ? this.m_flight.pos : (IsDefined(drone) ? drone.GetWorldPosition() : new Vector4(0.0, 0.0, 0.0, 1.0));
    at.W = 1.0;
    let up = new Vector4(0.0, 0.0, 1.0, 0.0);
    let fx = GameInstance.GetFxSystem(this.m_game);

    let mult = Cast<Float>(CMPilotSystem.Get(this.m_game).PayloadDmgPct()) / 100.0;
    switch this.m_payload {
      case 1:
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\frag_grenade\\w_explosives_001__frag_grenade_01.effect"), CMUMinotaur.At(at, up), true);
        CMUDrone.AreaAttack(this.m_game, at, t"Attacks.CM_BombusFrag", 5.0, 350.0 * mult, drone);
        break;
      case 2:
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\ozob_grenade\\w_ozob_grenade.effect"), CMUMinotaur.At(at, up), true);
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\w_explosion_medium.effect"), CMUMinotaur.At(at, up), true);
        CMUDrone.AreaAttack(this.m_game, at, t"Attacks.CM_BombusHE", 9.0, 900.0 * mult, drone);
        break;
      case 3:
        let gas = new CMGasCb();
        gas.game = this.m_game;
        gas.at = at;
        gas.rec = CMUDrone.FirstAttack(["Attacks.BiohazardGrenade", "Attacks.ChemicalGrenade", "Attacks.PoisonGrenade"]);
        gas.left = 8;
        gas.dmg = 25.0 * mult;
        gas.blame = drone;
        gas.Call();
        break;
      default:
        let rec = CMUDrone.FirstAttack(["Attacks.EMPGrenade", "Attacks.EMPExplosion", "Attacks.ElectricGrenade"]);
        fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\emp_grenade\\w_explosives_001_emp_grenade_01.effect"), CMUMinotaur.At(at, up), true);
        CMUDrone.AreaAttack(this.m_game, at, rec, 7.0, 0.0, drone);
        CMUDrone.AreaAttack(this.m_game, at, t"Attacks.CM_BombusShock", 7.0, 200.0 * mult, drone);
        break;
    }
    if released && IsDefined(drone) && ScriptedPuppet.IsAlive(drone) {
      GameInstance.GetStatPoolsSystem(this.m_game).RequestChangingStatPoolValue(Cast<StatsObjectID>(drone.GetEntityID()), gamedataStatPoolType.Health, -100.0, null, false, true);
    }
  }

  private let m_proxyId: EntityID;
  private let m_proxySpawned: Bool;
  private let m_proxyLive: Bool;
  private let m_proxyAt: Float;
  private let m_proxyLiveAt: Float;
  private let m_proxyBody: ref<PhysicalBodyInterface>;
  private let m_physOffColliders: array<wref<IComponent>>;
  private let m_physOffMeshes: array<wref<IComponent>>;
  private let m_physKeptColliders: array<wref<IComponent>>;
  private let m_physVel: Vector4;
  private let m_physLogAt: Float;
  private let m_physKnock: Float;
  private let m_physLastNow: Float;
  private let m_physResumeUntil: Float;
  private let m_physSpin: Vector4;
  private let m_physSkinned: array<wref<IComponent>>;
  private let m_skinnedGot: array<Bool>;
  private let m_skinWaitFrom: Float;
  private let m_podBodies: array<ref<PhysicalBodyInterface>>;

  private func StartPhys(drone: ref<NPCPuppet>, now: Float) -> Void {
    this.PhysCollisions(drone, false);

    ArrayClear(this.m_podBodies);
    ArrayClear(this.m_meshWasOn);
    for c in this.m_physOffMeshes {
      ArrayPush(this.m_meshWasOn, IsDefined(c) && c.IsEnabled());
      let pm = c as PhysicalMeshComponent;
      if IsDefined(pm) {
        let b = pm.CreatePhysicalBodyInterface();
        if IsDefined(b) {
          ArrayPush(this.m_podBodies, b);
        }
      }
    }

    let kept = 0;

    let still: array<wref<IComponent>>;
    for c in this.m_physKeptColliders {
      let cc = c as ColliderComponent;
      let b: ref<PhysicalBodyInterface>;
      if IsDefined(cc) {
        b = cc.CreatePhysicalBodyInterface();
      }
      if IsDefined(b) {
        ArrayPush(this.m_podBodies, b);
        ArrayPush(still, c);
        kept += 1;
      } else {
        if IsDefined(c) {
          c.Toggle(false);
          ArrayPush(this.m_physOffColliders, c);
        }
      }
    }
    this.m_physKeptColliders = still;

    ArrayClear(this.m_skinnedGot);
    for c in this.m_physSkinned {
      ArrayPush(this.m_skinnedGot, false);
    }
    this.m_skinWaitFrom = now;
    let skinned = this.TakeSkinned();
    if ArraySize(this.m_physOffMeshes) + ArraySize(this.m_physSkinned) > 0 {
    }

    this.PodsOff();
    this.m_podWaitFrom = now;
    this.m_podsReadyAt = 0.0;
    this.m_proxySpawned = false;
    this.m_proxyLive = false;
    this.m_proxyAt = now;
    this.m_physKnock = 0.0;
    this.m_physLastNow = 0.0;
    this.m_physResumeUntil = 0.0;
  }

  private func SpawnProxy(now: Float) -> Void {
    let spec = new DynamicEntitySpec();
    switch this.m_kind {
      case "octant":
        spec.templatePath = r"mnc\\physics\\proxy_octant.ent";
        break;
      case "bombus":
        spec.templatePath = r"mnc\\physics\\proxy_bombus.ent";
        break;
      case "griffin":
        spec.templatePath = r"mnc\\physics\\proxy_griffin.ent";
        break;
      default:
        spec.templatePath = r"mnc\\physics\\proxy_wyvern.ent";
    }
    spec.position = this.m_flight.pos;
    let face: EulerAngles;
    face.Yaw = this.m_flight.yaw;
    spec.orientation = EulerAngles.ToQuat(face);
    spec.persistState = false;
    spec.persistSpawn = false;
    spec.alwaysSpawned = true;
    spec.tags = [n"MNCPhysDrone"];
    this.m_proxyId = GameInstance.GetDynamicEntitySystem().CreateEntity(spec);
    this.m_proxySpawned = true;
    this.m_proxyLive = false;
    this.m_proxyAt = now;
    this.m_physKnock = 0.0;
    this.m_physLastNow = 0.0;
    this.m_physResumeUntil = 0.0;
  }

  private let m_partsDumps: Int32;
  private func PartsDump(why: String) -> Void {
    let drone = this.m_drone;
    if !IsDefined(drone) || !IsDefined(this.m_flight) || this.m_partsDumps >= 6 {
      return;
    }
    this.m_partsDumps += 1;
    let s = "drone parts (" + why + "):";
    for c in drone.GetComponents() {
      let kind = "";
      if c.IsA(n"entColliderComponent") || c.IsA(n"entSimpleColliderComponent") {
        kind = "collider";
      } else {
        if c.IsA(n"entPhysicalMeshComponent") {
          kind = "physmesh";
        } else {
          if c.IsA(n"entPhysicalSkinnedMeshComponent") {
            kind = "physskin";
          }
        }
      }
      if StrLen(kind) > 0 {
        let at = "";
        let pc = c as IPlacedComponent;
        if IsDefined(pc) {
          at = " " + FloatToStringPrec(Vector4.Distance(WorldPosition.ToVector4(WorldTransform.GetWorldPosition(pc.worldTransform)), this.m_flight.pos), 2) + " m";
        }
        s += " " + kind + " " + NameToString(c.GetName()) + " " + (c.IsEnabled() ? "ON" : "off") + at + (ArrayContains(this.m_physKeptColliders, c) ? " (kept, push-nothing)" : "") + ";";
      }
    }
    s += " bodies told to push nothing: " + IntToString(ArraySize(this.m_podBodies));
  }

  private func TryProxy(now: Float) -> Void {
    this.PodsOff();
    if !this.m_proxySpawned {
      if now - this.m_proxyAt >= 0.25 {

        let had = this.SkinnedCount();
        let got = this.TakeSkinned();
        if got > had {
          this.m_proxyAt = now;
          return;
        }
        if got < ArraySize(this.m_physSkinned) && now - this.m_skinWaitFrom < 4.0 {
          return;
        }
        if got < ArraySize(this.m_physSkinned) {
        }

        if ArraySize(this.m_physOffMeshes) > 0 {
          let asleep = 0;
          for c in this.m_physOffMeshes {
            if IsDefined(c) && !c.IsEnabled() {
              asleep += 1;
            }
          }
          if asleep > 0 {
            this.m_podsReadyAt = 0.0;
            if now - this.m_podWaitFrom < 1.5 {
              return;
            }
          } else {
            if this.m_podsReadyAt <= 0.0 {
              this.m_podsReadyAt = now;
            }
            if now - this.m_podsReadyAt < 0.25 {
              return;
            }
          }
        }
        this.SpawnProxy(now);
      }
      return;
    }
    let e = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_proxyId);
    if !IsDefined(e) || Vector4.Length(e.GetWorldPosition()) < 1.0 {
      if now - this.m_proxyAt > 10.0 {

        GameInstance.GetDynamicEntitySystem().DeleteEntity(this.m_proxyId);
        this.m_proxySpawned = false;
        this.m_proxyAt = now;
      }
      return;
    }
    let body = this.PhysBody(e);
    if !IsDefined(body) || !body.IsSimulated() {
      return;
    }
    let fl = this.m_flight;
    this.m_proxyLive = true;
    this.m_proxyLiveAt = now;
    this.m_physVel = fl.vel;
    CMPhysPlugin.SetVelocity(body, fl.vel);
    CMPhysPlugin.SetSpin(body, CMFlight.QRot(fl.q, fl.w));
    this.m_partsDumps = 0;
    this.PartsDump("live");

    let link = CMLinkSystem.Get(this.m_game);
    if IsDefined(link) {
      if EntityID.IsDefined(link.lastProxy) && link.lastProxy != this.m_proxyId {
        let old = GameInstance.GetDynamicEntitySystem().GetEntity(link.lastProxy);
      }
      link.lastProxy = this.m_proxyId;
    }
  }

  private func TakeSkinned() -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_physSkinned) && i < ArraySize(this.m_skinnedGot) {
      if !this.m_skinnedGot[i] {
        let c = this.m_physSkinned[i];
        let sb = CMPhysBodies.Of(c);
        if !IsDefined(sb) {
          sb = CMUDrone.SkinnedBody(c);
        }
        if IsDefined(sb) {
          ArrayPush(this.m_podBodies, sb);
          this.m_skinnedGot[i] = true;
        }
      }
      i += 1;
    }
    return this.SkinnedCount();
  }

  private func SkinnedCount() -> Int32 {
    let n = 0;
    for g in this.m_skinnedGot {
      if g {
        n += 1;
      }
    }
    return n;
  }

  private func PhysBody(e: ref<Entity>) -> ref<PhysicalBodyInterface> {
    if IsDefined(this.m_proxyBody) && this.m_proxyBody.IsSimulated() {
      return this.m_proxyBody;
    }
    let c = e.FindComponentByName(n"proxy_body") as ColliderComponent;
    if IsDefined(c) {
      this.m_proxyBody = c.CreatePhysicalBodyInterface();
    }
    return this.m_proxyBody;
  }

  private let m_meshWasOn: array<Bool>;
  private let m_podWaitFrom: Float;
  private let m_podsReadyAt: Float;
  private func PodsWatch() -> Void {
    let i = 0;
    while i < ArraySize(this.m_physOffMeshes) && i < ArraySize(this.m_meshWasOn) {
      let c = this.m_physOffMeshes[i];
      if IsDefined(c) {
        let on = c.IsEnabled();
        if on && !this.m_meshWasOn[i] {
          let off = false;
          let pm = c as PhysicalMeshComponent;
          let b: ref<PhysicalBodyInterface>;
          if IsDefined(pm) {
            b = pm.CreatePhysicalBodyInterface();
          }
          if IsDefined(b) {
            ArrayPush(this.m_podBodies, b);
          }
        }
        this.m_meshWasOn[i] = on;
      }
      i += 1;
    }
  }

  private func PodsOff() -> Int32 {
    this.PodsWatch();
    let n = 0;
    for b in this.m_podBodies {
      if IsDefined(b) && CMPhysColl.SetCollision(b, false) {
        n += 1;
      }
    }
    return n;
  }

  private func PhysFly(s: ref<CMCSession>, drone: ref<NPCPuppet>, f: Float, side: Float, climb: Float, heading: Float, dt: Float, now: Float) -> Void {
    let fl = this.m_flight;
    this.PodsOff();
    let e = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_proxyId);
    let body = IsDefined(e) ? this.PhysBody(e) : null;
    if !IsDefined(body) {

      if IsDefined(e) {
        GameInstance.GetDynamicEntitySystem().DeleteEntity(this.m_proxyId);
      }
      this.m_proxyLive = false;
      this.m_proxySpawned = false;
      this.m_proxyBody = null;
      this.m_proxyAt = now;
      return;
    }

    fl.pos = e.GetWorldPosition();
    fl.pos.W = 1.0;
    fl.q = e.GetWorldOrientation();
    let v = CMPhysStep.Velocity(body);
    let spin = CMPhysStep.Spin(body);

    if this.m_physLastNow > 0.0 && now - this.m_physLastNow > 0.33 {
      this.m_physResumeUntil = now + 0.5;
    }
    this.m_physLastNow = now;
    if now < this.m_physResumeUntil && Vector4.Length(v - this.m_physVel) > 2.0 {
      CMPhysPlugin.SetVelocity(body, this.m_physVel);
      CMPhysPlugin.SetSpin(body, this.m_physSpin);
      v = this.m_physVel;
      spin = this.m_physSpin;
    }
    this.m_physSpin = spin;
    fl.vel = v;
    fl.w = CMFlight.QInvRot(fl.q, spin);
    fl.Sync();

    let dv = Vector4.Length(v - this.m_physVel);
    this.m_physVel = v;
    this.m_physKnock = MaxF(this.m_physKnock, dv);

    if dv > this.ImpactLimit() && now >= this.m_physResumeUntil {
      if now - this.m_proxyLiveAt >= 0.5 {
        this.Impact(drone, dv);
      } else {
        this.PartsDump("knock " + FloatToStringPrec(dv, 1) + " m/s");

        if dv > 4.0 && ArraySize(this.m_physKeptColliders) > 0 {
          for c in this.m_physKeptColliders {
            if IsDefined(c) {
              c.Toggle(false);
              ArrayPush(this.m_physOffColliders, c);
            }
          }
          ArrayClear(this.m_physKeptColliders);
        }
      }
    }
    this.PhysGround();
    this.CrippledGround(drone, dt);

    fl.Step(dt, f, side, climb, heading);

    let t = fl.outTorque;
    let wb = fl.w + new Vector4(t.X / fl.Ix() * dt, t.Y / fl.Ix() * dt, t.Z / fl.Iz() * dt, 0.0);
    CMPhysPlugin.SetSpin(body, CMFlight.QRot(fl.q, wb));
    CMPhysStep.SetForce(body, fl.outForce, new Vector4(0.0, 0.0, 0.0, 0.0));

    CMPhysWind.IgnoreNear(7310 + CMUDrone.KindIndex(this.m_kind), fl.pos, fl.p.span + 1.0);
    if now >= this.m_physLogAt {
      this.m_physLogAt = now + 1.0;
      this.m_physKnock = 0.0;
    }
  }

  private func PhysGround() -> Void {
    let fl = this.m_flight;
    let hit: TraceResult;
    let top = fl.pos.Z + 1.0;
    if this.Ray(new Vector4(fl.pos.X, fl.pos.Y, top, 1.0), fl.pos - new Vector4(0.0, 0.0, 40.0, 0.0), hit) {
      this.m_ground = fl.pos.Z - hit.position.Z;
      this.m_groundFrom = "body ground ray";
      fl.grounded = this.m_ground < fl.p.bottom + 0.08 && Vector4.Length(fl.vel) < 2.0;
    } else {
      this.m_ground = -1.0;
      fl.grounded = false;
    }
    this.m_show = 90.0;
  }

  private func PhysCollisions(drone: ref<NPCPuppet>, on: Bool) -> Void {
    if !on {
      ArrayClear(this.m_physOffColliders);
      ArrayClear(this.m_physOffMeshes);
      ArrayClear(this.m_physSkinned);
      ArrayClear(this.m_physKeptColliders);
      for c in drone.GetComponents() {

        if c.IsA(n"entColliderComponent") || c.IsA(n"entSimpleColliderComponent") {
          if c.IsEnabled() {
            ArrayPush(this.m_physKeptColliders, c);
          }
        } else {

          if c.IsA(n"entPhysicalMeshComponent") {
            ArrayPush(this.m_physOffMeshes, c);
          } else {
            if c.IsA(n"entPhysicalSkinnedMeshComponent") {
              ArrayPush(this.m_physSkinned, c);
            }
          }
        }
      }
      return;
    }
    for c in this.m_physOffColliders {
      if IsDefined(c) {
        c.Toggle(true);
      }
    }
    for c in this.m_physOffMeshes {
      if IsDefined(c) {
        CMUDrone.MeshCollision(c, true);
      }
    }
    ArrayClear(this.m_physOffColliders);
    ArrayClear(this.m_physOffMeshes);
  }

  public static func SkinnedBody(c: ref<IComponent>) -> ref<PhysicalBodyInterface> {
    let cls = Reflection.GetClass(n"entPhysicalSkinnedMeshComponent");
    let fn = IsDefined(cls) ? cls.GetFunction(n"CreatePhysicalBodyInterface") : null;
    if !IsDefined(fn) {
      return null;
    }
    let ok = false;
    let args: array<Variant>;
    let params = fn.GetParameters();
    if ArraySize(params) > 0 {
      if Equals(params[0].GetType().GetName(), n"Uint32") {
        ArrayPush(args, ToVariant(0u));
      } else {
        ArrayPush(args, ToVariant(0));
      }
    }
    let v = fn.Call(c, args, ok);
    if !ok || !IsDefined(v) {
      return null;
    }
    return FromVariant<ref<PhysicalBodyInterface>>(v);
  }

  public static func MeshCollision(c: ref<IComponent>, on: Bool) -> Bool {
    let cls = Reflection.GetClass(n"entPhysicalMeshComponent");
    let fn = IsDefined(cls) ? cls.GetFunction(n"ToggleCollision") : null;
    if !IsDefined(fn) {
      return false;
    }
    let ok = false;
    fn.Call(c, [ToVariant(on)], ok);
    return ok;
  }

  public func OwnCollisionsBack(drone: ref<NPCPuppet>) -> Void {

    if IsDefined(drone) && !this.m_proxySpawned {
      this.PhysCollisions(drone, true);
    }
  }

  private func StopPhys(drone: ref<NPCPuppet>) -> Void {

    if !this.m_proxySpawned && ArraySize(this.m_podBodies) == 0 && ArraySize(this.m_physOffColliders) == 0 && ArraySize(this.m_physOffMeshes) == 0 {
      return;
    }
    if this.m_proxySpawned {
      let e = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_proxyId);
      if IsDefined(e) {
        let body = this.PhysBody(e);
        if IsDefined(body) {

          CMPhysColl.SetCollision(body, false);
          CMPhysPlugin.SetVelocity(body, new Vector4(0.0, 0.0, 0.0, 0.0));
          CMPhysPlugin.SetSpin(body, new Vector4(0.0, 0.0, 0.0, 0.0));
          CMPhysStep.SetForce(body, new Vector4(0.0, 0.0, 0.0, 0.0), new Vector4(0.0, 0.0, 0.0, 0.0));
          CMPhysStep.Release(body);
        }
      }
      GameInstance.GetDynamicEntitySystem().DeleteEntity(this.m_proxyId);
    }
    this.m_proxySpawned = false;
    this.m_proxyLive = false;
    this.m_proxyBody = null;
    for b in this.m_podBodies {
      if IsDefined(b) {
        CMPhysColl.SetCollision(b, true);
      }
    }
    ArrayClear(this.m_podBodies);

    if IsDefined(drone) {
      let cb = new CMDroneCollBackCb();
      cb.unit = this;
      cb.drone = drone;
      GameInstance.GetDelaySystem(this.m_game).DelayCallback(cb, 0.33, false);
    }
  }

  private let m_wash: ref<FxInstance>;
  private let m_washAt: Float;
  private let WASH_RENEW: Float = 4.0;

  private func WashHeight() -> Float {
    switch this.m_kind {
      case "bombus": return 1.2;
      case "octant": return 6.0;
    }
    return 3.5;
  }

  private func Downwash(now: Float) -> Void {
    let fl = this.m_flight;
    if this.m_ground < 0.0 || this.m_ground > this.WashHeight() {
      this.StopWash();
      return;
    }
    let p = new Vector4(fl.pos.X, fl.pos.Y, fl.pos.Z - this.m_ground + 0.05, 1.0);
    let up = new Vector4(0.0, 0.0, 1.0, 0.0);
    if !IsDefined(this.m_wash) || now >= this.m_washAt {
      if IsDefined(this.m_wash) {
        this.m_wash.BreakLoop();
      }
      this.m_wash = GameInstance.GetFxSystem(this.m_game).SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\vehicles\\av\\v_av_dust_kickup_no_debris.effect"), CMUMinotaur.At(p, up), true);
      this.m_washAt = now + this.WASH_RENEW;
      return;
    }
    this.m_wash.UpdateTransform(CMUMinotaur.At(p, up));
  }

  private func StopWash() -> Void {
    if IsDefined(this.m_wash) {
      this.m_wash.BreakLoop();
    }
    this.m_wash = null;
  }

  private let m_hold: Bool;
  private let m_holdPos: Vector4;
  private let m_holdYaw: Float;
  private let m_holdChase: Bool;
  private let m_holdTrim: Vector4;
  private let HOLD_NUDGE: Float = 4.0;

  public func Hold(s: ref<CMCSession>) -> Void {
    if !Equals(this.m_kind, "octant") || !IsDefined(this.m_flight) {
      return;
    }
    this.SetHold(s, !this.m_hold);
  }

  private func SetHold(s: ref<CMCSession>, on: Bool) -> Void {
    if Equals(on, this.m_hold) {
      return;
    }
    this.m_hold = on;
    if on {
      let fl = this.m_flight;
      this.m_holdPos = fl.pos + fl.vel * 0.5;
      this.m_holdPos.W = 1.0;
      this.m_holdYaw = fl.yaw;
      this.m_holdTrim = new Vector4(0.0, 0.0, 0.0, 0.0);
      this.m_holdChase = !s.SightView();
      if this.m_holdChase {
        s.SetChaseView(false);
      }
      s.rig.SetPitchLimits(-85.0, 30.0);
    } else {
      s.rig.SetPitchLimits(-35.0, 30.0);
      if this.m_holdChase {
        s.SetChaseView(true);
      }
    }
  }

  private func HoldKeys(s: ref<CMCSession>, dt: Float, out f: Float, out side: Float) -> Void {
    let fl = this.m_flight;
    let nf = (s.Key(CMCKey.W()) ? 1.0 : 0.0) - (s.Key(CMCKey.S()) ? 1.0 : 0.0);
    let ns = (s.Key(CMCKey.D()) ? 1.0 : 0.0) - (s.Key(CMCKey.A()) ? 1.0 : 0.0);
    let vf = CMPilotRig.Dir(s.rig.yaw, 0.0);
    let vr = new Vector4(vf.Y, -vf.X, 0.0, 0.0);
    let nudge = (vf * nf + vr * ns) * this.HOLD_NUDGE;
    this.m_holdPos += nudge * dt;
    this.m_holdPos.Z = fl.pos.Z;
    let err = this.m_holdPos - fl.pos;
    err.Z = 0.0;
    let want = err * 0.8;
    let n = Vector4.Length(want);
    if n > 8.0 {
      want = want * (8.0 / n);
    }
    want += nudge;

    this.m_holdTrim += err * (0.06 * dt);
    let tn = Vector4.Length(this.m_holdTrim);
    if tn > 0.6 {
      this.m_holdTrim = this.m_holdTrim * (0.6 / tn);
    }
    let k = (want - fl.vel) * 0.3 + this.m_holdTrim;
    let bf = CMPilotRig.Dir(fl.yaw, 0.0);
    let br = new Vector4(bf.Y, -bf.X, 0.0, 0.0);
    f = ClampF(k.X * bf.X + k.Y * bf.Y, -1.0, 1.0);
    side = ClampF(k.X * br.X + k.Y * br.Y, -1.0, 1.0);
  }

  public func ScreenAt(s: ref<CMCSession>, p: Vector4) -> Vector2 = this.Screen(s, p)

  private func Screen(s: ref<CMCSession>, p: Vector4) -> Vector2 {
    let tilt = this.CamTilt();
    let k = s.SightView() ? 1.0 : 0.35;
    let e: EulerAngles;
    e.Yaw = s.rig.yaw;
    e.Pitch = s.rig.pitch + tilt.X * k;
    e.Roll = s.rig.roll + tilt.Y * k;
    let d = CMFlight.QInvRot(EulerAngles.ToQuat(e), p - s.rig.pos);
    if d.Y < 0.5 {
      return Vector2(9999.0, 9999.0);
    }
    let scale = 1080.0 / TanF(Deg2Rad(s.rig.fov * 0.5));
    return Vector2(d.X / d.Y * scale, -d.Z / d.Y * scale);
  }

  private let m_partHp: array<Float>;
  private let m_partFx: array<ref<FxInstance>>;
  private let m_partFx2: array<ref<FxInstance>>;
  private let m_partLevel: array<Int32>;
  private let m_podsBreak: Bool;
  private let m_podHidden: array<wref<IComponent>>;
  private let m_podMasks: array<Uint64>;
  private let m_podLights: array<wref<IComponent>>;
  private let m_jets: array<ref<FxInstance>>;
  private let m_jetsOwn: Bool;

  public static func OctantParts() -> Int32 = 10

  private func RocketCap() -> Int32 {
    if Equals(this.m_kind, "octant") {
      return this.RocketPods() * 2;
    }
    return Equals(this.m_kind, "griffin") ? 2 : 0;
  }

  private func WpnType() -> Int32 {
    if Equals(this.m_kind, "octant") {
      return this.m_wpn;
    }
    if Equals(this.m_kind, "griffin") {
      return this.m_wpn == 1 ? 2 : 1;
    }
    return 1;
  }

  private func Armed() -> Bool = Equals(this.m_kind, "octant") || Equals(this.m_kind, "griffin") || Equals(this.m_kind, "wyvern")

  private func RocketPods() -> Int32 {
    if ArraySize(this.m_partHp) < CMUDrone.OctantParts() {
      return 2;
    }
    return (this.m_partHp[6] > 0.0 ? 1 : 0) + (this.m_partHp[7] > 0.0 ? 1 : 0);
  }

  public static func OctantPartName(i: Int32) -> String {
    switch i {
      case 1: return CMText.DrnThrFl();
      case 2: return CMText.DrnThrFr();
      case 3: return CMText.DrnThrBl();
      case 4: return CMText.DrnThrBr();
      case 5: return "LMG";
      case 6: return CMText.DrnRktL();
      case 7: return CMText.DrnRktR();
      case 8: return CMText.DrnMortar();
      case 9: return CMText.PartSensor();
    }
    return CMText.DrnHull();
  }

  public static func OctantShare(i: Int32) -> Float {
    if i == 0 { return 1.0; }
    if i <= 4 { return 0.2; }
    if i == 5 || i == 8 { return 0.15; }
    if i == 9 { return 0.1; }
    return 0.12;
  }

  private static func OctantReach(i: Int32) -> Float = i <= 4 ? 0.7 : 0.55

  public static func PartsOf(kind: String) -> Int32 {
    switch kind {
      case "octant": return CMUDrone.OctantParts();
      case "wyvern": return 7;
      case "griffin": return 3;
    }
    return 0;
  }
  private func PartCount() -> Int32 = CMUDrone.PartsOf(this.m_kind)

  public static func PartName(kind: String, i: Int32) -> String {
    if Equals(kind, "wyvern") {
      switch i {
        case 1: return CMText.DrnRotorL1();
        case 2: return CMText.DrnRotorL2();
        case 3: return CMText.DrnRotorL3();
        case 4: return CMText.DrnRotorR1();
        case 5: return CMText.DrnRotorR2();
        case 6: return CMText.DrnRotorR3();
      }
      return CMText.DrnHull();
    }
    if Equals(kind, "griffin") {
      switch i {
        case 1: return CMText.DrnPodL();
        case 2: return CMText.DrnPodR();
      }
      return CMText.DrnHull();
    }
    return CMUDrone.OctantPartName(i);
  }

  public static func PartLocal(kind: String, i: Int32) -> Vector4 {
    if Equals(kind, "wyvern") {
      switch i {
        case 1: return new Vector4(-0.14, 0.21, 0.24, 0.0);
        case 2: return new Vector4(-0.08, 0.0, 0.18, 0.0);
        case 3: return new Vector4(-0.14, -0.21, 0.24, 0.0);
        case 4: return new Vector4(0.14, 0.21, 0.23, 0.0);
        case 5: return new Vector4(0.08, 0.0, 0.19, 0.0);
        case 6: return new Vector4(0.14, -0.21, 0.24, 0.0);
      }
      return new Vector4(0.0, 0.15, 0.19, 0.0);
    }
    if Equals(kind, "griffin") {
      switch i {
        case 1: return new Vector4(-0.45, 0.15, -0.05, 0.0);
        case 2: return new Vector4(0.45, 0.15, -0.05, 0.0);
      }
      return new Vector4(0.0, -0.08, 0.02, 0.0);
    }
    return CMUDrone.OctantLocal(i);
  }

  public static func PartShare(kind: String, i: Int32) -> Float {
    if i == 0 {
      return 1.0;
    }
    if Equals(kind, "wyvern") {
      return 0.12;
    }
    if Equals(kind, "griffin") {
      return 0.35;
    }
    return CMUDrone.OctantShare(i);
  }

  private static func PartReach(kind: String, i: Int32) -> Float {
    if Equals(kind, "wyvern") {
      return 0.25;
    }
    if Equals(kind, "griffin") {
      return 0.6;
    }
    return CMUDrone.OctantReach(i);
  }

  private static func InHullBox(kind: String, p: Vector4) -> Bool {
    if Equals(kind, "wyvern") {
      return AbsF(p.X) < 0.09 && p.Y > -0.47 && p.Y < 0.49 && p.Z > -0.01 && p.Z < 0.46;
    }
    if Equals(kind, "griffin") {
      return AbsF(p.X) < 0.28 && p.Y > -0.73 && p.Y < 0.52 && p.Z > -0.47 && p.Z < 0.52;
    }
    return false;
  }

  private let m_spinDeathAt: Float;

  private func ApplyRotors() -> Void {
    let fl = this.m_flight;
    if Equals(this.m_kind, "wyvern") {

      let e: array<Float>;
      let lost = 0;
      let i = 1;
      while i <= 6 {
        let hp = this.m_partHp[i];
        ArrayPush(e, hp > 0.0 ? 0.35 + 0.65 * hp : 0.0);
        if hp <= 0.0 {
          lost += 1;
        }
        i += 1;
      }

      let boost = 1.0 + 0.35 * Cast<Float>(lost);

      fl.eff[0] = (e[0] + 0.5 * e[1]) / 1.5 * boost;
      fl.eff[1] = (e[3] + 0.5 * e[4]) / 1.5 * boost;
      fl.eff[2] = (e[2] + 0.5 * e[1]) / 1.5 * boost;
      fl.eff[3] = (e[5] + 0.5 * e[4]) / 1.5 * boost;
      fl.failing = lost >= 3 ? 2 : (lost >= 1 ? 1 : 0);
      fl.limp = lost >= 2 ? 1.0 : 0.6;
      return;
    }
    if Equals(this.m_kind, "griffin") {
      let l = this.m_partHp[1];
      let r = this.m_partHp[2];
      let el = l > 0.0 ? 0.35 + 0.65 * l : 0.0;
      let er = r > 0.0 ? 0.35 + 0.65 * r : 0.0;
      fl.eff[0] = el;
      fl.eff[2] = el;
      fl.eff[1] = er;
      fl.eff[3] = er;
      let dead = (l <= 0.0 ? 1 : 0) + (r <= 0.0 ? 1 : 0);
      fl.failing = dead >= 1 ? 2 : 0;
    }
  }

  private func SpinDeath(now: Float) -> Void {
    if !Equals(this.m_kind, "griffin") || ArraySize(this.m_partHp) < 3 || !IsDefined(this.m_drone) {
      return;
    }
    if this.m_partHp[1] > 0.0 && this.m_partHp[2] > 0.0 {
      return;
    }
    if this.m_spinDeathAt <= 0.0 {
      this.m_spinDeathAt = now + 3.0;
      return;
    }
    if now >= this.m_spinDeathAt && ScriptedPuppet.IsAlive(this.m_drone) {
      this.m_spinDeathAt = now + 9999.0;
      GameInstance.GetStatPoolsSystem(this.m_game).RequestChangingStatPoolValue(Cast<StatsObjectID>(this.m_drone.GetEntityID()), gamedataStatPoolType.Health, -100.0, null, false, true);
    }
  }

  private func ResetParts() -> Void {
    ArrayClear(this.m_partHp);
    this.StopPartFx();
    ArrayClear(this.m_podHidden);
    ArrayClear(this.m_podMasks);
    ArrayClear(this.m_podLights);
    ArrayClear(this.m_jets);
    this.m_jetsOwn = false;
    this.m_spinDeathAt = 0.0;
    let n = this.PartCount();
    if n == 0 {
      return;
    }
    let link = CMLinkSystem.Get(this.m_game);

    if link.PodsOf() == this.m_drone.GetEntityID() {
      for c in link.KeptPodHidden() {
        ArrayPush(this.m_podHidden, c);
      }
      for m in link.KeptPodMasks() {
        ArrayPush(this.m_podMasks, m);
      }
      for c in link.KeptPodLights() {
        ArrayPush(this.m_podLights, c);
      }

      if link.KeptJetsOff() {
        GameObjectEffectHelper.StartEffectEvent(this.m_drone, n"thrust_smoke");
      }
      link.ForgetPods();
      this.UnhidePods();
    }
    let kept = link.DroneParts(this.m_drone.GetEntityID(), n);
    let i = 0;
    while i < n {
      ArrayPush(this.m_partHp, kept[i]);
      ArrayPush(this.m_partLevel, 0);
      ArrayPush(this.m_partFx, null);
      ArrayPush(this.m_partFx2, null);
      i += 1;
    }
    this.ApplyParts(false);
  }

  public static func OctantLocal(i: Int32) -> Vector4 {
    switch i {
      case 1: return new Vector4(-1.22, 0.46, 0.56, 0.0);
      case 2: return new Vector4(1.22, 0.46, 0.56, 0.0);
      case 3: return new Vector4(-1.20, -0.59, 0.52, 0.0);
      case 4: return new Vector4(1.20, -0.59, 0.52, 0.0);
      case 5: return new Vector4(0.0, 1.38, 0.14, 0.0);
      case 6: return new Vector4(-1.11, 0.01, 0.56, 0.0);
      case 7: return new Vector4(1.11, 0.01, 0.56, 0.0);
      case 8: return new Vector4(0.25, -1.05, 0.45, 0.0);
      case 9: return new Vector4(0.0, 1.48, 0.05, 0.0);
    }
    return new Vector4(0.0, -0.02, 0.5, 0.0);
  }

  private func PartPos(i: Int32) -> Vector4 {
    let fl = this.m_flight;
    let p = fl.pos + CMFlight.QRot(fl.q, CMUDrone.PartLocal(this.m_kind, i) - this.m_c);
    p.W = 1.0;
    return p;
  }

  private func PartAt(p: Vector4) -> Int32 {
    let fl = this.m_flight;
    let local = CMFlight.QInvRot(fl.q, p - fl.pos) + this.m_c;
    if CMUDrone.InHullBox(this.m_kind, local) {
      return 0;
    }
    let best = 0;
    let bestD = 9999.0;
    let i = 1;
    while i < ArraySize(this.m_partHp) {
      let d = Vector4.Distance(p, this.PartPos(i));
      if d < CMUDrone.PartReach(this.m_kind, i) && d < bestD {
        best = i;
        bestD = d;
      }
      i += 1;
    }
    return best;
  }

  public func TakeHit(s: ref<CMCSession>, hit: ref<gameHitEvent>) -> Void {
    let drone = this.m_drone;
    if !IsDefined(drone) || !IsDefined(hit) || !IsDefined(this.m_flight) || ArraySize(this.m_partHp) == 0 {
      return;
    }
    if !IsDefined(hit.attackData) || hit.attackData.HasFlag(hitFlag.DealNoDamage) {
      return;
    }
    let dmg = hit.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    if dmg <= 0.0 {
      return;
    }
    let part = this.PartAt(hit.hitPosition);
    if part == 0 {
      return;
    }
    this.DamagePart(part, dmg);
  }

  private func DamagePart(part: Int32, dmg: Float) -> Void {
    let drone = this.m_drone;
    let hull = GameInstance.GetStatPoolsSystem(this.m_game).GetStatPoolMaxPointValue(Cast<StatsObjectID>(drone.GetEntityID()), gamedataStatPoolType.Health);
    let before = this.m_partHp[part];
    this.m_partHp[part] = MaxF(0.0, before - dmg / MaxF(1.0, hull * CMUDrone.PartShare(this.m_kind, part)));
    if before > 0.0 && this.m_partHp[part] <= 0.0 {
    }
    this.ApplyParts(true);
  }

  private func ApplyParts(live: Bool) -> Void {
    if ArraySize(this.m_partHp) == 0 || !IsDefined(this.m_flight) {
      return;
    }
    if !Equals(this.m_kind, "octant") {

      this.ApplyRotors();
      let q = 1;
      while q < ArraySize(this.m_partHp) {
        let hq = this.m_partHp[q];
        let lq = hq <= 0.0 ? 2 : (hq < 0.5 ? 1 : 0);
        if lq != this.m_partLevel[q] {
          this.PartLook(q, lq, live);
          this.m_partLevel[q] = lq;
        }
        q += 1;
      }
      CMLinkSystem.Get(this.m_game).SetDroneParts(this.m_drone.GetEntityID(), this.m_partHp);
      return;
    }
    if ArraySize(this.m_partHp) < CMUDrone.OctantParts() {
      return;
    }
    let fl = this.m_flight;
    let dead = 0;
    let i = 1;
    while i <= 4 {
      if this.m_partHp[i] <= 0.0 {
        dead += 1;
      }
      i += 1;
    }
    i = 1;
    while i <= 4 {
      let hp = this.m_partHp[i];

      fl.eff[i - 1] = hp > 0.0 ? 0.35 + 0.65 * hp : (dead == 1 ? 0.45 : 0.0);
      i += 1;
    }
    fl.failing = dead;

    let pods = (this.m_partHp[6] > 0.0 ? 1 : 0) + (this.m_partHp[7] > 0.0 ? 1 : 0);
    this.m_rockets = Min(this.m_rockets, pods * 2);
    let p = 1;
    while p < CMUDrone.OctantParts() {
      let hp = this.m_partHp[p];
      let level = hp <= 0.0 ? 2 : (hp < 0.5 ? 1 : 0);
      if level != this.m_partLevel[p] {
        this.PartLook(p, level, live);
        this.m_partLevel[p] = level;
      }
      p += 1;
    }
    this.Jets();
    let link = CMLinkSystem.Get(this.m_game);
    link.SetDroneParts(this.m_drone.GetEntityID(), this.m_partHp);
  }

  private func PartLook(p: Int32, level: Int32, live: Bool) -> Void {
    let fx = GameInstance.GetFxSystem(this.m_game);
    let at = CMUMinotaur.At(this.PartPos(p), new Vector4(0.0, 0.0, 1.0, 0.0));
    if IsDefined(this.m_partFx[p]) {
      this.m_partFx[p].BreakLoop();
      this.m_partFx[p] = null;
    }
    if IsDefined(this.m_partFx2[p]) {
      this.m_partFx2[p].BreakLoop();
      this.m_partFx2[p] = null;
    }

    if level == 1 {
      this.m_partFx[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\vehicles\\drone\\octant\\octant_damage_smoke.effect"), at, true);
      this.m_partFx2[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\devices\\_damage\\d_damage_sparks_small_loop.effect"), at, true);
      return;
    }
    if level == 2 {

      let octant = Equals(this.m_kind, "octant");
      let thrust = (octant && p >= 1 && p <= 4) || (Equals(this.m_kind, "griffin") && p >= 1);
      if live {
        fx.SpawnEffect(CMUMinotaur.Fx(thrust ? r"base\\fx\\vehicles\\drone\\octant\\octant_explosion_engine.effect" : r"base\\fx\\devices\\_damage\\d_damage_smoke_sparks_burst_01.effect"), at, true);
        GameObject.PlaySoundEvent(this.m_drone, n"dev_generic_impact_metal");
      }
      if !octant {

        if Equals(this.m_kind, "griffin") && p >= 1 {
          this.HideGriffinPod(p);
        }
        if Equals(this.m_kind, "wyvern") && p >= 1 {
          this.HideWyvernWing(p);
        }
        this.m_partFx[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\vehicles\\drone\\octant\\octant_damage_smoke.effect"), at, true);
        this.m_partFx2[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\environment\\sparks\\e_sparks_cable_electric_failure_medium_constant_falling.effect"), at, true);
        return;
      }
      if p >= 1 && p <= 4 && this.m_podsBreak {
        this.HidePod(p);
        this.m_partFx[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\vehicles\\drone\\octant\\octant_damage_smoke.effect"), at, true);
        this.m_partFx2[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\environment\\sparks\\e_sparks_cable_electric_failure_medium_constant_falling.effect"), at, true);
        return;
      }
      if (p >= 1 && p <= 4) || p == 0 {
        this.m_partFx[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\quest\\placeholders\\sq009_drone_fire.effect"), at, true);
      } else {
        this.m_partFx[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\vehicles\\drone\\octant\\octant_damage_smoke.effect"), at, true);
      }
      this.m_partFx2[p] = fx.SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\environment\\sparks\\e_sparks_cable_electric_failure_medium_constant_falling.effect"), at, true);
    }
  }

  private static func JetBone(i: Int32) -> CName {
    switch i {
      case 1: return n"l_front_01";
      case 2: return n"r_front_02";
      case 3: return n"l_back_01";
    }
    return n"r_back_01";
  }
  private func Jets() -> Void {
    let drone = this.m_drone;
    if !IsDefined(drone) || ArraySize(this.m_partHp) < CMUDrone.OctantParts() {
      return;
    }
    let lost = this.m_partHp[1] <= 0.0 || this.m_partHp[2] <= 0.0 || this.m_partHp[3] <= 0.0 || this.m_partHp[4] <= 0.0;
    if !lost {

      if this.m_jetsOwn {
        this.JetsBack();
      }
      return;
    }
    if !this.m_jetsOwn {
      GameObjectEffectHelper.BreakEffectLoopEvent(drone, n"thrust_smoke");
      this.m_jetsOwn = true;
      ArrayClear(this.m_jets);
      let k = 0;
      while k < 4 {
        ArrayPush(this.m_jets, null);
        k += 1;
      }
    }

    let i = 1;
    while i <= 4 {
      let alive = this.m_partHp[i] > 0.0;
      let fx = this.m_jets[i - 1];
      if alive && !IsDefined(fx) {
        this.m_jets[i - 1] = GameInstance.GetFxSystem(this.m_game).SpawnEffect(CMUMinotaur.Fx(CMUDrone.JetFx()), this.JetAt(i), true);
      }
      if !alive && IsDefined(fx) {
        fx.BreakLoop();
        this.m_jets[i - 1] = null;
      }
      i += 1;
    }
  }

  private static func PodBoxMin(i: Int32) -> Vector4 {
    switch i {
      case 1: return new Vector4(-0.73, -0.54, -0.55, 0.0);
      case 2: return new Vector4(-0.04, -0.54, -0.55, 0.0);
      case 3: return new Vector4(-0.69, -0.42, -0.67, 0.0);
    }
    return new Vector4(-0.05, -0.42, -0.67, 0.0);
  }
  private static func PodBoxMax(i: Int32) -> Vector4 {
    switch i {
      case 1: return new Vector4(0.04, 0.28, 0.45, 0.0);
      case 2: return new Vector4(0.73, 0.28, 0.45, 0.0);
      case 3: return new Vector4(0.05, 0.38, 0.27, 0.0);
    }
    return new Vector4(0.69, 0.38, 0.27, 0.0);
  }

  public static func JetFx() -> ResRef = r"mnc\\fx\\octant_thruster_one_s.effect"

  private let m_podMesh: array<wref<IPlacedComponent>>;
  private func PodMesh(i: Int32) -> wref<IPlacedComponent> {
    if ArraySize(this.m_podMesh) < 5 {
      ArrayResize(this.m_podMesh, 5);
    }
    if IsDefined(this.m_podMesh[i]) {
      return this.m_podMesh[i];
    }
    let drone = this.m_drone;
    if !IsDefined(drone) {
      return null;
    }
    let code = i == 1 ? "fl" : (i == 2 ? "fr" : (i == 3 ? "bl" : "br"));
    for c in drone.GetComponents() {
      if !IsDefined(this.m_podMesh[i]) && StrContains(NameToString(c.GetName()), "ext01_thruster_" + code) {
        let pc = c as IPlacedComponent;
        if IsDefined(pc) {
          this.m_podMesh[i] = pc;
        }
      }
    }
    return this.m_podMesh[i];
  }

  private func PodMeshPos(i: Int32) -> Vector4 {
    let drone = this.m_drone;
    if !IsDefined(drone) || i < 1 || i > 4 {
      return new Vector4(0.0, 0.0, 0.0, 0.0);
    }
    let found = this.PodMesh(i);
    if IsDefined(found) {
      if true {
        let pc = found;
        if IsDefined(pc) {
          let p = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(pc.worldTransform));
          let q = WorldTransform.GetOrientation(pc.worldTransform);

          let lo = CMUDrone.PodBoxMin(i);
          let hi = CMUDrone.PodBoxMax(i);
          let c0 = (lo + hi) * 0.5;
          let axes = [new Vector4(1.0, 0.0, 0.0, 0.0), new Vector4(-1.0, 0.0, 0.0, 0.0), new Vector4(0.0, 1.0, 0.0, 0.0), new Vector4(0.0, -1.0, 0.0, 0.0), new Vector4(0.0, 0.0, 1.0, 0.0), new Vector4(0.0, 0.0, -1.0, 0.0)];
          let best = 0;
          let bestZ = 9.0;
          let k = 0;
          while k < 6 {
            let z = CMFlight.QRot(q, axes[k]).Z;
            if z < bestZ {
              bestZ = z;
              best = k;
            }
            k += 1;
          }
          let face = c0;
          switch best {
            case 0: face.X = hi.X; break;
            case 1: face.X = lo.X; break;
            case 2: face.Y = hi.Y; break;
            case 3: face.Y = lo.Y; break;
            case 4: face.Z = hi.Z; break;
            default: face.Z = lo.Z; break;
          }
          face.W = 0.0;

          p = p + CMFlight.QRot(q, face) + CMFlight.QRot(q, axes[best]) * 0.15;
          p.W = 1.0;
          return p;
        }
      }
    }
    return new Vector4(0.0, 0.0, 0.0, 0.0);
  }

  private func JetAt(i: Int32) -> WorldTransform {
    let wt: WorldTransform;
    let drone = this.m_drone;
    let sc = IsDefined(drone) ? drone.FindComponentByName(n"Slot8842") as SlotComponent : null;
    let bone: WorldTransform;
    if IsDefined(sc) && sc.GetSlotTransform(CMUDrone.JetBone(i), bone) {
      let q = WorldTransform.GetOrientation(bone);

      let p = this.PodMeshPos(i);
      if p.W < 0.5 {
        p = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(bone));
      }
      let wp: WorldPosition;
      WorldPosition.SetVector4(wp, p);
      WorldTransform.SetWorldPosition(wt, wp);
      WorldTransform.SetOrientation(wt, q);
      return wt;
    }
    return CMUMinotaur.At(this.PartPos(i), new Vector4(0.0, 0.0, -1.0, 0.0));
  }

  private func JetsFollow() -> Void {
    if !this.m_jetsOwn {
      return;
    }

    let i = 1;
    while i <= 4 && i <= ArraySize(this.m_jets) {
      let fx = this.m_jets[i - 1];
      if IsDefined(fx) {
        fx.UpdateTransform(this.JetAt(i));
      }
      i += 1;
    }
  }

  private func JetsBack() -> Void {
    for fx in this.m_jets {
      if IsDefined(fx) {
        fx.BreakLoop();
      }
    }
    ArrayClear(this.m_jets);
    if this.m_jetsOwn && IsDefined(this.m_drone) {
      GameObjectEffectHelper.StartEffectEvent(this.m_drone, n"thrust_smoke");
    }
    this.m_jetsOwn = false;
  }

  private func PartFx() -> Void {
    if ArraySize(this.m_partHp) == 0 {
      return;
    }
    this.JetsFollow();
    let drone = this.m_drone;
    let hullFrac = 1.0;
    if IsDefined(drone) {
      let pools = GameInstance.GetStatPoolsSystem(this.m_game);
      let id = Cast<StatsObjectID>(drone.GetEntityID());
      hullFrac = pools.GetStatPoolValue(id, gamedataStatPoolType.Health, false) / MaxF(1.0, pools.GetStatPoolMaxPointValue(id, gamedataStatPoolType.Health));
    }
    let hullLevel = hullFrac < 0.25 ? 2 : (hullFrac < 0.5 ? 1 : 0);
    if hullLevel != this.m_partLevel[0] {
      this.PartLook(0, hullLevel, false);
      this.m_partLevel[0] = hullLevel;
    }
    let up = new Vector4(0.0, 0.0, 1.0, 0.0);
    let i = 0;
    while i < ArraySize(this.m_partHp) {
      if IsDefined(this.m_partFx[i]) || IsDefined(this.m_partFx2[i]) {
        let at = CMUMinotaur.At(this.PartPos(i), up);
        if IsDefined(this.m_partFx[i]) {
          this.m_partFx[i].UpdateTransform(at);
        }
        if IsDefined(this.m_partFx2[i]) {
          this.m_partFx2[i].UpdateTransform(at);
        }
      }
      i += 1;
    }
  }

  private func StopPartFx() -> Void {
    for f in this.m_partFx {
      if IsDefined(f) {
        f.BreakLoop();
      }
    }
    for f in this.m_partFx2 {
      if IsDefined(f) {
        f.BreakLoop();
      }
    }
    ArrayClear(this.m_partFx);
    ArrayClear(this.m_partFx2);
    ArrayClear(this.m_partLevel);
  }

  private static func WyvernWingBits(p: Int32) -> Uint64 {
    switch p {
      case 1: return 34094592ul;
      case 2: return 72638702567424ul;
      case 3: return 145277405134848ul;
      case 4: return 290554810269696ul;
      case 5: return 581109620539392ul;
    }
    return 1162219241078784ul;
  }

  private func HideWyvernWing(p: Int32) -> Void {
    let drone = this.m_drone;
    if !IsDefined(drone) {
      return;
    }
    let bits = CMUDrone.WyvernWingBits(p);
    let n = 0;

    for c in drone.GetComponents() {
      let sk = c as entSkinnedMeshComponent;
      if IsDefined(sk) {
        if Equals(c.GetName(), n"av_militech_wyvern_01") {
          let before = sk.chunkMask;
          ArrayPush(this.m_podHidden, c);
          ArrayPush(this.m_podMasks, before);
          sk.chunkMask = before & ~bits;
          sk.Toggle(false);
          sk.Toggle(true);
          n += 1;
        }
      }
    }
  }

  private func HideGriffinPod(p: Int32) -> Void {
    let drone = this.m_drone;
    if !IsDefined(drone) {
      return;
    }
    let code = p == 1 ? "wing_l" : "wing_r";
    let n = 0;
    for c in drone.GetComponents() {
      let m = c as MeshComponent;
      if IsDefined(m) && StrContains(NameToString(c.GetName()), code) && m.chunkMask != 0ul {
        ArrayPush(this.m_podHidden, c);
        ArrayPush(this.m_podMasks, m.chunkMask);
        m.chunkMask = 0ul;
        c.Toggle(false);
        n += 1;
      }
    }
    if n == 0 {

      let names = "";
      for c in drone.GetComponents() {
        if IsDefined(c as MeshComponent) {
          names = names + NameToString(c.GetName()) + " ";
        }
      }
    }
  }

  private func HidePod(p: Int32) -> Void {
    let drone = this.m_drone;
    if !IsDefined(drone) {
      return;
    }
    let code = p == 1 ? "fl" : (p == 2 ? "fr" : (p == 3 ? "bl" : "br"));
    for c in drone.GetComponents() {
      let n = NameToString(c.GetName());
      if StrContains(n, "drone_diode_emissive_" + code) {

        c.Toggle(false);
        ArrayPush(this.m_podLights, c);
      }
      if StrContains(n, "thruster_" + code) || StrContains(n, "sticker_" + code) || StrContains(n, "stickers_" + code) {
        let m = c as MeshComponent;
        if IsDefined(m) && m.chunkMask != 0ul {
          ArrayPush(this.m_podHidden, c);
          ArrayPush(this.m_podMasks, m.chunkMask);
          m.chunkMask = 0ul;

          c.Toggle(false);
        }
      }
    }
  }

  private func KeepLostPods() -> Void {
    let link = CMLinkSystem.Get(this.m_game);
    let drone = this.m_drone;

    let lost = ArraySize(this.m_partHp) >= CMUDrone.OctantParts() && (this.m_partHp[1] <= 0.0 || this.m_partHp[2] <= 0.0 || this.m_partHp[3] <= 0.0 || this.m_partHp[4] <= 0.0);
    if !lost || !IsDefined(drone) {
      this.UnhidePods();
      this.JetsBack();
      if IsDefined(drone) && link.PodsOf() == drone.GetEntityID() {
        link.ForgetPods();
      }
      return;
    }

    this.JetsBack();
    link.KeepPods(drone.GetEntityID(), this.m_podHidden, this.m_podMasks, this.m_podLights, false);
    ArrayClear(this.m_podHidden);
    ArrayClear(this.m_podMasks);
    ArrayClear(this.m_podLights);
    this.m_jetsOwn = false;
  }

  private func UnhidePods() -> Void {

    let i = ArraySize(this.m_podHidden) - 1;
    while i >= 0 {
      let sk = this.m_podHidden[i] as entSkinnedMeshComponent;
      if IsDefined(sk) {
        sk.chunkMask = this.m_podMasks[i];
        sk.Toggle(false);
        sk.Toggle(true);
      } else {
        let m = this.m_podHidden[i] as MeshComponent;
        if IsDefined(m) {
          m.chunkMask = this.m_podMasks[i];
          m.Toggle(true);
        }
      }
      i -= 1;
    }
    ArrayClear(this.m_podHidden);
    ArrayClear(this.m_podMasks);
    for c in this.m_podLights {
      if IsDefined(c) {
        c.Toggle(true);
      }
    }
    ArrayClear(this.m_podLights);
  }

  public func OpticsOnline() -> Bool = ArraySize(this.m_partHp) < CMUDrone.OctantParts() || this.m_partHp[9] > 0.0

  private let m_sndLastSpeed: Float;

  private func Pacify(drone: ref<NPCPuppet>, on: Bool) -> Void {
    if !on {

      CMPhysSoundWatch.Watch(false, new Vector4(0.0, 0.0, 0.0, 0.0), 0.0, 0.0);
    }
    drone.m_cmPiloted = on;
    let reactions = drone.GetStimReactionComponent();
    if IsDefined(reactions) {
      reactions.Toggle(!on);
    }
    let senses = drone.GetSensesComponent();
    if IsDefined(senses) {
      senses.Toggle(!on);
    }
    let tracker = drone.GetTargetTrackerComponent();
    if IsDefined(tracker) {
      if on {
        tracker.ClearThreats();
      }
      tracker.Toggle(!on);
    }
  }

  public static func Kind(drone: ref<NPCPuppet>) -> String {
    let rec = StrLower(TDBID.ToStringDEBUG(drone.GetRecordID()));
    if StrContains(rec, "bombus") {
      return "bombus";
    }
    if StrContains(rec, "griffin") {
      return "griffin";
    }
    if StrContains(rec, "octant") {
      return "octant";
    }
    return "wyvern";
  }

  public static func KindIndex(kind: String) -> Int32 {
    switch kind {
      case "octant": return 0;
      case "wyvern": return 1;
      case "griffin": return 2;
    }
    return 3;
  }

  public static func TypeName(kind: String) -> String {
    switch kind {
      case "bombus": return CMText.DrnNameBombus();
      case "griffin": return CMText.DrnNameGriffin();
      case "octant": return CMText.DrnNameOctant();
    }
    return CMText.DrnNameWyvern();
  }
}

public class CMDroneShot {
  public let kind: Int32;
  public let from: Vector4;
  public let via: Vector4;
  public let to: Vector4;
  public let target: Vector4;
  public let pos: Vector4;
  public let vel: Vector4;
  public let age: Float;
  public let life: Float;
  public let fx: ref<FxInstance>;
  public let struck: Bool;
  public let hit: wref<GameObject>;
}

public class CMWreckLogCb extends DelayCallback {
  public let drone: wref<NPCPuppet>;
  public let fell: Vector4;

  public func Call() -> Void {
    let d = this.drone;
    if !IsDefined(d) {
      return;
    }
    let p = d.GetWorldPosition();
  }
}

public class CMGasCb extends DelayCallback {
  public let game: GameInstance;
  public let at: Vector4;
  public let rec: TweakDBID;
  public let left: Int32;
  public let dmg: Float;
  public let blame: wref<NPCPuppet>;

  public func Call() -> Void {
    if this.left % 2 == 0 {
      GameInstance.GetFxSystem(this.game).SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\weapons\\explosives\\biohazard_grenade\\w_explosives_001_biohazard_grenade_01.effect"), CMUMinotaur.At(this.at, new Vector4(0.0, 0.0, 1.0, 0.0)), true);
    }
    CMUDrone.AreaAttack(this.game, this.at, this.rec, 6.0, this.dmg, this.blame);
    this.left -= 1;
    if this.left > 0 {
      GameInstance.GetDelaySystem(this.game).DelayCallback(this, 1.0, false);
    }
  }
}

public class CMDroneCollBackCb extends DelayCallback {
  public let unit: wref<CMUDrone>;
  public let drone: wref<NPCPuppet>;

  public func Call() -> Void {
    let u = this.unit;
    let d = this.drone;
    if IsDefined(u) && IsDefined(d) {
      u.OwnCollisionsBack(d);
    }
  }
}
