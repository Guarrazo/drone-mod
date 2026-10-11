module ControllableMechs.Control

import ControllableMechs.*

public class CMMechBody {
  private let m_game: GameInstance;
  private let m_id: EntityID;
  private let m_spawned: Bool;
  private let m_live: Bool;
  private let m_askedAt: Float;
  private let m_body: ref<PhysicalBodyInterface>;
  private let m_mechRef: wref<NPCPuppet>;
  private let m_offColliders: array<wref<IComponent>>;
  private let m_offMeshes: array<wref<IComponent>>;
  private let m_ownBodies: array<ref<PhysicalBodyInterface>>;
  private let m_keptColliders: array<wref<IComponent>>;
  private let m_keptCheckUntil: Float;

  public let led: Bool;
  public let landing: Float;
  public let knock: Float;
  public let why: String;
  public let failed: Bool;
  public let blocked: Bool;
  public let blockDir: Vector4;
  public let blockAt: Vector4;
  private let m_heldT: Float;
  private let m_offLegs: Float;
  private let m_ledAt: Float;
  private let m_still: Float;
  private let m_air: Float;
  private let m_fallVz: Float;
  private let m_feetVel: Vector4;
  private let m_walkDir: Vector4;
  private let m_walkSpeed: Float;
  private let m_legs: ref<CMAnimDriver>;
  private let m_action: Int32;
  private let m_faceDir: Vector4;
  private let m_easeUntil: Float;
  private let m_drivingWas: Bool;
  private let m_fallPose: Bool;
  private let m_staggerUntil: Float;
  private let m_lastAt: Vector4;
  private let m_lastSet: Bool;
  private let m_setLast: Bool;
  private let m_resyncAt: Float;
  private let m_resyncLogAt: Float;
  private let m_handAt: Float;
  private let m_handSynced: Bool;
  private let m_calm: Int32;
  private let m_pinAi: Bool;
  private let m_zOff: Float;
  private let m_zOffSet: Bool;
  private let m_vel: Vector4;
  private let m_heldQ: Quaternion;
  private let m_heldFwd: Vector4;
  private let m_placed: Vector4;
  private let m_aiIsOff: Bool;
  private let m_syncAt: Float;
  private let m_offDir: Vector4;
  private let m_airborne: Bool;
  private let m_logAt: Float;
  private let m_knockMax: Float;
  private let m_gap: Float;
  private let m_safe: Vector4;
  private let m_noGround: Float;
  private let m_now: Float;

  private let MASS: Float = 6000.0;
  private let HALF_Z: Float = 1.5;
  private let LIFT: Float = 0.6;
  private let ZOFF_MAX: Float = 0.08;
  private let G: Float = 9.81;
  private let W_FOLLOW: Float = 8.0;
  private let W_LEG: Float = 9.0;
  private let W_WALK: Float = 12.0;
  private let LEG_DAMP: Float = 0.7;
  private let FRICTION: Float = 4.0;
  private let SETTLE: Float = 0.45;
  private let SPIN_K: Float = 8.0;
  private let DROP: Float = 0.8;
  private let JUMP: Float = 0.8;
  private let ACCEL: Float = 8.0;
  private let DECEL: Float = 8.0;
  private let EASE: Float = 0.3;
  private let HAND_STILL: Float = 0.15;
  private let HAND_MAX: Float = 0.8;
  private let LEG_DROP: Float = 0.05;
  private let STAGGER_AT: Float = 5.0;
  private let STAGGER_T: Float = 2.97;

  public static func Make(game: GameInstance) -> ref<CMMechBody> {
    let b = new CMMechBody();
    b.m_game = game;
    b.m_legs = CMAnimDriver.Make(game);
    return b;
  }

  public func Live() -> Bool = this.m_live
  public func Id() -> EntityID = this.m_id

  public func Start(mech: ref<NPCPuppet>, now: Float) -> Void {
    this.m_mechRef = mech;
    this.Collisions(mech, false);
    this.OwnBodiesOff();
    this.m_spawned = false;
    this.m_live = false;
    this.led = false;
    this.m_askedAt = now;
    this.m_placed = new Vector4(0.0, 0.0, 0.0, 0.0);
    this.m_keptCheckUntil = now + 3.0;
  }

  public func Stop(mech: ref<NPCPuppet>) -> Void {
    if IsDefined(mech) {
      this.m_legs.Stop(mech, this.m_now);
      this.m_legs.Clear(mech, this.m_now);
    }
    if this.led && IsDefined(mech) {
      this.HandBack(mech, "the link closed", true);
    } else {
      if IsDefined(mech) && this.m_live {

        this.m_heldFwd = mech.GetWorldForward();
        this.Sync(mech);
      }
    }
    if this.m_spawned {
      let e = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_id);
      if IsDefined(e) {
        let body = this.Body(e);
        if IsDefined(body) {
          CMPhysStep.Release(body);
        }
      }
      GameInstance.GetDynamicEntitySystem().DeleteEntity(this.m_id);
    }
    this.m_spawned = false;
    this.m_live = false;
    this.m_body = null;
    for b in this.m_ownBodies {
      if IsDefined(b) {
        CMPhysColl.SetCollision(b, true);
      }
    }
    ArrayClear(this.m_ownBodies);
    if IsDefined(mech) {
      this.Collisions(mech, true);
    }
  }

  public func Tick(mech: ref<NPCPuppet>, dt: Float, now: Float) -> Void {
    this.landing = 0.0;
    this.knock = 0.0;
    if !IsDefined(mech) || dt <= 0.0 {
      return;
    }
    this.OwnBodiesOff();
    if !this.m_live {
      this.TryLive(mech, now);
      return;
    }
    let e = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_id);
    let body = IsDefined(e) ? this.Body(e) : null;
    if !IsDefined(body) {
      if IsDefined(e) {
        GameInstance.GetDynamicEntitySystem().DeleteEntity(this.m_id);
      }
      if this.led {
        this.HandBack(mech, "the body was lost", true);
      }
      this.m_live = false;
      this.m_spawned = false;
      this.m_body = null;
      this.m_askedAt = now;
      return;
    }
    CMWatch.Mark("mech body");
    let p = e.GetWorldPosition();
    p.W = 1.0;
    let q = e.GetWorldOrientation();
    let v = CMPhysStep.Velocity(body);
    v.W = 0.0;

    let dv = v - this.m_vel;
    dv.Z = 0.0;
    this.m_knockMax = MaxF(this.m_knockMax, Vector4.Length(dv));

    if ArraySize(this.m_keptColliders) > 0 && now < this.m_keptCheckUntil && Vector4.Length(dv) > 4.0 {
      for kc in this.m_keptColliders {
        if IsDefined(kc) {
          kc.Toggle(false);
          ArrayPush(this.m_offColliders, kc);
        }
      }
      ArrayClear(this.m_keptColliders);
    }
    this.m_now = now;
    if this.led {
      this.Leading(mech, body, p, v, dt, now);
    } else {
      this.Following(mech, body, p, v, dt, now);
    }
    if !this.m_live {
      return;
    }
    this.Upright(body, q);
    CMPhysWind.IgnoreNear(7320, p, 3.5);
    if now >= this.m_logAt {
      this.m_logAt = now + 2.0;
      this.m_knockMax = 0.0;
    }
  }

  private func Target(feet: Vector4) -> Vector4 = new Vector4(feet.X, feet.Y, feet.Z + this.LIFT + this.HALF_Z, 1.0)

  private func Following(mech: ref<NPCPuppet>, body: ref<PhysicalBodyInterface>, p: Vector4, v: Vector4, dt: Float, now: Float) -> Void {
    let at = mech.GetWorldPosition();

    let bottom = p.Z - this.HALF_Z;
    let gz = this.LegsGround(p, 60.0);
    let ground = gz > -99999.0;
    let gap = bottom - gz;
    this.m_gap = ground ? gap : -1.0;
    let onLegs = ground && gap < this.LIFT + this.DROP;
    let a = new Vector4(0.0, 0.0, 0.0, 0.0);
    if onLegs {
      a.Z = this.G + this.W_WALK * this.W_WALK * (this.LIFT - gap) - 2.0 * this.LEG_DAMP * this.W_WALK * v.Z;
      this.m_offLegs = 0.0;
      this.m_safe = new Vector4(p.X, p.Y, gz, 1.0);
    } else {
      this.m_offLegs += dt;
    }

    if onLegs && this.m_lastAt.W > 0.5 && this.m_handAt <= 0.0 && this.m_easeUntil <= 0.0 && !(this.m_walkSpeed > 0.0)
      && Vector4.Length(mech.GetVelocity()) < 0.3 {
      let seen = ClampF(at.Z - gz, 0.0, this.ZOFF_MAX);
      this.m_zOff = this.m_zOffSet ? this.m_zOff + (seen - this.m_zOff) * MinF(1.0, dt * 2.0) : seen;
      this.m_zOffSet = true;
    }
    let feetZ = bottom - this.LIFT;
    if ground && feetZ < gz && gap > -0.3 {
      feetZ = gz;
    }
    feetZ += this.m_zOff;
    let face = mech.GetWorldOrientation();
    let driving = this.m_walkSpeed > 0.0 && Vector4.Length(this.m_walkDir) > 0.01;
    if driving {
      if this.m_easeUntil > 0.0 || this.m_handAt > 0.0 {

        this.m_easeUntil = 0.0;
        this.m_handAt = 0.0;
        this.m_handSynced = false;
      }
    } else {
      if this.m_drivingWas {
        this.m_easeUntil = now + this.EASE;
        this.m_legs.Stop(mech, now);
      }
    }
    this.m_drivingWas = driving;
    let easing = !driving && now < this.m_easeUntil;
    if !driving && !easing && this.m_easeUntil > 0.0 {

      this.m_easeUntil = 0.0;
      this.m_handAt = now;
      this.m_handSynced = false;
      this.m_calm = 0;
    }
    if this.m_handAt > 0.0 {
      if !this.m_handSynced {
        if now - this.m_handAt >= this.HAND_STILL {
          this.SyncHere(mech, this.m_placed.W > 0.5 ? this.m_placed : at, face);
          this.m_handSynced = true;
        }
      } else {
        let wv = Vector4.Length(mech.GetVelocity());
        this.m_calm = wv < 1.0 ? this.m_calm + 1 : 0;
        if this.m_calm >= 3 || now - this.m_handAt > this.HAND_MAX {
          this.m_handAt = 0.0;
        }
      }
    }

    let carried = driving || easing || this.m_handAt > 0.0;
    this.m_pinAi = carried && !this.m_handSynced;
    this.blocked = false;
    this.m_setLast = false;
    if carried {

      let wantXY = driving ? this.m_walkDir * this.m_walkSpeed : new Vector4(0.0, 0.0, 0.0, 0.0);
      let dv = wantXY - this.m_feetVel;
      dv.Z = 0.0;
      dv.W = 0.0;
      let step = (driving ? this.ACCEL : this.DECEL) * dt;
      if Vector4.Length(dv) > step {
        dv = Vector4.Normalize(dv) * step;
      }
      this.m_feetVel = this.m_feetVel + dv;
      this.m_feetVel.Z = 0.0;
      this.m_feetVel.W = 0.0;
      if !driving && Vector4.Length(this.m_feetVel) < 0.05 {
        this.m_feetVel = new Vector4(0.0, 0.0, 0.0, 0.0);
      }
      let want = new Vector4(this.m_feetVel.X, this.m_feetVel.Y, v.Z, 0.0);

      let made = new Vector4(v.X, v.Y, 0.0, 0.0);
      let had = new Vector4(this.m_vel.X, this.m_vel.Y, 0.0, 0.0);
      if Vector4.Length(had) > 0.6 && Vector4.Dot(made, Vector4.Normalize(had)) < 0.5 * Vector4.Length(had) {
        this.m_heldT += dt;
        if this.m_heldT >= 0.2 {
          this.blocked = true;
          this.blockDir = Vector4.Normalize(this.m_feetVel);
          this.blockAt = new Vector4(p.X, p.Y, feetZ, 1.0);
        }
      } else {
        this.m_heldT = 0.0;
      }
      CMPhysPlugin.SetVelocity(body, want);
      this.m_vel = want;
      CMPhysStep.SetForce(body, a * this.MASS, new Vector4(0.0, 0.0, 0.0, 0.0));

      let placeAt = new Vector4(p.X, p.Y, feetZ - this.LEG_DROP, 1.0);
      if driving {
        this.m_legs.Tick(mech, this.m_action, now);
      }
      if this.m_faceDir.W > 0.5 && (driving || easing) {
        this.PlaceFacing(mech, placeAt, this.m_faceDir);
      } else {
        this.Place(mech, placeAt, face);
      }
      this.m_setLast = true;
    } else {

      let stride = new Vector4(0.0, 0.0, 0.0, 0.0);
      let sampled = false;
      let jumped = false;
      if this.m_lastAt.W > 0.5 && !this.m_lastSet {
        stride = new Vector4(at.X - this.m_lastAt.X, at.Y - this.m_lastAt.Y, 0.0, 0.0);
        sampled = true;
        if Vector4.Length(stride) > this.JUMP {

          jumped = true;
          stride = new Vector4(0.0, 0.0, 0.0, 0.0);
          sampled = false;
          if now >= this.m_resyncLogAt {
            this.m_resyncLogAt = now + 1.0;
          }
        }
      }

      let wild = Vector4.Length(mech.GetVelocity()) > 15.0;
      if wild {
        jumped = true;
        sampled = false;
        if now >= this.m_resyncLogAt {
          this.m_resyncLogAt = now + 1.0;
        }
      }
      if sampled {
        let sv = stride * (1.0 / dt);

        this.m_feetVel = this.m_feetVel + (sv - this.m_feetVel) * MinF(1.0, dt * 12.0);
        this.m_feetVel.Z = 0.0;
        this.m_feetVel.W = 0.0;
      }

      let off = new Vector4(at.X - p.X, at.Y - p.Y, 0.0, 0.0);
      let want = this.m_feetVel + off * this.W_FOLLOW;
      want.Z = 0.0;
      want.W = 0.0;
      if Vector4.Length(want) > 4.0 {
        want = Vector4.Normalize(want) * 4.0;
      }
      want.Z = v.Z;

      if Vector4.Length(off) > 0.5 {
        this.m_heldT += dt;
        if this.m_heldT >= 0.15 {
          this.blocked = true;
          this.blockDir = Vector4.Normalize(off);
          this.blockAt = new Vector4(p.X, p.Y, feetZ, 1.0);
        }
      } else {
        this.m_heldT = 0.0;
      }
      CMPhysPlugin.SetVelocity(body, want);
      this.m_vel = want;
      CMPhysStep.SetForce(body, a * this.MASS, new Vector4(0.0, 0.0, 0.0, 0.0));

      if jumped || this.blocked {
        this.Place(mech, new Vector4(p.X, p.Y, feetZ, 1.0), face);
        this.m_setLast = true;
        if now >= this.m_resyncAt {
          this.m_resyncAt = now + 0.3;
          this.SyncHere(mech, this.m_placed, face);
        }
      } else {
        if AbsF(at.Z - feetZ) > 0.2 {
          this.Place(mech, new Vector4(at.X, at.Y, feetZ, 1.0), face);
          this.m_setLast = true;
        }
      }
    }
    this.m_lastAt = this.m_setLast ? this.m_placed : at;
    this.m_lastAt.W = 1.0;
    this.m_lastSet = this.m_setLast;
    this.FootLog(mech, gz, carried ? (driving ? "walking" : "easing") : "standing", now);

    if !onLegs && this.m_offLegs >= 0.12 {
      if Vector4.Length(this.m_feetVel) > 0.3 {
        this.m_offDir = Vector4.Normalize(this.m_feetVel);
        this.m_offDir.W = 1.0;
      }
      this.Lead(mech, now, ground ? "walked off a drop (" + FloatToStringPrec(gap, 1) + " m)" : "nothing under it");
    }
  }

  private func FootLog(mech: ref<NPCPuppet>, gz: Float, mode: String, now: Float) -> Void {
    if now < this.m_footLogAt || gz < -99999.0 {
      return;
    }
    this.m_footLogAt = now + 1.0;
    if !CMPilotSystem.Get(mech.GetGame()).ShowDebug() {
      return;
    }

    let at = mech.GetWorldPosition();
  }
  private let m_footLogAt: Float;

  private let m_legZ: array<Float>;
  private let m_legAt: array<Vector4>;
  private let m_legFlip: Bool;
  private func LegsGround(p: Vector4, depth: Float) -> Float {
    if ArraySize(this.m_legZ) < 5 {
      ArrayResize(this.m_legZ, 5);
      ArrayResize(this.m_legAt, 5);
      let j = 0;
      while j < 5 {
        this.m_legZ[j] = -100000.0;
        this.m_legAt[j] = new Vector4(0.0, 0.0, -100000.0, 1.0);
        j += 1;
      }
    }
    this.m_legFlip = !this.m_legFlip;
    let best = -100000.0;
    let i = 0;
    while i < 5 {
      let cast = i == 0 || (this.m_legFlip ? (i == 1 || i == 4) : (i == 2 || i == 3));
      if cast {
        let ox = i == 0 ? 0.0 : ((i == 1 || i == 3) ? 0.8 : -0.8);
        let oy = i == 0 ? 0.0 : (i <= 2 ? 0.8 : -0.8);
        let hit: TraceResult;
        this.m_legAt[i] = p;
        if CMGround.Down(this.m_game, new Vector4(p.X + ox, p.Y + oy, p.Z + this.HALF_Z, 1.0), new Vector4(p.X + ox, p.Y + oy, p.Z - depth, 1.0), hit) {
          this.m_legZ[i] = Cast<Vector4>(hit.position).Z;
        } else {
          this.m_legZ[i] = -100000.0;
        }
      }
      if Vector4.Distance2D(this.m_legAt[i], p) < 0.5 {
        best = MaxF(best, this.m_legZ[i]);
      }
      i += 1;
    }
    return best;
  }

  public func SyncHere(mech: ref<NPCPuppet>, at: Vector4, q: Quaternion) -> Void {
    this.m_heldFwd = CMFlight.QRot(q, new Vector4(0.0, 1.0, 0.0, 0.0));
    this.m_placed = at;
    this.m_placed.W = 1.0;
    this.Sync(mech);
  }

  public func SetLegs(action: Int32) -> Void {
    this.m_action = action;
  }

  public func SetFacing(dir: Vector4) -> Void {
    this.m_faceDir = new Vector4(dir.X, dir.Y, 0.0, 1.0);
  }

  public func SetWalk(dir: Vector4, speed: Float) -> Void {
    this.m_walkDir = new Vector4(dir.X, dir.Y, 0.0, 0.0);
    if Vector4.Length(this.m_walkDir) > 0.01 {
      this.m_walkDir = Vector4.Normalize(this.m_walkDir);
    }
    this.m_walkSpeed = speed;
  }

  private func Leading(mech: ref<NPCPuppet>, body: ref<PhysicalBodyInterface>, p: Vector4, v: Vector4, dt: Float, now: Float) -> Void {
    let bottom = p.Z - this.HALF_Z;
    let gz = this.LegsGround(p, 120.0);
    let ground = gz > -99999.0;

    if ground {
      this.m_noGround = 0.0;
    } else {
      this.m_noGround += dt;
      if this.m_noGround >= 0.6 {
        this.Rescue(mech, now);
        return;
      }
    }
    let gap = bottom - gz;
    this.m_gap = ground ? gap : -1.0;
    let onLegs = ground && gap < this.LIFT + 0.05;
    let a = new Vector4(0.0, 0.0, 0.0, 0.0);
    if onLegs {
      a.Z = this.G + this.W_LEG * this.W_LEG * (this.LIFT - gap) - 2.0 * this.LEG_DAMP * this.W_LEG * v.Z;
    }
    let vh = new Vector4(v.X, v.Y, 0.0, 0.0);

    let staggering = now < this.m_staggerUntil;
    if onLegs {
      a.X -= vh.X * this.FRICTION;
      a.Y -= vh.Y * this.FRICTION;
    } else {

      if this.m_offDir.W > 0.5 && now - this.m_ledAt < 0.8 {
        let along = Vector4.Dot(vh, this.m_offDir);
        if along < 2.5 {
          a.X += this.m_offDir.X * (2.5 - along) * 6.0;
          a.Y += this.m_offDir.Y * (2.5 - along) * 6.0;
        }
      }
    }
    this.m_airborne = !onLegs;
    CMPhysStep.SetForce(body, a * this.MASS, new Vector4(0.0, 0.0, 0.0, 0.0));

    if onLegs {
      if this.m_air > 0.25 && this.m_fallVz < -1.0 {
        this.landing = -this.m_fallVz;

        if this.landing >= this.STAGGER_AT {
          this.m_staggerUntil = now + this.STAGGER_T;
          staggering = true;
          this.m_fallPose = false;
          this.m_legs.Pose(mech, n"StaggerFront", 1, 0.0, now);
        }
      }
      this.m_air = 0.0;
      this.m_fallVz = 0.0;
      this.m_safe = new Vector4(p.X, p.Y, gz, 1.0);
    } else {
      this.m_air += dt;
      this.m_fallVz = MinF(this.m_fallVz, v.Z);
    }
    this.m_vel = v;

    let feet = new Vector4(p.X, p.Y, bottom - this.LIFT, 1.0);

    if ground && feet.Z < gz && gap > -0.3 {
      feet.Z = gz;
    }
    feet.Z += this.m_zOff;
    this.Place(mech, feet, this.m_heldQ);

    if !onLegs && this.m_air > 0.15 && !this.m_fallPose {
      this.m_fallPose = true;
      this.m_legs.Pose(mech, n"MNC_FallBrace", 2, -1.0, now);
    }

    if onLegs && !staggering && this.m_legs.Posed() {
      this.m_fallPose = false;
      this.m_legs.Clear(mech, now);
    }

    if onLegs && !staggering && Vector4.Length(v) < 0.6 {
      this.m_still += dt;
    } else {
      this.m_still = 0.0;
    }

    if this.m_syncAt > 0.0 || this.m_still >= this.SETTLE {
      let wv = Vector4.Length(mech.GetVelocity());
      if this.m_syncAt <= 0.0 || now - this.m_syncAt > 1.0 {
        if this.m_syncAt > 0.0 {
        }
        this.Sync(mech);
        this.m_syncAt = now;
      } else {
        if now - this.m_syncAt >= 0.2 && wv < 6.0 {
          this.HandBack(mech, "settled", false);
        }
      }
    } else {
      if now - this.m_ledAt > 20.0 {
        this.HandBack(mech, "led for 20 s", true);
      }
    }
  }

  private func Sync(mech: ref<NPCPuppet>) -> Void {
    let ai = mech.GetAIControllerComponent();
    if !IsDefined(ai) {
      return;
    }
    if this.m_aiIsOff {
      ai.Toggle(true);
      this.m_aiIsOff = false;
    }
    let at = this.m_placed.W > 0.5 ? this.m_placed : mech.GetWorldPosition();
    let tp = new AITeleportCommand();
    tp.position = new Vector4(at.X, at.Y, at.Z, 1.0);
    tp.rotation = CMPilotRig.YawOf(this.m_heldFwd);
    tp.doNavTest = false;
    ai.SendCommand(tp);
  }

  private func Place(mech: ref<NPCPuppet>, feet: Vector4, q: Quaternion) -> Void {
    this.PinAi(mech);
    let wt: WorldTransform;
    let world: WorldPosition;
    WorldPosition.SetVector4(world, feet);
    WorldTransform.SetWorldPosition(wt, world);
    WorldTransform.SetOrientation(wt, q);
    mech.SetWorldTransform(wt);
    this.m_placed = feet;
    this.m_placed.W = 1.0;
  }

  private func PlaceFacing(mech: ref<NPCPuppet>, feet: Vector4, dir: Vector4) -> Void {
    this.PinAi(mech);
    let wt: WorldTransform;
    let world: WorldPosition;
    WorldPosition.SetVector4(world, feet);
    WorldTransform.SetWorldPosition(wt, world);
    WorldTransform.SetOrientationFromDir(wt, new Vector4(dir.X, dir.Y, 0.0, 0.0));
    mech.SetWorldTransform(wt);
    this.m_placed = feet;
    this.m_placed.W = 1.0;
  }

  private func PinAi(mech: ref<NPCPuppet>) -> Void {
    if ((this.led && this.m_syncAt <= 0.0) || this.m_pinAi) && !this.m_aiIsOff {
      let ai = mech.GetAIControllerComponent();
      if IsDefined(ai) {
        ai.Toggle(false);
        this.m_aiIsOff = true;
      }
    }
  }

  private func Upright(body: ref<PhysicalBodyInterface>, q: Quaternion) -> Void {
    let up = CMFlight.QRot(q, new Vector4(0.0, 0.0, 1.0, 0.0));
    let fwd = CMFlight.QRot(q, new Vector4(0.0, 1.0, 0.0, 0.0));
    let want = this.m_heldFwd;
    if !this.led {
      let mech = this.m_mechRef;
      if IsDefined(mech) {
        want = mech.GetWorldForward();
      }
    }

    let w = new Vector4(up.Y, -up.X, 0.0, 0.0) * (this.m_airborne ? 2.0 : this.SPIN_K);
    let fh = new Vector4(fwd.X, fwd.Y, 0.0, 0.0);
    let th = new Vector4(want.X, want.Y, 0.0, 0.0);
    if Vector4.Length(fh) > 0.1 && Vector4.Length(th) > 0.1 {
      fh = Vector4.Normalize(fh);
      th = Vector4.Normalize(th);
      let turn = AtanF(fh.X * th.Y - fh.Y * th.X, fh.X * th.X + fh.Y * th.Y);
      w.Z = ClampF(turn * this.SPIN_K, -3.0, 3.0);
    }
    CMPhysPlugin.SetSpin(body, w);
  }

  public func Lead(mech: ref<NPCPuppet>, now: Float, reason: String) -> Void {
    if !this.m_live || this.led {
      return;
    }
    this.led = true;
    this.why = reason;
    this.m_ledAt = now;
    this.m_still = 0.0;
    this.m_air = 0.0;
    this.m_fallVz = 0.0;
    this.m_syncAt = 0.0;
    this.m_placed = new Vector4(0.0, 0.0, 0.0, 0.0);
    this.m_heldQ = mech.GetWorldOrientation();
    this.m_heldFwd = mech.GetWorldForward();

    this.m_legs.Stop(mech, now);
    this.m_fallPose = false;
    this.m_drivingWas = false;
    this.m_easeUntil = 0.0;
    this.m_handAt = 0.0;
  }

  public func Push(mech: ref<NPCPuppet>, dv: Vector4, now: Float, reason: String) -> Void {
    if !this.m_live || !IsDefined(this.m_body) {
      return;
    }
    let v = CMPhysStep.Velocity(this.m_body);
    v.W = 0.0;
    CMPhysPlugin.SetVelocity(this.m_body, v + dv);
    this.m_vel = v + dv;
    this.knock = Vector4.Length(dv);
    this.Lead(mech, now, reason);
  }

  private func Rescue(mech: ref<NPCPuppet>, now: Float) -> Void {
    this.m_placed = this.m_safe.W > 0.5 ? this.m_safe : this.m_placed;
    this.HandBack(mech, "rescued", true);
    let e = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_id);
    if IsDefined(e) {
      let body = this.Body(e);
      if IsDefined(body) {
        CMPhysStep.Release(body);
      }
    }
    GameInstance.GetDynamicEntitySystem().DeleteEntity(this.m_id);
    this.m_live = false;
    this.m_spawned = false;
    this.m_body = null;
    this.m_askedAt = now;
    this.m_noGround = 0.0;
  }

  private func HandBack(mech: ref<NPCPuppet>, reason: String, sync: Bool) -> Void {
    if sync {
      this.Sync(mech);
    }
    this.m_legs.Clear(mech, this.m_now);
    this.m_fallPose = false;
    this.led = false;
    this.m_still = 0.0;
    this.m_syncAt = 0.0;
    this.m_offDir = new Vector4(0.0, 0.0, 0.0, 0.0);
    this.m_airborne = false;
    this.m_offLegs = 0.0;
    this.m_lastAt = new Vector4(0.0, 0.0, 0.0, 0.0);
    this.m_lastSet = false;
    this.m_feetVel = new Vector4(0.0, 0.0, 0.0, 0.0);
    this.m_placed = new Vector4(0.0, 0.0, 0.0, 0.0);
    this.m_drivingWas = false;
    this.m_easeUntil = 0.0;
  }

  private func TryLive(mech: ref<NPCPuppet>, now: Float) -> Void {
    this.m_mechRef = mech;
    if !this.m_spawned {
      if now - this.m_askedAt >= 0.25 {
        this.Spawn(mech, now);
      }
      return;
    }
    let e = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_id);
    if !IsDefined(e) || Vector4.Length(e.GetWorldPosition()) < 1.0 {
      if now - this.m_askedAt > 10.0 {

        this.Stop(mech);
        this.failed = true;
      }
      return;
    }
    let body = this.Body(e);
    if !IsDefined(body) || !body.IsSimulated() {
      return;
    }
    this.m_live = true;
    this.m_vel = new Vector4(0.0, 0.0, 0.0, 0.0);
    CMPhysPlugin.SetVelocity(body, this.m_vel);
  }

  private func Spawn(mech: ref<NPCPuppet>, now: Float) -> Void {
    let spec = new DynamicEntitySpec();
    spec.templatePath = r"mnc\\physics\\proxy_minotaur.ent";
    spec.position = this.Target(mech.GetWorldPosition());
    spec.orientation = mech.GetWorldOrientation();
    spec.persistState = false;
    spec.persistSpawn = false;
    spec.alwaysSpawned = true;
    spec.tags = [n"MNCPhysMech"];
    this.m_id = GameInstance.GetDynamicEntitySystem().CreateEntity(spec);
    this.m_spawned = true;
    this.m_live = false;
    this.m_askedAt = now;
  }

  private func Body(e: ref<Entity>) -> ref<PhysicalBodyInterface> {
    if IsDefined(this.m_body) && this.m_body.IsSimulated() {
      return this.m_body;
    }
    let c = e.FindComponentByName(n"proxy_body") as ColliderComponent;
    if IsDefined(c) {
      this.m_body = c.CreatePhysicalBodyInterface();
    }
    return this.m_body;
  }

  private func OwnBodiesOff() -> Void {
    for b in this.m_ownBodies {
      if IsDefined(b) {
        CMPhysColl.SetCollision(b, false);
      }
    }
  }

  private func Collisions(mech: ref<NPCPuppet>, on: Bool) -> Void {
    if !on {
      ArrayClear(this.m_offColliders);
      ArrayClear(this.m_offMeshes);
      ArrayClear(this.m_ownBodies);
      ArrayClear(this.m_keptColliders);
      for c in mech.GetComponents() {

        if c.IsA(n"entColliderComponent") || c.IsA(n"entSimpleColliderComponent") {
          if c.IsEnabled() {
            let cc = c as ColliderComponent;
            let cb: ref<PhysicalBodyInterface>;
            if IsDefined(cc) {
              cb = cc.CreatePhysicalBodyInterface();
            }
            if IsDefined(cb) {
              ArrayPush(this.m_ownBodies, cb);
              ArrayPush(this.m_keptColliders, c);
            } else {
              c.Toggle(false);
              ArrayPush(this.m_offColliders, c);
            }
          }
        } else {
          if c.IsA(n"entPhysicalMeshComponent") {
            let pm = c as PhysicalMeshComponent;
            if CMUDrone.MeshCollision(c, false) {
              ArrayPush(this.m_offMeshes, c);
            }
            if IsDefined(pm) {
              let b = pm.CreatePhysicalBodyInterface();
              if IsDefined(b) {
                ArrayPush(this.m_ownBodies, b);
              }
            }
          } else {
            if c.IsA(n"entPhysicalSkinnedMeshComponent") {
              let sb = CMPhysBodies.Of(c);
              if !IsDefined(sb) {
                sb = CMUDrone.SkinnedBody(c);
              }
              if IsDefined(sb) {
                ArrayPush(this.m_ownBodies, sb);
              }
            }
          }
        }
      }
      return;
    }
    for c in this.m_offColliders {
      if IsDefined(c) {
        c.Toggle(true);
      }
    }
    for c in this.m_offMeshes {
      if IsDefined(c) {
        CMUDrone.MeshCollision(c, true);
      }
    }
    ArrayClear(this.m_offColliders);
    ArrayClear(this.m_offMeshes);
  }

  public func Gap() -> Float = this.m_gap
}
