import os, results, sqlcipher

import ./migration

proc initializeDB*(path:string, definition: MigrationDefinition, runMigrations = true): DbConn =
  createDir path.parentDir()
  result = openDatabase(path)
  if runMigrations and not result.migrate(definition).isOk:
    raise newException(SqliteError, "Failure executing migrations")

proc initializeDB*(path, password: string, definition: MigrationDefinition, runMigrations = true): DbConn =
  createDir path.parentDir()
  result = openDatabase(path)
  result.key(password)
  result.execScript("PRAGMA cipher_page_size = 1024")
  result.execScript("PRAGMA kdf_iter = 3200")
  result.execScript("PRAGMA cipher_hmac_algorithm = HMAC_SHA1")
  result.execScript("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1")
  if runMigrations and not result.migrate(definition).isOk:
    raise newException(SqliteError, "Failure executing migrations")
