import # std libs
  std/json

import # vendor libs
  chronos

import # status modules
  ../private/callrpc,
  ./common

type
  CallRpcResult* = Result[JsonNode, string]

proc callRpc*(self: StatusObject, rpcMethod: string, params: JsonNode):
  Future[CallRpcResult] {.async, raises: [Exception].} =

  if not self.isLoggedIn:
    return CallRpcResult.err "Not logged in. Must be logged in"

  try:
    return CallRpcResult.ok await self.web3.callRpc(rpcMethod, params)
  except CatchableError as e:
    return CallRpcResult.err e.msg
