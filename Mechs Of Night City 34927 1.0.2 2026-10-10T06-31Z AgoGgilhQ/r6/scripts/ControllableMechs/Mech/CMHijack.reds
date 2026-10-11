module ControllableMechs

import TerminalKit.*
import ControllableMechs.Control.*

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
  let r = wrappedMethod(evt);
  if IsDefined(evt.staticData) {
    let tags = evt.staticData.GameplayTags();
    if ArrayContains(tags, n"MNC_NeuralHijack") {
      CMHijack.Get(this.GetGame()).Neural(this);
    } else {
      if ArrayContains(tags, n"MNC_SensorHijack") {
        CMHijack.Get(this.GetGame()).Sensor(this);
      }
    }
  }
  return r;
}

public class CMHijackTick extends DelayCallback {
  public let sys: wref<CMHijack>;
  public let gen: Int32;
  public let kind: Int32;
  public func Call() -> Void {
    if IsDefined(this.sys) {
      this.sys.Fire(this.gen, this.kind);
    }
  }
}

public class CMHijack extends ScriptableSystem {
  private persistent let m_given: Bool;
  private persistent let m_given32: Bool;
  private let m_stackIDs: array<EntityID>;
  private let m_stackN: array<Int32>;
  private let m_rogue: wref<NPCPuppet>;
  private let m_rogueUntil: Float;
  private let m_rogueGen: Int32;
  private let m_crash: ref<CMUDrone>;
  private let m_crashDrone: wref<NPCPuppet>;
  private let m_crashT: Float;
  private let m_crashLast: Float;
  private let m_crashGen: Int32;
  private let m_crashSide: Float;

  public static func Get(game: GameInstance) -> ref<CMHijack> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"ControllableMechs.CMHijack") as CMHijack;
  }

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    this.m_rogueGen += 1;
    this.m_crashGen += 1;
    this.m_crash = null;
    ArrayClear(this.m_stackIDs);
    ArrayClear(this.m_stackN);

    if !this.m_given {
      let player = GetPlayer(this.GetGameInstance());
      if IsDefined(player) {
        let ts = GameInstance.GetTransactionSystem(this.GetGameInstance());
        ts.GiveItem(player, ItemID.FromTDBID(t"Items.MNC_NeuralHijackProgram"), 1);

        this.m_given = true;
        this.m_given32 = true;
      }
    }
    this.Refresh();
    this.Diag();
  }

  private func Refresh() -> Void {
    if this.m_given32 {
      return;
    }
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) {
      return;
    }
    let ts = GameInstance.GetTransactionSystem(this.GetGameInstance());
    let gone = 0;
    let k = 0;
    while k < 5 {
      if ts.RemoveItemByTDBID(player, t"Items.MNC_NeuralHijackProgram", 1) {
        gone += 1;
      }
      if ts.RemoveItemByTDBID(player, t"Items.MNC_SensorHijackProgram", 1) {
        gone += 1;
      }
      k += 1;
    }
    ts.GiveItem(player, ItemID.FromTDBID(t"Items.MNC_NeuralHijackProgram"), 1);
    this.m_given32 = true;
    this.m_given = true;
  }

  private func Diag() -> Void {
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    let rec = TweakDBInterface.GetItemRecord(t"Items.MNC_NeuralHijackProgram");
    let s = "hijack diag: ";
    if IsDefined(rec) {
      s += "iconPath '" + rec.IconPath() + "'";
      let ic = rec.Icon();
      s += IsDefined(ic) ? ", icon " + TDBID.ToStringDEBUG(ic.GetID()) + " part '" + NameToString(ic.AtlasPartName()) + "' atlas " + (ResRef.IsValid(ic.AtlasResourcePath()) ? "set" : "EMPTY") : ", icon NONE";
    } else {
      s += "item record MISSING";
    }
    let ui = TweakDBInterface.GetUIIconRecord(t"UIIcon.MNC_NeuralHijack");
    s += IsDefined(ui) ? "; UIIcon.MNC_NeuralHijack part '" + NameToString(ui.AtlasPartName()) + "'" : "; UIIcon.MNC_NeuralHijack MISSING";
    let act = TweakDBInterface.GetObjectActionRecord(t"QuickHack.MNC_NeuralHijackHack");
    if IsDefined(act) {
      let ac = TweakDBInterface.GetStatModifierGroupRecord(TDB.GetForeignKey(act.GetID() + t".awarenessCost"));
      if IsDefined(ac) {
        let mods: array<wref<StatModifier_Record>>;
        ac.StatModifiers(mods);
        s += "; trace cost " + TDBID.ToStringDEBUG(ac.GetID()) + " with " + IntToString(ArraySize(mods)) + " modifiers";
      } else {
        s += "; trace cost NONE";
      }
    }
    if IsDefined(player) {
      let ts = GameInstance.GetTransactionSystem(game);
      let list: array<wref<gameItemData>>;
      ts.GetItemList(player, list);
      let loose = 0;
      for d in list {
        if IsDefined(d) && ItemID.GetTDBID(d.GetID()) == t"Items.MNC_NeuralHijackProgram" {
          loose += d.GetQuantity();
        }
      }
      s += "; " + IntToString(loose) + " in the backpack";
      let eq = GameInstance.GetScriptableSystemsContainer(game).Get(n"EquipmentSystem") as EquipmentSystem;
      if IsDefined(eq) {
        let deck = eq.GetItemInEquipSlot(player, gamedataEquipmentArea.SystemReplacementCW, 0);
        let dd = ts.GetItemData(player, deck);
        if IsDefined(dd) {
          let parts: array<InnerItemData>;
          dd.GetItemParts(parts);
          let inDeck = 0;
          let sensor = 0;
          for p in parts {
            let pid = ItemID.GetTDBID(InnerItemData.GetItemID(p));
            if pid == t"Items.MNC_NeuralHijackProgram" {
              inDeck += 1;
            }
            if pid == t"Items.MNC_SensorHijackProgram" {
              sensor += 1;
            }
          }
          s += ", " + IntToString(inDeck) + " in the deck (" + IntToString(ArraySize(parts)) + " programs slotted; Sensor Hijack " + IntToString(sensor) + ")";
        } else {
          s += ", no cyberdeck found";
        }
      }
    }
  }
  private func Now() -> Float = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGameInstance()))

  private func Later(delay: Float, kind: Int32, gen: Int32) -> Void {
    let cb = new CMHijackTick();
    cb.sys = this;
    cb.gen = gen;
    cb.kind = kind;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, delay, false);
  }

  public func Fire(gen: Int32, kind: Int32) -> Void {
    switch kind {
      case 0:
        if gen == this.m_rogueGen {
          this.RogueTick();
        }
        break;
      case 1:
        if gen == this.m_crashGen {
          this.CrashFrame();
        }
        break;
      default:
        let s = CMCSession.Get(this.GetGameInstance());
        if IsDefined(s) && !s.IsActive() {
          s.RequestBegin(0.0);
        }
        break;
    }
  }

  public static func SensorOn() -> Bool = false

  private static func IsDrone(npc: ref<NPCPuppet>) -> Bool = IsDefined(npc) && Equals(npc.GetNPCType(), gamedataNPCType.Drone)

  public func Neural(npc: ref<NPCPuppet>) -> Void {
    if !CMHijack.IsDrone(npc) || !ScriptedPuppet.IsAlive(npc) {
      return;
    }
    let game = this.GetGameInstance();
    let link = CMLinkSystem.Get(game);
    let player = GetPlayer(game);
    let msg = link.Hijack(npc);
    if IsDefined(player) {

      TKHud.SetTheme("cm_robotlink");
      if StrBeginsWith(msg, "*") {
        TKHud.Toast(CMText.HackNeural(), CMText.HackIsYours(CMLinkSystem.KindName(npc)), "", "", "", [], 2.5, false);
      } else {
        TKHud.Toast(CMText.HackNeural(), CMLinkSystem.Plain(msg), "", "", "", [], 2.5, true);
      }
    }

    this.Later(0.6, 2, 0);
  }

  public func Sensor(npc: ref<NPCPuppet>) -> Void {

    if !CMHijack.SensorOn() || !CMHijack.IsDrone(npc) || !ScriptedPuppet.IsAlive(npc) {
      return;
    }
    let n = this.Stack(npc.GetEntityID());
    if n == 1 {
      this.Blind(npc);
    } else {
      this.Crash(npc);
    }
  }

  private func Stack(id: EntityID) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_stackIDs) {
      if this.m_stackIDs[i] == id {
        this.m_stackN[i] += 1;
        return this.m_stackN[i];
      }
      i += 1;
    }
    ArrayPush(this.m_stackIDs, id);
    ArrayPush(this.m_stackN, 1);
    return 1;
  }

  private func Blind(npc: ref<NPCPuppet>) -> Void {
    let fx = CMUMinotaur.Fx(r"base\\fx\\quest\\q003\\boss_centaur\\weakspot_compensating\\weakspot_takedown_sparks.effect");
    GameInstance.GetFxSystem(this.GetGameInstance()).SpawnEffect(fx, CMUMinotaur.At(npc.GetWorldPosition() + new Vector4(0.0, 0.0, 1.0, 0.0), new Vector4(0.0, 0.0, 1.0, 0.0)), true);
    GameObject.PlaySoundEvent(npc, n"dev_generic_impact_metal");
    this.m_rogue = npc;
    this.m_rogueUntil = this.Now() + 30.0;
    this.m_rogueGen += 1;
    let player = GetPlayer(this.GetGameInstance());
    if IsDefined(player) {
      player.SetWarningMessage(CMText.HackBlinded(CMLinkSystem.KindName(npc)));
    }
    this.RogueTick();
  }

  private func RogueTick() -> Void {
    let npc = this.m_rogue;
    if !IsDefined(npc) || !ScriptedPuppet.IsAlive(npc) || this.Now() > this.m_rogueUntil {
      this.m_rogue = null;
      return;
    }
    let me = npc.GetAttitudeAgent();
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(me) || !IsDefined(player) {
      return;
    }
    me.SetAttitudeTowards(player.GetAttitudeAgent(), EAIAttitude.AIA_Hostile);
    let q: TargetSearchQuery;
    q.testedSet = TargetingSet.Complete;
    q.searchFilter = TSF_All(TSFMV.Obj_Puppet | TSFMV.St_AliveAndActive);
    q.maxDistance = Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) + 45.0;
    q.filterObjectByDistance = true;
    q.includeSecondaryTargets = false;
    q.ignoreInstigator = true;
    let parts: array<TS_TargetPartInfo>;
    GameInstance.GetTargetingSystem(this.GetGameInstance()).GetTargetParts(player, q, parts);
    let n = 0;
    for p in parts {
      let comp = TS_TargetPartInfo.GetComponent(p);
      if IsDefined(comp) {
        let other = comp.GetEntity() as ScriptedPuppet;
        if IsDefined(other) && other != npc && Vector4.Distance(other.GetWorldPosition(), npc.GetWorldPosition()) < 40.0 {
          let oa = other.GetAttitudeAgent();
          if IsDefined(oa) {
            me.SetAttitudeTowards(oa, EAIAttitude.AIA_Hostile);
            oa.SetAttitudeTowards(me, EAIAttitude.AIA_Hostile);
            n += 1;
          }
        }
      }
    }
    if n > 0 {
    }
    this.Later(1.0, 0, this.m_rogueGen);
  }

  private func Crash(npc: ref<NPCPuppet>) -> Void {
    if IsDefined(this.m_crash) {
      return;
    }
    let link = CMLinkSystem.Get(this.GetGameInstance());
    if link.IsLinkedTo(npc.GetEntityID()) {
      link.Unlink();
    }
    let unit = new CMUDrone();
    unit.forDrone = npc;
    let why = unit.Begin(CMCSession.Get(this.GetGameInstance()));
    if StrLen(why) > 0 {
      this.Wreck(npc);
      return;
    }
    unit.autoOn = true;
    unit.autoH = CMPilotRig.YawOf(npc.GetWorldForward());
    this.m_crashSide = RandF() < 0.5 ? -1.0 : 1.0;
    unit.autoF = 0.4;
    unit.autoS = this.m_crashSide;
    unit.autoC = -1.0;
    this.m_crash = unit;
    this.m_crashDrone = npc;
    this.m_crashT = 0.0;
    this.m_crashLast = this.Now();
    this.m_crashGen += 1;
    let player = GetPlayer(this.GetGameInstance());
    if IsDefined(player) {
      player.SetWarningMessage(CMText.HackFlightLost(CMLinkSystem.KindName(npc)));
    }
    this.Later(0.016, 1, this.m_crashGen);
  }

  private func CrashFrame() -> Void {
    let unit = this.m_crash;
    let npc = this.m_crashDrone;
    if !IsDefined(unit) || !IsDefined(npc) {
      this.m_crash = null;
      return;
    }
    let now = this.Now();
    let dt = ClampF(now - this.m_crashLast, 0.0, 0.1);
    this.m_crashLast = now;
    this.m_crashT += dt;
    if !ScriptedPuppet.IsAlive(npc) || this.m_crashT > 7.0 {
      this.EndCrash(npc);
      return;
    }

    unit.autoS = this.m_crashSide;
    unit.autoC = -1.0;
    unit.autoH = unit.FlightYaw() + this.m_crashSide * 140.0 * dt;
    unit.Tick(CMCSession.Get(this.GetGameInstance()), dt, now);

    if this.m_crashT > 1.0 && Vector4.Length(unit.FlightVel()) < 2.0 {
      this.EndCrash(npc);
      return;
    }
    this.Later(0.016, 1, this.m_crashGen);
  }

  private func EndCrash(npc: ref<NPCPuppet>) -> Void {
    this.m_crashGen += 1;
    if IsDefined(npc) && ScriptedPuppet.IsAlive(npc) {
      this.Wreck(npc);
    }
    if IsDefined(this.m_crash) {
      this.m_crash.autoOn = false;
      this.m_crash.End(CMCSession.Get(this.GetGameInstance()), false);
    }
    this.m_crash = null;
  }

  private func Wreck(npc: ref<NPCPuppet>) -> Void {
    GameInstance.GetStatPoolsSystem(this.GetGameInstance()).RequestSettingStatPoolValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatPoolType.Health, 0.0, null, true);
  }
}

@wrapMethod(QuickHackableHelper)
public final static func WillHackRevealPlayer(playerRef: ref<PlayerPuppet>, targetRecordId: TweakDBID, action: ref<ScriptableDeviceAction>, opt programItemID: ItemID) -> Bool {
  let r = wrappedMethod(playerRef, targetRecordId, action, programItemID);
  if IsDefined(action) && IsDefined(action.GetObjectActionRecord()) && Equals(action.GetObjectActionRecord().ActionName(), n"MNC_NeuralHijack") {
    let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(programItemID));
    let glp = IsDefined(rec) && rec.OnAttachContains(TweakDBInterface.GetGameplayLogicPackageRecord(t"EquipmentGLP.UntraceableHack"));
  }
  return r;
}
