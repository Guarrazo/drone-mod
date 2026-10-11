module ControllableMechs

import TerminalKit.*

public class CMTerminal extends TKPopup {
  public func Content() -> ref<TKContent> {
    let c = new CMContent();
    c.game = this.GetGame();
    return c;
  }

  public func Layout() -> array<String> {
    return CMTerminal.PaneSpecs();
  }

  public static func PaneSpecs() -> array<String> {
    let s: array<String>;
    ArrayPush(s, "ribbon|top|140|fixed");
    ArrayPush(s, "deck|bottom|150|fixed");
    ArrayPush(s, "rack|left|560|fixed");
    ArrayPush(s, "ops|right|740|fixed");
    ArrayPush(s, "stage|fill|0");
    return s;
  }
  public func Brand() -> String = ""
  public func Name() -> String = ""
  public func Status() -> String = ""
  public func Footer() -> String = ""
  public func BootText() -> String = CMText.TermBootText()
  public func BootLines() -> array<String> = [CMText.TermColdStart(), CMText.TermOperatorAuth(), CMText.TermChannelUp(), CMText.TermMotorPool(IntToString(CMFleet.Count())), CMText.TermFireControl()]
  public func BootSeconds() -> Float = 1.6
  public func StartPage() -> String = "console"
  public func FrameWidth() -> Float = 3200.0
  public func FrameHeight() -> Float = 1720.0

  public func ScaleSource() -> ref<TKScaleSource> = new CMConScale()

  protected func Setup() -> Void {
    if IsDefined(this.m_lens) {
      this.m_lens.SetTintColor(CMConPal.Bg());
      this.m_lens.SetOpacity(0.62);
    }
  }

  public func Style() -> ref<TKStyle> {
    let s = new TKStyle();
    s.frame = 0;
    s.rivets = false;
    s.hazard = false;
    s.scanlines = 0.0;
    s.headerPlates = true;
    s.segmentedBars = 10;
    s.selectSound = n"ui_menu_onpress";
    s.denySound = n"ui_hacking_press_fail";

    s.fontFamily = "base\\gameplay\\gui\\fonts\\industry\\industry.inkfontfamily";
    s.fontStyle = n"Demi";
    return s;
  }

  protected func Closing() -> Void {
    CMTerminalState.Forget(this);
  }

  protected func Closed() -> Void {
    CMTerminalState.Forget(this);
  }

  public static func Toggle(player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(player) {
      return;
    }
    let state = CMTerminalState.Get(player.GetGame());
    if CMTerminal.IsUp(state) {
      if !state.open.IsTyping() {
        state.open.Close();
      }
      return;
    }

    state.open = null;

    if !TKPopup.CanOpen(player) {
      return;
    }
    TKTheme.Register(new CMMilitaryPalette());
    TKTheme.Register(new CMRobotLinkPalette());
    let terminal = new CMTerminal();
    state.open = terminal;
    TKPopup.Open(player, terminal);
  }

  public static func IsUp(state: ref<CMTerminalState>) -> Bool {
    if !IsDefined(state) || !IsDefined(state.open) || !state.open.IsInitialized() {
      return false;
    }
    let root = state.open.GetRootWidget();
    return IsDefined(root) && root.IsVisible();
  }

  public static func CloseOpen(game: GameInstance) -> Void {
    let state = CMTerminalState.Get(game);
    if CMTerminal.IsUp(state) {
      state.open.Close();
    }
    if IsDefined(state) {
      state.open = null;
    }
  }
}

public class CMMilitaryPalette extends TKPalette {
  public func Id() -> String = "cm_military"
  public func Color(role: String) -> HDRColor {
    switch role {
      case "title": return new HDRColor(0.32, 0.95, 0.42, 1.0);
      case "accent": return new HDRColor(1.0, 0.62, 0.14, 1.0);
      case "text": return new HDRColor(0.68, 0.84, 0.70, 1.0);
      case "rule": return new HDRColor(0.12, 0.36, 0.18, 1.0);
      case "frame": return new HDRColor(0.26, 0.76, 0.34, 1.0);
    }
    return new HDRColor(0.80, 0.96, 0.82, 1.0);
  }
}

public class CMTerminalState extends ScriptableSystem {
  public let open: wref<CMTerminal>;

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    TKTheme.Register(new CMMilitaryPalette());
    TKTheme.Register(new CMRobotLinkPalette());
  }

  public static func Get(game: GameInstance) -> ref<CMTerminalState> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"ControllableMechs.CMTerminalState") as CMTerminalState;
  }

  public static func Forget(terminal: ref<CMTerminal>) -> Void {
    let state = CMTerminalState.Get(GetGameInstance());
    if IsDefined(state) && state.open == terminal {
      state.open = null;
    }
  }
}
