module DroneCompanion

public class DCPhoneData extends JournalNotificationData {
  public let contactHash: Int32;
}

public class DCPhoneChoice {
  public let id: String;
  public let label: String;
}

@addField(PlayerPuppet)
let m_dcPhoneChoices: String;

@addMethod(PlayerPuppet)
public func DCSetPhoneChoices(encoded: String) -> Void {
  this.m_dcPhoneChoices = encoded;
}

public abstract class DCPhone {
  public static func Hash() -> Int32 = 218891;

  public static func IsOurs(hash: Int32) -> Bool {
    return hash == DCPhone.Hash();
  }

  public static func Choices(game: GameInstance) -> array<ref<DCPhoneChoice>> {
    let out: array<ref<DCPhoneChoice>>;
    let player = GetPlayer(game) as PlayerPuppet;
    if !IsDefined(player) || StrLen(player.m_dcPhoneChoices) == 0 {
      return out;
    };
    let parts = StrSplit(player.m_dcPhoneChoices, "|");
    let i = 0;
    while i < ArraySize(parts) {
      let id: String;
      let label: String;
      if StrSplitFirst(parts[i], "=", id, label) && StrLen(id) > 0 && StrLen(label) > 0 {
        let choice = new DCPhoneChoice();
        choice.id = id;
        choice.label = label;
        ArrayPush(out, choice);
      };
      i += 1;
    };
    return out;
  }

  public static func Contact(game: GameInstance) -> ref<ContactData> {
    let data = new ContactData();
    data.hash = DCPhone.Hash();
    data.localizedName = DroneCompanionText("Mod-DroneCompanion-Phone-Name");
    data.contactId = "DroneCompanionRigger";
    data.id = "DroneCompanionRigger";
    data.avatarID = t"PhoneAvatars.Avatar_Unknown";
    data.questRelated = false;
    data.isCallable = false;
    data.type = MessengerContactType.SingleThread;
    data.lastMesssagePreview = DroneCompanionText("Mod-DroneCompanion-Phone-Preview");
    data.timeStamp = GameInstance.GetTimeSystem(game).GetGameTime();
    data.messagesCount = 1;
    data.unreadMessegeCount = 0;
    data.hasMessages = true;
    data.playerIsLastSender = false;
    return data;
  }

  public static func NotificationData(contactData: wref<ContactData>, source: PhoneScreenType) -> ref<DCPhoneData> {
    let data = new DCPhoneData();
    data.type = contactData.type;
    data.contactNameLocKey = StringToName(contactData.localizedName);
    data.mode = JournalNotificationMode.HUD;
    data.openedFromPhone = true;
    data.source = source;
    data.contactHash = contactData.hash;
    return data;
  }
}

@if(!ModuleExists("PhoneExtension.Classes"))
@wrapMethod(MessengerUtils)
public final static func GetSimpleContactDataArray(journal: ref<JournalManager>, includeUnknown: Bool, skipEmpty: Bool, includeWithNoUnread: Bool, opt activeDataSync: wref<MessengerContactSyncData>) -> array<ref<IScriptable>> {
  let contacts = wrappedMethod(journal, includeUnknown, skipEmpty, includeWithNoUnread, activeDataSync);
  ArrayPush(contacts, DCPhone.Contact(GetGameInstance()));
  return contacts;
}

@if(!ModuleExists("PhoneExtension.Classes"))
@wrapMethod(NewHudPhoneGameController)
public final func GotoSmsMessenger(contactData: wref<ContactData>) -> Void {
  if DCPhone.IsOurs(contactData.hash) {
    let evt = new OpenSmsMessengerEvent();
    evt.m_data = DCPhone.NotificationData(contactData, this.m_screenType);
    this.QueueEvent(evt);
  } else {
    wrappedMethod(contactData);
  };
}

@if(!ModuleExists("PhoneExtension.Classes"))
@wrapMethod(NewHudPhoneGameController)
public final func RefreshSmsMessager(contactData: wref<ContactData>) -> Void {
  if DCPhone.IsOurs(contactData.hash) {
    let evt = new RefreshSmsMessagerEvent();
    evt.m_data = DCPhone.NotificationData(contactData, this.m_screenType);
    this.QueueEvent(evt);
  } else {
    wrappedMethod(contactData);
  };
}

@if(!ModuleExists("PhoneExtension.Classes"))
@wrapMethod(PhoneMessagePopupGameController)
private final func SetFocus(isFocused: Bool) -> Void {
  if NotEquals(this.m_isFocused, isFocused) {
    let data = this.m_data as DCPhoneData;
    if IsDefined(data) && DCPhone.IsOurs(data.contactHash) {
      if isFocused {
        this.m_dialogViewController.DCShowDialog(data.contactHash);
        inkWidgetRef.SetVisible(this.m_hintCall, false);
      } else {
        this.m_dialogViewController.DCClearDialog();
      };
    };
  };
  wrappedMethod(isFocused);
}

@if(!ModuleExists("PhoneExtension.Classes"))
@wrapMethod(PhoneMessagePopupGameController)
private final func TryActivateChoice() -> Void {
  let data = this.m_data as DCPhoneData;
  if IsDefined(data) && DCPhone.IsOurs(data.contactHash) {
    if !this.m_phoneSystem.IsTextingEnabled() {
      this.ShowActionBlockedNotification();
      return;
    };
    this.m_dialogViewController.DCActivateChoice();
  } else {
    wrappedMethod();
  };
}

@if(!ModuleExists("PhoneExtension.Classes"))
@wrapMethod(MessengerDialogViewController)
public final func UpdateData(animateLastMessage: Bool, setVisited: Bool) -> Void {
  if DCPhone.IsOurs(this.m_contactHash) {
    this.DCRender();
  } else {
    wrappedMethod(animateLastMessage, setVisited);
  };
}

@if(!ModuleExists("PhoneExtension.Classes"))
@wrapMethod(MessengerDialogViewController)
public final func NavigateReplyOptions(isUp: Bool) -> Void {
  if DCPhone.IsOurs(this.m_contactHash) {
    this.m_choicesListController.DCNavigate(isUp);
  } else {
    wrappedMethod(isUp);
  };
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(MessengerDialogViewController)
public final func DCShowDialog(hash: Int32) -> Void {
  this.m_contactHash = hash;
  this.m_singleThreadMode = true;
  ArrayClear(this.m_replyOptions);
  ArrayClear(this.m_messages);
  this.UpdateData(false, true);
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(MessengerDialogViewController)
public final func DCClearDialog() -> Void {
  ArrayClear(this.m_replyOptions);
  ArrayClear(this.m_messages);
  this.m_messagesListController.Clear();
  this.m_choicesListController.Clear();
  inkCompoundRef.RemoveAllChildren(this.m_messagesList);
  inkCompoundRef.RemoveAllChildren(this.m_choicesList);
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(MessengerDialogViewController)
public final func DCRender() -> Void {
  this.DCPushMessage(DroneCompanionText("Mod-DroneCompanion-Phone-Greeting"), MessageViewType.Received, false);
  this.DCPushChoices();
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(MessengerDialogViewController)
public final func DCPushChoices() -> Void {
  let choices = DCPhone.Choices(GetGameInstance());
  let i = 0;
  while i < ArraySize(choices) {
    let widget = this.SpawnFromLocal(inkCompoundRef.Get(this.m_choicesList), n"Reply");
    let renderer = widget.GetControllerByType(n"MessangerReplyItemRenderer") as MessangerReplyItemRenderer;
    if IsDefined(renderer) {
      renderer.DCSetReply(choices[i].label, i == 0, this.m_hasFocus);
    };
    i += 1;
  };
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(MessengerDialogViewController)
public final func DCPushMessage(text: String, kind: MessageViewType, playSound: Bool) -> Void {
  let widget = this.SpawnFromLocal(inkCompoundRef.Get(this.m_messagesList), n"Message");
  let renderer = widget.GetControllerByType(n"MessangerItemRenderer") as MessangerItemRenderer;
  if IsDefined(renderer) {
    renderer.SetMessageView(text, kind, DroneCompanionText("Mod-DroneCompanion-Phone-Name"));
  };
  if playSound {
    this.m_audioSystem.Play(n"ui_messenger_recieved");
  };
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(MessengerDialogViewController)
public final func DCActivateChoice() -> Void {
  if inkCompoundRef.GetNumChildren(this.m_choicesList) == 0 {
    return;
  };
  let index = this.m_choicesListController.DCSelectedIndex();
  if index < 0 {
    return;
  };
  let choices = DCPhone.Choices(GetGameInstance());
  if index >= ArraySize(choices) {
    return;
  };
  let player = GetPlayer(GetGameInstance()) as PlayerPuppet;
  inkCompoundRef.RemoveAllChildren(this.m_choicesList);
  this.DCPushMessage(choices[index].label, MessageViewType.Sent, false);
  this.DCPushMessage(DroneCompanionText("Mod-DroneCompanion-Phone-Ack"), MessageViewType.Received, true);
  if IsDefined(player) {
    player.DCKeyCombo(choices[index].id);
  };
  this.DCPushChoices();
  this.m_audioSystem.Play(n"ui_messenger_select");
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(MessangerReplyItemRenderer)
public final func DCSetReply(text: String, isSelected: Bool, isActive: Bool) -> Void {
  inkTextRef.SetText(this.m_labelPathRef, text);
  this.m_isQuestImportant = false;
  this.m_selectedState = isSelected;
  this.m_isActive = isActive;
  this.AnimateSelection();
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(MessangerReplyItemRenderer)
public final func DCSelect(isSelected: Bool) -> Void {
  this.m_selectedState = isSelected;
  this.AnimateSelection();
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(JournalEntriesListController)
public final func DCSelectedIndex() -> Int32 {
  let root = this.GetRootCompoundWidget();
  let size = root.GetNumChildren();
  let i = 0;
  while i < size {
    let renderer = root.GetWidgetByIndex(i).GetControllerByType(n"MessangerReplyItemRenderer") as MessangerReplyItemRenderer;
    if IsDefined(renderer) && renderer.m_selectedState {
      return i;
    };
    i += 1;
  };
  return -1;
}

@if(!ModuleExists("PhoneExtension.Classes"))
@addMethod(JournalEntriesListController)
public final func DCNavigate(isUp: Bool) -> Void {
  let root = this.GetRootCompoundWidget();
  let size = root.GetNumChildren();
  let current = this.DCSelectedIndex();
  if current < 0 || size == 0 {
    return;
  };
  let next = Clamp(current + (isUp ? -1 : 1), 0, size - 1);
  if next == current {
    return;
  };
  let renderer = root.GetWidgetByIndex(current).GetControllerByType(n"MessangerReplyItemRenderer") as MessangerReplyItemRenderer;
  if IsDefined(renderer) {
    renderer.DCSelect(false);
  };
  renderer = root.GetWidgetByIndex(next).GetControllerByType(n"MessangerReplyItemRenderer") as MessangerReplyItemRenderer;
  if IsDefined(renderer) {
    renderer.DCSelect(true);
  };
}
