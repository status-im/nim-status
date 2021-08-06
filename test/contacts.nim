import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  status/private/[contacts, conversions, database, migrations/sql_scripts_app]

import # test modules
  ./test_helpers

procSuite "contacts":
  asyncTest "contacts":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let db = initializeDB(path, password)

    let contact1 = Contact(
      id: "Contact1",
      address: some("0xdeadbeefdeadbeefdeadbeefdeadbeef11111111".parseAddress),
      name: some("TheUsername1"),
      ensVerified: true,
      ensVerifiedAt: 11111,
      lastEnsClockValue: 111,
      ensVerificationRetries: 1,
      alias: some("Teenage Mutant NinjaTurtle"),
      identicon: "ABCDEF",
      photo: some("ABC"),
      lastUpdated: 11111,
      systemTags: @["tag11","tag12","tag13"],
      deviceInfo: @[ContactDeviceInfo(installationId: "ABC1", timestamp: 11, fcmToken: "ABC1")],
      tributeToTalk: some("ABC1"),
      localNickname: some("ABC1")
    )

    let contact2 = Contact(
      id: "Contact2",
      address: some("0xdeadbeefdeadbeefdeadbeefdeadbeef22222222".parseAddress),
      name: some("TheUsername2"),
      ensVerified: true,
      ensVerifiedAt: 22222,
      lastEnsClockValue: 222,
      ensVerificationRetries: 2,
      alias: some("Teenage Mutant NinjaTurtle"),
      identicon: "ABCDEF",
      photo: some("ABC"),
      lastUpdated: 22222,
      systemTags: @["tag21","tag22","tag23"],
      deviceInfo: @[ContactDeviceInfo(installationId: "ABC2", timestamp: 22, fcmToken: "ABC2")],
      tributeToTalk: some("ABC2"),
      localNickname: some("ABC2")
    )


    let contact3 = Contact(
      id: "Contact3",
      address: some("0xdeadbeefdeadbeefdeadbeefdeadbeef33333333".parseAddress),
      name: some("TheUsername3"),
      ensVerified: true,
      ensVerifiedAt: 33333,
      lastEnsClockValue: 333,
      ensVerificationRetries: 3,
      alias: some("Teenage Mutant NinjaTurtle"),
      identicon: "ABCDEF",
      photo: some("ABC"),
      lastUpdated: 33333,
      systemTags: @["tag31","tag32","tag33"],
      deviceInfo: @[ContactDeviceInfo(installationId: "ABC3", timestamp: 33, fcmToken: "ABC3")],
      tributeToTalk: some("ABC3"),
      localNickname: some("ABC3")
    )

    # TODO: begin transaction

    db.saveContact(contact1)
    var dbContacts = db.getContacts()

    check:
      dbContacts.len == 1
      dbContacts[0] == contact1

    db.saveContacts(@[contact2, contact3])
    dbContacts = db.getContacts()

    check:
      dbContacts.len == 3
      dbContacts == @[contact1, contact2, contact3]

    echo dbContacts

    db.close()
    removeFile(path)
