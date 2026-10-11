module ControllableMechs

import ControllableMechs.Control.*

public abstract class CMOrder {
  public static func None() -> Int32 = 0
  public static func Follow() -> Int32 = 1
  public static func Hold() -> Int32 = 2
  public static func MoveTo() -> Int32 = 3
  public static func Pilot() -> Int32 = 4
}

public class CMLinkSystem extends ScriptableSystem {

  private let m_cmPresetHits: array<Int32>;
  private let m_cmPresetMisses: array<Int32>;

  public func PresetAlive(dynamic: Bool) -> Bool {
    let i = dynamic ? 1 : 0;
    if ArraySize(this.m_cmPresetHits) < 2 {
      return true;
    }
    return this.m_cmPresetHits[i] > 0 || this.m_cmPresetMisses[i] < 20;
  }

  public func PresetNote(dynamic: Bool, presetHit: Bool, groupHit: Bool) -> Void {
    if ArraySize(this.m_cmPresetHits) < 2 {
      ArrayResize(this.m_cmPresetHits, 2);
      ArrayResize(this.m_cmPresetMisses, 2);
    }
    let i = dynamic ? 1 : 0;
    if presetHit {
      this.m_cmPresetHits[i] += 1;
    } else {
      if groupHit {
        this.m_cmPresetMisses[i] += 1;
        if this.m_cmPresetMisses[i] == 20 && this.m_cmPresetHits[i] == 0 {
        }
      }
    }
  }

  private let m_unitID: EntityID;
  private let m_linked: Bool;
  private let m_order: Int32;
  private let m_cmd: ref<AICommand>;
  private let m_generation: Int32;
  private let m_testID: EntityID;
  private let m_listening: Bool;
  private let m_stationed: Bool;

  private let LINK_RANGE: Float = 60.0;

  public static func SignalRange() -> Float = 250.0

  public func Range() -> Float {
    let unit = this.Unit();

    if this.m_hijacked {
      return CMLinkSystem.HijackRange();
    }
    return IsDefined(unit) && Equals(unit.GetNPCType(), gamedataNPCType.Drone) ? 500.0 : CMLinkSystem.SignalRange();
  }
  private let CHECK_TICK: Float = 1.0;

  public static func Plain(msg: String) -> String = StrReplaceAll(StrReplaceAll(msg, "!", ""), "*", "")

  public static func Get(game: GameInstance) -> ref<CMLinkSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"ControllableMechs.CMLinkSystem") as CMLinkSystem;
  }

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {

    this.Clear();
    let empty: EntityID;
    this.m_testID = empty;
  }

  private func Clear() -> Void {
    this.m_generation += 1;
    this.m_linked = false;
    this.m_stationed = false;
    this.m_order = CMOrder.None();
    this.m_cmd = null;
  }

  public static func IsRobot(npc: ref<NPCPuppet>) -> Bool {
    if !IsDefined(npc) {
      return false;
    }
    switch npc.GetNPCType() {
      case gamedataNPCType.Mech:
      case gamedataNPCType.Android:
      case gamedataNPCType.Drone:
      case gamedataNPCType.Spiderbot:
        return true;
    }
    return false;
  }

  public static func KindName(npc: ref<NPCPuppet>) -> String {
    if !IsDefined(npc) {
      return "";
    }
    switch npc.GetNPCType() {
      case gamedataNPCType.Mech:
        return CMText.LinkMech();
      case gamedataNPCType.Android:
        return CMText.LinkAndroid();
      case gamedataNPCType.Drone:
        return CMText.LinkDrone();
      case gamedataNPCType.Spiderbot:
        return CMText.LinkSpiderbot();
    }
    return CMText.LinkUnit();
  }

  public static func KindId(npc: ref<NPCPuppet>) -> String {
    if !IsDefined(npc) {
      return "";
    }
    switch npc.GetNPCType() {
      case gamedataNPCType.Mech:
        return "MECH";
      case gamedataNPCType.Android:
        return "ANDROID";
      case gamedataNPCType.Drone:
        return "DRONE";
      case gamedataNPCType.Spiderbot:
        return "SPIDERBOT";
    }
    return "UNIT";
  }

  public func IsLinked() -> Bool = this.m_linked && IsDefined(this.Unit())

  public func SetStationed(on: Bool) -> Void { this.m_stationed = on && this.m_linked; }
  public func IsStationed() -> Bool = this.m_stationed
  private func StationedNow() -> Bool {
    if !this.m_stationed || this.m_order != CMOrder.Hold() {
      return false;
    }
    let session = CMCSession.Get(this.GetGameInstance());
    return !(IsDefined(session) && session.IsActive());
  }
  public func Order() -> Int32 = this.m_order
  public func SetOrder(order: Int32) -> Void { this.m_order = order; }

  public func Unit() -> ref<NPCPuppet> {
    if !this.m_linked {
      return null;
    }
    return GameInstance.FindEntityByID(this.GetGameInstance(), this.m_unitID) as NPCPuppet;
  }

  public func LinkLookAt() -> String {
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) {
      return "";
    }
    let npc = GameInstance.GetTargetingSystem(this.GetGameInstance()).GetLookAtObject(player) as NPCPuppet;
    if !CMLinkSystem.IsRobot(npc) {
      return "!" + CMText.LinkNoRobotInSight();
    }
    if !ScriptedPuppet.IsAlive(npc) {
      return "!" + CMText.LinkIsDestroyed(CMLinkSystem.KindName(npc));
    }
    if npc.IsQuest() {
      return "!" + CMText.LinkShielded(CMLinkSystem.KindName(npc));
    }
    if Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > this.LINK_RANGE {
      return "!" + CMText.LinkOutOfRange();
    }
    return this.Link(npc);
  }

  public func Link(npc: ref<NPCPuppet>) -> String {
    if this.m_linked {
      this.Unlink();
    }
    this.m_unitID = npc.GetEntityID();
    this.m_linked = true;
    this.m_generation += 1;
    this.MakeFriendly(npc);
    this.SetNoRole(npc);
    this.Hold();

    if Equals(npc.GetNPCType(), gamedataNPCType.Mech) {
      CMCParts.Get(this.GetGameInstance()).Effects(npc);
      CMPartLab.Apply(npc);
    }
    this.Schedule();
    return "*" + CMText.LinkLinked(CMLinkSystem.KindName(npc));
  }

  public func Unlink() -> Void {
    let session = CMCSession.Get(this.GetGameInstance());
    if IsDefined(session) && session.IsActive() {
      session.End(CMText.LinkNeuralClosed(), false);
    }
    let unit = this.Unit();
    if this.m_hijacked {
      this.m_hijacked = false;
      if IsDefined(unit) && ScriptedPuppet.IsAlive(unit) {
        this.Unhijack(unit);
      }
    }
    if IsDefined(unit) {
      this.CancelCmd(unit);
      CMCParts.Get(this.GetGameInstance()).DropFx(unit);
    }
    CMCParts.Get(this.GetGameInstance()).SetTest(null, false);
    this.Clear();
  }

  public func HasTestMech() -> Bool = EntityID.IsDefined(this.m_testID)

  public func TestID() -> EntityID = this.m_testID
  public func IsLinkedTo(id: EntityID) -> Bool = this.m_linked && this.m_unitID == id

  public func SpawnTestMech(opt appearance: CName) -> String {
    return this.SpawnTest([t"Character.q003_militech_mech", t"Character.q114_arasaka_netnest_mech_friendly_quest", t"Character.Mech_NPC_Base"], appearance, 0.0, "*" + CMText.LinkMinotaurInbound(), "!" + CMText.LinkNoMinotaurRecord());
  }

  private let m_cmSpawnAt: Float;

  public func SpawnAge(unit: ref<GameObject>) -> Float {
    if !IsDefined(unit) || unit.GetEntityID() != this.m_testID {
      return -1.0;
    }
    return EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance())) - this.m_cmSpawnAt;
  }

  public let lastProxy: EntityID;

  public func JustSpawned(unit: ref<GameObject>) -> Bool {
    return unit.GetEntityID() == this.m_testID && EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance())) - this.m_cmSpawnAt < 5.0;
  }

  public func SpawnPlayerMech(opt livery: CName) -> String {

    let look = livery;
    if IsNameValid(livery) {
      look = CMPartLab.LookFor(NameToString(livery), CMPilotSystem.Get(this.GetGameInstance()), false, false);
    }
    return this.SpawnTest([t"Character.mnc_player_minotaur"], look, 0.0, "*" + CMText.LinkMechInbound(), "!" + CMText.LinkNoMechRecord());
  }

  public func LabUnit() -> ref<GameObject> {
    let unit = this.Unit();
    if IsDefined(unit) && IsDefined(unit.FindComponentByName(CMPartLab.Name(0))) {
      return unit;
    }
    let test = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_testID) as GameObject;
    if IsDefined(test) {
      return test;
    }
    return unit;
  }

  public func SpawnPlayerMechAt(livery: CName, at: Vector4) -> String {
    let look = livery;
    if IsNameValid(livery) {
      look = CMPartLab.LookFor(NameToString(livery), CMPilotSystem.Get(this.GetGameInstance()), false, false);
    }
    this.m_fixed = true;
    this.m_fixedAt = at;
    let msg = this.SpawnTest([t"Character.mnc_player_minotaur"], look, 0.0, "*" + CMText.LinkMechDropping(), "!" + CMText.LinkNoMechRecord());
    this.m_fixed = false;
    return msg;
  }
  private let m_fixed: Bool;
  private let m_fixedAt: Vector4;

  public func HoldGroundCheck(secs: Float) -> Void {
    this.m_groundHoldUntil = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance())) + secs;
  }
  private let m_groundHoldUntil: Float;

  public func SpawnTestDrone(kind: String, opt physics: Bool, opt far: Bool, opt look: CName) -> String {
    this.m_far = far;
    let records: array<TweakDBID>;
    switch kind {
      case "bombus":
        records = [t"Character.aldecaldos_drone_bombus_easy", t"Character.aldecaldos_base_drone_bombus", t"Character.con_kurtz_base_drone_bombus"];
        break;
      case "griffin":
        records = [t"Character.bls_se_militech_drone_griffin_medium", t"Character.bls_se_militech_drone_griffin_hard", t"Character.arr_militech_drone_griffin_hard"];
        break;
      case "wyvern":
        records = [t"Character.bls_se_militech_drone_wyvern_medium", t"Character.arasaka_drone_wyvern_medium4", t"Character.bou_kurtz_base_drone_wyvern"];
        break;
      default:
        records = [t"Character.bls_se_militech_drone_octant_medium", t"Character.border_patrol_octant", t"Character.arasaka_drone_octant_easy4"];
    }
    let msg = this.SpawnTest(records, look, 2.5, "*" + CMText.LinkKindInbound(StrUpper(kind)), "!" + CMText.LinkNoKindRecord(StrUpper(kind)));
    this.m_far = false;
    return msg;
  }
  private let m_far: Bool;

  private func SpawnTest(records: array<TweakDBID>, appearance: CName, lift: Float, ok: String, missing: String) -> String {
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return "";
    }
    if this.HasTestMech() {
      return "!" + CMText.LinkTestUnitOut();
    }
    let record: TweakDBID;
    let found = false;
    for id in records {
      if !found && IsDefined(TweakDBInterface.GetCharacterRecord(id)) {
        record = id;
        found = true;
      }
    }
    if !found {
      return missing;
    }
    if !this.m_listening {
      GameInstance.GetDynamicEntitySystem().RegisterListener(n"ControllableMechsTest", this, n"OnTestMechEvent");
      this.m_listening = true;
    }
    let fwd = player.GetWorldForward();
    fwd.Z = 0.0;
    fwd = Vector4.Normalize(fwd);
    let at: Vector4;
    if this.m_fixed {
      at = this.m_fixedAt;
    } else {
    if this.m_far {

      at = this.LaunchPoint(player.GetWorldPosition(), fwd);
    } else {
      if !this.SpawnPoint(player.GetWorldPosition(), fwd, at) {
        GameObject.PlaySoundEvent(player, n"ui_hacking_press_fail");
        return "!" + CMText.LinkNoClearLz();
      }
    }
    }
    let spec = new DynamicEntitySpec();
    spec.recordID = record;
    spec.position = at + new Vector4(0.0, 0.0, lift, 0.0);
    let face: EulerAngles;
    face.Yaw = CMPilotRig.YawOf(fwd) + 180.0;
    spec.orientation = EulerAngles.ToQuat(face);
    spec.persistState = false;
    spec.persistSpawn = false;
    spec.alwaysSpawned = true;
    if NotEquals(appearance, n"") {
      spec.appearanceName = appearance;
    }
    spec.tags = [n"ControllableMechsTest"];
    this.m_testID = GameInstance.GetDynamicEntitySystem().CreateEntity(spec);
    this.m_cmSpawnAt = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance()));
    return ok;
  }

  private func LaunchPoint(me: Vector4, fwd: Vector4) -> Vector4 {
    let game = this.GetGameInstance();
    let back = CMPilotRig.YawOf(fwd) + 180.0;
    let i = 0;
    while i < 12 {
      let yaw = back + Cast<Float>((i + 1) / 2) * 30.0 * ((i % 2) == 0 ? 1.0 : -1.0);
      let d = CMPilotRig.Dir(yaw, 0.0);
      let p = new Vector4(me.X + d.X * 110.0, me.Y + d.Y * 110.0, me.Z + 26.0, 1.0);
      p.Z = MaxF(p.Z, this.TopAt(p, me) + 12.0);
      if this.AirClear(p) {
        return p;
      }
      i += 1;
    }
    let over = new Vector4(me.X, me.Y, MaxF(me.Z + 26.0, this.TopAt(me, me) + 12.0), 1.0);
    return over;
  }

  private func TopAt(p: Vector4, me: Vector4) -> Float {
    let hit: TraceResult;
    if CMGround.Down(this.GetGameInstance(), new Vector4(p.X, p.Y, me.Z + 400.0, 1.0), new Vector4(p.X, p.Y, me.Z - 60.0, 1.0), hit) {
      return Cast<Vector4>(hit.position).Z;
    }
    return me.Z;
  }

  private func AirClear(p: Vector4) -> Bool {
    let game = this.GetGameInstance();
    let hit: TraceResult;
    let dirs = [new Vector4(6.0, 0.0, 0.0, 0.0), new Vector4(-6.0, 0.0, 0.0, 0.0), new Vector4(0.0, 6.0, 0.0, 0.0), new Vector4(0.0, -6.0, 0.0, 0.0), new Vector4(0.0, 0.0, 5.0, 0.0), new Vector4(0.0, 0.0, -5.0, 0.0)];
    for v in dirs {
      if CMGround.Down(game, p, p + v, hit) {
        return false;
      }
    }
    return true;
  }

  private func SpawnPoint(from: Vector4, fwd: Vector4, out at: Vector4) -> Bool {
    let yaw = CMPilotRig.YawOf(fwd);
    let dists: array<Float> = [14.0, 10.0, 6.0, 10.0, 10.0];
    let turns: array<Float> = [0.0, 0.0, 0.0, 40.0, -40.0];
    let fallback: Vector4;
    let haveFallback = false;
    let i = 0;
    while i < ArraySize(dists) {
      let p: Vector4;
      let onMesh = false;
      if this.GroundAt(from, CMPilotRig.Dir(yaw + turns[i], 0.0), dists[i], p, onMesh) {
        if onMesh {
          at = p;
          return true;
        }
        if !haveFallback {
          fallback = p;
          haveFallback = true;
        }
      }
      i += 1;
    }
    if haveFallback {
      at = fallback;
      return true;
    }
    return false;
  }

  private func GroundAt(from: Vector4, dir: Vector4, dist: Float, out p: Vector4, out onMesh: Bool) -> Bool {
    let game = this.GetGameInstance();
    let sq = GameInstance.GetSpatialQueriesSystem(game);
    let hit: TraceResult;
    let reach = dist;
    let chest = new Vector4(from.X, from.Y, from.Z + 1.2, 1.0);
    if sq.SyncRaycastByCollisionGroup(chest, chest + dir * (reach + 3.0), n"Static", hit, true, false) {
      reach = Vector4.Distance(chest, Cast<Vector4>(hit.position)) - 3.0;
    }
    if reach < 5.0 {
      return false;
    }
    let over = from + dir * reach;

    let found = false;
    for lift in [3.0, 8.0] {
      if !found && CMGround.Down(game, new Vector4(over.X, over.Y, over.Z + lift, 1.0), new Vector4(over.X, over.Y, over.Z - 8.0, 1.0), hit) {
        found = true;
      }
    }
    if !found {
      return false;
    }
    p = Cast<Vector4>(hit.position);
    p.W = 1.0;
    if AbsF(p.Z - from.Z) > 5.0 {
      return false;
    }

    let nav = GameInstance.GetNavigationSystem(game).GetNearestNavmeshPointBelowOnlyHumanNavmesh(new Vector4(p.X, p.Y, p.Z + 1.5, 1.0), 1.5, 4);
    onMesh = !Vector4.IsZero(nav) && AbsF(nav.Z - p.Z) < 2.5;
    if onMesh {
      p = nav;
      p.W = 1.0;
    }
    return true;
  }
  public func DespawnTestMech() -> Void {
    if !this.HasTestMech() {
      return;
    }
    if this.m_linked && this.m_unitID == this.m_testID {
      this.Unlink();
    }
    GameInstance.GetDynamicEntitySystem().DeleteEntity(this.m_testID);
    let empty: EntityID;
    this.m_testID = empty;
  }

  public func ForgetTestMech() -> Void {
    if !this.HasTestMech() {
      return;
    }
    if this.m_linked && this.m_unitID == this.m_testID {
      this.Unlink();
    }
    let empty: EntityID;
    this.m_testID = empty;
  }

  protected cb func OnTestMechEvent(event: ref<DynamicEntityEvent>) -> Void {
    if !Equals(event.GetEventType(), DynamicEntityEventType.Spawned) || event.GetEntityID() != this.m_testID {
      return;
    }
    let npc = GameInstance.GetDynamicEntitySystem().GetEntity(this.m_testID) as NPCPuppet;
    if IsDefined(npc) {
      let msg = this.Link(npc);
      let player = GetPlayer(this.GetGameInstance());
      if IsDefined(player) {
        player.SetWarningMessage(CMLinkSystem.Plain(msg));
      }
    }
  }

  public func Follow() -> Void {
    let unit = this.Unit();
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(unit) || !IsDefined(player) {
      return;
    }
    let cmd = new AIFollowTargetCommand();
    cmd.target = player;
    cmd.lookAtTarget = player;
    cmd.desiredDistance = 6.0;
    cmd.tolerance = 2.0;
    cmd.stopWhenDestinationReached = false;
    cmd.movementType = moveMovementType.Run;

    cmd.teleport = false;
    this.Send(unit, cmd, CMOrder.Follow());
  }

  public func Hold() -> Void {
    let unit = this.Unit();
    if !IsDefined(unit) {
      return;
    }
    this.CancelCmd(unit);
    this.m_order = CMOrder.Hold();
  }

  public func MoveToLookAt() -> Void {
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) {
      return;
    }
    let target = GameInstance.GetTargetingSystem(this.GetGameInstance()).GetLookAtObject(player);
    let pos: Vector4;
    if IsDefined(target) && NotEquals(target.GetEntityID(), this.m_unitID) {
      pos = target.GetWorldPosition();
    } else {
      pos = player.GetWorldPosition() + player.GetWorldForward() * 15.0;
    }
    this.MoveTo(pos);
  }

  public func MoveTo(pos: Vector4) -> Void {
    let unit = this.Unit();
    if !IsDefined(unit) {
      return;
    }
    let world: WorldPosition;
    WorldPosition.SetVector4(world, pos);
    let spec: AIPositionSpec;
    AIPositionSpec.SetWorldPosition(spec, world);
    let cmd = new AIMoveToCommand();
    cmd.movementTarget = spec;
    cmd.ignoreNavigation = false;
    cmd.finishWhenDestinationReached = true;
    this.Send(unit, cmd, CMOrder.MoveTo());
  }

  private func Send(unit: ref<NPCPuppet>, cmd: ref<AICommand>, order: Int32) -> Void {
    let ai = unit.GetAIControllerComponent();
    if !IsDefined(ai) {
      return;
    }
    this.CancelCmd(unit);
    this.m_stationed = false;
    ai.SendCommand(cmd);
    this.m_cmd = cmd;
    this.m_order = order;
  }

  private func CancelCmd(unit: ref<NPCPuppet>) -> Void {
    if IsDefined(this.m_cmd) {
      let ai = unit.GetAIControllerComponent();
      if IsDefined(ai) {
        ai.CancelCommand(this.m_cmd);
      }
      this.m_cmd = null;
    }
  }

  public func HealthFraction() -> Float {
    let unit = this.Unit();
    if !IsDefined(unit) {
      return 0.0;
    }
    let id = Cast<StatsObjectID>(unit.GetEntityID());
    return GameInstance.GetStatPoolsSystem(this.GetGameInstance()).GetStatPoolValue(id, gamedataStatPoolType.Health, true) / 100.0;
  }

  public func Distance() -> Float {
    let unit = this.Unit();
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(unit) || !IsDefined(player) {
      return -1.0;
    }
    return Vector4.Distance(player.GetWorldPosition(), unit.GetWorldPosition());
  }

  public func SignalFraction() -> Float {
    let d = this.Distance();
    return d < 0.0 ? 0.0 : ClampF(1.0 - d / this.Range(), 0.0, 1.0);
  }

  public func UnitName() -> String {
    let unit = this.Unit();
    return IsDefined(unit) ? unit.GetDisplayName() : "";
  }

  public func UnitKind() -> String = CMLinkSystem.KindId(this.Unit())

  private let m_droneParts: array<Float>;
  private let m_dronePartsOf: EntityID;

  public func DroneParts(id: EntityID, n: Int32) -> array<Float> {
    let out: array<Float>;
    let keep = id == this.m_dronePartsOf && ArraySize(this.m_droneParts) == n;
    let i = 0;
    while i < n {
      ArrayPush(out, keep ? this.m_droneParts[i] : 1.0);
      i += 1;
    }
    return out;
  }

  public func SetDroneParts(id: EntityID, parts: array<Float>) -> Void {
    this.m_dronePartsOf = id;
    ArrayClear(this.m_droneParts);
    for p in parts {
      ArrayPush(this.m_droneParts, p);
    }
  }

  private let m_podsOf: EntityID;
  private let m_podHidden: array<wref<IComponent>>;
  private let m_podMasks: array<Uint64>;
  private let m_podLights: array<wref<IComponent>>;
  private let m_jetsOff: Bool;

  public func PodsOf() -> EntityID = this.m_podsOf

  public func KeepPods(id: EntityID, hidden: array<wref<IComponent>>, masks: array<Uint64>, lights: array<wref<IComponent>>, jetsOff: Bool) -> Void {
    this.m_podsOf = id;
    this.ForgetPods();
    for c in hidden {
      ArrayPush(this.m_podHidden, c);
    }
    for m in masks {
      ArrayPush(this.m_podMasks, m);
    }
    for c in lights {
      ArrayPush(this.m_podLights, c);
    }
    this.m_jetsOff = jetsOff;
  }

  public func KeptPodHidden() -> array<wref<IComponent>> = this.m_podHidden
  public func KeptPodMasks() -> array<Uint64> = this.m_podMasks
  public func KeptPodLights() -> array<wref<IComponent>> = this.m_podLights
  public func KeptJetsOff() -> Bool = this.m_jetsOff

  public func ForgetPods() -> Void {
    ArrayClear(this.m_podHidden);
    ArrayClear(this.m_podMasks);
    ArrayClear(this.m_podLights);
    this.m_jetsOff = false;
  }

  public func DevDronePart(part: Int32, n: Int32) -> Void {
    let unit = this.Unit();
    if !IsDefined(unit) {
      return;
    }
    let parts = this.DroneParts(unit.GetEntityID(), n);
    let i = 0;
    while i < n {
      if part < 0 {
        parts[i] = 1.0;
      } else {
        if i == part {
          parts[i] = 0.0;
        }
      }
      i += 1;
    }
    this.SetDroneParts(unit.GetEntityID(), parts);
  }

  private func Schedule() -> Void {
    let cb = new CMLinkTick();
    cb.system = this;
    cb.generation = this.m_generation;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, this.CHECK_TICK, false);
  }

  public func OnTick(generation: Int32) -> Void {
    if generation != this.m_generation || !this.m_linked {
      return;
    }
    let unit = this.Unit();
    let player = GetPlayer(this.GetGameInstance());
    let stationed = this.StationedNow();
    if stationed && !IsDefined(unit) {

      this.Schedule();
      return;
    }
    if !IsDefined(unit) || !ScriptedPuppet.IsAlive(unit) {

      let session = CMCSession.Get(this.GetGameInstance());
      if IsDefined(session) && session.IsActive() {
        this.Schedule();
        return;
      }
      this.Drop(player, CMText.LinkLost());
      return;
    }
    if !stationed && this.Distance() > this.Range() {
      this.Drop(player, CMText.LinkOutOfSignal(CMLinkSystem.KindName(unit)));
      return;
    }
    let session = CMCSession.Get(this.GetGameInstance());
    if Equals(unit.GetNPCType(), gamedataNPCType.Mech) && !(IsDefined(session) && session.IsActive()) {
      this.KeepGrounded(unit);
    }
    this.Schedule();
  }

  private let m_airChecks: Int32;

  private func KeepGrounded(mech: ref<NPCPuppet>) -> Void {
    if EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance())) < this.m_groundHoldUntil {
      return;
    }
    let pos = mech.GetWorldPosition();
    let hit: TraceResult;
    let gap = 0.0;
    if CMGround.Down(this.GetGameInstance(), new Vector4(pos.X, pos.Y, pos.Z + 0.5, 1.0), new Vector4(pos.X, pos.Y, pos.Z - 60.0, 1.0), hit) {
      gap = pos.Z - Cast<Vector4>(hit.position).Z;
    }
    if gap < 2.0 {
      this.m_airChecks = 0;
      return;
    }
    this.m_airChecks += 1;

    if this.m_airChecks < 3 {
      return;
    }
    this.m_airChecks = -2;
    CMGround.SetDown(mech, Cast<Vector4>(hit.position));
  }

  private func Drop(player: ref<PlayerPuppet>, why: String) -> Void {
    this.Unlink();
    if IsDefined(player) {
      player.SetWarningMessage(why);
    }
  }

  public func TestAttitude(npc: ref<NPCPuppet>, on: Bool) -> Void {
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) || !IsDefined(npc) {
      return;
    }
    let playerAgent = player.GetAttitudeAgent();
    let npcAgent = npc.GetAttitudeAgent();
    if !IsDefined(playerAgent) || !IsDefined(npcAgent) {
      return;
    }
    if on {
      npcAgent.SetAttitudeTowards(playerAgent, EAIAttitude.AIA_Neutral);
      playerAgent.SetAttitudeTowards(npcAgent, EAIAttitude.AIA_Neutral);
    } else {
      playerAgent.SetAttitudeTowards(npcAgent, EAIAttitude.AIA_Friendly);
      this.MakeFriendly(npc);
    }
  }

  private let m_hijacked: Bool;
  private let m_hijackGroup: CName;
  public static func HijackRange() -> Float = 120.0

  public func Hijack(npc: ref<NPCPuppet>) -> String {
    let agent = npc.GetAttitudeAgent();
    let group = IsDefined(agent) ? agent.GetAttitudeGroup() : n"";
    let msg = this.Link(npc);
    this.m_hijacked = true;
    this.m_hijackGroup = group;
    return msg;
  }

  private func Unhijack(npc: ref<NPCPuppet>) -> Void {
    let player = GetPlayer(this.GetGameInstance());
    let agent = npc.GetAttitudeAgent();
    if IsDefined(agent) && IsNameValid(this.m_hijackGroup) {
      agent.SetAttitudeGroup(this.m_hijackGroup);
    }
    if IsDefined(agent) && IsDefined(player) && IsDefined(player.GetAttitudeAgent()) {
      agent.SetAttitudeTowards(player.GetAttitudeAgent(), EAIAttitude.AIA_Hostile);
    }
  }

  private func MakeFriendly(npc: ref<NPCPuppet>) -> Void {
    let player = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) {
      return;
    }
    let playerAgent = player.GetAttitudeAgent();
    let npcAgent = npc.GetAttitudeAgent();
    if IsDefined(playerAgent) && IsDefined(npcAgent) {
      npcAgent.SetAttitudeGroup(playerAgent.GetAttitudeGroup());
      npcAgent.SetAttitudeTowards(playerAgent, EAIAttitude.AIA_Friendly);
    }
  }

  private func SetNoRole(npc: ref<NPCPuppet>) -> Void {
    let ai = npc.GetAIControllerComponent();
    if IsDefined(ai) {
      ai.SetAIRole(new AINoRole());
      ai.OnAttach();
    }
  }
}

public abstract class CMGround {

  public static func PresetOn(game: GameInstance, dynamic: Bool) -> Bool {
    let l = CMLinkSystem.Get(game);
    return !IsDefined(l) || l.PresetAlive(dynamic);
  }
  public static func PresetSeen(game: GameInstance, dynamic: Bool, presetHit: Bool, groupHit: Bool) -> Void {
    let l = CMLinkSystem.Get(game);
    if IsDefined(l) {
      l.PresetNote(dynamic, presetHit, groupHit);
    }
  }

  public static func Down(game: GameInstance, from: Vector4, to: Vector4, out hit: TraceResult) -> Bool {
    let sq = GameInstance.GetSpatialQueriesSystem(game);
    let tryPreset = CMGround.PresetOn(game, false);
    if tryPreset && sq.SyncRaycastByCollisionPreset(from, to, n"World Static", hit, true) {
      CMGround.PresetSeen(game, false, true, true);
      return true;
    }
    let got = sq.SyncRaycastByCollisionGroup(from, to, n"Static", hit, true, false) || sq.SyncRaycastByCollisionGroup(from, to, n"Terrain", hit, true, false);
    if tryPreset {
      CMGround.PresetSeen(game, false, false, got);
    }
    return got;
  }

  public static func World(game: GameInstance, from: Vector4, to: Vector4, out hit: TraceResult) -> Bool {
    let sq = GameInstance.GetSpatialQueriesSystem(game);
    let tryPreset = CMGround.PresetOn(game, false);
    if tryPreset && sq.SyncRaycastByCollisionPreset(from, to, n"World Static", hit, true) {
      CMGround.PresetSeen(game, false, true, true);
      return true;
    }
    let a: TraceResult;
    let b: TraceResult;
    let gotA = sq.SyncRaycastByCollisionGroup(from, to, n"Static", a, true, false);
    let gotB = sq.SyncRaycastByCollisionGroup(from, to, n"Terrain", b, true, false);
    if tryPreset {
      CMGround.PresetSeen(game, false, false, gotA || gotB);
    }
    if gotA && (!gotB || Vector4.Distance(from, Cast<Vector4>(a.position)) <= Vector4.Distance(from, Cast<Vector4>(b.position))) {
      hit = a;
      return true;
    }
    if gotB {
      hit = b;
      return true;
    }
    return false;
  }

  public static func Movers(game: GameInstance, from: Vector4, to: Vector4, out hit: TraceResult) -> Bool {
    let sq = GameInstance.GetSpatialQueriesSystem(game);
    let tryPreset = CMGround.PresetOn(game, true);
    if tryPreset && sq.SyncRaycastByCollisionPreset(from, to, n"World Dynamic", hit, true) {
      CMGround.PresetSeen(game, true, true, true);
      return true;
    }
    let best = 1000000.0;
    let found = false;
    for g in [n"AI", n"Dynamic", n"Vehicle"] {
      let h: TraceResult;
      if sq.SyncRaycastByCollisionGroup(from, to, g, h, false, false) {
        let d = Vector4.Distance(from, Cast<Vector4>(h.position));
        if d < best {
          best = d;
          hit = h;
          found = true;
        }
      }
    }
    if tryPreset {
      CMGround.PresetSeen(game, true, false, found);
    }
    return found;
  }

  public static func SetDown(mech: ref<NPCPuppet>, ground: Vector4) -> Void {
    let ai = mech.GetAIControllerComponent();
    if !IsDefined(ai) {
      return;
    }
    let cmd = new AITeleportCommand();
    cmd.position = new Vector4(ground.X, ground.Y, ground.Z + 0.3, 1.0);
    cmd.rotation = CMPilotRig.YawOf(mech.GetWorldForward());
    cmd.doNavTest = false;
    ai.SendCommand(cmd);
    GameObject.PlaySoundEvent(mech, n"nme_boss_smasher_lcm_servo_short");
  }
}

public class CMLinkTick extends DelayCallback {
  public let system: wref<CMLinkSystem>;
  public let generation: Int32;

  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.OnTick(this.generation);
    }
  }
}
