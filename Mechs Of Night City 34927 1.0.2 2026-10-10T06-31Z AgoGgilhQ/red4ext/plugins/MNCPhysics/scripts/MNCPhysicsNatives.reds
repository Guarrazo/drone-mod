public static native func MNCPhysics_Version() -> Int32

public static native func MNCPhysics_SetLinearVelocity(body: ref<PhysicalBodyInterface>, velocity: Vector4) -> Bool
public static native func MNCPhysics_SetAngularVelocity(body: ref<PhysicalBodyInterface>, spin: Vector4) -> Bool

public static native func MNCPhysics_SetForce(body: ref<PhysicalBodyInterface>, force: Vector4, torque: Vector4) -> Bool
public static native func MNCPhysics_Release(body: ref<PhysicalBodyInterface>) -> Bool

public static native func MNCPhysics_SetCollision(body: ref<PhysicalBodyInterface>, on: Bool) -> Bool
public static native func MNCPhysics_StepVelocity(body: ref<PhysicalBodyInterface>) -> Vector4
public static native func MNCPhysics_StepSpin(body: ref<PhysicalBodyInterface>) -> Vector4
public static native func MNCPhysics_StepInfo(body: ref<PhysicalBodyInterface>) -> String

public static native func MNCPhysics_ComponentBody(component: ref<IComponent>, index: Int32) -> ref<PhysicalBodyInterface>

public static native func MNCPhysics_Mark(stage: String) -> Void

public static native func MNCPhysics_AudioWatch(on: Bool, drone: Vector4, speed: Float, accel: Float) -> Void
