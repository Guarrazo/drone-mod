module DroneCompanion

public final abstract class DroneGearFilter {
  public static func Category() -> ItemFilterCategory = ItemFilterCategory.SoftwareMods

  public static func Matches(data: wref<gameItemData>) -> Bool {
    if !IsDefined(data) {
      return false;
    }
    return data.HasTag(n"DroneCompanionGear");
  }
}

@wrapMethod(ItemCategoryFliter)
public final static func IsOfCategoryType(filter: ItemFilterCategory, data: wref<gameItemData>) -> Bool {
  if Equals(filter, DroneGearFilter.Category()) {
    return DroneGearFilter.Matches(data);
  }
  return wrappedMethod(filter, data);
}

@wrapMethod(UIInventoryItem)
public func GetFilterCategory() -> ItemFilterCategory {
  if DroneGearFilter.Matches(this.GetRealItemData()) {
    return DroneGearFilter.Category();
  }
  return wrappedMethod();
}

@wrapMethod(ItemFilterCategories)
public final static func GetLabelKey(filterType: ItemFilterCategory) -> CName {
  if Equals(filterType, DroneGearFilter.Category()) {
    return n"Drones";
  }
  return wrappedMethod(filterType);
}

@wrapMethod(ItemFilterCategories)
public final static func GetIcon(filterType: ItemFilterCategory) -> String {
  if Equals(filterType, DroneGearFilter.Category()) {
    return "UIIcon.dc_filter";
  }
  return wrappedMethod(filterType);
}
