import # nim libs
  json, options, os, times, unittest

import # vendor libs
  chronos, json_serialization, sqlcipher, web3/conversions as web3_conversions

import # nim-status libs
  ../../nim_status/[accounts, database, conversions],
  ./test_helpers

procSuite "accounts":
  asyncTest "accounts":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let db = initializeDB(path, password)

    var account:Account = Account(
      name: "Test",
      loginTimestamp: cast[int](cpuTime()),
      photoPath: "/path",
      keycardPairing: "",
      keyUid: "0x1234"
    )

    db.saveAccount(account)
    account.name = "Test_updated"
    db.updateAccount(account)
    db.updateAccountTimestamp(1, "0x1234")
    var accountList = db.getAccounts()

    check:
      accountList.len == 1

    let acc = accountList[0]

    check:
      acc.name == "Test_updated"
      acc.loginTimestamp == 1
      acc.photoPath == account.photoPath
      acc.keyUid == account.keyUid

    db.deleteAccount(account.keyUid)
    accountList = db.getAccounts()

    check:
      accountList.len == 0

    db.close()
    removeFile(path)
