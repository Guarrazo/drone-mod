module ControllableMechs

public class CMWeaponSpec {
  public let id: String;
  public let name: String;
  public let kind: Int32;

  public let cycle: Float;
  public let heatPerShot: Float;
  public let coolRate: Float;
  public let coolDelay: Float;
  public let unlockAt: Float;
  public let spreadDeg: Float;
  public let roundSpeed: Float;
  public let kick: Float;
  public let spinUp: Float;
  public let spinDown: Float;
  public let spinFire: Float;
  public let muzzleAhead: Float;
  public let muzzleFx: ResRef;
  public let trailFx: ResRef;
  public let addedFx: Bool;
  public let hmgSound: Bool;

  public let item: TweakDBID;

  public let cooldown: Float;
  public let speed: Float;
  public let radius: Float;
  public let damage: Float;
  public let blastFx: ResRef;
  public let salvo: Int32;
  public let scatter: Float;
  public let salvoGap: Float;

  public static func Gun() -> Int32 = 0
  public static func Launcher() -> Int32 = 1
}

public abstract class CMWeaponSpecs {
  public static func Get(id: String) -> ref<CMWeaponSpec> {
    switch id {
      case "mk31": return CMWeaponSpecs.MK31();
      case "m1": return CMWeaponSpecs.M1();
      case "plasma": return CMWeaponSpecs.Plasma();
      case "octant": return CMWeaponSpecs.Autocannon();
      case "fieldhmg": return CMWeaponSpecs.FieldHmg();
      case "rain": return CMWeaponSpecs.Rain();
    }
    return null;
  }

  public static func ArmGunCount() -> Int32 = 4
  public static func ArmGunId(i: Int32) -> String {
    switch i {
      case 1: return "plasma";
      case 2: return "octant";
      case 3: return "fieldhmg";
    }
    return "mk31";
  }

  public static func ArmGunReleased(i: Int32) -> Bool = i != 2

  public static func MK31() -> ref<CMWeaponSpec> {
    let w = new CMWeaponSpec();
    w.id = "mk31";
    w.name = "MK.31  HMG";
    w.kind = CMWeaponSpec.Gun();
    w.cycle = 0.0;
    w.heatPerShot = 0.022;
    w.coolRate = 0.30;
    w.coolDelay = 0.35;
    w.unlockAt = 0.35;
    w.spreadDeg = 0.6;
    w.roundSpeed = 4.0;
    w.kick = 0.1;
    w.spinUp = 0.5;
    w.spinDown = 0.9;
    w.spinFire = 0.3;
    w.muzzleAhead = 1.2;
    w.muzzleFx = r"base\\fx\\weapons\\firearms\\special\\militech_hmg\\w_special_hmg_muzzle_tpp.effect";
    w.trailFx = r"base\\fx\\weapons\\trails\\power\\w_trail_power_hmg_npc.effect";
    w.addedFx = true;
    w.hmgSound = true;
    return w;
  }

  public static func Plasma() -> ref<CMWeaponSpec> {
    let w = new CMWeaponSpec();
    w.id = "plasma";
    w.name = CMText.WpnPlasmaCannon();
    w.kind = CMWeaponSpec.Gun();
    w.item = t"Items.royce_plasma_cutter";
    w.cycle = 0.55;
    w.heatPerShot = 0.14;
    w.coolRate = 0.40;
    w.coolDelay = 0.5;
    w.unlockAt = 0.30;
    w.spreadDeg = 0.25;
    w.roundSpeed = 1.0;
    w.kick = 0.5;
    w.spinUp = 0.05;
    w.spinDown = 0.05;
    w.spinFire = 0.0;
    w.muzzleAhead = 1.0;
    w.addedFx = false;
    w.hmgSound = false;
    return w;
  }

  public static func Autocannon() -> ref<CMWeaponSpec> {
    let w = new CMWeaponSpec();
    w.id = "octant";
    w.name = CMText.WpnAutocannon();
    w.kind = CMWeaponSpec.Gun();
    w.item = t"Items.Octant_Autocannon";
    w.cycle = 0.0;
    w.heatPerShot = 0.02;
    w.coolRate = 0.35;
    w.coolDelay = 0.35;
    w.unlockAt = 0.35;
    w.spreadDeg = 0.5;
    w.roundSpeed = 1.0;
    w.kick = 0.15;
    w.spinUp = 0.3;
    w.spinDown = 0.6;
    w.spinFire = 0.2;
    w.muzzleAhead = 1.0;
    w.addedFx = false;
    w.hmgSound = false;
    return w;
  }

  public static func FieldHmg() -> ref<CMWeaponSpec> {
    let w = new CMWeaponSpec();
    w.id = "fieldhmg";
    w.name = CMText.WpnFieldHmg();
    w.kind = CMWeaponSpec.Gun();
    w.item = t"Items.Preset_HMG_Default";

    w.cycle = 0.25;
    w.heatPerShot = 0.04;
    w.coolRate = 0.30;
    w.coolDelay = 0.4;
    w.unlockAt = 0.35;
    w.spreadDeg = 0.4;
    w.roundSpeed = 1.0;
    w.kick = 0.45;
    w.spinUp = 0.7;
    w.spinDown = 1.0;
    w.spinFire = 0.35;
    w.muzzleAhead = 1.0;
    w.addedFx = false;
    w.hmgSound = false;
    return w;
  }

  public static func Rain() -> ref<CMWeaponSpec> {
    let w = new CMWeaponSpec();
    w.id = "rain";
    w.name = CMText.WpnRocketRain();
    w.kind = CMWeaponSpec.Launcher();
    w.item = t"Items.Smasher_Launcher_Rain_Left";
    w.cooldown = 10.0;
    w.speed = 55.0;
    w.radius = 3.0;
    w.damage = 220.0;
    w.salvo = 10;
    w.scatter = 9.0;
    w.salvoGap = 0.12;
    w.blastFx = r"base\\fx\\characters\\boss_adam_shasher\\ch_adam_smasher_impact_rocket.effect";
    return w;
  }

  public static func M1() -> ref<CMWeaponSpec> {
    let w = new CMWeaponSpec();
    w.id = "m1";
    w.name = CMText.WpnMissile();
    w.kind = CMWeaponSpec.Launcher();
    w.cooldown = 6.0;
    w.speed = 70.0;
    w.radius = 5.0;
    w.damage = 900.0;
    w.blastFx = r"base\\fx\\vehicles\\minotaur\\v_minotaur_explosion.effect";
    return w;
  }
}

public class CMHardpoint {
  public let name: CName;
  public let spec: ref<CMWeaponSpec>;

  public static func Make(name: CName, id: String) -> ref<CMHardpoint> {
    let h = new CMHardpoint();
    h.name = name;
    h.spec = CMWeaponSpecs.Get(id);
    return h;
  }
}

public abstract class CMLoadout {

  public static func Minotaur() -> array<ref<CMHardpoint>> {
    return [
      CMHardpoint.Make(n"arm_l", "mk31"),
      CMHardpoint.Make(n"arm_r", "mk31"),
      CMHardpoint.Make(n"pods", "m1")
    ];
  }

  public static func For(mech: ref<GameObject>) -> array<ref<CMHardpoint>> {
    let load = CMLoadout.Minotaur();
    if !CMPartLab.IsPlayerMech(mech) {
      return load;
    }
    let cfg = CMPilotSystem.Get(mech.GetGame());
    for h in load {
      if Equals(h.name, n"arm_l") || Equals(h.name, n"arm_r") {
        h.spec = CMWeaponSpecs.Get(CMLoadout.ArmGun(cfg, h.name));
      }
      if Equals(h.name, n"pods") {

        h.spec = CMPartLab.On(cfg, 0) ? CMWeaponSpecs.Rain() : null;
      }
    }
    return load;
  }

  public static func ArmGun(cfg: ref<CMPilotSystem>, arm: CName) -> String {
    return CMWeaponSpecs.ArmGunId(CMLoadout.ArmGunIndex(cfg, arm));
  }

  public static func ArmGunIndex(cfg: ref<CMPilotSystem>, arm: CName) -> Int32 {
    let i = Clamp(cfg.Int("gun." + NameToString(arm), 0), 0, CMWeaponSpecs.ArmGunCount() - 1);
    return CMWeaponSpecs.ArmGunReleased(i) ? i : 0;
  }

  public static func On(load: array<ref<CMHardpoint>>, name: CName) -> ref<CMWeaponSpec> {
    for h in load {
      if Equals(h.name, name) {
        return h.spec;
      }
    }
    return null;
  }
}
