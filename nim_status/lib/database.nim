import sqlcipher
import migration
import results

proc initializeDB*(path:string, definition: MigrationDefinition, runMigrations = true):DbConn =
  result = openDatabase(path)
  if runMigrations and not result.migrate(definition).isOk:
    raise newException(SqliteError, "Failure executing migrations")


proc initializeDB*(path, password: string, definition: MigrationDefinition, runMigrations = true):DbConn =
  result = openDatabase(path)
  result.key(password)
  if runMigrations and not result.migrate(definition).isOk:
    raise newException(SqliteError, "Failure executing migrations")
