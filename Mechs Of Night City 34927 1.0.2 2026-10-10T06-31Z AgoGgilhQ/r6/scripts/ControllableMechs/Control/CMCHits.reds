module ControllableMechs.Control

import ControllableMechs.*

@addField(GameObject)
public let m_cmRoundDmg: Float;

@addField(WeaponObject)
public let m_cmPiloted: Bool;

@addField(WeaponObject)
public let m_cmCreditV: Bool;

@wrapMethod(DamageSystem)
private final func ProcessPipeline(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
  let w = hitEvent.attackData.GetWeapon();

  let unitCar = hitEvent.target as VehicleObject;
  let unit = hitEvent.attackData.GetInstigator() as ScriptedPuppet;
  if IsDefined(unitCar) && IsDefined(unit) && unit.m_cmPiloted && (!IsDefined(w) || !w.m_cmPiloted) {
    let session = CMCSession.Get(unit.GetGame());
    if IsDefined(session) && session.CreditV() {
      hitEvent.attackData.SetInstigator(GetPlayer(unit.GetGame()));
    }
    let unitPools = GameInstance.GetStatPoolsSystem(unit.GetGame());
    let unitBefore = unitPools.GetStatPoolValue(Cast<StatsObjectID>(unitCar.GetEntityID()), gamedataStatPoolType.Health, true);
    wrappedMethod(hitEvent, cache);
    if !CMPilotSystem.Get(unit.GetGame()).ShowDebug() {
      return;
    }
    return;
  }
  if !IsDefined(w) || !w.m_cmPiloted {

    let ours = CMCHits.OurDrone(hitEvent);
    let oursBefore = 0.0;
    if IsDefined(ours) {
      oursBefore = GameInstance.GetStatPoolsSystem(ours.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(ours.GetEntityID()), gamedataStatPoolType.Health, true);
    }

    let rt = hitEvent.target;
    let roundHit = IsDefined(rt) && rt.m_cmRoundDmg > 0.0 && !IsDefined(hitEvent.attackData.GetWeapon());
    let roundBefore = 0.0;
    if roundHit {
      roundBefore = GameInstance.GetStatPoolsSystem(rt.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(rt.GetEntityID()), gamedataStatPoolType.Health, false);
      if IsDefined(hitEvent.attackComputed) {
        let vals = hitEvent.attackComputed.GetAttackValues();
        let vi = 0;
        while vi < ArraySize(vals) {
          vals[vi] = vi == 0 ? rt.m_cmRoundDmg : 0.0;
          vi += 1;
        }
        hitEvent.attackComputed.SetAttackValues(vals);
      }
    }
    wrappedMethod(hitEvent, cache);
    if roundHit {
      rt.m_cmRoundDmg = 0.0;
    }
    if IsDefined(ours) {
      CMCHits.DroneHitLog(ours, hitEvent, oursBefore);
    }

    let test = hitEvent.target as ScriptedPuppet;
    if IsDefined(test) && test.m_cmTestTarget {
      CMCHits.Landed(test.GetGame(), hitEvent);
    }
    return;
  }
  if w.m_cmCreditV {
    let player = GetPlayer(w.GetGame());
    if IsDefined(player) {
      hitEvent.attackData.SetInstigator(player);
    }
  }

  if w.m_cmHmg {
    if IsDefined(hitEvent.target as NPCPuppet) {
      CMCHits.CountProjectileHit(w.GetGame());
    }
    if IsDefined(hitEvent.target as VehicleObject) {
      CMCHits.CountVehicleHit(w.GetGame());
    }
  }

  let car = hitEvent.target as VehicleObject;
  let pools = GameInstance.GetStatPoolsSystem(w.GetGame());
  let carBefore = -1.0;
  if w.m_cmPlasma && IsDefined(car) {
    carBefore = pools.GetStatPoolValue(Cast<StatsObjectID>(car.GetEntityID()), gamedataStatPoolType.Health, true);
  }
  wrappedMethod(hitEvent, cache);
  if carBefore >= 0.0 && CMPilotSystem.Get(w.GetGame()).ShowDebug() {
  }
  CMCHits.Landed(w.GetGame(), hitEvent);
  if w.m_cmHmg {
    CMCHits.AddDamage(w.GetGame(), hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health));
    CMCHits.Heft(w, hitEvent);
  }
}

@addField(NPCPuppet)
public let m_cmKnockAt: Float;

public class CMCRagdollPush extends DelayCallback {
  public let npc: wref<NPCPuppet>;
  public let at: Vector4;
  public let impulse: Vector4;

  public func Call() -> Void {
    if IsDefined(this.npc) {
      this.npc.QueueEvent(CreateRagdollApplyImpulseEvent(this.at, this.impulse, 10000.0));
    }
  }
}

@addField(WeaponObject)
public let m_cmHmg: Bool;

@addField(WeaponObject)
public let m_cmPlasma: Bool;

@addField(WeaponObject)
public let m_cmFieldHmg: Bool;

@wrapMethod(DamageSystem)
private final func CalculateSourceModifiers(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
  wrappedMethod(hitEvent, cache);
  let w = hitEvent.attackData.GetWeapon();
  if IsDefined(w) && w.m_cmPiloted && w.m_cmHmg {
    let cfg = CMPilotSystem.Get(w.GetGame());

    let k = w.m_cmPlasma ? 7.64 * Cast<Float>(cfg.PlasmaDmgPct()) / 100.0
      : (w.m_cmFieldHmg ? 0.15 * (1.0 - Cast<Float>(cfg.FieldHmgCutPct()) / 100.0) : 0.125 * (1.0 - Cast<Float>(cfg.Mk31CutPct()) / 100.0));
    let before = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    if AbsF(k - 1.0) > 0.001 {
      hitEvent.attackComputed.MultAttackValue(k);
    }
    if !w.m_cmPlasma && !w.m_cmFieldHmg && cfg.ShowDebug() {
    }
  }

  let from = CMCHits.OurSource(hitEvent);
  if IsDefined(from) {
    let pct = Equals(from.GetNPCType(), gamedataNPCType.Drone) ? CMKeys.DroneDamage() : CMKeys.MechDamage();
    if pct != 100 {
      hitEvent.attackComputed.MultAttackValue(Cast<Float>(pct) / 100.0);
    }
  }
  CMCShield.Apply(hitEvent);

  let ours = CMCHits.OurDrone(hitEvent);
  if IsDefined(ours) {
    hitEvent.attackComputed.MultAttackValue(CMCHits.DRONE_TAKEN());
  }
}

public abstract class CMCShield {
public static func Apply(hitEvent: ref<gameHitEvent>) -> Void {
  let mech = hitEvent.target as NPCPuppet;
  if !IsDefined(mech) || !mech.m_cmShieldUp || mech.m_cmShieldCharge <= 0.0 {
    return;
  }
  let from = hitEvent.attackData.GetAttackPosition();
  let src = hitEvent.attackData.GetInstigator();
  if IsDefined(src) {
    from = src.GetWorldPosition();
  }
  let to = from - mech.GetWorldPosition();
  to.Z = 0.0;
  if Vector4.Dot(Vector4.Normalize(to), mech.GetWorldForward()) < 0.5 {
    return;
  }
  let dmg = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
  hitEvent.attackComputed.MultAttackValue(0.2);
  mech.m_cmShieldCharge = MaxF(0.0, mech.m_cmShieldCharge - dmg * 0.8 / 1500.0);
}
}

public class CMCHits extends ScriptableSystem {
  private let m_window: Float;
  private let m_lines: Int32;

  public static func Get(game: GameInstance) -> ref<CMCHits> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"ControllableMechs.Control.CMCHits") as CMCHits;
  }

  public static func OurSource(hitEvent: ref<gameHitEvent>) -> ref<NPCPuppet> {
    let w = hitEvent.attackData.GetWeapon();
    let src: ref<NPCPuppet>;
    if IsDefined(w) {
      if !w.m_cmPiloted {
        return null;
      }
      src = w.GetOwner() as NPCPuppet;
    } else {
      let inst = hitEvent.attackData.GetInstigator();
      if !IsDefined(inst) {
        return null;
      }
      if inst.IsPlayer() {
        src = CMCHits.Blamed(inst.GetGame()) as NPCPuppet;
      } else {
        src = inst as NPCPuppet;
      }
    }
    if !IsDefined(src) || (IsDefined(hitEvent.target) && hitEvent.target.GetEntityID() == src.GetEntityID()) {
      return null;
    }
    if src.m_cmPiloted {
      return src;
    }
    let out = CMFleet.Get(src.GetGame()).OutUnit();
    return IsDefined(out) && out.GetEntityID() == src.GetEntityID() ? src : null;
  }

  public static func Landed(game: GameInstance, hit: ref<gameHitEvent>) -> Void {
    let data = hit.attackData;
    if !data.HasFlag(hitFlag.DealNoDamage) {
      let session = CMCSession.Get(game);
      if IsDefined(session) {
        session.RoundHit(data.HasFlag(hitFlag.WasKillingBlow));
      }
    }
    if !CMPilotSystem.Get(game).ShowDebug() {
      return;
    }
    let sys = CMCHits.Get(game);
    if !IsDefined(sys) || !sys.Allow(EngineTime.ToFloat(GameInstance.GetEngineTime(game))) {
      return;
    }
    let cancelled = "";
    if data.HasFlag(hitFlag.DealNoDamage) {
      cancelled += " DealNoDamage";
    }
    if data.HasFlag(hitFlag.FriendlyFireIgnored) {
      cancelled += " FriendlyFireIgnored";
    }
    let target = hit.target as GameObject;
    let instigator = data.GetInstigator();
  }

  private let m_projHits: Int32;
  private let m_carHits: Int32;

  public static func CountVehicleHit(game: GameInstance) -> Void {
    let sys = CMCHits.Get(game);
    if IsDefined(sys) {
      sys.m_carHits += 1;
    }
  }

  private let m_damage: Float;

  public static func AddDamage(game: GameInstance, d: Float) -> Void {
    let sys = CMCHits.Get(game);
    if IsDefined(sys) {
      sys.m_damage += d;
    }
  }

  public static func CountProjectileHit(game: GameInstance) -> Void {
    let sys = CMCHits.Get(game);
    if IsDefined(sys) {
      sys.m_projHits += 1;
    }
  }

  private static func KNOCK_CHANCE(heavy: Bool) -> Float = heavy ? 0.3 : 0.04
  private static func KNOCK_COOLDOWN(heavy: Bool) -> Float = heavy ? 2.5 : 8.0
  private static func KILL_PUSH(heavy: Bool) -> Float = heavy ? 55.0 : 12.0

  public static func Heft(w: ref<WeaponObject>, hit: ref<gameHitEvent>) -> Void {
    let npc = hit.target as NPCPuppet;
    if !IsDefined(npc) || NotEquals(npc.GetNPCType(), gamedataNPCType.Human) || hit.attackData.HasFlag(hitFlag.DealNoDamage) {
      return;
    }
    let heavy = w.m_cmFieldHmg || w.m_cmPlasma;
    let game = w.GetGame();
    let away = npc.GetWorldPosition() - w.GetWorldPosition();
    away.Z = 0.0;
    away = Vector4.Normalize(away);
    if hit.attackData.HasFlag(hitFlag.WasKillingBlow) || !ScriptedPuppet.IsAlive(npc) {

      npc.QueueEvent(CreateForceRagdollEvent(n"CM_HMG"));
      let push = new CMCRagdollPush();
      push.npc = npc;
      push.at = hit.hitPosition;
      push.impulse = away * (CMCHits.KILL_PUSH(heavy) * 0.8);
      push.impulse.Z += CMCHits.KILL_PUSH(heavy) * 0.2;
      GameInstance.GetDelaySystem(game).DelayCallback(push, 0.1, false);
      return;
    }
    let now = EngineTime.ToFloat(GameInstance.GetEngineTime(game));
    if now - npc.m_cmKnockAt > CMCHits.KNOCK_COOLDOWN(heavy) && RandF() < CMCHits.KNOCK_CHANCE(heavy) {
      npc.m_cmKnockAt = now;
      StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.Knockdown");
    }
  }

  private let m_blamed: wref<GameObject>;
  private let m_blameUntil: Float;

  public static func Blame(unit: wref<GameObject>, seconds: Float) -> Void {
    let sys = CMCHits.Get(unit.GetGame());
    if IsDefined(sys) {
      sys.m_blamed = unit;
      sys.m_blameUntil = EngineTime.ToFloat(GameInstance.GetEngineTime(unit.GetGame())) + seconds;
    }
  }

  public static func Blamed(game: GameInstance) -> wref<GameObject> {
    let sys = CMCHits.Get(game);
    if IsDefined(sys) && IsDefined(sys.m_blamed) && EngineTime.ToFloat(GameInstance.GetEngineTime(game)) < sys.m_blameUntil {
      return sys.m_blamed;
    }
    return null;
  }

  public static func DRONE_TAKEN() -> Float = 3.0

  public static func OurDrone(hitEvent: ref<gameHitEvent>) -> ref<NPCPuppet> {
    let d = hitEvent.target as NPCPuppet;
    if !IsDefined(d) || NotEquals(d.GetNPCType(), gamedataNPCType.Drone) {
      return null;
    }
    let src = hitEvent.attackData.GetInstigator();
    if IsDefined(src) && (src.IsPlayer() || src.GetEntityID() == d.GetEntityID()) {
      return null;
    }
    if !CMLinkSystem.Get(d.GetGame()).IsLinkedTo(d.GetEntityID()) {
      return null;
    }
    return d;
  }

  public static func DroneHitLog(d: ref<NPCPuppet>, hitEvent: ref<gameHitEvent>, before: Float) -> Void {
    let after = GameInstance.GetStatPoolsSystem(d.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(d.GetEntityID()), gamedataStatPoolType.Health, true);
  }

  private func Allow(now: Float) -> Bool {
    if now - this.m_window > 5.0 {
      this.m_window = now;
      this.m_lines = 0;
    }
    this.m_lines += 1;
    return this.m_lines <= 25;
  }

  public static func Describe(obj: ref<GameObject>) -> String {
    if !IsDefined(obj) {
      return "nothing";
    }
    let s = NameToString(obj.GetClassName());
    let puppet = obj as ScriptedPuppet;
    if IsDefined(puppet) {
      s += " " + TDBID.ToStringDEBUG(puppet.GetRecordID());
    }
    let a = GameObject.GetAttitudeBetween(obj, GetPlayer(obj.GetGame()));
    s += Equals(a, EAIAttitude.AIA_Friendly) ? " (friendly to V)" : (Equals(a, EAIAttitude.AIA_Hostile) ? " (hostile to V)" : " (neutral to V)");
    return s;
  }

  public static func V(v: Vector4) -> String {
    return "(" + FloatToStringPrec(v.X, 1) + ", " + FloatToStringPrec(v.Y, 1) + ", " + FloatToStringPrec(v.Z, 1) + ")";
  }
}

@wrapMethod(RainMissileProjectile)
protected final func StartPhase1(targetPos: Vector4) -> Void {
  let first = NotEquals(EMissileRainPhase.Phase1, this.m_phase);
  wrappedMethod(targetPos);
  if first && IsDefined(this.m_weapon) && this.m_weapon.m_cmPiloted {
    GameObject.PlaySoundEvent(this, n"nme_boss_smasher_wpn_missile_flight_death_rain");
  }
}

@wrapMethod(RainMissileProjectile)
private final func Explode(projectilePosition: Vector4) -> Void {
  let was = this.m_hasExploded;
  wrappedMethod(projectilePosition);
  if !was && this.m_hasExploded && IsDefined(this.m_weapon) && this.m_weapon.m_cmPiloted {
    GameObject.PlaySoundEvent(this, n"nme_boss_smasher_wpn_missile_xplo");
  }
}
