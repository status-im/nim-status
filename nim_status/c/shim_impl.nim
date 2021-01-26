import strformat

import ../../nim_status as nim_status
import ./go/signals
import ./sys

export SignalCallback

proc notImplemented() =
  writeStackTrace()
  raise newException(Defect, "NOT IMPLEMENTED")

proc hashMessage*(message: cstring): cstring =
  var hash = nim_status.hashMessage($message)
  # status-go compatible formatting
  hash = fmt("{{\"result\":\"{hash}\"}}")
  result = cast[cstring](c_malloc(csize_t hash.len + 1))
  copyMem(result, hash.cstring, hash.len)
  result[hash.len] = '\0'

proc initKeystore*(keydir: cstring): cstring =
  notImplemented()

proc openAccounts*(datadir: cstring): cstring =
  notImplemented()

proc multiAccountGenerateAndDeriveAddresses*(paramsJSON: cstring): cstring =
  notImplemented()

proc multiAccountStoreDerivedAccounts*(paramsJSON: cstring): cstring =
  notImplemented()

proc multiAccountImportMnemonic*(paramsJSON: cstring): cstring =
  notImplemented()

proc multiAccountImportPrivateKey*(paramsJSON: cstring): cstring =
  notImplemented()

proc multiAccountDeriveAddresses*(paramsJSON: cstring): cstring =
  notImplemented()

proc saveAccountAndLogin*(accountData: cstring, password: cstring, settingsJSON: cstring, configJSON: cstring, subaccountData: cstring): cstring =
  notImplemented()

proc deleteMultiAccount*(keyUID: cstring, keyStoreDir: cstring): cstring =
  notImplemented()

proc callRPC*(inputJSON: cstring): cstring =
  notImplemented()

proc callPrivateRPC*(inputJSON: cstring): cstring =
  notImplemented()

proc addPeer*(peer: cstring): cstring =
  notImplemented()

proc setSignalEventCallback*(callback: SignalCallback) =
  notImplemented()

proc sendTransaction*(jsonArgs: cstring, password: cstring): cstring =
  notImplemented()

proc generateAlias*(pubKey: cstring): cstring =
  let alias = nim_status.generateAlias($pubKey)
  result = cast[cstring](c_malloc(csize_t alias.len + 1))
  copyMem(result, alias.cstring, alias.len)
  result[alias.len] = '\0'

proc identicon*(pubKey: cstring): cstring =
  let icon = nim_status.identicon($pubKey)
  result = cast[cstring](c_malloc(csize_t icon.len + 1))
  copyMem(result, icon.cstring, icon.len)
  result[icon.len] = '\0'

proc login*(accountData: cstring, password: cstring): cstring =
  notImplemented()

proc logout*(): cstring =
  notImplemented()

proc verifyAccountPassword*(keyStoreDir: cstring, address: cstring, password: cstring): cstring =
  notImplemented()

proc validateMnemonic*(mnemonic: cstring): cstring =
  notImplemented()

proc saveAccountAndLoginWithKeycard*(accountData: cstring, password: cstring, settingsJSON: cstring, configJSON: cstring, subaccountData: cstring, keyHex: cstring): cstring =
  notImplemented()

proc hashTransaction*(txArgsJSON: cstring): cstring =
  notImplemented()

proc extractGroupMembershipSignatures*(signaturePairsStr: cstring): cstring =
  notImplemented()

proc connectionChange*(typ: cstring, expensive: cstring) =
  notImplemented()

proc multiformatSerializePublicKey*(key: cstring, outBase: cstring): cstring =
  notImplemented()

proc multiformatDeserializePublicKey*(key: cstring, outBase: cstring): cstring =
  notImplemented()

proc validateNodeConfig*(configJSON: cstring): cstring =
  notImplemented()

proc loginWithKeycard*(accountData: cstring, password: cstring, keyHex: cstring): cstring =
  notImplemented()

proc recover*(rpcParams: cstring): cstring =
  notImplemented()

proc writeHeapProfile*(dataDir: cstring): cstring =
  notImplemented()

proc hashTypedData*(data: cstring): cstring =
  notImplemented()

proc resetChainData*(): cstring =
  notImplemented()

proc signMessage*(rpcParams: cstring): cstring =
  notImplemented()

proc signTypedData*(data: cstring, address: cstring, password: cstring): cstring =
  notImplemented()

proc stopCPUProfiling*(): cstring =
  notImplemented()

proc getNodesFromContract*(rpcEndpoint: cstring, contractAddress: cstring): cstring =
  notImplemented()

proc exportNodeLogs*(): cstring =
  notImplemented()

proc chaosModeUpdate*(on: cint): cstring =
  notImplemented()

proc signHash*(hexEncodedHash: cstring): cstring =
  notImplemented()

proc sendTransactionWithSignature*(txtArgsJSON: cstring, sigString: cstring): cstring =
  notImplemented()

proc startCPUProfile*(dataDir: cstring): cstring =
  notImplemented()

proc appStateChange*(state: cstring) =
  notImplemented()

proc signGroupMembership*(content: cstring): cstring =
  notImplemented()

proc multiAccountStoreAccount*(paramsJSON: cstring): cstring =
  notImplemented()

proc multiAccountLoadAccount*(paramsJSON: cstring): cstring =
  notImplemented()

proc multiAccountGenerate*(paramsJSON: cstring): cstring =
  notImplemented()

proc multiAccountReset*(): cstring =
  notImplemented()

proc migrateKeyStoreDir*(accountData: cstring, password: cstring, oldKeystoreDir: cstring, multiaccountKeystoreDir: cstring): cstring =
  notImplemented()

proc startWallet*(watchNewBlocks: bool): cstring =
  notImplemented()

proc stopWallet*(): cstring =
  notImplemented()

proc startLocalNotifications*(): cstring =
  notImplemented()

proc stopLocalNotifications*(): cstring =
  notImplemented()
