
import # nim libs
  options, json, sugar, sequtils

import # vendor libs
  json_serialization, json_serialization/[reader, writer, lexer],
  web3/conversions as web3_conversions, web3/ethtypes, sqlcipher


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
  
  SettingsCol* {.pure.} = enum
    Address = "address",
    ChaosMode = "chaos_mode",
    Currency = "currency",
    CustomBootNodes = "custom_bootnodes",
    CustomBootNodesEnabled = "custom_bootnodes_enabled",
    DappsAddress = "dapps_address",
    EIP1581Address = "eip1581_address",
    Fleet = "fleet",
    HideHomeToolTip = "hide_home_tooltip",
    InstallationId = "installation_id",
    KeyUID = "key_uid",
    KeyCard_InstanceUID = "keycard_instance_uid",
    Keycard_PairedOn = "keycard_paired_on",
    Keycard_Pairing = "keycard_pairing",
    LastUpdated = "last_updated",
    LatestDerivedPath = "latest_derived_path",
    LogLevel = "log_level",
    Mnemonic = "mnemonic",
    Name = "name",
    CurrentNetwork = "current_network",
    Networks = "networks",
    NodeConfig = "node_config",
    NotificationsEnabled = "notifications_enabled",
    PhotoPath = "photo_path",
    PinnedMailservers = "pinned_mailservers",
    PreferredName = "preferred_name",
    PreviewPrivacy = "preview_privacy",
    PublicKey = "public_key",
    RememberSyncingChoice = "remember_syncing_choice",
    RemotePushNotificationsEnabled = "remote_push_notifications_enabled",
    PushNotificationsServerEnabled = "push_notifications_server_enabled",
    PushNotificationsFromContactsOnly = "push_notifications_from_contacts_only",
    PushNotificationsBlockMentions = "push_notifications_block_mentions",
    SendPushNotifications = "send_push_notifications",
    SigningPhrase = "signing_phrase",
    StickersPacksInstalled = "stickers_packs_installed",
    StickersPacksPending = "stickers_packs_pending",
    StickersRecentStickers = "stickers_recent_stickers",
    SyncingOnMobileNetwork = "syncing_on_mobile_network",
    UseMailservers = "use_mailservers",
    Usernames = "usernames",
    WalletRootAddress = "wallet_root_address",
    WalletSetUpPassed = "wallet_set_up_passed",
    WalletVisibleTokens = "wallet_visible_tokens",
    Appearance = "appearance",
    WakuEnabled = "waku_enabled"
    WakuBloomFilterMode = "waku_bloom_filter_mode",
    WebviewAllowPermissionRequests = "webview_allow_permission_requests"

  UpstreamConfig* = object
    enabled* {.serializedFieldName("Enabled").}: bool
    url* {.serializedFieldName("URL").}: string

  NetworkConfig* = object
    dataDir* {.serializedFieldName("DataDir").}: string
    networkId* {.serializedFieldName("NetworkId").}: int
    upstreamConfig* {.serializedFieldName("UpstreamConfig").}: UpstreamConfig

  Network* = object
    config* {.serializedFieldName("config").}: NetworkConfig
    etherscanLink* {.serializedFieldName("etherscan-link").}: Option[string]
    id* {.serializedFieldName("id").}: string
    name*: string

  Settings* {.dbTableName("settings").} = object
    userAddress* {.serializedFieldName($SettingsType.Address), dbColumnName($SettingsCol.Address).}: Address
    chaosMode* {.serializedFieldName($SettingsType.ChaosMode), dbColumnName($SettingsCol.ChaosMode).}: Option[bool]
    currency* {.serializedFieldName($SettingsType.Currency), dbColumnName($SettingsCol.Currency).}: Option[string]
    currentNetwork* {.serializedFieldName($SettingsType.CurrentNetwork), dbColumnName($SettingsCol.CurrentNetwork).}: string
    customBootnodes* {.dontSerialize, serializedFieldName($SettingsType.CustomBootnodes), dbColumnName($SettingsCol.CustomBootnodes).}: Option[JsonNode]
    customBootnodesEnabled* {.dontSerialize, serializedFieldName($SettingsType.CustomBootnodesEnabled), dbColumnName($SettingsCol.CustomBootnodesEnabled).}: Option[JsonNode]
    dappsAddress* {.serializedFieldName($SettingsType.DappsAddress), dbColumnName($SettingsCol.DappsAddress).}: Address
    eip1581Address* {.serializedFieldName($SettingsType.EIP1581Address), dbColumnName($SettingsCol.EIP1581Address).}: Address
    fleet* {.dontSerialize, serializedFieldName($SettingsType.Fleet), dbColumnName($SettingsCol.Fleet).}: Option[string]
    hideHomeTooltip* {.dontSerialize, serializedFieldName($SettingsType.HideHomeTooltip), dbColumnName($SettingsCol.HideHomeTooltip).}: Option[bool]
    installationID* {.serializedFieldName($SettingsType.InstallationID), dbColumnName($SettingsCol.InstallationID).}: string
    keyUID* {.serializedFieldName($SettingsType.KeyUID), dbColumnName($SettingsCol.KeyUID).}: string
    keycardInstanceUID* {.serializedFieldName($SettingsType.Keycard_InstanceUID), dbColumnName($SettingsCol.Keycard_InstanceUID).}: Option[string]
    keycardPairedOn* {.serializedFieldName($SettingsType.Keycard_PairedOn), dbColumnName($SettingsCol.Keycard_PairedOn).}: Option[int64]
    keycardPairing* {.serializedFieldName($SettingsType.Keycard_Pairing), dbColumnName($SettingsCol.Keycard_Pairing).}: Option[string]
    lastUpdated* {.dontSerialize, serializedFieldName($SettingsType.LastUpdated), dbColumnName($SettingsCol.LastUpdated).}: Option[int64]
    latestDerivedPath* {.serializedFieldName($SettingsType.LatestDerivedPath), dbColumnName($SettingsCol.LatestDerivedPath).}: uint
    logLevel* {.dontSerialize, serializedFieldName($SettingsType.LogLevel), dbColumnName($SettingsCol.LogLevel).}: Option[string]
    mnemonic* {.serializedFieldName($SettingsType.Mnemonic), dbColumnName($SettingsCol.Mnemonic).}: Option[string]
    name* {.serializedFieldName($SettingsType.Name), dbColumnName($SettingsCol.Name).}: Option[string]
    networks* {.serializedFieldName($SettingsType.Networks), dbColumnName($SettingsCol.Networks).}: JsonNode
    nodeConfig* {.serializedFieldName($SettingsType.NodeConfig), dbColumnName($SettingsCol.NodeConfig).}: JsonNode
    # NotificationsEnabled indicates whether local notifications should be enabled (android only)
    notificationsEnabled* {.dontSerialize, serializedFieldName($SettingsType.NotificationsEnabled), dbColumnName($SettingsCol.NotificationsEnabled).}: Option[bool]
    photoPath* {.serializedFieldName($SettingsType.PhotoPath), dbColumnName($SettingsCol.PhotoPath).}: string
    pinnedMailservers* {.dontSerialize, serializedFieldName($SettingsType.PinnedMailservers), dbColumnName($SettingsCol.PinnedMailservers).}: Option[JsonNode]
    preferredName* {.dontSerialize, serializedFieldName($SettingsType.PreferredName), dbColumnName($SettingsCol.PreferredName).}: Option[string]
    previewPrivacy* {.serializedFieldName($SettingsType.PreviewPrivacy), dbColumnName($SettingsCol.PreviewPrivacy).}: bool
    publicKey* {.serializedFieldName($SettingsType.PublicKey), dbColumnName($SettingsCol.PublicKey).}: string
    # PushNotificationsServerEnabled indicates whether we should be running a push notification server
    pushNotificationsServerEnabled* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsServerEnabled), dbColumnName($SettingsCol.PushNotificationsServerEnabled).}: Option[bool]
    # PushNotificationsFromContactsOnly indicates whether we should only receive push notifications from contacts
    pushNotificationsFromContactsOnly* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsFromContactsOnly), dbColumnName($SettingsCol.PushNotificationsFromContactsOnly).}: Option[bool]
    # PushNotificationsBlockMentions indicates whether we should receive notifications for mentions
    pushNotificationsBlockMentions* {.dontSerialize, serializedFieldName($SettingsType.PushNotificationsBlockMentions), dbColumnName($SettingsCol.PushNotificationsBlockMentions).}: Option[bool]
    rememberSyncingChoice* {.dontSerialize, serializedFieldName($SettingsType.RememberSyncingChoice), dbColumnName($SettingsCol.RememberSyncingChoice).}: Option[bool]
    # RemotePushNotificationsEnabled indicates whether we should be using remote notifications (ios only for now)
    remotePushNotificationsEnabled* {.dontSerialize, serializedFieldName($SettingsType.RemotePushNotificationsEnabled), dbColumnName($SettingsCol.RemotePushNotificationsEnabled).}: Option[bool]
    signingPhrase* {.serializedFieldName($SettingsType.SigningPhrase), dbColumnName($SettingsCol.SigningPhrase).}: string
    stickerPacksInstalled* {.dontSerialize, serializedFieldName($SettingsType.StickersPacksInstalled), dbColumnName($SettingsCol.StickersPacksInstalled).}: Option[JsonNode]
    stickersPacksPending* {.dontSerialize, serializedFieldName($SettingsType.StickersPacksPending), dbColumnName($SettingsCol.StickersPacksPending).}: Option[JsonNode]
    stickersRecentStickers* {.dontSerialize, serializedFieldName($SettingsType.StickersRecentStickers), dbColumnName($SettingsCol.StickersRecentStickers).}: Option[JsonNode]
    syncingOnMobileNetwork* {.dontSerialize, serializedFieldName($SettingsType.SyncingOnMobileNetwork), dbColumnName($SettingsCol.SyncingOnMobileNetwork).}: Option[bool]
    # SendPushNotifications indicates whether we should send push notifications for other clients
    sendPushNotifications* {.dontSerialize, serializedFieldName($SettingsType.SendPushNotifications), dbColumnName($SettingsCol.SendPushNotifications).}: Option[bool]
    appearance* {.dontSerialize, serializedFieldName($SettingsType.Appearance), dbColumnName($SettingsCol.Appearance).}: uint
    useMailservers* {.dontSerialize, serializedFieldName($SettingsType.UseMailservers), dbColumnName($SettingsCol.UseMailservers).}: bool
    usernames* {.dontSerialize, serializedFieldName($SettingsType.Usernames), dbColumnName($SettingsCol.Usernames).}: Option[JsonNode]
    walletRootAddress* {.serializedFieldName($SettingsType.WalletRootAddress), dbColumnName($SettingsCol.WalletRootAddress).}: Option[Address]
    walletSetUpPassed* {.dontSerialize, serializedFieldName($SettingsType.WalletSetUpPassed), dbColumnName($SettingsCol.WalletSetUpPassed).}: Option[bool]
    walletVisibleTokens* {.dontSerialize, serializedFieldName($SettingsType.WalletVisibleTokens), dbColumnName($SettingsCol.WalletVisibleTokens).}: Option[JsonNode]
    wakuEnabled* {.dontSerialize, serializedFieldName($SettingsType.WakuEnabled), dbColumnName($SettingsCol.WakuEnabled).}: Option[bool]
    wakuBloomFilterMode* {.dontSerialize, serializedFieldName($SettingsType.WakuBloomFilterMode), dbColumnName($SettingsCol.WakuBloomFilterMode).}: Option[bool]
    webViewAllowPermissionRequests* {.dontSerialize, serializedFieldName($SettingsType.WebviewAllowPermissionRequests), dbColumnName($SettingsCol.WebviewAllowPermissionRequests).}: Option[bool]


proc writeValue*(writer: var JsonWriter, value: Settings|Network) =
  writer.beginRecord()
  for key, val in fieldPairs(value):
    when val is Option:
      if val.isSome:
        writer.writeField key, val.get()
    else:
      writer.writeField key, val
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

proc getNetwork*(self: Settings): Option[Network] =
  let found = self.networks.filter(network => network.id == self.currentNetwork)
  result = if found.len > 0: some found[0] else: none(Network)
