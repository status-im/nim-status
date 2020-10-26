
import options, json, json_serialization
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
    currency* {.dontSerialize, serializedFieldName($SettingsType.Currency).}: Option[string]
    currentNetwork* {.dontSerialize, serializedFieldName($SettingsType.CurrentNetwork).}: string
    customBootnodes* {.dontSerialize, serializedFieldName($SettingsType.CustomBootnodes).}: Option[JsonNode]
    customBootnodesEnabled* {.dontSerialize, serializedFieldName($SettingsType.CustomBootnodesEnabled).}: Option[JsonNode]
    dappsAddress* {.dontSerialize, serializedFieldName($SettingsType.DappsAddress).}: Address
    eip1581Address* {.dontSerialize, serializedFieldName($SettingsType.EIP1581Address).}: Address
    fleet* {.dontSerialize, serializedFieldName($SettingsType.Fleet).}: Option[string]
    hideHomeTooltip* {.dontSerialize, serializedFieldName($SettingsType.HideHomeTooltip).}: Option[bool]
    installationID* {.dontSerialize, serializedFieldName($SettingsType.InstallationID).}: string
    keyUID* {.dontSerialize, serializedFieldName($SettingsType.KeyUID).}: string
    keycardInstanceUID* {.dontSerialize, serializedFieldName($SettingsType.Keycard_InstanceUID).}: Option[string]
    keycardPairedOn* {.dontSerialize, serializedFieldName($SettingsType.Keycard_PairedOn).}: Option[int64]
    keycardPairing* {.dontSerialize, serializedFieldName($SettingsType.Keycard_Pairing).}: Option[string]
    lastUpdated* {.dontSerialize, serializedFieldName($SettingsType.LastUpdated).}: Option[int64]
    latestDerivedPath* {.dontSerialize, serializedFieldName($SettingsType.LatestDerivedPath).}: uint
    logLevel* {.dontSerialize, serializedFieldName($SettingsType.LogLevel).}: Option[string]
    mnemonic* {.dontSerialize, serializedFieldName($SettingsType.Mnemonic).}: Option[string]
    name* {.dontSerialize, serializedFieldName($SettingsType.Name).}: Option[string]
    networks* {.dontSerialize, serializedFieldName($SettingsType.Networks).}: JsonNode
    # NotificationsEnabled indicates whether local notifications should be enabled (android only)
    notificationsEnabled* {.dontSerialize, serializedFieldName($SettingsType.NotificationsEnabled).}: Option[bool]
    photoPath* {.dontSerialize, serializedFieldName($SettingsType.PhotoPath).}: string
    pinnedMailservers* {.dontSerialize, serializedFieldName($SettingsType.PinnedMailservers).}: Option[JsonNode]
    preferredName* {.dontSerialize, serializedFieldName($SettingsType.PreferredName).}: Option[string]
    previewPrivacy* {.dontSerialize, serializedFieldName($SettingsType.PreviewPrivacy).}: bool
    publicKey* {.dontSerialize, serializedFieldName($SettingsType.PublicKey).}: string
    # PushNotificationsServerEnabled indicates whether we should be running a push notification server
    pushNotificationsServerEnabled* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsServerEnabled).}: Option[bool]
    # PushNotificationsFromContactsOnly indicates whether we should only receive push notifications from contacts
    pushNotificationsFromContactsOnly* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsFromContactsOnly).}: Option[bool]
    # PushNotificationsBlockMentions indicates whether we should receive notifications for mentions
    pushNotificationsBlockMentions* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsBlockMentions).}: Option[bool]
    rememberSyncingChoice* {.dontSerialize, serializedFieldName($SettingsType.RememberSyncingChoice).}: Option[bool]
    # RemotePushNotificationsEnabled indicates whether we should be using remote notifications (ios only for now)
    remotePushNotificationsEnabled* {.dontSerialize, serializedFieldName($SettingsType.RemotePushNotificationsEnabled).}: Option[bool]
    signingPhrase* {.dontSerialize, serializedFieldName($SettingsType.SigningPhrase).}: string
    stickerPacksInstalled* {.dontSerialize, serializedFieldName($SettingsType.StickersPacksInstalled).}: Option[JsonNode]
    stickersPacksPending* {.dontSerialize, serializedFieldName($SettingsType.StickersPacksPending).}: Option[JsonNode]
    stickersRecentStickers* {.dontSerialize, serializedFieldName($SettingsType.StickersRecentStickers).}: Option[JsonNode]
    syncingOnMobileNetwork* {.dontSerialize, serializedFieldName($SettingsType.SyncingOnMobileNetwork).}: Option[bool]
    # SendPushNotifications indicates whether we should send push notifications for other clients
    sendPushNotifications* {.dontSerialize, serializedFieldName($SettingsType.SendPushNotifications).}: Option[bool]
    appearance* {.dontSerialize, serializedFieldName($SettingsType.Appearance).}: uint
    useMailservers* {.dontSerialize, serializedFieldName($SettingsType.UseMailservers).}: bool
    usernames* {.dontSerialize, serializedFieldName($SettingsType.Usernames).}: Option[JsonNode]
    walletRootAddress* {.dontSerialize, serializedFieldName($SettingsType.WalletRootAddress).}: Option[Address]
    walletSetUpPassed* {.dontSerialize, serializedFieldName($SettingsType.WalletSetUpPassed).}: Option[bool]
    walletVisibleTokens* {.dontSerialize, serializedFieldName($SettingsType.WalletVisibleTokens).}: Option[JsonNode]
    wakuEnabled* {.dontSerialize, serializedFieldName($SettingsType.WakuEnabled).}: Option[bool]
    wakuBloomFilterMode* {.dontSerialize, serializedFieldName($SettingsType.WakuBloomFilterMode).}: Option[bool]
    webViewAllowPermissionRequests* {.dontSerialize, serializedFieldName($SettingsType.WebviewAllowPermissionRequests).}: Option[bool]

proc `$`*(self: Settings): string =
  # echo Json.encode(self)
  var output = %* {
    $SettingsType.Address: self.userAddress,
    $SettingsType.CurrentNetwork: self.currentNetwork,
    $SettingsType.DappsAddress: self.dappsAddress,
    $SettingsType.EIP1581Address: self.eip1581Address,
    $SettingsType.InstallationID: self.installationID,
    $SettingsType.KeyUID: self.keyUID,
    $SettingsType.LatestDerivedPath: self.latestDerivedPath,
    $SettingsType.Networks: self.networks,
    $SettingsType.PhotoPath: self.photoPath,
    $SettingsType.PreviewPrivacy: self.previewPrivacy,
    $SettingsType.PublicKey: self.publicKey,
    $SettingsType.Appearance: self.appearance,
    $SettingsType.UseMailservers: self.useMailservers,
    $SettingsType.SigningPhrase: self.signingPhrase,
  }

  output.addOptionalValue($SettingsType.ChaosMode, self.chaosMode)
  output.addOptionalValue($SettingsType.Currency, self.currency)
  output.addOptionalValue($SettingsType.CustomBootNodes, self.customBootnodes)
  output.addOptionalValue($SettingsType.CustomBootnodesEnabled, self.customBootnodesEnabled)
  output.addOptionalValue($SettingsType.Fleet, self.fleet)
  output.addOptionalValue($SettingsType.HideHomeToolTip, self.hideHomeTooltip)
  output.addOptionalValue($SettingsType.KeyCard_InstanceUID, self.keycardInstanceUID)
  output.addOptionalValue($SettingsType.Keycard_PairedOn, self.keycardPairedOn)
  output.addOptionalValue($SettingsType.KeycardPairing, self.keycardPairing)
  output.addOptionalValue($SettingsType.LastUpdated, self.lastUpdated)
  output.addOptionalValue($SettingsType.LogLevel, self.logLevel)
  output.addOptionalValue($SettingsType.Mnemonic, self.mnemonic)
  output.addOptionalValue($SettingsType.Name, self.name)
  output.addOptionalValue($SettingsType.NotificationsEnabled, self.notificationsEnabled)
  output.addOptionalValue($SettingsType.PinnedMailservers, self.pinnedMailservers)
  output.addOptionalValue($SettingsType.PreferredName, self.preferredName)
  output.addOptionalValue($SettingsType.PushNotificationsServerEnabled, self.pushNotificationsServerEnabled)
  output.addOptionalValue($SettingsType.PushNotificationsFromContactsOnly, self.pushNotificationsFromContactsOnly)
  output.addOptionalValue($SettingsType.PushNotificationsBlockMentions, self.pushNotificationsBlockMentions)
  output.addOptionalValue($SettingsType.RememberSyncingChoice, self.rememberSyncingChoice)
  output.addOptionalValue($SettingsType.RemotePushNotificationsEnabled, self.remotePushNotificationsEnabled)
  output.addOptionalValue($SettingsType.StickersPacksInstalled, self.stickerPacksInstalled)
  output.addOptionalValue($SettingsType.StickersPacksPending, self.stickersPacksPending)
  output.addOptionalValue($SettingsType.StickersRecentStickers, self.stickersRecentStickers)
  output.addOptionalValue($SettingsType.SyncingOnMobileNetwork, self.syncingOnMobileNetwork)
  output.addOptionalValue($SettingsType.SendPushNotifications, self.sendPushNotifications)
  output.addOptionalValue($SettingsType.Usernames, self.usernames)
  output.addOptionalValue($SettingsType.WalletRootAddress, self.walletRootAddress)
  output.addOptionalValue($SettingsType.WalletSetUpPassed, self.walletSetUpPassed)
  output.addOptionalValue($SettingsType.WalletVisibleTokens, self.walletVisibleTokens)
  output.addOptionalValue($SettingsType.WakuEnabled, self.wakuEnabled)
  output.addOptionalValue($SettingsType.WakuBloomFilterMode, self.wakuBloomFilterMode)
  output.addOptionalValue($SettingsType.WebViewAllowPermissionRequests, self.webViewAllowPermissionRequests)

  result = $output


proc toSettings*(self: string): Settings =
  let o = self.parseJson
  result.userAddress = parseAddress(o[$SettingsType.Address].getStr)
  result.currentNetwork = o[$SettingsType.CurrentNetwork].getStr
  result.dappsAddress = parseAddress(o[$SettingsType.DappsAddress].getStr)
  result.eip1581Address = parseAddress(o[$SettingsType.EIP1581Address].getStr)
  result.installationID = o[$SettingsType.InstallationID].getStr
  result.keyUID = o[$SettingsType.KeyUID].getStr
  result.latestDerivedPath = o[$SettingsType.LatestDerivedPath].getInt.uint
  result.networks = o[$SettingsType.Networks]
  result.photoPath = o[$SettingsType.PhotoPath].getStr
  result.previewPrivacy = o[$SettingsType.PreviewPrivacy].getBool
  result.publicKey = o[$SettingsType.PublicKey].getStr
  result.appearance = o{$SettingsType.Appearance}.getInt.uint
  result.useMailservers = o{$SettingsType.UseMailservers}.getBool
  result.signingPhrase = o[$SettingsType.SigningPhrase].getStr
  result.chaosMode = getOption[bool](o, $SettingsType.ChaosMode)
  result.currency = getOption[string](o, $SettingsType.Currency)
  result.customBootnodes = getOption[JsonNode](o, $SettingsType.CustomBootNodes)
  result.customBootnodesEnabled = getOption[JsonNode](o, $SettingsType.CustomBootnodesEnabled)
  result.fleet = getOption[string](o, $SettingsType.Fleet)
  result.hideHomeTooltip = getOption[bool](o, $SettingsType.HideHomeToolTip)
  result.keycardInstanceUID = getOption[string](o, $SettingsType.KeyCard_InstanceUID)
  result.keycardPairedOn = getOption[int64](o, $SettingsType.Keycard_PairedOn)
  result.keycardPairing = getOption[string](o, $SettingsType.KeycardPairing)
  result.lastUpdated = getOption[int64](o, $SettingsType.LastUpdated)
  result.logLevel = getOption[string](o, $SettingsType.LogLevel)
  result.mnemonic = getOption[string](o, $SettingsType.Mnemonic)
  result.name = getOption[string](o, $SettingsType.Name)
  result.notificationsEnabled = getOption[bool](o, $SettingsType.NotificationsEnabled)
  result.pinnedMailservers = getOption[JsonNode](o, $SettingsType.PinnedMailservers)
  result.preferredName = getOption[string](o, $SettingsType.PreferredName)
  result.pushNotificationsServerEnabled = getOption[bool](o, $SettingsType.PushNotificationsServerEnabled)
  result.pushNotificationsFromContactsOnly = getOption[bool](o, $SettingsType.PushNotificationsFromContactsOnly)
  result.pushNotificationsBlockMentions = getOption[bool](o, $SettingsType.PushNotificationsBlockMentions)
  result.rememberSyncingChoice = getOption[bool](o, $SettingsType.RememberSyncingChoice)
  result.remotePushNotificationsEnabled = getOption[bool](o, $SettingsType.RemotePushNotificationsEnabled)
  result.stickerPacksInstalled = getOption[JsonNode](o, $SettingsType.StickersPacksInstalled)
  result.stickersPacksPending = getOption[JsonNode](o, $SettingsType.StickersPacksPending)
  result.stickersRecentStickers = getOption[JsonNode](o, $SettingsType.StickersRecentStickers)
  result.syncingOnMobileNetwork = getOption[bool](o, $SettingsType.SyncingOnMobileNetwork)
  result.sendPushNotifications = getOption[bool](o, $SettingsType.SendPushNotifications)
  result.usernames = getOption[JsonNode](o, $SettingsType.Usernames)
  result.walletRootAddress = getOption[Address](o, $SettingsType.WalletRootAddress)
  result.walletSetUpPassed = getOption[bool](o, $SettingsType.WalletSetUpPassed)
  result.walletVisibleTokens = getOption[JsonNode](o, $SettingsType.WalletVisibleTokens)
  result.wakuEnabled = getOption[bool](o, $SettingsType.WakuEnabled)
  result.wakuBloomFilterMode = getOption[bool](o, $SettingsType.WakuBloomFilterMode)
  result.webViewAllowPermissionRequests = getOption[bool](o, $SettingsType.WebViewAllowPermissionRequests)
