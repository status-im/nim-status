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

  MigrationError* = enum
    DbMigrationMismatch   = "migrations: db/migration mismatch"
    DataAndTypeMismatch   = "migrations: failed to deserialise data to " &
                              "supplied type"
    IndexOutOfBounds      = "migrations: index out of bounds"
    NoMigrationsExecuted  = "migrations: no migrations executed"
    OperationError        = "migrations: database operation error"
    QueryBuildError       = "migrations: invalid values used to build query"
    UnknownError          = "migrations: unknown error"

  MigrationResult*[T] = Result[T, MigrationError]


proc createMigrationTableIfNotExists*(db: DbConn): MigrationResult[void]
  {.raises: [].} =

  var migration: Migration
  const query = fmt"""CREATE TABLE IF NOT EXISTS {migration.tableName} (
                        {migration.name.columnName} VARCHAR NOT NULL PRIMARY KEY,
                        {migration.hash.columnName} VARCHAR NOT NULL
                      )"""
  try:
    db.execScript(query)
    ok()
  except SqliteError: err OperationError
  except Exception: err UnknownError


proc getLastMigrationExecuted*(db: DbConn): MigrationResult[Migration] {.raises:
  [AssertionError].} =


  ?db.createMigrationTableIfNotExists()

  try:
    var migration: Migration
    const query = fmt"""SELECT    {migration.name.columnName},
                                  {migration.hash.columnName}
                        FROM      {migration.tableName}
                        ORDER BY  rowid DESC
                        LIMIT 1"""

    let queryResult = db.one(Migration, query)
    if queryResult.isNone:
      return err NoMigrationsExecuted

    ok(queryResult.get)

  except SqliteError: err OperationError
  except UnpackError: err DataAndTypeMismatch
  except ValueError: err QueryBuildError

proc getAllMigrationsExecuted*(db: DbConn): MigrationResult[seq[Migration]]
  {.raises: [AssertionError].} =

  ?db.createMigrationTableIfNotExists()
  try:
    var migration: Migration
    const query = fmt"""SELECT    {migration.name.columnName},
                                  {migration.hash.columnName}
                        FROM      {migration.tableName}
                        ORDER BY  rowid ASC;"""
    ok db.all(Migration, query)
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc checkMigrations*(db: DbConn, definition: MigrationDefinition):
  MigrationResult[bool] {.raises: [AssertionError, Defect].} =

  let allMigrationsExecuted = ?db.getAllMigrationsExecuted()
  let migrations = toSeq(definition.migrationUp.keys)

  debug "Verifying migration data"

  if allMigrationsExecuted.len > migrations.len:
    warn "DB version might be greater than source code",
      migrationsInCode=migrations.len,
      migrationsExecuted=allMigrationsExecuted.len
    return ok false

  var i = -1
  try:

    for migration in allMigrationsExecuted:
      i += 1
      if migrations[i] != migration.name:
        warn "Migration order mismatch", migration=migration.name
        return ok false

      let hash = keccak_256.digest(definition.migrationUp[migration.name])
      if hash.data.toHex() != migration.hash:
        warn "Migration hash mismatch", hashDataToHex=hash.data.toHex,
          migrationHash=migration.hash
        warn "Migration hash mismatch", migration=migration.name
        return ok false

  except KeyError: return err IndexOutOfBounds
  # except ValueError:
  #   raise (ref MigrationError)(parent: e, msg: errorMsg)

  ok true


proc isUpToDate*(db: DbConn, definition: MigrationDefinition):
  MigrationResult[bool] {.raises: [AssertionError, ResultDefect].} =

  let lastMigrationExecuted = db.getLastMigrationExecuted()
  if lastMigrationExecuted.isOk:
    # Check what's the latest migration
    var currentMigration: Migration
    currentMigration = lastMigrationExecuted.get()

    var index = 0
    for name in definition.migrationUp.keys:
      if name == currentMigration.name and index ==
        definition.migrationUp.len - 1:
        return ok true
      index += 1

  ok false

proc execMigration(db: DbConn, name: string, query: seq[byte]):
  MigrationResult[void] {.raises: [], used.} =

  debug "Executing migration", name
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
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError
  except Exception: err UnknownError

proc migrate*(db: DbConn, definition: MigrationDefinition):
  MigrationResult[Migration] {.raises: [].} =

  try:

    ?db.createMigrationTableIfNotExists()

    if not ?db.checkMigrations(definition):
      return err DbMigrationMismatch

    let lastMigrationExecuted = db.getLastMigrationExecuted()
    if not lastMigrationExecuted.isOk:
      db.transaction:
        for name, query in definition.migrationUp.pairs:
          ?db.execMigration(name, query)
    else:
      if ?db.isUpToDate(definition):
        return lastMigrationExecuted

      let allMigrationsExecuted = ?db.getAllMigrationsExecuted()
      var index = -1
      db.transaction:
        for name, query in definition.migrationUp.pairs:
          index += 1
          if index <= (allMigrationsExecuted.len - 1): continue
          ?db.execMigration(name, query)

    return db.getLastMigrationExecuted

  except Exception as e: # comes from db.transaction
    warn "Could not execute migration", msg=e.msg
    return err OperationError

proc tearDown*(db: DbConn, definition: MigrationDefinition): MigrationResult[bool]
  {.raises: [AssertionError].} =

  let allMigrationsExecuted = (?db.getAllMigrationsExecuted).reversed()

  try:
    db.transaction:
      for m in allMigrationsExecuted:
        debug "Rolling back migration", name=m.name
        if definition.migrationDown.hasKey(m.name):
          let script = string.fromBytes(definition.migrationDown[m.name])
          if script != "": db.execScript(script)
        var migration: Migration
        db.exec(fmt"""DELETE FROM   {migration.tableName}
                      WHERE         {migration.name.columnName} = ?""", m.name)
  except SqliteError: return err OperationError
  except Exception: # comes from db.transaction
    return err OperationError
  ok true
