module ControllableMechs

import ControllableMechs.Control.*

public abstract class CMApi {
  public static func WireframeAtlasPath() -> String = "mnc\\ui\\unit_wireframes.inkatlas"
  public static func WireframeAtlas() -> ResRef = r"mnc\\ui\\unit_wireframes.inkatlas"

  public static func WireframePart(npc: ref<NPCPuppet>) -> CName {
    if !IsDefined(npc) {
      return n"";
    }
    switch npc.GetNPCType() {
      case gamedataNPCType.Mech:
        return n"minotaur";
      case gamedataNPCType.Drone:
        switch CMUDrone.Kind(npc) {
          case "bombus": return n"bombus";
          case "griffin": return n"griffin";
          case "octant": return n"octant";
        }
        return n"wyvern";
    }
    return n"";
  }

  public static func Wireframe(npc: ref<NPCPuppet>, out atlas: String, out part: String) -> Bool {
    let p = CMApi.WireframePart(npc);
    if !IsNameValid(p) {
      atlas = "";
      part = "";
      return false;
    }
    atlas = CMApi.WireframeAtlasPath();
    part = NameToString(p);
    return true;
  }

  public static func SetStationed(game: GameInstance, on: Bool) -> Void {
    CMLinkSystem.Get(game).SetStationed(on);
  }

  public static func IsStationed(game: GameInstance) -> Bool = CMLinkSystem.Get(game).IsStationed()
}

public abstract class CMVersion {
  public static func Text() -> String = "1.0.2"

  public static func Build() -> String = "1.0.2"
}
