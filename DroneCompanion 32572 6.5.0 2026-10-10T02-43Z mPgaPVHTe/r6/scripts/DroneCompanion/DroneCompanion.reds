module DroneCompanion
import Codeware.Localization.*

private static func DC_IsCompanionDrone(obj: wref<GameObject>) -> Bool {
  let sp: wref<ScriptedPuppet> = obj as ScriptedPuppet;
  if !IsDefined(sp) {
    return false;
  };
  let ses = GameInstance.GetStatusEffectSystem(sp.GetGame());
  return IsDefined(ses) && ses.HasStatusEffect(sp.GetEntityID(), t"DroneCompanion.CompanionSE");
}

private static func DC_IsPassive(obj: wref<GameObject>) -> Bool {
  let sp: wref<ScriptedPuppet> = obj as ScriptedPuppet;
  if !IsDefined(sp) {
    return false;
  };
  let ses = GameInstance.GetStatusEffectSystem(sp.GetGame());
  return IsDefined(ses) && ses.HasStatusEffect(sp.GetEntityID(), t"DroneCompanion.PassiveSE");
}

private static func DC_IsRetreating(obj: wref<GameObject>) -> Bool {
  let sp: wref<ScriptedPuppet> = obj as ScriptedPuppet;
  if !IsDefined(sp) {
    return false;
  };
  let ses = GameInstance.GetStatusEffectSystem(sp.GetGame());
  return IsDefined(ses) && ses.HasStatusEffect(sp.GetEntityID(), t"DroneCompanion.RetreatSE");
}

private static func DC_IsArena(obj: wref<GameObject>) -> Bool {
  let sp: wref<ScriptedPuppet> = obj as ScriptedPuppet;
  if !IsDefined(sp) {
    return false;
  };
  let ses = GameInstance.GetStatusEffectSystem(sp.GetGame());
  return IsDefined(ses) && ses.HasStatusEffect(sp.GetEntityID(), t"DroneCompanion.ArenaSE");
}

private static func DC_IsFighter(obj: wref<GameObject>) -> Bool {
  return DC_IsArena(obj) && !DC_IsCompanionDrone(obj);
}

@wrapMethod(ScriptedPuppet)
public final func IsQuickHackAble() -> Bool {
  if DC_IsCompanionDrone(this) {
    return true;
  };
  return wrappedMethod();
}

@wrapMethod(ScriptedPuppetPS)
public final const func IsQuickHacksExposed() -> Bool {
  if DC_IsCompanionDrone(this.GetOwnerEntity() as ScriptedPuppet) {
    return true;
  };
  return wrappedMethod();
}

private static func DC_HackIDs() -> array<TweakDBID> {
  return [
    t"DroneCompanion.HackRepair",
    t"DroneCompanion.HackHold",
    t"DroneCompanion.HackDismiss",
    t"DroneCompanion.HackDetonate",
    t"DroneCompanion.HackOverclock",
    t"DroneCompanion.HackFortify",
    t"DroneCompanion.HackOctant",
    t"DroneCompanion.HackWyvern",
    t"DroneCompanion.HackGriffin",
    t"DroneCompanion.HackBombus",
    t"DroneCompanion.HackMinotaur"
  ];
}

private static func DC_CooldownIDs() -> array<TweakDBID> {
  return [
    t"DroneCompanion.HackRepairCd",
    t"DroneCompanion.HackHoldCd",
    t"DroneCompanion.HackDismissCd",
    t"DroneCompanion.HackDetonateCd",
    t"DroneCompanion.HackOverclockCd",
    t"DroneCompanion.HackFortifyCd",
    t"DroneCompanion.HackOctantCd",
    t"DroneCompanion.HackWyvernCd",
    t"DroneCompanion.HackGriffinCd",
    t"DroneCompanion.HackBombusCd",
    t"DroneCompanion.HackMinotaurCd"
  ];
}

private static func DC_CooldownFor(id: TweakDBID) -> TweakDBID {
  let ids: array<TweakDBID> = DC_HackIDs();
  let cds: array<TweakDBID> = DC_CooldownIDs();
  let i: Int32 = 0;
  while i < ArraySize(ids) {
    if ids[i] == id {
      return cds[i];
    };
    i += 1;
  };
  return TDBID.None();
}

@wrapMethod(ScriptedPuppet)
private final func TranslateChoicesIntoQuickSlotCommands(const choices: script_ref<array<ref<PuppetAction>>>, commands: script_ref<array<ref<QuickhackData>>>) -> Void {
  wrappedMethod(choices, commands);
  if !DC_IsCompanionDrone(this) {
    return;
  };
  let ses = GameInstance.GetStatusEffectSystem(this.GetGame());
  if !IsDefined(ses) {
    return;
  };
  let i: Int32 = 0;
  while i < ArraySize(Deref(commands)) {
    let cmd: ref<QuickhackData> = Deref(commands)[i];
    let action: ref<PuppetAction> = cmd.m_action as PuppetAction;
    if IsDefined(action) {
      let cooldown: TweakDBID = DC_CooldownFor(action.GetObjectActionID());
      if TDBID.IsValid(cooldown) && ses.HasStatusEffect(this.GetEntityID(), cooldown) {
        cmd.m_isLocked = true;
        cmd.m_inactiveReason = "Mod-DroneCompanion-Hack-Cooling";
        cmd.m_actionState = EActionInactivityReson.Locked;
      };
    };
    i += 1;
  };
}

private static func DC_ListHasAction(list: script_ref<array<PlayerQuickhackData>>, id: TweakDBID) -> Bool {
  let i: Int32 = 0;
  while i < ArraySize(Deref(list)) {
    if IsDefined(Deref(list)[i].actionRecord) && Deref(list)[i].actionRecord.GetID() == id {
      return true;
    };
    i += 1;
  };
  return false;
}

@wrapMethod(RPGManager)
public final static func GetPlayerQuickHackListWithQuality(player: wref<PlayerPuppet>) -> array<PlayerQuickhackData> {
  let list: array<PlayerQuickhackData> = wrappedMethod(player);
  if !IsDefined(player) {
    return list;
  };
  let ids: array<TweakDBID> = DC_HackIDs();
  let added: Int32 = 0;
  let data: PlayerQuickhackData;
  let record: wref<ObjectAction_Record>;
  let i: Int32 = 0;
  while i < ArraySize(ids) {
    record = TweakDBInterface.GetObjectActionRecord(ids[i]);
    if IsDefined(record) && !DC_ListHasAction(list, ids[i]) {
      data.actionRecord = record;
      data.quality = 4;
      ArrayPush(list, data);
      added += 1;
    };
    i += 1;
  };
  if added > 0 {
    PlayerPuppet.ChacheQuickHackList(player, list);
  };
  return list;
}

private static func DC_PreventionWatches(victim: ref<GameObject>) -> Bool {
  let sp: ref<ScriptedPuppet> = victim as ScriptedPuppet;
  if !IsDefined(sp) || sp.IsHostile() {
    return false;
  };
  return sp.IsCrowd() || sp.IsVendor() || sp.IsCharacterCivilian() || sp.IsPrevention()
    || NPCManager.HasTag(sp.GetRecordID(), n"TriggerPrevention");
}

@wrapMethod(GameObject)
public final func FindAndRewardKiller(killType: gameKillType, opt instigator: wref<GameObject>) -> Void {
  let watched: Bool = DC_PreventionWatches(this);
  if DC_IsCompanionDrone(instigator) {
    let player = GetPlayer(this.GetGame());
    if IsDefined(player) {
      player.DCKill(instigator);
      if !watched {
        instigator = player;
      };
    };
  };
  if !watched {
    let i: Int32 = 0;
    while i < ArraySize(this.m_receivedDamageHistory) {
      if DC_IsCompanionDrone(this.m_receivedDamageHistory[i].source) {
        this.m_receivedDamageHistory[i].source = GetPlayer(this.GetGame());
      };
      i += 1;
    };
  };
  wrappedMethod(killType, instigator);
}

@wrapMethod(DamageSystem)
private final func Process(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
  let instigator: wref<ScriptedPuppet> = hitEvent.attackData.GetInstigator() as ScriptedPuppet;
  let target: wref<ScriptedPuppet> = hitEvent.target as ScriptedPuppet;
  if IsDefined(instigator) && IsDefined(target) {
    let instFighter: Bool = DC_IsFighter(instigator);
    let targFighter: Bool = DC_IsFighter(target);
    if instFighter || targFighter {
      if instFighter && targFighter {
        wrappedMethod(hitEvent, cache);
      };
      return;
    };
    let instOurs: Bool = DC_IsCompanionDrone(instigator);
    let targOurs: Bool = DC_IsCompanionDrone(target);
    let ignored: Bool = hitEvent.attackData.HasFlag(hitFlag.DealNoDamage) || hitEvent.attackData.HasFlag(hitFlag.FriendlyFireIgnored);
    if instOurs && !targOurs && !target.IsPlayer() && !ignored {
      target.m_dcLastAggressor = instigator;
    };
    if target.IsPlayer() && !instOurs && !instigator.IsPlayer() && !ignored && instigator.IsHostile() {
      let pp: ref<PlayerPuppet> = target as PlayerPuppet;
      if IsDefined(pp) {
        pp.m_dcAttacker = instigator;
        pp.m_dcAttackerAt = EngineTime.ToFloat(GameInstance.GetSimTime(pp.GetGame()));
      };
    };
    if (instOurs && targOurs) || (instigator.IsPlayer() && targOurs) || (instOurs && target.IsPlayer()) {
      return;
    };
  };
  wrappedMethod(hitEvent, cache);
}

private static func DC_HostileToSquad(owner: ref<GameObject>, drone: ref<GameObject>) -> Bool {
  return IsDefined(owner) && (owner.IsHostile() || Equals(owner.GetAttitudeTowards(drone), EAIAttitude.AIA_Hostile));
}

private static func DC_EngagedWithSquad(owner: ref<GameObject>, drone: ref<GameObject>) -> Bool {
  if !DC_HostileToSquad(owner, drone) {
    return false;
  };
  let sp: ref<ScriptedPuppet> = owner as ScriptedPuppet;
  if IsDefined(sp) {
    let hls: gamedataNPCHighLevelState = sp.GetHighLevelStateFromBlackboard();
    if Equals(hls, gamedataNPCHighLevelState.Combat) || Equals(hls, gamedataNPCHighLevelState.Alerted) {
      return true;
    };
  };
  let player: ref<PlayerPuppet> = GetPlayer(owner.GetGame());
  return IsDefined(player) && player.IsInCombat();
}

@wrapMethod(ReactionManagerComponent)
protected cb func OnDetectedEvent(evt: ref<OnDetectedEvent>) -> Bool {
  if IsDefined(evt) && IsDefined(evt.target) && evt.isVisible && DC_IsCompanionDrone(evt.target) && !DC_IsPassive(evt.target) {
    let owner: wref<ScriptedPuppet> = this.GetOwnerPuppet();
    if IsDefined(owner) && !DC_IsCompanionDrone(owner) && !DC_IsFighter(owner) && DC_EngagedWithSquad(owner, evt.target) {
      TargetTrackingExtension.InjectThreat(owner, evt.target);
    };
  };
  return wrappedMethod(evt);
}

@wrapMethod(SenseComponent)
public final static func ShouldIgnoreIfPlayerCompanion(owner: wref<Entity>, target: wref<Entity>) -> Bool {
  if DC_IsCompanionDrone(target as GameObject) && !DC_IsPassive(target as GameObject)
    && DC_EngagedWithSquad(owner as GameObject, target as GameObject) {
    return false;
  };
  return wrappedMethod(owner, target);
}

@wrapMethod(PlayerPuppet)
private final func UpdateLookAtObject(target: ref<GameObject>) -> Void {
  wrappedMethod(target);
  if IsDefined(target) && DC_IsCompanionDrone(target) {
    this.m_isAimingAtFriendly = false;
  };
}

@wrapMethod(NpcNameplateGameController)
private final func HelperCheckDistance(entity: ref<Entity>) -> Bool {
  if IsDefined(entity) && DC_IsCompanionDrone(entity as GameObject) {
    return true;
  };
  return wrappedMethod(entity);
}

@wrapMethod(NpcNameplateGameController)
protected cb func OnNameplateDataChanged(value: Variant) -> Bool {
  wrappedMethod(value);
  let data: NPCNextToTheCrosshair = FromVariant<NPCNextToTheCrosshair>(value);
  if IsDefined(data.npc) && DC_IsCompanionDrone(data.npc) {
    this.m_visualController.UpdateNPCNamesEnabled(true);
  };
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  wrappedMethod(puppet, incomingData, isNewNpc);
  if IsDefined(puppet) && DC_IsCompanionDrone(puppet) {
    this.UpdateHealthbarColor(false);
    inkWidgetRef.SetVisible(this.m_healthbarWidget, true);
  };
}

@wrapMethod(NameplateVisualsLogicController)
public final func UpdateHealthbarColor(isHostile: Bool) -> Void {
  if IsDefined(this.m_cachedPuppet) && DC_IsCompanionDrone(this.m_cachedPuppet) {
    inkWidgetRef.SetState(this.m_healthbarWidget, n"Friendly");
    inkWidgetRef.SetState(this.m_healthBarFull, n"Friendly");
    inkWidgetRef.SetState(this.m_healthBarFrame, n"Friendly");
    return;
  };
  wrappedMethod(isHostile);
}

@wrapMethod(DamageDigitsGameController)
protected cb func OnDamageAdded(value: Variant) -> Bool {
  if !IsDefined(this.m_realOwner) {
    return wrappedMethod(value);
  };
  let list: array<DamageInfo> = FromVariant<array<DamageInfo>>(value);
  let changed: Bool = false;
  let i: Int32 = 0;
  while i < ArraySize(list) {
    if DC_IsCompanionDrone(list[i].instigator) {
      let info: DamageInfo = list[i];
      info.instigator = this.m_realOwner;
      list[i] = info;
      changed = true;
    };
    i += 1;
  };
  if changed {
    return wrappedMethod(ToVariant(list));
  };
  return wrappedMethod(value);
}


@addField(PlayerPuppet)
let m_dcMechArmor: Bool;

@addMethod(PlayerPuppet)
public func DCSetMechArmor(on: Bool) -> Void {
  this.m_dcMechArmor = on;
}

@addField(PlayerPuppet)
let m_dcAndroidHeads: Bool;

@addMethod(PlayerPuppet)
public func DCSetAndroidHeads(on: Bool) -> Void {
  this.m_dcAndroidHeads = on;
}

@wrapMethod(DismembermentComponent)
public final static func RequestDismemberment(obj: ref<GameObject>, bodyPart: gameDismBodyPart, woundType: gameDismWoundType, opt hitPosition: Vector4, opt isCritical: Bool, opt debrisPath: String, opt debrisStrength: Float) -> Void {
  if DC_IsCompanionDrone(obj) {
    let player = GameInstance.GetPlayerSystem(obj.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if IsDefined(player) && player.m_dcAndroidHeads {
      return;
    };
  };
  wrappedMethod(obj, bodyPart, woundType, hitPosition, isCritical, debrisPath, debrisStrength);
}

@wrapMethod(ScriptedWeakspotObject)
protected func ReadTweakData() -> Void {
  wrappedMethod();
  if !this.m_weakspotRecordData.m_isInvulnerable && DC_IsCompanionDrone(this.GetOwner()) {
    let player = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if IsDefined(player) && player.m_dcMechArmor {
      this.m_weakspotRecordData.m_isInvulnerable = true;
    };
  };
}

private static func DC_CraftItemIds() -> array<TweakDBID> {
  return [
    t"DroneCompanion.CraftBombus",
    t"DroneCompanion.CraftFlathead",
    t"DroneCompanion.CraftOctant",
    t"DroneCompanion.CraftAndroid",
    t"DroneCompanion.CraftGriffin",
    t"DroneCompanion.CraftWyvern",
    t"DroneCompanion.CraftMinotaur",
    t"DroneCompanion.CraftCerberus",
    t"DroneCompanion.CraftChimera"
  ];
}

@addMethod(PlayerPuppet)
public func DCLearnRecipes() -> Void {
  let ids: array<TweakDBID> = DC_CraftItemIds();
  let i: Int32 = 0;
  while i < ArraySize(ids) {
    let req: ref<AddRecipeRequest> = new AddRecipeRequest();
    req.owner = this;
    req.recipe = ids[i];
    req.amount = 1;
    GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"CraftingSystem").QueueRequest(req);
    i += 1;
  };
}

@wrapMethod(CraftingMainLogicController)
protected func SetupFilters() -> Void {
  if IsDefined(this as CraftingLogicController) {
    ArrayPush(this.m_filters, EnumInt(DroneGearFilter.Category()));
  };
  wrappedMethod();
}

@wrapMethod(CraftingDataView)
public func FilterItem(item: ref<IScriptable>) -> Bool {
  if !Equals(this.m_itemFilterType, DroneGearFilter.Category()) {
    return wrappedMethod(item);
  };
  let recipeData: ref<RecipeData> = item as RecipeData;
  if IsDefined(recipeData) && IsDefined(recipeData.id) && recipeData.id.TagsContains(n"DroneCompanionCraft") {
    return true;
  };
  let craftData: ref<ItemCraftingData> = item as ItemCraftingData;
  if IsDefined(craftData) {
    let rec: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(InventoryItemData.GetID(craftData.inventoryItem)));
    if IsDefined(rec) && rec.TagsContains(n"DroneCompanionCraft") {
      return true;
    };
  };
  return false;
}


@addField(ScriptedPuppet)
let m_dcLastAggressor: wref<ScriptedPuppet>;

private static func DC_ArchetypeThreatScale(owner: wref<ScriptedPuppet>, drone: wref<ScriptedPuppet>) -> Float {
  if !IsDefined(owner) {
    return 1.0;
  };
  let record: ref<Character_Record> = TweakDBInterface.GetCharacterRecord(owner.GetRecordID());
  if !IsDefined(record) || !IsDefined(record.ArchetypeData()) || !IsDefined(record.ArchetypeData().Type()) {
    return 1.0;
  };
  let npc: wref<NPCPuppet> = drone as NPCPuppet;
  let flying: Bool = IsDefined(npc) && Equals(npc.GetNPCType(), gamedataNPCType.Drone);
  let mech: Bool = IsDefined(npc) && Equals(npc.GetNPCType(), gamedataNPCType.Mech);
  switch record.ArchetypeData().Type().Type() {
    case gamedataArchetypeType.SniperT2:
    case gamedataArchetypeType.FastSniperT3:
    case gamedataArchetypeType.NetrunnerT1:
    case gamedataArchetypeType.NetrunnerT2:
    case gamedataArchetypeType.NetrunnerT3:
      return 0.6;
    case gamedataArchetypeType.GenericMeleeT1:
    case gamedataArchetypeType.GenericMeleeT2:
    case gamedataArchetypeType.FastMeleeT2:
    case gamedataArchetypeType.FastMeleeT3:
    case gamedataArchetypeType.HeavyMeleeT2:
    case gamedataArchetypeType.HeavyMeleeT3:
      return flying ? 0.3 : (mech ? 0.6 : 1.0);
    case gamedataArchetypeType.ShotgunnerT2:
    case gamedataArchetypeType.ShotgunnerT3:
    case gamedataArchetypeType.FastShotgunnerT2:
    case gamedataArchetypeType.FastShotgunnerT3:
      return mech ? 0.7 : 1.0;
    case gamedataArchetypeType.HeavyRangedT2:
    case gamedataArchetypeType.HeavyRangedT3:
    case gamedataArchetypeType.TechieT2:
    case gamedataArchetypeType.TechieT3:
      return mech ? 1.5 : 1.0;
  };
  return 1.0;
}

private static func DC_ModulateThreat(owner: wref<ScriptedPuppet>, threat: wref<GameObject>, out threatValue: Float) -> Void {
  if !DC_IsCompanionDrone(threat) {
    return;
  };
  if DC_IsRetreating(threat) {
    threatValue = threatValue * 0.05;
    return;
  };
  if DC_IsPassive(threat) {
    return;
  };
  let sp: wref<ScriptedPuppet> = threat as ScriptedPuppet;
  if !IsDefined(sp) {
    return;
  };
  if GameInstance.GetStatusEffectSystem(sp.GetGame()).HasStatusEffect(sp.GetEntityID(), t"DroneCompanion.HackCloakSE") {
    threatValue = threatValue * 0.1;
    return;
  };
  let hpPct: Float = GameInstance.GetStatPoolsSystem(sp.GetGame())
    .GetStatPoolValue(Cast<StatsObjectID>(sp.GetEntityID()), gamedataStatPoolType.Health, true);
  threatValue = threatValue * (0.5 + hpPct / 100.0) * DC_ArchetypeThreatScale(owner, sp);
}

private static func DC_IsHmgBurst(id: TweakDBID) -> Bool {
  return id == t"MinotaurMech.AimAttackHMG" || id == t"MinotaurMech.AimAttackHMGLeft"
    || id == t"MinotaurMech.AimAttackHMGRight" || id == t"MinotaurMech.AimAttackHMGOnPlace"
    || id == t"MinotaurMech.AimAttackHMGOnPlaceLeft" || id == t"MinotaurMech.AimAttackHMGOnPlaceRight";
}

private static func DC_BurstTargetGone(context: ScriptExecutionContext) -> Bool {
  let target: ref<GameObject> = AIBehaviorScriptBase.GetCombatTarget(context);
  if !IsDefined(target) {
    return true;
  };
  let puppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
  return IsDefined(puppet) && (puppet.IsDead() || ScriptedPuppet.IsDefeated(puppet));
}

private static func DC_StallLabel(id: TweakDBID) -> String {
  if DC_IsHmgBurst(id) {
    return "hmg";
  };
  if id == t"MinotaurMech.RotateToTargetNoLimit" {
    return "rotate";
  };
  if id == t"DroneOctantActions.ShootDefault" {
    return "octant";
  };
  if id == t"DroneBombusActions.FollowTargetFast" {
    return "bombus";
  };
  return "";
}

private static func DC_StallLimit(label: String) -> Float {
  if Equals(label, "hmg") {
    return 12.0;
  };
  if Equals(label, "octant") {
    return 10.0;
  };
  if Equals(label, "bombus") {
    return 8.0;
  };
  return 6.0;
}

@addField(TweakAIActionAbstract)
let m_dcStart: Float;

@wrapMethod(TweakAIActionAbstract)
protected func Activate(context: ScriptExecutionContext) -> Void {
  wrappedMethod(context);
  this.m_dcStart = EngineTime.ToFloat(ScriptExecutionContext.GetAITime(context));
}

@wrapMethod(TweakAIActionAbstract)
protected func Update(context: ScriptExecutionContext) -> AIbehaviorUpdateOutcome {
  if IsDefined(this.m_actionRecord) {
    let label: String = DC_StallLabel(this.m_actionRecord.GetID());
    if StrLen(label) > 0 {
      let owner: ref<GameObject> = ScriptExecutionContext.GetOwner(context);
      if DC_IsCompanionDrone(owner) {
        if Equals(label, "hmg") && DC_BurstTargetGone(context) {
          return AIbehaviorUpdateOutcome.SUCCESS;
        };
        let elapsed: Float = EngineTime.ToFloat(ScriptExecutionContext.GetAITime(context)) - this.m_dcStart;
        if this.m_dcStart > 0.0 && elapsed > DC_StallLimit(label) {
          this.m_dcStart = 0.0;
          return AIbehaviorUpdateOutcome.SUCCESS;
        };
      };
    };
  };
  return wrappedMethod(context);
}

@wrapMethod(AIActionTarget)
private final static func RegularThreatCalculation(owner: wref<ScriptedPuppet>, ownerPos: Vector4, targetTrackerComponent: ref<TargetTrackerComponent>, newTargetObject: wref<GameObject>, threat: wref<GameObject>, timeSinceTargetChange: Float, currentTime: Float, out threatValue: Float) -> Void {
  wrappedMethod(owner, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatValue);
  DC_ModulateThreat(owner, threat, threatValue);
}

@wrapMethod(AIActionTarget)
private final static func BossThreatCalculation(owner: wref<ScriptedPuppet>, ownerPos: Vector4, targetTrackerComponent: ref<TargetTrackerComponent>, newTargetObject: wref<GameObject>, threat: wref<GameObject>, timeSinceTargetChange: Float, currentTime: Float, out threatValue: Float) -> Void {
  wrappedMethod(owner, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatValue);
  DC_ModulateThreat(owner, threat, threatValue);
}

@wrapMethod(AIActionHelper)
public final static func TryChangingAttitudeToHostile(owner: ref<ScriptedPuppet>, target: ref<GameObject>) -> Bool {
  if DC_IsFighter(owner) && IsDefined(target) && (target.IsPlayer() || DC_IsCompanionDrone(target)) {
    return false;
  };
  if DC_IsCompanionDrone(owner) && IsDefined(target) && !target.IsPlayer() && !DC_IsCompanionDrone(target)
    && !DC_HostileToSquad(target, owner) {
    return false;
  };
  if IsDefined(owner) && IsDefined(target) && target.IsPlayer() && !DC_IsCompanionDrone(owner) {
    let playerDist: Float = Vector4.Distance(target.GetWorldPosition(), owner.GetWorldPosition());
    if playerDist > 20.0 {
      let bot: wref<ScriptedPuppet> = owner.m_dcLastAggressor;
      if IsDefined(bot) && DC_IsCompanionDrone(bot) && ScriptedPuppet.IsActive(bot)
        && Vector4.Distance(bot.GetWorldPosition(), owner.GetWorldPosition()) <= 30.0 {
        if wrappedMethod(owner, bot) {
          TargetTrackingExtension.InjectThreat(owner, bot, 4.0);
          return true;
        };
      };
    };
  };
  return wrappedMethod(owner, target);
}

private static func DC_IsFlinchReaction(reactionPlayed: animHitReactionType) -> Bool {
  return Equals(reactionPlayed, animHitReactionType.Stagger)
    || Equals(reactionPlayed, animHitReactionType.Impact)
    || Equals(reactionPlayed, animHitReactionType.Pain);
}

private static func DC_IsMechPuppet(obj: wref<GameObject>) -> Bool {
  let np: wref<NPCPuppet> = obj as NPCPuppet;
  return IsDefined(np) && Equals(np.GetNPCType(), gamedataNPCType.Mech);
}

@wrapMethod(HitReactionComponent)
private final func SendDataToAIBehavior(reactionPlayed: animHitReactionType) -> Void {
  if DC_IsFlinchReaction(reactionPlayed) && IsDefined(this.m_attackData) {
    let instigator: wref<GameObject> = this.m_attackData.GetInstigator();
    if DC_IsCompanionDrone(this.m_ownerNPC) && !DC_IsMechPuppet(instigator) {
      return;
    };
    if IsDefined(this.m_ownerNPC) && this.m_ownerNPC.IsBoss() && DC_IsCompanionDrone(instigator) {
      return;
    };
  };
  wrappedMethod(reactionPlayed);
}

@wrapMethod(HitReactionComponent)
protected final func SendMechDataToAIBehavior(reactionPlayed: animHitReactionType) -> Void {
  if DC_IsFlinchReaction(reactionPlayed) && IsDefined(this.m_attackData) {
    let instigator: wref<GameObject> = this.m_attackData.GetInstigator();
    if DC_IsCompanionDrone(this.m_ownerNPC) && !DC_IsMechPuppet(instigator) {
      return;
    };
    if DC_IsMechPuppet(this.m_ownerNPC) && !DC_IsMechPuppet(instigator) && DC_IsCompanionDrone(instigator) {
      return;
    };
  };
  wrappedMethod(reactionPlayed);
}


@wrapMethod(InventoryItemDisplayController)
protected func UpdateBlueprint() -> Void {
  wrappedMethod();
  if IsDefined(this.m_recipeData) && IsDefined(this.m_recipeData.id)
    && this.m_recipeData.id.TagsContains(n"DroneCompanionCraft") {
    inkWidgetRef.SetVisible(this.m_backgroundBlueprint, false);
    inkWidgetRef.SetVisible(this.m_iconBlueprint, false);
    inkImageRef.SetState(this.m_itemImage, n"Default");
    inkImageRef.Get(this.m_itemImage).DisableAllEffectsByType(inkEffectType.ColorFill);
  };
}


@addMethod(PlayerPuppet)
public func DCCraftItem(itemId: TweakDBID) -> Bool {
  let cs: ref<CraftingSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"CraftingSystem") as CraftingSystem;
  let rec: ref<Item_Record> = TweakDBInterface.GetItemRecord(itemId);
  if !IsDefined(cs) || !IsDefined(rec) || !cs.CanItemBeCrafted(rec) {
    return false;
  };
  let req: ref<CraftItemRequest> = new CraftItemRequest();
  req.target = this;
  req.itemRecord = rec;
  req.amount = 1;
  cs.QueueRequest(req);
  return true;
}

@addField(PlayerPuppet)
let m_dcAttacker: wref<ScriptedPuppet>;

@addField(PlayerPuppet)
let m_dcAttackerAt: Float;

@addMethod(PlayerPuppet)
public func DCLastAttacker() -> wref<ScriptedPuppet> {
  let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame()));
  if IsDefined(this.m_dcAttacker) && now - this.m_dcAttackerAt < 3.0 {
    return this.m_dcAttacker;
  };
  return null;
}

@addMethod(PlayerPuppet)
public func DCGetWaypoint() -> Vector4 {
  let system: ref<MappinSystem> = GameInstance.GetMappinSystem(this.GetGame());
  let mappin: ref<IMappin> = system.GetMappin(system.GetManuallyTrackedMappinID());
  if IsDefined(mappin) && Equals(mappin.GetVariant(), gamedataMappinVariant.CustomPositionVariant) {
    let pos: Vector4 = mappin.GetWorldPosition();
    pos.W = 1.0;
    return pos;
  };
  return new Vector4(0.0, 0.0, 0.0, -1.0);
}

@addMethod(PlayerPuppet)
public func DCGetSeat() -> String {
  let info: MountingInfo = GameInstance.GetMountingFacility(this.GetGame()).GetMountingInfoSingleWithIds(this.GetEntityID());
  if !EntityID.IsDefined(info.parentId) {
    return "";
  };
  return NameToString(info.slotId.id);
}

@addMethod(PlayerPuppet)
public func DCGetRestrictions() -> String {
  let out: String = "";
  let effects: array<ref<StatusEffect>>;
  GameInstance.GetStatusEffectSystem(this.GetGame()).GetAppliedEffects(this.GetEntityID(), effects);
  let i: Int32 = 0;
  while i < ArraySize(effects) {
    let rec = effects[i].GetRecord();
    if IsDefined(rec) {
      out += TDBID.ToStringDEBUG(rec.GetID()) + ";";
    };
    i += 1;
  };
  return out;
}

@addMethod(PlayerPuppet)
public func DCForceVehCombat(on: Bool) -> Void {
  let evt: ref<PSMPostponedParameterBool> = new PSMPostponedParameterBool();
  if on {
    evt.id = n"startVehicleCombat";
  } else {
    evt.id = n"stopVehicleCombat";
  };
  evt.value = true;
  this.QueueEvent(evt);
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnDCKeyInput")
    .SetLifetime(CallbackLifetime.Session);
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  GameInstance.GetCallbackSystem().UnregisterCallback(n"Input/Key", this, n"OnDCKeyInput");
  return wrappedMethod();
}

@addMethod(PlayerPuppet)
protected cb func OnDCKeyInput(event: ref<KeyInputEvent>) {
  if !Equals(event.GetAction(), EInputAction.IACT_Press) || this.m_dcmMenuBlocked {
    return;
  };
  let key: EInputKey = event.GetKey();
  if VehicleComponent.IsMountedToVehicle(this.GetGame(), this) {
    if Equals(key, EInputKey.IK_G) {
      this.DCKeyCombo("chdrive");
      return;
    };
    if Equals(key, EInputKey.IK_Q) {
      this.DCKeyCombo("chcam");
    };
  };
}

@addMethod(PlayerPuppet)
public func DCKeyCombo(id: String) -> Void {}

@addMethod(PlayerPuppet)
public func DCUiLanguage() -> String {
  let loc: ref<LocalizationSystem> = LocalizationSystem.GetInstance(this.GetGame());
  return IsDefined(loc) ? NameToString(loc.GetInterfaceLanguage()) : "";
}
