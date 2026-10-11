module ControllableMechs

import Codeware.UI.ScreenHelper

public class CMSignalLost {
  private let m_root: ref<inkCanvas>;
  private let m_parent: wref<inkCompoundWidget>;
  private let m_flash: ref<inkRectangle>;
  private let m_static: array<ref<inkRectangle>>;
  private let m_title: ref<inkText>;
  private let m_foot: ref<inkText>;
  private let m_t: Float;
  private let m_W: Float;
  private let m_snowMax: Float;

  public static func Show(name: String, kind: String) -> ref<CMSignalLost> {
    let s = new CMSignalLost();
    s.Build(name, kind);
    return s;
  }

  private func Build(name: String, kind: String) -> Void {
    let layer = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
    if !IsDefined(layer) {
      return;
    }
    let window = layer.GetVirtualWindow();
    if !IsDefined(window) {
      return;
    }
    this.m_parent = window;
    let root = new inkCanvas();
    root.SetName(n"cm_signal_lost");
    root.SetInteractive(false);
    let screen = ScreenHelper.GetScreenSize(GetGameInstance());
    this.m_W = 3840.0;
    if screen.Y > 100.0 {
      let k = screen.Y / 2160.0;
      this.m_W = screen.X / k;
      root.SetAnchor(inkEAnchor.TopLeft);
      root.SetSize(Vector2(this.m_W, 2160.0));
      root.SetRenderTransformPivot(Vector2(0.0, 0.0));
      root.SetScale(Vector2(k, k));
    } else {
      root.SetAnchor(inkEAnchor.Fill);
    }
    root.Reparent(window);
    this.m_root = root;
    let W = this.m_W;
    let black = new HDRColor(0.0, 0.0, 0.0, 1.0);
    let white = new HDRColor(1.0, 1.0, 1.0, 1.0);

    let title = CMPilotHud.Red();
    let rule = CMPilotHud.Red();
    let snow = white;
    let dark = 0.94;
    let bands = 48;
    this.m_snowMax = 0.22;
    let sub = CMText.LostLinkTerminated(name);

    let back = CMText.LostPressReturn(CMKeys.PilotName(GetPlayer(GetGameInstance())));
    let foot = back;
    switch kind {
      case "bombus":

        title = white;
        rule = white;
        snow = new HDRColor(0.85, 0.85, 0.85, 1.0);
        dark = 0.55;
        bands = 140;
        this.m_snowMax = 0.55;
        sub = CMText.LostBombusSub(name);
        foot = CMText.LostNoVideo(back);
        break;
      case "octant":
        title = CMPilotHud.Amber();
        rule = CMPilotHud.Amber();
        snow = CMPilotHud.Amber();
        dark = 0.85;
        bands = 36;
        this.m_snowMax = 0.18;
        sub = CMText.LostDatalink(name);
        foot = CMText.LostLinkProcedure(back);
        break;
      case "wyvern":
        title = new HDRColor(0.62, 1.05, 1.00, 1.0);
        rule = CMPilotHud.Caution();
        snow = new HDRColor(0.62, 1.05, 1.00, 1.0);
        dark = 0.88;
        bands = 40;
        this.m_snowMax = 0.18;
        sub = CMText.LostIsrFeed(name);
        foot = CMText.LostContactsNotRetained(back);
        break;
      case "griffin":
        title = CMPilotHud.Red();
        rule = new HDRColor(0.40, 1.05, 0.52, 1.0);
        snow = new HDRColor(0.40, 1.05, 0.52, 1.0);
        dark = 0.9;
        bands = 44;
        this.m_snowMax = 0.2;
        sub = CMText.LostAirframe(name);
        foot = back;
        break;
    }
    CMPilotHud.Bar(root, 0.0, 0.0, W, 2160.0, black, dark);

    let i = 0;
    while i < bands {
      ArrayPush(this.m_static, CMPilotHud.Bar(root, 0.0, 0.0, W, 4.0, snow, 0.1));
      i += 1;
    }

    let cx = W * 0.5;
    let sh = CMPilotHud.Label(root, inkEAnchor.TopLeft, cx + 6.0, 846.0, CMText.LostSignalLost(), 170, n"Semi-Bold", black);
    sh.SetAnchorPoint(Vector2(0.5, 0.0));
    this.m_title = CMPilotHud.Label(root, inkEAnchor.TopLeft, cx, 840.0, CMText.LostSignalLost(), 170, n"Semi-Bold", title);
    this.m_title.SetAnchorPoint(Vector2(0.5, 0.0));
    let st = CMPilotHud.Label(root, inkEAnchor.TopLeft, cx, 1060.0, sub, 48, n"Semi-Bold", white);
    st.SetAnchorPoint(Vector2(0.5, 0.0));
    st.SetOpacity(0.85);
    CMKit.Pill(root, cx - 700.0, 1038.0, 1400.0, 6.0, rule, 0.9);
    this.m_foot = CMPilotHud.Label(root, inkEAnchor.TopLeft, cx, 1180.0, foot, 36, n"Medium", white);
    this.m_foot.SetAnchorPoint(Vector2(0.5, 0.0));

    this.m_flash = CMPilotHud.Bar(root, 0.0, 0.0, W, 2160.0, white, 0.9);
    this.Tick(0.0);
  }

  public func Tick(dt: Float) -> Void {
    if !IsDefined(this.m_root) {
      return;
    }
    this.m_t += dt;
    this.m_flash.SetOpacity(MaxF(0.0, 0.9 - this.m_t * 6.0));
    for b in this.m_static {
      b.SetMargin(inkMargin(0.0, RandRangeF(0.0, 2160.0), 0.0, 0.0));
      b.SetSize(Vector2(this.m_W, RandRangeF(2.0, 14.0)));
      b.SetOpacity(RandRangeF(0.03, this.m_snowMax));
    }
    this.m_title.SetOpacity(RandRangeF(0.0, 1.0) < 0.12 ? 0.35 : 1.0);
    let ph = this.m_t * 3.0;
    this.m_foot.SetOpacity(ph - Cast<Float>(FloorF(ph)) < 0.5 ? 0.9 : 0.25);
  }

  public func Remove() -> Void {
    if IsDefined(this.m_root) && IsDefined(this.m_parent) {
      this.m_parent.RemoveChild(this.m_root);
    }
    this.m_root = null;
    ArrayClear(this.m_static);
  }
}
