module ControllableMechs

import TerminalKit.*
import ControllableMechs.Control.*

public class CMConState {
  public let sel: Int32;
  public let mode: Int32;
  public let hp: String;
  public let msg: String;
  public let feed: array<String>;
  public let stage: wref<CMConStage>;
  public let dropAt: Vector4;
  public let dropOk: Bool;
  public let pickDrone: Bool;

  public func Say(text: String) -> Void {
    this.msg = text;
    let plain = CMLinkSystem.Plain(text);
    if StrLen(plain) > 0 {
      ArrayInsert(this.feed, 0, plain);
      while ArraySize(this.feed) > 6 {
        ArrayPop(this.feed);
      }
    }
  }
}

public class CMConBay {
  public let bay: Int32;
  public let kind: String;
  public let name: String;
  public let id: String;
  public let stamp: String;
  public let st: String;
  public let hull: Float;
  public let owned: Bool;
  public let out: Bool;
  public let linked: Bool;
  public let unit: wref<NPCPuppet>;
}

public class CMConPart {
  public let id: String;
  public let key: String;
  public let name: String;
  public let hp: Float;
  public let slot: String;
}

public class CMConLayer {
  public let tex: CName;
  public let x: Float;
  public let y: Float;
  public let w: Float;
  public let h: Float;
  public let part: String;
  public let own: Bool;
}

public abstract class CMConsole {

  public static func Bays(game: GameInstance) -> array<ref<CMConBay>> {
    let out: array<ref<CMConBay>>;
    let fleet = CMFleet.Get(game);
    let link = CMLinkSystem.Get(game);
    let session = CMCSession.Get(game);
    let piloting = IsDefined(session) && session.IsActive();
    let i = 0;
    while i < CMFleet.Count() {

      if fleet.Owned(i) {
      let b = new CMConBay();
      b.bay = i;
      b.kind = CMFleet.Kind(i);
      b.name = CMFleet.Name(i);
      b.id = CMText.CslBayId(IntToString(i + 1));
      b.owned = true;
      b.out = fleet.IsOut(i);
      let unit = b.out ? fleet.OutUnit() : null;
      b.unit = unit;
      b.linked = IsDefined(unit) && link.IsLinkedTo(unit.GetEntityID());
      b.hull = fleet.Hull(i);
      if b.out && IsDefined(unit) {
        b.hull = ClampF(GameInstance.GetStatPoolsSystem(game).GetStatPoolValue(Cast<StatsObjectID>(unit.GetEntityID()), gamedataStatPoolType.Health, true) / 100.0, 0.0, 1.0);
      }
      if fleet.Dead(i) && fleet.RepairLeft(i) <= 0.0 {
        b.stamp = CMText.CslDestroyed();
        b.st = "crit";
        b.hull = 0.0;
      } else {
        if fleet.RepairLeft(i) > 0.0 {
          b.stamp = CMText.CslInRepair();
          b.st = "warn";
        } else {
          if b.out {
            let wreck = IsDefined(unit) && !ScriptedPuppet.IsAlive(unit);
            b.stamp = wreck ? CMText.CslDestroyed() : (b.linked && piloting ? CMText.CslPiloted() : CMText.CslDeployed());
            b.st = wreck ? "crit" : "live";
          } else {
            b.stamp = fleet.Damaged(i) ? CMText.CslDamaged() : CMText.CslReady();
            b.st = fleet.Damaged(i) ? "warn" : "ok";
          }
        }
      }
      ArrayPush(out, b);
      }
      i += 1;
    }

    let wild = link.Unit();
    if IsDefined(wild) && !(fleet.OutBay() >= 0 && link.TestID() == wild.GetEntityID()) {
      let w = new CMConBay();
      w.bay = -1;
      w.kind = CMConsole.KindOf(wild);
      w.name = StrLen(wild.GetDisplayName()) > 0 ? StrUpper(wild.GetDisplayName()) : CMLinkSystem.KindName(wild);
      w.id = CMText.CslWild();
      w.stamp = CMText.CslWild();
      w.st = "wild";
      w.owned = false;
      w.out = true;
      w.linked = true;
      w.unit = wild;
      w.hull = link.HealthFraction();
      ArrayPush(out, w);
    }
    return out;
  }

  public static func KindOf(npc: ref<NPCPuppet>) -> String {
    if !IsDefined(npc) {
      return "";
    }
    if Equals(npc.GetNPCType(), gamedataNPCType.Drone) {
      return CMUDrone.Kind(npc);
    }
    if Equals(npc.GetNPCType(), gamedataNPCType.Mech) {
      return "minotaur";
    }
    return "";
  }

  public static func Selected(game: GameInstance, con: ref<CMConState>) -> ref<CMConBay> {
    let bays = CMConsole.Bays(game);
    let n = ArraySize(bays);
    if n == 0 {
      return null;
    }
    con.sel = Clamp(con.sel, 0, n - 1);
    return bays[con.sel];
  }

  public static func Hp(game: GameInstance, b: ref<CMConBay>, i: Int32) -> Float {
    let unit = b.unit;
    if b.out && IsDefined(unit) {
      if Equals(b.kind, "minotaur") {
        let st = CMCParts.Get(game).State(unit.GetEntityID());
        return i < ArraySize(st.hp) ? st.hp[i] : 1.0;
      }
      let n = CMUDrone.PartsOf(b.kind);

      let parts = CMLinkSystem.Get(game).DroneParts(unit.GetEntityID(), n);
      if i >= 0 && i < ArraySize(parts) {
        return parts[i];
      }
      return 1.0;
    }
    if b.bay < 0 {
      return 1.0;
    }
    if CMFleet.Get(game).Dead(b.bay) {
      return 0.0;
    }
    return CMFleet.Get(game).Hp(b.bay, i);
  }

  public static func Parts(game: GameInstance, b: ref<CMConBay>) -> array<ref<CMConPart>> {
    let out: array<ref<CMConPart>>;
    let cfg = CMPilotSystem.Get(game);
    let mine = b.bay == 0;
    switch b.kind {
      case "minotaur":
        ArrayPush(out, CMConsole.P("arm_l", CMText.CslLArm(), mine ? CMConsole.GunName(CMLoadout.ArmGun(cfg, n"arm_l")) : "MK.31 HMG", CMConsole.Hp(game, b, CMPart.ArmL()), mine ? "arm_l" : ""));
        ArrayPush(out, CMConsole.P("arm_r", CMText.CslRArm(), mine ? CMConsole.GunName(CMLoadout.ArmGun(cfg, n"arm_r")) : "MK.31 HMG", CMConsole.Hp(game, b, CMPart.ArmR()), mine ? "arm_r" : ""));
        ArrayPush(out, CMConsole.P("sensor", CMText.CslSensor(), CMText.CslOpticsSuite(), CMConsole.Hp(game, b, CMPart.Sensor()), ""));

        ArrayPush(out, CMConsole.P(mine && CMPartLab.On(cfg, 0) ? "pod" : "torso", CMText.CslShoulder(), mine ? (CMPartLab.On(cfg, 0) ? CMText.CslRocketRainPod() : CMText.CslNone()) : CMText.CslMissilePods(), CMConsole.Hp(game, b, CMPart.Pods()), mine ? "hullpod" : ""));
        ArrayPush(out, CMConsole.P("pods", CMText.CslBack(), mine ? (CMPartLab.On(cfg, 4) ? CMText.CslBags() : CMText.CslNone()) : CMText.CslBags(), b.hull, mine ? "bags" : ""));
        ArrayPush(out, CMConsole.P("leg_l", CMText.CslLLeg(), CMText.CslLegAssembly(), CMConsole.Hp(game, b, CMPart.LegL()), ""));
        ArrayPush(out, CMConsole.P("leg_r", CMText.CslRLeg(), CMText.CslLegAssembly(), CMConsole.Hp(game, b, CMPart.LegR()), ""));
        break;
      case "octant":
        ArrayPush(out, CMConsole.P("thruster_fl", CMText.CslThrusterFl(), CMText.CslThrusterPod(), CMConsole.Hp(game, b, 1), ""));
        ArrayPush(out, CMConsole.P("thruster_fr", CMText.CslThrusterFr(), CMText.CslThrusterPod(), CMConsole.Hp(game, b, 2), ""));
        ArrayPush(out, CMConsole.P("rocket_l", CMText.CslRocketsL(), CMText.CslRocketPod(), CMConsole.Hp(game, b, 6), ""));
        ArrayPush(out, CMConsole.P("rocket_r", CMText.CslRocketsR(), CMText.CslRocketPod(), CMConsole.Hp(game, b, 7), ""));
        ArrayPush(out, CMConsole.P("gun", CMText.CslNose(), "LMG", CMConsole.Hp(game, b, 5), ""));
        ArrayPush(out, CMConsole.P("sensor", CMText.CslSensor(), CMText.CslThermalSuite(), CMConsole.Hp(game, b, 9), ""));
        ArrayPush(out, CMConsole.P("mortar", CMText.CslMortar(), CMText.CslMortar(), CMConsole.Hp(game, b, 8), ""));
        ArrayPush(out, CMConsole.P("thruster_bl", CMText.CslThrusterBl(), CMText.CslThrusterPod(), CMConsole.Hp(game, b, 3), ""));
        ArrayPush(out, CMConsole.P("thruster_br", CMText.CslThrusterBr(), CMText.CslThrusterPod(), CMConsole.Hp(game, b, 4), ""));
        ArrayPush(out, CMConsole.P("body", CMText.CslHull(), CMText.CslAirframe(), b.hull, ""));
        break;
      case "wyvern":
        ArrayPush(out, CMConsole.P("arm_l", CMText.CslRotorsL(), CMConsole.Rotors(game, b, 1), CMConsole.Worst(game, b, 1, 3), ""));
        ArrayPush(out, CMConsole.P("arm_r", CMText.CslRotorsR(), CMConsole.Rotors(game, b, 4), CMConsole.Worst(game, b, 4, 6), ""));
        ArrayPush(out, CMConsole.P("body", CMText.CslHull(), CMText.CslAirframe(), b.hull, ""));
        ArrayPush(out, CMConsole.P("gun", CMText.CslNose(), CMText.CslSmgMount(), 1.0, ""));
        break;
      case "griffin":
        ArrayPush(out, CMConsole.P("wing_l", CMText.CslLPod(), CMText.CslWingPod(), CMConsole.Hp(game, b, 1), ""));
        ArrayPush(out, CMConsole.P("wing_r", CMText.CslRPod(), CMText.CslWingPod(), CMConsole.Hp(game, b, 2), ""));
        ArrayPush(out, CMConsole.P("body", CMText.CslHull(), CMText.CslAirframe(), b.hull, ""));
        break;
      case "bombus":
        ArrayPush(out, CMConsole.P("payload", CMText.CslPayload(), CMConsole.PayloadName(cfg.BombusPayload()), 1.0, b.owned ? "payload" : ""));
        ArrayPush(out, CMConsole.P("body", CMText.CslHull(), CMText.CslFpvFrame(), b.hull, ""));
        break;
    }
    return out;
  }

  private static func P(id: String, key: String, name: String, hp: Float, slot: String) -> ref<CMConPart> {
    let p = new CMConPart();
    p.id = id;
    p.key = key;
    p.name = name;
    p.hp = hp;
    p.slot = slot;
    return p;
  }

  private static func Rotors(game: GameInstance, b: ref<CMConBay>, first: Int32) -> String {
    let n = 0;
    let i = first;
    while i < first + 3 {
      if CMConsole.Hp(game, b, i) > 0.0 {
        n += 1;
      }
      i += 1;
    }
    return CMText.CslRotorsTurning(IntToString(n));
  }

  private static func Worst(game: GameInstance, b: ref<CMConBay>, a: Int32, z: Int32) -> Float {
    let w = 1.0;
    let i = a;
    while i <= z {
      w = MinF(w, CMConsole.Hp(game, b, i));
      i += 1;
    }
    return w;
  }

  public static func GunName(id: String) -> String {
    switch id {
      case "plasma": return CMText.CslPlasmaCannon();
      case "fieldhmg": return CMText.CslFieldHmg();
      case "octant": return CMText.CslAutocannon();
    }
    return "MK.31 HMG";
  }

  public static func PayloadName(i: Int32) -> String {
    switch i {
      case 2: return CMText.CslHighExplosive();
      case 3: return CMText.CslToxicGas();
      case 4: return CMText.CslShock();
    }
    return CMText.CslExplosive();
  }

  public static func PodAtlas() -> ResRef = r"mnc\\hud\\minotaur_pod34.inkatlas"

  public static func Atlas(kind: String) -> ResRef {
    if Equals(kind, "minotaur") {
      return CMMinotaurHud.Schematic34();
    }
    return CMDroneHud.Atlas();
  }

  public static func Size(kind: String) -> Vector2 {
    switch kind {
      case "minotaur": return Vector2(581.0, 640.0);
      case "octant": return Vector2(537.0, 560.0);
      case "wyvern": return Vector2(273.0, 360.0);
      case "griffin": return Vector2(311.0, 360.0);
      case "bombus": return Vector2(408.0, 360.0);
    }
    return Vector2(400.0, 400.0);
  }

  public static func Layers(kind: String) -> array<ref<CMConLayer>> {
    let out: array<ref<CMConLayer>>;
    switch kind {
      case "minotaur":
        ArrayPush(out, CMConsole.L(n"pods", 275.0, 107.0, 223.0, 126.0, "pods"));
        ArrayPush(out, CMConsole.L(n"leg_r", 245.0, 231.0, 211.0, 404.0, "leg_r"));
        ArrayPush(out, CMConsole.L(n"leg_l", 125.0, 254.0, 198.0, 360.0, "leg_l"));
        ArrayPush(out, CMConsole.L(n"arm_r", 352.0, 93.0, 225.0, 156.0, "arm_r"));
        ArrayPush(out, CMConsole.L(n"torso", 109.0, 39.0, 344.0, 374.0, "torso"));
        ArrayPush(out, CMConsole.L(n"arm_l", 5.0, 33.0, 224.0, 165.0, "arm_l"));
        ArrayPush(out, CMConsole.L(n"sensor", 209.0, 5.0, 252.0, 155.0, "sensor"));

        let pod = CMConsole.L(n"pod", 245.0, -20.0, 101.0, 114.0, "pod");
        pod.own = true;
        ArrayPush(out, pod);
        break;
      case "octant":
        ArrayPush(out, CMConsole.L(n"octant_body", 100.0, 16.0, 335.0, 539.0, "body"));
        ArrayPush(out, CMConsole.L(n"octant_thruster_fl", 5.0, 137.0, 132.0, 138.0, "thruster_fl"));
        ArrayPush(out, CMConsole.L(n"octant_thruster_fr", 401.0, 137.0, 132.0, 138.0, "thruster_fr"));
        ArrayPush(out, CMConsole.L(n"octant_thruster_bl", 11.0, 310.0, 126.0, 136.0, "thruster_bl"));
        ArrayPush(out, CMConsole.L(n"octant_thruster_br", 400.0, 310.0, 127.0, 136.0, "thruster_br"));
        ArrayPush(out, CMConsole.L(n"octant_gun", 242.0, 5.0, 53.0, 56.0, "gun"));
        ArrayPush(out, CMConsole.L(n"octant_rocket_l", 43.0, 225.0, 81.0, 109.0, "rocket_l"));
        ArrayPush(out, CMConsole.L(n"octant_rocket_r", 413.0, 225.0, 81.0, 109.0, "rocket_r"));
        ArrayPush(out, CMConsole.L(n"octant_mortar", 206.0, 348.0, 162.0, 202.0, "mortar"));
        ArrayPush(out, CMConsole.L(n"octant_sensor", 191.0, 15.0, 156.0, 102.0, "sensor"));
        break;
      case "wyvern":
        ArrayPush(out, CMConsole.L(n"wyvern_body", 42.0, 5.0, 189.0, 337.0, "body"));
        ArrayPush(out, CMConsole.L(n"wyvern_arm_l", 146.0, 52.0, 123.0, 205.0, "arm_l"));
        ArrayPush(out, CMConsole.L(n"wyvern_arm_r", 5.0, 101.0, 145.0, 189.0, "arm_r"));
        ArrayPush(out, CMConsole.L(n"wyvern_gun", 170.0, 324.0, 28.0, 31.0, "gun"));
        break;
      case "griffin":
        ArrayPush(out, CMConsole.L(n"griffin_body", 31.0, 46.0, 250.0, 309.0, "body"));
        ArrayPush(out, CMConsole.L(n"griffin_wing_l", 6.0, 5.0, 79.0, 246.0, "wing_l"));
        ArrayPush(out, CMConsole.L(n"griffin_wing_r", 227.0, 5.0, 80.0, 246.0, "wing_r"));
        break;
      case "bombus":
        ArrayPush(out, CMConsole.L(n"bombus_arm_back", 81.0, 5.0, 137.0, 99.0, "body"));
        ArrayPush(out, CMConsole.L(n"bombus_arm_l", 297.0, 69.0, 107.0, 119.0, "body"));
        ArrayPush(out, CMConsole.L(n"bombus_arm_r", 5.0, 156.0, 139.0, 112.0, "body"));
        ArrayPush(out, CMConsole.L(n"bombus_body", 82.0, 40.0, 253.0, 253.0, "body"));
        ArrayPush(out, CMConsole.L(n"bombus_payload", 191.0, 205.0, 130.0, 150.0, "payload"));
        break;
    }
    return out;
  }

  private static func L(tex: CName, x: Float, y: Float, w: Float, h: Float, part: String) -> ref<CMConLayer> {
    let l = new CMConLayer();
    l.tex = tex;
    l.x = x;
    l.y = y;
    l.w = w;
    l.h = h;
    l.part = part;
    return l;
  }

  public static func LayerFor(kind: String, part: String) -> ref<CMConLayer> {
    for l in CMConsole.Layers(kind) {
      if Equals(l.part, part) {
        return l;
      }
    }
    return null;
  }

  public static func Chrome(p: ref<TKPage>, page: String) -> Void {
    p.Region("ribbon");
    p.Custom("con_ribbon", page, "", "", "", false);
    p.Region("rack");
    p.Custom("con_rack", page, "", "", "", false);
    p.Region("ops");
    p.Custom("con_ops", page, "", "", "", false);
    p.Region("deck");
    p.Custom("con_deck", page, "", "", "", false);
  }

  public static func Stage(p: ref<TKPage>) -> Void {
    p.Custom("con_stage", "", "", "", "", true);
  }

  public static func IsOverlay(page: String) -> Bool = Equals(page, "tacmap") || Equals(page, "req")

  public static func Overlay(p: ref<TKPage>, page: String, arg: String) -> Void {

    p.SetOverlayBack(false);
    if Equals(page, "tacmap") {
      if Equals(arg, "drop") {
        p.SetTitle(CMText.CslMechDrop(), "");
      } else {
      if Equals(arg, "drone") {
        p.SetTitle(CMText.CslDroneOrders(), "");
      } else {
        p.SetTitle(CMText.CslTacMap(), "");
      }
      }
      p.Custom("con_map", arg, "", "", "", true);
      return;
    }
    p.SetTitle(CMText.CslRequisition(), "");
    p.Custom("con_req", arg, "", "", "", true);
  }

  public static func Make(c: ref<CMContent>, v: ref<TKView>, parent: ref<inkCompoundWidget>, r: ref<TKRow>) -> ref<TKCustom> {
    let w = v.RowWidth();
    let h = v.Height();
    switch r.text {
      case "con_ribbon": return CMConRibbon.Make(c, v, parent, w, h);
      case "con_rack": return CMConRack.Make(c, v, parent, w, h);
      case "con_stage": return CMConStage.Make(c, v, parent, w, h);
      case "con_ops": return CMConOps.Make(c, v, parent, w, h);
      case "con_deck": return CMConDeck.Make(c, v, parent, w, h, r.value);
      case "con_map": return CMConMap.Make(c, v, parent, w, h - 130.0, r.value);
      case "con_req": return CMConReq.Make(c, v, parent, w, h - 130.0, r.value);
    }
    return null;
  }

  public static func Act(c: ref<CMContent>, p: ref<TKPage>, action: String, arg: String) -> Void {
    let game = c.game;
    let con = c.Con();
    let fleet = CMFleet.Get(game);
    let link = CMLinkSystem.Get(game);
    let cfg = CMPilotSystem.Get(game);
    let b = CMConsole.Selected(game, con);
    switch action {
      case "con_sel":
        con.sel = StringToInt(arg, 0);
        con.hp = "";
        let nb = CMConsole.Selected(game, con);
        if IsDefined(nb) && !nb.owned && con.mode == 1 || IsDefined(nb) && !nb.owned && con.mode == 2 {
          con.mode = 0;
        }
        CMConsole.Panes(p);
        break;
      case "con_mode":
        con.mode = Clamp(StringToInt(arg, 0), 0, 3);
        con.hp = "";
        CMConsole.Panes(p);
        break;
      case "con_hp":
        con.hp = arg;
        if IsDefined(b) && b.owned {
          con.mode = 1;
          let slot = CMConsole.SlotOf(game, b, arg);
          if StrLen(slot) > 0 && !Equals(slot, "back") {
            p.Overlay("req", slot);
          }
        }
        CMConsole.Panes(p);
        break;
      case "con_deploy":
        if IsDefined(b) && b.bay >= 0 {
          con.Say(fleet.Deploy(b.bay));
        } else {
          con.Say("!" + CMText.CslNotYours());
        }
        CMConsole.Panes(p);
        break;
      case "con_recall":
        if IsDefined(b) && b.bay >= 0 && b.out {
          con.Say(fleet.Recall());
        } else {
          con.Say(IsDefined(b) && b.bay < 0 ? "!" + CMText.CslNotYours() : "!" + CMText.CslAtMotorPool());
        }
        CMConsole.Panes(p);
        break;
      case "con_pilot":
        if !IsDefined(b) || !b.linked {
          con.Say("!" + CMText.CslNotDeployed());
          CMConsole.Panes(p);
          break;
        }
        let session = CMCSession.Get(game);
        let why = session.CanPilot();
        if StrLen(why) > 0 {
          con.Say(why);
          CMConsole.Panes(p);
          break;
        }
        CMTerminal.CloseOpen(game);
        session.RequestBegin(0.4);
        p.skipRedraw = true;
        break;
      case "con_order":
        if !IsDefined(b) || !b.linked {
          con.Say("!" + CMText.CslNotDeployed());
        } else {

          p.EndOverlay("");
          con.dropOk = false;
          con.pickDrone = false;
          fleet.SetEscort(Equals(arg, "circle"));
          switch arg {
            case "circle":
              con.Say("*" + CMText.CslCircling(b.name));
              break;
            case "follow":
              link.Follow();
              con.Say("*" + CMText.CslFollowingV(b.name));
              break;
            case "move":
              link.MoveToLookAt();
              con.Say("*" + CMText.CslMovingToTarget(b.name));
              break;
            default:
              link.Hold();
              con.Say("*" + CMText.CslHolding(b.name));
              break;
          }
        }
        CMConsole.Panes(p);
        break;
      case "con_unlink":
        link.Unlink();
        con.Say("*" + CMText.CslLinkClosed());
        con.sel = 0;
        CMConsole.Panes(p);
        break;
      case "con_avdrop":
        let player = GetPlayer(game);
        if !IsDefined(b) || !b.linked || !IsDefined(player) {
          con.Say("!" + CMText.CslDeployFirst());
        } else {
          let why = CMNce.AirliftCallIn(b.unit, player.GetWorldPosition(), CMPilotRig.YawOf(player.GetWorldForward()));
          con.Say(StrLen(why) == 0 ? "*" + CMText.CslAvInbound(b.name) : why);
        }
        CMConsole.Panes(p);
        break;
      case "con_repair":
        if IsDefined(b) && b.bay >= 0 {
          con.Say(fleet.Repair(b.bay));
        }
        CMConsole.Panes(p);
        break;
      case "con_partsrepair":

        if IsDefined(b) && b.bay >= 0 {
          con.Say(fleet.RepairParts(b.bay));
        }
        CMConsole.Panes(p);
        break;
      case "con_fab":
        con.Say(fleet.Fab(arg));
        CMConsole.Panes(p);
        break;
      case "con_assemble":
        let made = fleet.Assemble();
        con.Say(made);
        if StrBeginsWith(made, "*") {
          let ai = 0;
          let ak = 0;
          while ak < 4 {
            if fleet.Owned(ak) {
              ai += 1;
            }
            ak += 1;
          }
          con.sel = ai;

          p.Overlay("req", "payload");
        }
        CMConsole.Panes(p);
        break;
      case "con_fit":

        let arm = StrBeforeFirst(arg, ":");
        let gid = CMWeaponSpecs.ArmGunId(StringToInt(StrAfterFirst(arg, ":"), 0));
        if CMConsole.Get(fleet, con, "gun_" + gid) {
          fleet.SetFit(arm + "=" + gid, true);
          CMConsole.ReapplyMech(game);
          con.Say("*" + CMText.CslArmFitted(Equals(arm, "arm_l") ? CMText.CslLArm() : CMText.CslRArm(), CMConsole.GunName(gid)));
        }
        CMConsole.Panes(p);
        break;
      case "con_toggle":

        if fleet.Has(arg) && fleet.Fitted(arg) {
          fleet.SetFit(arg, false);
          CMConsole.ReapplyMech(game);
          con.Say("*" + CMText.CslItemRemoved(CMConsole.ItemName(arg)));
        } else {
          if CMConsole.Get(fleet, con, arg) {
            fleet.SetFit(arg, true);
            CMConsole.ReapplyMech(game);
            con.Say("*" + CMText.CslItemFitted(CMConsole.ItemName(arg)));
          }
        }
        CMConsole.Panes(p);
        break;
      case "con_livery":
        if CMConsole.Get(fleet, con, "livery_" + arg) {
          fleet.SetFit("livery=" + arg, true);
          CMConsole.Repaint(game, arg);
          con.Say("*" + CMText.CslLiverySet(CMConsole.LiveryName(arg)));
        }
        CMConsole.Panes(p);
        break;
      case "con_dlivery":

        if IsDefined(b) && b.owned && b.bay > 0 {
          let dk = b.kind;
          if StrLen(arg) == 0 || CMConsole.Get(fleet, con, "dlivery_" + dk + "_" + arg) {
            fleet.SetFit("dlivery_" + dk + "=" + arg, StrLen(arg) > 0);
            if fleet.OutBay() == b.bay && IsDefined(fleet.OutUnit()) && StrLen(arg) > 0 {
              fleet.OutUnit().ScheduleAppearanceChange(StringToName(arg));
            }
            con.Say("*" + (StrLen(arg) == 0 ? CMText.CslDronePaintNext(StrUpper(dk), CMConsole.DroneLiveryName(arg)) : CMText.CslDronePaint(StrUpper(dk), CMConsole.DroneLiveryName(arg))));
          }
        }
        CMConsole.Panes(p);
        break;
      case "con_payload":
        if CMConsole.Get(fleet, con, "payload_" + arg) {
          fleet.SetFit("payload=" + arg, true);
          con.Say("*" + CMText.CslPayloadSet(CMConsole.PayloadName(StringToInt(arg, 1))));
        }
        CMConsole.Panes(p);
        break;
      case "con_buyunit":
        let ub = StringToInt(arg, 0);
        let bought = fleet.Buy("unit_" + arg);
        con.Say(StrBeginsWith(bought, "*") ? "*" + CMText.CslUnitBought(CMFleet.Name(ub)) : bought);
        if StrBeginsWith(bought, "*") {

          let idx = 0;
          let k = 0;
          while k < ub {
            if fleet.Owned(k) {
              idx += 1;
            }
            k += 1;
          }
          con.sel = idx;
          p.EndOverlay("");
        }
        CMConsole.Panes(p);
        break;
      case "con_map":
        p.Overlay("tacmap", "");
        break;
      case "con_dropmap":
        con.dropOk = false;
        con.pickDrone = false;
        p.Overlay("tacmap", "drop");
        break;
      case "con_ordermap":

        con.dropOk = false;
        con.pickDrone = true;
        p.Overlay("tacmap", "drone");
        break;
      case "con_dloiter":
      case "con_dhold":
        if !con.dropOk {
          con.Say("!" + CMText.CslClickMapFirst());
          CMConsole.Panes(p);
          break;
        }
        let loiter = Equals(action, "con_dloiter");
        let pmsg = fleet.SendTo(con.dropAt, loiter);
        con.Say(pmsg);
        if StrBeginsWith(pmsg, "*") {
          p.EndOverlay("");
        }
        CMConsole.Panes(p);
        break;
      case "con_droppick":

        let player = GetPlayer(game);
        con.dropOk = false;
        if IsDefined(player) {
          let me = player.GetWorldPosition();
          let px = me.X + StringToFloat(StrBeforeFirst(arg, ","), 0.0);
          let py = me.Y + StringToFloat(StrAfterFirst(arg, ","), 0.0);
          let hit: TraceResult;
          let most = con.pickDrone ? 400.0 : 250.0;
          if Vector4.Distance2D(me, new Vector4(px, py, me.Z, 1.0)) > most {
            con.Say("!" + CMText.CslTooFar(IntToString(RoundF(most))));
          } else {
            if CMGround.Down(game, new Vector4(px, py, me.Z + 80.0, 1.0), new Vector4(px, py, me.Z - 80.0, 1.0), hit) {
              con.dropAt = Cast<Vector4>(hit.position);
              con.dropAt.W = 1.0;
              con.dropOk = true;
              con.Say("*" + (con.pickDrone ? CMText.CslPointMarked(IntToString(RoundF(Vector4.Distance2D(me, con.dropAt)))) : CMText.CslSpotMarked(IntToString(RoundF(Vector4.Distance2D(me, con.dropAt))))));
            } else {
              con.Say("!" + CMText.CslNoGround());
            }
          }
        }
        CMConsole.Panes(p);
        break;
      case "con_drop":
        if !con.dropOk {
          con.Say("!" + CMText.CslPickSpotFirst());
          CMConsole.Panes(p);
          break;
        }
        let dmsg = fleet.DropMech(con.dropAt);
        con.Say(dmsg);
        con.dropOk = false;
        if StrBeginsWith(dmsg, "*") {
          CMTerminal.CloseOpen(game);
          p.skipRedraw = true;
          break;
        }
        CMConsole.Panes(p);
        break;
      case "con_req":

        if !IsDefined(b) || !b.owned || Equals(arg, "units") {
          p.Overlay("req", "units");
        } else {
          p.Overlay("req", arg);
        }
        break;
      case "con_back":
        p.EndOverlay("");
        if !Equals(p.page, "console") && !CMConsole.IsOverlay(p.page) {
          p.GoTo("console", "");
        }
        break;
      case "con_settings":
        p.GoTo(Equals(p.page, "settings") ? "console" : "settings", "");
        break;
    }
  }

  private static func Panes(p: ref<TKPage>) -> Void {
    p.Refresh("ribbon");
    p.Refresh("rack");
    p.Refresh("stage");
    p.Refresh("ops");
    p.Refresh("deck");
  }

  public static func SlotOf(game: GameInstance, b: ref<CMConBay>, hp: String) -> String {
    for part in CMConsole.Parts(game, b) {
      if Equals(part.id, hp) {
        return part.slot;
      }
    }
    return "";
  }

  private static func ReapplyMech(game: GameInstance) -> Void {
    let fleet = CMFleet.Get(game);
    if fleet.OutBay() == 0 {
      let unit = fleet.OutUnit();
      if IsDefined(unit) {
        CMPartLab.Apply(unit);
      }
    }
  }

  private static func Repaint(game: GameInstance, livery: String) -> Void {
    let fleet = CMFleet.Get(game);
    if fleet.OutBay() != 0 {
      return;
    }
    let unit = fleet.OutUnit();
    if !IsDefined(unit) {
      return;
    }
    let cfg = CMPilotSystem.Get(game);
    unit.ScheduleAppearanceChange(CMPartLab.LookFor(livery, cfg, CMPartLab.ArmGone(unit, true), CMPartLab.ArmGone(unit, false)));
    let again = new CMPartLabReapply();
    again.unit = unit;
    GameInstance.GetDelaySystem(game).DelayCallback(again, 1.5, false);
  }

  public static func Get(fleet: ref<CMFleet>, con: ref<CMConState>, item: String) -> Bool {
    if fleet.Has(item) {
      return true;
    }
    let msg = fleet.Buy(item);
    if !StrBeginsWith(msg, "*") {
      con.Say(msg);
      return false;
    }
    return true;
  }

  public static func ItemName(item: String) -> String {
    switch item {
      case "bags": return CMText.CslBags();
      case "hullpod": return CMText.CslRocketRainPod();
      case "counter": return CMText.CslCountermeasures();
    }
    if StrBeginsWith(item, "up_") {
      return CMConsole.UpName(StrAfterFirst(item, "up_"));
    }
    return StrUpper(item);
  }

  public static func Offer(fleet: ref<CMFleet>, item: String, fitted: Bool) -> String {
    if !fleet.Has(item) {
      return CMText.CslBuy(CMCon.Money(CMFleet.Price(item)));
    }
    return fitted ? CMText.CslRemove() : CMText.CslFit();
  }

  public static func OfferWhy(fleet: ref<CMFleet>, item: String) -> String {
    if fleet.Has(item) {
      return "";
    }
    let why = fleet.CantBuy(item);
    return Equals(why, "CAN'T AFFORD") ? CMText.CslCantAfford(CMCon.Money(CMFleet.Price(item))) : why;
  }

  public static func Liveries() -> array<String> = ["mnc_default", "mnc_militech_01", "mnc_arasaka_01", "mnc_police_01", "mnc_kurt"]

  public static func DroneLiveries(kind: String) -> array<String> {
    switch kind {
      case "octant": return ["", "militech_01", "arasaka_01", "kang_tao_01", "border_patrol_01", "traumateam_01"];
      case "wyvern": return ["", "militech_01", "arasaka_01"];
      case "griffin": return ["", "griffin_arasaka_01", "griffin_kangtao_01", "griffin_police_01"];
    }
    return ["", "surveillance_drone_01", "surveillance_police_01", "surveillance_netwatch_01", "surveillance_service_01"];
  }

  public static func DroneLiveryName(id: String) -> String {
    switch id {
      case "": return CMText.CslFactory();
      case "militech_01": return "MILITECH";
      case "arasaka_01": return "ARASAKA";
      case "griffin_arasaka_01": return "ARASAKA";
      case "kang_tao_01": return "KANG TAO";
      case "griffin_kangtao_01": return "KANG TAO";
      case "border_patrol_01": return CMText.CslBorderPatrol();
      case "traumateam_01": return "TRAUMA TEAM";
      case "griffin_police_01": return "NCPD";
      case "surveillance_police_01": return "NCPD";
      case "surveillance_netwatch_01": return "NETWATCH";
      case "surveillance_service_01": return CMText.CslCityService();
      case "surveillance_drone_01": return CMText.CslSurveillance();
    }
    return StrUpper(id);
  }

  public static func LiveryName(id: String) -> String {
    switch id {
      case "mnc_default": return CMText.CslFactoryGrey();
      case "mnc_arasaka_01": return "ARASAKA";
      case "mnc_police_01": return "NCPD";
      case "mnc_kurt": return CMText.CslKurts();
    }
    return "MILITECH";
  }

  public static func UpName(up: String) -> String {
    switch up {
      case "cooling": return CMText.CslCooling();
      case "feed": return CMText.CslAmmoFeed();
      case "jets": return CMText.CslJumpJets();
    }
    return CMText.CslShield();
  }

}
