module ControllableMechs

import ControllableMechs.Control.*

public class CMBehemothTick extends DelayCallback {
  public let sys: wref<CMBehemoth>;
  public let gen: Int32;
  public let step: Int32;

  public func Call() -> Void {
    if IsDefined(this.sys) {
      this.sys.Fire(this.gen, this.step);
    }
  }
}

public class CMBehemoth extends ScriptableSystem {
  private persistent let m_truckPending: Bool;
  private let m_gen: Int32;
  private let m_watching: Bool;
  private let m_shown: Bool;
  private let m_keys: Bool;
  private let m_unloading: Bool;
  private let m_fade: wref<inkRectangle>;

  public static func Record() -> TweakDBID = t"Vehicle.cm_mnc_behemoth"
  public static func Get(game: GameInstance) -> ref<CMBehemoth> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"ControllableMechs.CMBehemoth") as CMBehemoth;
  }

  public func Pending() -> Bool = this.m_truckPending
  public func Unloading() -> Bool = this.m_unloading

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    this.m_gen += 1;
    this.m_watching = false;
    this.m_shown = false;
    this.m_unloading = false;
    if this.m_truckPending {
      this.Watch();
    }
  }

  public func Grant() -> String {
    if this.m_truckPending {
      return "!" + CMText.BehAlreadyInVehicles();
    }
    let vs = GameInstance.GetVehicleSystem(this.GetGameInstance());
    if !IsDefined(TweakDBInterface.GetVehicleRecord(CMBehemoth.Record())) || !vs.EnablePlayerVehicleID(CMBehemoth.Record(), true, false) {
      return "!" + CMText.BehNoRecord();
    }
    this.m_truckPending = true;
    this.Watch();
    return "*" + CMText.BehInVehicles();
  }

  private func Watch() -> Void {
    if !this.m_keys {
      this.m_keys = true;
      GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnUnloadKey");
    }
    if !this.m_watching {
      this.m_watching = true;
      this.Later(0.25, 0);
    }
  }

  private func Later(delay: Float, step: Int32) -> Void {
    let cb = new CMBehemothTick();
    cb.sys = this;
    cb.gen = this.m_gen;
    cb.step = step;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, delay, false);
  }

  public func Fire(gen: Int32, step: Int32) -> Void {
    if gen != this.m_gen {
      return;
    }
    switch step {
      case 1:
        this.Unload();
        break;
      case 2:
        this.FadeIn();
        break;
      default:
        this.Look();
        break;
    }
  }

  private let m_truckID: EntityID;
  private let m_lookLog: Float;

  private func Truck() -> ref<VehicleObject> {
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    if IsDefined(player) {
      let sat = player.GetMountedVehicle();
      if IsDefined(sat) && sat.GetRecordID() == CMBehemoth.Record() {
        if this.m_truckID != sat.GetEntityID() {
        }
        this.m_truckID = sat.GetEntityID();
        return sat;
      }
    }
    let v = GameInstance.FindEntityByID(game, this.m_truckID) as VehicleObject;
    if IsDefined(v) && v.GetRecordID() == CMBehemoth.Record() {
      return v;
    }
    let bb = GameInstance.GetBlackboardSystem(game).Get(GetAllBlackboardDefs().VehicleSummonData);
    if IsDefined(bb) {
      let id = bb.GetEntityID(GetAllBlackboardDefs().VehicleSummonData.SummonedVehicleEntityID);
      v = GameInstance.FindEntityByID(game, id) as VehicleObject;
      if IsDefined(v) && v.GetRecordID() == CMBehemoth.Record() {
        if this.m_truckID != id {
        }
        this.m_truckID = id;
        return v;
      }
    }
    return null;
  }

  private func Look() -> Void {
    if !this.m_truckPending {
      this.m_watching = false;
      this.Prompt(false);
      return;
    }
    let player = GetPlayer(this.GetGameInstance());
    let truck = this.Truck();
    let at = false;
    if IsDefined(player) && IsDefined(truck) && !this.m_unloading && !IsDefined(player.GetMountedVehicle()) {

      let rel = player.GetWorldPosition() - truck.GetWorldPosition();
      let fwd = truck.GetWorldForward();
      fwd.Z = 0.0;
      fwd = Vector4.Normalize(fwd);
      let along = rel.X * fwd.X + rel.Y * fwd.Y;
      let side = AbsF(rel.X * fwd.Y - rel.Y * fwd.X);
      at = along < -3.0 && along > -9.0 && side < 2.6 && AbsF(rel.Z) < 3.0;
      let now = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGameInstance()));
      if now - this.m_lookLog > 3.0 && Vector4.Length(rel) < 15.0 {
        this.m_lookLog = now;
      }
    }
    this.Prompt(at);
    this.Later(0.25, 0);
  }

  private func Prompt(on: Bool) -> Void {
    if Equals(on, this.m_shown) && !on {
      return;
    }
    if on && !this.m_shown {
    }
    this.m_shown = on;
    let bb = GameInstance.GetBlackboardSystem(this.GetGameInstance()).Get(GetAllBlackboardDefs().UIInteractions);
    let data: InteractionChoiceHubData;
    data.active = on;
    if on {
      data.title = CMText.BehTruckTitle();
      let c: InteractionChoiceData;
      c.localizedName = CMText.BehUnloadMech();
      c.inputAction = n"Choice1";
      c.rawInputKey = CMKeys.Unload(GetPlayer(this.GetGameInstance()));
      ArrayPush(data.choices, c);
    }
    bb.SetVariant(GetAllBlackboardDefs().UIInteractions.InteractionChoiceHub, ToVariant(data), true);
  }

  protected cb func OnUnloadKey(event: ref<KeyInputEvent>) -> Void {
    if !this.m_shown || this.m_unloading || !Equals(event.GetAction(), EInputAction.IACT_Press) || !Equals(event.GetKey(), CMKeys.Unload(GetPlayer(this.GetGameInstance()))) {
      return;
    }
    this.m_unloading = true;
    this.Prompt(false);
    this.FadeOut();
    this.Later(0.9, 1);
  }

  private func Unload() -> Void {
    let game = this.GetGameInstance();
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let me = player.GetWorldPosition();
    let fwd = player.GetWorldForward();
    let right = new Vector4(fwd.Y, -fwd.X, 0.0, 0.0);
    let at = me + right * 6.0;
    let hit: TraceResult;
    if CMGround.Down(game, at + new Vector4(0.0, 0.0, 4.0, 0.0), at - new Vector4(0.0, 0.0, 6.0, 0.0), hit) {
      at = Cast<Vector4>(hit.position);
    } else {
      at = me - fwd * 7.0;
    }
    at.W = 1.0;
    let msg = CMFleet.Get(game).DeployAt(0, at);
    player.SetWarningMessage(CMLinkSystem.Plain(StrBeginsWith(msg, "*") ? "*" + CMText.BehMechUnloaded() : msg));
    if StrBeginsWith(msg, "*") {
      this.m_truckPending = false;
      GameInstance.GetVehicleSystem(game).EnablePlayerVehicleID(CMBehemoth.Record(), false, true);
    }
    this.Later(1.4, 2);
  }

  private func FadeOut() -> Void {
    let hud = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer").GetVirtualWindow();
    if !IsDefined(hud) {
      return;
    }
    let r = new inkRectangle();
    r.SetAnchor(inkEAnchor.Fill);
    r.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
    r.SetOpacity(0.0);
    r.Reparent(hud);
    this.m_fade = r;
    let def = new inkAnimDef();
    def.AddInterpolator(CMPilotHud.Fade(0.0, 1.0, 0.6, 0.0));
    r.PlayAnimation(def);
  }

  private func FadeIn() -> Void {
    this.m_unloading = false;
    if !IsDefined(this.m_fade) {
      return;
    }
    let def = new inkAnimDef();
    def.AddInterpolator(CMPilotHud.Fade(1.0, 0.0, 0.8, 0.0));
    this.m_fade.PlayAnimation(def);
    let gone = new CMBehemothFadeGone();
    gone.fade = this.m_fade;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(gone, 1.0, false);
  }
}

public class CMBehemothFadeGone extends DelayCallback {
  public let fade: wref<inkRectangle>;

  public func Call() -> Void {
    if IsDefined(this.fade) {
      let parent = this.fade.GetParentWidget() as inkCompoundWidget;
      if IsDefined(parent) {
        parent.RemoveChild(this.fade);
      }
    }
  }
}
