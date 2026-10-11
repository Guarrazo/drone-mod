module ControllableMechs.Control

import ControllableMechs.*

public class CMDroneSense {
  public let track: ref<CMDroneTrack>;
  private let m_scanAt: Float;
  private let m_nextTag: Int32;
  private let m_scanEnt: EntityID;
  private let m_scanT: Float;
  private let m_lockT: Float;
  private let m_pingReady: Float;
  private let m_tagging: Bool;
  private let m_logAt: Float;

  private let RANGE: Float = 120.0;
  private let SCAN_EVERY: Float = 0.5;
  private let SCAN_TIME: Float = 1.2;
  private let LOCK_HOLD: Float = 1.5;
  private let PING_RANGE: Float = 60.0;
  private let PING_COOLDOWN: Float = 20.0;
  private let ROUND_SPEED: Float = 320.0;
  private let NEAR: Float = 80.0;

  public static func Make(tagging: Bool) -> ref<CMDroneSense> {
    let s = new CMDroneSense();
    s.track = new CMDroneTrack();
    s.m_tagging = tagging;
    s.m_nextTag = 2;
    s.track.scan = -1.0;
    return s;
  }

  public func Tick(s: ref<CMCSession>, unit: ref<CMCUnit>, me: ref<GameObject>, pos: Vector4, now: Float, dt: Float) -> Void {
    let t = this.track;
    t.now = now;
    t.pos = pos;
    t.aim = s.aim;
    t.aimOk = s.aimDist > 0.0;
    t.yaw = s.rig.yaw;
    t.camPitch = s.rig.pitch;
    t.fov = s.rig.fov;
    t.pingLeft = MaxF(0.0, this.m_pingReady - now);
    if now >= this.m_scanAt {

      let hot = false;
      for hc in this.track.contacts {
        if hc.kind == 2 {
          hot = true;
        }
      }
      this.m_scanAt = now + (hot ? this.SCAN_EVERY : this.SCAN_EVERY * 2.0);
      this.Search(me, pos, now);
    }

    let onRay = s.aimEntity as NPCPuppet;
    if IsDefined(onRay) && !onRay.IsDead() && (!IsDefined(me) || !Equals(onRay.GetEntityID(), me.GetEntityID())) && Vector4.Distance(onRay.GetWorldPosition(), pos) <= this.RANGE {
      this.Note(onRay, GetPlayer(GetGameInstance()), now + this.SCAN_EVERY);
    }

    let lockNow: ref<CMDroneContact>;
    let aimId: EntityID;
    if IsDefined(s.aimEntity) {
      aimId = s.aimEntity.GetEntityID();
    }
    t.tagged = 0;
    t.hostiles = 0;
    t.detected = 0;
    for c in t.contacts {
      let e = c.ent;
      if IsDefined(e) {
        let p = e.GetWorldPosition();
        p.Z += c.kind == 0 ? 1.0 : 1.1;
        if dt > 0.0 && c.pos.W > 0.5 {
          let v = (p - c.pos) * (1.0 / dt);
          c.vel = c.vel + (v - c.vel) * MinF(1.0, dt * 6.0);
        }
        c.pos = p;
        c.pos.W = 1.0;
      }
      c.dist = Vector4.Distance(pos, c.pos);
      c.scr = unit.ScreenAt(s, c.pos);
      if c.tag > 0 {
        t.tagged += 1;
      }
      if c.kind == 2 && c.dist <= this.NEAR {
        t.hostiles += 1;
        if c.combat {
          t.detected += 1;
        }
      }
      if c.kind != 0 && EntityID.IsDefined(aimId) && Equals(c.id, aimId) {
        lockNow = c;
      }
    }

    if IsDefined(lockNow) {
      t.lock = lockNow;
      this.m_lockT = this.LOCK_HOLD;
    } else {
      this.m_lockT -= dt;
      if this.m_lockT <= 0.0 || !IsDefined(t.lock) || !IsDefined(t.lock.ent) || t.lock.hp <= 0.0 {
        t.lock = null;
      }
    }
    t.leadOn = false;
    if IsDefined(t.lock) && Vector4.Length(t.lock.vel) > 0.5 {
      let at = t.lock.pos + t.lock.vel * (t.lock.dist / this.ROUND_SPEED);
      t.lead = unit.ScreenAt(s, at);
      t.leadOn = AbsF(t.lead.X) < 1880.0 && AbsF(t.lead.Y) < 1040.0;
    }

    t.scan = -1.0;
    if this.m_tagging && IsDefined(lockNow) {
      if lockNow.tag > 0 {
        t.scan = 1.0;
      } else {
        if !Equals(this.m_scanEnt, lockNow.id) {
          this.m_scanEnt = lockNow.id;
          this.m_scanT = 0.0;
        }
        this.m_scanT += dt;
        t.scan = ClampF(this.m_scanT / this.SCAN_TIME, 0.0, 1.0);
        if this.m_scanT >= this.SCAN_TIME {
          this.TagIt(lockNow);
        }
      }
    } else {
      this.m_scanT = 0.0;
    }
  }

  public func Ping(me: ref<GameObject>, now: Float) -> Bool {
    if !this.m_tagging || now < this.m_pingReady {
      return false;
    }
    this.m_pingReady = now + this.PING_COOLDOWN;
    for c in this.track.contacts {
      if c.tag <= 0 && c.dist <= this.PING_RANGE {
        this.TagIt(c);
      }
    }
    if IsDefined(me) {
      GameObject.PlaySoundEvent(me, n"ui_hacking_access_granted");
    }
    return true;
  }

  private func TagIt(c: ref<CMDroneContact>) -> Void {
    c.tag = this.m_nextTag;
    this.m_nextTag += 1;

    let o = c.ent as GameObject;
    if IsDefined(o) && c.kind != 0 {
      GameObject.TagObject(o);
    }
    let pl = GetPlayer(GetGameInstance());
    if IsDefined(pl) {
      GameObject.PlaySoundEvent(pl, n"ui_menu_onpress");
    }
  }

  private func Search(me: ref<GameObject>, pos: Vector4, now: Float) -> Void {
    let game = GetGameInstance();
    let t = this.track;

    let pl = GetPlayer(game);
    if ArraySize(t.contacts) == 0 || t.contacts[0].kind != 0 {
      let v = new CMDroneContact();
      v.kind = 0;
      v.tag = 1;
      v.hp = 1.0;
      ArrayInsert(t.contacts, 0, v);
    }
    let vc = t.contacts[0];
    vc.ent = pl;
    vc.seen = now;
    if IsDefined(pl) {
      vc.id = pl.GetEntityID();
      vc.hp = GameInstance.GetStatPoolsSystem(game).GetStatPoolValue(Cast<StatsObjectID>(pl.GetEntityID()), gamedataStatPoolType.Health, true) / 100.0;
    }
    if !IsDefined(me) {
      return;
    }
    let q: TargetSearchQuery;
    q.testedSet = TargetingSet.Complete;
    q.searchFilter = TSF_All(TSFMV.Obj_Puppet | TSFMV.St_AliveAndActive);
    q.maxDistance = this.RANGE;
    q.filterObjectByDistance = true;
    q.includeSecondaryTargets = false;
    q.ignoreInstigator = true;

    let parts: array<TS_TargetPartInfo>;
    if IsDefined(pl) {
      q.maxDistance = MinF(300.0, this.RANGE + Vector4.Distance(pl.GetWorldPosition(), pos));
      GameInstance.GetTargetingSystem(game).GetTargetParts(pl, q, parts);
    }    for p in parts {
      let comp = TS_TargetPartInfo.GetComponent(p);
      let npc: ref<NPCPuppet>;
      if IsDefined(comp) {
        npc = comp.GetEntity() as NPCPuppet;
      }
      if IsDefined(npc) && !npc.IsDead() && !Equals(npc.GetEntityID(), me.GetEntityID()) && Vector4.Distance(npc.GetWorldPosition(), pos) <= this.RANGE {
        this.Note(npc, pl, now);
      }
    }
    if now >= this.m_logAt {
      this.m_logAt = now + 5.0;
    }

    let i = ArraySize(t.contacts) - 1;
    while i >= 1 {
      let c = t.contacts[i];
      let npc = c.ent as NPCPuppet;
      if c.seen < now - 0.01 || !IsDefined(npc) || npc.IsDead() {
        ArrayErase(t.contacts, i);
      }
      i -= 1;
    }
  }

  private func Note(npc: ref<NPCPuppet>, pl: ref<PlayerPuppet>, now: Float) -> Void {
    let t = this.track;
    let c = this.Find(npc.GetEntityID());
    if !IsDefined(c) {
      if ArraySize(t.contacts) >= 32 {
        return;
      }
      c = new CMDroneContact();
      c.id = npc.GetEntityID();
      c.ent = npc;
      ArrayPush(t.contacts, c);
    }
    c.seen = now;
    if npc.IsCivilian() || npc.IsCrowd() {
      c.kind = 1;
    } else {
      let att = IsDefined(pl) ? GameObject.GetAttitudeBetween(npc, pl) : EAIAttitude.AIA_Neutral;
      c.kind = Equals(att, EAIAttitude.AIA_Hostile) ? 2 : (Equals(att, EAIAttitude.AIA_Friendly) ? 4 : 3);
    }
    let ty = npc.GetNPCType();
    c.machine = Equals(ty, gamedataNPCType.Drone) || Equals(ty, gamedataNPCType.Mech) || Equals(ty, gamedataNPCType.Android);
    c.armed = IsDefined(ScriptedPuppet.GetWeaponRight(npc));
    c.combat = Equals(npc.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat);
    c.hp = GameInstance.GetStatPoolsSystem(npc.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatPoolType.Health, true) / 100.0;
  }

  private func Find(id: EntityID) -> ref<CMDroneContact> {
    for c in this.track.contacts {
      if Equals(c.id, id) {
        return c;
      }
    }
    return null;
  }
}

public abstract class CMDroneHull {
  public static func Points(kind: String) -> array<Vector4> {
    switch kind {
      case "bombus":
        return [new Vector4(0.019, 0.133, -0.005, 0.0), new Vector4(-0.046, -0.258, 0.128, 0.0), new Vector4(0.237, -0.074, 0.099, 0.0), new Vector4(-0.251, -0.033, 0.094, 0.0), new Vector4(0.000, -0.002, 0.271, 0.0), new Vector4(0.064, 0.163, 0.174, 0.0), new Vector4(0.215, 0.064, 0.108, 0.0), new Vector4(-0.033, 0.224, 0.139, 0.0), new Vector4(-0.215, 0.064, 0.108, 0.0), new Vector4(0.046, -0.258, 0.128, 0.0), new Vector4(0.049, 0.214, 0.028, 0.0), new Vector4(0.000, -0.267, 0.110, 0.0)];
      case "griffin":
        return [new Vector4(-0.036, 0.180, -0.474, 0.0), new Vector4(0.046, -0.531, 0.521, 0.0), new Vector4(0.490, 0.657, 0.115, 0.0), new Vector4(-0.490, 0.657, 0.115, 0.0), new Vector4(0.611, -0.195, -0.045, 0.0), new Vector4(-0.613, -0.194, -0.048, 0.0), new Vector4(0.094, -0.700, -0.120, 0.0), new Vector4(0.482, 0.424, -0.397, 0.0), new Vector4(-0.482, 0.423, -0.397, 0.0), new Vector4(0.072, 0.471, 0.318, 0.0), new Vector4(-0.446, -0.484, 0.045, 0.0), new Vector4(0.446, -0.484, 0.045, 0.0)];
      case "wyvern":
        return [new Vector4(0.010, 0.311, -0.007, 0.0), new Vector4(-0.068, -0.469, 0.386, 0.0), new Vector4(0.015, 0.051, 0.461, 0.0), new Vector4(-0.150, -0.184, 0.051, 0.0), new Vector4(-0.068, 0.470, 0.386, 0.0), new Vector4(0.074, -0.459, 0.058, 0.0), new Vector4(0.150, -0.180, 0.150, 0.0), new Vector4(0.001, 0.486, 0.181, 0.0), new Vector4(0.150, 0.185, 0.051, 0.0), new Vector4(-0.150, 0.030, 0.400, 0.0), new Vector4(0.150, -0.027, 0.400, 0.0), new Vector4(-0.094, 0.395, 0.058, 0.0)];
      case "octant":
        return [new Vector4(-0.129, 1.419, -0.760, 0.0), new Vector4(0.362, -1.666, 0.317, 0.0), new Vector4(-1.330, 0.047, 0.671, 0.0), new Vector4(1.336, 0.525, 0.603, 0.0), new Vector4(-0.319, -0.721, 1.066, 0.0), new Vector4(-0.790, -0.757, -0.237, 0.0), new Vector4(0.802, 0.798, -0.380, 0.0), new Vector4(0.790, -0.757, -0.237, 0.0), new Vector4(-0.983, 1.056, -0.294, 0.0), new Vector4(1.226, -0.527, 0.663, 0.0), new Vector4(0.048, 1.668, 0.095, 0.0), new Vector4(0.013, -1.360, -0.365, 0.0)];
    }
    let none: array<Vector4>;
    return none;
  }

  public static func SensorUpCm(kind: String) -> Int32 {
    switch kind {
      case "bombus": return 13;
      case "griffin": return 0;
      case "wyvern": return 22;
      case "octant": return 15;
    }
    return 10;
  }

  public static func SensorFwdCm(kind: String) -> Int32 {
    switch kind {
      case "bombus": return 34;
      case "griffin": return 79;
      case "wyvern": return 59;
      case "octant": return 179;
    }
    return 35;
  }
}
