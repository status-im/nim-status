import results, sqlcipher

import ./migration

proc initializeDB*(path:string, definition: MigrationDefinition):DbConn =
  result = openDatabase(path)
  if not result.migrate(definition).isOk:
    raise newException(SqliteError, "Failure executing migrations")


proc initializeDB*(path, password: string, definition: MigrationDefinition):DbConn =
  result = openDatabase(path)
  result.key(password)
  if not result.migrate(definition).isOk:
    raise newException(SqliteError, "Failure executing migrations")
