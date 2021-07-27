import # chat libs
  ./client/tasks

export tasks

logScope:
  topics = "chat client"

# This module's purpose is to provide wrappers for task invocation to e.g. send
# a message via nim-status/waku running in a separate thread; starting the
# client also initiates listening for events coming from nim-status/waku.

# `type ChatClient` is defined in ./common to avoid circular dependency

proc new*(T: type ChatClient, chatConfig: ChatConfig): T =
  let statusArg = StatusArg(chatConfig: chatConfig)
  var taskRunner = TaskRunner.new()
  taskRunner.createWorker(thread, status, statusContext, statusArg)

  var topics: OrderedSet[string]
  let topicsStr = chatConfig.contentTopics.strip()
  if topicsStr != "":
    topics = topicsStr.split(" ").toOrderedSet()

  T(chatConfig: chatConfig, events: newEventChannel(), loggedin: false,
    online: false, running: false, taskRunner: taskRunner, topics: topics)

proc start*(self: ChatClient) {.async.} =
  debug "client starting"

  self.events.open()
  await self.taskRunner.start()

  # set `self.running = true` before any `asyncSpawn` so client logic can check
  # `self.running` to know whether to run / continue running / stop running
  self.running = true
  debug "client started"

  asyncSpawn self.listen()

proc stop*(self: ChatClient) {.async.} =
  debug "client stopping"

  self.running = false
  await self.taskRunner.stop()
  self.events.close()

  debug "client stopped"

proc addWalletAccount*(self: ChatClient, name, password: string) {.async.} =
  asyncSpawn addWalletAccount(self.taskRunner, status, name, password)

proc addWalletPrivateKey*(self: ChatClient, name: string, privateKey: string,
  password: string) {.async.} =

  asyncSpawn addWalletPrivateKey(self.taskRunner, status, name, privateKey,
    password)

proc addWalletSeed*(self: ChatClient, name, mnemonic, password,
  bip39passphrase: string) {.async.} =

  asyncSpawn addWalletSeed(self.taskRunner, status, name, mnemonic,
    password, bip39passphrase)

proc addWalletWatchOnly*(self: ChatClient, address, name: string) {.async.} =
  asyncSpawn addWalletWatchOnly(self.taskRunner, status, address, name)

proc connect*(self: ChatClient, username: string) {.async.} =
  asyncSpawn startWakuChat2(self.taskRunner, status, username)

proc disconnect*(self: ChatClient) {.async.} =
  asyncSpawn stopWakuChat2(self.taskRunner, status)

proc createAccount*(self: ChatClient, password: string) {.async.} =
  asyncSpawn createAccount(self.taskRunner, status, password)

proc importMnemonic*(self: ChatClient, mnemonic: string, passphrase: string,
  password: string) {.async.} =

  asyncSpawn importMnemonic(self.taskRunner, status, mnemonic, passphrase,
    password)

proc joinTopic*(self: ChatClient, topic: string) {.async.} =
  asyncSpawn joinTopic(self.taskRunner, status, topic)

proc leaveTopic*(self: ChatClient, topic: string) {.async.} =
  asyncSpawn leaveTopic(self.taskRunner, status, topic)

proc listAccounts*(self: ChatClient) {.async.} =
  asyncSpawn listAccounts(self.taskRunner, status)

proc listWalletAccounts*(self: ChatClient) {.async.} =
  asyncSpawn listWalletAccounts(self.taskRunner, status)

proc login*(self: ChatClient, account: int, password: string) {.async.} =
  asyncSpawn login(self.taskRunner, status, account, password)

proc logout*(self: ChatClient) {.async.} =
  asyncSpawn logout(self.taskRunner, status)

proc sendMessage*(self: ChatClient, message: string) {.async.} =
  asyncSpawn publishWakuChat2(self.taskRunner, status, message)

proc getCustomTokens*(self: ChatClient) {.async.} =
  asyncSpawn getCustomTokens(self.taskRunner, status)

proc addCustomToken*(self: ChatClient, address: Address, name, symbol, color: string, decimals: uint) {.async.} =
  asyncSpawn addCustomToken(self.taskRunner, status, address, name, symbol, color, decimals)

proc deleteCustomToken*(self: ChatClient, index: int) {.async.} =
  asyncSpawn deleteCustomToken(self.taskRunner, status, index)
