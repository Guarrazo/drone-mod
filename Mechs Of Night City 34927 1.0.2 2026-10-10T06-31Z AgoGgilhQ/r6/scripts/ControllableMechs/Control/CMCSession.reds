module ControllableMechs.Control

import ControllableMechs.*
import TerminalKit.*

public abstract class CMCKey {
  public static func W() -> Int32 = 0
  public static func A() -> Int32 = 1
  public static func S() -> Int32 = 2
  public static func D() -> Int32 = 3
  public static func Lmb() -> Int32 = 4
  public static func Rmb() -> Int32 = 5
  public static func Mmb() -> Int32 = 6
  public static func Up() -> Int32 = 7
  public static func Down() -> Int32 = 8
  public static func Count() -> Int32 = 9
  public static func Name(i: Int32) -> String {
    switch i {
      case 0: return "W";
      case 1: return "A";
      case 2: return "S";
      case 3: return "D";
    }
    return "?";
  }
}

public class CMCSession extends ScriptableSystem {

  private let m_state: Int32;
  private let m_gen: Int32;
  private let m_unit: ref<CMCUnit>;

  public let rig: ref<CMPilotRig>;
  public let aim: Vector4;
  public let aimDist: Float;
  public let aimEntity: wref<Entity>;

  public let aimWorld: Vector4;
  private let m_sigLost: ref<CMSignalLost>;
  public let zoom: Bool;

  private let m_keys: array<Bool>;
  private let m_sensX: Float;
  private let m_sensY: Float;
  private let m_axisSeen: Int32;
  private let m_rawSeen: array<Bool>;

  private let m_camID: EntityID;
  private let m_cam: ref<CameraComponent>;
  private let m_camEntity: wref<Entity>;
  private let m_camBase: Vector4;
  private let m_camBased: Bool;
  private let m_camLocal0: Vector4;
  private let m_attachPending: Bool;
  private let m_clip: Float;
  private let m_lastFov: Float;
  private let m_blur: ref<CMBlurPanes>;

  private let m_hud: ref<CMPilotHud>;
  private let m_hudState: ref<CMPilotHudState>;

  private let m_lastTime: Float;
  private let m_slow: Float;
  private let m_frames: Int32;
  private let m_watchFrames: Int32;
  private let m_timerLoop: Bool;

  private let m_restricted: Bool;
  private let m_hidV: Bool;
  private let m_saveLocked: Bool;
  private let m_vHealth: Float;
  private let m_lastExit: Float;

  private let m_fireMode: Int32;
  private let m_chase: Bool;
  private let m_creditVOff: Bool;
  private let m_hullX: Int32;
  private let m_synced: Bool;

  private let m_chaseUp: Float;
  private let m_dtSmooth: Float;
  private let m_thermal: Int32;
  private let m_clockReal: Float;
  private let m_clockUsed: Float;
  private let m_chaseDist: Float;
  private let m_chaseSide: Float;
  private let m_opticsHeld: Bool;

  private let LOOK_STIFFNESS: Float = 7.0;
  private let LOOK_DAMPING: Float = 5.0;
  private let LOOK_YAW_RATE: Float = 24.0;
  private let LOOK_PITCH_RATE: Float = 16.0;
  private let LOOK_LEAD: Float = 25.0;
  private let OPTICS_FOV: Float = 27.0;
  private let OPTICS_RATE: Float = 0.5;
  private let STOMP: Float = 1.8;

  public static func Get(game: GameInstance) -> ref<CMCSession> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"ControllableMechs.Control.CMCSession") as CMCSession;
  }

  public static func Log(text: String) -> Void {
    TKLog.Add("ControllableMechs", text);
    if CMPilotSystem.Get(GetGameInstance()).ShowDebug() {
      let line = "CM " + text;
      ModLog(n"ControllableMechs", line);
    }
  }

  private func OnAttach() -> Void {
    let cbs = GameInstance.GetCallbackSystem();
    cbs.RegisterCallback(n"Session/BeforeEnd", this, n"OnSessionEnd").SetLifetime(CallbackLifetime.Forever);
  }

  private let m_inputOn: Bool;

  private func ListenInput(on: Bool) -> Void {
    if Equals(on, this.m_inputOn) {
      return;
    }
    this.m_inputOn = on;
    let cbs = GameInstance.GetCallbackSystem();
    if on {
      cbs.RegisterCallback(n"Input/Key", this, n"OnKey");
      cbs.RegisterCallback(n"Input/Axis", this, n"OnAxis")
        .AddTarget(InputTarget.Axis(EInputKey.IK_MouseX))
        .AddTarget(InputTarget.Axis(EInputKey.IK_MouseY));
    } else {
      cbs.UnregisterCallback(n"Input/Key", this, n"OnKey");
      cbs.UnregisterCallback(n"Input/Axis", this, n"OnAxis");
    }
  }

  private func OnDetach() -> Void {
    this.End("", true);
  }

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    this.End("", true);
  }

  protected cb func OnSessionEnd(event: ref<GameSessionEvent>) -> Void {
    this.End("", true);
  }

  private func Sync() -> Void {
    if this.m_synced {
      return;
    }
    this.m_synced = true;
    let cfg = CMPilotSystem.Get(this.GetGameInstance());
    this.m_fireMode = Clamp(cfg.Int("fireMode", CMFireMode.Stagger()), 0, 2);
    this.m_chase = cfg.Flag("chaseView", false);
    this.m_creditVOff = !cfg.Flag("creditV", true);
    this.m_hullX = Clamp(cfg.Int("hullMult", 10), 1, 50) + 1;
  }

  public func IsActive() -> Bool = this.m_state != 0
  public func FireMode() -> Int32 {
    this.Sync();
    return this.m_fireMode;
  }
  public func SetFireMode(mode: Int32) -> Void {
    this.Sync();
    this.m_fireMode = Clamp(mode, 0, 2);
    CMPilotSystem.Get(this.GetGameInstance()).PutInt("fireMode", this.m_fireMode);
  }

  public func SetChaseView(on: Bool) -> Void {
    this.SetChase(on);
  }

  public func CanPilot() -> String {
    let link = CMLinkSystem.Get(this.GetGameInstance());
    let mech = link.Unit();
    if !link.IsLinked() || !IsDefined(mech) {
      return "!" + CMText.UnitNoUnitLinked();
    }
    if NotEquals(mech.GetNPCType(), gamedataNPCType.Mech) && NotEquals(mech.GetNPCType(), gamedataNPCType.Drone) {
      return "!" + CMText.SesNeedsMechOrDrone();
    }
    if !ScriptedPuppet.IsAlive(mech) {
      return "!" + CMText.SesIsDestroyed(CMLinkSystem.KindName(mech));
    }

    if CMFleet.Get(this.GetGameInstance()).Dropping() {
      return "!" + CMText.SesStillDropping();
    }
    return "";
  }

  private func NewUnit() -> ref<CMCUnit> {
    let unit = CMLinkSystem.Get(this.GetGameInstance()).Unit();
    if IsDefined(unit) && Equals(unit.GetNPCType(), gamedataNPCType.Drone) {
      return new CMUDrone();
    }
    return new CMUMinotaur();
  }

  public func HullMult() -> Float {
    this.Sync();
    return 10.0;
  }
  public func SetHullMult(x: Int32) -> Void {
    this.Sync();
    this.m_hullX = Clamp(x, 1, 50) + 1;
    CMPilotSystem.Get(this.GetGameInstance()).PutInt("hullMult", this.m_hullX - 1);
  }
  public func CreditV() -> Bool {
    this.Sync();
    return true;
  }
  public func SetCreditV(on: Bool) -> Void {
    this.Sync();
    this.m_creditVOff = !on;
    CMPilotSystem.Get(this.GetGameInstance()).PutFlag("creditV", on);
  }
  public func IsChase() -> Bool {
    this.Sync();
    return this.m_chase;
  }

  private let m_rawExitAt: Float;
  public func Toggle() -> Void {

    if this.m_state == 0 && EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGameInstance())) - this.m_rawExitAt < 0.5 {
      return;
    }
    if this.m_state != 0 {
      this.End(CMText.SesLinkClosed(), false);
      return;
    }

    if this.Now() - this.m_lastExit < 0.5 {
      return;
    }

    let link = CMLinkSystem.Get(this.GetGameInstance());
    let unit = link.Unit();
    let age = link.SpawnAge(unit);
    if IsDefined(unit) && Equals(unit.GetNPCType(), gamedataNPCType.Drone) && age >= 0.0 && age < 2.0 {
      let at = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGameInstance()));
      if at >= this.m_keyWaitUntil {
        this.m_keyWaitUntil = at + 2.0 - age;
        let cb = new CMCKeyBeginCb();
        cb.system = this;
        GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, 2.0 - age, false);
      }
      return;
    }
    this.Warn(this.Begin(this.NewUnit(), false));
  }

  private let m_keyWaitUntil: Float;
  public func KeyBeginFromCallback() -> Void {
    if this.m_state == 0 {
      this.Warn(this.Begin(this.NewUnit(), false));
    }
  }

  public func RequestBegin(delay: Float) -> Void {

    let link = CMLinkSystem.Get(this.GetGameInstance());
    let unit = link.Unit();

    let age = link.SpawnAge(unit);
    if IsDefined(unit) && Equals(unit.GetNPCType(), gamedataNPCType.Drone) && age >= 0.0 && age < 2.0 {
      let again = new CMCRequestCb();
      again.system = this;
      again.delay = delay;
      GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(again, 2.0 - age, false);
      return;
    }
    if IsDefined(unit) && Equals(unit.GetNPCType(), gamedataNPCType.Drone) {
      let fleet = CMFleet.Get(this.GetGameInstance());

      let handed = false;
      if fleet.Autopilot().Flying(unit.GetEntityID()) {

        fleet.Autopilot().HandOver();
        handed = true;
      }
      fleet.SetEscort(false);
      let v = Vector4.Length(unit.GetVelocity());
      if !handed && v > 1.0 {
        link.Hold();
        delay = MaxF(delay, 1.6);
      }
    }
    let cb = new CMCBeginCb();
    cb.system = this;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, delay, false);
  }

  public func BeginFromCallback() -> Void {
    if this.m_state == 0 {
      this.Warn(this.Begin(this.NewUnit(), true));
    }
  }

  public func Begin(unit: ref<CMCUnit>, fromTerminal: Bool) -> String {
    if this.m_state != 0 {
      return "";
    }
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return "!" + CMText.SesNoOperator();
    }
    let veh: wref<VehicleObject>;
    VehicleComponent.GetVehicle(game, player.GetEntityID(), veh);
    if IsDefined(veh) {
      return "!" + CMText.SesLeaveVehicle();
    }
    if !fromTerminal && !TKPopup.CanOpen(player) {
      return "!" + CMText.SesNotNow();
    }

    let fleet = CMFleet.Get(game);
    let linked = CMLinkSystem.Get(game).Unit();
    if IsDefined(linked) && IsDefined(fleet) && fleet.Autopilot().Flying(linked.GetEntityID()) {
      fleet.Autopilot().HandOver();
      fleet.SetEscort(false);
    }
    this.m_gen += 1;
    this.rig = new CMPilotRig();
    this.m_unit = unit;
    let why = unit.Begin(this);
    if StrLen(why) > 0 {
      this.m_unit = null;
      this.rig = null;
      return why;
    }

    this.LoadChase();
    this.rig.Init(unit.Ground(), this.CamUp(), this.CamFwd(), unit.Facing());
    this.Sync();
    this.rig.SetChase(this.m_chase);
    this.ApplyWeight();
    this.m_clip = 999.0;
    this.m_lastFov = 0.0;
    this.aim = this.rig.pos + this.rig.Forward() * 100.0;
    this.aimDist = 0.0;
    this.zoom = false;
    this.m_opticsHeld = false;
    ArrayClear(this.m_keys);
    ArrayResize(this.m_keys, CMCKey.Count());
    this.m_axisSeen = 0;
    ArrayClear(this.m_rawSeen);
    ArrayResize(this.m_rawSeen, CMCKey.Count());
    this.m_frames = 0;
    this.m_hudState = new CMPilotHudState();
    this.CacheSensitivity();

    this.Restrict(player, true);
    SaveLocksManager.RequestSaveLockAdd(game, n"ControllableMechs_Control");
    this.m_saveLocked = true;
    this.m_vHealth = this.PlayerHealth(player);

    let spec = new StaticEntitySpec();
    spec.templatePath = r"base\\entities\\cameras\\simple_free_camera.ent";

    if CMPilotSystem.Get(game).PlateBlur() > 0 {
      spec.templatePath = CMBlurPanes.Template();
    }
    spec.position = this.rig.pos;
    spec.orientation = CMCSession.Identity();
    spec.attached = true;
    this.m_camID = GameInstance.GetStaticEntitySystem().SpawnEntity(spec);
    this.m_state = 1;
    if !EntityID.IsDefined(this.m_camID) {
      this.End("!" + CMText.SesCameraFailed(), false);
      return "";
    }
    this.m_attachPending = true;
    GameInstance.GetCallbackSystem().RegisterCallback(n"Entity/Attached", this, n"OnCamAttached");
    this.ListenInput(true);
    let timeout = new CMCTimeoutCb();
    timeout.system = this;
    timeout.generation = this.m_gen;
    GameInstance.GetDelaySystem(game).DelayCallback(timeout, 3.0, false);
    return "";
  }

  protected cb func OnCamAttached(event: ref<EntityLifecycleEvent>) -> Void {
    if !this.m_attachPending {
      return;
    }
    let entity = event.GetEntity();
    if !IsDefined(entity) || entity.GetEntityID() != this.m_camID {
      return;
    }
    this.m_attachPending = false;
    GameInstance.GetCallbackSystem().UnregisterCallback(n"Entity/Attached", this, n"OnCamAttached");
    if this.m_state != 1 {
      return;
    }
    let cam = entity.FindComponentByName(n"camera") as CameraComponent;
    if !IsDefined(cam) {
      for c in entity.GetComponents() {
        if !IsDefined(cam) {
          cam = c as CameraComponent;
        }
      }
    }
    if !IsDefined(cam) {
      this.End("!" + CMText.SesCameraFailed(), false);
      return;
    }
    this.m_camEntity = entity;
    this.m_cam = cam;

    this.m_camLocal0 = cam.GetLocalPosition();
    this.m_camLocal0.W = 0.0;
    this.m_camBase = entity.GetWorldPosition();
    this.m_camBased = true;
    this.ApplyCamera();
    cam.Activate(0.35, true);
    this.m_hud = this.m_unit.NewHud();
    this.m_hud.Build();
    this.m_blur = null;
    let blur = CMPilotSystem.Get(this.GetGameInstance()).PlateBlur();
    let rects = this.m_hud.BlurRects();
    if blur > 0 && ArraySize(rects) > 0 {
      this.m_blur = new CMBlurPanes();
      this.m_blur.Setup(entity, rects, this.rig.fov, blur);
      this.ApplyCamera();
    }
    this.m_hud.StartBoot();
    this.m_state = 2;
    let player = GetPlayer(this.GetGameInstance());
    if IsDefined(player) {
      player.m_cmcSession = this;
    }
    this.m_lastTime = this.Now();
    this.m_dtSmooth = 0.016;
    this.m_thermal = 0;
    this.m_clockReal = 0.0;
    this.m_clockUsed = 0.0;
    this.m_slow = 1.0;
    this.m_timerLoop = false;
    this.m_watchFrames = 0;
    this.ScheduleFrame();
    this.ScheduleWatchdog();
  }

  public func OnTimeout(generation: Int32) -> Void {
    if generation == this.m_gen && this.m_state == 1 {
      this.End("!" + CMText.SesCameraTimedOut(), false);
    }
  }

  public func End(reason: String, hard: Bool) -> Void {
    if this.m_state == 0 {
      return;
    }
    let game = this.GetGameInstance();
    CMWatch.Mark("idle: link closed (" + reason + ")");
    this.m_gen += 1;
    this.m_state = 0;
    if this.m_thermal != 0 {
      CMThermal.Set(game, 0);
      this.m_thermal = 0;
    }
    this.m_lastExit = this.Now();
    let player = GetPlayer(game);
    if IsDefined(player) {
      player.m_cmcSession = null;
    }
    this.ListenInput(false);
    if this.m_attachPending {
      this.m_attachPending = false;
      GameInstance.GetCallbackSystem().UnregisterCallback(n"Entity/Attached", this, n"OnCamAttached");
    }
    if IsDefined(this.m_unit) {
      this.m_unit.End(this, hard);
    }
    this.m_unit = null;

    let blend = hard ? 0.0 : 0.3;
    if IsDefined(this.m_cam) {
      this.m_cam.Deactivate(blend, true);
    }
    if IsDefined(player) {
      let fpp = player.GetFPPCameraComponent();
      if IsDefined(fpp) {
        fpp.Activate(blend, true);
        fpp.ResetPitch();
      }
    }
    this.m_cam = null;
    this.m_camEntity = null;
    this.m_camBased = false;
    if EntityID.IsDefined(this.m_camID) {
      if hard {
        GameInstance.GetStaticEntitySystem().DespawnEntity(this.m_camID);
      } else {
        let cb = new CMCDespawnCb();
        cb.id = this.m_camID;
        GameInstance.GetDelaySystem(game).DelayCallback(cb, blend + 0.15, false);
      }
    }
    let empty: EntityID;
    this.m_camID = empty;

    if IsDefined(this.m_hud) {
      this.m_hud.Remove();
    }
    this.m_hud = null;
    if IsDefined(this.m_sigLost) {
      this.m_sigLost.Remove();
    }
    this.m_sigLost = null;
    if IsDefined(player) && this.m_restricted {
      this.Restrict(player, false);
    }
    this.m_restricted = false;
    if this.m_saveLocked {
      SaveLocksManager.RequestSaveLockRemove(game, n"ControllableMechs_Control");
      this.m_saveLocked = false;
    }
    this.rig = null;
    ArrayClear(this.m_keys);
    this.Warn(reason);
  }

  private func ScheduleFrame() -> Void {
    let game = this.GetGameInstance();
    if this.m_timerLoop {
      let cb = new CMCFrameCb();
      cb.system = this;
      cb.generation = this.m_gen;
      GameInstance.GetDelaySystem(game).DelayCallback(cb, 0.016, false);
      return;
    }
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let evt = new CMCTickEvent();
    evt.generation = this.m_gen;
    GameInstance.GetDelaySystem(game).DelayEventNextFrame(player, evt);
  }

  private func ScheduleWatchdog() -> Void {
    let cb = new CMCWatchCb();
    cb.system = this;
    cb.generation = this.m_gen;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, 0.5, false);
  }

  public func OnWatchdog(generation: Int32) -> Void {
    if generation != this.m_gen || this.m_state != 2 {
      return;
    }
    if this.m_frames == this.m_watchFrames && !this.m_timerLoop {
      this.m_timerLoop = true;
      this.ScheduleFrame();
    }
    this.m_watchFrames = this.m_frames;
    this.ScheduleWatchdog();
  }

  public func OnFrame(generation: Int32) -> Void {
    if generation != this.m_gen || this.m_state != 2 {
      return;
    }
    this.m_frames += 1;
    let now = this.Now();
    let raw = ClampF(now - this.m_lastTime, 0.0, 0.1);
    this.m_lastTime = now;
    if raw <= 0.0 {
      raw = 0.016;
    }

    this.m_dtSmooth += (raw - this.m_dtSmooth) * 0.15;
    this.m_clockReal += raw;
    let dt = ClampF(this.m_dtSmooth + (this.m_clockReal - this.m_clockUsed) * 0.1, 0.002, 0.1);
    this.m_clockUsed += dt;
    if !this.m_unit.IsAlive() {

      if this.m_unit.SignalLost() {
        if !IsDefined(this.m_sigLost) {
          if IsDefined(this.m_hud) {
            this.m_hud.Remove();
          }
          this.m_hud = null;
          this.m_sigLost = CMSignalLost.Show(this.m_unit.Name(), this.m_unit.CamProfile());
          let pl = GetPlayer(this.GetGameInstance());
          if IsDefined(pl) {
            GameObject.PlaySoundEvent(pl, n"ui_hacking_access_denied");
          }
        }

        let op = GetPlayer(this.GetGameInstance());
        if !IsDefined(op) || op.IsDead() {
          this.End("!" + CMText.SesOperatorDown(), false);
          return;
        }
        this.m_sigLost.Tick(dt);
        this.ScheduleFrame();
        return;
      }
      this.End(this.m_unit.LostReason(), false);
      return;
    }
    let optics = this.m_fireMode == CMFireMode.Split() ? this.Key(CMCKey.Mmb()) : this.Key(CMCKey.Rmb());
    if NotEquals(optics, this.m_opticsHeld) {
      this.m_opticsHeld = optics;
      this.SetOptics(optics);
    }

    let first = this.m_unit.TickFirst();
    if first {
      this.m_unit.Tick(this, dt, now);
      if this.m_state != 2 || !IsDefined(this.m_unit) {
        return;
      }
    }
    CMWatch.Mark("session: camera");
    this.rig.Update(dt, this.m_unit.Ground(), this.CamUp(), this.CamFwd(), this.zoom);
    if this.ChaseNow() {

      this.rig.pos += CMPilotRig.Dir(this.rig.yaw - 90.0, 0.0) * this.m_chaseSide;
    }
    this.ClipCamera(dt);
    this.ApplyCamera();
    if IsDefined(this.m_hud) {
      this.m_hud.SetAttitude(CMPilotRig.Wrap(-this.rig.yaw), this.rig.pitch);
      this.m_hud.Boot(dt);
      this.m_hud.Tags(dt);
    }
    CMWatch.Mark("session: aim");
    this.UpdateAim();
    if !first {
      this.m_unit.Tick(this, dt, now);
    }

    this.m_slow += dt;
    if this.m_slow >= 0.1 {
      this.m_slow = 0.0;
      CMWatch.Mark("session: slow tick (hud refresh)");
      if !this.SlowTick(now) {
        return;
      }
      CMWatch.Mark("session: frame done");
    }
    this.ScheduleFrame();
  }

  private func LoadChase() -> Void {
    if !IsDefined(this.m_unit) {
      return;
    }
    let cfg = CMPilotSystem.Get(this.GetGameInstance());
    let prof = this.m_unit.CamProfile();
    this.m_chaseUp = Cast<Float>(cfg.ChaseUpCm(prof)) / 100.0;
    this.m_chaseDist = Cast<Float>(cfg.ChaseDistCm(prof)) / 100.0;
    this.m_chaseSide = Equals(prof, "mech") ? cfg.ChaseSide() : Cast<Float>(cfg.ChaseSideCm(prof)) / 100.0 * (cfg.ShoulderLeft(prof) ? -1.0 : 1.0);
  }

  private func SlowTick(now: Float) -> Bool {
    this.LoadChase();
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    if !IsDefined(player) {
      this.End("", false);
      return false;
    }
    if player.IsDead() {
      this.End("!" + CMText.SesOperatorDown(), false);
      return false;
    }
    let hp = this.PlayerHealth(player);
    if hp < this.m_vHealth - 0.01 && !CMPilotSystem.Get(game).StayWhenHit() {
      this.End("!" + CMText.SesOperatorAttacked(), false);
      return false;
    }
    this.m_vHealth = hp;
    let why = this.m_unit.SlowTick(this, now);
    if StrLen(why) > 0 {
      this.End(why, false);
      return false;
    }
    this.RefreshHud();
    return true;
  }

  private func RefreshHud() -> Void {
    if !IsDefined(this.m_hud) {
      return;
    }
    let s = this.m_hudState;
    s.title = this.m_unit.Name();
    let h = RoundF(CMPilotRig.Wrap(-this.rig.yaw));
    s.heading = h < 0 ? h + 360 : h;
    s.range = this.aimDist;
    s.zoomed = this.zoom;
    s.speed = this.rig.speed;
    s.fireMode = this.m_fireMode;
    s.warning = "";
    s.sensor = CMThermal.Name(this.m_thermal);
    this.m_unit.Hud(this, s);
    this.m_hud.Refresh(s);
  }

  public func OpticsLost() -> Void {
    if this.zoom {
      this.SetOptics(false);
    }
  }

  public func UnitHit(hit: ref<gameHitEvent>) -> Void {
    if this.m_state == 2 && IsDefined(this.m_unit) {
      this.m_unit.TakeHit(this, hit);
    }
  }

  public func PartsRestored() -> Void {
    if this.m_state == 2 && IsDefined(this.m_unit) {
      this.m_unit.TakeHit(this, null);
    }
  }

  public func HitFrom(from: Vector4) -> Void {
    if this.m_state != 2 || !IsDefined(this.m_hud) || !IsDefined(this.rig) || !IsDefined(this.m_unit) {
      return;
    }
    this.m_hud.HitFrom(CMPilotRig.Wrap(CMPilotRig.YawOf(from - this.m_unit.Ground()) - this.rig.yaw));
  }

  public func Hud() -> ref<CMPilotHud> = this.m_hud

  public func FlashTag(tag: Int32) -> Void {
    if IsDefined(this.m_hud) {
      this.m_hud.TagFlash(tag);
    }
  }

  public func RoundHit(kill: Bool) -> Void {
    if this.m_state != 2 {
      return;
    }
    if IsDefined(this.m_hud) {
      this.m_hud.Hit(kill);
    }
    if kill && IsDefined(this.rig) {
      this.rig.Recoil(0.3);
    }
  }

  private func CamUp() -> Float = this.ChaseNow() ? this.m_chaseUp : this.m_unit.SensorUp()
  private func CamFwd() -> Float = this.ChaseNow() ? -this.m_chaseDist : this.m_unit.SensorFwd()

  private func ChaseNow() -> Bool = this.m_chase && !this.zoom

  public func SightView() -> Bool = !this.ChaseNow()

  private func SetOptics(on: Bool) -> Void {
    if on && IsDefined(this.m_unit) && !this.m_unit.OpticsOnline() {
      GameObject.PlaySoundEvent(GetPlayer(this.GetGameInstance()), n"ui_hacking_press_fail");
      return;
    }
    this.zoom = on;
    this.m_clip = 999.0;
    this.rig.SetChase(this.ChaseNow());
    this.ApplyWeight();
    if IsDefined(this.m_hud) {
      this.m_hud.SetOptics(on);
      if on {
        this.m_hud.TagFlash(CMPilotHud.TagZoom());
      }
    }
  }

  private func SetChase(on: Bool) -> Void {
    this.Sync();
    this.m_chase = on;
    CMPilotSystem.Get(this.GetGameInstance()).PutFlag("chaseView", on);
    this.m_clip = 999.0;
    if IsDefined(this.rig) {
      this.rig.SetChase(this.ChaseNow());
      this.ApplyWeight();
    }
  }

  private func ApplyWeight() -> Void {
    let k = this.zoom ? this.OPTICS_RATE : 1.0;

    let t = Cast<Float>(CMPilotSystem.Get(this.GetGameInstance()).TurnPct()) / 100.0;
    if IsDefined(this.m_unit) && this.m_unit.LightLook() {

      this.rig.SetWeight(900.0, 60.0, 720.0 * k, 720.0 * k, 0.0);
    } else {
      this.rig.SetWeight(this.LOOK_STIFFNESS * t, this.LOOK_DAMPING * SqrtF(t), this.LOOK_YAW_RATE * k * t, this.LOOK_PITCH_RATE * k * t, this.LOOK_LEAD * k);
    }
    this.rig.SetZoomFov(this.OPTICS_FOV);
    this.rig.SetStepWeight(this.STOMP * (IsDefined(this.m_unit) ? this.m_unit.StepWeight() : 1.0));
    this.rig.SetStride(!IsDefined(this.m_unit) || this.m_unit.StepWeight() > 0.0);
    this.rig.SetRecoilScale(Cast<Float>(CMPilotSystem.Get(this.GetGameInstance()).RecoilPct()) / 100.0);
  }

  private func ApplyCamera() -> Void {
    if !IsDefined(this.m_camEntity) || !IsDefined(this.m_cam) {
      return;
    }

    let off = this.rig.pos - this.m_camBase;
    if !this.m_camBased || Vector4.Length(off) > 2000.0 {
      let world: WorldPosition;
      WorldPosition.SetVector4(world, this.rig.pos);
      let wt: WorldTransform;
      WorldTransform.SetWorldPosition(wt, world);
      WorldTransform.SetOrientation(wt, CMCSession.Identity());
      this.m_camEntity.SetWorldTransform(wt);
      this.m_camBase = this.rig.pos;
      this.m_camBased = true;
      off = new Vector4(0.0, 0.0, 0.0, 0.0);
    }
    off.W = 0.0;
    this.m_cam.SetLocalPosition(this.m_camLocal0 + off);
    let e: EulerAngles;
    e.Yaw = this.rig.yaw + this.rig.kickYaw + this.rig.shakeYaw;
    e.Pitch = this.rig.pitch + this.rig.kickPitch + this.rig.shakePitch;
    e.Roll = this.rig.roll + this.rig.shakeRoll;

    if IsDefined(this.m_unit) {
      let tilt = this.m_unit.CamTilt();
      let k = this.ChaseNow() ? 0.35 : 1.0;
      e.Pitch += tilt.X * k;
      e.Roll += tilt.Y * k;
    }
    let camRot = EulerAngles.ToQuat(e);
    this.m_cam.SetLocalOrientation(camRot);
    if AbsF(this.rig.fov - this.m_lastFov) > 0.05 {
      this.m_lastFov = this.rig.fov;
      this.m_cam.SetFOV(this.rig.fov);
      if IsDefined(this.m_blur) {
        this.m_blur.Fov(this.rig.fov);
      }
    }
    if IsDefined(this.m_blur) {
      this.m_blur.Follow(this.m_camLocal0 + off, camRot);
    }
  }

  private func ClipCamera(dt: Float) -> Void {
    let g = this.m_unit.Ground();
    let pivot = new Vector4(g.X, g.Y, g.Z + this.CamUp(), 1.0);
    let want = this.rig.pos;
    let off = want - pivot;
    let full = Vector4.Length(off);
    if full < 0.3 {
      return;
    }
    let dir = off * (1.0 / full);
    let allowed = full;
    let hit: TraceResult;
    if GameInstance.GetSpatialQueriesSystem(this.GetGameInstance()).SyncRaycastByCollisionGroup(pivot, want + dir * 0.35, n"Static", hit, true, false) {
      allowed = MaxF(0.2, Vector4.Distance(pivot, Cast<Vector4>(hit.position)) - 0.35);
    }
    if allowed < this.m_clip {
      this.m_clip = allowed;
    } else {
      this.m_clip = MinF(allowed, this.m_clip + 6.0 * dt);
    }
    if this.m_clip < full {
      this.rig.pos = pivot + dir * this.m_clip;
    }
  }

  private func UpdateAim() -> Void {
    let fwd = this.rig.Forward();
    let to = this.rig.pos + fwd * 600.0;
    let skip = MaxF(this.m_unit.AimSkip(), Vector4.Dot(this.m_unit.Ground() - this.rig.pos, fwd) + 3.0);
    let sq = GameInstance.GetSpatialQueriesSystem(this.GetGameInstance());
    let best = 0.0;
    this.aimEntity = null;
    let hit: TraceResult;
    this.aimWorld = to;
    if CMGround.World(this.GetGameInstance(), this.rig.pos + fwd * 0.3, to, hit) {
      this.aim = Cast<Vector4>(hit.position);
      best = Vector4.Distance(this.rig.pos, this.aim);
      this.aimWorld = this.aim;
    }
    let dyn: TraceResult;
    if CMGround.Movers(this.GetGameInstance(), this.rig.pos + fwd * skip, to, dyn) {
      let p = Cast<Vector4>(dyn.position);
      let d = Vector4.Distance(this.rig.pos, p);
      if best <= 0.0 || d < best {
        this.aim = p;
        best = d;
        this.aimEntity = TraceResult.GetHitEntity(dyn);
      }
    }
    if best <= 0.0 {
      this.aim = to;
    }
    this.aimDist = best;
  }

  public func PipOffset(p: Vector4) -> Vector2 {
    let scale = 1080.0 / TanF(Deg2Rad(this.rig.fov * 0.5));
    let d = p - this.rig.pos;
    let flat = SqrtF(d.X * d.X + d.Y * d.Y);
    let yawOff = CMPilotRig.Wrap(CMPilotRig.YawOf(d) - this.rig.yaw);
    let pitchOff = Rad2Deg(AtanF(d.Z, flat)) - this.rig.pitch;
    if AbsF(yawOff) > 80.0 {
      return Vector2(9999.0, 9999.0);
    }
    return Vector2(-TanF(Deg2Rad(yawOff)) * scale, -TanF(Deg2Rad(pitchOff)) * scale);
  }

  public func Key(i: Int32) -> Bool {
    return i >= 0 && i < ArraySize(this.m_keys) && this.m_keys[i];
  }

  private func RawKey(i: Int32, down: Bool) -> Void {
    if i >= 0 && i < ArraySize(this.m_rawSeen) {
      this.m_rawSeen[i] = true;
    }
    this.SetKey(i, down);
  }

  private func ActionKey(i: Int32, down: Bool, from: String) -> Void {
    if i >= 0 && i < ArraySize(this.m_rawSeen) && this.m_rawSeen[i] {
      return;
    }
    this.SetKey(i, down, from);
  }

  private func SetKey(i: Int32, down: Bool, opt from: String) -> Void {
    if i >= 0 && i < ArraySize(this.m_keys) {
      if NotEquals(this.m_keys[i], down) && i <= CMCKey.D() {
      }
      this.m_keys[i] = down;
    }
  }

  public func OnGameAction(name: CName, type: gameinputActionType, value: Float) -> Bool {
    if this.m_state != 2 {
      return false;
    }

    let down = !Equals(type, gameinputActionType.BUTTON_RELEASED) && AbsF(value) > 0.1;

    switch name {
      case n"Forward": this.ActionKey(CMCKey.W(), down, "Forward"); break;
      case n"Back": this.ActionKey(CMCKey.S(), down, "Back"); break;
      case n"Left": this.ActionKey(CMCKey.A(), down, "Left"); break;
      case n"Right": this.ActionKey(CMCKey.D(), down, "Right"); break;
      case n"RangedAttack":
      case n"ShootPrimary":
        this.ActionKey(CMCKey.Lmb(), down, "attack");
        break;
      case n"CameraAim":
        this.ActionKey(CMCKey.Rmb(), down, "aim");
        break;
      case n"CameraMouseX":
        if this.m_axisSeen == 0 && IsDefined(this.rig) {
          this.rig.Look(-value / 45.0 * (this.zoom ? 0.5 : 1.0), 0.0);
        }
        break;
      case n"CameraMouseY":
        if this.m_axisSeen == 0 && IsDefined(this.rig) {
          this.rig.Look(0.0, value / 45.0 * (this.zoom ? 0.5 : 1.0));
        }
        break;

      case n"ToggleSprint":
      case n"Sprint":
      case n"Jump":
      case n"ToggleCrouch":
      case n"Crouch":
      case n"Dodge":
      case n"DodgeForward":
      case n"DodgeBackward":
      case n"DodgeLeft":
      case n"DodgeRight":
      case n"Reload":
      case n"SwitchItem":
      case n"SelectWeapon":
      case n"NextWeapon":
      case n"PreviousWeapon":
      case n"QuickMelee":
      case n"UseConsumable":
      case n"UseCombatGadget":
      case n"MeleeAttack":
      case n"Choice1":
        break;
      default:
        return false;
    }
    return true;
  }

  private let m_cmDefAt: Float;
  private let m_cmSensorAt: Float;
  private let m_cmModeAt: Float;
  private let HOLD_KEY: Float = 0.35;

  protected cb func OnKey(event: ref<KeyInputEvent>) -> Void {
    if this.m_state != 2 {
      return;
    }
    let action = event.GetAction();
    if Equals(action, EInputAction.IACT_Axis) {
      return;
    }
    let down = !Equals(action, EInputAction.IACT_Release);

    if IsDefined(this.m_sigLost) && !Equals(event.GetKey(), EInputKey.IK_Backslash) && !Equals(event.GetKey(), CMKeys.Pilot(GetPlayer(this.GetGameInstance()))) {
      return;
    }
    let press = Equals(action, EInputAction.IACT_Press);

    if Equals(event.GetKey(), CMKeys.Gunship(GetPlayer(this.GetGameInstance()))) {
      if press && IsDefined(this.m_unit) {
        this.m_unit.Hold(this);
        this.m_slow = 1.0;
      }
      return;
    }

    let pk40 = GetPlayer(this.GetGameInstance());
    let extras = IsDefined(this.m_unit) && this.m_unit.HasExtras();
    if extras && Equals(event.GetKey(), CMKeys.Defence(pk40)) {
      if press {
        this.m_cmDefAt = this.Now();
      } else {
        if Equals(action, EInputAction.IACT_Release) {
          if this.Now() - this.m_cmDefAt >= this.HOLD_KEY {
            this.m_unit.ShieldKey(this);
          } else {
            if this.m_unit.HasCounter() {
              this.m_unit.Counter(this);
              this.FlashTag(CMPilotHud.TagMissile());
            }
          }
        }
      }
      return;
    }
    if extras && Equals(event.GetKey(), CMKeys.Jump(pk40)) {
      if press && this.m_unit.Jump(this) {
        return;
      }
    }

    if Equals(event.GetKey(), CMKeys.Declutter(GetPlayer(this.GetGameInstance()))) {
      if press {
        let cfg = CMPilotSystem.Get(this.GetGameInstance());
        let on = !cfg.Flag("blastRing", true);
        cfg.PutFlag("blastRing", on);
      }
      return;
    }

    let key = event.GetKey();
    let p = GetPlayer(this.GetGameInstance());
    if Equals(key, CMKeys.Sensor(p)) {

      if extras {
        if press {
          this.m_cmSensorAt = this.Now();
          return;
        }
        if !Equals(action, EInputAction.IACT_Release) {
          return;
        }
        if this.Now() - this.m_cmSensorAt >= this.HOLD_KEY {
          this.m_unit.Lights(this);
          return;
        }
      }

      if press || (extras && Equals(action, EInputAction.IACT_Release)) {
        this.m_thermal = (this.m_thermal + 1) % CMThermal.Count();
        if !CMThermal.Set(this.GetGameInstance(), this.m_thermal) {
          this.m_thermal = 0;
        }
      }
      return;
    }
    if Equals(key, CMKeys.View(p)) {
      if press {
        this.SetChase(!this.m_chase);
        this.m_slow = 1.0;
        this.FlashTag(CMPilotHud.TagView());
      }
      return;
    }
    if Equals(key, CMKeys.Secondary(p)) {

      if press && IsDefined(this.m_unit) {
        this.m_unit.Secondary(this);
        this.m_slow = 1.0;
        this.FlashTag(CMPilotHud.TagMissile());
      }
      return;
    }
    if Equals(key, CMKeys.FireMode(p)) {

      if extras {
        if press {
          this.m_cmModeAt = this.Now();
          return;
        }
        if !Equals(action, EInputAction.IACT_Release) {
          return;
        }
        if this.Now() - this.m_cmModeAt >= this.HOLD_KEY {
          this.m_unit.Secondary(this);
          this.m_slow = 1.0;
          this.FlashTag(CMPilotHud.TagMode());
          return;
        }
      }
      if press || (extras && Equals(action, EInputAction.IACT_Release)) {
        if !IsDefined(this.m_unit) || !this.m_unit.Select(this) {
          this.SetFireMode(CMFireMode.Next(this.m_fireMode));
        }
        this.m_slow = 1.0;
        this.FlashTag(CMPilotHud.TagMode());
      }
      return;
    }
    if Equals(key, CMKeys.Track(p)) {

      if press && IsDefined(this.m_unit) {
        this.m_unit.Track(this);
      }
      return;
    }
    if Equals(key, CMKeys.SplitOptics(p)) {
      this.RawKey(CMCKey.Mmb(), down);
      return;
    }

    if Equals(key, CMKeys.Pilot(p)) && NotEquals(key, EInputKey.IK_Backslash) {
      if press {
        this.m_rawExitAt = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGameInstance()));
        this.End(CMText.SesLinkClosed(), false);
      }
      return;
    }

    if Equals(key, CMKeys.Forward(p)) { this.RawKey(CMCKey.W(), down); return; }
    if Equals(key, CMKeys.Left(p)) { this.RawKey(CMCKey.A(), down); return; }
    if Equals(key, CMKeys.Back(p)) { this.RawKey(CMCKey.S(), down); return; }
    if Equals(key, CMKeys.Right(p)) { this.RawKey(CMCKey.D(), down); return; }
    if Equals(key, CMKeys.Fire(p)) { this.RawKey(CMCKey.Lmb(), down); return; }
    if Equals(key, CMKeys.Aim(p)) { this.RawKey(CMCKey.Rmb(), down); return; }
    if Equals(key, CMKeys.Climb(p)) { this.RawKey(CMCKey.Up(), down); return; }
    if Equals(key, CMKeys.Descend(p)) { this.RawKey(CMCKey.Down(), down); return; }
    if Equals(key, EInputKey.IK_Backslash) {

      if press {
        this.m_rawExitAt = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGameInstance()));
        this.End(CMText.SesLinkClosed(), false);
      }
    }
  }

  protected cb func OnAxis(event: ref<AxisInputEvent>) -> Void {
    if this.m_state != 2 || !IsDefined(this.rig) {
      return;
    }
    this.m_axisSeen += 1;
    let v = event.GetValue();
    let k = this.zoom ? 0.5 : 1.0;
    if Equals(event.GetKey(), EInputKey.IK_MouseX) {
      this.rig.Look(-v * this.m_sensX * k, 0.0);
    } else {
      this.rig.Look(0.0, -v * this.m_sensY * k);
    }
  }

  private func CacheSensitivity() -> Void {
    this.m_sensX = 0.15;
    this.m_sensY = 0.15;
    let settings = GameInstance.GetSettingsSystem(this.GetGameInstance());
    let x = settings.GetVar(n"/controls/fppcameramouse", n"FPP_MouseX") as ConfigVarFloat;
    let y = settings.GetVar(n"/controls/fppcameramouse", n"FPP_MouseY") as ConfigVarFloat;
    if IsDefined(x) && x.GetValue() > 0.0 {
      this.m_sensX = x.GetValue() / 100.0;
    }
    if IsDefined(y) && y.GetValue() > 0.0 {
      this.m_sensY = y.GetValue() / 100.0;
    }
    let k = Cast<Float>(CMPilotSystem.Get(this.GetGameInstance()).SensPct()) / 100.0;
    this.m_sensX *= k;
    this.m_sensY *= k;
  }

  private func Restrict(player: ref<PlayerPuppet>, on: Bool) -> Void {
    let ss = GameInstance.GetStatusEffectSystem(this.GetGameInstance());
    let pid = player.GetEntityID();
    let rid = player.GetRecordID();
    let list: array<TweakDBID> = [
      t"GameplayRestriction.NoMovement",
      t"GameplayRestriction.NoCombat",
      t"GameplayRestriction.NoZooming",
      t"GameplayRestriction.NoPhone",
      t"GameplayRestriction.NoWorldInteractions",
      t"GameplayRestriction.NoJump",
      t"GameplayRestriction.NoRadialMenus",
      t"GameplayRestriction.NoCameraControl",
      t"GameplayRestriction.NoCyberware",
      t"GameplayRestriction.NoPhotoMode",
      t"GameplayRestriction.VehicleNoSummoning"
    ];

    if !IsDefined(this.m_unit as CMUDrone) {
      ArrayPush(list, t"GameplayRestriction.NoQuickHacks");
      ArrayPush(list, t"GameplayRestriction.NoScanning");
    } else {
      ss.RemoveStatusEffect(pid, t"GameplayRestriction.NoQuickHacks");
      ss.RemoveStatusEffect(pid, t"GameplayRestriction.NoScanning");
    }

    let psm = GameInstance.GetBlackboardSystem(this.GetGameInstance()).GetLocalInstanced(pid, GetAllBlackboardDefs().PlayerStateMachine);
    if IsDefined(psm) {
      psm.SetBool(GetAllBlackboardDefs().PlayerStateMachine.IsControllingDevice, on);
      psm.FireCallbacks();
    }

    let vm = GameInstance.GetVisionModeSystem(this.GetGameInstance());
    if on {
      player.QueueEvent(new ActivateTPPRepresentationEvent());
      GameObjectEffectHelper.StartEffectEvent(player, n"camera_mask");
      let ap: VisionAppearance;
      ap.fill = 2;
      ap.outline = 3;
      ap.showThroughWalls = true;
      vm.ForceVisionAppearance(player, ap, 0.3);
    } else {
      player.QueueEvent(new DeactivateTPPRepresentationEvent());
      GameObjectEffectHelper.StopEffectEvent(player, n"camera_mask");
      vm.CancelForceVisionAppearance(player, 0.3);
    }
    for id in list {
      if on {
        ss.ApplyStatusEffect(pid, id, rid, pid);
      } else {
        ss.RemoveStatusEffect(pid, id);
      }
    }
    this.m_restricted = on;

    if on {
      if CMPilotSystem.Get(this.GetGameInstance()).HideOperator() && !player.IsInvisible() {
        player.SetInvisible(true);
        this.m_hidV = true;
      }
    } else {
      if this.m_hidV {
        player.SetInvisible(false);
        this.m_hidV = false;
      }
    }
  }

  private func PlayerHealth(player: ref<PlayerPuppet>) -> Float {
    return GameInstance.GetStatPoolsSystem(this.GetGameInstance()).GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, false);
  }

  public func Now() -> Float = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGameInstance()))

  public static func Identity() -> Quaternion {
    let e: EulerAngles;
    return EulerAngles.ToQuat(e);
  }

  public static func AimError(weapon: ref<GameObject>, at: Vector4) -> Float {
    if !IsDefined(weapon) {
      return -1.0;
    }
    let to = Vector4.Normalize(at - weapon.GetWorldPosition());
    let fwd = Vector4.Normalize(weapon.GetWorldForward());
    return Rad2Deg(AcosF(ClampF(Vector4.Dot(to, fwd), -1.0, 1.0)));
  }

  private func Warn(msg: String) -> Void {
    let player = GetPlayer(this.GetGameInstance());
    if IsDefined(player) && StrLen(msg) > 0 {
      player.SetWarningMessage(CMLinkSystem.Plain(msg));
    }
  }
}

public class CMCTickEvent extends Event {
  public let generation: Int32;
}

@addField(PlayerPuppet)
public let m_cmcSession: wref<CMCSession>;

@addMethod(PlayerPuppet)
protected cb func OnCMCTick(evt: ref<CMCTickEvent>) -> Bool {
  if IsDefined(this.m_cmcSession) {
    this.m_cmcSession.OnFrame(evt.generation);
  }
  return true;
}

public class CMCFrameCb extends DelayCallback {
  public let system: wref<CMCSession>;
  public let generation: Int32;
  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.OnFrame(this.generation);
    }
  }
}

public class CMCWatchCb extends DelayCallback {
  public let system: wref<CMCSession>;
  public let generation: Int32;
  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.OnWatchdog(this.generation);
    }
  }
}

public class CMCTimeoutCb extends DelayCallback {
  public let system: wref<CMCSession>;
  public let generation: Int32;
  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.OnTimeout(this.generation);
    }
  }
}

public class CMCBeginCb extends DelayCallback {
  public let system: wref<CMCSession>;
  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.BeginFromCallback();
    }
  }
}

public class CMCDespawnCb extends DelayCallback {
  public let id: EntityID;
  public func Call() -> Void {
    GameInstance.GetStaticEntitySystem().DespawnEntity(this.id);
  }
}

public class CMCRequestCb extends DelayCallback {
  public let system: wref<CMCSession>;
  public let delay: Float;
  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.RequestBegin(this.delay);
    }
  }
}

public class CMCKeyBeginCb extends DelayCallback {
  public let system: wref<CMCSession>;
  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.KeyBeginFromCallback();
    }
  }
}
