import os, tables
import sqlcipher, results
import ../../nim_status/lib/migration
import ../../nim_status/lib/migrations/sql_scripts
import stew/byteutils

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
var dbConn = openDatabase(path)

dbConn.key(passwd)


assert dbConn.getLastMigrationExecuted().error() == "No migrations were executed"
assert dbConn.migrate().isOk
assert dbConn.isUpToDate()

# Creating dinamically new migrations just to check if isUpToDate and migrate work as expected
migrationUp["002_abc"] = "CREATE TABLE anotherTable (address VARCHAR NOT NULL PRIMARY KEY) WITHOUT ROWID;".toBytes
migrationDown["002_abc"] = "DROP TABLE anotherTable;".toBytes

assert not dbConn.isUpToDate()
assert dbConn.migrate().isOk

assert dbConn.isUpToDate()

assert dbConn.migrate().isOk

assert dbConn.tearDown()
assert dbConn.tearDown()

assert not dbConn.isUpToDate()
assert dbConn.getLastMigrationExecuted().error() == "No migrations were executed"


dbConn.close()