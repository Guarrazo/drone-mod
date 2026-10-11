module ControllableMechs.Control

import ControllableMechs.*

public abstract class CMCUnit extends IScriptable {

  public func Begin(s: ref<CMCSession>) -> String = "!" + CMText.UnitNoUnit()

  public func End(s: ref<CMCSession>, hard: Bool) -> Void {}

  public func IsAlive() -> Bool = false
  public func LostReason() -> String = "!" + CMText.UnitLost()

  public func Ground() -> Vector4 = new Vector4(0.0, 0.0, 0.0, 1.0)
  public func Facing() -> Float = 0.0
  public func SensorUp() -> Float = 2.0
  public func SensorFwd() -> Float = 0.0

  public func AimSkip() -> Float = 1.0

  public func Tick(s: ref<CMCSession>, dt: Float, now: Float) -> Void {}

  public func SlowTick(s: ref<CMCSession>, now: Float) -> String = ""

  public func Hud(s: ref<CMCSession>, state: ref<CMPilotHudState>) -> Void {}

  public func Secondary(s: ref<CMCSession>) -> Void {}

  public func Select(s: ref<CMCSession>) -> Bool = false

  public func Hold(s: ref<CMCSession>) -> Void {}

  public func Track(s: ref<CMCSession>) -> Void {}

  public func HasCounter() -> Bool = false
  public func Counter(s: ref<CMCSession>) -> Void {}

  public func HasExtras() -> Bool = false
  public func Lights(s: ref<CMCSession>) -> Bool = false
  public func Jump(s: ref<CMCSession>) -> Bool = false
  public func ShieldKey(s: ref<CMCSession>) -> Bool = false

  public func TakeHit(s: ref<CMCSession>, hit: ref<gameHitEvent>) -> Void {}

  public func OpticsOnline() -> Bool = true

  public func CamTilt() -> Vector4 = new Vector4(0.0, 0.0, 0.0, 0.0)
  public func StepWeight() -> Float = 1.0

  public func LightLook() -> Bool = false

  public func CamProfile() -> String = "mech"

  public func TickFirst() -> Bool = false

  public func NewHud() -> ref<CMPilotHud> = new CMPilotHud()
  public func Name() -> String = CMText.UnitName()

  public func ScreenAt(s: ref<CMCSession>, p: Vector4) -> Vector2 {
    let e: EulerAngles;
    e.Yaw = s.rig.yaw;
    e.Pitch = s.rig.pitch;
    e.Roll = s.rig.roll;
    let d = CMFlight.QInvRot(EulerAngles.ToQuat(e), p - s.rig.pos);
    if d.Y < 0.5 {
      return Vector2(9999.0, 9999.0);
    }
    let scale = 1080.0 / TanF(Deg2Rad(s.rig.fov * 0.5));
    return Vector2(d.X / d.Y * scale, -d.Z / d.Y * scale);
  }

  public func SignalLost() -> Bool = false
}
