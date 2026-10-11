module ControllableMechs.Control

import ControllableMechs.*

@addField(NPCPuppet)
public let m_cmArmLGone: Bool;

@addField(NPCPuppet)
public let m_cmArmRGone: Bool;

@addField(NPCPuppet)
public let m_cmShieldUp: Bool;

@addField(NPCPuppet)
public let m_cmShieldCharge: Float;

public abstract class CMPart {
  public static func Sensor() -> Int32 = 0
  public static func Torso() -> Int32 = 1
  public static func ArmL() -> Int32 = 2
  public static func ArmR() -> Int32 = 3
  public static func LegL() -> Int32 = 4
  public static func LegR() -> Int32 = 5
  public static func Pods() -> Int32 = 6
  public static func Count() -> Int32 = 7

  public static func Name(i: Int32) -> String {
    switch i {
      case 0: return CMText.PartSensor();
      case 1: return CMText.PartTorso();
      case 2: return "MK.31 L";
      case 3: return "MK.31 R";
      case 4: return CMText.PartLegL();
      case 5: return CMText.PartLegR();
      case 6: return CMText.PartMissilePods();
    }
    return CMText.PartPart();
  }

  public static func Share(i: Int32) -> Float {
    switch i {
      case 0: return 0.30;
      case 2: return 0.35;
      case 3: return 0.35;
      case 4: return 0.40;
      case 5: return 0.40;
      case 6: return 0.30;
    }
    return 1.0;
  }
}

@addField(ScriptedPuppet)
public let m_cmTestTarget: Bool;

public class CMPartHit {
  public let part: Int32;
  public let broke: Bool;
}

public class CMPartState {
  public let id: EntityID;
  public let hp: array<Float>;
  public let fx: array<Bool>;
  public let stage: array<Int32>;
  public let fxInst: array<ref<FxInstance>>;
  public let fxPart: array<Int32>;
  public let att: array<Bool>;
  public let killed: array<Bool>;

}

public class CMCParts extends ScriptableSystem {
  private let m_states: array<ref<CMPartState>>;

  public static func Get(game: GameInstance) -> ref<CMCParts> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"ControllableMechs.Control.CMCParts") as CMCParts;
  }

  public func State(id: EntityID) -> ref<CMPartState> {
    for st in this.m_states {
      if st.id == id {
        return st;
      }
    }
    let st = new CMPartState();
    st.id = id;
    let i = 0;
    while i < CMPart.Count() {
      ArrayPush(st.hp, 1.0);
      ArrayPush(st.fx, false);
      ArrayPush(st.stage, 0);
      ArrayPush(st.att, false);
      ArrayPush(st.killed, false);
      i += 1;
    }
    ArrayPush(this.m_states, st);
    return st;
  }

  public func Restore(mech: ref<NPCPuppet>) -> Void {
    if !IsDefined(mech) {
      return;
    }
    let st = this.State(mech.GetEntityID());
    let i = 0;
    while i < CMPart.Count() {
      st.hp[i] = 1.0;
      i += 1;
    }
    CMCParts.ShowGun(mech, true, true);
    CMCParts.ShowGun(mech, false, true);
    this.Effects(mech);

    GameInstance.GetStatPoolsSystem(mech.GetGame()).RequestSettingStatPoolMaxValue(Cast<StatsObjectID>(mech.GetEntityID()), gamedataStatPoolType.Health, null);
    let session = CMCSession.Get(mech.GetGame());
    if IsDefined(session) {
      session.PartsRestored();
    }
  }

  public func Break(mech: ref<NPCPuppet>, part: Int32) -> Void {
    if !IsDefined(mech) || part < 0 || part >= CMPart.Count() || part == CMPart.Torso() {
      return;
    }
    let st = this.State(mech.GetEntityID());
    st.hp[part] = 0.0;
    if (part == CMPart.ArmL() || part == CMPart.ArmR()) && !st.killed[part] {
      st.killed[part] = true;
      CMCParts.BlowGun(mech, part == CMPart.ArmL());
      CMCParts.ShowGun(mech, part == CMPart.ArmL(), false);
    }

    this.Effects(mech);
  }

  public func Hit(mech: ref<NPCPuppet>, hit: ref<gameHitEvent>) -> ref<CMPartHit> {
    if !IsDefined(mech) || !IsDefined(hit) || !IsDefined(hit.attackData) || hit.attackData.HasFlag(hitFlag.DealNoDamage) {
      return null;
    }
    let dmg = hit.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    if dmg <= 0.0 {
      return null;
    }

    let d = hit.hitPosition - mech.GetWorldPosition();
    let fwd = mech.GetWorldForward();
    let right = CMPilotRig.Dir(CMPilotRig.YawOf(fwd) - 90.0, 0.0);
    let up = d.Z;
    let side = Vector4.Dot(d, right);
    let back = -(d.X * fwd.X + d.Y * fwd.Y);
    let zone = EHitReactionZone.Special;
    if ArraySize(hit.hitRepresentationResult.hitShapes) > 0 {
      zone = HitShapeUserDataBase.GetHitReactionZone(hit.hitRepresentationResult.hitShapes[0].userData as HitShapeUserDataBase);
    }
    let r = new CMPartHit();
    r.part = CMCParts.PartAt(zone, up, side, back);
    let game = mech.GetGame();
    if r.part == CMPart.Torso() {
      return r;
    }
    let st = this.State(mech.GetEntityID());
    let before = st.hp[r.part];
    if before <= 0.0 {
      return r;
    }
    let hull = GameInstance.GetStatPoolsSystem(game).GetStatPoolMaxPointValue(Cast<StatsObjectID>(mech.GetEntityID()), gamedataStatPoolType.Health);
    st.hp[r.part] = MaxF(0.0, before - dmg / MaxF(1.0, hull * CMPart.Share(r.part)));
    r.broke = st.hp[r.part] <= 0.0;
    return r;
  }

  public static func PartAt(zone: EHitReactionZone, up: Float, side: Float, back: Float) -> Int32 {
    switch zone {
      case EHitReactionZone.Head: return CMPart.Sensor();
      case EHitReactionZone.ArmLeft: return CMPart.ArmL();
      case EHitReactionZone.HandLeft: return CMPart.ArmL();
      case EHitReactionZone.ArmRight: return CMPart.ArmR();
      case EHitReactionZone.HandRight: return CMPart.ArmR();
      case EHitReactionZone.LegLeft: return CMPart.LegL();
      case EHitReactionZone.LegRight: return CMPart.LegR();
    }
    if up < 1.15 {
      return side < 0.0 ? CMPart.LegL() : CMPart.LegR();
    }
    if AbsF(side) > 0.62 && up > 1.6 {
      return side < 0.0 ? CMPart.ArmL() : CMPart.ArmR();
    }
    if back > 0.55 && up > 1.45 && up < 2.25 {
      return CMPart.Pods();
    }
    if up > 2.3 && AbsF(side) < 0.4 {
      return CMPart.Sensor();
    }
    return CMPart.Torso();
  }

  private let m_test: wref<NPCPuppet>;

  public func Testing() -> Bool = IsDefined(this.m_test) && this.m_test.m_cmTestTarget

  public func SetTest(mech: ref<NPCPuppet>, on: Bool) -> Void {
    if IsDefined(this.m_test) && (!on || this.m_test != mech) {
      this.m_test.m_cmTestTarget = false;
      CMLinkSystem.Get(this.m_test.GetGame()).TestAttitude(this.m_test, false);
      GameInstance.GetGodModeSystem(this.m_test.GetGame()).RemoveGodMode(this.m_test.GetEntityID(), gameGodModeType.Immortal, n"CMDamageTest");
      CMCParts.ShieldSpots(this.m_test, false);
      this.m_test = null;
    }
    if !on || !IsDefined(mech) {
      return;
    }
    mech.m_cmTestTarget = true;

    CMLinkSystem.Get(mech.GetGame()).TestAttitude(mech, true);
    GameInstance.GetGodModeSystem(mech.GetGame()).AddGodMode(mech.GetEntityID(), gameGodModeType.Immortal, n"CMDamageTest");

    CMCParts.ShieldSpots(mech, true);
    this.m_test = mech;
  }

  public func TestHit(mech: ref<NPCPuppet>, hit: ref<gameHitEvent>) -> Void {
    if !IsDefined(mech) {
      return;
    }

    CMLinkSystem.Get(mech.GetGame()).TestAttitude(mech, true);
    let r = this.Hit(mech, hit);
    if !IsDefined(r) {
      return;
    }
    if r.broke {
      this.Break(mech, r.part);
    }
    let text = CMPart.Name(r.part);
    if r.part == CMPart.Torso() {
      let hull = GameInstance.GetStatPoolsSystem(mech.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(mech.GetEntityID()), gamedataStatPoolType.Health, true);
      text += " (HULL " + IntToString(RoundF(hull)) + "%)";
    } else {
      let hp = this.State(mech.GetEntityID()).hp[r.part];
      text += hp <= 0.0 ? " BROKEN" : " " + IntToString(RoundF(hp * 100.0)) + "%";
    }
    CMCParts.Screen(mech.GetGame(), "DAMAGE TEST: " + text);
  }

  public static func ShieldSpots(mech: ref<NPCPuppet>, on: Bool) -> Void {
    let comp = mech.GetWeakspotComponent();
    if !IsDefined(comp) {
      return;
    }
    let spots: array<wref<WeakspotObject>>;
    comp.GetWeakspots(spots);
    let gods = GameInstance.GetGodModeSystem(mech.GetGame());
    for spot in spots {
      if IsDefined(spot) {
        if on {
          gods.AddGodMode(spot.GetEntityID(), gameGodModeType.Invulnerable, n"CMDamageTest");
        } else {
          gods.RemoveGodMode(spot.GetEntityID(), gameGodModeType.Invulnerable, n"CMDamageTest");
        }
      }
    }
  }

  public static func Screen(game: GameInstance, text: String) -> Void {
    let msg: SimpleScreenMessage;
    msg.isShown = true;
    msg.duration = 2.5;
    msg.message = text;
    let bb = GameInstance.GetBlackboardSystem(game).Get(GetAllBlackboardDefs().UI_Notifications);
    bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
  }

  public func Effects(mech: ref<NPCPuppet>) -> Void {
    if !IsDefined(mech) {
      return;
    }
    let st = this.State(mech.GetEntityID());
    let i = 0;
    while i < CMPart.Count() {
      let on = st.hp[i] <= 0.0 && i != CMPart.Torso();
      if NotEquals(on, st.fx[i]) {
        st.fx[i] = on;
        for name in CMCParts.EffectsOf(i) {
          if on {
            GameObjectEffectHelper.StartEffectEvent(mech, name);
          } else {
            GameObjectEffectHelper.StopEffectEvent(mech, name);
          }
        }
      }

      if on && !st.att[i] {
        st.att[i] = true;
        this.Attach(mech, st, i);
      } else {
        if !on && st.att[i] {
          st.att[i] = false;
          this.Detach(st, i);
        }
      }
      i += 1;
    }
    this.GunStage(mech, st, true);
    this.GunStage(mech, st, false);
  }

  public static func EffectsOf(part: Int32) -> array<CName> {
    switch part {
      case 0: return [n"hacks_optics_malfunction"];
      case 2: return [n"left_arm_destroyed"];
      case 3: return [n"right_arm_destroyed"];
      case 4: return [n"hacks_locomotion_malfunction", n"se_locomotion_malfunction_left"];
      case 5: return [n"hacks_locomotion_malfunction", n"se_locomotion_malfunction_right"];
    }
    return [];
  }

  private func Attach(mech: ref<NPCPuppet>, st: ref<CMPartState>, part: Int32) -> Void {
    switch part {
      case 2:
        this.AttachFx(mech, st, part, r"base\\fx\\quest\\q003\\boss_centaur\\weakspot_compensating\\weakspot_takedown_sparks.effect", n"WeakspotLeft", 0.0);
        break;
      case 3:
        this.AttachFx(mech, st, part, r"base\\fx\\quest\\q003\\boss_centaur\\weakspot_compensating\\weakspot_takedown_sparks.effect", n"WeakspotRight", 0.0);
        break;
      case 6:
        this.AttachFx(mech, st, part, r"base\\fx\\vehicles\\minotaur\\v_minotaur_smoke.effect", n"Chest", 0.35);
        this.AttachFx(mech, st, part, r"base\\fx\\vehicles\\minotaur\\v_minotaur_smoke.effect", n"Chest", -0.35);
        this.AttachFx(mech, st, part, r"base\\fx\\quest\\q003\\boss\\weakspot\\weakspot_fuel.effect", n"Chest", 0.0);
        break;
    }
  }

  public func DropFx(mech: ref<NPCPuppet>) -> Void {
    if !IsDefined(mech) {
      return;
    }
    let st = this.State(mech.GetEntityID());
    if ArraySize(st.fxInst) > 0 {
    }
    for inst in st.fxInst {
      if IsDefined(inst) {
        inst.BreakLoop();
        inst.Kill();
      }
    }
    ArrayClear(st.fxInst);
    ArrayClear(st.fxPart);
    let i = 0;
    while i < CMPart.Count() {
      st.att[i] = false;
      i += 1;
    }
  }

  public static func HasSlot(mech: ref<NPCPuppet>, slot: CName) -> Bool {
    let wt: WorldTransform;
    for comp in [n"Item_Attachment_Slot", n"Slot5006"] {
      let sc = mech.FindComponentByName(comp) as SlotComponent;
      if IsDefined(sc) && sc.GetSlotTransform(slot, wt) {
        return true;
      }
    }
    return false;
  }

  private func AttachFx(mech: ref<NPCPuppet>, st: ref<CMPartState>, part: Int32, path: ResRef, slot: CName, side: Float) -> Void {
    if !CMCParts.HasSlot(mech, slot) {
      return;
    }
    let fx: FxResource;
    ResourceAsyncRef.SetPath(fx.effect, path);
    let at: WorldTransform;
    WorldTransform.SetPosition(at, mech.GetWorldPosition());
    let inst = GameInstance.GetFxSystem(mech.GetGame()).SpawnEffect(fx, at);
    if !IsDefined(inst) {
      return;
    }
    let rel: WorldTransform;
    WorldTransform.SetPosition(rel, new Vector4(side, 0.0, 0.0, 1.0));
    inst.AttachToSlot(mech, entAttachmentTarget.Transform, slot, rel);
    ArrayPush(st.fxInst, inst);
    ArrayPush(st.fxPart, part);
  }

  private func Detach(st: ref<CMPartState>, part: Int32) -> Void {
    let i = ArraySize(st.fxInst) - 1;
    while i >= 0 {
      if st.fxPart[i] == part {
        if IsDefined(st.fxInst[i]) {
          st.fxInst[i].BreakLoop();
          st.fxInst[i].Kill();
        }
        ArrayErase(st.fxInst, i);
        ArrayErase(st.fxPart, i);
      }
      i -= 1;
    }
  }

  private func GunStage(mech: ref<NPCPuppet>, st: ref<CMPartState>, left: Bool) -> Void {
    let part = left ? CMPart.ArmL() : CMPart.ArmR();
    let hp = st.hp[part];
    let stage = hp < 0.35 ? 2 : (hp < 0.7 ? 1 : 0);
    if stage == st.stage[part] {
      return;
    }
    if st.killed[part] {
      st.stage[part] = stage;
      return;
    }
    let spot = CMCParts.Spot(mech, left);
    if IsDefined(spot) {
      if stage >= 1 && st.stage[part] < 1 {
        GameObjectEffectHelper.StartEffectEvent(spot, n"weakspot_damage_stage_01");
      }
      if stage >= 2 && st.stage[part] < 2 {
        GameObjectEffectHelper.StartEffectEvent(spot, n"weakspot_damage_stage_02");
      }
      if stage < st.stage[part] {
        GameObjectEffectHelper.StopEffectEvent(spot, n"weakspot_damage_stage_01");
        GameObjectEffectHelper.StopEffectEvent(spot, n"weakspot_damage_stage_02");
      }
    }
    st.stage[part] = stage;
  }

  public static func Spot(mech: ref<NPCPuppet>, left: Bool) -> ref<WeakspotObject> {
    let comp = mech.GetWeakspotComponent();
    if !IsDefined(comp) {
      return null;
    }
    let spots: array<wref<WeakspotObject>>;
    comp.GetWeakspots(spots);
    let right = CMPilotRig.Dir(CMPilotRig.YawOf(mech.GetWorldForward()) - 90.0, 0.0);
    let pos = mech.GetWorldPosition();
    for spot in spots {
      if IsDefined(spot) {
        let side = Vector4.Dot(spot.GetWorldPosition() - pos, right);
        if (left && side < 0.0) || (!left && side > 0.0) {
          return spot;
        }
      }
    }
    return null;
  }

  public static func ShowGun(mech: ref<NPCPuppet>, left: Bool, on: Bool) -> Void {
    let c = mech.FindComponentByName(left ? n"mch_003__minotaur_weapons_l_01" : n"mch_003__minotaur_weapons_r_01");
    if IsDefined(c) {
      c.Toggle(on);
    }

    if left {
      mech.m_cmArmLGone = !on;
    } else {
      mech.m_cmArmRGone = !on;
    }
    CMPartLab.Apply(mech);
  }

  public static func BlowGun(mech: ref<NPCPuppet>, left: Bool) -> Void {
    let comp = mech.GetWeakspotComponent();
    if !IsDefined(comp) {
      return;
    }
    let spots: array<wref<WeakspotObject>>;
    comp.GetWeakspots(spots);
    let right = CMPilotRig.Dir(CMPilotRig.YawOf(mech.GetWorldForward()) - 90.0, 0.0);
    let pos = mech.GetWorldPosition();
    for spot in spots {
      if IsDefined(spot) {
        let side = Vector4.Dot(spot.GetWorldPosition() - pos, right);
        if (left && side < 0.0) || (!left && side > 0.0) {

          let gods = GameInstance.GetGodModeSystem(mech.GetGame());
          gods.RemoveGodMode(spot.GetEntityID(), gameGodModeType.Invulnerable, n"ControllableMechs");
          gods.RemoveGodMode(spot.GetEntityID(), gameGodModeType.Invulnerable, n"CMDamageTest");
          ScriptedWeakspotObject.Kill(spot);
        }
      }
    }
  }
}
