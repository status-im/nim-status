{.push raises: [Defect].}

import # std libs
  std/[json, strformat, strutils]

import # vendor libs
  chronos, chronicles,
  eth/common as eth_common,
  eth/[common/transaction, keys],
  json_rpc/client, json_serialization, web3

import # status modules
  ./common, ./settings, ./util

type
  # remoteMethods contains methods that should be routed to
  # the upstream node; the rest is considered to be routed to
  # the local node.
  RemoteMethod* {.pure.} = enum
    eth_protocolVersion = "eth_protocolVersion",
    eth_syncing = "eth_syncing",
    eth_coinbase = "eth_coinbase",
    eth_mining = "eth_mining",
    eth_hashrate = "eth_hashrate",
    eth_gasPrice = "eth_gasPrice",
    # eth_accounts = "eth_accounts" # due to sub-accounts handling
    eth_blockNumber = "eth_blockNumber",
    eth_getBalance = "eth_getBalance",
    eth_getStorageAt = "eth_getStorageAt",
    eth_getTransactionCount = "eth_getTransactionCount",
    eth_getBlockTransactionCountByHash = "eth_getBlockTransactionCountByHash"
    eth_getBlockTransactionCountByNumber = "eth_getBlockTransactionCountByNumber",
    eth_getUncleCountByBlockHash = "eth_getUncleCountByBlockHash",
    eth_getUncleCountByBlockNumber = "eth_getUncleCountByBlockNumber",
    eth_getCode = "eth_getCode",
    # eth_sign = "eth_sign" # only the local node has an injected account to sign the payload with
    # eth_sendTransaction = "eth_sendTransaction" # we handle this specially calling eth_estimateGas, signing it locally and sending eth_sendRawTransaction afterwards
    eth_sendRawTransaction = "eth_sendRawTransaction",
    eth_call = "eth_call",
    eth_estimateGas = "eth_estimateGas",
    eth_getBlockByHash = "eth_getBlockByHash",
    eth_getBlockByNumber = "eth_getBlockByNumber",
    eth_getTransactionByHash = "eth_getTransactionByHash",
    eth_getTransactionByBlockHashAndIndex = "eth_getTransactionByBlockHashAndIndex",
    eth_getTransactionByBlockNumberAndIndex = "eth_getTransactionByBlockNumberAndIndex",
    eth_getTransactionReceipt = "eth_getTransactionReceipt",
    eth_getUncleByBlockHashAndIndex = "eth_getUncleByBlockHashAndIndex",
    eth_getUncleByBlockNumberAndIndex = "eth_getUncleByBlockNumberAndIndex",
    # eth_getCompilers = "eth_getCompilers"    # goes to the local because there's no need to send it anywhere
    # eth_compileLLL = "eth_compileLLL"      # goes to the local because there's no need to send it anywhere
    # eth_compileSolidity = "eth_compileSolidity" # goes to the local because there's no need to send it anywhere
    # eth_compileSerpent = "eth_compileSerpent"  # goes to the local because there's no need to send it anywhere
    eth_getLogs = "eth_getLogs",
    eth_getWork = "eth_getWork",
    eth_submitWork = "eth_submitWork",
    eth_submitHashrate = "eth_submitHashrate",
    net_version = "net_version",
    net_peerCount = "net_peerCount",
    net_listening = "net_listening"


proc getWeb3Conn*(networkName: string, network: Option[Network]):
  Web3Result[Web3] =

  if network.isNone:
    return err Web3Error(kind: web3Internal,
      internalError: InitFailureNetSettings)

  if not network.get().config.upstreamConfig.enabled:
    return err Web3Error(kind: web3Internal,
      internalError: InitFailureNetSettings)

  try:
    # TODO: this proc should be async instead of using `waitFor`
    ok waitFor newWeb3(network.get().config.upstreamConfig.url)
  except CatchableError: err Web3Error(kind: web3Internal,
      internalError: InitFailureBadUrlScheme)

proc newWeb3*(settings: Settings, networkName: string): Web3Result[Web3] =
  let network = settings.getNetwork(networkName)
  getWeb3Conn(networkName, network)

proc newWeb3*(settings: Settings): Web3Result[Web3] =
  let network = settings.getCurrentNetwork()
  getWeb3Conn(settings.currentNetwork, network)

proc callRpc*(web3Conn: Web3, rpcMethod: RemoteMethod, params: JsonNode):
  Future[Web3Result[Response]] {.async.} =

  try:
    let resp = await web3Conn.provider.call($rpcMethod, params)
    return ok resp
  except ValueError as e:
    try:
      let rpcError = Json.decode(e.msg, RpcError, allowUnknownFields = true)
      return err Web3Error(kind: web3Rpc, rpcError: rpcError)
    except:
      return err Web3Error(kind: web3Internal,
        internalError: ParseRpcResponseError)
  except CatchableError:
    return err Web3Error(kind: web3Internal, internalError: UnknownRpcError)

proc callRpc*(web3Conn: Web3, rpcMethod: string, params: JsonNode):
  Future[Web3Result[Response]] {.async.} =

  if web3Conn == nil:
    return err Web3Error(kind: web3Internal,
      internalError: Web3ValueError)

  var rpcMethodParsed: RemoteMethod
  try:
    rpcMethodParsed = parseEnum[RemoteMethod](rpcMethod)
  except:
    let rpcError = RpcError(
      code: -32601,
      message: fmt(static("the method {rpcMethod} does not exist/is ")) &
        "not available"
    )
    return err(Web3Error(kind: web3Rpc, rpcError: rpcError))

  try:
    let resp = await web3Conn.provider.call($rpcMethod, params)
    return ok resp
  except ValueError as e:
    try:
      let rpcError = Json.decode(e.msg, RpcError, allowUnknownFields = true)
      return err Web3Error(kind: web3Rpc, rpcError: rpcError)
    except:
      return err Web3Error(kind: web3Internal,
        internalError: ParseRpcResponseError)
  except CatchableError:
    return err Web3Error(kind: web3Internal, internalError: UnknownRpcError)

proc signTransaction*(tr: var Transaction, pk: PrivateKey) =
  let h = tr.txHashNoSignature
  let s = sign(pk, SkMessage(h.data))

  var r = toRaw(s)
  let v = r[64]

  tr.R = fromBytesBE(UInt256, r.toOpenArray(0, 31))
  tr.S = fromBytesBE(UInt256, r.toOpenArray(32, 63))

  tr.V = int64(v)

  if tr.txType == TxType.TxLegacy:
    tr.V += 27 # TODO! Complete this
