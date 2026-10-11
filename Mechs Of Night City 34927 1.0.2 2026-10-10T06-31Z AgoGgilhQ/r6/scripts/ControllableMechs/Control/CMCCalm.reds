module ControllableMechs.Control

import ControllableMechs.*

@addField(ScriptedPuppet)
public let m_cmPiloted: Bool;

@wrapMethod(TargetTrackingExtension)
public final static func OnHit(ownerPuppet: wref<ScriptedPuppet>, evt: ref<gameHitEvent>) -> Void {
  if IsDefined(ownerPuppet) && ownerPuppet.m_cmPiloted {
    let shooter = evt.attackData.GetInstigator();
    CMCCalm.Note(ownerPuppet, shooter, "a hit");
    CMCSession.Get(ownerPuppet.GetGame()).UnitHit(evt);

    if IsDefined(shooter) && !shooter.IsPlayer() {
      CMCSession.Get(ownerPuppet.GetGame()).HitFrom(shooter.GetWorldPosition());
    }
    return;
  }

  if IsDefined(ownerPuppet) && ownerPuppet.m_cmTestTarget {
    CMCParts.Get(ownerPuppet.GetGame()).TestHit(ownerPuppet as NPCPuppet, evt);
    return;
  }

  if IsDefined(ownerPuppet) && IsDefined(evt) && IsDefined(evt.attackData) {
    let credited = evt.attackData.GetInstigator();
    let unit = CMCCalm.FiredBy(evt, credited);
    if IsDefined(unit) && IsDefined(credited) && unit != credited {
      evt.attackData.SetInstigator(unit);
      wrappedMethod(ownerPuppet, evt);
      evt.attackData.SetInstigator(credited);

      if credited.IsPlayer() && !evt.attackData.HasFlag(hitFlag.WasKillingBlow) {
        TargetTrackingExtension.RemoveThreat(ownerPuppet, credited);
      }
      CMCCalm.Drew(ownerPuppet, unit);
      return;
    }
  }
  wrappedMethod(ownerPuppet, evt);
}

@wrapMethod(TargetTrackingExtension)
public final static func InjectThreat(puppet: wref<ScriptedPuppet>, threat: wref<Entity>, accuracy: Float, opt cooldown: Float) -> Void {
  if IsDefined(puppet) && puppet.m_cmPiloted {
    CMCCalm.Note(puppet, threat as GameObject, "a shared threat");

    CMCCalm.DrawFire(puppet, threat as ScriptedPuppet);
    return;
  }
  if IsDefined(puppet) && puppet.m_cmTestTarget {
    return;
  }
  wrappedMethod(puppet, threat, accuracy, cooldown);
}

@wrapMethod(NPCPuppet)
public final static func ChangeHighLevelState(obj: ref<GameObject>, newState: gamedataNPCHighLevelState) -> Void {
  let puppet = obj as ScriptedPuppet;
  if IsDefined(puppet) && (puppet.m_cmPiloted || puppet.m_cmTestTarget)
    && (Equals(newState, gamedataNPCHighLevelState.Alerted) || Equals(newState, gamedataNPCHighLevelState.Combat)
      || Equals(newState, gamedataNPCHighLevelState.Stealth) || Equals(newState, gamedataNPCHighLevelState.Fear)) {
    if CMPilotSystem.Get(puppet.GetGame()).ShowDebug() {
    }
    return;
  }
  wrappedMethod(obj, newState);
}

@wrapMethod(NPCStatesComponent)
public final static func AlertPuppet(ownerPuppet: wref<ScriptedPuppet>) -> Void {
  if IsDefined(ownerPuppet) && (ownerPuppet.m_cmPiloted || ownerPuppet.m_cmTestTarget) {
    return;
  }
  wrappedMethod(ownerPuppet);
}

@wrapMethod(TargetTrackingExtension)
public final static func InjectThreat(puppet: wref<ScriptedPuppet>, const threat: script_ref<TrackedLocation>) -> Void {
  if IsDefined(puppet) && (puppet.m_cmPiloted || puppet.m_cmTestTarget) {
    return;
  }
  wrappedMethod(puppet, threat);
}

@wrapMethod(TargetTrackingExtension)
public final static func InjectThreat(puppet: wref<ScriptedPuppet>, pos: Vector4, timeToLive: Float) -> Void {
  if IsDefined(puppet) && (puppet.m_cmPiloted || puppet.m_cmTestTarget) {
    return;
  }
  wrappedMethod(puppet, pos, timeToLive);
}

@wrapMethod(TargetTrackingExtension)
protected cb func OnEnemyPushedToSquad(evt: ref<EnemyPushedToSquad>) -> Bool {
  let owner = this.GetEntity() as ScriptedPuppet;
  if IsDefined(owner) && (owner.m_cmPiloted || owner.m_cmTestTarget) {
    return false;
  }
  return wrappedMethod(evt);
}

public abstract class CMCCalm {

  public static func FiredBy(evt: ref<gameHitEvent>, credited: wref<GameObject>) -> wref<GameObject> {
    let w = evt.attackData.GetWeapon();
    if IsDefined(w) {
      if w.m_cmPiloted {
        return w.GetOwner();
      }
      return null;
    }
    if IsDefined(credited) && credited.IsPlayer() {
      return CMCHits.Blamed(credited.GetGame());
    }
    return null;
  }

  public static func DrawFire(unit: wref<ScriptedPuppet>, enemy: wref<ScriptedPuppet>) -> Void {

    if !IsDefined(enemy) || !IsDefined(unit) || enemy.GetEntityID() == unit.GetEntityID() || enemy.m_cmPiloted || enemy.IsPlayer() || !ScriptedPuppet.IsAlive(enemy) {
      return;
    }
    let player = GetPlayer(unit.GetGame());
    if !IsDefined(player) {
      return;
    }

    let foeOfUnit = Equals(GameObject.GetAttitudeBetween(enemy, unit), EAIAttitude.AIA_Hostile);
    if !foeOfUnit && NotEquals(GameObject.GetAttitudeBetween(enemy, player), EAIAttitude.AIA_Hostile) {
      return;
    }
    let turned = false;
    if !foeOfUnit {
      GameObject.ChangeAttitudeToHostile(enemy, unit);
      turned = true;
    }
    TargetTrackingExtension.InjectThreat(enemy, unit);

    let tt = enemy.GetTargetTrackerComponent();
    if IsDefined(tt) {

      tt.AddThreat(unit, true, unit.GetWorldPosition(), 1.0, -1.0, false);
      tt.SetThreatAccuracy(unit, 1.0);
      tt.SetThreatBeliefAccuracy(unit, 1.0);
      tt.SetThreatBaseMul(unit, 2.0);
    }
    let cfg = CMPilotSystem.Get(unit.GetGame());

    if cfg.HideOperator() || !CMCCalm.SeesV(enemy, player) {
      TargetTrackingExtension.RemoveThreat(enemy, player);
    }
    if turned && cfg.ShowDebug() {
    }
  }

  public static func SeesV(npc: wref<ScriptedPuppet>, player: ref<PlayerPuppet>) -> Bool {
    let a = npc.GetWorldPosition() + new Vector4(0.0, 0.0, 1.6, 0.0);
    let b = player.GetWorldPosition() + new Vector4(0.0, 0.0, 1.6, 0.0);
    if Vector4.Distance(a, b) > 60.0 {
      return false;
    }
    let hit: TraceResult;
    return !CMGround.Down(npc.GetGame(), a, b, hit);
  }

  public static func Drew(victim: wref<ScriptedPuppet>, unit: wref<GameObject>) -> Void {
    if !CMPilotSystem.Get(victim.GetGame()).ShowDebug() {
      return;
    }
  }

  public static func Note(owner: wref<ScriptedPuppet>, from: wref<GameObject>, what: String) -> Void {
    if !IsDefined(owner) || !CMPilotSystem.Get(owner.GetGame()).ShowDebug() {
      return;
    }
    let who = "something";
    let dist = "?";
    if IsDefined(from) {
      who = CMCHits.Describe(from);
      dist = FloatToStringPrec(Vector4.Distance(owner.GetWorldPosition(), from.GetWorldPosition()), 1);
    }
  }
}

@wrapMethod(JumpDecisions)
protected const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && IsDefined(player.m_cmcSession) {
    if wrappedMethod(stateContext, scriptInterface) && CMPilotSystem.Get(player.GetGame()).ShowDebug() {
    }
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(CrouchDecisions)
protected const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && IsDefined(player.m_cmcSession) {
    if wrappedMethod(stateContext, scriptInterface) && CMPilotSystem.Get(player.GetGame()).ShowDebug() {
    }
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(ChargeJumpDecisions)
protected const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && IsDefined(player.m_cmcSession) {
    if wrappedMethod(stateContext, scriptInterface) && CMPilotSystem.Get(player.GetGame()).ShowDebug() {
    }
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(DoubleJumpDecisions)
protected const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && IsDefined(player.m_cmcSession) {
    if wrappedMethod(stateContext, scriptInterface) && CMPilotSystem.Get(player.GetGame()).ShowDebug() {
    }
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(HoverJumpDecisions)
protected const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && IsDefined(player.m_cmcSession) {
    if wrappedMethod(stateContext, scriptInterface) && CMPilotSystem.Get(player.GetGame()).ShowDebug() {
    }
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(ClimbDecisions)
protected const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && IsDefined(player.m_cmcSession) {
    if wrappedMethod(stateContext, scriptInterface) && CMPilotSystem.Get(player.GetGame()).ShowDebug() {
    }
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(VaultDecisions)
protected const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && IsDefined(player.m_cmcSession) {
    if wrappedMethod(stateContext, scriptInterface) && CMPilotSystem.Get(player.GetGame()).ShowDebug() {
    }
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

public abstract class CMCEquipGuard {

  public static func Guards(owner: ref<GameObject>, slot: TweakDBID) -> Bool {
    if slot != t"AttachmentSlots.WeaponLeft" && slot != t"AttachmentSlots.WeaponRight" {
      return false;
    }
    if !CMPartLab.IsPlayerMech(owner) {
      return false;
    }
    let cfg = CMPilotSystem.Get(owner.GetGame());
    return !Equals(CMLoadout.ArmGun(cfg, n"arm_l"), "mk31") || !Equals(CMLoadout.ArmGun(cfg, n"arm_r"), "mk31");
  }

  public static func Note(owner: ref<GameObject>, what: String) -> Void {
    let npc = owner as NPCPuppet;
    if !IsDefined(npc) {
      return;
    }
    let now = EngineTime.ToFloat(GameInstance.GetSimTime(owner.GetGame()));
    if now >= npc.m_cmEquipNoteAt {
      npc.m_cmEquipNoteAt = now + 5.0;
    }
  }
}

@addField(NPCPuppet)
public let m_cmEquipNoteAt: Float;

@wrapMethod(AISubActionEquipOnSlot_Record_Implementation)
public final static func Equip(context: ScriptExecutionContext, const itemsToEquip: script_ref<array<NPCItemToEquip>>, cacheEquipped: Bool) -> Bool {
  let owner = ScriptExecutionContext.GetOwner(context);
  let items = Deref(itemsToEquip);
  for it in items {
    if CMCEquipGuard.Guards(owner, it.slotID) {
      CMCEquipGuard.Note(owner, "equip");
      return true;
    }
  }
  return wrappedMethod(context, itemsToEquip, cacheEquipped);
}

@wrapMethod(AISubActionForceEquip_Record_Implementation)
public final static func Equip(context: ScriptExecutionContext, record: wref<AISubActionForceEquip_Record>) -> Bool {
  let owner = ScriptExecutionContext.GetOwner(context);
  if IsDefined(record.AttachmentSlot()) && CMCEquipGuard.Guards(owner, record.AttachmentSlot().GetID()) {
    CMCEquipGuard.Note(owner, "force equip");
    return true;
  }
  return wrappedMethod(context, record);
}

@wrapMethod(AISubActionUnequipOnSlot_Record_Implementation)
public final static func Unequip(context: ScriptExecutionContext, dropItem: Bool, itemsToUnequip: array<NPCItemToEquip>) -> Bool {
  let owner = ScriptExecutionContext.GetOwner(context);
  for it in itemsToUnequip {
    if CMCEquipGuard.Guards(owner, it.slotID) {
      CMCEquipGuard.Note(owner, "unequip");
      return true;
    }
  }
  return wrappedMethod(context, dropItem, itemsToUnequip);
}

@wrapMethod(AISubActionForceUnequip_Record_Implementation)
public final static func Unequip(context: ScriptExecutionContext, record: wref<AISubActionForceUnequip_Record>) -> Bool {
  let owner = ScriptExecutionContext.GetOwner(context);
  if IsDefined(record.AttachmentSlot()) && CMCEquipGuard.Guards(owner, record.AttachmentSlot().GetID()) {
    CMCEquipGuard.Note(owner, "force unequip");
    return true;
  }
  return wrappedMethod(context, record);
}
