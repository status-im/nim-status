{.push raises: [Defect].}

import # std libs
  std/[json, options, strformat, strutils]

import # vendor libs
  json_serialization, sqlcipher

import # status modules
  ./conversions, ./settings/types

export types, options

proc createSettings*(db: DbConn, s: Settings, nodecfg: JsonNode) {.raises:
  [Defect, SqliteError, ValueError].} =
  # TODO: replace JsonNode by a proper NodeConfig object?

  var setting: Settings
  let query = fmt"""INSERT INTO {setting.tableName} (
                      {setting.userAddress.columnName},
                      {setting.currency.columnName},
                      {setting.currentNetwork.columnName},
                      {setting.dappsAddress.columnName},
                      {setting.eip1581Address.columnName},
                      {setting.installationId.columnName},
                      {setting.keyUid.columnName},
                      {setting.keycardInstanceUid.columnName},
                      {setting.keycardPairedOn.columnName},
                      {setting.keycardPairing.columnName},
                      {setting.latestDerivedPath.columnName},
                      {setting.mnemonic.columnName},
                      {setting.name.columnName},
                      {setting.networks.columnName},
                      {setting.nodeConfig.columnName},
                      {setting.photoPath.columnName},
                      {setting.previewPrivacy.columnName},
                      {setting.publicKey.columnName},
                      {setting.signingPhrase.columnName},
                      {setting.walletRootAddress.columnName},
                      synthetic_id)
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

proc getNodeConfig*(db: DbConn): JsonNode {.raises: [Defect, Exception].} =

  var settings: Settings
  let query = fmt"""SELECT    {settings.nodeConfig.columnName}
                    FROM      {settings.tableName}
                    WHERE     synthetic_id = 'id'"""
  let nodeConfig = db.value(JsonNode, query)
  if not nodeConfig.isSome:
    raise newException(ValueError, "No record found for node config")
  nodeConfig.get

proc getSetting*[T](db: DbConn, _: typedesc[T], setting: SettingsCol): Option[T]
  {.raises: [Defect, SqliteError, ref ValueError].} =
  var settings: Settings
  let query = fmt"""SELECT    {$setting}
                    FROM      {settings.tableName}
                    WHERE     synthetic_id = 'id'"""

  db.value(T, query)

proc getSetting*[T](db: DbConn, _: typedesc[T], setting: SettingsCol,
  defaultValue: T): T {.raises: [Defect, SqliteError, ValueError].} =

  let setting = db.getSetting[:T](T, setting)
  if setting.isNone:
    result = defaultValue
  else:
    result = setting.get

proc getSettings*(db: DbConn): Settings {.raises: [Defect, Exception].} =

  let query = fmt"""SELECT    *
                    FROM      {result.tableName}
                    WHERE     synthetic_id = 'id'"""

  let settings = db.one(Settings, query)
  if not settings.isSome:
    raise newException(ValueError, "No record found for settings")
  settings.get

proc saveSetting*(db: DbConn, setting: SettingsCol, value: auto) {.raises:
  [Defect, SqliteError, ValueError].} =

  var settings: Settings
  db.exec(fmt"""UPDATE    {settings.tableName}
                SET       {setting} = ?
                WHERE     synthetic_id = 'id'""", value)
