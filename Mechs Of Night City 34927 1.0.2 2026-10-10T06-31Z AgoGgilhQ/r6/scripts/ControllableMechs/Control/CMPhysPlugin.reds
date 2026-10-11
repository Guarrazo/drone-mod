module ControllableMechs.Control

@if(ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysPlugin {
  public static func Present() -> Bool = MNCPhysics_Version() > 0
  public static func Version() -> Int32 = MNCPhysics_Version()
  public static func HasVelocity() -> Bool = MNCPhysics_Version() >= 2
  public static func SetVelocity(body: ref<PhysicalBodyInterface>, v: Vector4) -> Bool = MNCPhysics_SetLinearVelocity(body, v)
  public static func SetSpin(body: ref<PhysicalBodyInterface>, w: Vector4) -> Bool = MNCPhysics_SetAngularVelocity(body, w)
}

@if(!ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysPlugin {
  public static func Present() -> Bool = false
  public static func Version() -> Int32 = 0
  public static func HasVelocity() -> Bool = false
  public static func SetVelocity(body: ref<PhysicalBodyInterface>, v: Vector4) -> Bool = false
  public static func SetSpin(body: ref<PhysicalBodyInterface>, w: Vector4) -> Bool = false
}

@if(ModuleExists("MNCPhysics.Plugin"))
public abstract class CMWatch {
  public static func Mark(stage: String) -> Void {
    MNCPhysics_Mark(stage);
  }
}

@if(!ModuleExists("MNCPhysics.Plugin"))
public abstract class CMWatch {
  public static func Mark(stage: String) -> Void {}
}

@if(ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysStep {
  public static func Present() -> Bool = true
  public static func SetForce(body: ref<PhysicalBodyInterface>, force: Vector4, torque: Vector4) -> Bool = MNCPhysics_SetForce(body, force, torque)
  public static func Release(body: ref<PhysicalBodyInterface>) -> Bool = MNCPhysics_Release(body)
  public static func Velocity(body: ref<PhysicalBodyInterface>) -> Vector4 = MNCPhysics_StepVelocity(body)
  public static func Spin(body: ref<PhysicalBodyInterface>) -> Vector4 = MNCPhysics_StepSpin(body)
  public static func Info(body: ref<PhysicalBodyInterface>) -> String = MNCPhysics_StepInfo(body)
}

@if(!ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysStep {
  public static func Present() -> Bool = false
  public static func SetForce(body: ref<PhysicalBodyInterface>, force: Vector4, torque: Vector4) -> Bool = false
  public static func Release(body: ref<PhysicalBodyInterface>) -> Bool = false
  public static func Velocity(body: ref<PhysicalBodyInterface>) -> Vector4 = new Vector4(0.0, 0.0, 0.0, 0.0)
  public static func Spin(body: ref<PhysicalBodyInterface>) -> Vector4 = new Vector4(0.0, 0.0, 0.0, 0.0)
  public static func Info(body: ref<PhysicalBodyInterface>) -> String = "MNC Physics version 3 not installed"
}

@if(ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysColl {
  public static func Present() -> Bool = true
  public static func SetCollision(body: ref<PhysicalBodyInterface>, on: Bool) -> Bool = MNCPhysics_SetCollision(body, on)
}

@if(!ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysColl {
  public static func Present() -> Bool = false
  public static func SetCollision(body: ref<PhysicalBodyInterface>, on: Bool) -> Bool = false
}

@if(ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysBodies {
  public static func Present() -> Bool = true
  public static func Of(c: ref<IComponent>) -> ref<PhysicalBodyInterface> = MNCPhysics_ComponentBody(c, 0)
}

@if(!ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysBodies {
  public static func Present() -> Bool = false
  public static func Of(c: ref<IComponent>) -> ref<PhysicalBodyInterface> = null
}

@if(ModuleExists("CyberpunkWindFramework"))
public abstract class CMPhysWind {
  public static func IgnoreNear(id: Int32, position: Vector4, radius: Float) -> Void {
    CWF_IgnoreNear(id, position, radius);
  }
}

@if(!ModuleExists("CyberpunkWindFramework"))
public abstract class CMPhysWind {
  public static func IgnoreNear(id: Int32, position: Vector4, radius: Float) -> Void {}
}

@if(ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysSoundWatch {
  public static func Watch(on: Bool, drone: Vector4, speed: Float, accel: Float) -> Void {
    MNCPhysics_AudioWatch(on, drone, speed, accel);
  }
}

@if(!ModuleExists("MNCPhysics.Plugin"))
public abstract class CMPhysSoundWatch {
  public static func Watch(on: Bool, drone: Vector4, speed: Float, accel: Float) -> Void {}
}
