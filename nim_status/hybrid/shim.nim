# This module (see also `./go/shim.nim` and `./c/go/shim_impl.nim`) wraps the
# API supplied by status-go when it is compiled into `libstatus.a` or
# `libstatus.dll|dylib|so`. Unlike `./go/shim.nim`, individual proc wrappers
# here are expected to be *hybrids* that combine existing status-go
# functionality with Nim code implemented elsewhere in this library. For
# example, the `callRPC` proc in this module could redirect some calls to procs
# in other modules in this library while passing other calls to
# status-go. Individual procs in this module may also be complete replacements
# for their status-go counterparts (e.g. `hashMessage` and `identicon`), in
# which case it is expected the replacements will behave identically with their
# counterparts. The hybrids may exhibit behavior incompatible with status-go
# while they are a work-in-progress.

# Hybrids implemented here may all eventually become complete replacements for
# their status-go counterparts, at which time this module would be renamed
# `shim.nim` and have close correspondence with the code in `./c/shim.nim` and
# `./c/shim_impl.nim`, i.e. the latter can make use of the replacement procs in
# this module as appropriate.

# It is expected that this module will be consumed as an import in another Nim
# module; when doing so, it is not necessary to separately compile
# `./c/go/shim.nim` but it is the responsibility of the user to link status-go
# compiled to `libstatus` into the final executable.

import strformat
import json
import json_serialization

from ../../nim_status as nim_status import nil
from ../go/shim as go_shim import nil
import ../c/go/signals

from ../settings as settings import nil
from ../settings/types as settings_types import nil
from ../accounts as accounts import nil

import sqlcipher

export SignalCallback

proc notImplemented() =
  writeStackTrace()
  raise newException(Defect, "NOT IMPLEMENTED")

# `hashMessage` is a complete replacement, not a hybrid
proc hashMessage*(message: string): string =
  let hash = nim_status.hashMessage(message)
  # status-go compatible formatting
  fmt("{{\"result\":\"{hash}\"}}")

proc initKeystore*(keydir: string): string =
  notImplemented()

proc openAccounts*(datadir: string): string =
  notImplemented()

proc multiAccountGenerateAndDeriveAddresses*(paramsJSON: string): string =
  notImplemented()

proc multiAccountStoreDerivedAccounts*(paramsJSON: string): string =
  notImplemented()

proc multiAccountImportMnemonic*(paramsJSON: string): string =
  notImplemented()

proc multiAccountImportPrivateKey*(paramsJSON: string): string =
  notImplemented()

proc multiAccountDeriveAddresses*(paramsJSON: string): string =
  notImplemented()

proc saveAccountAndLogin*(accountData: string, password: string, settingsJSON: string, configJSON: string, subaccountData: string): string =
  notImplemented()

proc deleteMultiAccount*(keyUID: string, keyStoreDir: string): string =
  notImplemented()

proc callRPC*(inputJSON: string): string =
  notImplemented()

proc callPrivateRPC*(inputJSON: string): string =
  let parsedJson = parseJson(inputJSON)
  let rpcMethod = parsedJson["method"].getStr
  if rpcMethod == "settings_getSettings":
    let db = accounts.db_conn
    let settings = settings.getSettings(db)

    result = Json.encode(settings)
  elif rpcMethod == "settings_saveSetting":
    let params = parsedJson["params"].getElems()
    let db = accounts.db_conn
      
    settings.saveSetting(db, params[0], params[1])
    result = """{"error": false}"""
  else:
    result = go_shim.callPrivateRPC(inputJSON)

proc addPeer*(peer: string): string =
  notImplemented()

proc setSignalEventCallback*(callback: SignalCallback) =
  notImplemented()

proc sendTransaction*(jsonArgs: string, password: string): string =
  notImplemented()

# `generateAlias` is a complete replacement, not a hybrid
export nim_status.generateAlias

# `identicon` is a complete replacement, not a hybrid
export nim_status.identicon

proc login*(accountData: string, password: string): string =
  notImplemented()

proc logout*(): string =
  notImplemented()

proc verifyAccountPassword*(keyStoreDir: string, address: string, password: string): string =
  notImplemented()

proc validateMnemonic*(mnemonic: string): string =
  notImplemented()

proc saveAccountAndLoginWithKeycard*(accountData: string, password: string, settingsJSON: string, configJSON: string, subaccountData: string, keyHex: string): string =
  notImplemented()

proc hashTransaction*(txArgsJSON: string): string =
  notImplemented()

proc extractGroupMembershipSignatures*(signaturePairsStr: string): string =
  notImplemented()

proc connectionChange*(typ: string, expensive: string) =
  notImplemented()

proc multiformatSerializePublicKey*(key: string, outBase: string): string =
  notImplemented()

proc multiformatDeserializePublicKey*(key: string, outBase: string): string =
  notImplemented()

proc validateNodeConfig*(configJSON: string): string =
  notImplemented()

proc loginWithKeycard*(accountData: string, password: string, keyHex: string): string =
  notImplemented()

proc recover*(rpcParams: string): string =
  notImplemented()

proc writeHeapProfile*(dataDir: string): string =
  notImplemented()

proc hashTypedData*(data: string): string =
  notImplemented()

proc resetChainData*(): string =
  notImplemented()

proc signMessage*(rpcParams: string): string =
  notImplemented()

proc signTypedData*(data: string, address: string, password: string): string =
  notImplemented()

proc stopCPUProfiling*(): string =
  notImplemented()

proc getNodesFromContract*(rpcEndpoint: string, contractAddress: string): string =
  notImplemented()

proc exportNodeLogs*(): string =
  notImplemented()

proc chaosModeUpdate*(on: int): string =
  notImplemented()

proc signHash*(hexEncodedHash: string): string =
  notImplemented()

proc sendTransactionWithSignature*(txtArgsJSON: string, sigString: string): string =
  notImplemented()

proc startCPUProfile*(dataDir: string): string =
  notImplemented()

proc appStateChange*(state: string) =
  notImplemented()

proc signGroupMembership*(content: string): string =
  notImplemented()

proc multiAccountStoreAccount*(paramsJSON: string): string =
  notImplemented()

proc multiAccountLoadAccount*(paramsJSON: string): string =
  notImplemented()

proc multiAccountGenerate*(paramsJSON: string): string =
  notImplemented()

proc multiAccountReset*(): string =
  notImplemented()

proc migrateKeyStoreDir*(accountData: string, password: string, oldKeystoreDir: string, multiaccountKeystoreDir: string): string =
  notImplemented()

proc startWallet*(watchNewBlocks: bool): string =
  notImplemented()

proc stopWallet*(): string =
  notImplemented()

proc startLocalNotifications*(): string =
  notImplemented()

proc stopLocalNotifications*(): string =
  notImplemented()
