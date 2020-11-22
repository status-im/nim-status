import # nim libs
  os, json, options

import # vendor libs
  sqlcipher, json_serialization, web3/conversions as web3_conversions

import # nim-status libs
  ../../nim_status/lib/[settings, database, conversions]

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd)

let settingsStr = """{
    "address": "0x1122334455667788990011223344556677889900",
    "networks/current-network": "mainnet",
    "dapps-address": "0x1122334455667788990011223344556677889900",
    "eip1581-address": "0x1122334455667788990011223344556677889900",
    "installation-id": "ABC-DEF-GHI",
    "key-uid": "XYZ",
    "latest-derived-path": 0,
    "networks/networks": [{"someNetwork": "1"}],
    "photo-path": "ABXYZC",
    "preview-privacy?": false,
    "public-key": "0x123",
    "signing-phrase": "ABC DEF GHI"
  }"""

let settingsObj = JSON.decode(settingsStr, Settings, allowUnknownFields = true)

let nodeConfig = %* {"config": 1}

createSettings(db, settingsObj, nodeConfig)

let dbSettings1 = getSettings(db)

assert $settingsObj.userAddress == $dbSettings1.userAddress
assert settingsObj.currentNetwork == dbSettings1.currentNetwork
assert $settingsObj.dappsAddress == $dbSettings1.dappsAddress
assert $settingsObj.eip1581Address == $dbSettings1.eip1581Address
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

saveSetting(db, SettingsType.ChaosMode, testBool)
saveSetting(db, SettingsType.Currency, testString)
saveSetting(db, SettingsType.CustomBootNodes, testJSON)
saveSetting(db, SettingsType.CustomBootNodesEnabled, testJSON)
saveSetting(db, SettingsType.DappsAddress, testAddress)
saveSetting(db, SettingsType.EIP1581Address, testAddress)
saveSetting(db, SettingsType.Fleet, testString)
saveSetting(db, SettingsType.HideHomeTooltip, testBool)
saveSetting(db, SettingsType.KeycardInstanceUID, testString)
saveSetting(db, SettingsType.Keycard_PairedOn, testInt64)
saveSetting(db, SettingsType.Keycard_Pairing, testString)
saveSetting(db, SettingsType.LastUpdated, testInt64)
saveSetting(db, SettingsType.LatestDerivedPath, testInt)
saveSetting(db, SettingsType.LogLevel, testString)
saveSetting(db, SettingsType.Mnemonic, testString)
saveSetting(db, SettingsType.Name, testString)
saveSetting(db, SettingsType.CurrentNetwork, testString)
saveSetting(db, SettingsType.Networks, testJSON)
saveSetting(db, SettingsType.NodeConfig, testJSON)
saveSetting(db, SettingsType.NotificationsEnabled, testBool)
saveSetting(db, SettingsType.PhotoPath, testString)
saveSetting(db, SettingsType.PinnedMailservers, testJSON)
saveSetting(db, SettingsType.PreferredName, testString)
saveSetting(db, SettingsType.PreviewPrivacy, testBool)
saveSetting(db, SettingsType.PublicKey, testString)
saveSetting(db, SettingsType.RememberSyncingChoice, testBool)
saveSetting(db, SettingsType.RemotePushNotificationsEnabled, testBool)
saveSetting(db, SettingsType.PushNotificationsServerEnabled, testBool)
saveSetting(db, SettingsType.PushNotificationsFromContactsOnly, testBool)
saveSetting(db, SettingsType.SendPushNotifications, testBool)
saveSetting(db, SettingsType.StickersPacksInstalled, testJSON)
saveSetting(db, SettingsType.StickersPacksPending, testJSON)
saveSetting(db, SettingsType.StickersRecentStickers, testJSON)
saveSetting(db, SettingsType.SyncingOnMobileNetwork, testBool)
saveSetting(db, SettingsType.Usernames, testJSON)
saveSetting(db, SettingsType.WalletSetupPassed, testBool)
saveSetting(db, SettingsType.WalletVisibleTokens, testJSON)
saveSetting(db, SettingsType.Appearance, testInt)
saveSetting(db, SettingsType.WakuEnabled, testBool)
saveSetting(db, SettingsType.WakuBloomFilterMode, testBool)

let dbSettings2 = getSettings(db)

assert dbSettings2.chaosMode.get() == testBool
assert dbSettings2.currency.get() == testString
assert dbSettings2.customBootNodes.get() == testJson
assert dbSettings2.customBootNodesEnabled.get() == testJson
assert $dbSettings2.dappsAddress == $testAddress
assert $dbSettings2.eip1581Address == $testAddress
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
assert $dbSettings2.networks == $testJSON
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
assert $dbSettings2.stickerPacksInstalled.get() == $testJSON
assert dbSettings2.stickersPacksPending.get() == testJSON
assert dbSettings2.stickersRecentStickers.get() == testJSON
assert dbSettings2.syncingOnMobileNetwork.get() == testBool
assert dbSettings2.userNames.get() == testJSON
assert dbSettings2.walletSetupPassed.get() == testBool
assert dbSettings2.walletVisibleTokens.get() == testJSON
assert dbSettings2.appearance == testUint
assert dbSettings2.wakuEnabled.get() == testBool
assert dbSettings2.wakuBloomFilterMode.get() == testBool

assert $getNodeConfig(db) == $testJSON

db.close()
removeFile(path)
