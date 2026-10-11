module ControllableMechs

import ControllableMechs.Control.*

public class CMFleetTick extends DelayCallback {
  public let fleet: wref<CMFleet>;
  public let generation: Int32;

  public func Call() -> Void {
    if IsDefined(this.fleet) {
      this.fleet.OnTick(this.generation);
    }
  }
}

public class CMFleet extends ScriptableSystem {

  private persistent let m_fleetHp: array<Float>;
  private persistent let m_fleetHull: array<Float>;
  private persistent let m_fleetDead: array<Bool>;
  private persistent let m_fleetRepairEnd: array<Float>;
  private persistent let m_fleetRepairTotal: array<Float>;
  private persistent let m_fleetLayout: Int32;

  private persistent let m_shopItems: array<CName>;
  private persistent let m_shopFits: array<CName>;
  private persistent let m_shopReady: Bool;
  private persistent let m_bombusBuilt: Bool;

  private let m_outBay: Int32;
  private let m_outID: EntityID;
  private let m_applied: Bool;
  private let m_generation: Int32;
  private let m_ticking: Bool;
  private let m_fabLearned: Bool;

  private let m_escort: Bool;
  private let m_escortStep: Int32;
  private let m_escortIn: Bool;

  public static func Get(game: GameInstance) -> ref<CMFleet> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"ControllableMechs.CMFleet") as CMFleet;
  }

  public static func Count() -> Int32 = 5
  public static func Kind(bay: Int32) -> String {
    switch bay {
      case 1: return "octant";
      case 2: return "wyvern";
      case 3: return "griffin";
      case 4: return "bombus";
    }
    return "minotaur";
  }

  public static func Parts(bay: Int32) -> Int32 {
    if bay == 0 {
      return CMPart.Count();
    }
    return CMUDrone.PartsOf(CMFleet.Kind(bay));
  }

  private static func BayAt(bay: Int32) -> Int32 {
    let at = 0;
    let i = 0;
    while i < bay {
      at += CMFleet.Parts(i);
      i += 1;
    }
    return at;
  }

  private static func LayoutCode() -> Int32 {
    let n = 0;
    let i = 0;
    while i < CMFleet.Count() {
      n = n * 16 + CMFleet.Parts(i);
      i += 1;
    }
    return n;
  }

  private func OnAttach() -> Void {
    this.m_outBay = -1;
    this.Fit();
  }

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {

    this.m_generation += 1;
    this.m_outBay = -1;
    this.m_ticking = false;
    this.Fit();
    this.ShopInit();
    this.SyncCfg();

    let lb = 2;
    while lb <= 4 {
      let un = StringToName("unit_" + IntToString(lb));
      if this.Dead(lb) && ArrayContains(this.m_shopItems, un) {
        this.MarkBought(NameToString(un));
        while ArrayContains(this.m_shopItems, un) {
          ArrayRemove(this.m_shopItems, un);
        }
        this.FinishRepair(lb);
      }
      lb += 1;
    }

    this.m_fabLearned = false;
    let learn = new CMFabLearnCb();
    learn.fleet = this;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(learn, 3.0, false);
  }

  private func ShopInit() -> Void {
    if this.m_shopReady {

      if !ArrayContains(this.m_shopItems, n"livery_mnc_default") {
        ArrayPush(this.m_shopItems, n"livery_mnc_default");
      }
      return;
    }
    this.m_shopReady = true;
    ArrayClear(this.m_shopItems);
    ArrayClear(this.m_shopFits);

    ArrayPush(this.m_shopItems, n"gun_mk31");
    ArrayPush(this.m_shopItems, n"livery_mnc_default");
    ArrayPush(this.m_shopItems, n"payload_1");
    ArrayPush(this.m_shopFits, n"arm_l=mk31");
    ArrayPush(this.m_shopFits, n"arm_r=mk31");
    ArrayPush(this.m_shopFits, n"livery=mnc_default");
    ArrayPush(this.m_shopFits, n"payload=1");
  }

  public func Has(item: String) -> Bool {
    this.ShopInit();

    if StrBeginsWith(item, "payload_") {
      return true;
    }
    return ArrayContains(this.m_shopItems, StringToName(item));
  }

  public func Owned(bay: Int32) -> Bool = this.Has("unit_" + IntToString(bay))

  public func Fitted(fit: String) -> Bool {
    this.ShopInit();
    return ArrayContains(this.m_shopFits, StringToName(fit));
  }

  public func FitOf(slot: String) -> String {
    this.ShopInit();
    for f in this.m_shopFits {
      let s = NameToString(f);
      if StrBeginsWith(s, slot + "=") {
        return StrAfterFirst(s, "=");
      }
    }
    return "";
  }

  public static func Price(item: String) -> Int32 {
    let base = CMFleet.BasePrice(item);
    if Equals(item, "unit_0") || Equals(item, "unit_1") {
      let fleet = CMFleet.Get(GetGameInstance());
      if IsDefined(fleet) && fleet.BoughtBefore(item) {
        return base / 4;
      }
    }
    return base;
  }

  public func BoughtBefore(item: String) -> Bool {
    this.ShopInit();
    return ArrayContains(this.m_shopItems, StringToName("had_" + item));
  }

  private func MarkBought(item: String) -> Void {
    let had = StringToName("had_" + item);
    if StrBeginsWith(item, "unit_") && !ArrayContains(this.m_shopItems, had) {
      ArrayPush(this.m_shopItems, had);
    }
  }

  public static func BasePrice(item: String) -> Int32 {
    switch item {
      case "unit_0": return 250000;
      case "unit_1": return 60000;
      case "unit_2": return 45000;
      case "unit_3": return 80000;
      case "unit_4": return 12000;
      case "gun_plasma": return 38000;
      case "gun_fieldhmg": return 26000;
      case "bags": return 6000;
      case "hullpod": return 32000;
      case "counter": return 18000;
      case "up_cooling": return 9000;
      case "up_feed": return 11000;
      case "up_jets": return 28000;
      case "up_shield": return 35000;
      case "livery_mnc_kurt": return 7500;
      case "livery_mnc_militech_01": return 5000;
      case "livery_mnc_default": return 0;
      case "payload_2": return 1500;
      case "payload_3": return 2000;
      case "payload_4": return 1800;
    }

    if StrBeginsWith(item, "dlivery_") {
      return 2500;
    }
    return 5000;
  }

  public func CantBuy(item: String) -> String {
    if this.Has(item) {
      return CMText.ViewOwned();
    }
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) || CMFleet.Eddies(player) < CMFleet.Price(item) {
      return "CAN'T AFFORD";
    }
    return "";
  }

  public func Buy(item: String) -> String {
    let why = this.CantBuy(item);
    if StrLen(why) > 0 {
      return "!" + (Equals(why, "CAN'T AFFORD") ? CMText.FleetCantAfford() : why);
    }
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    let paid = CMFleet.Price(item);
    GameInstance.GetTransactionSystem(game).RemoveItem(player, MarketSystem.Money(), paid);
    GameObject.PlaySound(player, n"ui_menu_item_bought");
    ArrayPush(this.m_shopItems, StringToName(item));
    this.MarkBought(item);
    if Equals(item, "unit_4") {
      this.m_bombusBuilt = false;
    }
    return "*" + CMText.FleetBoughtFor(CMCon.Money(paid));
  }

  public func SetFit(fit: String, on: Bool) -> Void {
    this.ShopInit();
    if StrContains(fit, "=") {
      let slot = StrBeforeFirst(fit, "=") + "=";
      let i = ArraySize(this.m_shopFits) - 1;
      while i >= 0 {
        if StrBeginsWith(NameToString(this.m_shopFits[i]), slot) {
          ArrayErase(this.m_shopFits, i);
        }
        i -= 1;
      }
    } else {
      ArrayRemove(this.m_shopFits, StringToName(fit));
    }
    if on {
      ArrayPush(this.m_shopFits, StringToName(fit));
    }
    this.SyncCfg();
  }

  public func SyncCfg() -> Void {
    let cfg = CMPilotSystem.Get(this.GetGameInstance());
    if !IsDefined(cfg) {
      return;
    }
    cfg.PutInt("gun.arm_l", CMFleet.GunIndex(this.FitOf("arm_l")));
    cfg.PutInt("gun.arm_r", CMFleet.GunIndex(this.FitOf("arm_r")));
    CMPartLab.SetOn(cfg, 4, this.Fitted("bags"));
    CMPartLab.SetOn(cfg, 0, this.Fitted("hullpod"));
    CMPartLab.SetOn(cfg, 1, this.Fitted("hullpod"));
    CMPartLab.SetOn(cfg, 12, this.Fitted("counter"));
    CMPartLab.SetOn(cfg, 13, this.Fitted("counter"));
    for up in ["cooling", "feed", "jets", "shield"] {
      CMPartLab.SetUp(cfg, up, this.Fitted("up_" + up));
    }
    let livery = this.FitOf("livery");
    cfg.Put("livery", StrLen(livery) > 0 ? livery : "mnc_default");
    cfg.SetBombusPayload(StringToInt(this.FitOf("payload"), 1));
  }

  public static func GunIndex(id: String) -> Int32 {
    let i = 0;
    while i < CMWeaponSpecs.ArmGunCount() {
      if Equals(CMWeaponSpecs.ArmGunId(i), id) {
        return i;
      }
      i += 1;
    }
    return 0;
  }

  private func Fit() -> Void {
    let parts = 0;
    let i = 0;
    while i < CMFleet.Count() {
      parts += CMFleet.Parts(i);
      i += 1;
    }
    if this.m_fleetLayout == CMFleet.LayoutCode() && ArraySize(this.m_fleetHp) == parts && ArraySize(this.m_fleetHull) == CMFleet.Count()
      && ArraySize(this.m_fleetDead) == CMFleet.Count() && ArraySize(this.m_fleetRepairEnd) == CMFleet.Count() && ArraySize(this.m_fleetRepairTotal) == CMFleet.Count() {
      return;
    }
    ArrayClear(this.m_fleetHp);
    ArrayClear(this.m_fleetHull);
    ArrayClear(this.m_fleetDead);
    ArrayClear(this.m_fleetRepairEnd);
    ArrayClear(this.m_fleetRepairTotal);
    i = 0;
    while i < parts {
      ArrayPush(this.m_fleetHp, 1.0);
      i += 1;
    }
    i = 0;
    while i < CMFleet.Count() {
      ArrayPush(this.m_fleetHull, 1.0);
      ArrayPush(this.m_fleetDead, false);
      ArrayPush(this.m_fleetRepairEnd, 0.0);
      ArrayPush(this.m_fleetRepairTotal, 0.0);
      i += 1;
    }
    this.m_fleetLayout = CMFleet.LayoutCode();
  }

  public func Hp(bay: Int32, part: Int32) -> Float {
    this.Fit();
    let i = CMFleet.BayAt(bay) + part;
    return part >= 0 && part < CMFleet.Parts(bay) ? this.m_fleetHp[i] : 1.0;
  }

  public func Hull(bay: Int32) -> Float {
    this.Fit();
    return bay >= 0 && bay < CMFleet.Count() ? this.m_fleetHull[bay] : 1.0;
  }

  public func Dead(bay: Int32) -> Bool {
    this.Fit();
    return bay >= 0 && bay < CMFleet.Count() && this.m_fleetDead[bay];
  }

  public func OutBay() -> Int32 = this.m_outBay
  public func IsOut(bay: Int32) -> Bool = bay >= 0 && this.m_outBay == bay
  public func OutUnit() -> ref<NPCPuppet> {
    if this.m_outBay < 0 {
      return null;
    }
    return GameInstance.FindEntityByID(this.GetGameInstance(), this.m_outID) as NPCPuppet;
  }

  public func RepairLeft(bay: Int32) -> Float {
    this.Fit();
    if bay < 0 || bay >= CMFleet.Count() || this.m_fleetRepairEnd[bay] <= 0.0 {
      return 0.0;
    }
    let left = this.m_fleetRepairEnd[bay] - CMFleet.Now(this.GetGameInstance());
    if left <= 0.0 {
      this.FinishRepair(bay);
      return 0.0;
    }
    return left;
  }
  public func RepairTotal(bay: Int32) -> Float = bay >= 0 && bay < ArraySize(this.m_fleetRepairTotal) ? this.m_fleetRepairTotal[bay] : 0.0

  public static func Now(game: GameInstance) -> Float = GameInstance.GetTimeSystem(game).GetGameTimeStamp()

  public func Damaged(bay: Int32) -> Bool {
    if this.Dead(bay) || this.Hull(bay) < 0.995 {
      return true;
    }
    let i = 0;
    while i < CMFleet.Parts(bay) {
      if this.Hp(bay, i) < 0.995 {
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func CantDeploy(bay: Int32) -> String {
    if !this.Owned(bay) {
      return CMText.ViewNotOwned();
    }
    if this.Dead(bay) {
      return CMText.ViewDestroyed();
    }
    if this.RepairLeft(bay) > 0.0 {
      return CMText.FleetInRepair();
    }
    if this.m_outBay == bay {
      return CMText.FleetDeployed();
    }
    let link = CMLinkSystem.Get(this.GetGameInstance());
    if link.HasTestMech() {
      return CMText.FleetOneUnitOut();
    }
    if bay == 0 && CMBehemoth.Get(this.GetGameInstance()).Pending() && !CMBehemoth.Get(this.GetGameInstance()).Unloading() {
      return CMText.FleetInBehemoth();
    }
    let session = CMCSession.Get(this.GetGameInstance());
    if IsDefined(session) && session.IsActive() {
      return CMText.FleetPiloting();
    }
    return "";
  }

  public func Deploy(bay: Int32) -> String {
    let why = this.CantDeploy(bay);
    if StrLen(why) > 0 {
      return "!" + why;
    }
    let link = CMLinkSystem.Get(this.GetGameInstance());
    let cfg = CMPilotSystem.Get(this.GetGameInstance());
    let msg = "";
    if bay == 0 {

      return CMBehemoth.Get(this.GetGameInstance()).Grant();
    } else {

      let built = bay == 4 && this.m_bombusBuilt;
      msg = link.SpawnTestDrone(CMFleet.Kind(bay), false, !built, StringToName(this.FitOf("dlivery_" + CMFleet.Kind(bay))));
    }
    if StrBeginsWith(msg, "*") && link.HasTestMech() {
      this.m_outBay = bay;
      this.m_outID = link.TestID();
      this.m_applied = false;
      this.m_escort = bay > 0;
      this.m_escortStep = 0;
      this.m_escortIn = false;
      this.m_escortSeen = new Vector4(0.0, 0.0, 0.0, 0.0);
      this.StartTick();
      if bay > 0 {
        this.Autopilot().FollowV();
        this.Autopilot().Arm(this.m_outID);
      }
    }
    return msg;
  }

  public func DeployAt(bay: Int32, at: Vector4) -> String {
    let why = this.CantDeploy(bay);
    if StrLen(why) > 0 {
      return "!" + why;
    }
    let link = CMLinkSystem.Get(this.GetGameInstance());
    let cfg = CMPilotSystem.Get(this.GetGameInstance());
    let msg = link.SpawnPlayerMechAt(StringToName(cfg.Text("livery", "mnc_default")), at);
    if StrBeginsWith(msg, "*") && link.HasTestMech() {
      this.m_outBay = bay;
      this.m_outID = link.TestID();
      this.m_applied = false;
      this.m_escort = false;
      this.StartTick();
    }
    return msg;
  }

  private let m_drop: ref<CMMechDrop>;
  public func Dropping() -> Bool = IsDefined(this.m_drop) && this.m_drop.Active()
  public func DropMech(at: Vector4) -> String {
    let why = this.CantDeploy(0);
    if StrLen(why) > 0 {
      return "!" + why;
    }
    if this.Dropping() {
      return "!" + CMText.FleetDropUnderWay();
    }
    if !CMPhysStep.Present() {
      return "!" + CMText.FleetDropNeedsPhysics();
    }
    this.m_drop = CMMechDrop.Start(this.GetGameInstance(), at);
    return "*" + CMText.FleetDropIn10();
  }

  public func Recall() -> String {
    if this.m_outBay < 0 {
      return "!" + CMText.FleetNothingDeployed();
    }
    let bay = this.m_outBay;
    this.Autopilot().Stop("recalled");
    this.Capture();
    if this.m_outBay < 0 {
      return "!" + CMText.FleetWasLost(CMFleet.Name(bay));
    }
    let name = CMFleet.Name(this.m_outBay);
    CMLinkSystem.Get(this.GetGameInstance()).DespawnTestMech();
    this.m_outBay = -1;
    this.m_generation += 1;
    this.m_ticking = false;
    return "*" + CMText.FleetBackAtPool(name);
  }

  public static func Name(bay: Int32) -> String {
    if bay == 0 {
      return CMText.LinkMech();
    }
    return StrUpper(CMFleet.Kind(bay));
  }

  private func StartTick() -> Void {
    if this.m_ticking {
      return;
    }
    this.m_ticking = true;
    this.Schedule();
  }

  private func Schedule() -> Void {
    let cb = new CMFleetTick();
    cb.fleet = this;
    cb.generation = this.m_generation;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, 2.0, false);
  }

  public func OnTick(generation: Int32) -> Void {
    if generation != this.m_generation || this.m_outBay < 0 {
      this.m_ticking = false;
      return;
    }
    let link = CMLinkSystem.Get(this.GetGameInstance());

    if !link.HasTestMech() || link.TestID() != this.m_outID {
      this.m_outBay = -1;
      this.m_ticking = false;
      return;
    }
    let unit = this.OutUnit();
    if IsDefined(unit) {
      if !this.m_applied && unit.IsAttached() && !link.JustSpawned(unit) {
        this.Apply(unit);
      } else {
        if this.m_applied {
          this.Capture();
          this.Escort(unit);
        }
      }
    }
    this.Schedule();
  }

  private func Apply(unit: ref<NPCPuppet>) -> Void {
    let bay = this.m_outBay;
    let game = this.GetGameInstance();
    this.m_applied = true;
    if bay == 0 {
      let parts = CMCParts.Get(game);
      let st = parts.State(unit.GetEntityID());
      let i = 0;
      while i < CMPart.Count() {
        if i != CMPart.Torso() {
          let h = this.Hp(bay, i);
          if h <= 0.0 {
            parts.Break(unit, i);
          } else {
            st.hp[i] = h;
          }
        }
        i += 1;
      }
      parts.Effects(unit);
    } else {
      let n = CMFleet.Parts(bay);
      if n > 0 {
        let hp: array<Float>;
        let i = 0;
        while i < n {
          ArrayPush(hp, this.Hp(bay, i));
          i += 1;
        }
        CMLinkSystem.Get(game).SetDroneParts(unit.GetEntityID(), hp);
      }
    }

    if bay == 2 || bay == 3 {
      let sid = Cast<StatsObjectID>(unit.GetEntityID());
      GameInstance.GetStatsSystem(game).AddModifier(sid, RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Multiplier, 1.25));
    }

    let hpPct = bay == 0 ? CMKeys.MechHealth() : CMKeys.DroneHealth();
    if hpPct != 100 {
      let hid = Cast<StatsObjectID>(unit.GetEntityID());
      GameInstance.GetStatsSystem(game).AddModifier(hid, RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Multiplier, Cast<Float>(hpPct) / 100.0));
    }
    let hull = this.Hull(bay);
    if hull < 0.995 {
      GameInstance.GetStatPoolsSystem(game).RequestSettingStatPoolValue(Cast<StatsObjectID>(unit.GetEntityID()), gamedataStatPoolType.Health, MaxF(1.0, hull * 100.0), null, true);
    }
  }

  public func Capture() -> Void {
    let bay = this.m_outBay;
    if bay < 0 || !this.m_applied {
      return;
    }
    let game = this.GetGameInstance();
    let unit = this.OutUnit();
    if !IsDefined(unit) {
      return;
    }
    let at = CMFleet.BayAt(bay);
    if !ScriptedPuppet.IsAlive(unit) {
      if CMFleet.LostWhenKilled(bay) {
        this.Lose(bay);
        return;
      }
      this.m_fleetDead[bay] = true;
      this.m_fleetHull[bay] = 0.0;
      let i = 0;
      while i < CMFleet.Parts(bay) {
        this.m_fleetHp[at + i] = 0.0;
        i += 1;
      }
      return;
    }
    if bay == 0 {
      let st = CMCParts.Get(game).State(unit.GetEntityID());
      let i = 0;
      while i < CMPart.Count() && i < ArraySize(st.hp) {
        this.m_fleetHp[at + i] = st.hp[i];
        i += 1;
      }
    } else {
      let n = CMFleet.Parts(bay);
      if n > 0 {
        let hp = CMLinkSystem.Get(game).DroneParts(unit.GetEntityID(), n);
        let i = 0;
        while i < n {
          this.m_fleetHp[at + i] = hp[i];
          i += 1;
        }
      }
    }
    let id = Cast<StatsObjectID>(unit.GetEntityID());
    this.m_fleetHull[bay] = ClampF(GameInstance.GetStatPoolsSystem(game).GetStatPoolValue(id, gamedataStatPoolType.Health, true) / 100.0, 0.0, 1.0);
  }

  public static func PartPrice(bay: Int32, part: Int32) -> Int32 {
    if bay == 0 {
      if part == CMPart.Torso() {
        return 9000;
      }
      return part == CMPart.ArmL() || part == CMPart.ArmR() ? 7000 : 5000;
    }
    return part == 0 ? 3000 : 1500;
  }
  public static func HullPrice(bay: Int32) -> Int32 = bay == 0 ? 12000 : 4000
  public static func RebuildPrice(bay: Int32) -> Int32 = bay == 0 ? 85000 : 22000

  public func PartCost(bay: Int32, part: Int32) -> Int32 = RoundF((1.0 - this.Hp(bay, part)) * Cast<Float>(CMFleet.PartPrice(bay, part)))
  public func HullCost(bay: Int32) -> Int32 = RoundF((1.0 - this.Hull(bay)) * Cast<Float>(CMFleet.HullPrice(bay)))

  public func RepairCost(bay: Int32) -> Int32 {
    if this.Dead(bay) {
      return CMFleet.RebuildPrice(bay);
    }
    let cost = this.HullCost(bay);
    let i = 0;
    while i < CMFleet.Parts(bay) {
      cost += this.PartCost(bay, i);
      i += 1;
    }
    return cost;
  }

  public func RepairTime(bay: Int32) -> Float {
    if this.Dead(bay) {
      return 6.0 * 3600.0;
    }
    let n = this.Hull(bay) < 0.995 ? 1 : 0;
    let i = 0;
    while i < CMFleet.Parts(bay) {
      if this.Hp(bay, i) < 0.995 {
        n += 1;
      }
      i += 1;
    }
    return Cast<Float>(Max(n, 1)) * 1200.0;
  }

  public func CantRepair(bay: Int32) -> String {
    if !this.Damaged(bay) {
      return CMText.FleetNothingToRepair();
    }
    if this.m_outBay == bay {
      return CMText.FleetRecallFirst();
    }
    if this.RepairLeft(bay) > 0.0 {
      return CMText.FleetInRepair();
    }
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) || CMFleet.Eddies(player) < this.RepairCost(bay) {
      return CMText.FleetCantAfford();
    }
    return "";
  }

  public func Repair(bay: Int32) -> String {
    let why = this.CantRepair(bay);
    if StrLen(why) > 0 {
      return "!" + why;
    }
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    let cost = this.RepairCost(bay);
    GameInstance.GetTransactionSystem(game).RemoveItem(player, MarketSystem.Money(), cost);
    GameObject.PlaySound(player, n"ui_menu_item_bought");
    let t = this.RepairTime(bay);
    this.m_fleetRepairTotal[bay] = t;
    this.m_fleetRepairEnd[bay] = CMFleet.Now(game) + t;
    return "*" + (this.Dead(bay) ? CMText.FleetRebuildStarted(CMFleet.Name(bay), CMCon.Money(cost)) : CMText.FleetRepairStarted(CMFleet.Name(bay), CMCon.Money(cost)));
  }

  public static func FabItem(kind: String) -> TweakDBID {
    switch kind {
      case "octant": return t"Items.MNC_OctantParts";
      case "wyvern": return t"Items.MNC_WyvernParts";
      case "griffin": return t"Items.MNC_GriffinParts";
      case "bombus": return t"Items.MNC_BombusKit";
    }
    return TDBID.None();
  }
  public static func FabName(kind: String) -> String = Equals(kind, "bombus") ? CMText.FleetBombusKit() : CMText.FleetKindParts(StrUpper(kind))

  public static func FabNeeds(kind: String) -> array<Int32> {
    switch kind {
      case "octant": return [0, 0, 15, 5];
      case "wyvern": return [15, 8, 0, 0];
      case "griffin": return [0, 15, 6, 0];
    }
    return [0, 0, 0, 0];
  }
  public static func Material(i: Int32) -> TweakDBID {
    switch i {
      case 1: return t"Items.UncommonMaterial1";
      case 2: return t"Items.RareMaterial1";
      case 3: return t"Items.EpicMaterial1";
    }
    return t"Items.CommonMaterial1";
  }
  public static func MaterialName(i: Int32) -> String {
    switch i {
      case 1: return CMText.FleetUncommon();
      case 2: return CMText.FleetRare();
      case 3: return CMText.FleetEpic();
    }
    return CMText.FleetCommon();
  }

  public func Held(id: TweakDBID) -> Int32 {
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    if !IsDefined(player) || !TDBID.IsValid(id) {
      return 0;
    }

    let list: array<wref<gameItemData>>;
    GameInstance.GetTransactionSystem(game).GetItemList(player, list);
    let n = 0;
    for d in list {
      if IsDefined(d) && ItemID.GetTDBID(d.GetID()) == id {
      n += d.GetQuantity();
      }
    }
    return n;
  }

  public func Take(id: TweakDBID, n: Int32) -> Void {
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    if IsDefined(player) {
      GameInstance.GetTransactionSystem(game).RemoveItemByTDBID(player, id, n, true);
    }
  }

  public static func FabCost(kind: String) -> String {
    let needs = CMFleet.FabNeeds(kind);
    let s = "";
    let i = 0;
    while i < 4 {
      if needs[i] > 0 {
        s += (StrLen(s) > 0 ? " + " : "") + CMText.FleetMaterialCount(IntToString(needs[i]), CMFleet.MaterialName(i));
      }
      i += 1;
    }
    return s;
  }

  public func CantFab(kind: String) -> String {
    if !TDBID.IsValid(CMFleet.FabItem(kind)) || Equals(kind, "bombus") {
      return CMText.FleetNothingToMake();
    }
    let needs = CMFleet.FabNeeds(kind);
    let i = 0;
    while i < 4 {
      if this.Held(CMFleet.Material(i)) < needs[i] {
        return CMText.FleetNotEnoughComponents();
      }
      i += 1;
    }
    return "";
  }

  public func Fab(kind: String) -> String {
    let why = this.CantFab(kind);
    if StrLen(why) > 0 {
      return "!" + why;
    }
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    let ts = GameInstance.GetTransactionSystem(game);
    let needs = CMFleet.FabNeeds(kind);
    let i = 0;
    while i < 4 {
      if needs[i] > 0 {
        ts.RemoveItem(player, ItemID.FromTDBID(CMFleet.Material(i)), needs[i]);
      }
      i += 1;
    }
    ts.GiveItem(player, ItemID.FromTDBID(CMFleet.FabItem(kind)), 1);
    GameObject.PlaySound(player, n"ui_menu_item_bought");
    return "*" + CMText.FleetFabricated(CMFleet.FabName(kind), IntToString(this.Held(CMFleet.FabItem(kind))));
  }

  public func PartsNeed(bay: Int32) -> Int32 = this.Dead(bay) ? 3 : 1

  public func CantRepairParts(bay: Int32) -> String {
    let id = CMFleet.FabItem(CMFleet.Kind(bay));
    if bay <= 0 || bay >= 4 || !TDBID.IsValid(id) {
      return CMText.FleetNoPartsForUnit();
    }
    if !this.Damaged(bay) {
      return CMText.FleetNothingToRepair();
    }
    if this.m_outBay == bay {
      return CMText.FleetRecallFirst();
    }
    if this.RepairLeft(bay) > 0.0 {
      return CMText.FleetInRepair();
    }
    let held = this.Held(id);
    if held < this.PartsNeed(bay) {
      return this.PartsNeed(bay) == 1 ? CMText.FleetNeedPart(IntToString(this.PartsNeed(bay))) : CMText.FleetNeedParts(IntToString(this.PartsNeed(bay)));
    }
    return "";
  }

  public func RepairParts(bay: Int32) -> String {
    let why = this.CantRepairParts(bay);
    if StrLen(why) > 0 {
      return "!" + why;
    }
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    let n = this.PartsNeed(bay);
    this.Take(CMFleet.FabItem(CMFleet.Kind(bay)), n);
    GameObject.PlaySound(player, n"ui_menu_item_bought");
    let t = this.RepairTime(bay);
    this.m_fleetRepairTotal[bay] = t;
    this.m_fleetRepairEnd[bay] = CMFleet.Now(game) + t;
    return "*" + (this.Dead(bay) ? CMText.FleetRebuildStartedParts(CMFleet.Name(bay), IntToString(n)) : CMText.FleetRepairStartedParts(CMFleet.Name(bay), IntToString(n)));
  }

  public func CantAssemble() -> String {
    if this.Owned(4) {
      return CMText.ViewInYourFleet();
    }
    if this.Held(t"Items.MNC_BombusKit") < 1 {
      return CMText.FleetNoKitHeld();
    }
    return "";
  }

  public func Assemble() -> String {
    let why = this.CantAssemble();
    if StrLen(why) > 0 {
      return "!" + why;
    }
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    this.Take(t"Items.MNC_BombusKit", 1);
    GameObject.PlaySound(player, n"ui_menu_item_bought");
    ArrayPush(this.m_shopItems, n"unit_4");
    this.m_bombusBuilt = true;
    return "*" + CMText.FleetBombusBuilt();
  }

  public func LearnRecipes() -> Void {
    if this.m_fabLearned {
      return;
    }
    let cs = GameInstance.GetScriptableSystemsContainer(this.GetGameInstance()).Get(n"CraftingSystem") as CraftingSystem;
    if !IsDefined(cs) {
      return;
    }
    let book = cs.GetPlayerCraftBook();
    if !IsDefined(book) {
      return;
    }
    let shown = 0;
    for kind in ["octant", "wyvern", "griffin", "bombus"] {
      let id = CMFleet.FabItem(kind);
      if !book.KnowsRecipe(id) {
        book.AddRecipe(id);
      }
      let rec = book.GetRecipeData(id);
      if !rec.isHidden {
        shown += 1;
      }
    }
    let all = book.GetCraftableItems();
    this.m_fabLearned = true;
  }

  public static func LostWhenKilled(bay: Int32) -> Bool = bay >= 2 && bay <= 4

  private func Lose(bay: Int32) -> Void {
    this.Autopilot().Stop("the unit was lost");

    let un = StringToName("unit_" + IntToString(bay));

    if ArrayContains(this.m_shopItems, un) {
      this.MarkBought("unit_" + IntToString(bay));
    }
    while ArrayContains(this.m_shopItems, un) {
      ArrayRemove(this.m_shopItems, un);
    }
    if bay == 4 {
      this.m_bombusBuilt = false;
    }
    this.FinishRepair(bay);
    if this.m_outBay == bay {
      CMLinkSystem.Get(this.GetGameInstance()).ForgetTestMech();
      this.m_outBay = -1;
      this.m_generation += 1;
      this.m_ticking = false;
    }
    let player = GetPlayer(this.GetGameInstance());
    if IsDefined(player) {
      player.SetWarningMessage(CMText.FleetUnitLost(CMFleet.Name(bay)));
    }
  }

  private func FinishRepair(bay: Int32) -> Void {
    let at = CMFleet.BayAt(bay);
    let i = 0;
    while i < CMFleet.Parts(bay) {
      this.m_fleetHp[at + i] = 1.0;
      i += 1;
    }
    this.m_fleetHull[bay] = 1.0;
    this.m_fleetDead[bay] = false;
    this.m_fleetRepairEnd[bay] = 0.0;
    this.m_fleetRepairTotal[bay] = 0.0;
  }

  public static func Eddies(player: ref<PlayerPuppet>) -> Int32 {
    if !IsDefined(player) {
      return 0;
    }
    return GameInstance.GetTransactionSystem(player.GetGame()).GetItemQuantity(player, MarketSystem.Money());
  }

  public func Escorting() -> Bool = this.m_escort && this.m_outBay > 0
  public func SetEscort(on: Bool) -> Void {
    this.m_escort = on && this.m_outBay > 0;
    this.m_escortIn = false;
    if !this.m_escort {
      this.Autopilot().Stop("another order");
    } else {
      let u = CMLinkSystem.Get(this.GetGameInstance()).Unit();
      if IsDefined(u) {
        this.Autopilot().FollowV();
        this.Autopilot().Arm(u.GetEntityID());
      }
    }
  }

  private let m_auto: ref<CMDroneAutopilot>;
  public func Autopilot() -> ref<CMDroneAutopilot> {
    if !IsDefined(this.m_auto) {
      this.m_auto = CMDroneAutopilot.Make(this.GetGameInstance());
    }
    return this.m_auto;
  }

  private let m_escortSeen: Vector4;

  public func SendTo(at: Vector4, loiter: Bool) -> String {
    if this.m_outBay <= 0 {
      return "!" + CMText.FleetNoDroneOut();
    }
    let unit = this.OutUnit();
    if !IsDefined(unit) || !CMLinkSystem.Get(this.GetGameInstance()).IsLinkedTo(unit.GetEntityID()) {
      return "!" + CMText.FleetDroneNotLinked();
    }
    this.m_escort = true;
    let ap = this.Autopilot();
    if !ap.Flying(unit.GetEntityID()) {
      let why = ap.Start();
      if StrLen(why) > 0 {
        return "!" + StrUpper(why);
      }
    }
    ap.SetPoint(at, loiter);
    return "*" + (loiter ? CMText.FleetLoitering(CMFleet.Name(this.m_outBay)) : CMText.FleetHoldingOver(CMFleet.Name(this.m_outBay)));
  }

  private func Escort(unit: ref<NPCPuppet>) -> Void {
    if !this.m_escort || this.m_outBay <= 0 || !ScriptedPuppet.IsAlive(unit) {
      return;
    }
    let game = this.GetGameInstance();
    let link = CMLinkSystem.Get(game);
    let session = CMCSession.Get(game);
    if !link.IsLinkedTo(unit.GetEntityID()) || (IsDefined(session) && session.IsActive()) {
      return;
    }
    let ap = this.Autopilot();
    if !ap.Flying(unit.GetEntityID()) {
      let why = ap.Start();
      if StrLen(why) > 0 {
      }
    }
  }
}

public class CMFabLearnCb extends DelayCallback {
  public let fleet: wref<CMFleet>;
  public func Call() -> Void {
    if IsDefined(this.fleet) {
      this.fleet.LearnRecipes();
    }
  }
}
