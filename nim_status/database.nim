import results, sqlcipher

import ./migration

proc initializeDB*(path, password: string):DbConn =
  result = openDatabase(path)
  result.key(password)
  if not result.migrate().isOk:
    raise newException(SqliteError, "Failure executing migrations")
