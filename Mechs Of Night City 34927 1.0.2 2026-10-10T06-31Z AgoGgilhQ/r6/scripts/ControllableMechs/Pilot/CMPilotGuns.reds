module ControllableMechs

import ControllableMechs.Control.*

public abstract class CMFireMode {
  public static func Stagger() -> Int32 = 0
  public static func Together() -> Int32 = 1
  public static func Split() -> Int32 = 2

  public static func Name(mode: Int32) -> String {
    if mode == CMFireMode.Together() { return CMText.GunLinkedSalvo(); }
    if mode == CMFireMode.Split() { return CMText.GunSplit(); }
    return CMText.GunStaggered();
  }

  public static func Next(mode: Int32) -> Int32 = (mode + 1) % 3
}

public class CMGun {
  public let hardpoint: CName;
  public let spec: ref<CMWeaponSpec>;
  public let cycle: Float;
  public let weapon: wref<WeaponObject>;
  public let heat: Float;
  public let locked: Bool;
  public let nextShot: Float;
  public let lastShot: Float;
  public let flash: Float;
  public let offAim: Bool;
  public let destroyed: Bool;
  public let ownTarget: Bool;
  public let target: Vector4;

  public func Ready() -> Bool = IsDefined(this.weapon) && !this.destroyed && this.weapon.IsAttached() && this.Holds(this.weapon)

  public func Slot() -> TweakDBID = Equals(this.hardpoint, n"arm_l") ? t"AttachmentSlots.WeaponLeft" : t"AttachmentSlots.WeaponRight"

  public func Holds(w: wref<WeaponObject>) -> Bool {
    return !TDBID.IsValid(this.spec.item) || ItemID.GetTDBID(w.GetItemID()) == this.spec.item;
  }
}

public class CMPilotGuns {
  public let left: ref<CMGun>;
  public let right: ref<CMGun>;
  private let m_turnLeft: Bool;
  private let m_names: String;
  public let rate: Float = 1.0;
  public let fired: Int32;
  public let ownerV: Bool;
  public let roundFrom: array<Vector4>;
  public let roundTo: array<Vector4>;
  public let trace: Bool;

  public func Init(mech: ref<NPCPuppet>, load: array<ref<CMHardpoint>>) -> Void {
    this.left = CMPilotGuns.Mount(load, n"arm_l");
    this.right = CMPilotGuns.Mount(load, n"arm_r");

    let rightID = CMPilotGuns.Fit(mech, this.right, ItemID.None());
    CMPilotGuns.Fit(mech, this.left, rightID);
    this.Refresh(mech);
    this.left.cycle = CMPilotGuns.CycleOf(mech.GetGame(), this.left);
    this.right.cycle = CMPilotGuns.CycleOf(mech.GetGame(), this.right);
    if CMPartLab.IsPlayerMech(mech) {
      CMPilotGuns.Upgrade(this.left, CMPilotSystem.Get(mech.GetGame()));
      CMPilotGuns.Upgrade(this.right, CMPilotSystem.Get(mech.GetGame()));
    }
    this.m_turnLeft = true;
  }

  public func Refit(mech: ref<NPCPuppet>) -> Void {

    let rightID: ItemID;
    if !this.right.destroyed {
      rightID = CMPilotGuns.Fit(mech, this.right, ItemID.None());
    }
    if !this.left.destroyed {
      CMPilotGuns.Fit(mech, this.left, rightID);
    }
  }

  public func SlotsNow(mech: ref<NPCPuppet>) -> String {
    let ts = GameInstance.GetTransactionSystem(mech.GetGame());
    let l = ts.GetItemInSlot(mech, this.left.Slot());
    let r = ts.GetItemInSlot(mech, this.right.Slot());
    return "L " + (IsDefined(l) ? CMPilotGuns.ItemTag(l.GetItemID()) : "empty") + "  R " + (IsDefined(r) ? CMPilotGuns.ItemTag(r.GetItemID()) : "empty");
  }

  private static func Upgrade(g: ref<CMGun>, cfg: ref<CMPilotSystem>) -> Void {
    if CMPartLab.Up(cfg, "cooling") {
      g.spec.coolRate *= 1.6;
      g.spec.heatPerShot *= 0.8;
    }
    if CMPartLab.Up(cfg, "feed") {
      g.cycle *= 0.8;
      g.spec.heatPerShot *= 1.15;
    }
  }

  private static func Mount(load: array<ref<CMHardpoint>>, hp: CName) -> ref<CMGun> {
    let g = new CMGun();
    g.hardpoint = hp;
    g.spec = CMLoadout.On(load, hp);
    if !IsDefined(g.spec) || g.spec.kind != CMWeaponSpec.Gun() {
      g.spec = CMWeaponSpecs.MK31();
    }
    return g;
  }

  private static func Fit(mech: ref<NPCPuppet>, g: ref<CMGun>, taken: ItemID) -> ItemID {
    let want = g.spec.item;
    if !TDBID.IsValid(want) {
      if !CMPartLab.IsPlayerMech(mech) {
        return ItemID.None();
      }
      want = Equals(g.hardpoint, n"arm_l") ? t"Items.Minotaur_HMG_Left" : t"Items.Minotaur_HMG_Right";
    }
    return CMPilotGuns.FitSlot(mech, g.Slot(), want, taken, NameToString(g.hardpoint));
  }

  public static func FitSlot(mech: ref<NPCPuppet>, slot: TweakDBID, want: TweakDBID, taken: ItemID, label: String) -> ItemID {
    let ts = GameInstance.GetTransactionSystem(mech.GetGame());
    let cur = ts.GetItemInSlot(mech, slot);
    if IsDefined(cur) && ItemID.GetTDBID(cur.GetItemID()) == want && cur.GetItemID() != taken {
      return cur.GetItemID();
    }
    let id = CMPilotGuns.Carried(ts, mech, want, taken);
    if !ItemID.IsValid(id) {

      let fresh = ItemID.IsValid(taken) && ItemID.GetTDBID(taken) == want ? ItemID.DuplicateRandomSeedWithOffset(taken, want, 7) : ItemID.FromTDBID(want);
      ts.GiveItem(mech, fresh, 1);
      id = CMPilotGuns.Carried(ts, mech, want, taken);
    }
    if !ItemID.IsValid(id) {
      return ItemID.None();
    }
    ts.RemoveItemFromSlot(mech, slot);

    let none: wref<ItemObject>;
    let ok = ts.AddItemToSlot(mech, slot, id, false, none, ERenderingPlane.RPl_Scene, false, true);
    return ok ? id : ItemID.None();
  }

  public static func ItemTag(id: ItemID) -> String {
    return TDBID.ToStringDEBUG(ItemID.GetTDBID(id)) + " #" + ToString(ItemID.GetRngSeed(id));
  }

  private static func Carried(ts: ref<TransactionSystem>, mech: ref<NPCPuppet>, rec: TweakDBID, taken: ItemID) -> ItemID {
    let items: array<wref<gameItemData>>;
    ts.GetItemList(mech, items);
    for it in items {
      if ItemID.GetTDBID(it.GetID()) == rec && it.GetID() != taken {
        return it.GetID();
      }
    }
    let none: ItemID;
    return none;
  }

  private static func CycleOf(game: GameInstance, g: ref<CMGun>) -> Float {
    if g.spec.cycle > 0.0 {
      return g.spec.cycle;
    }
    if IsDefined(g.weapon) {
      let c = GameInstance.GetStatsSystem(game).GetStatValue(Cast<StatsObjectID>(g.weapon.GetEntityID()), gamedataStatType.CycleTime);
      if c > 0.03 && c < 1.0 {
        return c;
      }
    }
    return 0.1;
  }

  public func Describe() -> String = this.m_names

  public func Refresh(mech: ref<NPCPuppet>) -> Bool {
    if (this.left.Ready() || this.left.destroyed) && (this.right.Ready() || this.right.destroyed) {
      return false;
    }
    let ts = GameInstance.GetTransactionSystem(mech.GetGame());
    let r = ScriptedPuppet.GetWeaponRight(mech);
    let l = ScriptedPuppet.GetWeaponLeft(mech);

    if !IsDefined(r) || !this.right.Holds(r) {
      r = ts.GetItemInSlot(mech, t"AttachmentSlots.WeaponRight") as WeaponObject;
    }
    if !IsDefined(l) || !this.left.Holds(l) {
      l = ts.GetItemInSlot(mech, t"AttachmentSlots.WeaponLeft") as WeaponObject;
    }
    let back = false;
    if !this.right.Ready() && !this.right.destroyed && IsDefined(r) && this.right.Holds(r) {
      this.right.weapon = r;
      back = true;
    }
    if !this.left.Ready() && !this.left.destroyed && IsDefined(l) && this.left.Holds(l) {
      this.left.weapon = l;
      back = true;
    }

    if !this.left.Ready() && !this.left.destroyed && this.right.Ready() && this.left.Holds(this.right.weapon) && !TDBID.IsValid(this.left.spec.item) {
      this.left.weapon = this.right.weapon;
      back = true;
    }
    if !this.right.Ready() && !this.right.destroyed && this.left.Ready() && this.right.Holds(this.left.weapon) && !TDBID.IsValid(this.right.spec.item) {
      this.right.weapon = this.left.weapon;
      back = true;
    }
    this.m_names = "L " + CMPilotGuns.ItemName(this.left.weapon) + "  R " + CMPilotGuns.ItemName(this.right.weapon);
    return back;
  }

  private let m_speedMods: array<ref<gameStatModifierData>>;
  private let m_speedIDs: array<StatsObjectID>;

  public func SpeedUp(game: GameInstance, ownSpeed: Bool) -> String {
    this.SlowDown(game);
    let stats = GameInstance.GetStatsSystem(game);
    let note = "";
    let guns: array<ref<CMGun>> = [this.left];
    if this.right.weapon != this.left.weapon {
      ArrayPush(guns, this.right);
    }
    for g in guns {
      let w = g.weapon;
      let mult = ownSpeed ? 1.0 : g.spec.roundSpeed;
      if IsDefined(w) {
        let id = Cast<StatsObjectID>(w.GetEntityID());
        let before = stats.GetStatValue(id, gamedataStatType.SmartGunNPCProjectileVelocity);
        for t in [gamedataStatType.SmartGunNPCProjectileVelocity, gamedataStatType.SmartGunPlayerProjectileVelocity] {
          let mod = RPGManager.CreateStatModifier(t, gameStatModifierType.Multiplier, mult);
          stats.AddModifier(id, mod);
          ArrayPush(this.m_speedMods, mod);
          ArrayPush(this.m_speedIDs, id);
        }
        note += (StrLen(note) > 0 ? "  " : "") + "NPC round velocity " + FloatToStringPrec(before, 1) + " -> " + FloatToStringPrec(stats.GetStatValue(id, gamedataStatType.SmartGunNPCProjectileVelocity), 1);

        let rec = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(w.GetItemID()));
        if IsDefined(rec) && IsDefined(rec.Evolution()) {
          note += " (" + EnumValueToString("gamedataWeaponEvolution", Cast<Int64>(EnumInt(rec.Evolution().Type()))) + ")";
        }
      }
    }
    return note;
  }

  public func SlowDown(game: GameInstance) -> Void {
    let stats = GameInstance.GetStatsSystem(game);
    let i = 0;
    while i < ArraySize(this.m_speedMods) {
      stats.RemoveModifier(this.m_speedIDs[i], this.m_speedMods[i]);
      i += 1;
    }
    ArrayClear(this.m_speedMods);
    ArrayClear(this.m_speedIDs);
  }

  private func Cycle(g: ref<CMGun>) -> Float = g.cycle / MaxF(0.2, this.rate)

  public static func ItemName(w: wref<WeaponObject>) -> String {
    if !IsDefined(w) {
      return "NONE";
    }
    return CMPilotGuns.ItemTag(w.GetItemID());
  }

  public func Update(mech: ref<NPCPuppet>, now: Float, dt: Float, lmb: Bool, rmb: Bool, mode: Int32, aim: Vector4, camPos: Vector4) -> Int32 {
    this.Cool(this.left, now, dt);
    this.Cool(this.right, now, dt);
    let shots = 0;
    if mode == CMFireMode.Split() {
      if lmb && this.TryFire(mech, this.left, now, aim, camPos) { shots += 1; }
      if rmb && this.TryFire(mech, this.right, now, aim, camPos) { shots += 1; }
      return shots;
    }
    if !lmb {
      return 0;
    }
    if mode == CMFireMode.Together() {
      if this.TryFire(mech, this.left, now, aim, camPos) { shots += 1; }
      if this.right.weapon != this.left.weapon {
        if this.TryFire(mech, this.right, now, aim, camPos) { shots += 1; }
      }
      return shots;
    }

    let first = this.m_turnLeft ? this.left : this.right;
    let second = this.m_turnLeft ? this.right : this.left;
    let half = this.Cycle(first) * 0.5;
    if this.CanFire(first, now) && this.TryFire(mech, first, now, aim, camPos) {
      second.nextShot = MaxF(second.nextShot, now + half);
      this.m_turnLeft = !this.m_turnLeft;
      return 1;
    }
    if !this.CanFire(first, now) && (first.locked || !first.Ready()) && this.TryFire(mech, second, now, aim, camPos) {
      return 1;
    }
    return 0;
  }

  public func BarrelPoint(g: ref<CMGun>, dist: Float) -> Vector4 {
    if !g.Ready() {
      return new Vector4(0.0, 0.0, 0.0, 1.0);
    }
    let o = g.weapon.GetWorldPosition();
    let f = g.weapon.GetWorldForward();
    let d = ClampF(dist, 5.0, 400.0);
    return new Vector4(o.X + f.X * d, o.Y + f.Y * d, o.Z + f.Z * d, 1.0);
  }

  private func CanFire(g: ref<CMGun>, now: Float) -> Bool {
    return g.Ready() && !g.locked && !g.offAim && now >= g.nextShot;
  }

  private func TryFire(mech: ref<NPCPuppet>, g: ref<CMGun>, now: Float, aim: Vector4, camPos: Vector4) -> Bool {
    if !this.CanFire(g, now) {
      return false;
    }
    let cycle = this.Cycle(g);
    let spreadDeg = g.spec.spreadDeg;

    let at = g.ownTarget ? g.target : aim;
    let dist = Vector4.Distance(g.ownTarget ? g.weapon.GetWorldPosition() : camPos, at);
    let r = dist * Deg2Rad(spreadDeg * (1.0 + g.heat * 1.5));
    let target = new Vector4(at.X + RandRangeF(-r, r), at.Y + RandRangeF(-r, r), at.Z + RandRangeF(-r, r) * 0.6, 1.0);

    let owner: ref<GameObject> = mech;
    if this.ownerV {
      owner = GetPlayer(mech.GetGame());
    }
    AIWeapon.Fire(owner, g.weapon, now, 0.0, gamedataTriggerMode.FullAuto, target);
    this.fired += 1;
    if this.trace {
      ArrayPush(this.roundFrom, g.weapon.GetWorldPosition());
      ArrayPush(this.roundTo, target);
    }
    g.nextShot = now + cycle;
    g.lastShot = now;
    g.flash = 0.06;
    g.heat = MinF(1.0, g.heat + g.spec.heatPerShot);
    if g.heat >= 1.0 {
      g.locked = true;
    }
    return true;
  }

  private func Cool(g: ref<CMGun>, now: Float, dt: Float) -> Void {
    if g.flash > 0.0 {
      g.flash = MaxF(0.0, g.flash - dt);
    }
    if now - g.lastShot < g.spec.coolDelay && !g.locked {
      return;
    }
    g.heat = MaxF(0.0, g.heat - g.spec.coolRate * dt);
    if g.locked && g.heat <= g.spec.unlockAt {
      g.locked = false;
    }
  }
}
