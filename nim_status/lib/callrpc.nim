import web3, os, json, chronos, json_rpc/client
import settings, sets

type Web3Error* = object of CatchableError

# remoteMethods contains methods that should be routed to
# the upstream node; the rest is considered to be routed to
# the local node.
const remoteMethods = toHashSet([
  "eth_protocolVersion",
  "eth_syncing",
  "eth_coinbase",
  "eth_mining",
  "eth_hashrate",
  "eth_gasPrice",
  # "eth_accounts", # due to sub-accounts handling
  "eth_blockNumber",
  "eth_getBalance",
  "eth_getStorageAt",
  "eth_getTransactionCount",
  "eth_getBlockTransactionCountByHash",
  "eth_getBlockTransactionCountByNumber",
  "eth_getUncleCountByBlockHash",
  "eth_getUncleCountByBlockNumber",
  "eth_getCode",
  # "eth_sign", # only the local node has an injected account to sign the payload with
  # "eth_sendTransaction", # we handle this specially calling eth_estimateGas, signing it locally and sending eth_sendRawTransaction afterwards
  "eth_sendRawTransaction",
  "eth_call",
  "eth_estimateGas",
  "eth_getBlockByHash",
  "eth_getBlockByNumber",
  "eth_getTransactionByHash",
  "eth_getTransactionByBlockHashAndIndex",
  "eth_getTransactionByBlockNumberAndIndex",
  "eth_getTransactionReceipt",
  "eth_getUncleByBlockHashAndIndex",
  "eth_getUncleByBlockNumberAndIndex",
  # "eth_getCompilers",    # goes to the local because there's no need to send it anywhere
  # "eth_compileLLL",      # goes to the local because there's no need to send it anywhere
  # "eth_compileSolidity", # goes to the local because there's no need to send it anywhere
  # "eth_compileSerpent",  # goes to the local because there's no need to send it anywhere
  "eth_getLogs",
  "eth_getWork",
  "eth_submitWork",
  "eth_submitHashrate",
  "net_version",
  "net_peerCount",
  "net_listening",
])


proc newWeb3*(settings: Settings): Web3 =
  let network = settings.getNetwork()
  if network.isNone:
    raise (ref Web3Error)(msg: "Config not found for network " & settings.currentNetwork)

  if not network.get().config.upstreamConfig.enabled: 
    raise (ref Web3Error)(msg: "Network " & settings.currentNetwork & " is not enabled")

  result = waitFor newWeb3(network.get().config.upstreamConfig.url)


proc callRPC*(web3Conn: Web3, rpcMethod: string, params: JsonNode): Response =
  try:
    # TODO: implement call to eth_accounts?
    if not remoteMethods.contains(rpcMethod):
      return (true, %* {"code": -32601, "message": "the method " & rpcMethod & " does not exist/is not available"})

    result = waitFor web3Conn.provider.call(rpcMethod, params)
  except ValueError:
    raise (ref Web3Error)(msg: getCurrentExceptionMsg())

