import status_go
import types

# All procs start with lowercase because the compiler will also need to import status-go,
# and it will complain of duplication of function names

export SignalCallback

proc hashMessage*(message: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.HashMessage(message)
  tearDownForeignThreadGc()

proc initKeystore*(keydir: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.InitKeystore(keydir)
  tearDownForeignThreadGc()

proc openAccounts*(datadir: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.OpenAccounts(datadir)
  tearDownForeignThreadGc()

proc multiAccountGenerateAndDeriveAddresses*(paramsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountGenerateAndDeriveAddresses(paramsJSON)
  tearDownForeignThreadGc()

proc multiAccountStoreDerivedAccounts*(paramsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountStoreDerivedAccounts(paramsJSON)
  tearDownForeignThreadGc()

proc multiAccountImportMnemonic*(paramsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountImportMnemonic(paramsJSON)
  tearDownForeignThreadGc()

proc multiAccountImportPrivateKey*(paramsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountImportPrivateKey(paramsJSON)
  tearDownForeignThreadGc()

proc multiAccountDeriveAddresses*(paramsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountDeriveAddresses(paramsJSON)
  tearDownForeignThreadGc()

proc saveAccountAndLogin*(accountData: cstring, password: cstring, settingsJSON: cstring, configJSON: cstring, subaccountData: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.SaveAccountAndLogin(accountData, password, settingsJSON, configJSON, subaccountData)
  tearDownForeignThreadGc()

proc callRPC*(inputJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.CallRPC(inputJSON)
  tearDownForeignThreadGc()

proc callPrivateRPC*(inputJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.CallPrivateRPC(inputJSON)
  tearDownForeignThreadGc()

proc addPeer*(peer: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.AddPeer(peer)
  tearDownForeignThreadGc()

proc setSignalEventCallback*(callback: SignalCallback) {.exportc.} =
  setupForeignThreadGc()
  status_go.SetSignalEventCallback(callback)
  tearDownForeignThreadGc()

proc sendTransaction*(jsonArgs: cstring, password: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.SendTransaction(jsonArgs, password)
  tearDownForeignThreadGc()

proc generateAlias*(pk: GoString): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.GenerateAlias(pk)
  tearDownForeignThreadGc()

proc identicon*(pk: GoString): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.Identicon(pk)
  tearDownForeignThreadGc()

proc login*(accountData: cstring, password: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.Login(accountData, password)
  tearDownForeignThreadGc()

proc logout*(): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.Logout()
  tearDownForeignThreadGc()

proc verifyAccountPassword*(keyStoreDir: cstring, address: cstring, password: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.VerifyAccountPassword(keyStoreDir, address, password)
  tearDownForeignThreadGc()

proc validateMnemonic*(mnemonic: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.ValidateMnemonic(mnemonic)
  tearDownForeignThreadGc()

proc recoverAccount(password: cstring, mnemonic: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.RecoverAccount(password, mnemonic)
  tearDownForeignThreadGc()

proc startOnboarding(n: cint, mnemonicPhraseLength: cint): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.StartOnboarding(n, mnemonicPhraseLength)
  tearDownForeignThreadGc()

proc saveAccountAndLoginWithKeycard(accountData: cstring, password: cstring, settingsJSON: cstring, configJSON: cstring, subaccountData: cstring, keyHex: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.SaveAccountAndLoginWithKeycard(accountData, password, settingsJSON, configJSON, subaccountData, keyHex)
  tearDownForeignThreadGc()

proc hashTransaction(txArgsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.HashTransaction(txArgsJSON)
  tearDownForeignThreadGc()

proc extractGroupMembershipSignatures(signaturePairsStr: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.ExtractGroupMembershipSignatures(signaturePairsStr)
  tearDownForeignThreadGc()

proc connectionChange(typ: cstring, expensive: cstring) {.exportc.} =
  setupForeignThreadGc()
  status_go.ConnectionChange(typ, expensive)
  tearDownForeignThreadGc()

proc multiformatSerializePublicKey(key: cstring, outBase: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiformatSerializePublicKey(key, outBase)
  tearDownForeignThreadGc()

proc multiformatDeserializePublicKey(key: cstring, outBase: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiformatDeserializePublicKey(key, outBase)
  tearDownForeignThreadGc()

proc validateNodeConfig(configJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.ValidateNodeConfig(configJSON)
  tearDownForeignThreadGc()

proc loginWithKeycard(accountData: cstring, password: cstring, keyHex: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.LoginWithKeycard(accountData, password, keyHex)
  tearDownForeignThreadGc()

proc recover(rpcParams: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.Recover(rpcParams)
  tearDownForeignThreadGc()

proc writeHeapProfile(dataDir: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.WriteHeapProfile(dataDir)
  tearDownForeignThreadGc()

proc importOnboardingAccount(id: cstring, password: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.ImportOnboardingAccount(id, password)
  tearDownForeignThreadGc()

proc removeOnboarding() {.exportc.} =
  setupForeignThreadGc()
  status_go.RemoveOnboarding()
  tearDownForeignThreadGc()

proc hashTypedData(data: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.HashTypedData(data)
  tearDownForeignThreadGc()

proc resetChainData(): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.ResetChainData()
  tearDownForeignThreadGc()

proc signMessage(rpcParams: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.SignMessage(rpcParams)
  tearDownForeignThreadGc()

proc signTypedData(data: cstring, address: cstring, password: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.SignTypedData(data, address, password)
  tearDownForeignThreadGc()

proc stopCPUProfiling(): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.StopCPUProfiling()
  tearDownForeignThreadGc()

proc getNodesFromContract(rpcEndpoint: cstring, contractAddress: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.GetNodesFromContract(rpcEndpoint, contractAddress)
  tearDownForeignThreadGc()

proc exportNodeLogs(): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.ExportNodeLogs()
  tearDownForeignThreadGc()

proc chaosModeUpdate(on: cint): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.ChaosModeUpdate(on)
  tearDownForeignThreadGc()

proc signHash(hexEncodedHash: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.SignHash(hexEncodedHash)
  tearDownForeignThreadGc()

proc createAccount(password: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.CreateAccount(password)
  tearDownForeignThreadGc()

proc sendTransactionWithSignature(txtArgsJSON: cstring, sigString: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.SendTransactionWithSignature(txtArgsJSON, sigString)
  tearDownForeignThreadGc()

proc startCPUProfile(dataDir: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.StartCPUProfile(dataDir)
  tearDownForeignThreadGc()

proc appStateChange(state: cstring) {.exportc.} =
  setupForeignThreadGc()
  status_go.AppStateChange(state)
  tearDownForeignThreadGc()

proc signGroupMembership(content: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.SignGroupMembership(content)
  tearDownForeignThreadGc()

proc multiAccountStoreAccount(paramsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountStoreAccount(paramsJSON)
  tearDownForeignThreadGc()

proc multiAccountLoadAccount(paramsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountLoadAccount(paramsJSON)
  tearDownForeignThreadGc()

proc multiAccountGenerate(paramsJSON: cstring): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountGenerate(paramsJSON)
  tearDownForeignThreadGc()

proc multiAccountReset(): cstring {.exportc.} =
  setupForeignThreadGc()
  result = status_go.MultiAccountReset()
  tearDownForeignThreadGc()
