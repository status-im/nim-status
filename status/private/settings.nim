{.push raises: [Defect].}

import # std libs
  std/[json, options, strformat]

import # vendor libs
  json_serialization, sqlcipher

import # status modules
  ./conversions, ./settings/types

export options, types

proc createSettings*(db: DbConn, s: Settings, nodecfg: JsonNode) {.raises:
  [Defect, SettingDbError].} =
  # TODO: replace JsonNode by a proper NodeConfig object?

  const errorMsg = "Error inserting settings in to the database"

  try:
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
  except SqliteError as e:
    raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref SettingDbError)(parent: e, msg: errorMsg)

proc getNodeConfig*(db: DbConn): JsonNode {.raises: [Defect, SettingDbError].} =

  const errorMsg = "Error getting node config from the database"
  var nodeConfig: Option[JsonNode]
  try:
    var settings: Settings
    let query = fmt"""SELECT    {settings.nodeConfig.columnName}
                      FROM      {settings.tableName}
                      WHERE     synthetic_id = 'id'"""
    nodeConfig = db.value(JsonNode, query)
  except SqliteError as e:
    raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except Exception as e:
    raise (ref SettingDbError)(parent: e, msg: errorMsg)

  if not nodeConfig.isSome:
    raise newException(SettingDbError, "No record found for node config")

  return nodeConfig.get


proc getSetting*[T](db: DbConn, _: typedesc[T], setting: SettingsCol): Option[T]
  {.raises: [Defect, SettingDbError].} =

  const errorMsg = "Error getting setting from the database"
  try:
    var settings: Settings
    let query = fmt"""SELECT    {setting}
                      FROM      {settings.tableName}
                      WHERE     synthetic_id = 'id'"""

    db.value(T, query)
  except SqliteError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)

proc getSetting*[T](db: DbConn, _: typedesc[T], setting: SettingsCol,
  defaultValue: T): T {.raises: [Defect, SettingDbError].} =

  const errorMsg = "Error getting setting from the database"
  try:
    let setting = db.getSetting[:T](T, setting)
    return setting.get(defaultValue)
  except SqliteError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)

proc getSettings*(db: DbConn): Settings {.raises: [SettingDbError].} =

  const errorMsg = "Error getting settings from the database"
  try:
    let query = fmt"""SELECT    *
                      FROM      {result.tableName}
                      WHERE     synthetic_id = 'id'"""

    let settings = db.one(Settings, query)
    if not settings.isSome:
      raise newException(SettingDbError, "No record found for settings")
    settings.get

  except SerializationError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except Exception as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)

proc saveSetting*(db: DbConn, setting: SettingsCol, value: auto) {.raises:
  [Defect, SettingDbError].} =

  const errorMsg = "Error saving setting in the database"
  try:
    var settings: Settings
    db.exec(fmt"""UPDATE    {settings.tableName}
                  SET       {setting} = ?
                  WHERE     synthetic_id = 'id'""", value)
  except SqliteError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
      raise (ref SettingDbError)(parent: e, msg: errorMsg)
