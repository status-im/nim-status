import sqlcipher
import os, json
import ../../nim_status/lib/settings
import ../../nim_status/lib/database

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd)

let settingsObj = """{
    "address": "0x1122334455667788990011223344556677889900",
    "networks/current-network": "mainnet",
    "dapps-address": "0x1122334455667788990011223344556677889900",
    "eip1581-address": "0x1122334455667788990011223344556677889900",
    "installation-id": "ABC-DEF-GHI",
    "key-uid": "ABC",
    "latest-derived-path": 0,
    "networks/networks": [{"someNetwork": "1"}],
    "photo-path": "ABC",
    "preview-privacy?": true,
    "public-key": "0x123",
    "appearance": 1,
    "use-mailservers?": true,
    "signing-phrase": "ABC DEF GHI",
    "chaos-mode?": null
  }""".toSettings

createSettings(db, settingsObj, %* {})

let s = getSettings(db)

saveSetting(db, SettingsEnum.ChaosMode, "A")

let s2 = getSettings(db)
echo $s2

db.close()
removeFile(path)
