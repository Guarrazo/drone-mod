module DroneCompanion

public final abstract class DroneShardAction {
  public static func ChassisOf(id: TweakDBID) -> String {
    if id == t"DroneCompanion.ShardOctant" { return "Octant"; }
    if id == t"DroneCompanion.ShardWyvern" { return "Wyvern"; }
    if id == t"DroneCompanion.ShardGriffin" { return "Griffin"; }
    if id == t"DroneCompanion.ShardBombus" { return "Bombus"; }
    if id == t"DroneCompanion.ShardMinotaur" { return "Minotaur"; }
    if id == t"DroneCompanion.ShardAndroid" { return "Android"; }
    if id == t"DroneCompanion.ShardFlathead" { return "Flathead"; }
    if id == t"DroneCompanion.ShardChimera" { return "Chimera"; }
    if id == t"DroneCompanion.ShardCerberus" { return "Cerberus"; }
    return "";
  }
}

@wrapMethod(ItemActionsHelper)
public final static func ProcessItemAction(gi: GameInstance, executor: wref<GameObject>,
    itemData: wref<gameItemData>, actionID: TweakDBID, fromInventory: Bool) -> Bool {
  if actionID == t"DroneCompanion.SummonAction" && IsDefined(itemData) {
    let chassis: String = DroneShardAction.ChassisOf(ItemID.GetTDBID(itemData.GetID()));
    if StrLen(chassis) > 0 {
      let player: ref<PlayerPuppet> = executor as PlayerPuppet;
      if IsDefined(player) {
        player.DCEmit("shard:" + chassis);
        return true;
      };
    };
  };
  return wrappedMethod(gi, executor, itemData, actionID, fromInventory);
}
