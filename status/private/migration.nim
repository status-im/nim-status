{.push raises: [Defect].}

import # std libs
  std/[algorithm, sequtils, strformat, tables]

import # vendor libs
  chronicles, nimcrypto, sqlcipher,
  stew/[byteutils, results]

import # status modules
  ./migrations/types

export MigrationDefinition

type Migration* {.dbTableName("migrations").} = object
  name* {.dbColumnName("name").}: string
  hash* {.dbColumnName("hash").}: string

type MigrationResult* = Result[Migration, string]


proc createMigrationTableIfNotExists*(db: DbConn) {.raises: [Exception].} =

  var migration: Migration
  const query = fmt"""CREATE TABLE IF NOT EXISTS {migration.tableName} (
                          {migration.name.columnName} VARCHAR NOT NULL PRIMARY KEY,
                          {migration.hash.columnName} VARCHAR NOT NULL
                        )"""
  db.execScript(query)


proc getLastMigrationExecuted*(db: DbConn): MigrationResult {.raises: [Defect,
  Exception].} =

  var migration: Migration
  db.createMigrationTableIfNotExists()
  const query = fmt"SELECT {migration.name.columnName}, {migration.hash.columnName} FROM {migration.tableName} ORDER BY rowid DESC LIMIT 1"
  let queryResult = db.one(Migration, query)
  if not queryResult.isSome:
    return  MigrationResult.err("No migrations were executed")
  MigrationResult.ok(queryResult.get())

proc getAllMigrationsExecuted*(db: DbConn): seq[Migration] {.raises: [Defect,
  Exception].} =

  db.createMigrationTableIfNotExists()
  var migration: Migration
  const query = fmt"SELECT {migration.name.columnName}, {migration.hash.columnName} FROM {migration.tableName} ORDER BY rowid ASC;"
  db.all(Migration, query)

proc checkMigrations*(db: DbConn, definition: MigrationDefinition): bool
  {.raises: [Defect, Exception].} =

  let allMigrationsExecuted = db.getAllMigrationsExecuted()
  let migrations = toSeq(definition.migrationUp.keys)

  debug "Verifying migration data"

  if allMigrationsExecuted.len > migrations.len:
    warn "DB version might be greater than source code", migrationsInCode=migrations.len, migrationsExecuted=allMigrationsExecuted.len
    return false

  var i = -1
  for migration in allMigrationsExecuted:
    i += 1
    if migrations[i] != migration.name:
      warn "Migration order mismatch", migration=migration.name
      return false

    if keccak_256.digest(definition.migrationUp[migration.name]).data.toHex() != migration.hash:
      warn "Migration hash mismatch", migration=migration.name
      return false

  return true


proc isUpToDate*(db: DbConn, definition: MigrationDefinition): bool {.raises:
  [Defect, Exception].} =

  let lastMigrationExecuted = db.getLastMigrationExecuted()
  if lastMigrationExecuted.isOk:
    # Check what's the latest migration
    let currentMigration = lastMigrationExecuted.get()

    var index = 0
    for name in definition.migrationUp.keys:
      if name == currentMigration.name and index == definition.migrationUp.len - 1:
        return true
      index += 1

  result = false


proc migrate*(db: DbConn, definition: MigrationDefinition): MigrationResult
  {.raises: [Defect, Exception].} =

  db.createMigrationTableIfNotExists()
  if not db.checkMigrations(definition): return MigrationResult.err "db/migration mismatch"
  var migration: Migration
  let lastMigrationExecuted = db.getLastMigrationExecuted()
  if not lastMigrationExecuted.isOk:
    try:
      db.transaction:
        for name, query in definition.migrationUp.pairs:
          debug "Executing migration", name
          db.execScript(string.fromBytes(query))
          db.exec(fmt"INSERT INTO {migration.tableName}({migration.name.columnName}, {migration.hash.columnName}) VALUES(?, ?)", name, keccak_256.digest(query).data.toHex())
    except SqliteError:
      let msg = getCurrentExceptionMsg()
      warn "Could not execute migration", msg
      return MigrationResult.err "Could not execute migration"
  else:
    if db.isUpToDate(definition): return lastMigrationExecuted

    let allMigrationsExecuted = db.getAllMigrationsExecuted()
    var index = -1
    try:
      db.transaction:
        for name, query in definition.migrationUp.pairs:
          index += 1
          if index <= (allMigrationsExecuted.len - 1): continue
          debug "Executing migration", name
          db.execScript(string.fromBytes(query))
          db.exec(fmt"INSERT INTO {migration.tableName}({migration.name.columnName}, {migration.hash.columnName}) VALUES(?, ?)", name, keccak_256.digest(query).data.toHex())
    except SqliteError:
      let msg = getCurrentExceptionMsg()
      warn "Could not execute migration", msg
      return MigrationResult.err "Could not execute migration"

  return db.getLastMigrationExecuted()


proc tearDown*(db: DbConn, definition: MigrationDefinition): bool {.raises:
  [Defect, Exception].} =

  var migration: Migration
  var allMigrationsExecuted = db.getAllMigrationsExecuted().reversed()
  try:
    db.transaction:
      for m in allMigrationsExecuted:
        debug "Rolling back migration", name=m.name
        if definition.migrationDown.hasKey(m.name):
          let script = string.fromBytes(definition.migrationDown[m.name])
          if script != "": db.execScript(script)
        db.exec(fmt"DELETE FROM {migration.tableName} WHERE {migration.name.columnName} = ?", m.name)
  except SqliteError:
    warn "Could not rollback migration"
    return false
  return true
