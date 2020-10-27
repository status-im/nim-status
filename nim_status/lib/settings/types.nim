
import options, json, json_serialization
import  json_serialization/[reader, writer, lexer]
import utils
import web3/[conversions, ethtypes]


type
  SettingsError* = object of CatchableError

  SettingsType* {.pure.} = enum
    Address = "address",
    ChaosMode = "chaos-mode?",
    Currency = "currency",
    CustomBootNodes = "custom-bootnodes",
    CustomBootNodesEnabled = "custom-bootnodes-enabled?",
    DappsAddress = "dapps-address",
    EIP1581Address = "eip1581-address",
    Fleet = "fleet",
    HideHomeToolTip = "hide-home-tooltip?",
    InstallationId = "installation-id",
    KeyUID = "key-uid",
    KeyCard_InstanceUID = "keycard-instance_uid",
    Keycard_PairedOn = "keycard-paired_on",
    Keycard_Pairing = "keycard-pairing",
    LastUpdated = "last-updated",
    LatestDerivedPath = "latest-derived-path",
    LogLevel = "log-level",
    Mnemonic = "mnemonic",
    Name = "name",
    CurrentNetwork = "networks/current-network",
    Networks = "networks/networks",
    NodeConfig = "node-config",
    NotificationsEnabled = "notifications-enabled?",
    PhotoPath = "photo-path",
    PinnedMailservers = "pinned-mailservers",
    PreferredName = "preferred-name",
    PreviewPrivacy = "preview-privacy?",
    PublicKey = "public-key",
    RememberSyncingChoice = "remember-syncing-choice?",
    RemotePushNotificationsEnabled = "remote-push-notifications-enabled?",
    PushNotificationsServerEnabled = "push-notifications-server-enabled?",
    PushNotificationsFromContactsOnly = "push-notifications-from-contacts-only?",
    PushNotificationsBlockMentions = "push-notifications-block-mentions?",
    SendPushNotifications = "send-push-notifications?",
    SigningPhrase = "signing-phrase",
    StickersPacksInstalled = "stickers/packs-installed",
    StickersPacksPending = "stickers/packs-pending",
    StickersRecentStickers = "stickers/recent-stickers",
    SyncingOnMobileNetwork = "syncing-on-mobile-network?",
    UseMailservers = "use-mailservers?",
    Usernames = "usernames",
    WalletRootAddress = "wallet-root-address",
    WalletSetUpPassed = "wallet-set-up-passed?",
    WalletVisibleTokens = "wallet/visible-tokens",
    Appearance = "appearance",
    WakuEnabled = "waku-enabled"
    WakuBloomFilterMode = "waku-bloom-filter-mode",
    WebviewAllowPermissionRequests = "webview-allow-permission-requests?"
 
  Settings* = object
    userAddress* {.serializedFieldName($SettingsType.Address).}: Address 
    chaosMode* {.serializedFieldName($SettingsType.ChaosMode).}: Option[bool]
    currency* {.serializedFieldName($SettingsType.Currency).}: Option[string]
    currentNetwork* {.serializedFieldName($SettingsType.CurrentNetwork).}: string
    customBootnodes* {.dontSerialize, serializedFieldName($SettingsType.CustomBootnodes).}: Option[JsonNode]
    customBootnodesEnabled* {.dontSerialize, serializedFieldName($SettingsType.CustomBootnodesEnabled).}: Option[JsonNode]
    dappsAddress* {.serializedFieldName($SettingsType.DappsAddress).}: Address
    eip1581Address* {.serializedFieldName($SettingsType.EIP1581Address).}: Address
    fleet* {.dontSerialize, serializedFieldName($SettingsType.Fleet).}: Option[string]
    hideHomeTooltip* {.dontSerialize, serializedFieldName($SettingsType.HideHomeTooltip).}: Option[bool]
    installationID* {.serializedFieldName($SettingsType.InstallationID).}: string
    keyUID* {.serializedFieldName($SettingsType.KeyUID).}: string
    keycardInstanceUID* {.serializedFieldName($SettingsType.Keycard_InstanceUID).}: Option[string]
    keycardPairedOn* {.serializedFieldName($SettingsType.Keycard_PairedOn).}: Option[int64]
    keycardPairing* {.serializedFieldName($SettingsType.Keycard_Pairing).}: Option[string]
    lastUpdated* {.dontSerialize, serializedFieldName($SettingsType.LastUpdated).}: Option[int64]
    latestDerivedPath* {.serializedFieldName($SettingsType.LatestDerivedPath).}: uint
    logLevel* {.dontSerialize, serializedFieldName($SettingsType.LogLevel).}: Option[string]
    mnemonic* {.serializedFieldName($SettingsType.Mnemonic).}: Option[string]
    name* {.serializedFieldName($SettingsType.Name).}: Option[string]
    networks* {.serializedFieldName($SettingsType.Networks).}: JsonNode
    # NotificationsEnabled indicates whether local notifications should be enabled (android only)
    notificationsEnabled* {.dontSerialize, serializedFieldName($SettingsType.NotificationsEnabled).}: Option[bool]
    photoPath* {.serializedFieldName($SettingsType.PhotoPath).}: string
    pinnedMailservers* {.dontSerialize, serializedFieldName($SettingsType.PinnedMailservers).}: Option[JsonNode]
    preferredName* {.dontSerialize, serializedFieldName($SettingsType.PreferredName).}: Option[string]
    previewPrivacy* {.serializedFieldName($SettingsType.PreviewPrivacy).}: bool
    publicKey* {.serializedFieldName($SettingsType.PublicKey).}: string
    # PushNotificationsServerEnabled indicates whether we should be running a push notification server
    pushNotificationsServerEnabled* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsServerEnabled).}: Option[bool]
    # PushNotificationsFromContactsOnly indicates whether we should only receive push notifications from contacts
    pushNotificationsFromContactsOnly* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsFromContactsOnly).}: Option[bool]
    # PushNotificationsBlockMentions indicates whether we should receive notifications for mentions
    pushNotificationsBlockMentions* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsBlockMentions).}: Option[bool]
    rememberSyncingChoice* {.dontSerialize, serializedFieldName($SettingsType.RememberSyncingChoice).}: Option[bool]
    # RemotePushNotificationsEnabled indicates whether we should be using remote notifications (ios only for now)
    remotePushNotificationsEnabled* {.dontSerialize, serializedFieldName($SettingsType.RemotePushNotificationsEnabled).}: Option[bool]
    signingPhrase* {.serializedFieldName($SettingsType.SigningPhrase).}: string
    stickerPacksInstalled* {.dontSerialize, serializedFieldName($SettingsType.StickersPacksInstalled).}: Option[JsonNode]
    stickersPacksPending* {.dontSerialize, serializedFieldName($SettingsType.StickersPacksPending).}: Option[JsonNode]
    stickersRecentStickers* {.dontSerialize, serializedFieldName($SettingsType.StickersRecentStickers).}: Option[JsonNode]
    syncingOnMobileNetwork* {.dontSerialize, serializedFieldName($SettingsType.SyncingOnMobileNetwork).}: Option[bool]
    # SendPushNotifications indicates whether we should send push notifications for other clients
    sendPushNotifications* {.dontSerialize, serializedFieldName($SettingsType.SendPushNotifications).}: Option[bool]
    appearance* {.dontSerialize, serializedFieldName($SettingsType.Appearance).}: uint
    useMailservers* {.dontSerialize, serializedFieldName($SettingsType.UseMailservers).}: bool
    usernames* {.dontSerialize, serializedFieldName($SettingsType.Usernames).}: Option[JsonNode]
    walletRootAddress* {.serializedFieldName($SettingsType.WalletRootAddress).}: Option[Address]
    walletSetUpPassed* {.dontSerialize, serializedFieldName($SettingsType.WalletSetUpPassed).}: Option[bool]
    walletVisibleTokens* {.dontSerialize, serializedFieldName($SettingsType.WalletVisibleTokens).}: Option[JsonNode]
    wakuEnabled* {.dontSerialize, serializedFieldName($SettingsType.WakuEnabled).}: Option[bool]
    wakuBloomFilterMode* {.dontSerialize, serializedFieldName($SettingsType.WakuBloomFilterMode).}: Option[bool]
    webViewAllowPermissionRequests* {.dontSerialize, serializedFieldName($SettingsType.WebviewAllowPermissionRequests).}: Option[bool]


proc writeValue*(writer: var JsonWriter, value: Settings) =
  writer.beginRecord()
  for key, val in fieldPairs(value):
    when val is Option:
      if val.isSome:
        writer.writeField $key, val.get()
    else:
      writer.writeField $key, $val
  writer.endRecord()


proc readValue*[T](reader: var JsonReader, value: var Option[T]) =
  let tok = reader.lexer.tok
  if tok == tkNull:
    reset value
    reader.lexer.next()
  else:
    let v = reader.readValue(T)
    if v == default(T):
      reset value
    else:
      value = some v

proc `$`*(self: Settings): string =
  return Json.encode(self)
