module TerminalKit.Tools

import TerminalKit.*
import RedFunctions.*
import RedFunctions.Json.*
import RedFunctions.Storage.*

public class TKToolsHost extends IScriptable {
  public func Storage() -> String = "TerminalKit"
  public func Kinds() -> array<String> = ["Spot", "Spawn point", "Patrol point", "Entrance", "Drop point", "Other"]
  public func Sizes() -> array<String> = ["", "Small", "Medium", "Large", "Huge"]

  public func District() -> String = ""
  public func Logged(entry: ref<JsonMap>) -> Void {}
  public func Routed(entry: ref<JsonMap>) -> Void {}
  public func Changed() -> Void {}
  public func Warn(text: String) -> Void {
    let p = GetPlayer(GetGameInstance());
    if IsDefined(p) {
      p.SetWarningMessage(text);
    }
  }
}

public class TKToolsSystem extends ScriptableSystem {
  public let host: ref<TKToolsHost>;
  public let kind: Int32;
  public let size: Int32;
  public let posPage: Int32;
  public let positions: ref<JsonList>;
  public let routes: ref<JsonList>;
  public let routeOn: Bool;
  public let routeNodes: array<Vector4>;
  public let routeLooks: array<Vector4>;
  public let routePage: Int32;
  public let inspect: array<String>;
  public let inspectRecord: String;
  public let inspectLook: String;
  public let flats: array<String>;
  public let flatsOf: String;
  public let spawnFriendly: Bool;
  public let spawned: array<EntityID>;
  public let spawnedNames: array<String>;
  public let tweakQuery: String;
  public let tweakKind: Int32;
  public let tweakPage: Int32;
  public let tweakHits: array<String>;
  public let logFilter: String;
  public let logPage: Int32;

  public static func Get() -> ref<TKToolsSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"TerminalKit.Tools.TKToolsSystem") as TKToolsSystem

  private func OnAttach() -> Void {
    GameInstance.GetDynamicEntitySystem().RegisterListener(n"TKSpawnTest", this, n"OnSpawnEvent");
  }

  private func OnDetach() -> Void {
    GameInstance.GetDynamicEntitySystem().UnregisterListener(n"TKSpawnTest", this, n"OnSpawnEvent");
  }

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    this.routeOn = false;
    ArrayClear(this.routeNodes);
    ArrayClear(this.routeLooks);
    ArrayClear(this.spawned);
    ArrayClear(this.spawnedNames);
  }

  public func Host() -> ref<TKToolsHost> {
    if !IsDefined(this.host) {
      this.host = new TKToolsHost();
    }
    return this.host;
  }

  private cb func OnSpawnEvent(event: ref<DynamicEntityEvent>) {
    if NotEquals(event.GetEventType(), DynamicEntityEventType.Spawned) || !this.spawnFriendly {
      return;
    }
    let npc = GameInstance.GetDynamicEntitySystem().GetEntity(event.GetEntityID()) as NPCPuppet;
    let player = GetPlayer(this.GetGameInstance());
    if IsDefined(npc) && IsDefined(player) {
      let a = npc.GetAttitudeAgent();
      if IsDefined(a) {
        a.SetAttitudeGroup(player.GetAttitudeAgent().GetAttitudeGroup());
        a.SetAttitudeTowards(player.GetAttitudeAgent(), EAIAttitude.AIA_Friendly);
      }
    }
  }
}

public abstract class TKTools {

  public static func Use(host: ref<TKToolsHost>) -> Void {
    let sys = TKToolsSystem.Get();
    if IsDefined(sys) {
      sys.host = host;
      sys.positions = null;
      sys.routes = null;
    }
  }

  public static func UseFor(host: ref<TKToolsHost>) -> Void {
    let sys = TKToolsSystem.Get();
    if !IsDefined(sys) || !IsDefined(host) {
      return;
    }
    if !IsDefined(sys.host) || NotEquals(sys.host.Storage(), host.Storage()) {
      TKTools.Use(host);
    }
  }

  public static func Sys() -> ref<TKToolsSystem> = TKToolsSystem.Get()
  public static func Store() -> ref<ModStorage> = ModStorage.Open(TKTools.Sys().Host().Storage())
  private static func Warn(text: String) -> Void { TKTools.Sys().Host().Warn(text); }

  public static func Request(p: ref<TKPage>, page: String, arg: String) -> Bool {
    if !StrBeginsWith(page, "tk_") || !IsDefined(TKTools.Sys()) {
      return false;
    }
    switch page {
      case "tk_tools": TKTools.Home(p); break;
      case "tk_positions": TKTools.Positions(p); break;
      case "tk_routes": TKTools.Routes(p); break;
      case "tk_inspect": TKToolsWorld.Inspect(p); break;
      case "tk_spawn": TKToolsWorld.Spawn(p); break;
      case "tk_tweak": TKToolsWorld.Tweak(p); break;
      case "tk_flats": TKToolsWorld.Flats(p); break;
      case "tk_log": TKToolsWorld.Log(p); break;
      default: return false;
    }
    return true;
  }

  public static func Act(p: ref<TKPage>, action: String, arg: String) -> Bool {
    if !StrBeginsWith(action, "tk_") || !IsDefined(TKTools.Sys()) {
      return false;
    }
    let sys = TKTools.Sys();
    let v = TKTools.Value(arg);
    switch action {
      case "tk_go": p.GoTo(StrBeforeFirst(arg + "~", "~"), StrAfterFirst(arg, "~")); break;
      case "tk_copy":
        RedFunc.SetClipboardText(arg);
        p.SetMessage("COPIED: " + arg);
        break;

      case "tk_kind": sys.kind = v; break;
      case "tk_size": sys.size = v; break;
      case "tk_log": TKTools.LogHere(p, p.GetField("tk_posname")); break;
      case "tk_posdel": TKTools.DeletePosition(StringToInt(arg, -1)); p.SetMessage("POSITION DELETED"); break;
      case "tk_pospage": sys.posPage = v; break;

      case "tk_route": TKTools.RouteAction(p, arg); break;
      case "tk_routepage": sys.routePage = v; break;
      default: return TKToolsWorld.Act(p, action, arg);
    }
    return true;
  }

  public static func Value(arg: String) -> Int32 = StringToInt(StrContains(arg, ":") ? StrAfterLast(arg, ":") : arg, 0)

  public static func Nav(p: ref<TKPage>, current: String) -> Void {
    p.Links("TOOLS|POSITIONS|ROUTES|INSPECT|SPAWN|TWEAKDB|LOG", "tk_tools|tk_positions|tk_routes|tk_inspect|tk_spawn|tk_tweak|tk_log", current);
  }

  private static func Home(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    p.SetTitle("DEV TOOLS", "TerminalKit Tools: files go to r6/storages/" + sys.Host().Storage());
    TKTools.Nav(p, "tk_tools");
    p.Tile("POSITIONS", IntToString(TKTools.PositionList().Size()) + " LOGGED", "Stand somewhere, name it, log it", "cyan", "OPEN", "tk_go", "tk_positions", true);
    p.Tile("ROUTES", sys.routeOn ? "RECORDING" : IntToString(TKTools.RouteList().Size()) + " SAVED", "Walk a route, log each stop", "green", "OPEN", "tk_go", "tk_routes", true);
    p.Tile("INSPECT", ArraySize(sys.inspect) > 0 ? "LAST: " + StrUpper(StrAfterLast(sys.inspectRecord, ".")) : "LOOK AT IT", "Record, look, faction, attitude", "yellow", "OPEN", "tk_go", "tk_inspect", true);
    p.Tile("SPAWN", IntToString(ArraySize(sys.spawned)) + " OUT", "Any NPC or vehicle record ahead of V", "orange", "OPEN", "tk_go", "tk_spawn", true);
    p.Tile("TWEAKDB", RedFunc.TweakNamesReady() ? IntToString(RedFunc.TweakNamesCount()) + " NAMES" : "!NAMES LOADING", "Search records and their flats", "purple", "OPEN", "tk_go", "tk_tweak", true);
    let logLines = TKLog.Lines();
    p.Tile("LOG", IntToString(ArraySize(logLines)) + " LINES", "What mods wrote with TKLog.Add", "blue", "OPEN", "tk_go", "tk_log", true);
  }

  public static func PositionList() -> ref<JsonList> {
    let sys = TKTools.Sys();
    if !IsDefined(sys.positions) {
      let data = TKTools.Store().ReadJson("positions.json");
      sys.positions = IsDefined(data) && data.IsList() ? data.AsList() : JsonList.Make();
    }
    return sys.positions;
  }

  public static func GameDistrict() -> String {
    let prevention = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"PreventionSystem") as PreventionSystem;
    let district = IsDefined(prevention) ? prevention.GetCurrentDistrict() : null;
    if !IsDefined(district) {
      return "";
    }
    let record = TweakDBInterface.GetDistrictRecord(district.GetDistrictID());
    return IsDefined(record) ? StrAfterLast(TDBID.ToStringDEBUG(record.GetID()), ".") : "";
  }

  private static func Positions(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    let host = sys.Host();
    let kinds = host.Kinds();
    let sizes = host.Sizes();
    sys.kind = Clamp(sys.kind, 0, ArraySize(kinds) - 1);
    sys.size = Clamp(sys.size, 0, ArraySize(sizes) - 1);
    p.SetTitle("POSITION LOGGER", "Stand on the spot, face the way it should face, name it and log it (positions.json)");
    TKTools.Nav(p, "tk_positions");
    p.Input("NAME", "", "tk_posname");
    p.Dropdown("KIND", "What the spot is for", IntToString(sys.kind), TKStr.Join(kinds, "|"), TKTools.Indices(ArraySize(kinds)), "tk_kind", "");
    let names = sizes;
    names[0] = "None";
    p.Dropdown("SIZE", "For places that come in sizes", IntToString(sys.size), TKStr.Join(names, "|"), TKTools.Indices(ArraySize(sizes)), "tk_size", "");
    p.Button("LOG THIS POSITION", "tk_log", "", true);
    let list = TKTools.PositionList();
    let per = 6;
    let pages = TKSheet.Pages(list.Size(), per);
    let page = Clamp(sys.posPage, 0, pages - 1);
    p.Heading("LOGGED (" + IntToString(list.Size()) + ")");

    let i = list.Size() - 1 - page * per;
    let stop = Max(-1, i - per);
    while i > stop {
      let pos = list.MapAt(i);
      let tag = pos.Text("type", "?") + (StrLen(pos.Text("size", "")) > 0 ? ", " + pos.Text("size", "") : "");
      let at = FloatToStringPrec(pos.Float("x", 0.0), 1) + ", " + FloatToStringPrec(pos.Float("y", 0.0), 1) + ", " + FloatToStringPrec(pos.Float("z", 0.0), 1);
      p.Buttons(IntToString(i + 1) + ". [" + tag + "] " + pos.Text("name", "?"), pos.Text("district", "") + "  (" + at + ")  yaw " + FloatToStringPrec(pos.Float("yaw", 0.0), 0), "",
        "COPY|?DELETE", "tk_copy|tk_posdel", at + "\n" + IntToString(i));
      i -= 1;
    }
    if pages > 1 {
      p.Pager(page, pages, "tk_pospage", "");
    }
  }

  public static func Indices(n: Int32) -> String {
    let parts: array<String>;
    let i = 0;
    while i < n {
      ArrayPush(parts, IntToString(i));
      i += 1;
    }
    return TKStr.Join(parts, "|");
  }

  private static func LogHere(p: ref<TKPage>, name: String) -> Void {
    let sys = TKTools.Sys();
    let host = sys.Host();
    let player = GetPlayer(GetGameInstance());
    if !IsDefined(player) {
      return;
    }
    let pos = player.GetWorldPosition();
    let rot = player.GetWorldOrientation();
    let list = TKTools.PositionList();
    let kinds = host.Kinds();
    let sizes = host.Sizes();
    let entry = JsonMap.Make();
    entry.PutText("name", StrLen(name) > 0 ? name : "Position " + IntToString(list.Size() + 1));
    entry.PutText("type", kinds[Clamp(sys.kind, 0, ArraySize(kinds) - 1)]);
    let size = sizes[Clamp(sys.size, 0, ArraySize(sizes) - 1)];
    if StrLen(size) > 0 {
      entry.PutText("size", size);
    }
    let district = host.District();
    entry.PutText("district", StrLen(district) > 0 ? district : TKTools.GameDistrict());
    entry.PutFloat("x", pos.X);
    entry.PutFloat("y", pos.Y);
    entry.PutFloat("z", pos.Z);
    entry.PutFloat("yaw", player.GetWorldYaw());
    entry.PutFloat("qi", rot.i);
    entry.PutFloat("qj", rot.j);
    entry.PutFloat("qk", rot.k);
    entry.PutFloat("qr", rot.r);
    entry.PutText("time", RedFunc.RealDate());
    list.Push(entry);
    TKTools.Store().WriteJson("positions.json", list);
    host.Logged(entry);
    TKLog.Add("TOOLS", "position logged: " + entry.Text("name", ""));
    p.SetMessage("POSITION LOGGED: " + StrUpper(entry.Text("name", "")));
  }

  private static func DeletePosition(i: Int32) -> Void {
    let list = TKTools.PositionList();
    if list.RemoveAt(i) {
      TKTools.Store().WriteJson("positions.json", list);
      TKTools.Sys().Host().Changed();
    }
  }

  public static func RouteList() -> ref<JsonList> {
    let sys = TKTools.Sys();
    if !IsDefined(sys.routes) {
      let data = TKTools.Store().ReadJson("routes.json");
      sys.routes = IsDefined(data) && data.IsList() ? data.AsList() : JsonList.Make();
    }
    return sys.routes;
  }

  public static func Recording() -> Bool {
    let sys = TKTools.Sys();
    return IsDefined(sys) && sys.routeOn;
  }

  public static func LogStop() -> Void {
    let sys = TKTools.Sys();
    let player = GetPlayer(GetGameInstance());
    if !IsDefined(sys) || !IsDefined(player) {
      return;
    }
    if !sys.routeOn {
      TKTools.Warn("NOT RECORDING A ROUTE");
      return;
    }
    let pos = player.GetWorldPosition();
    let fw = player.GetWorldForward();
    ArrayPush(sys.routeNodes, pos);
    ArrayPush(sys.routeLooks, Vector4(pos.X + fw.X * 5.0, pos.Y + fw.Y * 5.0, pos.Z, 1.0));
    TKTools.Warn("ROUTE STOP " + IntToString(ArraySize(sys.routeNodes)) + " LOGGED");
  }

  private static func Routes(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    p.SetTitle("ROUTE RECORDER", "Walk a route and log each stop: here, or with your mod's key (TKTools.LogStop) with the terminal closed (routes.json)");
    TKTools.Nav(p, "tk_routes");
    if sys.routeOn {
      p.Input("ROUTE NAME", "", "tk_routename");
      p.Buttons("RECORDING: " + IntToString(ArraySize(sys.routeNodes)) + " STOPS", "Log a stop where you stand, or close the terminal and use your key.", "green",
        "LOG STOP HERE|UNDO LAST|SAVE|CANCEL", "tk_route|tk_route|tk_route|tk_route", "stop|undo|save|cancel");
      let k = 0;
      while k < ArraySize(sys.routeNodes) {
        let n = sys.routeNodes[k];
        p.Pair("STOP " + IntToString(k + 1), FloatToStringPrec(n.X, 1) + ", " + FloatToStringPrec(n.Y, 1) + ", " + FloatToStringPrec(n.Z, 1), "");
        k += 1;
      }
    } else {
      p.Buttons("RECORD A ROUTE", "Start, walk the route logging each stop, then save and name it.", "", "START RECORDING", "tk_route", "start");
    }
    let list = TKTools.RouteList();
    let per = 5;
    let pages = TKSheet.Pages(list.Size(), per);
    let page = Clamp(sys.routePage, 0, pages - 1);
    p.Heading("SAVED ROUTES (" + IntToString(list.Size()) + ")");
    let i = list.Size() - 1 - page * per;
    let stop = Max(-1, i - per);
    while i > stop {
      let r = list.MapAt(i);
      let nodes = r.List("nodes");
      p.Buttons(StrUpper(r.Text("name", "?")), IntToString(IsDefined(nodes) ? nodes.Size() : 0) + " stops  |  " + r.Text("time", ""), "", "?DELETE", "tk_route", "del" + IntToString(i));
      i -= 1;
    }
    if pages > 1 {
      p.Pager(page, pages, "tk_routepage", "");
    }
  }

  private static func RouteAction(p: ref<TKPage>, arg: String) -> Void {
    let sys = TKTools.Sys();
    if Equals(arg, "start") {
      sys.routeOn = true;
      ArrayClear(sys.routeNodes);
      ArrayClear(sys.routeLooks);
      return;
    }
    if Equals(arg, "stop") {
      TKTools.LogStop();
      return;
    }
    if Equals(arg, "undo") {
      if ArraySize(sys.routeNodes) > 0 {
        ArrayPop(sys.routeNodes);
        ArrayPop(sys.routeLooks);
      }
      return;
    }
    if Equals(arg, "cancel") {
      sys.routeOn = false;
      return;
    }
    if Equals(arg, "save") {
      if ArraySize(sys.routeNodes) < 2 {
        p.SetMessage("LOG AT LEAST TWO STOPS FIRST");
        return;
      }
      let name = p.GetField("tk_routename");
      let list = TKTools.RouteList();
      let entry = JsonMap.Make();
      entry.PutText("name", StrLen(name) > 0 ? name : "Route " + IntToString(list.Size() + 1));
      entry.PutText("time", RedFunc.RealDate());
      let nodes = JsonList.Make();
      let k = 0;
      while k < ArraySize(sys.routeNodes) {
        let m = JsonMap.Make();
        let n = sys.routeNodes[k];
        let l = sys.routeLooks[k];
        m.PutFloat("x", n.X); m.PutFloat("y", n.Y); m.PutFloat("z", n.Z);
        m.PutFloat("lx", l.X); m.PutFloat("ly", l.Y); m.PutFloat("lz", l.Z);
        nodes.Push(m);
        k += 1;
      }
      entry.Put("nodes", nodes);
      list.Push(entry);
      TKTools.Store().WriteJson("routes.json", list);
      sys.routeOn = false;
      sys.Host().Routed(entry);
      TKLog.Add("TOOLS", "route saved: " + entry.Text("name", ""));
      p.SetMessage("ROUTE SAVED: " + StrUpper(entry.Text("name", "")) + " (" + IntToString(ArraySize(sys.routeNodes)) + " STOPS)");
      return;
    }
    if StrBeginsWith(arg, "del") {
      let list = TKTools.RouteList();
      if list.RemoveAt(StringToInt(StrAfterFirst(arg, "del"), -1)) {
        TKTools.Store().WriteJson("routes.json", list);
        sys.Host().Changed();
      }
    }
  }
}

public abstract class TKToolsWorld {
  public static func Act(p: ref<TKPage>, action: String, arg: String) -> Bool {
    let sys = TKTools.Sys();
    switch action {
      case "tk_look": TKToolsWorld.LookAt(p); break;
      case "tk_insp_log":
        if ArraySize(sys.inspect) > 0 {
          let lines: array<String>;
          ArrayPush(lines, "# " + RedFunc.RealDate());
          for l in sys.inspect {
            ArrayPush(lines, StrReplace(l, "|", ": "));
          }
          ArrayPush(lines, "");
          TKTools.Store().WriteLines("inspect.txt", lines, true);
          p.SetMessage("ADDED TO INSPECT.TXT");
        }
        break;
      case "tk_spawn": TKToolsWorld.SpawnIt(p, p.GetField("tk_record"), p.GetField("tk_appearance")); break;
      case "tk_tspawn":
        TKToolsWorld.SpawnIt(p, arg, "");
        break;
      case "tk_despawn": TKToolsWorld.Despawn(Equals(arg, "all")); break;
      case "tk_friend": sys.spawnFriendly = TKTools.Value(arg) == 1; break;
      case "tk_tsearch":
        sys.tweakQuery = arg;
        sys.tweakPage = 0;
        TKToolsWorld.Search();
        break;
      case "tk_tkind":
        sys.tweakKind = TKTools.Value(arg);
        TKToolsWorld.Search();
        break;
      case "tk_tpage": sys.tweakPage = TKTools.Value(arg); break;
      case "tk_tdump":
        let lines: array<String>;
        ArrayPush(lines, "# TweakSearch \"" + sys.tweakQuery + "\" | " + RedFunc.RealDate() + " | " + IntToString(ArraySize(sys.tweakHits)) + " hits");
        for h in sys.tweakHits {
          ArrayPush(lines, h);
        }
        TKTools.Store().WriteLines("tweak_search.txt", lines);
        p.SetMessage("WROTE TWEAK_SEARCH.TXT");
        break;
      case "tk_tflats":
        sys.flatsOf = arg;
        sys.flats = RedFunc.TweakChildren(arg, 400);
        p.GoTo("tk_flats", "");
        break;
      case "tk_fdump":
        let lines: array<String>;
        ArrayPush(lines, "# " + sys.flatsOf + " | " + RedFunc.RealDate() + " | " + IntToString(ArraySize(sys.flats)) + " flats");
        for f in sys.flats {
          ArrayPush(lines, f);
        }
        TKTools.Store().WriteLines("tweak_record.txt", lines);
        p.SetMessage("WROTE TWEAK_RECORD.TXT");
        break;
      case "tk_lfilter":
        sys.logFilter = arg;
        sys.logPage = 0;
        break;
      case "tk_lpage": sys.logPage = TKTools.Value(arg); break;
      case "tk_lclear": TKLog.Clear(); break;
      case "tk_lsave":
        TKTools.Store().WriteLines("log.txt", TKLog.Lines());
        p.SetMessage("WROTE LOG.TXT");
        break;
      default: return false;
    }
    return true;
  }

  public static func Inspect(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    p.SetTitle("INSPECTOR", "Look straight at an NPC, a vehicle or an object, then inspect it");
    TKTools.Nav(p, "tk_inspect");
    p.Buttons("LOOK-AT", ArraySize(sys.inspect) > 0 ? "The last thing inspected is below." : "Nothing inspected yet.", "",
      "INSPECT|ADD TO INSPECT.TXT", "tk_look|tk_insp_log", "\n");
    if ArraySize(sys.inspect) == 0 {
      return;
    }
    p.Ledger("head", "WHAT|VALUE", "L28|L72");
    for l in sys.inspect {
      p.Ledger("line", l, "L28|L72");
    }
    if StrLen(sys.inspectRecord) > 0 {
      p.Buttons("RECORD", sys.inspectRecord, "", "COPY RECORD|COPY LOOK|SHOW FLATS|SPAWN ANOTHER", "tk_copy|tk_copy|tk_tflats|tk_tspawn",
        sys.inspectRecord + "\n" + sys.inspectLook + "\n" + sys.inspectRecord + "\n" + sys.inspectRecord);
    }
  }

  private static func Attitude(a: EAIAttitude) -> String {
    switch a {
      case EAIAttitude.AIA_Friendly: return "Friendly";
      case EAIAttitude.AIA_Hostile: return "Hostile";
      default: return "Neutral";
    }
  }

  private static func LookAt(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    let player = GetPlayer(GetGameInstance());
    if !IsDefined(player) {
      return;
    }
    let obj = GameInstance.GetTargetingSystem(GetGameInstance()).GetLookAtObject(player);
    if !IsDefined(obj) {
      p.SetMessage("LOOK STRAIGHT AT SOMETHING FIRST (CLOSE THE TERMINAL, AIM, OPEN IT AGAIN)");
      return;
    }
    ArrayClear(sys.inspect);
    sys.inspectRecord = "";
    sys.inspectLook = "";
    ArrayPush(sys.inspect, "CLASS|" + NameToString(obj.GetClassName()));
    let npc = obj as NPCPuppet;
    let veh = obj as VehicleObject;
    if IsDefined(npc) {
      let id = npc.GetRecordID();
      sys.inspectRecord = TDBID.ToStringDEBUG(id);
      sys.inspectLook = NameToString(npc.GetCurrentAppearanceName());
      ArrayPush(sys.inspect, "RECORD|" + sys.inspectRecord);
      ArrayPush(sys.inspect, "APPEARANCE|" + sys.inspectLook);
      let rec = TweakDBInterface.GetCharacterRecord(id);
      if IsDefined(rec) {
        ArrayPush(sys.inspect, "NAME|" + GetLocalizedTextByKey(rec.DisplayName()));
        if IsDefined(rec.Affiliation()) {
          ArrayPush(sys.inspect, "AFFILIATION|" + TDBID.ToStringDEBUG(rec.Affiliation().GetID()));
        }
        if IsDefined(rec.ReactionPreset()) {
          ArrayPush(sys.inspect, "REACTION PRESET|" + TDBID.ToStringDEBUG(rec.ReactionPreset().GetID()));
        }
      }
      ArrayPush(sys.inspect, "NPC TYPE|" + EnumValueToString("gamedataNPCType", Cast<Int64>(EnumInt(npc.GetNPCType()))));
      ArrayPush(sys.inspect, "LEVEL|" + IntToString(Cast<Int32>(GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatType.Level))));
      ArrayPush(sys.inspect, "STATE|" + (npc.IsDead() ? "Dead" : "Alive") + (npc.IsCivilian() ? ", civilian" : "") + (npc.IsCrowd() ? ", crowd" : ""));
    } else {
      if IsDefined(veh) {
        sys.inspectRecord = TDBID.ToStringDEBUG(veh.GetRecordID());
        ArrayPush(sys.inspect, "RECORD|" + sys.inspectRecord);
      }
    }
    ArrayPush(sys.inspect, "ATTITUDE TO V|" + TKToolsWorld.Attitude(obj.GetAttitudeTowards(player)));
    ArrayPush(sys.inspect, "ENTITY|" + ToString(EntityID.GetHash(obj.GetEntityID())));
    let pos = obj.GetWorldPosition();
    ArrayPush(sys.inspect, "POSITION|" + FloatToStringPrec(pos.X, 2) + ", " + FloatToStringPrec(pos.Y, 2) + ", " + FloatToStringPrec(pos.Z, 2));
    ArrayPush(sys.inspect, "DISTANCE|" + FloatToStringPrec(Vector4.Distance(pos, player.GetWorldPosition()), 1) + " m");
    TKLog.Add("TOOLS", "inspected " + (StrLen(sys.inspectRecord) > 0 ? sys.inspectRecord : NameToString(obj.GetClassName())));
  }

  public static func Spawn(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    p.SetTitle("SPAWN TESTER", "Any NPC or vehicle record, a few metres ahead of V (not saved with the game)");
    TKTools.Nav(p, "tk_spawn");
    p.Input("RECORD", sys.inspectRecord, "tk_record");
    p.Input("APPEARANCE", "", "tk_appearance");
    p.Check("ON V'S SIDE", "Spawned NPCs join V's attitude group", sys.spawnFriendly, "tk_friend", "");
    p.Buttons("SPAWN", IntToString(ArraySize(sys.spawned)) + " out now", "", "SPAWN|DELETE LAST|DELETE ALL", "tk_spawn|tk_despawn|tk_despawn", "\nlast\nall");
    let k = ArraySize(sys.spawnedNames) - 1;
    while k >= 0 {
      p.Pair(IntToString(k + 1) + ".", sys.spawnedNames[k], "");
      k -= 1;
    }
  }

  private static func SpawnIt(p: ref<TKPage>, record: String, look: String) -> Void {
    let sys = TKTools.Sys();
    let player = GetPlayer(GetGameInstance());
    if !IsDefined(player) || StrLen(record) == 0 {
      p.SetMessage("TYPE A RECORD FIRST (Character.xxx or Vehicle.xxx)");
      return;
    }
    let id = TDBID.Create(record);
    if !IsDefined(TweakDBInterface.GetCharacterRecord(id)) && !IsDefined(TweakDBInterface.GetVehicleRecord(id)) {
      p.SetMessage("NO SUCH NPC OR VEHICLE RECORD: " + record);
      return;
    }
    let pos = player.GetWorldPosition();
    let fw = player.GetWorldForward();
    let ahead = IsDefined(TweakDBInterface.GetVehicleRecord(id)) ? 7.0 : 3.0;
    let spec = new DynamicEntitySpec();
    spec.recordID = id;
    if StrLen(look) > 0 {
      spec.appearanceName = StringToName(look);
    }
    spec.position = Vector4(pos.X + fw.X * ahead, pos.Y + fw.Y * ahead, pos.Z + 0.2, 1.0);
    spec.orientation = player.GetWorldOrientation();
    spec.persistState = false;
    spec.persistSpawn = false;
    spec.alwaysSpawned = true;
    spec.tags = [n"TKSpawnTest"];
    let entity = GameInstance.GetDynamicEntitySystem().CreateEntity(spec);
    if !EntityID.IsDefined(entity) {
      p.SetMessage("COULDN'T SPAWN " + record);
      return;
    }
    ArrayPush(sys.spawned, entity);
    ArrayPush(sys.spawnedNames, record + (StrLen(look) > 0 ? " / " + look : ""));
    TKLog.Add("TOOLS", "spawned " + record);
    p.SetMessage("SPAWNED " + StrUpper(StrAfterLast(record, ".")));
    p.GoTo("tk_spawn", "");
  }

  private static func Despawn(all: Bool) -> Void {
    let sys = TKTools.Sys();
    while ArraySize(sys.spawned) > 0 {
      let n = ArraySize(sys.spawned) - 1;
      GameInstance.GetDynamicEntitySystem().DeleteEntity(sys.spawned[n]);
      ArrayPop(sys.spawned);
      ArrayPop(sys.spawnedNames);
      if !all {
        return;
      }
    }
  }

  private static func Search() -> Void {
    let sys = TKTools.Sys();
    ArrayClear(sys.tweakHits);
    if StrLen(sys.tweakQuery) >= 2 && RedFunc.TweakNamesReady() {
      sys.tweakHits = RedFunc.TweakSearch(sys.tweakQuery, sys.tweakKind, 2000);
    }
  }

  public static func Tweak(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    p.SetTitle("TWEAKDB", "Search the game's records by name (at least two letters); copy, open or spawn a hit");
    TKTools.Nav(p, "tk_tweak");
    if !RedFunc.TweakNamesReady() {
      p.Text("!The TweakDB name table is still loading. Try again in a moment.", "red");
    }
    p.Search("SEARCH", sys.tweakQuery, "tk_query", "tk_tsearch");
    p.Dropdown("LOOK IN", "What the search covers", IntToString(sys.tweakKind), "RECORDS|FLATS|QUERIES|EVERYTHING", "0|1|2|3", "tk_tkind", "");
    let n = ArraySize(sys.tweakHits);
    p.Buttons("RESULTS", IntToString(n) + (n >= 2000 ? "+ (the first 2,000)" : "") + " for \"" + sys.tweakQuery + "\"", "", (n > 0 ? "" : "!") + "DUMP TO FILE", "tk_tdump", "");
    let per = 10;
    let pages = TKSheet.Pages(n, per);
    let page = Clamp(sys.tweakPage, 0, pages - 1);
    let i = page * per;
    while i < n && i < (page + 1) * per {
      let hit = sys.tweakHits[i];
      let spawnable = StrBeginsWith(hit, "Character.") || StrBeginsWith(hit, "Vehicle.");
      p.Buttons(hit, "", "", "COPY|FLATS|" + (spawnable ? "" : "!") + "SPAWN", "tk_copy|tk_tflats|tk_tspawn", hit + "\n" + hit + "\n" + hit);
      i += 1;
    }
    if pages > 1 {
      p.Pager(page, pages, "tk_tpage", "");
    }
  }

  public static func Flats(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    p.SetTitle("RECORD", sys.flatsOf);
    TKTools.Nav(p, "tk_tweak");
    p.Buttons(sys.flatsOf, IntToString(ArraySize(sys.flats)) + " flats", "", "COPY NAME|DUMP TO FILE|BACK TO SEARCH", "tk_copy|tk_fdump|tk_go", sys.flatsOf + "\n\ntk_tweak");
    for f in sys.flats {
      p.Note(f);
    }
  }

  public static func Log(p: ref<TKPage>) -> Void {
    let sys = TKTools.Sys();
    p.SetTitle("LOG", "What mods wrote with TKLog.Add, newest first (kept for this session)");
    TKTools.Nav(p, "tk_log");
    p.Search("FILTER", sys.logFilter, "tk_filter", "tk_lfilter");
    let all = TKLog.Lines();
    let shown: array<String>;
    let k = ArraySize(all) - 1;
    let needle = StrLower(sys.logFilter);
    while k >= 0 {
      if StrLen(needle) == 0 || StrContains(StrLower(all[k]), needle) {
        ArrayPush(shown, all[k]);
      }
      k -= 1;
    }
    p.Buttons("LINES", IntToString(ArraySize(shown)) + " of " + IntToString(ArraySize(all)), "", "SAVE TO LOG.TXT|?CLEAR", "tk_lsave|tk_lclear", "\n");
    let per = 20;
    let pages = TKSheet.Pages(ArraySize(shown), per);
    let page = Clamp(sys.logPage, 0, pages - 1);
    let i = page * per;
    while i < ArraySize(shown) && i < (page + 1) * per {
      p.Note(shown[i]);
      i += 1;
    }
    if pages > 1 {
      p.Pager(page, pages, "tk_lpage", "");
    }
  }
}
