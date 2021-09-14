import # std libs
  std/[os, tables, unittest]

import # vendor libs
  chronos, sqlcipher, stew/[byteutils, results]

import # status lib
  status/private/migration,
  status/private/migrations/sql_scripts_accounts as migration_accounts

import # test modules
  ./test_helpers

procSuite "migrations":
  asyncTest "migrations":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    var db = openDatabase(path)

    db.key(password)

    var
      migrationDefinition = migration_accounts.newMigrationDefinition()
      lastMigration = db.getLastMigrationExecuted()

    check:
      lastMigration.isErr
      lastMigration.error == NoMigrationsExecuted
      db.migrate(migrationDefinition).isOk
      db.isUpToDate(migrationDefinition).isOk

    # Create new migrations to check if isUpToDate and migrate work as expected
    migrationDefinition.migrationUp["002_abc"] = "CREATE TABLE anotherTable (address VARCHAR NOT NULL PRIMARY KEY) WITHOUT ROWID;".toBytes
    migrationDefinition.migrationDown["002_abc"] = "DROP TABLE anotherTable;".toBytes

    var isUpToDate = db.isUpToDate(migrationDefinition)
    check:
      isUpToDate.isOk
      isUpToDate.get == false
      db.migrate(migrationDefinition).isOk
      db.isUpToDate(migrationDefinition).isOk
      db.migrate(migrationDefinition).isOk
      db.tearDown(migrationDefinition).isOk
      db.tearDown(migrationDefinition).isOk
    isUpToDate = db.isUpToDate(migrationDefinition)
    check:
      isUpToDate.isOk
      isUpToDate.get == false

    lastMigration = db.getLastMigrationExecuted()
    check:
      lastMigration.isErr
      lastMigration.error == NoMigrationsExecuted

    db.close()
    removeFile(path)
