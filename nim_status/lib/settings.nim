import # nim libs
  json, options, strutils, locks, strformat

import # vendor libs
  web3/conversions as web3_conversions, web3/ethtypes, sqlcipher, json_serialization

import # nim-status libs
  conversions, settings/types

export types, options

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
            s.userAddress,
            s.currency,
            s.currentNetwork,
            s.dappsAddress,
            s.eip1581Address,
            s.installationID,
            s.keyUID,
            s.keycardInstanceUID,
            s.keycardPairedOn,
            s.keycardPairing,
            s.latestDerivedPath,
            s.mnemonic,
            s.name,
            s.networks,
            nodecfg,
            s.photoPath,
            s.previewPrivacy,
            s.publicKey,
            s.signingPhrase,
            s.walletRootAddress)

proc saveSetting*(db: DbConn, setting: string, value: auto) =
  var settings: Settings
  db.exec(fmt"""UPDATE {settings.tableName} SET {setting} = ? WHERE synthetic_id = 'id'""", value)

proc getNodeConfig*(db: DbConn): JsonNode =
  var settings: Settings
  let query = fmt"""SELECT {settings.nodeConfig.columnName} FROM {settings.tableName} WHERE synthetic_id = 'id'"""
  let nodeConfig = db.value(JsonNode, query)
  if not nodeConfig.isSome:
    raise newException(ValueError, "No record found for node config")
  nodeConfig.get

proc getSettings*(db: DbConn): Settings =
  let query = fmt"""SELECT * FROM {result.tableName} WHERE synthetic_id = 'id'"""

  let settings = db.one(Settings, query)
  if not settings.isSome:
    raise newException(ValueError, "No record found for settings")
  settings.get
