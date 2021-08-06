import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  status/private/[database, mailservers]

import # test modules
  ./test_helpers

procSuite "mailservers":
  asyncTest "mailservers":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let db = initializeDB(path, password)

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

    check:
      dbMailservers.len == 3

    db.deleteMailserver(mailserver1)

    dbMailservers = db.getMailservers()

    echo dbMailservers

    check:
      dbMailservers.len == 2

    db.close()
    removeFile(path)
