{.push raises: [Defect].}

import # std libs
  std/[json, strutils]

import # vendor libs
  chronos, json_rpc/client, web3

import # status modules
  ./common, ./settings

type
  Web3Error* = object of StatusError

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
  Web3 {.raises: [Defect, Web3Error].} =

  if network.isNone:
    raise (ref Web3Error)(msg: "config not found for network " & networkName)

  if not network.get().config.upstreamConfig.enabled:
    raise (ref Web3Error)(msg: "network " & networkName & " is not enabled")

  try:
    waitFor newWeb3(network.get().config.upstreamConfig.url)
  except CatchableError as e:
    raise (ref Web3Error)(parent: e, msg: "Error instantiating Web3 object")

proc newWeb3*(settings: Settings, networkName: string):
  Web3 {.raises: [CatchableError, Defect, ref Web3Error].} =

  let network = settings.getNetwork(networkName)
  getWeb3Conn(networkName, network)

proc newWeb3*(settings: Settings): Web3 {.raises: [CatchableError, Defect,
  ref Web3Error].} =
  let network = settings.getCurrentNetwork()
  getWeb3Conn(settings.currentNetwork, network)

proc callRpc*(web3Conn: Web3, rpcMethod: RemoteMethod, params: JsonNode):
  Future[Response] {.async, raises: [Defect, CatchableError].} =
  const errorMsg = "Error calling RPC method"
  try:
    return await web3Conn.provider.call($rpcMethod, params)
  except CatchableError as e:
    raise (ref Web3Error)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref Web3Error)(parent: e, msg: errorMsg)


proc callRpc*(web3Conn: Web3, rpcMethod: string, params: JsonNode):
  Future[Response] {.async, raises: [CatchableError, Defect, ref Web3Error].} =

  if web3Conn == nil:
    raise (ref Web3Error)(msg: "web3 connection is not available")

  try:
    discard parseEnum[RemoteMethod](rpcMethod)
  except:
    return %* {"code": -32601, "message": "the method " & rpcMethod & " does not exist/is not available"}

  const errorMsg = "Error calling RPC method"
  try:
    return await web3Conn.provider.call(rpcMethod, params)
  except CatchableError as e:
    raise (ref Web3Error)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref Web3Error)(parent: e, msg: errorMsg)
