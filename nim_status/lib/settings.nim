import # nim libs
  json, options, strutils, locks

import # vendor libs
  web3/conversions as web3_conversions, web3/ethtypes, sqlcipher

import # nim-status libs
  conversions, settings/types

export types

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
  let query = """SELECT * FROM settings WHERE synthetic_id = 'id'"""

  let settings = execQuery[Settings](db, query)
  if settings.len == 0:
    raise newException(ValueError, "No records found for settings")
  settings[0]