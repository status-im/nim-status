{.push raises: [Defect].}

import # std libs
  std/[json, options, strformat]

import # vendor libs
  json_serialization, sqlcipher

import # status modules
  ./common, ./conversions, ./settings/types

export options, types

proc createSettings*(db: DbConn, s: Settings, nodecfg: JsonNode):
  DbResult[void] =
  # TODO: replace JsonNode by a proper NodeConfig object?

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
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getNodeConfig*(db: DbConn): DbResult[JsonNode] =

  var nodeConfig: Option[JsonNode]
  try:
    var settings: Settings
    let query = fmt"""SELECT    {settings.nodeConfig.columnName}
                      FROM      {settings.tableName}
                      WHERE     synthetic_id = 'id'"""
    nodeConfig = db.value(JsonNode, query)
  except SqliteError: return err OperationError
  except ValueError: return err QueryBuildError
  except Exception: return err UnknownError

  if not nodeConfig.isSome:
    return err RecordNotFound

  ok nodeConfig.get


proc getSetting*[T](db: DbConn, _: typedesc[T], setting: SettingsCol):
  DbResult[Option[T]] =

  try:
    var settings: Settings
    let query = fmt"""SELECT    {setting}
                      FROM      {settings.tableName}
                      WHERE     synthetic_id = 'id'"""

    ok db.value(T, query)
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getSetting*[T](db: DbConn, _: typedesc[T], setting: SettingsCol,
  defaultValue: T): DbResult[T] =

  try:
    let setting = ?db.getSetting[:T](T, setting)
    ok setting.get(defaultValue)
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getSettings*(db: DbConn): DbResult[Settings] {.raises: [].} =

  try:
    var setting: Settings
    let query = fmt"""SELECT    *
                      FROM      {setting.tableName}
                      WHERE     synthetic_id = 'id'"""

    let settings = db.one(Settings, query)
    if settings.isNone:
      return err RecordNotFound
    ok settings.get

  except SerializationError: err DataAndTypeMismatch
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError
  except Exception: err UnknownError

proc saveSetting*(db: DbConn, setting: SettingsCol, value: auto):
  DbResult[void] =

  try:
    var settings: Settings
    db.exec(fmt"""UPDATE    {settings.tableName}
                  SET       {setting} = ?
                  WHERE     synthetic_id = 'id'""", value)
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError
