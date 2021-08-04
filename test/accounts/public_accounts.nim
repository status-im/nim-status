import # std libs
  std/[json, options, os, times, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  ../../status/private/[accounts/public_accounts, conversions, database]

import # test modules
  ../test_helpers

procSuite "public accounts":
  asyncTest "saveAccount, updateAccountTimestamp, deleteAccount":
    let path = currentSourcePath.parentDir().parentDir() & "/build/my.db"
    removeFile(path)
    let db = initializeDB(path)

    let timestamp1 = getTime()

    var account:PublicAccount = PublicAccount(
      creationTimestamp: timestamp1.toUnix,
      name: "Test",
      identicon: "data:image/png;base64,something",
      keycardPairing: "",
      keyUid: "0x1234"
    )

    db.saveAccount(account)

    # check that the values saved correctly
    var accountList = db.getPublicAccounts()
    check:
      accountList[0].creationTimestamp == timestamp1.toUnix
      accountList[0].name == account.name
      accountList[0].identicon == account.identicon
      accountList[0].keycardPairing == account.keycardPairing
      accountList[0].keyUid == account.keyUid
      accountList[0].loginTimestamp.isSome == false

    let acctByKeyUid = db.getPublicAccount(account.keyUid)
    check:
      acctByKeyUid.isSome
    let acctByKeyUidVal = acctByKeyUid.get
    check:
      acctByKeyUidVal.creationTimestamp == timestamp1.toUnix
      acctByKeyUidVal.name == account.name
      acctByKeyUidVal.identicon == account.identicon
      acctByKeyUidVal.keycardPairing == account.keycardPairing
      acctByKeyUidVal.keyUid == account.keyUid
      acctByKeyUidVal.loginTimestamp.isSome == false

    let timestamp2 = timestamp1 + 100.minutes

    # check that we can update name, identicon, keycardPairing, loginTimestamp
    account.name = account.name & "_updated"
    account.identicon = account.identicon & "_updated"
    account.keycardPairing = account.keycardPairing & "_updated"
    account.loginTimestamp = timestamp2.toUnix.some
    db.updateAccount(account)
    accountList = db.getPublicAccounts()

    check:
      accountList.len == 1
      accountList[0].creationTimestamp == timestamp1.toUnix
      accountList[0].name == account.name
      accountList[0].identicon == account.identicon
      accountList[0].keycardPairing == account.keycardPairing
      accountList[0].loginTimestamp == account.loginTimestamp
      accountList[0].keyUid == account.keyUid # should not have been updated

    # check that we only update timestamp with `updateAccountTimestamp`
    let newTimestamp = 1
    db.updateAccountTimestamp(newTimestamp, account.keyUid)
    accountList = db.getPublicAccounts()

    check:
      accountList.len == 1
      accountList[0].name == account.name
      accountList[0].identicon == account.identicon
      accountList[0].keycardPairing == account.keycardPairing
      accountList[0].loginTimestamp.isSome and
        accountList[0].loginTimestamp.get == newTimestamp
      accountList[0].keyUid == account.keyUid

    # check that we can delete accounts
    db.deleteAccount(account.keyUid)
    accountList = db.getPublicAccounts()

    check:
      accountList.len == 0

    db.close()
    removeFile(path)
