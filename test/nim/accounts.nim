import # nim libs
   os, json, options

import # vendor libs
 sqlcipher, json_serialization, web3/conversions as web3_conversions

import # nim-status libs
 ../../nim_status/lib/[accounts, database, conversions]

import times

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd)

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
assert accountList.len == 1
let acc = accountList[0]

assert acc.name == "Test_updated"
assert acc.loginTimestamp == 1
assert acc.photoPath == account.photoPath
assert acc.keyUid == account.keyUid

db.deleteAccount(account.keyUid)

accountList = db.getAccounts()

assert accountList.len == 0

db.close()
removeFile(path)
