module ControllableMechs.Control

import ControllableMechs.*

public abstract class CMThermal {

  public static func Count() -> Int32 = 3

  public static func Name(mode: Int32) -> String {
    switch mode {
      case 1: return "WHT";
      case 2: return "THERMAL";
      case 3: return "RED HOT";
    }
    return "DAY";
  }

  public static func Label(name: String) -> String {
    switch name {
      case "WHT": return CMText.ThermWht();
      case "THERMAL": return CMText.ThermThermal();
      case "RED HOT": return CMText.ThermRedHot();
      case "DAY": return CMText.ThermDay();
    }
    return name;
  }

  private static func Effect(mode: Int32) -> CName {
    switch mode {
      case 1: return n"mnc_thermal_white";
      case 2: return n"mnc_thermal_orange";
      case 3: return n"mnc_thermal_red";
    }
    return n"";
  }

  private static func Register(player: ref<GameObject>) -> Bool {
    let spawner = player.FindComponentByName(n"fx_status_effects") as entEffectSpawnerComponent;
    if !IsDefined(spawner) {
      return false;
    }
    CMThermal.Ensure(spawner, n"mnc_thermal_white", r"mnc\\fx\\thermal\\white.effect");
    CMThermal.Ensure(spawner, n"mnc_thermal_orange", r"mnc\\fx\\thermal\\orange.effect");
    CMThermal.Ensure(spawner, n"mnc_thermal_red", r"mnc\\fx\\thermal\\red.effect");
    return true;
  }

  private static func Ensure(spawner: ref<entEffectSpawnerComponent>, name: CName, path: ResRef) -> Void {
    for d in spawner.effectDescs {
      if Equals(d.effectName, name) {
        return;
      }
    }
    let desc = new entEffectDesc();
    desc.effectName = name;
    desc.effect *= path;
    ArrayPush(spawner.effectDescs, desc);
  }

  public static func Set(game: GameInstance, mode: Int32) -> Bool {
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return false;
    }
    GameObjectEffectHelper.StopEffectEvent(player, n"mnc_thermal_white");
    GameObjectEffectHelper.StopEffectEvent(player, n"mnc_thermal_orange");
    GameObjectEffectHelper.StopEffectEvent(player, n"mnc_thermal_red");
    if mode <= 0 {
      return true;
    }
    if !CMThermal.Register(player) {
      return false;
    }
    GameObjectEffectHelper.StartEffectEvent(player, CMThermal.Effect(mode), true);
    return true;
  }
}
