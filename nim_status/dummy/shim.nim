import ../c/go/shim as go_shim
import ../types

export SignalCallback

# All procs start with lowercase because the compiler will also need to import
# status-go, and it will complain of duplication of function names

proc throwEx() =
  writeStackTrace()
  raise newException(Defect, "DISABLED")

proc hashMessage*(message: string): string =
  throwEx()
 
proc initKeystore*(keydir: string): string =
  throwEx()

proc openAccounts*(datadir: string): string =
  throwEx()

proc multiAccountGenerateAndDeriveAddresses*(paramsJSON: string): string =
  throwEx()

proc multiAccountStoreDerivedAccounts*(paramsJSON: string): string =
  throwEx()

proc multiAccountImportMnemonic*(paramsJSON: string): string =
  throwEx()

proc multiAccountImportPrivateKey*(paramsJSON: string): string =
  throwEx()

proc multiAccountDeriveAddresses*(paramsJSON: string): string =
  throwEx()

proc saveAccountAndLogin*(accountData: string, password: string, settingsJSON: string, configJSON: string, subaccountData: string): string =
  throwEx()

proc deleteMultiAccount*(keyUID: string, keyStoreDir: string): string =
  throwEx()

proc callRPC*(inputJSON: string): string =
  throwEx()

proc callPrivateRPC*(inputJSON: string): string =
  throwEx()

proc addPeer*(peer: string): string =
  throwEx()

proc setSignalEventCallback*(callback: SignalCallback) =
  throwEx()

proc sendTransaction*(jsonArgs: string, password: string): string =
  throwEx()

proc generateAlias*(pk: string): string =
  throwEx()

proc identicon*(pk: string): string =
  throwEx()

proc login*(accountData: string, password: string): string =
  throwEx()

proc logout*(): string =
  throwEx()

proc verifyAccountPassword*(keyStoreDir: string, address: string, password: string): string =
  throwEx()

proc validateMnemonic*(mnemonic: string): string =
  throwEx()

proc saveAccountAndLoginWithKeycard*(accountData: string, password: string, settingsJSON: string, configJSON: string, subaccountData: string, keyHex: string): string =
  throwEx()

proc hashTransaction*(txArgsJSON: string): string =
  throwEx()

proc extractGroupMembershipSignatures*(signaturePairsStr: string): string =
  throwEx()

proc connectionChange*(typ: string, expensive: string) =
  throwEx()

proc multiformatSerializePublicKey*(key: string, outBase: string): string =
  throwEx()

proc multiformatDeserializePublicKey*(key: string, outBase: string): string =
  throwEx()

proc validateNodeConfig*(configJSON: string): string =
  throwEx()

proc loginWithKeycard*(accountData: string, password: string, keyHex: string): string =
  throwEx()

proc recover*(rpcParams: string): string =
  throwEx()

proc writeHeapProfile*(dataDir: string): string =
  throwEx()

proc hashTypedData*(data: string): string =
  throwEx()

proc resetChainData*(): string =
  throwEx()

proc signMessage*(rpcParams: string): string =
  throwEx()

proc signTypedData*(data: string, address: string, password: string): string =
  throwEx()

proc stopCPUProfiling*(): string =
  throwEx()

proc getNodesFromContract*(rpcEndpoint: string, contractAddress: string): string =
  throwEx()

proc exportNodeLogs*(): string =
  throwEx()

proc chaosModeUpdate*(on: int): string =
  throwEx()

proc signHash*(hexEncodedHash: string): string =
  throwEx()

proc sendTransactionWithSignature*(txtArgsJSON: string, sigString: string): string =
  throwEx()

proc startCPUProfile*(dataDir: string): string =
  throwEx()

proc appStateChange*(state: string) =
  throwEx()

proc signGroupMembership*(content: string): string =
  throwEx()

proc multiAccountStoreAccount*(paramsJSON: string): string =
  throwEx()

proc multiAccountLoadAccount*(paramsJSON: string): string =
  throwEx()

proc multiAccountGenerate*(paramsJSON: string): string =
  throwEx()

proc multiAccountReset*(): string =
  throwEx()

proc migrateKeyStoreDir*(accountData: string, password: string, oldKeystoreDir: string, multiaccountKeystoreDir: string): string =
  throwEx()

proc startWallet*(watchNewBlocks: bool): string =
  throwEx()

proc stopWallet*(): string =
  throwEx()

proc startLocalNotifications*(): string =
  throwEx()

proc stopLocalNotifications*(): string =
  throwEx()
 
