{.push raises: [Defect].}

import # std libs
  std/[os, unicode]

import # vendor libs
  nimcrypto/keccak, sqlcipher, stew/results

import # status modules
  ./common, ./migration,
  ./migrations/sql_scripts_accounts as acc_migration,
  ./migrations/sql_scripts_app as app_migration

export sqlcipher

type
  DbError* = object of StatusError

proc initializeDB*(path: string): DbConn {.raises: [DbError, Defect].} =
  const errorMsg = "Error initializing database"
  try:

    createDir path.parentDir()
    var runMigrations = false
    if not path.fileExists():
      runMigrations = true
    result = openDatabase(path)
    if runMigrations:
      let definition = acc_migration.newMigrationDefinition()
      if not result.migrate(definition).isOk:
        raise newException(DbError, "Failure executing migrations")

  except IOError as e:
    raise (ref DbError)(parent: e, msg: errorMsg)
  except OSError as e:
    raise (ref DbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
    raise (ref DbError)(parent: e, msg: errorMsg)

proc hash(password: string): string {.raises: [].} =
  "0x" & toUpper($keccak_256.digest(password))

proc initializeDB*(path, password: string): DbConn {.raises:
  [DbError, Defect].} =

  const errorMsg = "Error initializing database"
  try:
    createDir path.parentDir()
    var runMigrations = false
    if not path.fileExists():
      runMigrations = true
    result = openDatabase(path)
    result.key(password.hash)
    # Custom encryption settings are used by status-go with sqlcipher v3 to
    # accommodate lower-performance mobile devices. See:
    # * https://github.com/status-im/status-go/pull/1343
    # * https://github.com/status-im/status-go/blob/81171ad9e64feeceff81bc78b1aefba196cb1172/sqlite/sqlite.go#L12-L21
    # nim-status will instead use sqlcipher v4's defaults, but in the future we
    # may need to allow custom settings to be specified at compile time.
    # ----------------------------------------------------------------------------
    # result.exec("PRAGMA cipher_page_size = 1024")
    # result.exec("PRAGMA kdf_iter = 3200")
    # result.exec("PRAGMA cipher_hmac_algorithm = HMAC_SHA1")
    # result.exec("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1")
    # ----------------------------------------------------------------------------
    result.exec("PRAGMA foreign_keys = ON")
    result.exec("PRAGMA journal_mode = WAL")
    if runMigrations:
      let definition = app_migration.newMigrationDefinition()
      if not result.migrate(definition).isOk:
        raise newException(DbError, "Failure executing migrations")

  except IOError as e:
    raise (ref DbError)(parent: e, msg: errorMsg)
  except OSError as e:
    raise (ref DbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
    raise (ref DbError)(parent: e, msg: errorMsg)
