{.push raises: [Defect].}

import # std libs
  std/[os, strutils, unicode]

import # vendor libs
  nimcrypto/keccak, sqlcipher

import # status modules
  ./common, ./migration,
  ./migrations/sql_scripts_accounts as acc_migration,
  ./migrations/sql_scripts_app as app_migration,
  ./util

export sqlcipher

proc initDb*(path: string): DbResult[DbConn] =
  try:

    createDir path.parentDir()
    var runMigrations = false
    if not path.fileExists():
      runMigrations = true
    let dbConn = openDatabase(path)
    if runMigrations:
      let definition = acc_migration.newMigrationDefinition()
      discard ?dbConn.migrate(definition).mapErrTo(DbError.MigrationError)
    ok dbConn

  except IOError, OSError: err InitFailure
  except SqliteError: err DbError.OperationError

proc hash(password: string): string {.raises: [].} =
  "0x" & toUpper($keccak_256.digest(password))

proc initDb*(path, password: string): DbResult[DbConn] =

  try:
    createDir path.parentDir()
    var runMigrations = false
    if not path.fileExists():
      runMigrations = true
    let dbConn = openDatabase(path)
    # try:
    dbConn.key(password.hash)

    # Custom encryption settings are used by status-go with sqlcipher v3 to
    # accommodate lower-performance mobile devices. See:
    # * https://github.com/status-im/status-go/pull/1343
    # * https://github.com/status-im/status-go/blob/81171ad9e64feeceff81bc78b1aefba196cb1172/sqlite/sqlite.go#L12-L21
    # nim-status will instead use sqlcipher v4's defaults, but in the future we
    # may need to allow custom settings to be specified at compile time.
    # ----------------------------------------------------------------------------
    # dbConn.exec("PRAGMA cipher_page_size = 1024")
    # dbConn.exec("PRAGMA kdf_iter = 3200")
    # dbConn.exec("PRAGMA cipher_hmac_algorithm = HMAC_SHA1")
    # dbConn.exec("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1")
    # ----------------------------------------------------------------------------
    dbConn.exec("PRAGMA foreign_keys = ON")
    dbConn.exec("PRAGMA journal_mode = WAL")
    if runMigrations:
      let definition = app_migration.newMigrationDefinition()
      discard ?dbConn.migrate(definition).mapErrTo(DbError.MigrationError)
    return ok dbConn
  except SqliteError as e:
    if e.msg.contains("file is not a database"):
      return err DbError.KeyError
    else: return err DbError.OperationError
  except IOError, OSError: return err InitFailure
