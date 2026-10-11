module ControllableMechs

import TerminalKit.*
import ControllableMechs.Control.*

public class CMMechDropTick extends DelayCallback {
  public let drop: wref<CMMechDrop>;
  public let gen: Int32;
  public let frame: Bool;

  public func Call() -> Void {
    if IsDefined(this.drop) {
      if this.frame {
        this.drop.Frame(this.gen);
      } else {
        this.drop.Second(this.gen);
      }
    }
  }
}

public class CMMechDropStripOff extends DelayCallback {
  public let strip: ref<TKHudStrip>;
  public func Call() -> Void {
    if IsDefined(this.strip) {
      this.strip.Hide();
    }
  }
}

public class CMMechDrop extends IScriptable {
  private let m_game: GameInstance;
  private let m_at: Vector4;
  private let m_ground: Float;
  private let m_count: Int32;
  private let m_gen: Int32;
  private let m_started: Bool;
  private let m_last: Float;
  private let m_t: Float;
  private let m_z: Float;
  private let m_vz: Float;
  private let m_landedAt: Float;
  private let m_face: Quaternion;
  private let m_legs: ref<CMAnimDriver>;
  private let m_active: Bool;

  public static func HEIGHT() -> Float = 25.0
  private static func G() -> Float = 9.81
  private static func STAGGER() -> Float = 2.97
  public func Active() -> Bool = this.m_active

  public static func Start(game: GameInstance, at: Vector4) -> ref<CMMechDrop> {
    let d = new CMMechDrop();
    d.m_game = game;
    d.m_at = at;
    d.m_count = 10;
    d.m_active = true;
    TKPins.Add("mnc_drop", at);
    d.Say();
    d.Later(1.0, false);
    return d;
  }

  public func Cancel() -> Void {
    this.m_gen += 1;
    this.m_active = false;
    TKPins.Remove("mnc_drop");
    this.StripOff(0.0);
    let mech = CMFleet.Get(this.m_game).OutUnit();
    if IsDefined(mech) && this.m_started {
      this.Release(mech);
    }
  }

  private func Later(delay: Float, frame: Bool) -> Void {
    let cb = new CMMechDropTick();
    cb.drop = this;
    cb.gen = this.m_gen;
    cb.frame = frame;

    GameInstance.GetDelaySystem(this.m_game).DelayCallback(cb, frame ? 0.016 : delay, false);
  }

  private let m_strip: ref<TKHudStrip>;

  private func Strip(title: String, right: String, sub: String, frac: Float, warn: Bool) -> Void {
    if !IsDefined(this.m_strip) {
      this.m_strip = TKHud.Strip("mnc_drop", 620.0);
    }
    TKHud.SetTheme("cm_robotlink");
    this.m_strip.Set(title, right, sub);
    this.m_strip.Target(new Vector4(this.m_at.X, this.m_at.Y, this.m_at.Z, 1.0));
    this.m_strip.Fraction(frac);
    this.m_strip.Warn(warn);
    this.m_strip.Show();
  }

  private func StripOff(after: Float) -> Void {
    if !IsDefined(this.m_strip) {
      return;
    }
    if after <= 0.0 {
      this.m_strip.Hide();
      return;
    }
    let cb = new CMMechDropStripOff();
    cb.strip = this.m_strip;
    GameInstance.GetDelaySystem(this.m_game).DelayCallback(cb, after, false);
  }

  private func Say() -> Void {
    this.Strip(CMText.DropInbound(), CMText.DropCountdown(IntToString(this.m_count)), CMText.DropLzMarked(), Cast<Float>(this.m_count) / 10.0, this.m_count <= 3);
  }

  public func Second(gen: Int32) -> Void {
    if gen != this.m_gen || !this.m_active {
      return;
    }
    this.m_count -= 1;
    if this.m_count > 0 {
      this.Say();
      this.Later(1.0, false);
      return;
    }
    this.m_ground = this.GroundAt(this.m_at);
    let top = new Vector4(this.m_at.X, this.m_at.Y, this.m_ground + CMMechDrop.HEIGHT(), 1.0);
    let msg = CMFleet.Get(this.m_game).DeployAt(0, top);
    if !StrBeginsWith(msg, "*") {
      this.Cancel();
      this.Strip(CMText.DropAborted(), "", CMLinkSystem.Plain(msg), 0.0, true);
      this.StripOff(4.0);
      return;
    }
    CMLinkSystem.Get(this.m_game).HoldGroundCheck(10.0);
    this.m_last = EngineTime.ToFloat(GameInstance.GetEngineTime(this.m_game));
    this.m_t = 0.0;
    this.Later(0.0, true);
  }

  private func GroundAt(at: Vector4) -> Float {
    let nav = GameInstance.GetNavigationSystem(this.m_game).GetNearestNavmeshPointBelowOnlyHumanNavmesh(new Vector4(at.X, at.Y, at.Z + 30.0, 1.0), 60.0, 8);
    if !Vector4.IsZero(nav) && Vector4.Distance2D(nav, at) < 6.0 {
      return nav.Z;
    }
    return at.Z;
  }

  public func Frame(gen: Int32) -> Void {
    if gen != this.m_gen || !this.m_active {
      return;
    }
    let now = EngineTime.ToFloat(GameInstance.GetEngineTime(this.m_game));
    let dt = ClampF(now - this.m_last, 0.0, 0.1);
    this.m_last = now;
    this.m_t += dt;
    let mech = CMFleet.Get(this.m_game).OutUnit();
    if !this.m_started {
      if !IsDefined(mech) || !mech.IsAttached() {
        if this.m_t > 15.0 {
          this.Cancel();
          return;
        }
        this.Later(0.0, true);
        return;
      }
      this.m_started = true;
      this.m_t = 0.0;
      this.m_z = this.m_ground + CMMechDrop.HEIGHT();
      this.m_vz = 0.0;
      this.m_face = mech.GetWorldOrientation();
      this.m_legs = CMAnimDriver.Make(this.m_game);

      this.m_legs.Pose(mech, n"MNC_FallBrace", 2, -1.0, now);
      let sp = mech.GetWorldPosition();
      this.Strip(CMText.LinkMechDropping(), "", CMText.DropImpactImminent(), 0.0, true);
    }
    if !IsDefined(mech) {
      this.Cancel();
      return;
    }
    if this.m_landedAt <= 0.0 {
      this.m_vz -= CMMechDrop.G() * dt;
      this.m_z += this.m_vz * dt;
      if this.m_z <= this.m_ground {
        this.m_z = this.m_ground;
        this.Land(mech, -this.m_vz, now);
        this.m_landedAt = MaxF(this.m_t, 0.01);
      }
      this.Put(mech);
      if this.m_t - this.m_logAt >= 0.25 {
        this.m_logAt = this.m_t;
      }
    } else {

      this.Put(mech);
      if this.m_t - this.m_landedAt >= CMMechDrop.STAGGER() + 0.2 {
        this.Finish(mech);
        return;
      }
    }
    if this.m_t > 20.0 {
      this.m_z = this.m_ground;
      this.Put(mech);
      this.Finish(mech);
      return;
    }
    this.Later(0.0, true);
  }

  private let m_logAt: Float;

  private func Put(mech: ref<NPCPuppet>) -> Void {
    let p = new Vector4(this.m_at.X, this.m_at.Y, this.m_z, 1.0);
    let ai = mech.GetAIControllerComponent();
    if IsDefined(ai) {
      let tp = new AITeleportCommand();
      tp.position = p;
      tp.rotation = CMPilotRig.YawOf(Quaternion.GetForward(this.m_face));
      tp.doNavTest = false;
      ai.SendCommand(tp);
      return;
    }
    GameInstance.GetTeleportationFacility(this.m_game).Teleport(mech, p, Quaternion.ToEulerAngles(this.m_face));
  }

  private func Land(mech: ref<NPCPuppet>, speed: Float, now: Float) -> Void {
    GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_lcm_land");
    GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_melee_stomp_heavy");
    GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_fbk_bodyfall");
    let feet = new Vector4(this.m_at.X, this.m_at.Y, this.m_ground, 1.0);
    GameInstance.GetFxSystem(this.m_game).SpawnEffect(CMUMinotaur.Fx(r"base\\fx\\characters\\boss_adam_shasher\\ch_adam_smasher_land_heavy.effect"), CMUMinotaur.At(feet, new Vector4(0.0, 0.0, 1.0, 0.0)), true);
    this.m_legs.Pose(mech, n"StaggerFront", 1, 0.0, now);
  }

  private func Release(mech: ref<NPCPuppet>) -> Void {
    let now = EngineTime.ToFloat(GameInstance.GetEngineTime(this.m_game));
    if IsDefined(this.m_legs) {
      this.m_legs.Clear(mech, now);
    }
    let ai = mech.GetAIControllerComponent();
    if IsDefined(ai) {
      ai.Toggle(true);
      let tp = new AITeleportCommand();
      tp.position = new Vector4(this.m_at.X, this.m_at.Y, this.m_z, 1.0);
      tp.rotation = CMPilotRig.YawOf(mech.GetWorldForward());
      tp.doNavTest = false;
      ai.SendCommand(tp);
    }
  }

  private func Finish(mech: ref<NPCPuppet>) -> Void {
    let p = mech.GetWorldPosition();
    this.Release(mech);
    this.m_active = false;
    this.m_gen += 1;
    TKPins.Remove("mnc_drop");
    this.Strip(CMText.DropOnGround(), "", CMText.DropLinkReady(), 1.0, false);
    this.StripOff(4.0);
  }
}
