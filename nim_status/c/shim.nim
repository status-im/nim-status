# The goal of this module (see also `./shim_impl.nim`) is to wrap the APIs
# re-exported by this library's root `nim_status.nim` such that the function
# names, parameter types, return types, and overall behavior match the API of
# status-go when it is compiled into `libstatus.a`.

# NOTE: this module is completely independent of status-go and is intended
# primarily as a means for consumers of status-go (e.g. status-react) to
# transition from status-go's API to nim-status' own APIs.

# It is expected that this module will be compiled into an archive so that it
# can be consumed as a C library (see the `nim_status` target in this repo's
# Makefile, which compiles this module into `build/nim_status.a`). If this
# module is successfully implemented in full, `nim_status.a` will be able to
# serve as a drop-in replacement for `libstatus.a`.

# In the future there may be a module in `nim_status/c/` that is intended to be
# compiled into an archive (consumable as a C library) providing nim-status'
# own APIs *without* a status-go compatibility wrapper, but at present there is
# no such module since those APIs are still taking shape.

import ./shim_impl as nim_shim

let HashMessage {.exportc.} = nim_shim.hashMessage
let InitKeystore {.exportc.} = nim_shim.initKeystore
let OpenAccounts {.exportc.} = nim_shim.openAccounts
let MultiAccountGenerateAndDeriveAddresses {.exportc.} = nim_shim.multiAccountGenerateAndDeriveAddresses
let MultiAccountStoreDerivedAccounts {.exportc.} = nim_shim.multiAccountStoreDerivedAccounts
let MultiAccountImportMnemonic {.exportc.} = nim_shim.multiAccountImportMnemonic
let MultiAccountImportPrivateKey {.exportc.} = nim_shim.multiAccountImportPrivateKey
let MultiAccountDeriveAddresses {.exportc.} = nim_shim.multiAccountDeriveAddresses
let SaveAccountAndLogin {.exportc.} = nim_shim.saveAccountAndLogin
let DeleteMultiAccount {.exportc.} = nim_shim.deleteMultiAccount
let CallRPC {.exportc.} = nim_shim.callRPC
let CallPrivateRPC {.exportc.} = nim_shim.callPrivateRPC
let AddPeer {.exportc.} = nim_shim.addPeer
let SendTransaction {.exportc.} = nim_shim.sendTransaction
let GenerateAlias {.exportc.} = nim_shim.generateAlias
let Identicon {.exportc.} = nim_shim.identicon
let Login {.exportc.} = nim_shim.login
let Logout {.exportc.} = nim_shim.logout
let VerifyAccountPassword {.exportc.} = nim_shim.verifyAccountPassword
let ValidateMnemonic {.exportc.} = nim_shim.validateMnemonic
let SaveAccountAndLoginWithKeycard {.exportc.} = nim_shim.saveAccountAndLoginWithKeycard
let HashTransaction {.exportc.} = nim_shim.hashTransaction
let ExtractGroupMembershipSignatures {.exportc.} = nim_shim.extractGroupMembershipSignatures
let ConnectionChange {.exportc.} = nim_shim.connectionChange
let MultiformatSerializePublicKey {.exportc.} = nim_shim.multiformatSerializePublicKey
let MultiformatDeserializePublicKey {.exportc.} = nim_shim.multiformatDeserializePublicKey
let ValidateNodeConfig {.exportc.} = nim_shim.validateNodeConfig
let LoginWithKeycard {.exportc.} = nim_shim.loginWithKeycard
let Recover {.exportc.} = nim_shim.recover
let WriteHeapProfile {.exportc.} = nim_shim.writeHeapProfile
let HashTypedData {.exportc.} = nim_shim.hashTypedData
let ResetChainData {.exportc.} = nim_shim.resetChainData
let SignMessage {.exportc.} = nim_shim.signMessage
let SignTypedData {.exportc.} = nim_shim.signTypedData
let StopCPUProfiling {.exportc.} = nim_shim.stopCPUProfiling
let GetNodesFromContract {.exportc.} = nim_shim.getNodesFromContract
let ExportNodeLogs {.exportc.} = nim_shim.exportNodeLogs
let ChaosModeUpdate {.exportc.} = nim_shim.chaosModeUpdate
let SignHash {.exportc.} = nim_shim.signHash
let SendTransactionWithSignature {.exportc.} = nim_shim.sendTransactionWithSignature
let StartCPUProfile {.exportc.} = nim_shim.startCPUProfile
let AppStateChange {.exportc.} = nim_shim.appStateChange
let SignGroupMembership {.exportc.} = nim_shim.signGroupMembership
let MultiAccountStoreAccount {.exportc.} = nim_shim.multiAccountStoreAccount
let MultiAccountLoadAccount {.exportc.} = nim_shim.multiAccountLoadAccount
let MultiAccountGenerate {.exportc.} = nim_shim.multiAccountGenerate
let MultiAccountReset {.exportc.} = nim_shim.multiAccountReset
let MigrateKeyStoreDir {.exportc.} = nim_shim.migrateKeyStoreDir
let StartWallet {.exportc.} = nim_shim.startWallet
let StopWallet {.exportc.} = nim_shim.stopWallet
let StartLocalNotifications {.exportc.} = nim_shim.startLocalNotifications
let StopLocalNotifications {.exportc.} = nim_shim.stopLocalNotifications

type SignalCallback {.exportc: "SignalCallback".} = proc(eventMessage: cstring): void {.cdecl.}

proc SetSignalEventCallback(callback: SignalCallback) {.exportc.} =
  nim_shim.setSignalEventCallback(callback)

let setupForeignThreadGc {.exportc.} = setupForeignThreadGc
let tearDownForeignThreadGc {.exportc.} = tearDownForeignThreadGc
