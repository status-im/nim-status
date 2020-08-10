import lib/shim as nim_shim

let hashMessage {.exportc.} = nim_shim.hashMessage
let generateAlias {.exportc.} = nim_shim.generateAlias

import go/shim as go_shim

let initKeystore {.exportc.} = go_shim.initKeystore
let openAccounts {.exportc.} = go_shim.openAccounts
let multiAccountGenerateAndDeriveAddresses {.exportc.} = go_shim.multiAccountGenerateAndDeriveAddresses
let multiAccountStoreDerivedAccounts {.exportc.} = go_shim.multiAccountStoreDerivedAccounts
let multiAccountImportMnemonic {.exportc.} = go_shim.multiAccountImportMnemonic
let multiAccountImportPrivateKey {.exportc.} = go_shim.multiAccountImportPrivateKey
let multiAccountDeriveAddresses {.exportc.} = go_shim.multiAccountDeriveAddresses
let saveAccountAndLogin {.exportc.} = go_shim.saveAccountAndLogin
let callRPC {.exportc.} = go_shim.callRPC
let callPrivateRPC {.exportc.} = go_shim.callPrivateRPC
let addPeer {.exportc.} = go_shim.addPeer
let sendTransaction {.exportc.} = go_shim.sendTransaction
let identicon {.exportc.} = go_shim.identicon
let login {.exportc.} = go_shim.login
let logout {.exportc.} = go_shim.logout
let verifyAccountPassword {.exportc.} = go_shim.verifyAccountPassword
let validateMnemonic {.exportc.} = go_shim.validateMnemonic
let recoverAccount {.exportc.} = go_shim.recoverAccount
let startOnboarding {.exportc.} = go_shim.startOnboarding
let saveAccountAndLoginWithKeycard {.exportc.} = go_shim.saveAccountAndLoginWithKeycard
let hashTransaction {.exportc.} = go_shim.hashTransaction
let extractGroupMembershipSignatures {.exportc.} = go_shim.extractGroupMembershipSignatures
let connectionChange {.exportc.} = go_shim.connectionChange
let multiformatSerializePublicKey {.exportc.} = go_shim.multiformatSerializePublicKey
let multiformatDeserializePublicKey {.exportc.} = go_shim.multiformatDeserializePublicKey
let validateNodeConfig {.exportc.} = go_shim.validateNodeConfig
let loginWithKeycard {.exportc.} = go_shim.loginWithKeycard
let recover {.exportc.} = go_shim.recover
let writeHeapProfile {.exportc.} = go_shim.writeHeapProfile
let importOnboardingAccount {.exportc.} = go_shim.importOnboardingAccount
let removeOnboarding {.exportc.} = go_shim.removeOnboarding
let hashTypedData {.exportc.} = go_shim.hashTypedData
let resetChainData {.exportc.} = go_shim.resetChainData
let signMessage {.exportc.} = go_shim.signMessage
let signTypedData {.exportc.} = go_shim.signTypedData
let stopCPUProfiling {.exportc.} = go_shim.stopCPUProfiling
let getNodesFromContract {.exportc.} = go_shim.getNodesFromContract
let exportNodeLogs {.exportc.} = go_shim.exportNodeLogs
let chaosModeUpdate {.exportc.} = go_shim.chaosModeUpdate
let signHash {.exportc.} = go_shim.signHash
let createAccount {.exportc.} = go_shim.createAccount
let sendTransactionWithSignature {.exportc.} = go_shim.sendTransactionWithSignature
let startCPUProfile {.exportc.} = go_shim.startCPUProfile
let appStateChange {.exportc.} = go_shim.appStateChange
let signGroupMembership {.exportc.} = go_shim.signGroupMembership
let multiAccountStoreAccount {.exportc.} = go_shim.multiAccountStoreAccount
let multiAccountLoadAccount {.exportc.} = go_shim.multiAccountLoadAccount
let multiAccountGenerate {.exportc.} = go_shim.multiAccountGenerate
let multiAccountReset {.exportc.} = go_shim.multiAccountReset

type SignalCallback {.exportc: "SignalCallback".} = proc(eventMessage: cstring): void {.cdecl.}

proc setSignalEventCallback(callback: SignalCallback) {.exportc.} =
  go_shim.setSignalEventCallback(callback)
