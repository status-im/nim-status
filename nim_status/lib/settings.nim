import settings/types
import settings/utils
import web3/[conversions, ethtypes]
import sqlcipher
import json
import options
import strutils
import locks

export types, utils

proc createSettings*(db: DbConn, s: Settings, nodecfg: JsonNode) = # TODO: replace JsonNode by a proper NodeConfig object?
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

proc saveSetting*(db: DbConn, setting: SettingsType, value: bool) =
  case setting
  of SettingsType.ChaosMode:
    db.exec("UPDATE settings SET chaos_mode = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.HideHomeToolTip:
    db.exec("UPDATE settings SET hide_home_tooltip = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.PreviewPrivacy:
    db.exec("UPDATE settings SET preview_privacy = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.SyncingOnMobileNetwork:
    db.exec("UPDATE settings SET syncing_on_mobile_network = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.RememberSyncingChoice:
    db.exec("UPDATE settings SET remember_syncing_choice = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.RemotePushNotificationsEnabled:
    db.exec("UPDATE settings SET remote_push_notifications_enabled = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.PushNotificationsServerEnabled:
    db.exec("UPDATE settings SET push_notifications_server_enabled = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.PushNotificationsFromContactsOnly:
    db.exec("UPDATE settings SET push_notifications_from_contacts_only = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.PushNotificationsBlockMentions:
    db.exec("UPDATE settings SET push_notifications_block_mentions = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.SendPushNotifications:
    db.exec("UPDATE settings SET send_push_notifications = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.UseMailservers:
    db.exec("UPDATE settings SET use_mailservers = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.NotificationsEnabled:
    db.exec("UPDATE settings SET notifications_enabled = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.WakuEnabled:
    db.exec("UPDATE settings SET waku_enabled = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.WalletSetupPassed:
    db.exec("UPDATE settings SET wallet_set_up_passed = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.WakuBloomFilterMode:
    db.exec("UPDATE settings SET waku_bloom_filter_mode = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.WebviewAllowPermissionRequests:
    db.exec("UPDATE settings SET webview_allow_permission_requests = ? WHERE synthetic_id = 'id'", value)
  else: 
    raise (ref SettingsError)(msg: "Setting: '" & $setting & "' cannot be updated or invalid data type received")


proc saveSetting*(db: DbConn, setting: SettingsType, value: int64) =
  case setting
  of SettingsType.Keycard_PairedOn:
    db.exec("UPDATE settings SET keycard_paired_on = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.LastUpdated:
    db.exec("UPDATE settings SET last_updated = ? WHERE synthetic_id = 'id'", value)
  else: 
    raise (ref SettingsError)(msg: "Setting: '" & $setting & "' cannot be updated or invalid data type received")


proc saveSetting*(db: DbConn, setting: SettingsType, value: int) =
  case setting
  of SettingsType.LatestDerivedPath:
    db.exec("UPDATE settings SET latest_derived_path = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.Appearance:
    db.exec("UPDATE settings SET appearance = ? WHERE synthetic_id = 'id'", value)
  else: 
    raise (ref SettingsError)(msg: "Setting: '" & $setting & "' cannot be updated or invalid data type received")


proc saveSetting*(db: DbConn, setting: SettingsType, value: string) =
  case setting
  of SettingsType.Currency:
    db.exec("UPDATE settings SET currency = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.Fleet:
    db.exec("UPDATE settings SET fleet = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.KeycardInstanceUID:
    db.exec("UPDATE settings SET keycard_instance_uid = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.Keycard_Pairing:
    db.exec("UPDATE settings SET keycard_pairing = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.LogLevel:
    db.exec("UPDATE settings SET log_level = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.Mnemonic:
    db.exec("UPDATE settings SET mnemonic = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.Name:
    db.exec("UPDATE settings SET name = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.CurrentNetwork:
    db.exec("UPDATE settings SET current_network = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.PhotoPath:
    db.exec("UPDATE settings SET photo_path = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.PreferredName:
    db.exec("UPDATE settings SET preferred_name = ? WHERE synthetic_id = 'id'", value)
  of SettingsType.PublicKey:
    db.exec("UPDATE settings SET public_key = ? WHERE synthetic_id = 'id'", value)
  else: 
    raise (ref SettingsError)(msg: "Setting: '" & $setting & "' cannot be updated or invalid data type received")


proc saveSetting*(db: DbConn, setting: SettingsType, value: JsonNode) =
  case setting
  of SettingsType.CustomBootnodes:
    db.exec("UPDATE settings SET custom_bootnodes = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.CustomBootnodesEnabled:
    db.exec("UPDATE settings SET custom_bootnodes_enabled = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.Networks:
    db.exec("UPDATE settings SET networks = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.NodeConfig:
    db.exec("UPDATE settings SET node_config = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.PinnedMailservers:
    db.exec("UPDATE settings SET pinned_mailservers = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.StickersPacksInstalled:
    db.exec("UPDATE settings SET stickers_packs_installed = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.StickersPacksPending:
    db.exec("UPDATE settings SET stickers_packs_pending = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.StickersRecentStickers:
    db.exec("UPDATE settings SET stickers_recent_stickers = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.Usernames:
    db.exec("UPDATE settings SET usernames = ? WHERE synthetic_id = 'id'", ($value))
  of SettingsType.WalletVisibleTokens:
    db.exec("UPDATE settings SET wallet_visible_tokens = ? WHERE synthetic_id = 'id'", ($value))
  else: 
    raise (ref SettingsError)(msg: "Setting: '" & $setting & "' cannot be updated or invalid data type received")


proc saveSetting*(db: DbConn, setting: SettingsType, value: Address) =
  case setting
  of SettingsType.DappsAddress:
    db.exec("UPDATE settings SET dapps_address = ? WHERE synthetic_id = 'id'", $value)
  of SettingsType.EIP1581Address:
    db.exec("UPDATE settings SET eip1581_address = ? WHERE synthetic_id = 'id'", $value)
  else: 
    raise (ref SettingsError)(msg: "Setting: '" & $setting & "' cannot be updated or invalid data type received")


proc saveSetting*(db: DbConn, setting: string, value: auto) =
  var s: SettingsType
  try: 
    s = parseEnum[SettingsType](setting)
  except:
    raise (ref SettingsError)(msg: "Unknown setting: '" & $setting)

  saveSetting(db, s, value)


proc getNodeConfig*(db: DbConn): JsonNode =
  let query = "SELECT node_config FROM settings WHERE synthetic_id = 'id'"
  for r in rows(db, query):
    return r[0].strVal.parseJson


proc getSettings*(db: DbConn): Settings =
  let query = """SELECT address, chaos_mode, currency, current_network,
  custom_bootnodes, custom_bootnodes_enabled, dapps_address, eip1581_address,
  fleet, hide_home_tooltip, installation_id, key_uid, keycard_instance_uid,
  keycard_paired_on, keycard_pairing, last_updated, latest_derived_path, log_level,
  mnemonic, name, networks, notifications_enabled, push_notifications_server_enabled,
  push_notifications_from_contacts_only, remote_push_notifications_enabled,
  send_push_notifications, push_notifications_block_mentions, photo_path,
  pinned_mailservers, preferred_name, preview_privacy, public_key, remember_syncing_choice,
  signing_phrase, stickers_packs_installed, stickers_packs_pending, stickers_recent_stickers,
  syncing_on_mobile_network, use_mailservers, usernames, appearance, wallet_root_address,
  wallet_set_up_passed, wallet_visible_tokens, waku_bloom_filter_mode, waku_enabled,
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
    result.wakuEnabled = r[45].optionBool
    result.webViewAllowPermissionRequests = r[46].optionBool
    break
