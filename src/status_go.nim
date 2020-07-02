import types

#[
  TODO: create procs for these:
extern char* MultiformatDeserializePublicKey(char* key, char* outBase);
extern char* ValidateNodeConfig(char* configJSON);
extern char* LoginWithKeycard(char* accountData, char* password, char* keyHex);
extern char* Recover(char* rpcParams);
extern char* WriteHeapProfile(char* dataDir);
extern char* ImportOnboardingAccount(char* id, char* password);
extern void RemoveOnboarding();
extern char* HashTypedData(char* data);
extern char* ResetChainData();
extern char* SignMessage(char* rpcParams);
extern char* SignTypedData(char* data, char* address, char* password);
extern char* StopCPUProfiling();
extern char* GetNodesFromContract(char* rpcEndpoint, char* contractAddress);
extern char* ExportNodeLogs();
extern char* ChaosModeUpdate(int on);
extern char* SignHash(char* hexEncodedHash);
extern char* CreateAccount(char* password);
extern char* SendTransactionWithSignature(char* txtArgsJSON, char* sigString);
extern char* StartCPUProfile(char* dataDir);
extern void AppStateChange(char* state);
extern char* SignGroupMembership(char* content);
extern char* MultiAccountStoreAccount(char* paramsJSON);
extern char* MultiAccountLoadAccount(char* paramsJSON);
extern char* MultiAccountGenerate(char* paramsJSON);
extern char* MultiAccountReset();
]#

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
