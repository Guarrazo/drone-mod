module MNCPhysics.Plugin

public abstract class MNCPhysicsPlugin {
  public static func Present() -> Bool = MNCPhysics_Version() > 0
}
