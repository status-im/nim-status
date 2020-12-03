import # nim libs
  os, json, options

import # vendor libs
  sqlcipher, json_serialization, web3/conversions as web3_conversions,
  web3/ethtypes

import # nim-status libs
  ../../nim_status/lib/[settings, database, conversions]

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd)

let settingsStr = """{
    "address": "0x1122334455667788990011223344556677889900",
    "chaos-mode": true,
    "networks/current-network": "mainnet",
    "dapps-address": "0x1122334455667788990011223344556677889900",
    "eip1581-address": "0x1122334455667788990011223344556677889900",
    "installation-id": "ABC-DEF-GHI",
    "key-uid": "XYZ",
    "latest-derived-path": 0,
    "networks/networks": [{"someNetwork": "1"}],
    "name": "test",
    "photo-path": "ABXYZC",
    "preview-privacy?": false,
    "public-key": "0x123",
    "signing-phrase": "ABC DEF GHI",
    "wallet-root-address": "0x1122334455667788990011223344556677889900"
  }"""
let settingsObj = Json.decode(settingsStr, Settings, allowUnknownFields = true)

let nodeConfig = %* {"config": 1}

createSettings(db, settingsObj, nodeConfig)

let dbSettings1 = getSettings(db)

assert settingsObj.userAddress == dbSettings1.userAddress
assert settingsObj.chaosMode.isNone
assert dbSettings1.chaosMode.get == false
assert settingsObj.currentNetwork == dbSettings1.currentNetwork
assert settingsObj.dappsAddress == dbSettings1.dappsAddress
assert settingsObj.eip1581Address == dbSettings1.eip1581Address
assert settingsObj.installationId == dbSettings1.installationId
assert settingsObj.keyUID == dbSettings1.keyUID
assert settingsObj.latestDerivedPath == dbSettings1.latestDerivedPath
assert settingsObj.photoPath == dbSettings1.photoPath
assert settingsObj.previewPrivacy == dbSettings1.previewPrivacy
assert settingsObj.publicKey == dbSettings1.publicKey
assert settingsObj.signingPhrase == dbSettings1.signingPhrase

assert $getNodeConfig(db) == $nodeConfig

let testBool = true
let testString = "ABCDE"
let testJSON = %* { "abc": 123 }
let testInt:int = 1
let testInt64:int64 = 1
let testUint:uint = 1
var testAddress = "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef".parseAddress
var setting: Settings

saveSetting(db, setting.chaosMode.columnName, testBool)
saveSetting(db, setting.currency.columnName, testString)
saveSetting(db, setting.customBootNodes.columnName, testJSON)
saveSetting(db, setting.customBootNodesEnabled.columnName, testJSON)
saveSetting(db, setting.dappsAddress.columnName, testAddress)
saveSetting(db, setting.eip1581Address.columnName, testAddress)
saveSetting(db, setting.fleet.columnName, testString)
saveSetting(db, setting.hideHomeTooltip.columnName, testBool)
saveSetting(db, setting.keycardInstanceUID.columnName, testString)
saveSetting(db, setting.keycardPairedOn.columnName, testInt64)
saveSetting(db, setting.keycardPairing.columnName, testString)
saveSetting(db, setting.lastUpdated.columnName, testInt64)
saveSetting(db, setting.latestDerivedPath.columnName, testInt)
saveSetting(db, setting.logLevel.columnName, testString)
saveSetting(db, setting.mnemonic.columnName, testString)
saveSetting(db, setting.name.columnName, testString)
saveSetting(db, setting.currentNetwork.columnName, testString)
saveSetting(db, setting.networks.columnName, testJSON)
saveSetting(db, setting.nodeConfig.columnName, testJSON)
saveSetting(db, setting.notificationsEnabled.columnName, testBool)
saveSetting(db, setting.photoPath.columnName, testString)
saveSetting(db, setting.pinnedMailservers.columnName, testJSON)
saveSetting(db, setting.preferredName.columnName, testString)
saveSetting(db, setting.previewPrivacy.columnName, testBool)
saveSetting(db, setting.publicKey.columnName, testString)
saveSetting(db, setting.rememberSyncingChoice.columnName, testBool)
saveSetting(db, setting.remotePushNotificationsEnabled.columnName, testBool)
saveSetting(db, setting.pushNotificationsServerEnabled.columnName, testBool)
saveSetting(db, setting.pushNotificationsFromContactsOnly.columnName, testBool)
saveSetting(db, setting.sendPushNotifications.columnName, testBool)
saveSetting(db, setting.stickerPacksInstalled.columnName, testJSON)
saveSetting(db, setting.stickersPacksPending.columnName, testJSON)
saveSetting(db, setting.stickersRecentStickers.columnName, testJSON)
saveSetting(db, setting.syncingOnMobileNetwork.columnName, testBool)
saveSetting(db, setting.usernames.columnName, testJSON)
saveSetting(db, setting.walletSetupPassed.columnName, testBool)
saveSetting(db, setting.walletVisibleTokens.columnName, testJSON)
saveSetting(db, setting.appearance.columnName, testInt)
saveSetting(db, setting.wakuEnabled.columnName, testBool)
saveSetting(db, setting.wakuBloomFilterMode.columnName, testBool)

let dbSettings2 = getSettings(db)

assert dbSettings2.chaosMode.get() == testBool
assert dbSettings2.currency.get() == testString
assert dbSettings2.customBootNodes.get() == testJson
assert dbSettings2.customBootNodesEnabled.get() == testJson
assert dbSettings2.dappsAddress == testAddress
assert dbSettings2.eip1581Address == testAddress
assert dbSettings2.fleet.get() == testString
assert dbSettings2.hideHomeTooltip.get() == testBool
assert dbSettings2.keycardInstanceUID.get() == testString
assert dbSettings2.keycardPairedOn.get() == testInt64
assert dbSettings2.keycardPairing.get() == testString
assert dbSettings2.lastUpdated.get() == testInt64
assert dbSettings2.latestDerivedPath == testUint
assert dbSettings2.logLevel.get() == testString
assert dbSettings2.mnemonic.get() == testString
assert dbSettings2.name.get() == testString
assert dbSettings2.currentNetwork == testString
assert dbSettings2.networks == testJSON
assert dbSettings2.notificationsEnabled.get() == testBool
assert dbSettings2.photoPath == testString
assert dbSettings2.pinnedMailservers.get() == testJSON
assert dbSettings2.preferredName.get() == testString
assert dbSettings2.previewPrivacy == testBool
assert dbSettings2.publicKey == testString
assert dbSettings2.rememberSyncingChoice.get() == testBool
assert dbSettings2.remotePushNotificationsEnabled.get() == testBool
assert dbSettings2.pushNotificationsServerEnabled.get() == testBool
assert dbSettings2.pushNotificationsFromContactsOnly.get() == testBool
assert dbSettings2.sendPushNotifications.get() == testBool
assert dbSettings2.stickerPacksInstalled.get() == testJSON
assert dbSettings2.stickersPacksPending.get() == testJSON
assert dbSettings2.stickersRecentStickers.get() == testJSON
assert dbSettings2.syncingOnMobileNetwork.get() == testBool
assert dbSettings2.userNames.get() == testJSON
assert dbSettings2.walletSetupPassed.get() == testBool
assert dbSettings2.walletVisibleTokens.get() == testJSON
assert dbSettings2.appearance == testUint
assert dbSettings2.wakuEnabled.get() == testBool
assert dbSettings2.wakuBloomFilterMode.get() == testBool

assert getNodeConfig(db) == testJSON

db.close()
removeFile(path)
