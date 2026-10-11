module DroneCompanion

public class DCHud extends IScriptable {
  private let m_panel: wref<inkVerticalPanel>;
  private let m_rows: array<wref<inkHorizontalPanel>>;
  private let m_icons: array<wref<inkImage>>;
  private let m_names: array<wref<inkText>>;
  private let m_subs: array<wref<inkText>>;
  private let m_fills: array<wref<inkRectangle>>;
  private let m_last: String;
  private let m_scale: Float = 0.65;
  private let m_posX: Float = 10.0;
  private let m_posY: Float = 140.0;

  private final func MakeText(size: Int32, parent: ref<inkCompoundWidget>) -> ref<inkText> {
    let text: ref<inkText> = new inkText();
    text.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    text.SetFontStyle(n"Medium");
    text.SetFontSize(size);
    text.SetFitToContent(true);
    text.Reparent(parent);
    return text;
  }

  public final func Build(root: ref<inkCompoundWidget>) -> Void {
    let old: ref<inkWidget> = root.GetWidgetByPathName(n"dcSquadHud");
    if IsDefined(old) {
      root.RemoveChild(old);
    };

    let panel: ref<inkVerticalPanel> = new inkVerticalPanel();
    panel.SetName(n"dcSquadHud");
    panel.SetAnchor(inkEAnchor.TopLeft);
    panel.SetAnchorPoint(new Vector2(0.0, 0.0));
    panel.SetTranslation(new Vector2(this.m_posX, this.m_posY));
    panel.SetScale(new Vector2(this.m_scale, this.m_scale));
    panel.SetVisible(false);
    panel.Reparent(root);
    this.m_panel = panel;

    let i: Int32 = 0;
    while i < 8 {
      let row: ref<inkHorizontalPanel> = new inkHorizontalPanel();
      row.SetMargin(inkMargin(0.0, 0.0, 0.0, 10.0));
      row.SetVisible(false);
      row.Reparent(panel);
      ArrayPush(this.m_rows, row);

      let icon: ref<inkImage> = new inkImage();
      icon.SetAtlasResource(ResRef.FromString("dronecompanion\\gui\\dc_icons.inkatlas"));
      icon.SetSize(Vector2(44.0, 44.0));
      icon.SetMargin(inkMargin(0.0, 2.0, 10.0, 0.0));
      icon.Reparent(row);
      ArrayPush(this.m_icons, icon);

      let col: ref<inkVerticalPanel> = new inkVerticalPanel();
      col.Reparent(row);

      let name: ref<inkText> = this.MakeText(28, col);
      name.SetTintColor(new HDRColor(0.90, 0.90, 0.93, 1.0));
      name.SetLetterCase(textLetterCase.UpperCase);
      ArrayPush(this.m_names, name);

      let barCv: ref<inkCanvas> = new inkCanvas();
      barCv.SetSize(Vector2(240.0, 8.0));
      barCv.SetMargin(inkMargin(0.0, 4.0, 0.0, 2.0));
      barCv.Reparent(col);

      let barBg: ref<inkRectangle> = new inkRectangle();
      barBg.SetSize(Vector2(240.0, 8.0));
      barBg.SetTintColor(new HDRColor(0.5, 0.5, 0.55, 1.0));
      barBg.SetOpacity(0.25);
      barBg.Reparent(barCv);

      let fill: ref<inkRectangle> = new inkRectangle();
      fill.SetSize(Vector2(240.0, 8.0));
      fill.Reparent(barCv);
      ArrayPush(this.m_fills, fill);

      let sub: ref<inkText> = this.MakeText(22, col);
      sub.SetTintColor(new HDRColor(0.74, 0.74, 0.78, 1.0));
      ArrayPush(this.m_subs, sub);

      i += 1;
    };
  }

  private final func HpColor(pct: Float) -> HDRColor {
    if pct >= 50.0 {
      return new HDRColor(0.35, 0.85, 0.40, 1.0);
    };
    if pct >= 25.0 {
      return new HDRColor(0.95, 0.78, 0.20, 1.0);
    };
    return new HDRColor(0.92, 0.22, 0.18, 1.0);
  }

  public final func SetScale(scale: Float) -> Void {
    this.m_scale = MaxF(0.4, MinF(2.0, scale)) * 0.65;
    if IsDefined(this.m_panel) {
      this.m_panel.SetScale(new Vector2(this.m_scale, this.m_scale));
    };
  }

  public final func SetOffset(x: Float, y: Float) -> Void {
    this.m_posX = x;
    this.m_posY = y;
    if IsDefined(this.m_panel) {
      this.m_panel.SetTranslation(new Vector2(x, y));
    };
  }

  public final func Ready() -> Bool {
    return IsDefined(this.m_panel);
  }

  public final func SetState(payload: String) -> Void {
    if !IsDefined(this.m_panel) || Equals(payload, this.m_last) {
      return;
    };
    this.m_last = payload;
    if StrLen(payload) == 0 {
      this.m_panel.SetVisible(false);
      return;
    };
    let lines: array<String> = StrSplit(payload, "\n");
    let i: Int32 = 0;
    while i < ArraySize(this.m_rows) {
      if i < ArraySize(lines) {
        let f: array<String> = StrSplit(lines[i], "\t", true);
        if ArraySize(f) >= 4 {
          let pct: Float = StringToFloat(f[1], 0.0);
          let isNote: Bool = pct < 0.0;
          this.m_icons[i].SetTexturePart(StringToName(f[0]));
          this.m_icons[i].SetVisible(!isNote);
          this.m_names[i].SetText(f[2]);
          let down: Bool = ArraySize(f) >= 5 && Equals(f[4], "d");
          if down || (ArraySize(f) >= 5 && Equals(f[4], "f")) {
            this.m_names[i].SetTintColor(new HDRColor(0.95, 0.35, 0.30, 1.0));
          } else {
            this.m_names[i].SetTintColor(new HDRColor(0.90, 0.90, 0.93, 1.0));
          };
          if down {
            this.m_icons[i].SetTintColor(new HDRColor(0.95, 0.35, 0.30, 1.0));
          } else {
            this.m_icons[i].SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
          };
          this.m_subs[i].SetText(f[3]);
          this.m_fills[i].SetSize(Vector2(240.0 * MaxF(0.0, MinF(pct, 100.0)) / 100.0, 8.0));
          this.m_fills[i].SetTintColor(this.HpColor(pct));
          this.m_fills[i].SetVisible(!isNote);
          this.m_rows[i].SetVisible(true);
        } else {
          this.m_rows[i].SetVisible(false);
        };
      } else {
        this.m_rows[i].SetVisible(false);
      };
      i += 1;
    };
    this.m_panel.SetVisible(true);
  }
}

@addField(PlayerPuppet)
let m_dcHudPanel: ref<DCHud>;

@addMethod(PlayerPuppet)
public func DCKill(drone: wref<GameObject>) -> Bool {
  return true;
}

@addMethod(PlayerPuppet)
public func DCHudScale(scale: Float) -> Bool {
  if IsDefined(this.m_dcHudPanel) {
    this.m_dcHudPanel.SetScale(scale);
    return true;
  };
  return false;
}

@addMethod(PlayerPuppet)
public func DCHudOffset(x: Float, y: Float) -> Bool {
  if IsDefined(this.m_dcHudPanel) {
    this.m_dcHudPanel.SetOffset(x, y);
    return true;
  };
  return false;
}

@addMethod(PlayerPuppet)
public func DCHudPush(payload: String) -> Bool {
  if IsDefined(this.m_dcHudPanel) && this.m_dcHudPanel.Ready() {
    this.m_dcHudPanel.SetState(payload);
    return true;
  };
  return false;
}

private static func DC_HudRoot() -> ref<inkCompoundWidget> {
  let layer: ref<inkLayerWrapper> = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
  if !IsDefined(layer) {
    return null;
  };
  return layer.GetVirtualWindow();
}

@wrapMethod(healthbarWidgetGameController)
protected cb func OnPlayerAttach(playerGameObject: ref<GameObject>) -> Bool {
  let ret: Bool = wrappedMethod(playerGameObject);
  let pp: ref<PlayerPuppet> = playerGameObject as PlayerPuppet;
  if IsDefined(pp) {
    let root: ref<inkCompoundWidget> = DC_HudRoot();
    let hud: ref<DCHud> = new DCHud();
    if IsDefined(root) {
      hud.Build(root);
    };
    pp.m_dcHudPanel = hud;
    pp.DCEmit(hud.Ready() ? "hud:ok" : "hud:noroot");
  };
  return ret;
}

private static func DC_ChassisIconPart(id: EntityID) -> CName {
  let ses: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(GetGameInstance());
  if !IsDefined(ses) || !ses.HasStatusEffect(id, t"DroneCompanion.CompanionSE") {
    return n"";
  };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisOctantSE") { return n"octant"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisWyvernSE") { return n"wyvern"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisGriffinSE") { return n"griffin"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisBombusSE") { return n"bombus"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisMinotaurSE") { return n"minotaur"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisAndroidSE") { return n"android"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisFlatheadSE") { return n"flathead"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisChimeraSE") { return n"chimera"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisCerberusSE") { return n"cerberus"; };
  return n"";
}

public class DCWreckMappinData extends MappinScriptData {
  public let chassis: CName;
}

public class DCWreckMark {
  public let rec: String;
  public let id: NewMappinID;
}

@addField(PlayerPuppet)
let m_dcWrecks: array<ref<DCWreckMark>>;

@addMethod(PlayerPuppet)
public func DCUnmarkWreck(rec: String) -> Bool {
  let found: Bool = false;
  let i: Int32 = 0;
  while i < ArraySize(this.m_dcWrecks) {
    if Equals(this.m_dcWrecks[i].rec, rec) {
      GameInstance.GetMappinSystem(this.GetGame()).UnregisterMappin(this.m_dcWrecks[i].id);
      ArrayErase(this.m_dcWrecks, i);
      found = true;
    } else {
      i += 1;
    };
  };
  return found;
}

@addMethod(PlayerPuppet)
public func DCMarkWreck(rec: String, chassis: CName, pos: Vector4) -> Bool {
  this.DCUnmarkWreck(rec);
  let data: MappinData;
  data.mappinType = t"Mappins.DroneCompanionMappin";
  data.variant = gamedataMappinVariant.CPO_PingDoorVariant;
  data.visibleThroughWalls = true;
  let tag: ref<DCWreckMappinData> = new DCWreckMappinData();
  tag.chassis = chassis;
  data.scriptData = tag;
  let mark: ref<DCWreckMark> = new DCWreckMark();
  mark.rec = rec;
  mark.id = GameInstance.GetMappinSystem(this.GetGame()).RegisterMappin(data, pos);
  ArrayPush(this.m_dcWrecks, mark);
  return true;
}

@addMethod(BaseMinimapMappinController)
protected func DCHideIfDrone() -> Void {
  let mappin: wref<IMappin> = this.GetMappin();
  if !IsDefined(mappin) || Equals(mappin.GetVariant(), gamedataMappinVariant.CPO_PingDoorVariant) || !DC_IsDronePuppet(mappin.GetEntityID()) {
    return;
  };
  this.SetForceHide(true);
  let root: ref<inkWidget> = this.GetRootWidget();
  if IsDefined(root) {
    root.SetVisible(false);
    root.SetOpacity(0.0);
  };
}

@wrapMethod(BaseMinimapMappinController)
protected func Intro() -> Void {
  wrappedMethod();
  this.DCHideIfDrone();
}

@wrapMethod(MinimapStealthMappinController)
protected func Intro() -> Void {
  wrappedMethod();
  this.DCHideIfDrone();
}

@wrapMethod(MinimapStealthMappinController)
protected func Update() -> Void {
  wrappedMethod();
  this.DCHideIfDrone();
}

public static func DC_IsOurMappin(mappin: wref<IMappin>) -> Bool {
  if !IsDefined(mappin) || !Equals(mappin.GetVariant(), gamedataMappinVariant.CPO_PingDoorVariant) {
    return false;
  };
  if IsDefined(DC_WreckData(mappin)) {
    return true;
  };
  let id: EntityID = mappin.GetEntityID();
  return EntityID.IsDefined(id) && GameInstance.GetStatusEffectSystem(GetGameInstance()).HasStatusEffect(id, t"DroneCompanion.CompanionSE");
}

@addField(MinimapPOIMappinController)
let m_dcNoPulse: Bool;

public static func DC_IsEntityCustomMappin(mappin: wref<IMappin>) -> Bool {
  if !IsDefined(mappin) || !Equals(mappin.GetVariant(), gamedataMappinVariant.CPO_PingDoorVariant) {
    return false;
  };
  return EntityID.IsDefined(mappin.GetEntityID()) || IsDefined(DC_WreckData(mappin));
}

@wrapMethod(MinimapPOIMappinController)
protected func Intro() -> Void {
  wrappedMethod();
  if DC_IsEntityCustomMappin(this.GetMappin()) {
    this.m_dcNoPulse = true;
    this.StopPingAnimation();
    inkWidgetRef.SetVisible(this.m_pulseWidget, false);
  };
}

@wrapMethod(MinimapPOIMappinController)
public func PlayPingAnimation(opt loopInfinite: Bool, opt overrideAnimName: CName) -> Bool {
  if this.m_dcNoPulse || DC_IsEntityCustomMappin(this.GetMappin()) {
    this.m_dcNoPulse = true;
    inkWidgetRef.SetVisible(this.m_pulseWidget, false);
    return false;
  };
  return wrappedMethod(loopInfinite, overrideAnimName);
}

public static func DC_WreckData(mappin: wref<IMappin>) -> ref<DCWreckMappinData> {
  if !IsDefined(mappin) {
    return null;
  };
  return mappin.GetScriptData() as DCWreckMappinData;
}

public static func DC_IsDown(id: EntityID) -> Bool {
  let puppet: ref<ScriptedPuppet> = GameInstance.FindEntityByID(GetGameInstance(), id) as ScriptedPuppet;
  if !IsDefined(puppet) {
    return false;
  };
  return puppet.IsDead() || ScriptedPuppet.IsDefeated(puppet);
}

public static func DC_IconTint(down: Bool) -> HDRColor {
  if down {
    return new HDRColor(0.95, 0.35, 0.30, 1.0);
  };
  return new HDRColor(1.0, 1.0, 1.0, 1.0);
}

public static func DC_StanceKey(id: EntityID) -> Int32 {
  if DC_IsDown(id) {
    return 4;
  };
  let ses: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(GetGameInstance());
  if !IsDefined(ses) {
    return 0;
  };
  if ses.HasStatusEffect(id, t"DroneCompanion.ArenaSE") {
    return 3;
  };
  if ses.HasStatusEffect(id, t"DroneCompanion.PassiveSE") {
    return 2;
  };
  if ses.HasStatusEffect(id, t"DroneCompanion.DefensiveSE") {
    return 1;
  };
  return 0;
}

public static func DC_StanceTint(key: Int32) -> HDRColor {
  switch key {
    case 1: return new HDRColor(1.0, 0.82, 0.25, 1.0);
    case 2: return new HDRColor(0.37, 0.96, 1.0, 1.0);
    case 3: return new HDRColor(0.85, 0.45, 1.0, 1.0);
    case 4: return DC_IconTint(true);
  };
  return DC_IconTint(false);
}

@addField(MinimapPOIMappinController)
let m_dcTintKey: Int32;

@addField(MinimapPOIMappinController)
let m_dcTinted: Bool;

@wrapMethod(MinimapPOIMappinController)
protected func Update() -> Void {
  wrappedMethod();
  let mappin: wref<IMappin> = this.GetMappin();
  if !IsDefined(mappin) || !Equals(mappin.GetVariant(), gamedataMappinVariant.CPO_PingDoorVariant) {
    return;
  };
  if DC_IsOurMappin(mappin) {
    this.SetRootVisible(true);
  };
  let id: EntityID = mappin.GetEntityID();
  if !EntityID.IsDefined(id) {
    return;
  };
  inkWidgetRef.SetVisible(this.m_pulseWidget, false);
  let key: Int32 = DC_StanceKey(id);
  if this.m_dcTinted && key == this.m_dcTintKey {
    return;
  };
  this.m_dcTintKey = key;
  this.m_dcTinted = true;
  inkImageRef.SetTintColor(this.iconWidget, DC_StanceTint(key));
}

@wrapMethod(BaseWorldMapMappinController)
protected func UpdateIcon() -> Void {
  wrappedMethod();
  let mappin: wref<IMappin> = this.GetMappin();
  if !IsDefined(mappin) || !Equals(mappin.GetVariant(), gamedataMappinVariant.CPO_PingDoorVariant) {
    return;
  };
  let id: EntityID = mappin.GetEntityID();
  let wreck: ref<DCWreckMappinData> = DC_WreckData(mappin);
  if !EntityID.IsDefined(id) && !IsDefined(wreck) {
    return;
  };
  let part: CName = IsDefined(wreck) ? wreck.chassis : DC_ChassisIconPart(id);
  if IsNameValid(part) {
    inkImageRef.SetAtlasResource(this.iconWidget, r"dronecompanion\\gui\\dc_icons.inkatlas");
    inkImageRef.SetTexturePart(this.iconWidget, part);
    let img: ref<inkImage> = inkImageRef.Get(this.iconWidget) as inkImage;
    if IsDefined(img) {
      img.SetFitToContent(false);
    };
    inkImageRef.SetSize(this.iconWidget, new Vector2(48.0, 48.0));
    inkImageRef.SetTintColor(this.iconWidget, IsDefined(wreck) ? DC_IconTint(true) : DC_StanceTint(DC_StanceKey(id)));
  };
}

@wrapMethod(BaseWorldMapMappinController)
protected final func Update() -> Void {
  wrappedMethod();
  let mappin: wref<IMappin> = this.GetMappin();
  if DC_IsOurMappin(mappin) {
    this.SetRootVisible(true);
    let id: EntityID = mappin.GetEntityID();
    if EntityID.IsDefined(id) {
      inkImageRef.SetTintColor(this.iconWidget, DC_StanceTint(DC_StanceKey(id)));
    };
  };
}

@wrapMethod(WorldMapTooltipController)
public func SetData(const data: script_ref<WorldMapTooltipData>, menu: ref<WorldMapMenuGameController>) -> Void {
  wrappedMethod(data, menu);
  let mappin: wref<IMappin> = Deref(data).mappin;
  if !DC_IsOurMappin(mappin) {
    return;
  };
  let wreck: ref<DCWreckMappinData> = DC_WreckData(mappin);
  let part: String = NameToString(IsDefined(wreck) ? wreck.chassis : DC_ChassisIconPart(mappin.GetEntityID()));
  if StrLen(part) == 0 {
    return;
  };
  inkTextRef.SetText(this.m_titleText, StrUpper(StrLeft(part, 1)) + StrRight(part, StrLen(part) - 1));
  inkWidgetRef.SetVisible(this.m_descText, false);
}

public class DCMapVariantTweak extends ScriptableTweak {
  protected cb func OnApply() -> Void {
    let batch: ref<TweakDBBatch> = TweakDBManager.StartBatch();
    this.JoinWaypointGroups(batch, n"MappinUIFilterGroup_Record");
    this.JoinWaypointGroups(batch, n"MappinsGroup_Record");
    batch.Commit();
  }

  private func JoinWaypointGroups(batch: ref<TweakDBBatch>, type: CName) -> Void {
    let groups: array<ref<TweakDBRecord>> = TweakDBInterface.GetRecords(type);
    let i: Int32 = 0;
    while i < ArraySize(groups) {
      let flat: TweakDBID = groups[i].GetID() + t".mappins";
      let variants: array<TweakDBID> = TweakDBInterface.GetForeignKeyArray(flat);
      let listsWaypoint: Bool = false;
      let j: Int32 = 0;
      while j < ArraySize(variants) {
        let variant: ref<MappinVariant_Record> = TweakDBInterface.GetMappinVariantRecord(variants[j]);
        if IsDefined(variant) && Equals(variant.Type(), gamedataMappinVariant.CustomPositionVariant) {
          listsWaypoint = true;
        };
        j += 1;
      };
      if listsWaypoint && !ArrayContains(variants, t"Mappins.DroneCompanionVariant") {
        ArrayPush(variants, t"Mappins.DroneCompanionVariant");
        batch.SetFlat(flat, variants);
        batch.UpdateRecord(groups[i].GetID());
      };
      i += 1;
    };
  }
}

@wrapMethod(WorldMappinsContainerController)
public func CreateMappinUIProfile(mappin: wref<IMappin>, mappinVariant: gamedataMappinVariant, customData: ref<MappinControllerCustomData>) -> MappinUIProfile {
  if Equals(mappinVariant, gamedataMappinVariant.CPO_PingDoorVariant) {
    let id: EntityID = mappin.GetEntityID();
    if EntityID.IsDefined(id) {
      let player: ref<GameObject> = this.GetPlayerControlledObject();
      if IsDefined(player) && GameInstance.GetStatusEffectSystem(player.GetGame()).HasStatusEffect(id, t"DroneCompanion.CompanionSE") {
        return MappinUIProfile.None();
      };
    };
  };
  return wrappedMethod(mappin, mappinVariant, customData);
}

public static func DC_IsDronePuppet(id: EntityID) -> Bool {
  if !EntityID.IsDefined(id) {
    return false;
  };
  if GameInstance.GetStatusEffectSystem(GetGameInstance()).HasStatusEffect(id, t"DroneCompanion.CompanionSE") {
    return true;
  };
  let puppet: ref<NPCPuppet> = GameInstance.FindEntityByID(GetGameInstance(), id) as NPCPuppet;
  if !IsDefined(puppet) {
    return false;
  };
  let record: ref<SubCharacter_Record> = TweakDBInterface.GetCharacterRecord(puppet.GetRecordID()) as SubCharacter_Record;
  return IsDefined(record) && Equals(record.BaseAttitudeGroup(), n"player");
}

@wrapMethod(MinimapContainerController)
public func CreateMappinUIProfile(mappin: wref<IMappin>, mappinVariant: gamedataMappinVariant, customData: ref<MappinControllerCustomData>) -> MappinUIProfile {
  if IsDefined(DC_WreckData(mappin)) {
    return MappinUIProfile.Create(r"base\\gameplay\\gui\\widgets\\minimap\\minimap_poi_mappin.inkwidget", t"MappinUISpawnProfile.Always", t"MinimapMappinUIProfile.Default");
  };
  let id: EntityID = mappin.GetEntityID();
  if EntityID.IsDefined(id) {
    if DC_IsDronePuppet(id) {
      if Equals(mappinVariant, gamedataMappinVariant.CPO_PingDoorVariant) {
        return MappinUIProfile.Create(r"base\\gameplay\\gui\\widgets\\minimap\\minimap_poi_mappin.inkwidget", t"MappinUISpawnProfile.Always", t"MinimapMappinUIProfile.Default");
      };
      return MappinUIProfile.None();
    };
  };
  return wrappedMethod(mappin, mappinVariant, customData);
}

@wrapMethod(MinimapPOIMappinController)
protected func UpdateIcon() -> Void {
  wrappedMethod();
  let mappin: wref<IMappin> = this.GetMappin();
  if !IsDefined(mappin) || !Equals(mappin.GetVariant(), gamedataMappinVariant.CPO_PingDoorVariant) {
    return;
  };
  let wreck: ref<DCWreckMappinData> = DC_WreckData(mappin);
  if IsDefined(wreck) {
    inkImageRef.SetAtlasResource(this.iconWidget, r"dronecompanion\\gui\\dc_icons.inkatlas");
    inkImageRef.SetTexturePart(this.iconWidget, wreck.chassis);
    inkImageRef.SetTintColor(this.iconWidget, DC_IconTint(true));
    return;
  };
  let id: EntityID = mappin.GetEntityID();
  if !EntityID.IsDefined(id) {
    return;
  };
  let ses: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(GetGameInstance());
  if !IsDefined(ses) || !ses.HasStatusEffect(id, t"DroneCompanion.CompanionSE") {
    return;
  };
  let part: CName = n"";
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisOctantSE") { part = n"octant"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisWyvernSE") { part = n"wyvern"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisGriffinSE") { part = n"griffin"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisBombusSE") { part = n"bombus"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisMinotaurSE") { part = n"minotaur"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisAndroidSE") { part = n"android"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisFlatheadSE") { part = n"flathead"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisChimeraSE") { part = n"chimera"; };
  if ses.HasStatusEffect(id, t"DroneCompanion.ChassisCerberusSE") { part = n"cerberus"; };
  if IsNameValid(part) {
    inkImageRef.SetAtlasResource(this.iconWidget, r"dronecompanion\\gui\\dc_icons.inkatlas");
    inkImageRef.SetTexturePart(this.iconWidget, part);
  };
}

@wrapMethod(BaseMinimapMappinController)
protected func Update() -> Void {
  wrappedMethod();
  let mappin: wref<IMappin> = this.GetMappin();
  if IsDefined(mappin) && !Equals(mappin.GetVariant(), gamedataMappinVariant.CPO_PingDoorVariant) && !this.IsForceHide() {
    let id: EntityID = mappin.GetEntityID();
    if EntityID.IsDefined(id) && GameInstance.GetStatusEffectSystem(GetGameInstance()).HasStatusEffect(id, t"DroneCompanion.CompanionSE") {
      this.SetForceHide(true);
    };
  };
}
