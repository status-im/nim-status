import # vendor libs
  eth/common as eth_common

import # client modules
  ./client/[common, events, tasks]

export # modules
  events

export # symbols
  Client, clientEvents

logScope:
  topics = "client"

# This module's purpose is to provide wrappers for task invocation to e.g. send
# a message via nim-status/waku running in a separate thread; starting the
# client also initiates listening for events coming from nim-status/waku.

# `type Client` is defined in ./common to avoid circular dependency

const status = "status"

proc new*(T: type Client, clientConfig: ClientConfig): T =
  var
    statusArg = StatusArg(clientConfig: clientConfig)
    taskRunner = TaskRunner.new()

  taskRunner.createWorker(thread, status, statusContext, statusArg)
  statusArg.chanSendToHost =
    taskRunner.workers[status].worker.chanRecvFromWorker

  T(clientConfig: clientConfig, events: newEventChannel(), running: false,
    taskRunner: taskRunner)

proc getTopics(self: Client): Future[seq[ContentTopic]] {.async, gcsafe.}

proc start*(self: Client) {.async.} =
  debug "client starting"

  self.events.open()
  await self.taskRunner.start()

  # set `self.running = true` before any `asyncSpawn` so client logic can check
  # `self.running` to know whether to run / continue running / stop running
  self.running = true
  debug "client started"

  asyncSpawn self.listen()
  self.topics = toOrderedSet(await self.getTopics())
  if self.topics.len > 0: self.currentTopic = self.topics.toSeq[^1]

proc stopContext(self: Client): Future[void] {.async, gcsafe.}

proc stop*(self: Client) {.async.} =
  debug "client stopping"

  self.running = false
  await self.stopContext()
  await self.taskRunner.stop()
  self.events.close()

  debug "client stopped"

# task invocation procs --------------------------------------------------------

proc addCustomToken*(self: Client, address: Address, name, symbol,
  color: string, decimals: uint) {.async.} =

  asyncSpawn addCustomToken(self.taskRunner, status, address, name, symbol,
    color, decimals)

proc addWalletAccount*(self: Client, name, password: string) {.async.} =
  asyncSpawn addWalletAccount(self.taskRunner, status, name, password)

proc addWalletPrivateKey*(self: Client, name: string, privateKey: string,
  password: string) {.async.} =

  asyncSpawn addWalletPrivateKey(self.taskRunner, status, name, privateKey,
    password)

proc addWalletSeed*(self: Client, name, mnemonic, password,
  bip39passphrase: string) {.async.} =

  asyncSpawn addWalletSeed(self.taskRunner, status, name, mnemonic,
    password, bip39passphrase)

proc addWalletWatchOnly*(self: Client, address, name: string) {.async.} =
  asyncSpawn addWalletWatchOnly(self.taskRunner, status, address, name)

proc callRpc*(self: Client, rpcMethod: string, params: JsonNode) {.async.} =
  asyncSpawn callRpc(self.taskRunner, status, rpcMethod, params)

proc connect*(self: Client) {.async.} =
  asyncSpawn connect(self.taskRunner, status)

proc createAccount*(self: Client, password: string) {.async.} =
  asyncSpawn createAccount(self.taskRunner, status, password)

proc deleteCustomToken*(self: Client, index: int) {.async.} =
  asyncSpawn deleteCustomToken(self.taskRunner, status, index)

proc deleteWalletAccount*(self: Client, index: int,
  password: string) {.async.} =

  asyncSpawn deleteWalletAccount(self.taskRunner, status, index, password)

proc disconnect*(self: Client) {.async.} =
  asyncSpawn disconnect(self.taskRunner, status)

proc getAssets*(self: Client, owner: Address) {.async.} =
  asyncSpawn getAssets(self.taskRunner, status, owner)

proc getCustomTokens*(self: Client) {.async.} =
  asyncSpawn getCustomTokens(self.taskRunner, status)

proc getTopics(self: Client): Future[seq[ContentTopic]] {.async, gcsafe.} =
  return await getTopics(self.taskRunner, status)

proc getPrice*(self: Client, tokenSymbol, fiatCurrency: string) {.async.} =
  asyncSpawn getPrice(self.taskRunner, status, tokenSymbol, fiatCurrency)

proc importMnemonic*(self: Client, mnemonic: string, passphrase: string,
  password: string) {.async.} =

  asyncSpawn importMnemonic(self.taskRunner, status, mnemonic, passphrase,
    password)

proc joinTopic*(self: Client, topic: ContentTopic) {.async.} =
  asyncSpawn joinTopic(self.taskRunner, status, topic)

proc leaveTopic*(self: Client, topic: ContentTopic) {.async.} =
  asyncSpawn leaveTopic(self.taskRunner, status, topic)

proc listAccounts*(self: Client) {.async.} =
  asyncSpawn listAccounts(self.taskRunner, status)

proc listWalletAccounts*(self: Client) {.async.} =
  asyncSpawn listWalletAccounts(self.taskRunner, status)

proc login*(self: Client, account: int, password: string) {.async.} =
  asyncSpawn login(self.taskRunner, status, account, password)

proc logout*(self: Client) {.async.} =
  asyncSpawn logout(self.taskRunner, status)

proc sendMessage*(self: Client, message: string, topic: ContentTopic)
  {.async.} =

  asyncSpawn sendMessage(self.taskRunner, status, message, topic)

proc sendTransaction*(self: Client, fromAddress: EthAddress,
  transaction: Transaction, password: string) {.async.} =

  asyncSpawn sendTransaction(self.taskRunner, status, fromAddress, transaction,
    password)

proc setPriceTimeout*(self: Client, timeout: int) {.async.} =
  asyncSpawn setPriceTimeout(self.taskRunner, status, timeout)

proc stopContext(self: Client) {.async, gcsafe.} =
  await stopContext(self.taskRunner, status)
