module ControllableMechs

import ControllableMechs.Control.*

public class CMPartLabReapply extends DelayCallback {
  public let unit: wref<GameObject>;

  public func Call() -> Void {
    if IsDefined(this.unit) {
      CMPartLab.Apply(this.unit);
    }
  }
}

public abstract class CMPartLab {

  public static func Count() -> Int32 = 17

  public static func Name(i: Int32) -> CName {
    switch i {
      case 0: return n"mnc_pod";
      case 1: return n"mnc_pod_stand";
      case 2: return n"mnc_barrel_l";
      case 3: return n"mnc_barrel_r";
      case 5: return n"mnc_metal_l";
      case 6: return n"mnc_metal_r";
      case 7: return n"mnc_hmg_l";
      case 8: return n"mnc_hmg_r";
      case 9: return n"mnc_armor_l";
      case 10: return n"mnc_armor_r";
      case 11: return n"mnc_armor_front";
      case 12: return n"mnc_smoke_l";
      case 13: return n"mnc_smoke_r";
      case 14: return n"mnc_sensor";
      case 15: return n"mnc_jet_l";
      case 16: return n"mnc_jet_r";
    }
    return n"mch_003__minotaur_bags_01";
  }

  public static func Label(i: Int32) -> String {
    switch i {
      case 0: return CMText.LabRocketPod();
      case 1: return CMText.LabPodStand();
      case 2: return CMText.LabPlasmaL();
      case 3: return CMText.LabPlasmaR();
      case 5: return CMText.LabAutocannonL();
      case 6: return CMText.LabAutocannonR();
      case 7: return CMText.LabFieldHmgL();
      case 8: return CMText.LabFieldHmgR();
      case 12: return CMText.LabCounterL();
      case 13: return CMText.LabCounterR();
      case 15: return CMText.LabJumpJetL();
      case 16: return CMText.LabJumpJetR();
    }
    return CMText.LabBags();
  }

  private static func DefaultCm(i: Int32, axis: Int32) -> Int32 {
    switch i {
      case 0: return axis == 0 ? -9 : (axis == 1 ? 85 : -8);
      case 1: return axis == 0 ? -10 : (axis == 1 ? 85 : -10);
      case 2: return axis == 0 ? 86 : (axis == 1 ? -90 : -41);
      case 3: return axis == 0 ? -67 : (axis == 1 ? -90 : 46);
      case 5: return axis == 0 ? 41 : (axis == 1 ? -30 : -254);
      case 6: return axis == 0 ? 19 : (axis == 1 ? -276 : -28);
      case 7: return axis == 0 ? -12 : (axis == 1 ? 11 : -41);
      case 8: return axis == 0 ? 28 : (axis == 1 ? 15 : 41);
      case 12: return axis == 0 ? -58 : (axis == 1 ? 10 : -23);
      case 13: return axis == 0 ? 40 : (axis == 1 ? 10 : -27);
      case 15: return axis == 0 ? -11 : (axis == 1 ? 30 : 10);
      case 16: return axis == 0 ? -9 : (axis == 1 ? -12 : -29);
    }
    return 0;
  }

  private static func DefaultDeg(i: Int32, axis: Int32) -> Int32 {
    switch i {
      case 0: return axis == 0 ? 180 : (axis == 1 ? 76 : 0);
      case 1: return axis == 0 ? -165 : (axis == 1 ? 73 : -16);
      case 2: return axis == 0 ? 0 : (axis == 1 ? 87 : -180);
      case 3: return axis == 0 ? 0 : (axis == 1 ? -90 : 0);
      case 5: return axis == 0 ? 172 : (axis == 1 ? 98 : 99);
      case 7: return axis == 0 ? 0 : (axis == 1 ? 90 : 180);
      case 8: return axis == 0 ? 0 : (axis == 1 ? -93 : 0);
      case 12: return axis == 0 ? -56 : (axis == 1 ? 103 : -54);
      case 13: return axis == 0 ? 30 : (axis == 1 ? 103 : 66);
      case 15: return axis == 0 ? -87 : (axis == 1 ? 180 : -88);
      case 16: return axis == 0 ? -90 : (axis == 1 ? -5 : -180);
    }
    return 0;
  }

  private static func DefaultPieces(i: Int32) -> Int32 {
    return i == 5 ? 254 : -1;
  }

  private static func Key(i: Int32, k: String) -> String {
    let pre = "part";
    if i == 2 || i == 3 {
      pre = "cannon";
    }
    if i == 5 || i == 6 {
      pre = "cplasma";
    }
    if i >= 9 {
      pre = "hull";
    }
    if i == 15 || i == 16 {
      pre = "jet";
    }
    return pre + IntToString(i) + "." + k;
  }

  public static func GunOf(i: Int32) -> String {
    switch i {
      case 2: return "plasma";
      case 3: return "plasma";
      case 5: return "octant";
      case 6: return "octant";
      case 7: return "fieldhmg";
      case 8: return "fieldhmg";
    }
    return "";
  }
  public static func FollowsGun(i: Int32) -> Bool = StrLen(CMPartLab.GunOf(i)) > 0
  public static func LeftArm(i: Int32) -> Bool = i == 2 || i == 5 || i == 7
  public static func Movable(i: Int32) -> Bool = i != 4

  public static func Retired(i: Int32) -> Bool = i == 9 || i == 10 || i == 11 || i == 14

  public static func Mask(i: Int32) -> Uint64 = 9223372036854775807ul

  public static func PiecesOf(cfg: ref<CMPilotSystem>, i: Int32) -> Uint64 {
    let set = cfg.Int(CMPartLab.Key(i, "pieces"), CMPartLab.DefaultPieces(i));
    if set < 0 {
      return CMPartLab.Mask(i);
    }

    let keep = CMPartLab.Mask(i) & 18446744073709551360ul;
    return keep | Cast<Uint64>(set);
  }

  public static func Up(cfg: ref<CMPilotSystem>, name: String) -> Bool = cfg.Flag("up." + name, false)
  public static func SetUp(cfg: ref<CMPilotSystem>, name: String, on: Bool) -> Void { cfg.PutFlag("up." + name, on); }

  public static func On(cfg: ref<CMPilotSystem>, i: Int32) -> Bool {
    if i == 15 || i == 16 {
      return CMPartLab.Up(cfg, "jets");
    }
    if CMPartLab.FollowsGun(i) {
      return Equals(CMLoadout.ArmGun(cfg, CMPartLab.LeftArm(i) ? n"arm_l" : n"arm_r"), CMPartLab.GunOf(i));
    }
    return cfg.Flag(CMPartLab.Key(i, "on"), false);
  }
  public static func Cm(cfg: ref<CMPilotSystem>, i: Int32, axis: Int32) -> Int32 {
    let k = axis == 0 ? "x" : (axis == 1 ? "y" : "z");
    return cfg.Int(CMPartLab.Key(i, k), CMPartLab.DefaultCm(i, axis));
  }
  public static func Deg(cfg: ref<CMPilotSystem>, i: Int32, axis: Int32) -> Int32 {
    let k = axis == 0 ? "yaw" : (axis == 1 ? "pitch" : "roll");
    return cfg.Int(CMPartLab.Key(i, k), CMPartLab.DefaultDeg(i, axis));
  }
  public static func SetOn(cfg: ref<CMPilotSystem>, i: Int32, on: Bool) -> Void { cfg.PutFlag(CMPartLab.Key(i, "on"), on); }

  public static func IsPlayerMech(unit: ref<GameObject>) -> Bool {
    return IsDefined(unit) && IsDefined(unit.FindComponentByName(CMPartLab.Name(0)));
  }

  public static func LookFor(look: String, cfg: ref<CMPilotSystem>, goneL: Bool, goneR: Bool) -> CName {
    let base = look;
    if StrEndsWith(look, "__nl") || StrEndsWith(look, "__nr") || StrEndsWith(look, "__nb") {
      base = StrLeft(look, StrLen(look) - 4);
    }
    let hideL = goneL || !Equals(CMLoadout.ArmGun(cfg, n"arm_l"), "mk31");
    let hideR = goneR || !Equals(CMLoadout.ArmGun(cfg, n"arm_r"), "mk31");
    return StringToName(base + (hideL ? (hideR ? "__nb" : "__nl") : (hideR ? "__nr" : "")));
  }

  private static func ArmLook(unit: ref<GameObject>, cfg: ref<CMPilotSystem>) -> Bool {
    let cur = NameToString(unit.GetCurrentAppearanceName());
    let want = NameToString(CMPartLab.LookFor(cur, cfg, CMPartLab.ArmGone(unit, true), CMPartLab.ArmGone(unit, false)));
    if Equals(want, cur) {
      return false;
    }

    if !unit.IsAttached() || CMLinkSystem.Get(unit.GetGame()).JustSpawned(unit) {
      return false;
    }
    unit.ScheduleAppearanceChange(StringToName(want));
    let again = new CMPartLabReapply();
    again.unit = unit;
    GameInstance.GetDelaySystem(unit.GetGame()).DelayCallback(again, 1.5, false);
    return true;
  }

  public static func HideItemModels(unit: ref<GameObject>) -> Void {
    let ts = GameInstance.GetTransactionSystem(unit.GetGame());
    let hid = 0;
    let slots: array<TweakDBID>;
    ArrayPush(slots, t"AttachmentSlots.WeaponLeft");
    ArrayPush(slots, t"AttachmentSlots.WeaponRight");
    for slot in slots {
      let item = ts.GetItemInSlot(unit, slot);
      if IsDefined(item) && ItemID.GetTDBID(item.GetItemID()) == CMWeaponSpecs.FieldHmg().item {
        for c in item.GetComponents() {
          let sk = c as entSkinnedMeshComponent;
          if IsDefined(sk) {
            sk.chunkMask = 0ul;
            sk.Toggle(false);
            hid += 1;
          } else {
            let m = c as MeshComponent;
            if IsDefined(m) {
              m.chunkMask = 0ul;
              m.Toggle(false);
              hid += 1;
            }
          }
        }
      }
    }
    if hid > 0 {
    }
  }

  public static func ArmGone(unit: ref<GameObject>, left: Bool) -> Bool {
    let npc = unit as NPCPuppet;
    if !IsDefined(npc) {
      return false;
    }
    return left ? npc.m_cmArmLGone : npc.m_cmArmRGone;
  }

  public static func Apply(unit: ref<GameObject>) -> Int32 {
    if !IsDefined(unit) || !IsDefined(unit.FindComponentByName(CMPartLab.Name(0))) {
      return 0;
    }
    let cfg = CMPilotSystem.Get(unit.GetGame());
    let found = 0;
    let i = 0;
    while i < CMPartLab.Count() {
      let c = unit.FindComponentByName(CMPartLab.Name(i));
      if IsDefined(c) {
        found += 1;
        let on = CMPartLab.On(cfg, i) && !CMPartLab.Retired(i);

        if CMPartLab.FollowsGun(i) && CMPartLab.ArmGone(unit, CMPartLab.LeftArm(i)) {
          on = false;
        }
        let mask = on ? CMPartLab.PiecesOf(cfg, i) : 0ul;
        c.Toggle(on);
        let sk = c as entSkinnedMeshComponent;
        if IsDefined(sk) {
          sk.chunkMask = mask;
        } else {
          let m = c as MeshComponent;
          if IsDefined(m) {
            m.chunkMask = mask;
          }
        }

        let pc = c as IPlacedComponent;
        if IsDefined(pc) && CMPartLab.Movable(i) {
          let at = new Vector4(Cast<Float>(CMPartLab.Cm(cfg, i, 0)) / 100.0, Cast<Float>(CMPartLab.Cm(cfg, i, 1)) / 100.0, Cast<Float>(CMPartLab.Cm(cfg, i, 2)) / 100.0, 1.0);
          pc.SetLocalPosition(at);
          let e: EulerAngles;
          e.Yaw = Cast<Float>(CMPartLab.Deg(cfg, i, 0));
          e.Pitch = Cast<Float>(CMPartLab.Deg(cfg, i, 1));
          e.Roll = Cast<Float>(CMPartLab.Deg(cfg, i, 2));
          pc.SetLocalOrientation(EulerAngles.ToQuat(e));
        }
      }
      i += 1;
    }
    CMPartLab.ArmLook(unit, cfg);
    CMPartLab.HideItemModels(unit);
    return found;
  }

  public static func Where(unit: ref<GameObject>) -> Void {
    if !CMPartLab.IsPlayerMech(unit) {
      return;
    }
    let cfg = CMPilotSystem.Get(unit.GetGame());
    let base = unit.GetWorldPosition();
    let fwd = unit.GetWorldForward();
    let right = new Vector4(fwd.Y, -fwd.X, 0.0, 0.0);
    let i = 0;
    while i < CMPartLab.Count() {
      if CMPartLab.On(cfg, i) && !CMPartLab.Retired(i) {
        let pc = unit.FindComponentByName(CMPartLab.Name(i)) as IPlacedComponent;
        if IsDefined(pc) {
          let d = Matrix.GetTranslation(pc.GetLocalToWorld()) - base;
        } else {
        }
      }
      i += 1;
    }
  }

}
