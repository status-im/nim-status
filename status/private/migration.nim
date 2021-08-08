{.push raises: [Defect].}

import # std libs
  std/[algorithm, options, sequtils, strformat, tables]

import # vendor libs
  chronicles, nimcrypto, sqlcipher,
  stew/[byteutils, results]

import # status modules
  ./common, ./migrations/types

export MigrationDefinition

type
  Migration* {.dbTableName("migrations").} = object
    name* {.dbColumnName("name").}: string
    hash* {.dbColumnName("hash").}: string

  MigrationResult* = Result[Migration, string]

  MigrationError* = object of StatusError


proc createMigrationTableIfNotExists*(db: DbConn) {.raises: [MigrationError].} =

  var migration: Migration
  const errorMsg = "Error creating migration table if not exists"
  const query = fmt"""CREATE TABLE IF NOT EXISTS {migration.tableName} (
                        {migration.name.columnName} VARCHAR NOT NULL PRIMARY KEY,
                        {migration.hash.columnName} VARCHAR NOT NULL
                      )"""
  try:

    db.execScript(query)

  except SqliteError as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg)
  except Exception as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg)


proc getLastMigrationExecuted*(db: DbConn): MigrationResult {.raises:
  [AssertionError, MigrationError, UnpackError].} =

  var migration: Migration
  const errorMsg = "Error getting last migration executed"

  db.createMigrationTableIfNotExists()

  const query = fmt"""SELECT    {migration.name.columnName},
                                {migration.hash.columnName}
                      FROM      {migration.tableName}
                      ORDER BY  rowid DESC
                      LIMIT 1"""
  try:

    let queryResult = db.one(Migration, query)
    if not queryResult.isSome:
      return  MigrationResult.err("No migrations were executed")

    return MigrationResult.ok(queryResult.get())

  except SqliteError as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg)

proc getAllMigrationsExecuted*(db: DbConn): seq[Migration] {.raises:
  [AssertionError, MigrationError].} =

  const errorMsg = "Error getting all migrations executed"
  db.createMigrationTableIfNotExists()
  var migration: Migration
  const query = fmt"""SELECT    {migration.name.columnName},
                                {migration.hash.columnName}
                      FROM      {migration.tableName}
                      ORDER BY  rowid ASC;"""
  try:

    return db.all(Migration, query)

  except SqliteError as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg)

proc checkMigrations*(db: DbConn, definition: MigrationDefinition): bool
  {.raises: [AssertionError, Defect, MigrationError].} =

  let allMigrationsExecuted = db.getAllMigrationsExecuted()
  let migrations = toSeq(definition.migrationUp.keys)

  debug "Verifying migration data"

  if allMigrationsExecuted.len > migrations.len:
    warn "DB version might be greater than source code", migrationsInCode=migrations.len, migrationsExecuted=allMigrationsExecuted.len
    return false

  const errorMsg = "Error checking migration hash for mismatch"
  var i = -1
  try:

    for migration in allMigrationsExecuted:
      i += 1
      if migrations[i] != migration.name:
        warn "Migration order mismatch", migration=migration.name
        return false

      let hash = keccak_256.digest(definition.migrationUp[migration.name])
      if hash.data.toHex() != migration.hash:
        warn "Migration hash mismatch", hashDataToHex=hash.data.toHex, migrationHash=migration.hash
        warn "Migration hash mismatch", migration=migration.name
        return false

  except KeyError as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg &
      ", migration not defined")
  except ValueError as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg)

  return true


proc isUpToDate*(db: DbConn, definition: MigrationDefinition): bool {.raises:
  [AssertionError, MigrationError, ResultDefect, UnpackError].} =

  let lastMigrationExecuted = db.getLastMigrationExecuted()
  if lastMigrationExecuted.isOk:
    # Check what's the latest migration
    var currentMigration: Migration
    currentMigration = lastMigrationExecuted.get()

    var index = 0
    for name in definition.migrationUp.keys:
      if name == currentMigration.name and index == definition.migrationUp.len - 1:
        return true
      index += 1

  result = false

proc execMigration(db: DbConn, name: string, query: seq[byte]) {.raises:
  [MigrationError].} =

  debug "Executing migration", name
  const errorMsg = "Error executing migration"
  try:

    db.execScript(string.fromBytes(query))

    var migration: Migration
    let
      migQuery = fmt"""INSERT INTO  {migration.tableName} (
                                      {migration.name.columnName},
                                      {migration.hash.columnName}
                                    )
                    VALUES          (?, ?)"""
      hash = keccak_256.digest(query)

    db.exec(migQuery, name, hash.data.toHex)

  except SqliteError as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg)
  except Exception as e:
    raise (ref MigrationError)(parent: e, msg: errorMsg)

proc migrate*(db: DbConn, definition: MigrationDefinition): MigrationResult
  {.raises: [].} =

  const errorMsg = "Could not execute migration, "

  try:

    db.createMigrationTableIfNotExists()

    if not db.checkMigrations(definition):
      return MigrationResult.err "db/migration mismatch"

    let lastMigrationExecuted = db.getLastMigrationExecuted()
    if not lastMigrationExecuted.isOk:
      db.transaction:
        for name, query in definition.migrationUp.pairs:
          db.execMigration(name, query)
    else:
      if db.isUpToDate(definition):
        return lastMigrationExecuted

      let allMigrationsExecuted = db.getAllMigrationsExecuted()
      var index = -1
      db.transaction:
        for name, query in definition.migrationUp.pairs:
          index += 1
          if index <= (allMigrationsExecuted.len - 1): continue
          db.execMigration(name, query)

    return db.getLastMigrationExecuted()

  except MigrationError as e:
    warn "Could not execute migration", msg=e.msg
    return MigrationResult.err errorMsg & e.msg
  except Exception as e: # comes from db.transaction
    warn "Could not execute migration", msg=e.msg
    return MigrationResult.err errorMsg & e.msg


proc tearDown*(db: DbConn, definition: MigrationDefinition): bool {.raises:
  [AssertionError].} =

  const errorMsg = "Could not rollback migration"
  var
    migration: Migration
    allMigrationsExecuted: seq[Migration]

  try:
    allMigrationsExecuted = db.getAllMigrationsExecuted().reversed()
  except MigrationError:
    warn errorMsg
    return false

  try:
    db.transaction:
      for m in allMigrationsExecuted:
        debug "Rolling back migration", name=m.name
        if definition.migrationDown.hasKey(m.name):
          let script = string.fromBytes(definition.migrationDown[m.name])
          if script != "": db.execScript(script)
        db.exec(fmt"""DELETE FROM   {migration.tableName}
                      WHERE         {migration.name.columnName} = ?""", m.name)
  except SqliteError:
    warn errorMsg
    return false
  except Exception:
    warn errorMsg
    return false
  return true
