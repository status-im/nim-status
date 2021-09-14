{.push raises: [Defect].}

import # std libs
  std/[algorithm, os, sequtils, strutils, sugar]

import # vendor libs
  chronicles, nimcrypto/keccak, sqlcipher

import # status modules
  ./common, ./util

export sqlcipher

type SchemaRow = object
  sql: string

proc staticReadSqlFiles(subdir: string): seq[string] =
  let dir = currentSourcePath.parentDir() / "database" / subdir
  var paths: seq[string]

  try:
    for kind, path in walkDir(dir):
      if kind == pcFile and ".sql" in path:
        paths.add path

    paths = sorted(paths, system.cmp[string])

    for path in paths:
      result.add path.staticRead.strip.replace("\r\n", "\n").replace("\r", "\n")

  except Exception:
    raise newException(Defect, "unable to read .sql files in " & dir)

const accountsDbMigrations = staticReadSqlFiles("accounts")

const accountsDbSchemaHashes = [
  "0x28854B208E827817841CE092415942450CEEC0CBD1D2465B4064FFDAF2D296A4"
]

const userDbMigrations = staticReadSqlFiles("user")

const userDbSchemaHashes = [
  "0xDD66374561205B700F7999ECF93D8E1BD4F69772C04A355DDE14CD916D8AE2D9"
]

const extraDbScripts = staticReadSqlFiles("extra")

when accountsDbSchemaHashes.len != accountsDbMigrations.len:
  {.fatal:
    "accountsDbSchemaHashes.len must be equal to accountsDbMigrations.len!".}

when userDbSchemaHashes.len != userDbMigrations.len:
  {.fatal: "userDbSchemaHashes.len must be equal to userDbMigrations.len!".}

proc hash(s: string): string = "0x" & toUpper($keccak_256.digest(s))

proc initDb*(path: string, encrypted: bool, migrations: openArray[string],
  schemaHashes: openArray[string], foreignKeys: bool, password: string = "",
  extraScripts: openArray[string] = @[]): DbResult[DbConn] =

  let latestVersion = migrations.len

  try:
    createDir path.parentDir()

    var
      runMigrations = false
      startAt = 1

    if not path.fileExists(): runMigrations = true

    let dbConn = openDatabase(path)

    if encrypted:
      dbConn.key(password.hash)

      # Custom encryption settings are used by status-go with sqlcipher v3 to
      # accommodate lower-performance mobile devices. See:
      # * https://github.com/status-im/status-go/pull/1343
      # * https://github.com/status-im/status-go/blob/81171ad9e64feeceff81bc78b1aefba196cb1172/sqlite/sqlite.go#L12-L21
      # nim-status will instead use sqlcipher v4's defaults, but in the future we
      # may need to allow custom settings to be specified at compile time.
      # --------------------------------------------------------------------------
      # dbConn.exec("PRAGMA cipher_page_size = 1024")
      # dbConn.exec("PRAGMA kdf_iter = 3200")
      # dbConn.exec("PRAGMA cipher_hmac_algorithm = HMAC_SHA1")
      # dbConn.exec("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1")
      # --------------------------------------------------------------------------

    if foreignKeys: dbConn.exec("PRAGMA foreign_keys = ON")
    dbConn.exec("PRAGMA journal_mode = WAL")

    if not runMigrations:
      let currentVersionOption = dbConn.value(int, "PRAGMA user_version")

      if not currentVersionOption.isSome: return err DbError.VersionUnavailable

      let currentVersion = currentVersionOption.get

      if currentVersion < 1:
        return err DbError.VersionTooLow
      elif currentVersion > latestVersion:
        return err DbError.VersionTooHigh
      elif currentVersion < latestVersion:
        runMigrations = true
        startAt = currentVersion + 1

      let
        schemaSql = dbConn.all(SchemaRow,
          """SELECT    sql
             FROM      sqlite_schema
             WHERE     sql IS NOT NULL
             ORDER BY  rootpage ASC""")

        sql = schemaSql
          .map(r => r.sql.strip)
          .join("\n\n")
          .replace("\r\n", "\n")
          .replace("\r", "\n")

        computed = sql.hash
        expected = schemaHashes[currentVersion - 1]

      if computed != expected:
        error "db schema hash mismatch", computed, expected,
          version=currentVersion

        return err DbError.SchemaHashMismatch

    if runMigrations:
      let migration = migrations[(startAt - 1)..^1].join("\n\n")
      dbConn.transaction:
        dbConn.execScript(migration)

        # N.B. "extra scripts" should not in any way change the schema of the
        # database (via e.g. CREATE TABLE). If they do change the schema, they
        # will effectively break the database versioning logic implemented in
        # this module.

        # "extra scripts" should be limited to filling a newly created database
        # with some default data, e.g. token data. The order in which "extra
        # scripts" are run should not matter.

        # Since it is expected that "extra scripts" will be updated over time,
        # for each script there should exist a nim-status API that can at
        # runtime update the same data in an existing database.

        for script in extraScripts: dbConn.execScript(script)

      dbConn.exec("PRAGMA user_version = " & $latestVersion)

    ok dbConn

  except SqliteError as e:
    if encrypted and e.msg.contains("file is not a database"):
      err DbError.KeyError
    else:
      err DbError.OperationError

  except Exception, IOError, OSError: return err InitFailure

proc initAccountsDb*(path: string): DbResult[DbConn] =
  initDb(path, false, accountsDbMigrations, accountsDbSchemaHashes, false)

proc initUserDb*(path, password: string): DbResult[DbConn] =
  initDb(path, true, userDbMigrations, userDbSchemaHashes, true, password,
    extraDbScripts)
