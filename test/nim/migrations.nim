import # nim libs
  os, tables, unittest

import # vendor libs
  chronos, results, sqlcipher, stew/byteutils

import # nim-status libs
  ../../nim_status/migration,
  ../../nim_status/migrations/sql_scripts,
  ./test_helpers

procSuite "migrations":
  asyncTest "migrations":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    var db = openDatabase(path)

    db.key(password)

    check:
      db.getLastMigrationExecuted().error() == "No migrations were executed"
      db.migrate().isOk
      db.isUpToDate()

    # !!! migrationUp, migrationDown were changed from `var` to `const`, so it's not possible to make the changes below
    # Creating dinamically new migrations just to check if isUpToDate and migrate work as expected
    # migrationUp["002_abc"] = "CREATE TABLE anotherTable (address VARCHAR NOT NULL PRIMARY KEY) WITHOUT ROWID;".toBytes
    # migrationDown["002_abc"] = "DROP TABLE anotherTable;".toBytes

    check:
      # not db.isUpToDate()
      db.migrate().isOk
      db.isUpToDate()
      db.migrate().isOk
      db.tearDown()
      db.tearDown()
      not db.isUpToDate()
      db.getLastMigrationExecuted().error() == "No migrations were executed"

    db.close()
    removeFile(path)
