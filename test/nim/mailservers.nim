import sqlcipher
import os, json, json_serialization
import options
import ../../nim_status/lib/mailservers
import ../../nim_status/lib/database
import ../../nim_status/lib/migrations/sql_scripts_app

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/my.db"
let db = initializeDB(path, passwd, newMigrationDefinition())

let mailserver1 = Mailserver(
  id: "mailserver-1",
  name: "foo",
  address: "bar",
  password: some("baz"),
  fleet: "quux"
)

let mailserver2 = Mailserver(
  id: "mailserver-2",
  name: "foo",
  address: "bar",
  password: some("baz"),
  fleet: "quux"
)

let mailserver3 = Mailserver(
  id: "mailserver-3",
  name: "foo",
  address: "bar",
  password: some("baz"),
  fleet: "quux"
)

db.saveMailserver(mailserver1)
db.saveMailservers(@[mailserver2, mailserver3])

var dbMailservers = db.getMailservers()

echo dbMailservers

assert dbMailservers.len == 3

db.deleteMailserver(mailserver1)

dbMailservers = db.getMailservers()

echo dbMailservers

assert dbMailservers.len == 2

db.close()
removeFile(path)
