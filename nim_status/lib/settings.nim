import settings/[types, utils]
import web3/conversions
import sqlcipher
import json
import options

export Settings, SettingsEnum, `$`, `toSettings`

proc newSettingsError(key, value: string): ref SettingsError =
  (ref SettingsError)(msg: "Invalid setting: " & key & ": " & value)

proc newSettingsError(key: SettingsEnum, value: string): ref SettingsError =
  newSettingsError($SettingsEnum, value)

proc createSettings*(db: DbConn, s: Settings, nodecfg: JsonNode) = # TODO: replace JsonNode by a proper NodeConfig object
  let query = """INSERT INTO settings (
                  address, currency, current_network, dapps_address,
                  eip1581_address, installation_id, key_uid,
                  keycard_instance_uid, keycard_paired_on,
                  keycard_pairing, latest_derived_path, mnemonic,
                  name, networks, node_config, photo_path,
                  preview_privacy, public_key, signing_phrase,
                  wallet_root_address, synthetic_id) 
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'id')"""

  db.exec(query,
            $s.userAddress,
            (if s.currency.isSome(): s.currency.get() else: ""),
            s.currentNetwork,
            $s.dappsAddress,
            $s.eip1581Address,
            s.installationID,
            s.keyUID,
            (if s.keycardInstanceUID.isSome(): s.keycardInstanceUID.get() else: ""),
            (if s.keycardPairedOn.isSome(): s.keycardPairedOn.get() else: 0),
            (if s.keycardPairing.isSome(): s.keycardPairing.get() else: ""),
            s.latestDerivedPath,
            s.mnemonic,
            (if s.name.isSome(): s.name.get() else: ""),
            $s.networks,
            $nodecfg,
            s.photoPath,
            s.previewPrivacy,
            s.publicKey,
            s.signingPhrase,
            (if s.walletRootAddress.isSome(): $s.walletRootAddress.get() else: ""))
  
proc saveSetting*(db:DbConn, setting: SettingsEnum, value: string) =
  discard

proc saveSetting*(db:DbConn, setting: string, value: string) =
  discard
  #[try: 
    parseEnum(setting)
  catch
    newSettingsError(setting, value)]#

proc getNodeConfig*(db: DbConn): JsonNode =
  # TODO:
  # "SELECT node_config FROM settings WHERE synthetic_id = 'id'"
  discard

proc getSettings*(db: DbConn): Settings =
  let query = """SELECT address, chaos_mode, currency, current_network, custom_bootnodes, custom_bootnodes_enabled, dapps_address, eip1581_address, 
  fleet, hide_home_tooltip, installation_id, key_uid, keycard_instance_uid, 
  keycard_paired_on, keycard_pairing, last_updated, latest_derived_path, log_level, 
  mnemonic, name, networks, notifications_enabled, push_notifications_server_enabled, 
  push_notifications_from_contacts_only, remote_push_notifications_enabled, 
  send_push_notifications, push_notifications_block_mentions, photo_path, 
  pinned_mailservers, preferred_name, preview_privacy, public_key, remember_syncing_choice,
   signing_phrase, stickers_packs_installed, stickers_packs_pending, stickers_recent_stickers, 
   syncing_on_mobile_network, use_mailservers, usernames, appearance, wallet_root_address,
    wallet_set_up_passed, wallet_visible_tokens, waku_bloom_filter_mode, 
    webview_allow_permission_requests FROM settings WHERE synthetic_id = 'id'"""

  for r in rows(db, query):
    result.userAddress = r[0].strVal.parseAddress
    result.chaosMode = r[1].optionBool
    result.currency =  r[2].optionString
    result.currentNetwork = r[3].strVal
    result.customBootNodes = r[4].optionJsonNode
    result.customBootNodesEnabled = r[5].optionJsonNode
    result.dappsAddress = r[6].strVal.parseAddress
    result.eip1581Address = r[7].strVal.parseAddress
    result.fleet = r[8].optionString
    result.hideHomeToolTip = r[9].optionBool
    result.installationID = r[10].strVal
    result.keyUID = r[11].strVal
    result.keycardInstanceUID = r[12].optionString
    result.keycardPairedOn = r[13].optionInt
    result.keycardPairing = r[14].optionString
    result.lastUpdated = r[15].optionInt64
    result.latestDerivedPath = r[16].intVal.uint
    result.logLevel = r[17].optionString
    result.mnemonic = r[18].optionString
    result.name = r[19].optionString
    result.networks = r[20].strVal.parseJson
    result.notificationsEnabled = r[21].optionBool
    result.pushNotificationsServerEnabled = r[22].optionBool
    result.pushNotificationsFromContactsOnly = r[23].optionBool
    result.remotePushNotificationsEnabled = r[24].optionBool
    result.sendPushNotifications = r[25].optionBool
    result.pushNotificationsBlockMentions = r[26].optionBool
    result.photoPath = r[27].strVal
    result.pinnedMailservers = r[28].optionJsonNode
    result.preferredName = r[29].optionString
    result.previewPrivacy = r[30].intVal.bool
    result.publicKey = r[31].strVal
    result.rememberSyncingChoice = r[32].optionBool
    result.signingPhrase = r[33].strVal
    result.stickerPacksInstalled = r[34].optionJsonNode
    result.stickersPacksPending = r[35].optionJsonNode
    result.stickersRecentStickers = r[36].optionJsonNode
    result.syncingOnMobileNetwork = r[37].optionBool
    result.useMailservers = r[38].intVal.bool
    result.usernames = r[39].optionJsonNode
    result.appearance = r[40].intVal.uint
    result.walletRootAddress = r[41].optionAddress
    result.walletSetUpPassed = r[42].optionBool
    result.walletVisibleTokens = r[43].optionJsonNode
    result.wakuBloomFilterMode = r[44].optionBool
    result.webViewAllowPermissionRequests = r[45].optionBool
    break
