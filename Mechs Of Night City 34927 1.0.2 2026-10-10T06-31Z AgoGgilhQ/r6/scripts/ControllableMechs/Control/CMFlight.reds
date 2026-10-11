module ControllableMechs.Control

import ControllableMechs.*

public class CMFlightProfile {
  public let mass: Float;
  public let arm: Float;
  public let thrust: Float;
  public let spool: Float;
  public let kq: Float;
  public let agility: Float;
  public let tilt: Float;
  public let tiltRate: Float;
  public let yawRate: Float;
  public let climb: Float;
  public let cdh: Float;
  public let cdv: Float;
  public let flap: Float;
  public let impact: Float;
  public let com: Float;
  public let bottom: Float;
  public let span: Float;
  public let ramp: Float;
  public let expo: Float;
  public let showTilt: Float;
}

public class CMFlight {
  public let pos: Vector4;
  public let vel: Vector4;
  public let q: Quaternion;
  public let w: Vector4;
  public let spool: array<Float>;
  public let eff: array<Float>;
  public let level: Float;
  public let holdZ: Float;
  public let holding: Bool;
  public let grounded: Bool;
  public let groundGain: Float;
  public let failing: Int32;
  public let limp: Float;
  public let clock: Float;
  public let outForce: Vector4;
  public let outTorque: Vector4;
  public let wind: Vector4;

  public let p: ref<CMFlightProfile>;

  public let yaw: Float;
  public let pitch: Float;
  public let roll: Float;

  public static func Make(p: ref<CMFlightProfile>, pos: Vector4, yaw: Float) -> ref<CMFlight> {
    let f = new CMFlight();
    f.p = p;
    f.pos = pos;
    f.vel = new Vector4(0.0, 0.0, 0.0, 0.0);
    f.w = new Vector4(0.0, 0.0, 0.0, 0.0);
    let half = Deg2Rad(yaw) * 0.5;
    f.q.i = 0.0;
    f.q.j = 0.0;
    f.q.k = SinF(half);
    f.q.r = CosF(half);
    let hover = ClampF(p.mass * 9.81 / (4.0 * p.thrust), 0.0, 1.0);
    let i = 0;
    while i < 4 {
      ArrayPush(f.spool, hover);
      ArrayPush(f.eff, 1.0);
      i += 1;
    }
    f.holdZ = pos.Z;
    f.holding = true;
    f.limp = 1.0;
    f.groundGain = 1.0;
    f.wind = new Vector4(0.0, 0.0, 0.0, 0.0);
    f.Angles();
    return f;
  }

  public func SetGround(height: Float) -> Void {
    if height < 0.0 {
      this.groundGain = 1.0;
      return;
    }
    let q = this.p.span * 0.8 / (4.0 * MaxF(0.05, height));
    this.groundGain = q >= 0.9 ? 1.2 : MinF(1.2, 1.0 / (1.0 - q * q));
  }

  public static func QMul(a: Quaternion, b: Quaternion) -> Quaternion {
    let o: Quaternion;
    o.r = a.r * b.r - a.i * b.i - a.j * b.j - a.k * b.k;
    o.i = a.r * b.i + a.i * b.r + a.j * b.k - a.k * b.j;
    o.j = a.r * b.j - a.i * b.k + a.j * b.r + a.k * b.i;
    o.k = a.r * b.k + a.i * b.j - a.j * b.i + a.k * b.r;
    return o;
  }

  public static func QRot(q: Quaternion, v: Vector4) -> Vector4 {
    let tx = 2.0 * (q.j * v.Z - q.k * v.Y);
    let ty = 2.0 * (q.k * v.X - q.i * v.Z);
    let tz = 2.0 * (q.i * v.Y - q.j * v.X);
    return new Vector4(v.X + q.r * tx + (q.j * tz - q.k * ty), v.Y + q.r * ty + (q.k * tx - q.i * tz), v.Z + q.r * tz + (q.i * ty - q.j * tx), 0.0);
  }

  public static func QInvRot(q: Quaternion, v: Vector4) -> Vector4 {
    let c: Quaternion;
    c.i = -q.i;
    c.j = -q.j;
    c.k = -q.k;
    c.r = q.r;
    return CMFlight.QRot(c, v);
  }

  public static func Cross(a: Vector4, b: Vector4) -> Vector4 = new Vector4(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X, 0.0)

  public func Up() -> Vector4 = CMFlight.QRot(this.q, new Vector4(0.0, 0.0, 1.0, 0.0))
  public func Forward() -> Vector4 = CMFlight.QRot(this.q, new Vector4(0.0, 1.0, 0.0, 0.0))
  public func Right() -> Vector4 = CMFlight.QRot(this.q, new Vector4(1.0, 0.0, 0.0, 0.0))

  public func Ix() -> Float = this.p.mass * this.p.arm * this.p.arm * 0.5
  public func Iz() -> Float = this.p.mass * this.p.arm * this.p.arm * 0.8

  public func Step(dt: Float, fwd: Float, side: Float, c: Float, view: Float) -> Void {
    let p = this.p;
    let m = p.mass;
    this.clock += dt;

    if this.failing >= 2 {
      fwd *= 0.2;
      side *= 0.2;
    }
    let stick = SqrtF(fwd * fwd + side * side);
    if stick > 1.0 {
      fwd /= stick;
      side /= stick;
    }
    let up = this.Up();
    let heading = this.yaw;

    let rate = Deg2Rad(p.tiltRate);
    let acroX = -fwd * rate;
    let acroY = side * rate;

    let hy = Deg2Rad(heading) * 0.5;
    let tp = Deg2Rad(-fwd * p.tilt) * 0.5;
    let tr = Deg2Rad(side * p.tilt) * 0.5;
    let qy: Quaternion;
    qy.k = SinF(hy);
    qy.r = CosF(hy);
    let qp: Quaternion;
    qp.i = SinF(tp);
    qp.r = CosF(tp);
    let qr: Quaternion;
    qr.j = SinF(tr);
    qr.r = CosF(tr);
    let wantUp = CMFlight.QRot(CMFlight.QMul(CMFlight.QMul(qy, qp), qr), new Vector4(0.0, 0.0, 1.0, 0.0));
    let err = CMFlight.QInvRot(this.q, CMFlight.Cross(up, wantUp));
    let ka = p.agility * 0.4;
    let wantX = acroX + (err.X * ka - acroX) * this.level;
    let wantY = acroY + (err.Y * ka - acroY) * this.level;
    let dyaw = CMPilotRig.Wrap(view - heading);
    let wantZ = Deg2Rad(ClampF(dyaw * 5.0, -p.yawRate, p.yawRate));

    let ix = this.Ix();
    let iz = this.Iz();
    let tx = ix * p.agility * (wantX - this.w.X);
    let ty = ix * p.agility * (wantY - this.w.Y);
    let tz = iz * p.agility * 0.5 * (wantZ - this.w.Z);

    let az: Float;
    if this.grounded && c <= 0.05 {

      this.holding = true;
      this.holdZ = this.pos.Z;
      az = -1.0;
    } else if AbsF(c) > 0.05 {
      this.holding = false;
      az = (c * p.climb - this.vel.Z) * 1.6;
    } else {
      if !this.holding {
        this.holding = true;
        this.holdZ = this.pos.Z + this.vel.Z * 0.6;
      }
      az = (this.holdZ - this.pos.Z) * 0.8 - this.vel.Z;
    }

    let tc = up.Z > 0.3 ? m * (9.81 + az) / up.Z : m * 9.81 * 0.6;

    let d = p.arm * 0.7071;
    let base = tc * 0.25;
    let px = tx / (4.0 * d);
    let py = ty / (4.0 * d);
    let pz = tz / (4.0 * p.kq);

    let cmd: array<Float> = [(base + px + py + pz) / p.thrust, (base + px - py - pz) / p.thrust, (base - px + py - pz) / p.thrust, (base - px - py + pz) / p.thrust];

    let ci = 0;
    while ci < 4 {
      if this.eff[ci] > 0.05 && this.eff[ci] < 1.0 {
        cmd[ci] = cmd[ci] / this.eff[ci];
      }
      ci += 1;
    }
    let lo = MinF(MinF(cmd[0], cmd[1]), MinF(cmd[2], cmd[3]));
    let hi = MaxF(MaxF(cmd[0], cmd[1]), MaxF(cmd[2], cmd[3]));
    let i = 0;
    while i < 4 {

      if hi - lo > 1.0 {
        cmd[i] = (cmd[i] - lo) / (hi - lo);
      } else {
        if hi > 1.0 {
          cmd[i] -= hi - 1.0;
        } else {
          if lo < 0.0 {
            cmd[i] -= lo;
          }
        }
      }
      this.spool[i] += (cmd[i] - this.spool[i]) * MinF(1.0, dt / MaxF(0.01, p.spool));
      i += 1;
    }
    let tg = p.thrust * this.groundGain;
    let t0 = this.spool[0] * this.eff[0] * tg;
    let t1 = this.spool[1] * this.eff[1] * tg;
    let t2 = this.spool[2] * this.eff[2] * tg;
    let t3 = this.spool[3] * this.eff[3] * tg;

    let bx = d * (t0 + t1 - t2 - t3);
    let by = d * (t0 - t1 + t2 - t3);
    let bz = p.kq * (t0 - t1 - t2 + t3);

    let air = this.vel - this.wind;
    let vb = CMFlight.QInvRot(this.q, air);
    bx += p.flap * vb.Y;
    by -= p.flap * vb.X;

    let damp = this.grounded ? 8.0 : 1.5;
    bx -= ix * damp * this.w.X;
    by -= ix * damp * this.w.Y;
    bz -= iz * (this.grounded ? 4.0 : 1.0) * this.w.Z;

    if !this.grounded && this.failing == 1 {
      bx += ix * 0.55 * this.limp * SinF(this.clock * 3.1);
      by += ix * 0.4 * this.limp * SinF(this.clock * 2.3 + 1.0);
      bz += iz * 0.25 * this.limp;
      bx -= ix * 1.5 * this.w.X;
      by -= ix * 1.5 * this.w.Y;
      bz -= iz * 1.0 * this.w.Z;
    }
    if !this.grounded && this.failing >= 2 {
      bz += iz * 6.0;
      bx += ix * 1.5 * SinF(this.clock * 4.0);
      by += ix * 1.5 * SinF(this.clock * 3.3 + 0.7);
    }

    let fe = CMFlight.QRot(this.q, new Vector4(0.0, 0.0, t0 + t1 + t2 + t3, 0.0));
    let dragE = new Vector4(-0.6 * p.cdh * vb.X * AbsF(vb.X), -0.6 * p.cdh * vb.Y * AbsF(vb.Y), -0.6 * p.cdv * vb.Z * AbsF(vb.Z), 0.0);
    fe += CMFlight.QRot(this.q, dragE);
    fe -= air * (0.05 * m);
    this.outForce = fe;
    this.outTorque = new Vector4(bx, by, bz, 0.0);
    this.Angles();
  }

  public func Sync() -> Void {
    this.Angles();
  }

  private func Angles() -> Void {
    let f = this.Forward();
    let r = this.Right();

    this.yaw = CMPilotRig.Wrap(Rad2Deg(2.0 * AtanF(this.q.k, this.q.r)));
    this.pitch = Rad2Deg(AsinF(ClampF(f.Z, -1.0, 1.0)));
    this.roll = Rad2Deg(AsinF(ClampF(-r.Z, -1.0, 1.0)));
  }

  public func Shown(limit: Float) -> Quaternion {
    if limit >= 89.0 {
      return this.q;
    }

    let h = Deg2Rad(this.yaw) * 0.5;
    let tw: Quaternion;
    tw.k = SinF(h);
    tw.r = CosF(h);
    let twi: Quaternion;
    twi.k = -tw.k;
    twi.r = tw.r;
    let sw = CMFlight.QMul(this.q, twi);
    if sw.r < 0.0 {
      sw.i = -sw.i;
      sw.j = -sw.j;
      sw.k = -sw.k;
      sw.r = -sw.r;
    }
    let s = SqrtF(sw.i * sw.i + sw.j * sw.j + sw.k * sw.k);
    let lim = Deg2Rad(MaxF(0.0, limit));
    if 2.0 * AtanF(s, sw.r) > lim && s > 0.00001 {
      let k = SinF(lim * 0.5) / s;
      sw.i *= k;
      sw.j *= k;
      sw.k *= k;
      sw.r = CosF(lim * 0.5);
    }
    return CMFlight.QMul(sw, tw);
  }

  public func Spool() -> Float = (this.spool[0] + this.spool[1] + this.spool[2] + this.spool[3]) * 0.25
}

public abstract class CMDroneProfiles {

  public static func DefaultLevel(kind: String) -> Int32 {
    switch kind {
      case "bombus": return 65;
      case "octant": return 95;
    }
    return 85;
  }

  public static func For(kind: String) -> ref<CMFlightProfile> {
    let p = new CMFlightProfile();
    switch kind {
      case "bombus":

        p.mass = 6.0; p.arm = 0.2; p.thrust = 30.0; p.spool = 0.06; p.kq = 0.02; p.agility = 11.0;
        p.tilt = 61.0; p.tiltRate = 45.0; p.yawRate = 200.0; p.climb = 5.0;
        p.cdh = 0.3; p.cdv = 0.45; p.flap = 0.06; p.impact = 6.0; p.com = 0.13;

        p.bottom = 0.134; p.span = 0.27; p.ramp = 0.3; p.expo = 0.6; p.showTilt = 90.0;
        break;
      case "octant":
        p.mass = 180.0; p.arm = 1.0; p.thrust = 900.0; p.spool = 0.14; p.kq = 0.08; p.agility = 4.5;
        p.tilt = 20.0; p.tiltRate = 90.0; p.yawRate = 60.0; p.climb = 3.0;
        p.cdh = 10.7; p.cdv = 16.0; p.flap = 2.0; p.impact = 5.0; p.com = 0.15;

        p.bottom = 0.91; p.span = 1.4; p.ramp = 0.2; p.expo = 0.3; p.showTilt = 90.0;
        break;
      default:
        p.mass = 40.0; p.arm = 0.45; p.thrust = 190.0; p.spool = 0.10; p.kq = 0.04; p.agility = 9.0;
        p.tilt = 22.0; p.tiltRate = 120.0; p.yawRate = 110.0; p.climb = 4.0;
        p.cdh = 1.9; p.cdv = 2.8; p.flap = 0.35; p.impact = 5.5; p.com = Equals(kind, "wyvern") ? 0.22 : 0.0;

        p.bottom = Equals(kind, "wyvern") ? 0.227 : 0.474; p.span = Equals(kind, "wyvern") ? 0.5 : 0.62; p.ramp = 0.2; p.expo = 0.3; p.showTilt = 90.0;
    }
    return p;
  }
}
