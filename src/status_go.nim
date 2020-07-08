import types

proc HashMessage*(message: cstring): cstring {.importc: "HashMessage".}

proc InitKeystore*(keydir: cstring): cstring {.importc: "InitKeystore".}

proc OpenAccounts*(datadir: cstring): cstring {.importc: "OpenAccounts".}

proc MultiAccountGenerateAndDeriveAddresses*(paramsJSON: cstring): cstring {.importc: "MultiAccountGenerateAndDeriveAddresses".}

proc MultiAccountStoreDerivedAccounts*(paramsJSON: cstring): cstring {.importc: "MultiAccountStoreDerivedAccounts".}

proc MultiAccountImportMnemonic*(paramsJSON: cstring): cstring {.importc: "MultiAccountImportMnemonic".}

proc MultiAccountImportPrivateKey*(paramsJSON: cstring): cstring {.importc: "MultiAccountImportPrivateKey".}

proc MultiAccountDeriveAddresses*(paramsJSON: cstring): cstring {.importc: "MultiAccountDeriveAddresses".}

proc SaveAccountAndLogin*(accountData: cstring, password: cstring, settingsJSON: cstring, configJSON: cstring, subaccountData: cstring): cstring {.importc: "SaveAccountAndLogin".}

proc CallRPC*(inputJSON: cstring): cstring {.importc: "CallRPC".}

proc CallPrivateRPC*(inputJSON: cstring): cstring {.importc: "CallPrivateRPC".}

proc AddPeer*(peer: cstring): cstring {.importc: "AddPeer".}

proc SetSignalEventCallback*(callback: SignalCallback) {.importc: "SetSignalEventCallback".}

proc SendTransaction*(jsonArgs: cstring, password: cstring): cstring {.importc: "SendTransaction".}

proc GenerateAlias*(pk: GoString): cstring {.importc: "GenerateAlias".}

proc Identicon*(pk: GoString): cstring {.importc: "Identicon".}

proc Login*(accountData: cstring, password: cstring): cstring {.importc: "Login".}

proc Logout*(): cstring {.importc: "Logout".}

proc VerifyAccountPassword*(keyStoreDir: cstring, address: cstring, password: cstring): cstring {.importc: "VerifyAccountPassword".}

proc ValidateMnemonic*(mnemonic: cstring): cstring {.importc: "ValidateMnemonic".}

proc RecoverAccount*(password: cstring, mnemonic: cstring): cstring {.importc: "RecoverAccount".}

proc StartOnboarding*(n: cint, mnemonicPhraseLength: cint): cstring {.importc: "StartOnboarding".}

proc SaveAccountAndLoginWithKeycard*(accountData: cstring, password: cstring, settingsJSON: cstring, configJSON: cstring, subaccountData: cstring, keyHex: cstring): cstring {.importc: "SaveAccountAndLoginWithKeycard".}

proc HashTransaction*(txArgsJSON: cstring): cstring {.importc: "HashTransaction".}

proc ExtractGroupMembershipSignatures*(signaturePairsStr: cstring): cstring {.importc: "ExtractGroupMembershipSignatures".}

proc ConnectionChange*(typ: cstring, expensive: cstring) {.importc: "ConnectionChange".}

proc MultiformatSerializePublicKey*(key: cstring, outBase: cstring): cstring {.importc: "MultiformatSerializePublicKey".}

proc MultiformatDeserializePublicKey*(key: cstring, outBase: cstring): cstring {.importc: "MultiformatDeserializePublicKey".}

proc ValidateNodeConfig*(configJSON: cstring): cstring {.importc: "ValidateNodeConfig".}

proc LoginWithKeycard*(accountData: cstring, password: cstring, keyHex: cstring): cstring {.importc: "LoginWithKeycard".}

proc Recover*(rpcParams: cstring): cstring {.importc: "Recover".}

proc WriteHeapProfile*(dataDir: cstring): cstring {.importc: "WriteHeapProfile".}

proc ImportOnboardingAccount*(id: cstring, password: cstring): cstring {.importc: "ImportOnboardingAccount".}

proc RemoveOnboarding*() {.importc: "RemoveOnboarding".}

proc HashTypedData*(data: cstring): cstring {.importc: "HashTypedData".}

proc ResetChainData*(): cstring {.importc: "ResetChainData".}

proc SignMessage*(rpcParams: cstring): cstring {.importc: "SignMessage".}

proc SignTypedData*(data: cstring, address: cstring, password: cstring): cstring {.importc: "SignTypedData".}

proc StopCPUProfiling*(): cstring {.importc: "StopCPUProfiling".}

proc GetNodesFromContract*(rpcEndpoint: cstring, contractAddress: cstring): cstring {.importc: "GetNodesFromContract".}

proc ExportNodeLogs*(): cstring {.importc: "ExportNodeLogs".}

proc ChaosModeUpdate*(on: cint): cstring {.importc: "ChaosModeUpdate".}

proc SignHash*(hexEncodedHash: cstring): cstring {.importc: "SignHash".}

proc CreateAccount*(password: cstring): cstring {.importc: "CreateAccount".}

proc SendTransactionWithSignature*(txtArgsJSON: cstring, sigString: cstring): cstring {.importc: "SendTransactionWithSignature".}

proc StartCPUProfile*(dataDir: cstring): cstring {.importc: "StartCPUProfile".}

proc AppStateChange*(state: cstring) {.importc: "AppStateChange".}

proc SignGroupMembership*(content: cstring): cstring {.importc: "SignGroupMembership".}

proc MultiAccountStoreAccount*(paramsJSON: cstring): cstring {.importc: "MultiAccountStoreAccount".}

proc MultiAccountLoadAccount*(paramsJSON: cstring): cstring {.importc: "MultiAccountLoadAccount".}

proc MultiAccountGenerate*(paramsJSON: cstring): cstring {.importc: "MultiAccountGenerate".}

proc MultiAccountReset*(): cstring {.importc: "MultiAccountReset".}
