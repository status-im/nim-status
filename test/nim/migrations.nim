import # nim libs
  os, tables, unittest

import # vendor libs
  chronos, results, sqlcipher, stew/byteutils

import # nim-status libs
  ../../nim_status/migration,
  ../../nim_status/migrations/sql_scripts_accounts as migration_accounts,
  ./test_helpers

procSuite "migrations":
  asyncTest "migrations":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    var db = openDatabase(path)

    db.key(password)

    var migrationDefinition = migration_accounts.newMigrationDefinition()

    check:
      db.getLastMigrationExecuted().error() == "No migrations were executed"
      db.migrate(migrationDefinition).isOk
      db.isUpToDate(migrationDefinition)

    # Create new migrations to check if isUpToDate and migrate work as expected
    migrationDefinition.migrationUp["002_abc"] = "CREATE TABLE anotherTable (address VARCHAR NOT NULL PRIMARY KEY) WITHOUT ROWID;".toBytes
    migrationDefinition.migrationDown["002_abc"] = "DROP TABLE anotherTable;".toBytes

    check:
      not db.isUpToDate(migrationDefinition)
      db.migrate(migrationDefinition).isOk
      db.isUpToDate(migrationDefinition)
      db.migrate(migrationDefinition).isOk
      db.tearDown(migrationDefinition)
      db.tearDown(migrationDefinition)
      not db.isUpToDate(migrationDefinition)
      db.getLastMigrationExecuted().error() == "No migrations were executed"

    db.close()
    removeFile(path)
