import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  status/private/[common, database, mailservers]

import # test modules
  ./test_helpers

procSuite "mailservers":
  asyncTest "mailservers":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initUserDb(path, password)
    check dbResult.isOk

    let db = dbResult.get

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

    check db.saveMailserver(mailserver1).isOk
    check db.saveMailservers(@[mailserver2, mailserver3]).isOk

    var dbMailservers = db.getMailservers()

    echo dbMailservers

    check:
      dbMailservers.isOk
      dbMailservers.get.len == 3
      db.deleteMailserver(mailserver1).isOk

    dbMailservers = db.getMailservers()

    echo dbMailservers

    check:
      dbMailservers.isOk
      dbMailservers.get.len == 2

    db.close()
    removeFile(path)
