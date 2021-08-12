{.push raises: [Defect].}

import # std libs
  std/[json, sequtils, sugar]

import # vendor libs
  chronicles, chronos,
  eth/common as eth_common,
  eth/[common/transaction, keys, rlp],
  stew/byteutils

import # status modules
  ../private/[accounts/accounts, accounts/generator/generator, callrpc, settings],
  ./common

type
  CallRpcResult* = Result[JsonNode, string]

  SendTransactionResult* = Result[JsonNode, string]

proc callRpc*(self: StatusObject, rpcMethod: string, params: JsonNode):
  Future[CallRpcResult] {.async.} =

  if not self.isLoggedIn:
    return CallRpcResult.err "Not logged in. Must be logged in"

  try:
    return CallRpcResult.ok await self.web3.callRpc(rpcMethod, params)
  except CatchableError as e:
    return CallRpcResult.err e.msg

proc sendTransaction*(self: StatusObject, fromAddress: EthAddress, transaction: Transaction, password: string, dir: string):
  Future[SendTransactionResult] {.async.} =
  if not self.isLoggedIn:
    return SendTransactionResult.err "Not logged in. Must be logged in"

  try:
    let account = self.userDb.getWalletAccount(Address(fromAddress))
    if account.isNone:
      return SendTransactionResult.err "Wallet address not found"

    let loadAccountResult = self.accountsGenerator.loadAccount(account.get.address, password,dir)
    if loadAccountResult.isErr:
      return SendTransactionResult.err loadAccountResult.error

    let accountResult = self.accountsGenerator.findAccount(loadAccountResult.get.id)
    if accountResult.isErr:
      return SendTransactionResult.err accountResult.error

    let
      settings = self.userDb.getSettings()
      network = settings.getCurrentNetwork()

    var trx = transaction
    trx.chainId = ChainId(network.get.config.networkId)
    signTransaction(trx, PrivateKey(accountResult.get.secretKey))
    let rawTransaction = "0x" & rlp.encode(trx).toHex

    return SendTransactionResult.ok await self.web3.callRpc(RemoteMethod.eth_sendRawTransaction, %*[rawTransaction])
  except CatchableError as e:
    return SendTransactionResult.err e.msg
