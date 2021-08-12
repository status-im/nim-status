{.push raises: [Defect].}

import # std libs
  std/json

import # vendor libs
  chronicles, chronos, eth/common as eth_common,
  eth/[keys, rlp],
  stew/byteutils

import # status modules
  ../private/[accounts/accounts, accounts/generator/generator, callrpc,
              settings],
  ./common

type
  ProviderApiError* = enum
    AccountLoadError   = "provider: error loading account"
    AccountNotLoaded   = "provider: account cannot be found because it is " &
                           "not loaded"
    GetNetworkFailure  = "provider: could not determine current network"
    GetSettingsFailure = "provider: failed to get settings"
    GetWeb3Error       = "provider: error getting web3 provider"
    InternalRpcError   = "provider: RPC error"
    MustBeLoggedIn     = "provider: operation not permitted, must be logged in"
    UserDbError        = "provider: user DB error, must be logged in"
    WalletError        = "provider: wallet address not found"

  pErrorKind* = enum
    ## Web3 Error Kinds
    pApi,
    pRpc

  ProviderError* = object
    case kind*: pErrorKind
    of pApi:
      apiError*: ProviderApiError
    of pRpc:
      rpcError*: RpcError

  RpcError* = object
    code*: int
    message*: string

  ProviderResult*[T] = Result[T, ProviderError]

proc callRpc*(self: StatusObject, rpcMethod: string, params: JsonNode):
  Future[ProviderResult[JsonNode]] {.async.} =

  if not self.isLoggedIn:
    return err ProviderError(kind: pApi, apiError: MustBeLoggedIn)

  let web3Result = self.web3
  if web3Result.isErr:
    return err ProviderError(kind: pApi, apiError: GetWeb3Error)

  let
    web3 = web3Result.get
    respResult = await web3.callRpc(rpcMethod, params)
  if respResult.isErr:
    let error = respResult.error
    if error.kind == web3Internal:
      return err ProviderError(kind: pApi, apiError: InternalRpcError)
    else:
      let
        ogRpcError = error.rpcError
        rpcError = RpcError(code: ogRpcError.code, message: ogRpcError.message)
      return err ProviderError(kind: pRpc, rpcError: rpcError)
  return ok(respResult.get)

proc sendTransaction*(self: StatusObject, fromAddress: EthAddress,
  transaction: Transaction, password: string, dir: string):
  Future[ProviderResult[JsonNode]] {.async.} =

  if not self.isLoggedIn:
    return err ProviderError(kind: pApi, apiError: MustBeLoggedIn)

  let db = self.userDb()
  if db.isErr:
    return err ProviderError(kind: pApi, apiError: UserDbError)

  let account = db.get.getWalletAccount(Address(fromAddress))
  if account.isErr:
    return err ProviderError(kind: pApi, apiError: WalletError)

  if account.get.isNone:
    return err ProviderError(kind: pApi, apiError: WalletError)

  let loadAccountResult = self.accountsGenerator.loadAccount(
    account.get.get.address, password, dir)
  if loadAccountResult.isErr:
    return err ProviderError(kind: pApi, apiError: AccountLoadError)

  let accountResult = self.accountsGenerator.findAccount(
    loadAccountResult.get.id)
  if accountResult.isErr:
    return err ProviderError(kind: pApi, apiError: AccountNotLoaded)

  let settings = db.get.getSettings()
  if settings.isErr:
    return err ProviderError(kind: pApi, apiError: GetSettingsFailure)

  let network = settings.get.getCurrentNetwork()
  if network.isNone:
    return err ProviderError(kind: pApi, apiError: GetNetworkFailure)

  var trx = transaction
  trx.chainId = ChainId(network.get.config.networkId)
  signTransaction(trx, PrivateKey(accountResult.get.secretKey))
  let rawTransaction = "0x" & rlp.encode(trx).toHex

  let
    rpcMethod = RemoteMethod.eth_sendRawTransaction
    params = %*[rawTransaction]

  let web3Result = self.web3
  if web3Result.isErr:
    return err ProviderError(kind: pApi, apiError: GetWeb3Error)

  let
    web3 = web3Result.get
    respResult = await web3.callRpc(rpcMethod, params)

  if respResult.isErr:
    let error = respResult.error
    if error.kind == web3Internal:
      return err ProviderError(kind: pApi, apiError: InternalRpcError)
    else:
      let
        ogRpcError = error.rpcError
        rpcError = RpcError(code: ogRpcError.code, message: ogRpcError.message)
      return err ProviderError(kind: pRpc, rpcError: rpcError)
  return ok respResult.get
