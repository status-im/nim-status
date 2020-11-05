import sqlcipher
import migration
import results

proc initializeDB*(path, password: string):DbConn =
  result = openDatabase(path)
  result.key(password)
  if not result.migrate().isOk:
    raise newException(SqliteError, "Failure executing migrations")

