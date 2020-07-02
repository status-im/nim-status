import status_go
import types

# All procs start with lowercase because the compiler will also need to import status-go,
# and it will complain of duplication of function names

proc hashMessage*(message: cstring): cstring {.exportc.} =
  result = status_go.HashMessage(message)

proc initKeystore*(keydir: cstring): cstring {.exportc.} =
  result = status_go.InitKeystore(keydir)

proc openAccounts*(datadir: cstring): cstring {.exportc.} =
  result = status_go.OpenAccounts(datadir)

proc multiAccountGenerateAndDeriveAddresses*(paramsJSON: cstring): cstring {.exportc.} =
  result = status_go.MultiAccountGenerateAndDeriveAddresses(paramsJSON)

proc multiAccountStoreDerivedAccounts*(paramsJSON: cstring): cstring {.exportc.} =
  result = status_go.MultiAccountStoreDerivedAccounts(paramsJSON)

proc multiAccountImportMnemonic*(paramsJSON: cstring): cstring {.exportc.} =
  result = status_go.MultiAccountImportMnemonic(paramsJSON)

proc multiAccountImportPrivateKey*(paramsJSON: cstring): cstring {.exportc.} =
  result = status_go.MultiAccountImportPrivateKey(paramsJSON)

proc multiAccountDeriveAddresses*(paramsJSON: cstring): cstring {.exportc.} =
  result = status_go.MultiAccountDeriveAddresses(paramsJSON)

proc saveAccountAndLogin*(accountData: cstring, password: cstring, settingsJSON: cstring, configJSON: cstring, subaccountData: cstring): cstring {.exportc.} =
  result = status_go.SaveAccountAndLogin(accountData, password, settingsJSON, configJSON, subaccountData)

proc callRPC*(inputJSON: cstring): cstring {.exportc.} =
  result = status_go.CallRPC(inputJSON)

proc callPrivateRPC*(inputJSON: cstring): cstring {.exportc.} =
  result = status_go.CallPrivateRPC(inputJSON)

proc addPeer*(peer: cstring): cstring {.exportc.} =
  result = status_go.AddPeer(peer)

proc setSignalEventCallback*(callback: SignalCallback) {.exportc.} =
  # TODO: test callbacks
  status_go.SetSignalEventCallback(callback)

proc sendTransaction*(jsonArgs: cstring, password: cstring): cstring {.exportc.} =
  result = status_go.SendTransaction(jsonArgs, password)

proc generateAlias*(pk: GoString): cstring {.exportc.} =
  result = status_go.GenerateAlias(pk)

proc identicon*(pk: GoString): cstring {.exportc.} =
  result = status_go.Identicon(pk)

proc login*(accountData: cstring, password: cstring): cstring {.exportc.} =
  result = status_go.Login(accountData, password)

proc logout*(): cstring {.exportc.} =
  result = status_go.Logout()

proc verifyAccountPassword*(keyStoreDir: cstring, address: cstring, password: cstring): cstring {.exportc.} =
  result = status_go.VerifyAccountPassword(keyStoreDir, address, password)

proc validateMnemonic*(mnemonic: cstring): cstring {.exportc.} =
  result = status_go.ValidateMnemonic(mnemonic)

proc recoverAccount(password: cstring, mnemonic: cstring): cstring {.exportc.} =
  result = status_go.RecoverAccount(password, mnemonic)

proc startOnboarding(n: cint, mnemonicPhraseLength: cint): cstring {.exportc.} =
  result = status_go.StartOnboarding(n, mnemonicPhraseLength)

proc saveAccountAndLoginWithKeycard(accountData: cstring, password: cstring, settingsJSON: cstring, configJSON: cstring, subaccountData: cstring, keyHex: cstring): cstring {.exportc.} =
  result = status_go.SaveAccountAndLoginWithKeycard(accountData, password, settingsJSON, configJSON, subaccountData, keyHex)

proc hashTransaction(txArgsJSON: cstring): cstring {.exportc.} =
  result = status_go.HashTransaction(txArgsJSON)

proc extractGroupMembershipSignatures(signaturePairsStr: cstring): cstring {.exportc.} =
  result = status_go.ExtractGroupMembershipSignatures(signaturePairsStr)

proc connectionChange(typ: cstring, expensive: cstring) {.exportc.} =
  status_go.ConnectionChange(typ, expensive)

proc multiformatSerializePublicKey(key: cstring, outBase: cstring): cstring {.exportc.} =
  result = status_go.MultiformatSerializePublicKey(key, outBase)


# TODO: Create a nim proc for each of these status_go functions
#[
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