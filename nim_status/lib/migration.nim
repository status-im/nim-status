import sqlcipher, results
import sequtils, tables, algorithm
import stew/byteutils
import migrations/sql_scripts
import nimcrypto
import chronicles

type MigrationResult = Result[string, string]

proc createMigrationTableIfNotExists*(db: DbConn) =
  const settingSQL = """CREATE TABLE IF NOT EXISTS migrations (
                          name VARCHAR NOT NULL PRIMARY KEY,
                          hash VARCHAR NOT NULL
                        )"""
  db.execScript(settingSQL)


proc getLastMigrationExecuted*(db: DbConn): MigrationResult =
  db.createMigrationTableIfNotExists()
  const query = "SELECT name FROM migrations ORDER BY rowid DESC LIMIT 1;"
  for r in rows(db, query):
    return MigrationResult.ok r[0].strVal
  return MigrationResult.err "No migrations were executed"


proc getAllMigrationsExecuted*(db: DbConn): OrderedTable[string, string] =
  db.createMigrationTableIfNotExists()
  const query = "SELECT name, hash FROM migrations ORDER BY rowid ASC;"
  result = initOrderedTable[string, string]()
  for r in rows(db, query):
    result[r[0].strVal] = r[1].strVal


proc checkMigrations*(db: DbConn): bool =
  let allMigrationsExecuted = db.getAllMigrationsExecuted()
  let migrations = toSeq(migrationUp.keys)
  
  debug "Verifying migration data"

  if toSeq(allMigrationsExecuted.keys).len > migrations.len:
    warn "DB version might be greater than source", migrationsInCode=migrations.len, migrationsExecuted=toSeq(allMigrationsExecuted.keys).len
    return false

  var i = -1
  for name, hash in allMigrationsExecuted.pairs:
    i += 1
    if migrations[i] != name: 
      warn "Migration order mismatch", name
      return false

    if keccak_256.digest(migrationUp[name]).data.toHex() != hash:
      warn "Migration hash mismatch", name
      return false

  return true


proc isUpToDate*(db: DbConn):bool =
  let lastMigrationExecuted = db.getLastMigrationExecuted()
  if lastMigrationExecuted.isOk:
    # Check what's the latest migration
    let currentMigration = lastMigrationExecuted.get()
    
    var index = 0
    for name in migrationUp.keys:
      if name == currentMigration and index == migrationUp.len - 1:
        return true
      index += 1
  
  result = false


proc migrate*(db: DbConn): MigrationResult =
  db.createMigrationTableIfNotExists()
  if not db.checkMigrations(): return MigrationResult.err "db/migration mismatch"

  let lastMigrationExecuted = db.getLastMigrationExecuted()
  if not lastMigrationExecuted.isOk:
    try:
      db.exec("BEGIN")
      for name, query in migrationUp.pairs:
        debug "Executing migration", name
        db.execScript(string.fromBytes(query))
        db.exec("INSERT INTO migrations(name, hash) VALUES(?, ?)", name, keccak_256.digest(query).data.toHex())
      db.exec("COMMIT")
    except SqliteError:
      db.execScript("ROLLBACK")
      warn "Could not execute migration"
      return MigrationResult.err "Could not execute migration"
  else:
    if db.isUpToDate(): return lastMigrationExecuted
    
    let allMigrationsExecuted = db.getAllMigrationsExecuted()
    var index = -1
    try:
      db.execScript("BEGIN")
      for name, query in migrationUp.pairs:
        index += 1
        if index <= (allMigrationsExecuted.len - 1): continue
        debug "Executing migration", name
        db.execScript(string.fromBytes(query))
        db.exec("INSERT INTO migrations(name, hash) VALUES(?, ?)", name, keccak_256.digest(query).data.toHex())
      db.execScript("COMMIT")
    except SqliteError:
      warn "Could not execute migration"
      db.execScript("ROLLBACK")
      return MigrationResult.err "Could not execute migration"

  return db.getLastMigrationExecuted()


proc tearDown*(db: DbConn):bool =
  var allMigrationsExecuted = toSeq(db.getAllMigrationsExecuted().keys)
  allMigrationsExecuted.reverse()
  try:
    db.execScript("BEGIN")
    for migration in allMigrationsExecuted:
      debug "Rolling back migration", migration
      if migrationDown.hasKey(migration):
        let script = string.fromBytes(migrationDown[migration])
        if script != "": db.execScript(script)
      db.exec("DELETE FROM migrations WHERE name = ?", migration)
    db.execScript("COMMIT")
  except SqliteError:
    warn "Could not rollback migration"
    db.execScript("ROLLBACK")
    return false
  return true

