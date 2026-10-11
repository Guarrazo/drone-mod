module ControllableMechs.Control

import ControllableMechs.*

public class CMAnimDriver {
  private let m_action: Int32;
  private let m_rearm: Bool;
  private let m_posed: CName;

  public static func Make(game: GameInstance) -> ref<CMAnimDriver> {
    return new CMAnimDriver();
  }

  public static func Forward() -> Int32 = 3
  public static func Back() -> Int32 = 6
  public static func Left() -> Int32 = 8
  public static func Right() -> Int32 = 9

  public static func Name(action: Int32) -> String {
    switch action {
      case 0: return "idle";
      case 3: return "walk_0";
      case 6: return "walk_180";
      case 8: return "walk_270";
      case 9: return "walk_090";
      default: return "clip " + IntToString(action);
    }
  }

  public static func Row(action: Int32) -> CName {
    switch action {
      case 3: return n"MNC_Walk0";
      case 6: return n"MNC_Walk180";
      case 8: return n"MNC_Walk270";
      case 9: return n"MNC_Walk090";
      default: return n"";
    }
  }

  public static func Speed(action: Int32) -> Float = (action == 8 || action == 9) ? 0.9333 : 1.3067

  public func Tick(mech: ref<NPCPuppet>, action: Int32, now: Float) -> Void {
    if action != this.m_action {
      let was = this.m_action;
      this.m_action = action;
      this.m_rearm = false;
      if action > 0 {
        if was > 0 {
          this.Ask(mech, CMAnimDriver.Row(was), 0, 0.0);
          this.m_rearm = true;
        } else {
          this.Ask(mech, CMAnimDriver.Row(action), 2, -1.0);
        }
      }
      return;
    }
    if this.m_rearm && action > 0 {
      this.m_rearm = false;
      this.Ask(mech, CMAnimDriver.Row(action), 2, -1.0);
    }
  }

  public func Stop(mech: ref<NPCPuppet>, now: Float) -> Void {
    if this.m_action == 0 {
      return;
    }
    this.Ask(mech, CMAnimDriver.Row(this.m_action), 0, 0.0);
    this.m_action = 0;
    this.m_rearm = false;
  }

  public func Pose(mech: ref<NPCPuppet>, row: CName, state: Int32, duration: Float, now: Float) -> Void {
    this.m_posed = row;
    this.Ask(mech, row, state, duration);
  }

  public func Clear(mech: ref<NPCPuppet>, now: Float) -> Void {
    if Equals(this.m_posed, n"") {
      return;
    }
    this.Ask(mech, this.m_posed, 0, 0.0);
    this.m_posed = n"";
  }

  public func Posed() -> Bool = NotEquals(this.m_posed, n"")

  private func Ask(mech: ref<NPCPuppet>, row: CName, state: Int32, duration: Float) -> Void {
    let f = new animAnimFeature_AIActionAnimation();
    f.animFeatureName = row;
    f.state = state;
    f.stateDuration = duration;
    AnimationControllerComponent.ApplyFeature(mech, n"ActionAnimation", f);
  }
}
