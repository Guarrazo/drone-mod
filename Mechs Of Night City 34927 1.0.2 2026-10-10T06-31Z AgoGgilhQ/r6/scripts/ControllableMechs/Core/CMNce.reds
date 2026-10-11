module ControllableMechs

@if(ModuleExists("NightCityEmpires"))
import NightCityEmpires.*

public abstract class CMNce {
  @if(ModuleExists("NightCityEmpires"))
  public static func Installed() -> Bool = true

  @if(!ModuleExists("NightCityEmpires"))
  public static func Installed() -> Bool = false

  @if(ModuleExists("NightCityEmpires"))
  public static func AirliftReady() -> String = NCEAirliftReady()

  @if(!ModuleExists("NightCityEmpires"))
  public static func AirliftReady() -> String = "!" + CMText.NceNeedsEmpires()

  @if(ModuleExists("NightCityEmpires"))
  public static func AirliftCallIn(unit: ref<NPCPuppet>, near: Vector4, yaw: Float) -> String = NCEAirliftCallIn(unit, near, yaw)

  @if(!ModuleExists("NightCityEmpires"))
  public static func AirliftCallIn(unit: ref<NPCPuppet>, near: Vector4, yaw: Float) -> String = "!" + CMText.NceNeedsEmpires()

}
