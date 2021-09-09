import # std libs
  std/[json, options, os, times, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  status/private/[accounts/public_accounts, conversions, database]

import # test modules
  ../test_helpers

procSuite "public accounts":
  asyncTest "saveAccount, updateAccountTimestamp, deleteAccount":
    let path = currentSourcePath.parentDir().parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initAccountsDb(path)
    check dbResult.isOk

    let db = dbResult.get

    let timestamp1 = getTime()

    var account: PublicAccount = PublicAccount(
      creationTimestamp: timestamp1.toUnix,
      name: "Test",
      identicon: "data:image/png;base64,something",
      keycardPairing: "",
      keyUid: "0x1234"
    )

    check db.saveAccount(account).isOk

    # check that the values saved correctly
    var accountList = db.getPublicAccounts()
    check accountList.isOk
    var dbAccount = accountList.get[0]
    check:
      dbAccount.creationTimestamp == timestamp1.toUnix
      dbAccount.name == account.name
      dbAccount.identicon == account.identicon
      dbAccount.keycardPairing == account.keycardPairing
      dbAccount.keyUid == account.keyUid
      dbAccount.loginTimestamp.isSome == false

    let acctByKeyUidResult = db.getPublicAccount(account.keyUid)
    check:
      acctByKeyUidResult.isOk
      acctByKeyUidResult.get.isSome

    let acctByKeyUidVal = acctByKeyUidResult.get.get
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
    check db.updateAccount(account).isOk

    accountList = db.getPublicAccounts()
    check:
      accountList.isOk
      accountList.get.len == 1

    dbAccount = accountList.get[0]

    check:
      dbAccount.creationTimestamp == timestamp1.toUnix
      dbAccount.name == account.name
      dbAccount.identicon == account.identicon
      dbAccount.keycardPairing == account.keycardPairing
      dbAccount.loginTimestamp == account.loginTimestamp
      dbAccount.keyUid == account.keyUid # should not have been updated

    # check that we only update timestamp with `updateAccountTimestamp`
    let newTimestamp = 1
    check db.updateAccountTimestamp(newTimestamp, account.keyUid).isOk
    accountList = db.getPublicAccounts()

    check:
      accountList.isOk
      accountList.get.len == 1

    dbAccount = accountList.get[0]

    check:
      dbAccount.name == account.name
      dbAccount.identicon == account.identicon
      dbAccount.keycardPairing == account.keycardPairing
      dbAccount.loginTimestamp.isSome and
      dbAccount.loginTimestamp.get == newTimestamp
      dbAccount.keyUid == account.keyUid

    # check that we can delete accounts
    check db.deleteAccount(account.keyUid).isOk
    accountList = db.getPublicAccounts()

    check:
      accountList.isOk
      accountList.get.len == 0

    db.close()
    removeFile(path)
