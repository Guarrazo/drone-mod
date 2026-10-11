module ControllableMechs

import TerminalKit.*
import TerminalKit.Tools.*
import ControllableMechs.Control.*

public class CMContent extends TKContent {
  public let game: GameInstance;

  private let m_con: ref<CMConState>;

  public func Con() -> ref<CMConState> {
    if !IsDefined(this.m_con) {
      this.m_con = new CMConState();
    }
    return this.m_con;
  }

  public func Request(p: ref<TKPage>, page: String, arg: String) -> Void {

    let theme = CMPilotSystem.Get(this.game).Theme();
    p.SetTheme(Equals(theme, "cm_military") ? "cm_robotlink" : theme);

    if CMConsole.IsOverlay(page) {
      CMConsole.Overlay(p, page, arg);
      return;
    }
    CMConsole.Chrome(p, page);
    p.Region("stage");
    switch page {
      case "settings":
        this.Settings(p);
        break;
      default:
        CMConsole.Stage(p);
        break;
    }
  }

  public func Custom(v: ref<TKView>, parent: ref<inkCompoundWidget>, p: ref<TKPage>, r: ref<TKRow>) -> ref<TKCustom> {
    return CMConsole.Make(this, v, parent, r);
  }

  public func HitHover(v: ref<TKView>, action: String, arg: String, over: Bool) -> Void {
    if Equals(action, "con_hp") {
      let con = this.Con();
      if IsDefined(con.stage) {
        con.stage.Hover(arg, over);
      }
    }
  }

  public func Act(p: ref<TKPage>, action: String, arg: String) -> Void {
    if StrBeginsWith(action, "con_") {
      CMConsole.Act(this, p, action, arg);
      return;
    }
    let cfg = CMPilotSystem.Get(this.game);
    let session = CMCSession.Get(this.game);
    switch action {
      case "cfgprofile":
        cfg.SetCfgProfile(CMContent.Val(arg, 0));
        break;
      case "dcamup":
        cfg.SetDroneCamUpCm(cfg.CfgProfile(), CMContent.InToCm(CMContent.Val(arg, CMContent.CmToIn(cfg.DroneCamUpCm(cfg.CfgProfile())))));
        break;
      case "dcamfwd":
        cfg.SetDroneCamFwdCm(cfg.CfgProfile(), CMContent.InToCm(CMContent.Val(arg, CMContent.CmToIn(cfg.DroneCamFwdCm(cfg.CfgProfile())))));
        break;
      case "dhide":
        cfg.SetDroneHideInSight(cfg.CfgProfile(), Equals(CMContent.Str(arg), "1"));
        break;
      case "dstab":
        cfg.SetDroneStabilize(cfg.CfgProfile(), CMContent.Val(arg, 0));
        break;
      case "dcamreset":
        cfg.ResetDroneCam(cfg.CfgProfile());
        p.SetMessage("*" + CMText.ConSensorMountResetOf(StrUpper(cfg.CfgProfile())));
        break;

      case "firemode":
        session.SetFireMode(CMContent.Val(arg, 0));
        break;
      case "dronehud":
        cfg.SetDroneHudStyle(cfg.CfgProfile(), CMContent.Val(arg, 0));
        break;
      case "mechhud":
        cfg.SetMechHudStyle(CMContent.Val(arg, 0));
        break;
      case "recoil":
        cfg.SetRecoilPct(CMContent.Val(arg, cfg.RecoilPct()));
        break;
      case "turn":
        cfg.SetTurnPct(CMContent.Val(arg, cfg.TurnPct()));
        break;
      case "sens":
        cfg.SetSensPct(CMContent.Val(arg, cfg.SensPct()));
        break;
      case "view":
        session.SetChaseView(CMContent.Val(arg, 0) == 1);
        break;
      case "chasedist":
        cfg.SetChaseDistCm(CMContent.FtToCm(CMContent.Val(arg, CMContent.CmToFt(cfg.ChaseDistCm(cfg.CfgProfile())))), cfg.CfgProfile());
        break;
      case "chaseup":
        cfg.SetChaseUpCm(CMContent.InToCm(CMContent.Val(arg, CMContent.CmToIn(cfg.ChaseUpCm(cfg.CfgProfile())))), cfg.CfgProfile());
        break;
      case "chaseside":
        cfg.SetChaseSideCm(CMContent.InToCm(CMContent.Val(arg, CMContent.CmToIn(cfg.ChaseSideCm(cfg.CfgProfile())))), cfg.CfgProfile());
        break;
      case "shoulder":
        cfg.SetShoulderLeft(CMContent.Val(arg, 0) == 1, cfg.CfgProfile());
        break;
      case "chasereset":
        cfg.ResetChaseOf(cfg.CfgProfile());
        p.SetMessage("*" + CMText.ConChaseCameraReset());
        break;
      case "camup":
        cfg.SetCamUpCm(CMContent.InToCm(CMContent.Val(arg, CMContent.CmToIn(cfg.CamUpCm()))));
        break;
      case "camfwd":
        cfg.SetCamFwdCm(CMContent.InToCm(CMContent.Val(arg, CMContent.CmToIn(cfg.CamFwdCm()))));
        break;
      case "camreset":
        cfg.ResetCamera();
        p.SetMessage("*" + CMText.ConSensorSensReset());
        break;
      case "theme":
        cfg.SetTheme(CMContent.Str(arg));
        p.SetTheme(CMContent.Str(arg));
        break;
    }
  }

  private func Settings(p: ref<TKPage>) -> Void {
    let cfg = CMPilotSystem.Get(this.game);
    let session = CMCSession.Get(this.game);
    p.SetTitle(CMText.ConConfiguration(), CMText.ConConfigSub());
    p.SetSection("settings");

    p.Dropdown(CMText.ConProfile(), CMText.ConProfileTip(), IntToString(cfg.CfgProfileIndex()), CMText.ConProfileOpts(), "0|1|2|3|4", "cfgprofile", "");
    let kind = cfg.CfgProfile();
    if NotEquals(kind, "mech") {
      this.DroneSettings(p, cfg, kind);
    } else {
      this.MechSettings(p, cfg, session);
    }
    this.CommonSettings(p, cfg, session);
  }

  private func ChaseSettings(p: ref<TKPage>, cfg: ref<CMPilotSystem>, prof: String) -> Void {
    let drone = NotEquals(prof, "mech");
    p.Heading(drone ? CMText.ConChaseCameraOf(StrUpper(prof)) : CMText.ConChaseCamera());
    p.Slider(CMText.ConDistance(), drone ? CMText.ConBehindDrone() : CMText.ConBehindMech(), "", (drone ? "2" : "10") + "|52|1|" + IntToString(CMContent.CmToFt(cfg.ChaseDistCm(prof))) + "| ft", "chasedist", "");
    p.Slider(CMText.ConHeight(), drone ? CMText.ConAboveDrone() : CMText.ConAboveMechFeet(), "", (drone ? "0" : "60") + "|354|2|" + IntToString(CMContent.CmToIn(cfg.ChaseUpCm(prof))) + "| in", "chaseup", "");
    p.Slider(CMText.ConSideOffset(), CMText.ConSideOffsetTip(), "", "0|156|2|" + IntToString(CMContent.CmToIn(cfg.ChaseSideCm(prof))) + "| in", "chaseside", "");
    p.Dropdown(CMText.ConShoulder(), CMText.ConShoulderTip(), cfg.ShoulderLeft(prof) ? "1" : "0", CMText.ConShoulderOpts(), "0|1", "shoulder", "");
    p.Item(CMText.ConDefaults(), drone ? CMText.ConChaseDroneDefaults() : CMText.ConChaseMechDefaults(), "", CMText.ConReset(), "chasereset", "", true);
    p.SetTip(CMText.ConChaseTip());
  }

  private func DroneSettings(p: ref<TKPage>, cfg: ref<CMPilotSystem>, kind: String) -> Void {

    if CMUDrone.HasTypeB(kind) {
      p.Heading(CMText.ConDisplayOf(StrUpper(kind)));
      p.Dropdown(CMText.ConHudStyle(), CMText.ConDroneHudTip(), IntToString(cfg.DroneHudStyle(kind)), CMText.ConTypeOpts(), "0|1", "dronehud", "");
    }
    p.Heading(CMText.ConOpticsMountOf(StrUpper(kind)));
    p.Slider(CMText.ConHeight(), CMText.ConDroneHeightTip(), "", "0|118|1|" + IntToString(CMContent.CmToIn(cfg.DroneCamUpCm(kind))) + "| in", "dcamup", "");
    p.Slider(CMText.ConForward(), CMText.ConDroneFwdTip(), "", "0|157|1|" + IntToString(CMContent.CmToIn(cfg.DroneCamFwdCm(kind))) + "| in", "dcamfwd", "");
    p.Dropdown(CMText.ConStabilize(), CMText.ConStabilizeTip(), IntToString(cfg.DroneStabilize(kind)), CMText.ConStabilizeOpts(), "0|1|2", "dstab", "");
    p.Check(CMText.ConHideDrone(), CMText.ConHideDroneTip(), cfg.DroneHideInSight(kind), "dhide", "");
    p.Item(CMText.ConDefaults(), CMText.ConDroneMountDefaults(IntToString(CMContent.CmToIn(CMDroneHull.SensorUpCm(kind))), IntToString(CMContent.CmToIn(CMDroneHull.SensorFwdCm(kind)))), "", CMText.ConReset(), "dcamreset", "", true);
    p.SetTip(CMText.ConAppliesAtOnce());
    this.ChaseSettings(p, cfg, kind);
  }

  private func MechSettings(p: ref<TKPage>, cfg: ref<CMPilotSystem>, session: ref<CMCSession>) -> Void {
    p.Heading(CMText.ConDisplay());
    p.Dropdown(CMText.ConHudStyle(), CMText.ConMechHudTip(),
      IntToString(cfg.MechHudStyle()),
      CMHudPal.StyleName(1) + "|" + CMHudPal.StyleName(0), "1|0", "mechhud", "");
    p.Heading(CMText.ConFireControl());
    p.Dropdown(CMText.ConFireMode(), CMText.ConFireModeTip(),
      IntToString(session.FireMode()),
      CMFireMode.Name(0) + "|" + CMFireMode.Name(1) + "|" + CMFireMode.Name(2), "0|1|2", "firemode", "");
    p.SetTip(CMText.ConFireModeHelp());
    p.Slider(CMText.ConRecoil(), CMText.ConRecoilTip(), "", "0|200|10|" + IntToString(cfg.RecoilPct()) + "|%", "recoil", "");

    p.Heading(CMText.ConChassis());
    p.Slider(CMText.ConTurnSpeed(), CMText.ConTurnSpeedTip(), "", "50|300|25|" + IntToString(cfg.TurnPct()) + "|%", "turn", "");

    p.Heading(CMText.ConOpticsMount());
    p.Slider(CMText.ConHeight(), CMText.ConMechHeightTip(), "", "40|177|1|" + IntToString(CMContent.CmToIn(cfg.CamUpCm())) + "| in", "camup", "");
    p.Slider(CMText.ConForward(), CMText.ConMechFwdTip(), "", "0|196|1|" + IntToString(CMContent.CmToIn(cfg.CamFwdCm())) + "| in", "camfwd", "");
    p.Item(CMText.ConDefaults(), CMText.ConMechMountDefaults(), "", CMText.ConReset(), "camreset", "", true);
    this.ChaseSettings(p, cfg, "mech");
  }

  private func CommonSettings(p: ref<TKPage>, cfg: ref<CMPilotSystem>, session: ref<CMCSession>) -> Void {
    p.Heading(CMText.ConOperator());
    p.Slider(CMText.ConMouseSens(), CMText.ConMouseSensTip(), "", "25|300|5|" + IntToString(cfg.SensPct()) + "|%", "sens", "");

    p.Heading(CMText.ConOpticsView());
    p.Dropdown(CMText.ConView(), CMText.ConViewTip(), session.IsChase() ? "1" : "0", CMText.ConViewOpts(), "0|1", "view", "");

    p.Heading(CMText.ConDisplay());
    p.Dropdown(CMText.ConTerminalPalette(), CMText.ConTerminalPaletteTip(), cfg.Theme(), CMContent.ThemeLabels(), CMContent.ThemeValues(), "theme", "");
  }

  public static func Str(arg: String) -> String {
    let s = arg;
    while StrContains(s, ":") {
      s = StrAfterFirst(s, ":");
    }
    return s;
  }

  public static func Val(arg: String, def: Int32) -> Int32 = StringToInt(CMContent.Str(arg), def)

  public static func CmToIn(cm: Int32) -> Int32 = RoundF(Cast<Float>(cm) / 2.54)
  public static func InToCm(inches: Int32) -> Int32 = RoundF(Cast<Float>(inches) * 2.54)
  public static func CmToFt(cm: Int32) -> Int32 = RoundF(Cast<Float>(cm) / 30.48)
  public static func FtToCm(ft: Int32) -> Int32 = RoundF(Cast<Float>(ft) * 30.48)

  public static func ThemeLabels() -> String {
    let ids = TKTheme.Ids();
    let s = "";
    for id in ids {
      s += (StrLen(s) > 0 ? "|" : "") + StrUpper(id);
    }
    return s;
  }

  public static func ThemeValues() -> String {
    let ids = TKTheme.Ids();
    let s = "";
    for id in ids {
      s += (StrLen(s) > 0 ? "|" : "") + id;
    }
    return s;
  }

}
