import os, tables
import sqlcipher, results
import ../../nim_status/lib/migration
import ../../nim_status/lib/migrations/sql_scripts_accounts as migration_accounts
import stew/byteutils

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
var dbConn = openDatabase(path)

dbConn.key(passwd)

var migrationDefinition = migration_accounts.newMigrationDefinition()

assert dbConn.getLastMigrationExecuted().error() == "No migrations were executed"
assert dbConn.migrate(migrationDefinition).isOk
assert dbConn.isUpToDate(migrationDefinition)

# Creating dinamically new migrations just to check if isUpToDate and migrate work as expected
migrationDefinition.migrationUp["002_abc"] = "CREATE TABLE anotherTable (address VARCHAR NOT NULL PRIMARY KEY) WITHOUT ROWID;".toBytes
migrationDefinition.migrationDown["002_abc"] = "DROP TABLE anotherTable;".toBytes

assert not dbConn.isUpToDate(migrationDefinition)
assert dbConn.migrate(migrationDefinition).isOk

assert dbConn.isUpToDate(migrationDefinition)

assert dbConn.migrate(migrationDefinition).isOk

assert dbConn.tearDown(migrationDefinition)
assert dbConn.tearDown(migrationDefinition)

assert not dbConn.isUpToDate(migrationDefinition)
assert dbConn.getLastMigrationExecuted().error() == "No migrations were executed"


dbConn.close()