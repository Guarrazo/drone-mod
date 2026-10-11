module DroneCompanion

public class DCPerksButton extends inkLogicController {
  private let m_owner: wref<PlayerPuppet>;
  private let m_back: wref<inkImage>;
  private let m_edge: wref<inkImage>;
  private let m_screen: wref<inkWidget>;

  public func DCSetScreen(screen: ref<inkWidget>) -> Void {
    this.m_screen = screen;
  }

  public func DCSetup(owner: ref<PlayerPuppet>, back: ref<inkImage>, edge: ref<inkImage>) -> Void {
    this.m_owner = owner;
    this.m_back = back;
    this.m_edge = edge;
  }

  private func DCLit(on: Bool) -> Void {
    if IsDefined(this.m_back) {
      this.m_back.SetTintColor(on ? new HDRColor(0.72, 0.12, 0.16, 1.0) : new HDRColor(0.4118, 0.0863, 0.0902, 1.0));
    };
    if IsDefined(this.m_edge) {
      this.m_edge.SetOpacity(on ? 1.0 : 0.80);
    };
  }

  protected cb func OnDCClick(evt: ref<inkPointerEvent>) -> Bool {
    if !evt.IsAction(n"click") {
      return false;
    };
    if IsDefined(this.m_owner) {
      let holder: ref<DCMenuHolder> = DCMenuHolder.Get(this.m_owner.GetGame());
      if IsDefined(holder) && IsDefined(this.m_screen) {
        holder.DCHide(this.m_screen);
      };
      this.m_owner.DCEmit("open:grid");
    };
    return false;
  }

  protected cb func OnDCHoverOver(evt: ref<inkPointerEvent>) -> Bool {
    this.DCLit(true);
    return false;
  }

  protected cb func OnDCHoverOut(evt: ref<inkPointerEvent>) -> Bool {
    this.DCLit(false);
    return false;
  }
}

public func DCFindText(root: ref<inkCompoundWidget>) -> ref<inkText> {
  if !IsDefined(root) {
    return null;
  };
  let i: Int32 = 0;
  while i < root.GetNumChildren() {
    let child: ref<inkWidget> = root.GetWidgetByIndex(i);
    let asText: ref<inkText> = child as inkText;
    if IsDefined(asText) {
      return asText;
    };
    let deeper: ref<inkText> = DCFindText(child as inkCompoundWidget);
    if IsDefined(deeper) {
      return deeper;
    };
    i += 1;
  };
  return null;
}

@if(ModuleExists("CustomPerkFramework"))
public func DCCustomPerkFrameworkInstalled() -> Bool {
  return true;
}

@if(!ModuleExists("CustomPerkFramework"))
public func DCCustomPerkFrameworkInstalled() -> Bool {
  return false;
}

@addField(NewPerksCategoriesGameController)
let m_dcButton: wref<inkWidget>;

@addField(NewPerksCategoriesGameController)
let m_dcButtonLogic: ref<DCPerksButton>;

@addMethod(NewPerksCategoriesGameController)
protected cb func OnDCScreenBlock(evt: ref<inkPointerEvent>) -> Bool {
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if !IsDefined(player) {
    return false;
  };
  let holder: ref<DCMenuHolder> = DCMenuHolder.Get(player.GetGame());
  if IsDefined(holder) && holder.DCIsOpenNow()
    && (evt.IsAction(n"next_menu") || evt.IsAction(n"prior_menu")
      || evt.IsAction(n"next_sub_menu") || evt.IsAction(n"prior_sub_menu")) {
    evt.Consume();
  };
  return false;
}

@wrapMethod(NewPerksCategoriesGameController)
protected cb func OnUninitialize() -> Bool {
  this.UnregisterFromGlobalInputCallback(n"OnPreOnPress", this, n"OnDCScreenBlock");
  let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    let holder: ref<DCMenuHolder> = DCMenuHolder.Get(player.GetGame());
    if IsDefined(holder) {
      holder.DCRestore();
    };
  };
  return wrappedMethod();
}

@wrapMethod(NewPerksCategoriesGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  if IsDefined(this.m_dcButton) {
    return result;
  };

  let sibling: ref<inkWidget> = inkWidgetRef.Get(this.m_skillsScreenButton);
  if !IsDefined(sibling) {
    return result;
  };
  let parent: ref<inkCompoundWidget> = sibling.GetParentWidget() as inkCompoundWidget;
  if !IsDefined(parent) {
    return result;
  };

  let base: inkMargin = sibling.GetMargin();
  let size: Vector2 = sibling.GetSize();
  let lift: Float = (size.Y + 20.0) * (DCCustomPerkFrameworkInstalled() ? 2.0 : 1.0);

  let spawned: ref<inkWidget> = this.SpawnFromExternal(parent,
    r"base\\gameplay\\gui\\fullscreen\\inventory\\inventory_screen.inkwidget",
    n"HyperlinkButton");
  if !IsDefined(spawned) {
    return result;
  };

  let holder: ref<inkWidget> = spawned;
  holder.SetName(n"dcDroneButton");
  holder.SetAnchor(sibling.GetAnchor());
  holder.SetAnchorPoint(sibling.GetAnchorPoint());
  holder.SetMargin(inkMargin(base.left, base.top - lift, base.right, base.bottom + lift));
  holder.SetInteractive(true);
  holder.SetSupportFocus(true);

  let label: ref<inkText> = DCFindText(holder as inkCompoundWidget);
  if IsDefined(label) {
    label.SetText(DroneCompanionText("Mod-DroneCompanion-PerksButton"));
    label.SetLetterCase(textLetterCase.UpperCase);
    label.SetFontSize(34);
    label.SetWrapping(false, 0.0);
  };

  let logic: ref<DCPerksButton> = new DCPerksButton();
  logic.DCSetup(this.GetPlayerControlledObject() as PlayerPuppet, null, null);
  logic.DCSetScreen(this.GetRootCompoundWidget());
  this.m_dcButtonLogic = logic;
  holder.RegisterToCallback(n"OnRelease", logic, n"OnDCClick");

  this.m_dcButton = holder;
  this.RegisterToGlobalInputCallback(n"OnPreOnPress", this, n"OnDCScreenBlock");
  return result;
}
