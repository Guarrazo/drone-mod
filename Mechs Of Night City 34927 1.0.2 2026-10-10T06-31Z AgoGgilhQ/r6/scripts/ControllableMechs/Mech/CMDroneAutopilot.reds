module ControllableMechs

import ControllableMechs.Control.*

public class CMAPTickEvent extends Event {
  public let gen: Int32;
}

@addField(PlayerPuppet)
public let m_cmAutopilot: wref<CMDroneAutopilot>;

@addMethod(PlayerPuppet)
protected cb func OnCMAPTick(evt: ref<CMAPTickEvent>) -> Bool {
  if IsDefined(this.m_cmAutopilot) {
    this.m_cmAutopilot.Frame(evt.gen);
  }
  return true;
}

public class CMDroneAutoTick extends DelayCallback {
  public let ap: wref<CMDroneAutopilot>;
  public let gen: Int32;
  public let kind: Int32;
  public func Call() -> Void {
    if IsDefined(this.ap) {
      this.ap.Timer(this.gen, this.kind);
    }
  }
}

public class CMDroneAutopilot extends IScriptable {
  private let m_game: GameInstance;
  private let m_unit: ref<CMUDrone>;
  private let m_gen: Int32;
  private let m_on: Bool;
  private let m_last: Float;
  private let m_angle: Float;
  private let m_in: Bool;
  private let m_logAt: Float;
  private let m_id: EntityID;
  private let m_floor: Float;
  private let m_floorUntil: Float;
  private let m_stuck: Float;
  private let m_seen: String;
  private let m_armID: EntityID;
  private let m_armGen: Int32;
  private let m_armUntil: Float;
  private let m_timerLoop: Bool;
  private let m_frames: Int32;
  private let m_watchFrames: Int32;
  private let m_rateFrames: Int32;
  private let m_prevVel: Vector4;
  private let m_recoverUntil: Float;
  private let m_hp: Float;

  private let m_fanAt: Float;
  private let m_fanNear: Float;
  private let m_fanWhat: String;
  private let m_fanLow: Float;
  private let m_clearAt: Float;
  private let m_clear: Bool;

  public static func RADIUS() -> Float = 16.0
  public static func HEIGHT() -> Float = 22.0
  public static func CLEAR() -> Float = 9.0
  public static func ORBIT_SPEED() -> Float = 6.0
  public static func MAX_SPEED() -> Float = 14.0

  public func On() -> Bool = this.m_on

  private let m_mode: Int32;
  private let m_point: Vector4;
  public func OnPoint() -> Bool = this.m_on && this.m_mode > 0
  public func SetPoint(at: Vector4, loiter: Bool) -> Void {
    this.m_point = at;
    this.m_mode = loiter ? 1 : 2;
    this.m_in = false;
  }
  public func FollowV() -> Void {
    if this.m_mode != 0 {
      this.m_mode = 0;
      this.m_in = false;
    }
  }
  public func Flying(id: EntityID) -> Bool = this.m_on && this.m_id == id

  public static func Make(game: GameInstance) -> ref<CMDroneAutopilot> {
    let a = new CMDroneAutopilot();
    a.m_game = game;
    return a;
  }

  public func Arm(id: EntityID) -> Void {
    if this.m_on {
      return;
    }
    this.m_armID = id;
    this.m_armGen += 1;
    this.m_armUntil = this.Now() + 20.0;
    this.Schedule(1, 0.1, this.m_armGen);
  }

  public func Timer(gen: Int32, kind: Int32) -> Void {
    switch kind {
      case 1:
        if gen != this.m_armGen || this.m_on {
          return;
        }
        if CMLinkSystem.Get(this.m_game).IsLinkedTo(this.m_armID) {
          let why = this.Start();
          if StrLen(why) > 0 {
          }
          return;
        }
        if this.Now() < this.m_armUntil {
          this.Schedule(1, 0.1, gen);
        }
        break;
      case 2:
        this.Watchdog(gen);
        break;
      default:
        this.Frame(gen);
        break;
    }
  }

  private func Schedule(kind: Int32, delay: Float, gen: Int32) -> Void {
    let cb = new CMDroneAutoTick();
    cb.ap = this;
    cb.gen = gen;
    cb.kind = kind;
    GameInstance.GetDelaySystem(this.m_game).DelayCallback(cb, delay, false);
  }

  public func Start() -> String {
    if this.m_on {
      return "";
    }
    let link = CMLinkSystem.Get(this.m_game);
    let drone = link.Unit();
    if !IsDefined(drone) || !Equals(drone.GetNPCType(), gamedataNPCType.Drone) {
      return CMText.AutoNoDroneLinked();
    }
    let session = CMCSession.Get(this.m_game);
    if IsDefined(session) && session.IsActive() {
      return CMText.AutoPiloted();
    }
    let player = GetPlayer(this.m_game);
    if !IsDefined(player) {
      return CMText.AutoNoPlayer();
    }
    let unit = new CMUDrone();
    let why = unit.Begin(session);
    if StrLen(why) > 0 {
      return why;
    }
    unit.autoOn = true;
    unit.autoH = CMPilotRig.YawOf(drone.GetWorldForward());
    link.SetOrder(CMOrder.None());
    this.m_unit = unit;
    this.m_id = drone.GetEntityID();
    this.m_on = true;
    this.m_in = false;
    this.m_floor = 0.0;
    this.m_floorUntil = 0.0;
    this.m_stuck = 0.0;
    this.m_recoverUntil = 0.0;
    this.m_prevVel = new Vector4(0.0, 0.0, 0.0, 0.0);
    this.m_hp = this.Health(drone);
    this.m_armGen += 1;
    this.m_gen += 1;
    this.m_last = this.Now();
    this.m_frames = 0;
    this.m_watchFrames = 0;
    this.m_rateFrames = 0;
    this.m_timerLoop = false;
    player.m_cmAutopilot = this;
    let rel = drone.GetWorldPosition() - player.GetWorldPosition();
    this.m_angle = AtanF(rel.Y, rel.X);
    this.NextFrame();
    this.Schedule(2, 0.5, this.m_gen);
    return "";
  }

  public func Stop(why: String) -> Void {
    this.Halt(why, false);
  }

  public func HandOver() -> Void {
    this.Halt("handed to the pilot", true);
  }

  private func Halt(why: String, keepAiOff: Bool) -> Void {
    this.m_armGen += 1;
    if !this.m_on {
      return;
    }
    this.m_on = false;
    this.m_gen += 1;
    let session = CMCSession.Get(this.m_game);
    if IsDefined(this.m_unit) {
      this.m_unit.autoOn = false;
      this.m_unit.keepAiOff = keepAiOff;
      this.m_unit.End(session, false);
    }
    this.m_unit = null;
  }

  private func Now() -> Float = EngineTime.ToFloat(GameInstance.GetEngineTime(this.m_game))

  private func PlayerPos() -> Vector4 {
    let p = GetPlayer(this.m_game);
    return IsDefined(p) ? p.GetWorldPosition() : new Vector4(0.0, 0.0, 0.0, 1.0);
  }

  private func Health(npc: ref<NPCPuppet>) -> Float {
    return GameInstance.GetStatPoolsSystem(this.m_game).GetStatPoolValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatPoolType.Health, true);
  }

  private func NextFrame() -> Void {
    if this.m_timerLoop {
      this.Schedule(0, 0.016, this.m_gen);
      return;
    }
    let player = GetPlayer(this.m_game);
    if !IsDefined(player) {
      return;
    }
    let evt = new CMAPTickEvent();
    evt.gen = this.m_gen;
    GameInstance.GetDelaySystem(this.m_game).DelayEventNextFrame(player, evt);
  }

  private func Watchdog(gen: Int32) -> Void {
    if gen != this.m_gen || !this.m_on {
      return;
    }
    if this.m_frames == this.m_watchFrames && !this.m_timerLoop {
      this.m_timerLoop = true;
      this.NextFrame();
    }
    this.m_watchFrames = this.m_frames;
    this.Schedule(2, 0.5, gen);
  }

  public func Frame(gen: Int32) -> Void {
    if gen != this.m_gen || !this.m_on || !IsDefined(this.m_unit) {
      return;
    }
    this.m_frames += 1;
    this.m_rateFrames += 1;
    let now = this.Now();
    let dt = ClampF(now - this.m_last, 0.0, 0.1);
    this.m_last = now;
    if dt <= 0.0 {
      this.NextFrame();
      return;
    }
    if !this.m_unit.IsAlive() {
      this.Stop("the drone is down");
      return;
    }
    let link = CMLinkSystem.Get(this.m_game);
    if !link.IsLinkedTo(this.m_id) {
      this.Stop("the link closed");
      return;
    }
    let session = CMCSession.Get(this.m_game);
    if IsDefined(session) && session.IsActive() {
      this.Stop("piloted");
      return;
    }
    if this.m_unit.Live() {
      this.Steer(dt, now);
    }
    this.m_unit.Tick(session, dt, now);
    this.NextFrame();
  }

  private func Look(from: Vector4, to: Vector4) -> Float {
    let hit: TraceResult;
    if this.m_unit.Probe(from, to, hit) {
      return Vector4.Distance(from, Cast<Vector4>(hit.position));
    }
    return -1.0;
  }

  private func Steer(dt: Float, now: Float) -> Void {
    let u = this.m_unit;
    let drone = CMLinkSystem.Get(this.m_game).Unit();
    let pos = u.FlightPos();
    let vel = u.FlightVel();
    let velH = new Vector4(vel.X, vel.Y, 0.0, 0.0);
    let speed = Vector4.Length(velH);
    let me = this.PlayerPos();
    let centre = new Vector4(me.X, me.Y, me.Z + CMDroneAutopilot.HEIGHT(), 1.0);
    if this.m_mode > 0 {
      centre = new Vector4(this.m_point.X, this.m_point.Y, this.m_point.Z + CMDroneAutopilot.HEIGHT(), 1.0);
    }
    let d = Vector4.Distance2D(pos, centre);
    let yawNow = u.FlightYaw();

    let dv = Vector4.Length(vel - this.m_prevVel);
    this.m_prevVel = vel;
    let knocked = dv > 4.0;
    if knocked {
      this.m_recoverUntil = now + 1.5;
    }
    if IsDefined(drone) {
      let hp = this.Health(drone);
      if hp < this.m_hp - 0.01 {
      }
      this.m_hp = hp;
    }
    if u.FlightTilt() > 35.0 && now >= this.m_recoverUntil {
      this.m_recoverUntil = now + 1.5;
    }
    if now < this.m_recoverUntil {

      u.autoF = 0.0;
      u.autoS = 0.0;
      u.autoC = 1.0;
      u.autoH = yawNow;
      u.autoFire = false;
      this.m_seen = "recovering";
      this.Report(now, d, pos, me, vel);
      return;
    }

    let want: Vector4;
    let targetZ = centre.Z;
    if this.m_mode == 2 {

      let to = centre - pos;
      to.Z = 0.0;
      let dist = Vector4.Length(to);
      want = dist < 1.5 ? new Vector4(0.0, 0.0, 0.0, 0.0) : Vector4.Normalize(to) * MinF(CMDroneAutopilot.MAX_SPEED(), 0.5 + dist * 0.3);
      this.m_in = dist < 4.0;
    } else {
    if !this.m_in && d < CMDroneAutopilot.RADIUS() + 4.0 {
      this.m_in = true;
      let rel = pos - centre;
      this.m_angle = AtanF(rel.Y, rel.X);
    }
    if this.m_in {
      this.m_angle += CMDroneAutopilot.ORBIT_SPEED() / CMDroneAutopilot.RADIUS() * dt;
      let ahead = this.m_angle + 0.5;
      let target = centre + new Vector4(CosF(ahead) * CMDroneAutopilot.RADIUS(), SinF(ahead) * CMDroneAutopilot.RADIUS(), 0.0, 0.0);
      let to = target - pos;
      to.Z = 0.0;
      want = Vector4.Normalize(to) * MinF(CMDroneAutopilot.ORBIT_SPEED() + Vector4.Length(to) * 0.2, 8.0);
    } else {

      let rel = pos - centre;
      rel.Z = 0.0;
      let a = AtanF(rel.Y, rel.X);
      let edge = centre + new Vector4(CosF(a + 0.6) * CMDroneAutopilot.RADIUS(), SinF(a + 0.6) * CMDroneAutopilot.RADIUS(), 0.0, 0.0);
      let to = edge - pos;
      to.Z = 0.0;
      want = Vector4.Normalize(to) * MinF(CMDroneAutopilot.MAX_SPEED(), 1.5 + Vector4.Length(to) * 0.3);
    }
    }

    let engaging = this.Gunner(drone, pos, now);
    let wantYaw = engaging ? CMPilotRig.YawOf(u.autoAim - pos) : CMPilotRig.YawOf(want);
    let turning = !engaging && speed < 4.0 && AbsF(CMPilotRig.Wrap(wantYaw - yawNow)) > 50.0;

    let dir = speed > 2.0 ? Vector4.Normalize(velH) : Vector4.Normalize(want);
    let side = new Vector4(dir.Y, -dir.X, 0.0, 0.0);
    let half = u.Span() + 0.4;

    let reach = ClampF(speed * 2.5 + 1.0, 10.0, 41.0);
    if now >= this.m_fanAt {
      this.m_fanAt = now + 0.05;
      let up = new Vector4(0.0, 0.0, 1.2, 0.0);
      this.m_fanNear = -1.0;
      this.m_fanWhat = "";
      let k = 0;
      while k < 4 {
        let st = pos;
        if k == 1 {
          st = pos + side * half;
        } else {
          if k == 2 {
            st = pos - side * half;
          } else {
            if k == 3 {
              st = pos + up;
            }
          }
        }
        let r = this.Look(st, st + dir * reach);
        if r >= 0.0 && (this.m_fanNear < 0.0 || r < this.m_fanNear) {
          this.m_fanNear = r;
          this.m_fanWhat = k == 0 ? "centre" : (k == 1 ? "left" : (k == 2 ? "right" : "top"));
        }
        k += 1;
      }
      this.m_fanLow = this.Look(pos, pos + dir * reach + new Vector4(0.0, 0.0, -7.0, 0.0));
    }
    let near = this.m_fanNear;
    let what = this.m_fanWhat;
    let low = this.m_fanLow;
    let gap = u.GroundGap();
    let climbFor = false;
    this.m_seen = "clear";
    if near >= 0.0 {
      want = want * ClampF((near - 5.0) / reach, 0.0, 1.0);
      climbFor = true;
      this.m_seen = what + " " + FloatToStringPrec(near, 1) + " m";
    } else {
      if low >= 0.0 {
        climbFor = true;
        this.m_seen = "below ahead " + FloatToStringPrec(low, 1) + " m";
      }
    }

    let wantZ = targetZ;
    if gap >= 0.0 && gap < CMDroneAutopilot.CLEAR() {
      wantZ = MaxF(wantZ, pos.Z + (CMDroneAutopilot.CLEAR() - gap) + 2.0);
      climbFor = true;
    }
    if climbFor {
      this.m_floor = MaxF(this.m_floor, pos.Z + 6.0);
      this.m_floorUntil = now + 4.0;
    }
    if now < this.m_floorUntil {
      wantZ = MaxF(wantZ, this.m_floor);
    } else {
      this.m_floor = 0.0;
    }
    let c = ClampF((wantZ - pos.Z) * 0.3 - vel.Z * 0.3, -0.6, 0.8);
    if climbFor {
      c = 1.0;
    }

    if Vector4.Length(want) > 3.0 && speed < 1.0 && !turning {
      this.m_stuck += dt;
    } else {
      this.m_stuck = 0.0;
    }
    if this.m_stuck > 1.5 {
      c = 1.0;
      want = want * 0.2;
      this.m_seen = "stuck, climbing";
    }

    let cap = this.m_in ? 0.45 : 0.6;
    let lack = want - velH;
    let stick = lack * (1.0 / 8.0);
    if Vector4.Length(stick) > cap {
      stick = Vector4.Normalize(stick) * cap;
    }
    if turning {
      stick = new Vector4(0.0, 0.0, 0.0, 0.0) - velH * (1.0 / 8.0);
      this.m_seen = this.m_seen + ", turning in place";
    }
    let fwd = CMPilotRig.Dir(yawNow, 0.0);
    let right = CMPilotRig.Dir(yawNow - 90.0, 0.0);
    u.autoF = ClampF(stick.X * fwd.X + stick.Y * fwd.Y, -cap, cap);
    u.autoS = ClampF(stick.X * right.X + stick.Y * right.Y, -cap, cap);
    u.autoC = c;
    u.autoH = engaging || Vector4.Length(want) > 1.5 ? wantYaw : yawNow;
    this.Report(now, d, pos, me, vel);
  }

  public static func ENGAGE() -> Float = 45.0
  private let m_gunAt: Float;
  private let m_gunTarget: wref<NPCPuppet>;
  private let m_burstUntil: Float;
  private let m_restUntil: Float;

  private func Gunner(drone: wref<NPCPuppet>, pos: Vector4, now: Float) -> Bool {
    let u = this.m_unit;
    u.autoFire = false;
    if this.m_mode == 2 || !u.HasGun() || !IsDefined(drone) {
      this.m_gunTarget = null;
      return false;
    }
    let t = this.m_gunTarget;
    if IsDefined(t) && (!ScriptedPuppet.IsAlive(t) || t.IsDead() || Vector4.Distance(t.GetWorldPosition(), pos) > CMDroneAutopilot.ENGAGE() + 10.0) {
      t = null;
      this.m_gunTarget = null;
    }
    if !IsDefined(t) && now >= this.m_gunAt {
      this.m_gunAt = now + 0.5;
      t = this.FindTarget(drone, pos);
      this.m_gunTarget = t;
      if IsDefined(t) {
      }
    }
    if !IsDefined(t) {
      return false;
    }
    let aim = t.GetWorldPosition() + new Vector4(0.0, 0.0, 1.1, 0.0);
    aim.W = 1.0;
    u.autoAim = aim;
    u.autoTarget = t;
    let far = Vector4.Distance(pos, aim);

    if now >= this.m_clearAt {
      this.m_clearAt = now + 0.1;
      let block = this.Look(pos, aim);
      this.m_clear = block < 0.0 || block > far - 1.5;
    }
    let clear = this.m_clear;
    let facing = AbsF(CMPilotRig.Wrap(CMPilotRig.YawOf(aim - pos) - u.FlightYaw())) < 20.0;
    if clear && facing {
      if now >= this.m_restUntil {
        this.m_burstUntil = now + 1.5;
        this.m_restUntil = now + 2.3;
      }
      u.autoFire = now < this.m_burstUntil;
    }
    return true;
  }

  private func FindTarget(drone: wref<NPCPuppet>, pos: Vector4) -> wref<NPCPuppet> {
    let pl = GetPlayer(this.m_game);
    if !IsDefined(pl) {
      return null;
    }
    let q: TargetSearchQuery;
    q.testedSet = TargetingSet.Complete;
    q.searchFilter = TSF_All(TSFMV.Obj_Puppet | TSFMV.St_AliveAndActive);
    q.maxDistance = MinF(400.0, CMDroneAutopilot.ENGAGE() + Vector4.Distance(pl.GetWorldPosition(), pos));
    q.filterObjectByDistance = true;
    q.includeSecondaryTargets = false;
    q.ignoreInstigator = true;
    let parts: array<TS_TargetPartInfo>;
    GameInstance.GetTargetingSystem(this.m_game).GetTargetParts(pl, q, parts);
    let best: wref<NPCPuppet>;
    let bestD = 0.0;
    for p in parts {
      let comp = TS_TargetPartInfo.GetComponent(p);
      let npc: ref<NPCPuppet>;
      if IsDefined(comp) {
        npc = comp.GetEntity() as NPCPuppet;
      }
      if IsDefined(npc) && !npc.IsDead() && npc.GetEntityID() != drone.GetEntityID() {
        let d = Vector4.Distance(npc.GetWorldPosition(), pos);
        let hostile = Equals(GameObject.GetAttitudeBetween(npc, pl), EAIAttitude.AIA_Hostile) || Equals(GameObject.GetAttitudeBetween(npc, drone), EAIAttitude.AIA_Hostile);
        let fighting = Equals(npc.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat);
        if d <= CMDroneAutopilot.ENGAGE() && hostile && fighting && (!IsDefined(best) || d < bestD) {
          let aim = npc.GetWorldPosition() + new Vector4(0.0, 0.0, 1.1, 0.0);
          let block = this.Look(pos, aim);
          if block < 0.0 || block > Vector4.Distance(pos, aim) - 1.5 {
            best = npc;
            bestD = d;
          }
        }
      }
    }
    return best;
  }

  private func Report(now: Float, d: Float, pos: Vector4, me: Vector4, vel: Vector4) -> Void {
    if now < this.m_logAt {
      return;
    }
    this.m_logAt = now + 1.0;
    let u = this.m_unit;
    this.m_rateFrames = 0;
  }
}
