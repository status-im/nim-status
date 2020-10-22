
import options, json, json_serialization
import utils
import web3/[conversions, ethtypes]

type
  SettingsError* = object of CatchableError

  SettingsEnum* {.pure.} = enum
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
    WakuBloomFilterMode = "waku-bloom-filter-mode",
    WebviewAllowPermissionRequests = "webview-allow-permission-requests?"
 
  Settings* = object
    userAddress* {.serializedFieldName("address").}: Address 
    chaosMode* {.serializedFieldName("chaos-mode?").}: Option[bool]
    currency* {.serializedFieldName("currency").}: Option[string]
    currentNetwork* {.serializedFieldName("networks/current-network").}: string
    customBootnodes* {.serializedFieldName("custom-bootnodes").}: Option[JsonNode]
    customBootnodesEnabled* {.serializedFieldName("custom-bootnodes-enabled?").}: Option[JsonNode]
    dappsAddress* {.serializedFieldName("dapps-address").}: Address
    eip1581Address* {.serializedFieldName("eip1581-address").}: Address
    fleet* {.serializedFieldName("fleet").}: Option[string]
    hideHomeTooltip* {.serializedFieldName("hide-home-tooltip?").}: Option[bool]
    installationID* {.serializedFieldName("installation-id").}: string
    keyUID* {.serializedFieldName("key-uid").}: string
    keycardInstanceUID* {.serializedFieldName("keycard-instance-uid").}: Option[string]
    keycardPairedOn* {.serializedFieldName("keycard-paired-on").}: Option[int64]
    keycardPairing* {.serializedFieldName("keycard-pairing").}: Option[string]
    lastUpdated* {.serializedFieldName("last-updated").}: Option[int64]
    latestDerivedPath* {.serializedFieldName("latest-derived-path").}: uint
    logLevel* {.serializedFieldName("log-level").}: Option[string]
    mnemonic* {.serializedFieldName("mnemonic").}: Option[string]
    name* {.serializedFieldName("name").}: Option[string]
    networks* {.serializedFieldName("networks/networks").}: JsonNode
    # NotificationsEnabled indicates whether local notifications should be enabled (android only)
    notificationsEnabled* {.serializedFieldName("notifications-enabled?").}: Option[bool]
    photoPath* {.serializedFieldName("photo-path").}: string
    pinnedMailservers* {.serializedFieldName("pinned-mailservers").}: Option[JsonNode]
    preferredName* {.serializedFieldName("preferred-name").}: Option[string]
    previewPrivacy* {.serializedFieldName("preview-privacy?").}: bool
    publicKey* {.serializedFieldName("public-key").}: string
    # PushNotificationsServerEnabled indicates whether we should be running a push notification server
    pushNotificationsServerEnabled* {.serializedFieldName("push-notifications-server-enabled?").}: Option[bool]
    # PushNotificationsFromContactsOnly indicates whether we should only receive push notifications from contacts
    pushNotificationsFromContactsOnly* {.serializedFieldName("push-notifications-from-contacts-only?").}: Option[bool]
    # PushNotificationsBlockMentions indicates whether we should receive notifications for mentions
    pushNotificationsBlockMentions* {.serializedFieldName("push-notifications-block-mentions?").}: Option[bool]
    rememberSyncingChoice* {.serializedFieldName("remember-syncing-choice?").}: Option[bool]
    # RemotePushNotificationsEnabled indicates whether we should be using remote notifications (ios only for now)
    remotePushNotificationsEnabled* {.serializedFieldName("remote-push-notifications-enabled?").}: Option[bool]
    signingPhrase* {.serializedFieldName("signing-phrase").}: string
    stickerPacksInstalled* {.serializedFieldName("stickers/packs-installed").}: Option[JsonNode]
    stickersPacksPending* {.serializedFieldName("stickers/packs-pending").}: Option[JsonNode]
    stickersRecentStickers* {.serializedFieldName("stickers/recent-stickers").}: Option[JsonNode]
    syncingOnMobileNetwork* {.serializedFieldName("syncing-on-mobile-network?").}: Option[bool]
    # SendPushNotifications indicates whether we should send push notifications for other clients
    sendPushNotifications* {.serializedFieldName("send-push-notifications?").}: Option[bool]
    appearance* {.serializedFieldName("appearance").}: uint
    useMailservers* {.serializedFieldName("use-mailservers?").}: bool
    usernames* {.serializedFieldName("usernames").}: Option[JsonNode]
    walletRootAddress* {.serializedFieldName("wallet-root-address").}: Option[Address]
    walletSetUpPassed* {.serializedFieldName("wallet-set-up-passed?").}: Option[bool]
    walletVisibleTokens* {.serializedFieldName("wallet/visible-tokens").}: Option[JsonNode]
    wakuBloomFilterMode* {.serializedFieldName("waku-bloom-filter-mode").}: Option[bool]
    webViewAllowPermissionRequests* {.serializedFieldName("webview-allow-permission-requests?").}: Option[bool]


proc `$`*(self: Settings): string =
  var output = %* {
    $SettingsEnum.Address: self.userAddress,
    $SettingsEnum.CurrentNetwork: self.currentNetwork,
    $SettingsEnum.DappsAddress: self.dappsAddress,
    $SettingsEnum.EIP1581Address: self.eip1581Address,
    $SettingsEnum.InstallationID: self.installationID,
    $SettingsEnum.KeyUID: self.keyUID,
    $SettingsEnum.LatestDerivedPath: self.latestDerivedPath,
    $SettingsEnum.Networks: self.networks,
    $SettingsEnum.PhotoPath: self.photoPath,
    $SettingsEnum.PreviewPrivacy: self.previewPrivacy,
    $SettingsEnum.PublicKey: self.publicKey,
    $SettingsEnum.Appearance: self.appearance,
    $SettingsEnum.UseMailservers: self.useMailservers,
    $SettingsEnum.SigningPhrase: self.signingPhrase,
  }

  output.addOptionalValue($SettingsEnum.ChaosMode, self.chaosMode)
  output.addOptionalValue($SettingsEnum.Currency, self.currency)
  output.addOptionalValue($SettingsEnum.CustomBootNodes, self.customBootnodes)
  output.addOptionalValue($SettingsEnum.CustomBootnodesEnabled, self.customBootnodesEnabled)
  output.addOptionalValue($SettingsEnum.Fleet, self.fleet)
  output.addOptionalValue($SettingsEnum.HideHomeToolTip, self.hideHomeTooltip)
  output.addOptionalValue($SettingsEnum.KeyCard_InstanceUID, self.keycardInstanceUID)
  output.addOptionalValue($SettingsEnum.Keycard_PairedOn, self.keycardPairedOn)
  output.addOptionalValue($SettingsEnum.KeycardPairing, self.keycardPairing)
  output.addOptionalValue($SettingsEnum.LastUpdated, self.lastUpdated)
  output.addOptionalValue($SettingsEnum.LogLevel, self.logLevel)
  output.addOptionalValue($SettingsEnum.Mnemonic, self.mnemonic)
  output.addOptionalValue($SettingsEnum.Name, self.name)
  output.addOptionalValue($SettingsEnum.NotificationsEnabled, self.notificationsEnabled)
  output.addOptionalValue($SettingsEnum.PinnedMailservers, self.pinnedMailservers)
  output.addOptionalValue($SettingsEnum.PreferredName, self.preferredName)
  output.addOptionalValue($SettingsEnum.PushNotificationsServerEnabled, self.pushNotificationsServerEnabled)
  output.addOptionalValue($SettingsEnum.PushNotificationsFromContactsOnly, self.pushNotificationsFromContactsOnly)
  output.addOptionalValue($SettingsEnum.PushNotificationsBlockMentions, self.pushNotificationsBlockMentions)
  output.addOptionalValue($SettingsEnum.RememberSyncingChoice, self.rememberSyncingChoice)
  output.addOptionalValue($SettingsEnum.RemotePushNotificationsEnabled, self.remotePushNotificationsEnabled)
  output.addOptionalValue($SettingsEnum.StickersPacksInstalled, self.stickerPacksInstalled)
  output.addOptionalValue($SettingsEnum.StickersPacksPending, self.stickersPacksPending)
  output.addOptionalValue($SettingsEnum.StickersRecentStickers, self.stickersRecentStickers)
  output.addOptionalValue($SettingsEnum.SyncingOnMobileNetwork, self.syncingOnMobileNetwork)
  output.addOptionalValue($SettingsEnum.SendPushNotifications, self.sendPushNotifications)
  output.addOptionalValue($SettingsEnum.Usernames, self.usernames)
  output.addOptionalValue($SettingsEnum.WalletRootAddress, self.walletRootAddress)
  output.addOptionalValue($SettingsEnum.WalletSetUpPassed, self.walletSetUpPassed)
  output.addOptionalValue($SettingsEnum.WalletVisibleTokens, self.walletVisibleTokens)
  output.addOptionalValue($SettingsEnum.WakuBloomFilterMode, self.wakuBloomFilterMode)
  output.addOptionalValue($SettingsEnum.WebViewAllowPermissionRequests, self.webViewAllowPermissionRequests)

  result = $output


proc toSettings*(self: string): Settings =
  let o = self.parseJson
  result.userAddress = parseAddress(o[$SettingsEnum.Address].getStr)
  result.currentNetwork = o[$SettingsEnum.CurrentNetwork].getStr
  result.dappsAddress = parseAddress(o[$SettingsEnum.DappsAddress].getStr)
  result.eip1581Address = parseAddress(o[$SettingsEnum.EIP1581Address].getStr)
  result.installationID = o[$SettingsEnum.InstallationID].getStr
  result.keyUID = o[$SettingsEnum.KeyUID].getStr
  result.latestDerivedPath = o[$SettingsEnum.LatestDerivedPath].getInt.uint
  result.networks = o[$SettingsEnum.Networks]
  result.photoPath = o[$SettingsEnum.PhotoPath].getStr
  result.previewPrivacy = o[$SettingsEnum.PreviewPrivacy].getBool
  result.publicKey = o[$SettingsEnum.PublicKey].getStr
  result.appearance = o[$SettingsEnum.Appearance].getInt.uint
  result.useMailservers = o[$SettingsEnum.UseMailservers].getBool
  result.signingPhrase = o[$SettingsEnum.SigningPhrase].getStr
  result.chaosMode = o.getOptionBool($SettingsEnum.ChaosMode)
  result.currency = o.getOptionString($SettingsEnum.Currency)
  result.customBootnodes = o.getOptionJsonNode($SettingsEnum.CustomBootNodes)
  result.customBootnodesEnabled = o.getOptionJsonNode($SettingsEnum.CustomBootnodesEnabled)
  result.fleet = o.getOptionString($SettingsEnum.Fleet)
  result.hideHomeTooltip = o.getOptionBool($SettingsEnum.HideHomeToolTip)
  result.keycardInstanceUID = o.getOptionString($SettingsEnum.KeyCard_InstanceUID)
  result.keycardPairedOn = o.getOptionInt64($SettingsEnum.Keycard_PairedOn)
  result.keycardPairing = o.getOptionString($SettingsEnum.KeycardPairing)
  result.lastUpdated = o.getOptionInt64($SettingsEnum.LastUpdated)
  result.logLevel = o.getOptionString($SettingsEnum.LogLevel)
  result.mnemonic = o.getOptionString($SettingsEnum.Mnemonic)
  result.name = o.getOptionString($SettingsEnum.Name)
  result.notificationsEnabled = o.getOptionBool($SettingsEnum.NotificationsEnabled)
  result.pinnedMailservers = o.getOptionJsonNode($SettingsEnum.PinnedMailservers)
  result.preferredName = o.getOptionString($SettingsEnum.PreferredName)
  result.pushNotificationsServerEnabled = o.getOptionBool($SettingsEnum.PushNotificationsServerEnabled)
  result.pushNotificationsFromContactsOnly = o.getOptionBool($SettingsEnum.PushNotificationsFromContactsOnly)
  result.pushNotificationsBlockMentions = o.getOptionBool($SettingsEnum.PushNotificationsBlockMentions)
  result.rememberSyncingChoice = o.getOptionBool($SettingsEnum.RememberSyncingChoice)
  result.remotePushNotificationsEnabled = o.getOptionBool($SettingsEnum.RemotePushNotificationsEnabled)
  result.stickerPacksInstalled = o.getOptionJsonNode($SettingsEnum.StickersPacksInstalled)
  result.stickersPacksPending = o.getOptionJsonNode($SettingsEnum.StickersPacksPending)
  result.stickersRecentStickers = o.getOptionJsonNode($SettingsEnum.StickersRecentStickers)
  result.syncingOnMobileNetwork = o.getOptionBool($SettingsEnum.SyncingOnMobileNetwork)
  result.sendPushNotifications = o.getOptionBool($SettingsEnum.SendPushNotifications)
  result.usernames = o.getOptionJsonNode($SettingsEnum.Usernames)
  result.walletRootAddress = o.getOptionAddress($SettingsEnum.WalletRootAddress)
  result.walletSetUpPassed = o.getOptionBool($SettingsEnum.WalletSetUpPassed)
  result.walletVisibleTokens = o.getOptionJsonNode($SettingsEnum.WalletVisibleTokens)
  result.wakuBloomFilterMode = o.getOptionBool($SettingsEnum.WakuBloomFilterMode)
  result.webViewAllowPermissionRequests = o.getOptionBool($SettingsEnum.WebViewAllowPermissionRequests)
