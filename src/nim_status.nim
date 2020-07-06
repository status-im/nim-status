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

proc multiformatDeserializePublicKey(key: cstring, outBase: cstring): cstring {.exportc.} =
  result = status_go.MultiformatDeserializePublicKey(key, outBase)

proc validateNodeConfig(configJSON: cstring): cstring {.exportc.} =
  result = status_go.ValidateNodeConfig(configJSON)

proc loginWithKeycard(accountData: cstring, password: cstring, keyHex: cstring): cstring {.exportc.} =
  result = status_go.LoginWithKeycard(accountData, password, keyHex)

proc recover(rpcParams: cstring): cstring {.exportc.} =
  result = status_go.Recover(rpcParams)

proc writeHeapProfile(dataDir: cstring): cstring {.exportc.} =
  result = status_go.WriteHeapProfile(dataDir)

proc importOnboardingAccount(id: cstring, password: cstring): cstring {.exportc.} =
  result = status_go.ImportOnboardingAccount(id, password)

proc removeOnboarding() {.exportc.} =
  status_go.RemoveOnboarding()

proc hashTypedData(data: cstring): cstring {.exportc.} =
  result = status_go.HashTypedData(data)

proc resetChainData(): cstring {.exportc.} =
  result = status_go.ResetChainData()

proc signMessage(rpcParams: cstring): cstring {.exportc.} =
  result = status_go.SignMessage(rpcParams)

proc signTypedData(data: cstring, address: cstring, password: cstring): cstring {.exportc.} =
  result = status_go.SignTypedData(data, address, password)

proc stopCPUProfiling(): cstring {.exportc.} =
  result = status_go.StopCPUProfiling()

proc getNodesFromContract(rpcEndpoint: cstring, contractAddress: cstring): cstring {.exportc.} =
  result = status_go.GetNodesFromContract(rpcEndpoint, contractAddress)

proc exportNodeLogs(): cstring {.exportc.} =
  result = status_go.ExportNodeLogs()

proc chaosModeUpdate(on: cint): cstring {.exportc.} =
  result = status_go.ChaosModeUpdate(on)

proc signHash(hexEncodedHash: cstring): cstring {.exportc.} =
  result = status_go.SignHash(hexEncodedHash)

proc createAccount(password: cstring): cstring {.exportc.} =
  result = status_go.CreateAccount(password)

proc sendTransactionWithSignature(txtArgsJSON: cstring, sigString: cstring): cstring {.exportc.} =
  result = status_go.SendTransactionWithSignature(txtArgsJSON, sigString)

proc startCPUProfile(dataDir: cstring): cstring {.exportc.} =
  result = status_go.StartCPUProfile(dataDir)

proc appStateChange(state: cstring) {.exportc.} =
  status_go.AppStateChange(state)

proc signGroupMembership(content: cstring): cstring {.exportc.} =
  result = status_go.SignGroupMembership(content)

proc multiAccountStoreAccount(paramsJSON: cstring): cstring {.exportc.} =
  result = status_go.MultiAccountStoreAccount(paramsJSON)

proc multiAccountLoadAccount(paramsJSON: cstring): cstring {.exportc.} =
  result = status_go.MultiAccountLoadAccount(paramsJSON)

proc multiAccountGenerate(paramsJSON: cstring): cstring {.exportc.} =
  result = status_go.MultiAccountGenerate(paramsJSON)

proc multiAccountReset(): cstring {.exportc.} =
  result = status_go.MultiAccountReset()
