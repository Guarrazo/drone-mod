module ControllableMechs

import ControllableMechs.Control.*
import Codeware.UI.*

public class CMInput extends IScriptable {
  public let player: wref<PlayerPuppet>;

  private let m_lastName: CName;
  private let m_lastTime: Float;

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    if !ListenerAction.IsButtonJustPressed(action) {
      return false;
    }
    let name = ListenerAction.GetName(action);

    let now = EngineTime.ToFloat(GameInstance.GetEngineTime(this.player.GetGame()));
    if Equals(name, this.m_lastName) && now - this.m_lastTime < 0.25 {
      return false;
    }
    this.m_lastName = name;
    this.m_lastTime = now;
    let session = CMCSession.Get(this.player.GetGame());
    if Equals(name, n"CM_Pilot") {
      session.Toggle();
      return false;
    }
    if session.IsActive() {
      return false;
    }
    switch name {
      case n"CM_OpenLink":
        CMTerminal.Toggle(this.player);
        break;
      case n"CM_LinkLookAt":
        let msg = CMLinkSystem.Get(this.player.GetGame()).LinkLookAt();
        if StrLen(msg) > 0 {
          this.player.SetWarningMessage(CMLinkSystem.Plain(msg));
        }
        break;
    }
    return false;
  }
}

@addField(PlayerPuppet)
private let m_cmInput: ref<CMInput>;

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result = wrappedMethod();
  this.m_cmInput = new CMInput();
  this.m_cmInput.player = this;
  this.RegisterInputListener(this.m_cmInput, n"CM_OpenLink");
  this.RegisterInputListener(this.m_cmInput, n"CM_LinkLookAt");
  this.RegisterInputListener(this.m_cmInput, n"CM_Pilot");
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
  if IsDefined(this.m_cmcSession) {
    if this.m_cmcSession.OnGameAction(ListenerAction.GetName(action), ListenerAction.GetType(action), ListenerAction.GetValue(action)) {

      ListenerActionConsumer.ConsumeSingleAction(consumer);
      return true;
    }
  }
  return wrappedMethod(action, consumer);
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  if IsDefined(this.m_cmInput) {
    this.UnregisterInputListener(this.m_cmInput);
    this.m_cmInput = null;
  }
  return wrappedMethod();
}

@if(ModuleExists("ModSettingsModule"))
public class CMKeybinds {

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Robot Link")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Open Regis Software")
  @runtimeProperty("ModSettings.description", "Opens the Robot Link console")
  public let cmOpenLink: EInputKey = EInputKey.IK_O;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Robot Link")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Link the robot you look at")
  @runtimeProperty("ModSettings.description", "Links the mech, drone, android or spiderbot under your crosshair")
  public let cmLinkLookAt: EInputKey = EInputKey.IK_LeftBracket;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Robot Link")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Pilot the linked unit")
  @runtimeProperty("ModSettings.description", "Takes control of the linked unit; press again to close the link")
  public let cmPilot: EInputKey = EInputKey.IK_U;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Robot Link")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Unload the mech from the Behemoth")
  @runtimeProperty("ModSettings.description", "At the Behemoth's back")
  public let cmUnload: EInputKey = EInputKey.IK_F;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Forward")
  @runtimeProperty("ModSettings.description", "Walk or fly forward")
  public let cmForward: EInputKey = EInputKey.IK_W;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Back")
  @runtimeProperty("ModSettings.description", "Walk or fly back")
  public let cmBack: EInputKey = EInputKey.IK_S;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Left")
  @runtimeProperty("ModSettings.description", "Turn or strafe left")
  public let cmLeft: EInputKey = EInputKey.IK_A;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Right")
  @runtimeProperty("ModSettings.description", "Turn or strafe right")
  public let cmRight: EInputKey = EInputKey.IK_D;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Climb (drones)")
  @runtimeProperty("ModSettings.description", "A drone climbs while held")
  public let cmClimb: EInputKey = EInputKey.IK_Space;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Descend (drones)")
  @runtimeProperty("ModSettings.description", "A drone descends while held")
  public let cmDescend: EInputKey = EInputKey.IK_LControl;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Jump jets (mech)")
  @runtimeProperty("ModSettings.description", "Fires the player mech's jump jets, with the upgrade fitted")
  public let cmJump: EInputKey = EInputKey.IK_Space;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Third-person view")
  @runtimeProperty("ModSettings.description", "Switches between the cockpit and the chase view")
  public let cmView: EInputKey = EInputKey.IK_V;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Fire")
  @runtimeProperty("ModSettings.description", "Fires the unit's guns")
  public let cmFire: EInputKey = EInputKey.IK_LeftMouse;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Aim (optics)")
  @runtimeProperty("ModSettings.description", "Zooms the optics while held")
  public let cmAim: EInputKey = EInputKey.IK_RightMouse;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Fire mode and weapon select")
  @runtimeProperty("ModSettings.description", "Tap for the fire mode; on the mech, hold for rocket rain")
  public let cmFireMode: EInputKey = EInputKey.IK_B;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Secondary weapon")
  @runtimeProperty("ModSettings.description", "The missile, the rockets or the Wyvern's ping")
  public let cmSecondary: EInputKey = EInputKey.IK_G;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Sensor mode")
  @runtimeProperty("ModSettings.description", "Tap for the thermal modes; on the mech, hold for the headlights")
  public let cmSensor: EInputKey = EInputKey.IK_T;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Optics in split fire")
  @runtimeProperty("ModSettings.description", "Zooms the optics while the guns fire split")
  public let cmSplitOptics: EInputKey = EInputKey.IK_MiddleMouse;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Track the locked target")
  @runtimeProperty("ModSettings.description", "The guns follow the target under the reticle")
  public let cmTrack: EInputKey = EInputKey.IK_R;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Defence (mech)")
  @runtimeProperty("ModSettings.description", "Tap for countermeasures, hold to raise or lower the shield")
  public let cmDefence: EInputKey = EInputKey.IK_X;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Gunship hold (drones)")
  @runtimeProperty("ModSettings.description", "Holds the drone in place while you aim")
  public let cmGunship: EInputKey = EInputKey.IK_F;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Piloting")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Bombus blast ring (drones)")
  @runtimeProperty("ModSettings.description", "Shows or hides the Bombus blast ring on the HUD")
  public let cmDeclutter: EInputKey = EInputKey.IK_X;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Regis Software")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Deploy the selected unit")
  @runtimeProperty("ModSettings.description", "While the console is open")
  public let cmConDeploy: EInputKey = EInputKey.IK_F;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Regis Software")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Recall the selected unit")
  @runtimeProperty("ModSettings.description", "While the console is open")
  public let cmConRecall: EInputKey = EInputKey.IK_R;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Regis Software")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Tactical map")
  @runtimeProperty("ModSettings.description", "While the console is open")
  public let cmConMap: EInputKey = EInputKey.IK_M;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Keys: Regis Software")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Requisition")
  @runtimeProperty("ModSettings.description", "While the console is open")
  public let cmConReq: EInputKey = EInputKey.IK_Q;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Health and Damage")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Mech health")
  @runtimeProperty("ModSettings.description", "The player mech's health, as a share of its tuned health. Applies the next time it deploys")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "25")
  @runtimeProperty("ModSettings.max", "400")
  public let cmMechHealth: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Health and Damage")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Drone health")
  @runtimeProperty("ModSettings.description", "Each of your drones' health, as a share of its tuned health. Applies the next time it deploys")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "25")
  @runtimeProperty("ModSettings.max", "400")
  public let cmDroneHealth: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Health and Damage")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Mech damage")
  @runtimeProperty("ModSettings.description", "Everything the mech hits with, as a share of its tuned damage. Applies at once")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "400")
  public let cmMechDamage: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "Mechs of Night City")
  @runtimeProperty("ModSettings.category", "Health and Damage")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Drone damage")
  @runtimeProperty("ModSettings.description", "Everything your drones hit with, as a share of their tuned damage. Applies at once")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "400")
  public let cmDroneDamage: Int32 = 100;
}

@if(ModuleExists("ModSettingsModule"))
public abstract class CMKeys {

  public static func GunshipName(player: ref<PlayerPuppet>) -> String {
    let n = EnumValueToString("EInputKey", Cast<Int64>(EnumInt(CMKeys.Gunship(player))));
    return StrBeginsWith(n, "IK_") ? StrUpper(StrAfterFirst(n, "IK_")) : StrUpper(n);
  }

  public static func Gunship(player: ref<PlayerPuppet>) -> EInputKey {
    if IsDefined(player) && IsDefined(player.m_cmKeybinds) {
      return player.m_cmKeybinds.cmGunship;
    }
    return EInputKey.IK_F;
  }

  public static func Pilot(player: ref<PlayerPuppet>) -> EInputKey {
    if IsDefined(player) && IsDefined(player.m_cmKeybinds) {
      return player.m_cmKeybinds.cmPilot;
    }
    return EInputKey.IK_U;
  }

  public static func PilotName(player: ref<PlayerPuppet>) -> String {
    let n = EnumValueToString("EInputKey", Cast<Int64>(EnumInt(CMKeys.Pilot(player))));
    let s = StrBeginsWith(n, "IK_") ? StrAfterFirst(n, "IK_") : n;
    return Equals(s, "Backslash") ? "\\" : StrUpper(s);
  }

  public static func Declutter(player: ref<PlayerPuppet>) -> EInputKey {
    if IsDefined(player) && IsDefined(player.m_cmKeybinds) {
      return player.m_cmKeybinds.cmDeclutter;
    }
    return EInputKey.IK_X;
  }

  public static func DeclutterName(player: ref<PlayerPuppet>) -> String {
    let n = EnumValueToString("EInputKey", Cast<Int64>(EnumInt(CMKeys.Declutter(player))));
    return StrBeginsWith(n, "IK_") ? StrUpper(StrAfterFirst(n, "IK_")) : StrUpper(n);
  }

  public static func View(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmView : EInputKey.IK_V
  public static func FireMode(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmFireMode : EInputKey.IK_B
  public static func Secondary(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmSecondary : EInputKey.IK_G
  public static func Sensor(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmSensor : EInputKey.IK_T
  public static func SplitOptics(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmSplitOptics : EInputKey.IK_MiddleMouse
  public static func Track(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmTrack : EInputKey.IK_R
  public static func Defence(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmDefence : EInputKey.IK_X
  public static func Jump(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmJump : EInputKey.IK_Space
  public static func ConDeploy(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmConDeploy : EInputKey.IK_F
  public static func ConRecall(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmConRecall : EInputKey.IK_R
  public static func ConMap(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmConMap : EInputKey.IK_M
  public static func ConReq(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmConReq : EInputKey.IK_Q

  public static func Forward(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmForward : EInputKey.IK_W
  public static func Back(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmBack : EInputKey.IK_S
  public static func Left(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmLeft : EInputKey.IK_A
  public static func Right(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmRight : EInputKey.IK_D
  public static func Climb(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmClimb : EInputKey.IK_Space
  public static func Descend(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmDescend : EInputKey.IK_LControl
  public static func Fire(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmFire : EInputKey.IK_LeftMouse
  public static func Aim(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmAim : EInputKey.IK_RightMouse
  public static func Unload(player: ref<PlayerPuppet>) -> EInputKey = IsDefined(player) && IsDefined(player.m_cmKeybinds) ? player.m_cmKeybinds.cmUnload : EInputKey.IK_F

  public static func MechHealth() -> Int32 = CMKeys.Pct(0)
  public static func DroneHealth() -> Int32 = CMKeys.Pct(1)
  public static func MechDamage() -> Int32 = CMKeys.Pct(2)
  public static func DroneDamage() -> Int32 = CMKeys.Pct(3)
  private static func Pct(which: Int32) -> Int32 {
    let player = GetPlayer(GetGameInstance());
    if !IsDefined(player) || !IsDefined(player.m_cmKeybinds) {
      return 100;
    }
    let k = player.m_cmKeybinds;
    switch which {
      case 0: return Clamp(k.cmMechHealth, 25, 400);
      case 1: return Clamp(k.cmDroneHealth, 25, 400);
      case 2: return Clamp(k.cmMechDamage, 0, 400);
    }
    return Clamp(k.cmDroneDamage, 0, 400);
  }
}

@if(!ModuleExists("ModSettingsModule"))
public abstract class CMKeys {
  public static func Gunship(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_F
  public static func GunshipName(player: ref<PlayerPuppet>) -> String = "F"
  public static func Declutter(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_X
  public static func DeclutterName(player: ref<PlayerPuppet>) -> String = "X"
  public static func Pilot(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_U
  public static func PilotName(player: ref<PlayerPuppet>) -> String = "U"
  public static func View(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_V
  public static func FireMode(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_B
  public static func Secondary(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_G
  public static func Sensor(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_T
  public static func SplitOptics(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_MiddleMouse
  public static func Track(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_R
  public static func Defence(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_X
  public static func Jump(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_Space
  public static func ConDeploy(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_F
  public static func ConRecall(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_R
  public static func ConMap(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_M
  public static func ConReq(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_Q
  public static func Forward(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_W
  public static func Back(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_S
  public static func Left(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_A
  public static func Right(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_D
  public static func Climb(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_Space
  public static func Descend(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_LControl
  public static func Fire(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_LeftMouse
  public static func Aim(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_RightMouse
  public static func Unload(player: ref<PlayerPuppet>) -> EInputKey = EInputKey.IK_F
  public static func MechHealth() -> Int32 = 100
  public static func DroneHealth() -> Int32 = 100
  public static func MechDamage() -> Int32 = 100
  public static func DroneDamage() -> Int32 = 100
}

public abstract class CMKeyName {
  public static func Of(k: EInputKey) -> String {
    let n = EnumValueToString("EInputKey", Cast<Int64>(EnumInt(k)));
    let s = StrBeginsWith(n, "IK_") ? StrAfterFirst(n, "IK_") : n;
    switch s {
      case "LeftMouse": return CMText.KeyLmb();
      case "RightMouse": return CMText.KeyRmb();
      case "MiddleMouse": return CMText.KeyMmb();
      case "Backslash": return "\\";
      case "Slash": return "/";
      case "LeftBracket": return "[";
      case "RightBracket": return "]";
      case "Comma": return ",";
      case "Period": return ".";
      case "Semicolon": return ";";
      case "Apostrophe": return "'";
      case "Tilde": return "~";
      case "Minus": return "-";
      case "Equals": return "=";
      case "LControl": return CMText.KeyLCtrl();
      case "RControl": return CMText.KeyRCtrl();
      case "LShift": return CMText.KeyLShift();
      case "RShift": return CMText.KeyRShift();
      case "LAlt": return CMText.KeyLAlt();
      case "RAlt": return CMText.KeyRAlt();
      case "Space": return CMText.KeySpace();
      case "Enter": return CMText.KeyEnter();
      case "Tab": return CMText.KeyTab();
    }
    if StrBeginsWith(s, "NumPad") {
      return CMText.KeyNum(StrAfterFirst(s, "NumPad"));
    }
    return StrUpper(s);
  }

  public static func Tag(k: EInputKey) -> String = "[" + CMKeyName.Of(k) + "]"

  public static func Fire() -> String = CMKeyName.Tag(CMKeys.Fire(GetPlayer(GetGameInstance())))
  public static func Aim() -> String = CMKeyName.Tag(CMKeys.Aim(GetPlayer(GetGameInstance())))
  public static func FireMode() -> String = CMKeyName.Tag(CMKeys.FireMode(GetPlayer(GetGameInstance())))
  public static func Secondary() -> String = CMKeyName.Tag(CMKeys.Secondary(GetPlayer(GetGameInstance())))
  public static func Sensor() -> String = CMKeyName.Tag(CMKeys.Sensor(GetPlayer(GetGameInstance())))

  public static func Game(action: CName, fallback: String) -> String {
    let hints = ButtonHintsManager.GetInstance();
    if !IsDefined(hints) || !hints.IsInitialized() {
      return fallback;
    }
    let part = StrUpper(hints.GetActionKey(action));
    if StrLen(part) == 0 {
      return fallback;
    }
    if StrContains(part, "MOUSE") || StrContains(part, "MB") {
      if StrContains(part, "LEFT") || StrContains(part, "LMB") || StrContains(part, "_1") {
        return CMText.KeyLmb();
      }
      if StrContains(part, "RIGHT") || StrContains(part, "RMB") || StrContains(part, "_2") {
        return CMText.KeyRmb();
      }
      if StrContains(part, "MIDDLE") || StrContains(part, "MMB") || StrContains(part, "_3") {
        return CMText.KeyMmb();
      }
    }

    let key = part;
    while StrContains(key, "_") {
      key = StrAfterFirst(key, "_");
    }
    return StrLen(key) > 0 && StrLen(key) <= 6 ? key : fallback;
  }

}

@if(ModuleExists("ModSettingsModule"))
@addField(PlayerPuppet)
private let m_cmKeybinds: ref<CMKeybinds>;

@if(ModuleExists("ModSettingsModule"))
@wrapMethod(PlayerPuppet)
protected cb func OnMakePlayerVisibleAfterSpawn(evt: ref<EndGracePeriodAfterSpawn>) -> Bool {
  if !IsDefined(this.m_cmKeybinds) {
    this.m_cmKeybinds = new CMKeybinds();
    ModSettings.RegisterListenerToClass(this.m_cmKeybinds);
  }
  return wrappedMethod(evt);
}
