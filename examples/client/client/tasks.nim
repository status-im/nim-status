import # std libs
  std/os

import # vendor libs
  stew/byteutils, task_runner

from eth/common as eth_common import EthAddress, Transaction

import # status lib
  status/api/[accounts, auth, opensea, provider, tokens, waku, wallet],
  status/private/[alias, protocol]

import # client modules
  ./common, ./events, ./serialization

logScope:
  topics = "client"

type
  StatusArg* = ref object of ContextArg
    chanSendToHost*: WorkerChannel
    clientConfig*: ClientConfig

var
  chanSendToHost {.threadvar.}: WorkerChannel
  conf {.threadvar.}: ClientConfig
  extIp {.threadvar.}: Option[ValidIpAddress]
  extTcpPort {.threadvar.}: Option[Port]
  extUdpPort {.threadvar.}: Option[Port]
  natIsSetup {.threadvar.}: bool
  nodekey {.threadvar.}: Nodekey
  nodekeyGenerated {.threadvar.}: bool
  status {.threadvar.}: StatusObject
  stopped {.threadvar.}: bool
  updatePricesTimeout {.threadvar.}: Duration
  updatingPrices {.threadvar.}: bool

const signalHandler: StatusSignalHandler = proc(signal: StatusSignal)
  {.async, gcsafe, nimcall.} =

  if not stopped:
    case signal.kind:
      of StatusEventKind.chat2Message:
        let
          signalEvent = cast[Chat2MessageEvent](signal.event)
          chat2Message = signalEvent.data
          message = string.fromBytes(chat2Message.payload)
          timestamp = chat2Message.timestamp
          topic = signalEvent.topic
          username = chat2Message.nick
          event = UserMessageEvent(message: message, timestamp: timestamp,
            topic: topic, username: username)

          eventEnc = event.encode

        trace "signalHandler sent event to host", event=eventEnc
        asyncSpawn chanSendToHost.send(eventEnc.safe)

      of StatusEventKind.chat2MessageError:
        let
          signalEvent = cast[Chat2MessageErrorEvent](signal.event)
          err = signalEvent.error
          timestamp = signalEvent.timestamp
          topic = signalEvent.topic

        error "error handling chat2 message", error=err, timestamp, topic

      of StatusEventKind.publicChatMessage:
        let
          signalEvent = cast[PublicChatMessageEvent](signal.event)
          publicChatMessage = signalEvent.data
          message = publicChatMessage.message.text
          timestamp = publicChatMessage.timestamp
          topic = signalEvent.topic
          username = publicChatMessage.alias
          event = UserMessageEvent(message: message, timestamp: timestamp,
            topic: topic, username: username)

          eventEnc = event.encode

        trace "signalHandler sent event to host", event=eventEnc
        asyncSpawn chanSendToHost.send(eventEnc.safe)

      of StatusEventKind.publicChatMessageError:
        let
          signalEvent = cast[PublicChatMessageErrorEvent](signal.event)
          err = signalEvent.error
          timestamp = signalEvent.timestamp
          topic = signalEvent.topic

        error "error handling public chat message", error=err, timestamp, topic

proc statusContext*(arg: ContextArg) {.async, gcsafe, nimcall,
  raises: [Defect].} =

  let contextArg = cast[StatusArg](arg)

  chanSendToHost = contextArg.chanSendToHost
  conf = contextArg.clientConfig
  stopped = false

  # in a separate commit/PR, rename `StatusObject` to `Status`
  status = StatusObject.new(dataDir = conf.dataDir,
    signalHandler = signalHandler).expect("StatusObject init should never fail")

  let contentTopicsStr = conf.contentTopics.strip()
  if contentTopicsStr != "":
    let contentTopics = contentTopicsStr.split(" ").toOrderedSet()
    for topic in contentTopics.items:
      let t = ContentTopic.init(topic)
      if t.isOk:
        status.joinTopic(t.get)

  updatePricesTimeout = 60000.milliseconds # 60 seconds by default
  updatingPrices = false

proc updatePrices() {.async.} =
  updatingPrices = true

  while status.loginState == LoginState.loggedin:
    let res = await status.updatePrices()
    if res.isErr:
      # TODO: send error to the TUI for display (possibly in the status bar?)
      error "failed to update prices", error = $res.error
    await sleepAsync(updatePricesTimeout)

  updatingPrices = false

proc addWalletAccount*(name: string, password: string)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let
    dir = status.dataDir / "keystore"
    # Hardcode bip39Passphrase to empty string. Can be enabled in UI later if
    # needed.
    walletAccountResult = status.addWalletAccount(name, password, dir)

  if walletAccountResult.isErr:
    let
      event = AddWalletAccountEvent(error: $walletAccountResult.error,
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    walletAccount = walletAccountResult.get
    walletName = walletAccount.name.get("")
    event = AddWalletAccountEvent(name: walletName,
      address: walletAccount.address, timestamp: timestamp)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc addWalletPrivateKey*(name: string, privateKey:string, password: string)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let
    dir = status.dataDir / "keystore"
    walletAccountResult = status.addWalletPrivateKey(privateKey, name, password,
      dir)

  if walletAccountResult.isErr:
    let
      event = AddWalletAccountEvent(error: $walletAccountResult.error,
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    walletAccount = walletAccountResult.get
    walletName = walletAccount.name.get("")
    event = AddWalletAccountEvent(name: walletName,
      address: walletAccount.address, timestamp: timestamp)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc addWalletSeed*(name: string, mnemonic: string, password: string,
  bip39Passphrase: string) {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let
    dir = status.dataDir / "keystore"
    walletAccountResult = status.addWalletSeed(Mnemonic mnemonic, name,
      password, dir, bip39Passphrase)

  if walletAccountResult.isErr:
    let
      event = AddWalletAccountEvent(error: $walletAccountResult.error,
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    walletAccount = walletAccountResult.get
    walletName = walletAccount.name.get("")
    event = AddWalletAccountEvent(name: walletName,
      address: walletAccount.address, timestamp: timestamp)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc addWalletWatchOnly*(address: string, name: string)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix


  let addressParsed = address.parseAddress
  if addressParsed.isErr:
    let
      event = AddWalletAccountEvent(error: "Error adding watch-only wallet " &
        "account: " & $addressParsed.error, timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let walletAccountResult = status.addWalletWatchOnly(addressParsed.get, name)

  if walletAccountResult.isErr:
    let
      event = AddWalletAccountEvent(error: $walletAccountResult.error,
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    walletAccount = walletAccountResult.get
    walletName = if walletAccount.name.isNone: "" else: walletAccount.name.get
    event = AddWalletAccountEvent(name: walletName,
      address: walletAccount.address, timestamp: timestamp)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc createAccount*(password: string) {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let
    dir = status.dataDir / "keystore"
    # Hardcode bip39Passphrase to empty string. Can be enabled in UI later if
    # needed.
    publicAccountResult = status.createAccount(12, "", password, dir)

  if publicAccountResult.isErr:
    let
      event = CreateAccountEvent(error: "Error creating account, error: " &
        $publicAccountResult.error, timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    account = publicAccountResult.get
    event = CreateAccountEvent(account: account, timestamp: timestamp)
    eventEnc = event.encode


  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc deleteWalletAccount*(index: int, password: string)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  var
    event: DeleteWalletAccountEvent
    numberedAccount: WalletAccount
    address: Address

  let allAccounts = status.getWalletAccounts()
  if allAccounts.isErr:
    event = DeleteWalletAccountEvent(error: "error getting wallet accounts: " &
      $allAccounts.error)

  elif index < 1 or index > allAccounts.get.len:
    event = DeleteWalletAccountEvent(error: "bad account index number")

  else:
    numberedAccount = allAccounts.get[index - 1]
    address = numberedAccount.address

    let
      dir = status.dataDir / "keystore"
      walletResult = status.deleteWalletAccount(address, password, dir)

    if walletResult.isOk:
      let wallet = walletResult.get
      event = DeleteWalletAccountEvent(name: wallet.name.get("(unnamed)"),
        address: $wallet.address, timestamp: timestamp)

    else:
      event = DeleteWalletAccountEvent(error: $walletResult.error,
        timestamp: timestamp)

  let eventEnc = event.encode
  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc importMnemonic*(mnemonic: string, bip39Passphrase: string,
  password: string) {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix
    dir = status.dataDir / "keystore"

  let importedResult = status.importMnemonic(Mnemonic mnemonic, bip39Passphrase,
      password, dir)

  if importedResult.isErr:
    let
      event = ImportMnemonicEvent(error: "Error importing mnemonic: " &
        $importedResult.error, timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    account = importedResult.get
    event = ImportMnemonicEvent(account: account, timestamp: timestamp)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc joinTopic*(topic: ContentTopic) {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  status.joinTopic(topic)

  let
    event = JoinTopicEvent(timestamp: timestamp, topic: topic)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

  if status.wakuFilter: (await status.addFilters(@[topic])).expect(
    "addFilters is not expected to fail in this context")

  if status.wakuStore: (await status.queryHistory(@[topic])).expect(
    "queryHistory is not expected to fail in this context")

proc leaveTopic*(topic: ContentTopic) {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  status.leaveTopic(topic)

  let
    event = LeaveTopicEvent(timestamp: timestamp, topic: topic)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

  if status.wakuFilter: (await status.removeFilters(@[topic])).expect(
    "removeFilters is not expected to fail in this context")

proc listAccounts*() {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let accountsResult = status.getPublicAccounts()

  if accountsResult.isErr:
    let
      event = ListAccountsEvent(error: "Error listing accounts: " &
        $accountsResult.error, timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)

  let
    event = ListAccountsEvent(accounts: accountsResult.get,
      timestamp: timestamp)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc listWalletAccounts*() {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let accounts = status.getWalletAccounts()
  if accounts.isErr:
    let
      event = ListWalletAccountsEvent(error: $accounts.error,
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    event = ListWalletAccountsEvent(accounts: accounts.get,
      timestamp: timestamp)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc login*(account: int, password: string)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let allAccountsResult = status.getPublicAccounts()

  if allAccountsResult.isErr:
    let
      event = LoginEvent(error: $allAccountsResult.error, loggedin: false,
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  var
    event: LoginEvent
    eventEnc: string
    numberedAccount: PublicAccount
    keyUid: string

  let allAccounts = allAccountsResult.get

  if account < 1 or account > allAccounts.len:
    event = LoginEvent(error: "bad account number", loggedin: false,
      timestamp: timestamp)

    eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  numberedAccount = allAccounts[account - 1]
  keyUid = numberedAccount.keyUid

  let loginResult = status.login(keyUid, password)

  if loginResult.isErr:
    event = LoginEvent(error: $loginResult.error, loggedin: false,
      timestamp: timestamp)

    eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  event = LoginEvent(account: loginResult.get, loggedin: true,
    timestamp: timestamp)

  eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

  if not updatingPrices: asyncSpawn updatePrices()

  var netEvent: WakuConnectionEvent

  if not natIsSetup:
    (extIp, extTcpPort, extUdpPort) = setupNat(conf.nat, clientId,
      Port(uint16(conf.tcpPort) + conf.portsShift),
      Port(uint16(conf.udpPort) + conf.portsShift))

    natIsSetup = true

  if not nodekeyGenerated:
    nodekey =
      if $conf.nodekey == "":
        Nodekey.init()
      else:
        # per ../config `conf.nodekey` has already been validated
        Nodekey.fromHex($conf.nodekey).get

    nodekeyGenerated = true

  let connectResult = await status.connect(nodekey, extIp, extTcpPort,
    extUdpPort, ValidIpAddress.init($conf.listenAddress), conf.tcpPort,
    conf.udpPort, conf.portsShift, conf.topics.split(" "), conf.rlnRelay,
    conf.relay, conf.fleet, conf.staticnodes, conf.swap, conf.filternode,
    conf.lightpushnode, conf.store, conf.storenode, conf.keepalive)

  if connectResult.isErr:
    netEvent = WakuConnectionEvent(error: $connectResult.error, online: false,
      timestamp: timestamp)

    eventEnc = netEvent.encode
    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  netEvent = WakuConnectionEvent(online: true, timestamp: timestamp)
  eventEnc = netEvent.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

  if status.wakuStore: (await status.queryHistory(status.getTopics)).expect(
    "queryHistory is not expected to fail in this context")

proc logout*() {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  var
    eventEnc: string
    event: LogoutEvent
    netEvent: WakuConnectionEvent

  if status.networkState == NetworkState.online:
    let disconnectResult = await status.disconnect()

    if disconnectResult.isErr:
      netEvent = WakuConnectionEvent(error: $disconnectResult.error, online: true,
        timestamp: timestamp)

      eventEnc = netEvent.encode
      trace "task sent error event to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)

      event = LogoutEvent(error: "Logout failed because disonnect failed",
        loggedin: true, timestamp: timestamp)

      eventEnc = event.encode
      trace "task sent error event to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)
      return

    netEvent = WakuConnectionEvent(online: false, timestamp: timestamp)
    eventEnc = netEvent.encode

    trace "task sent event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)

  let logoutResult = status.logout()

  if logoutResult.isErr:
    event = LogoutEvent(error: $logoutResult.error, loggedin: true,
      timestamp: timestamp)

    eventEnc = event.encode

    trace "task sent event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  event = LogoutEvent(loggedin: false, timestamp: timestamp)
  eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc connect*() {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  var
    event: WakuConnectionEvent
    eventEnc: string

  if not natIsSetup:
    (extIp, extTcpPort, extUdpPort) = setupNat(conf.nat, clientId,
      Port(uint16(conf.tcpPort) + conf.portsShift),
      Port(uint16(conf.udpPort) + conf.portsShift))

    natIsSetup = true

  if not nodekeyGenerated:
    nodekey =
      if $conf.nodekey == "":
        Nodekey.init()
      else:
        # per ../config `conf.nodekey` has already been validated
        Nodekey.fromHex($conf.nodekey).get

    nodekeyGenerated = true

  let connectResult = await status.connect(nodekey, extIp, extTcpPort,
    extUdpPort, ValidIpAddress.init($conf.listenAddress), conf.tcpPort,
    conf.udpPort, conf.portsShift, conf.topics.split(" "), conf.rlnRelay,
    conf.relay, conf.fleet, conf.staticnodes, conf.swap, conf.filternode,
    conf.lightpushnode, conf.store, conf.storenode, conf.keepalive)

  if connectResult.isErr:
    event = WakuConnectionEvent(error: $connectResult.error, online: false,
      timestamp: timestamp)

    eventEnc = event.encode
    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  event = WakuConnectionEvent(online: true, timestamp: timestamp)
  eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

  if status.wakuStore: (await status.queryHistory(status.getTopics)).expect(
    "queryHistory is not expected to fail in this context")

proc disconnect*() {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  var
    event: WakuConnectionEvent
    eventEnc: string

  let disconnectResult = await status.disconnect()

  if disconnectResult.isErr:
    event = WakuConnectionEvent(error: $disconnectResult.error, online: true,
      timestamp: timestamp)

    eventEnc = event.encode
    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  event = WakuConnectionEvent(online: false, timestamp: timestamp)
  eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc sendMessage*(message: string, topic: ContentTopic)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  var
    event: SendMessageEvent
    eventEnc: string

  let sendResult = await status.sendMessage(message, topic)

  if sendResult.isErr:
    event = SendMessageEvent(error: $sendResult.error, sent: false,
      timestamp: timestamp)

    eventEnc = event.encode
    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  event = SendMessageEvent(sent: true, timestamp: timestamp)
  eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc getAssets*(owner: Address) {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let assets = await status.getOpenseaAssets(owner)

  if assets.isErr:
    let
      event = GetAssetsEvent(error: $assets.error)
      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    event = GetAssetsEvent(assets: assets.get, timestamp: timestamp)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc getCustomTokens*() {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let tokens = status.getCustomTokens()

  if tokens.isErr:
    let
      event = GetCustomTokensEvent(error: $tokens.error)
      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    event = GetCustomTokensEvent(tokens: tokens.get,
      timestamp: timestamp)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc addCustomToken*(address: Address, name: string, symbol: string,
  color: string, decimals: uint) {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let addResult = status.addCustomToken(address, name, symbol, color, decimals)
  if addResult.isErr:
    let
      event = AddCustomTokenEvent(error: $addResult.error,
        timestamp: timestamp)

      eventEnc = event.encode


    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    token = addResult.get
    event = AddCustomTokenEvent(address: $token.address, name: token.name,
      symbol: token.symbol, color: token.color, decimals: token.decimals,
      timestamp: timestamp)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc deleteCustomToken*(index: int) {.task(kind=no_rts, stoppable=false).} =
  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let allTokensResult = status.getCustomTokens()

  if allTokensResult.isErr:
    let
      event = DeleteCustomTokenEvent(error: $allTokensResult.error,
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let allTokens = allTokensResult.get

  if index > allTokens.len:
    let
      event = DeleteCustomTokenEvent(error: "bad token number",
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    address = allTokens[index - 1].address
    deleteResult = status.deleteCustomToken(address)

  if deleteResult.isErr:
    let
      event = DeleteCustomTokenEvent(error: $deleteResult.error,
        timestamp: timestamp)

      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    event = DeleteCustomTokenEvent(address: $address, timestamp: timestamp)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc callRpc*(rpcMethod: string, params: JsonNode)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let callResult = await status.callRpc(rpcMethod, params)

  if callResult.isErr:
    let
      error = callResult.error
      errorMsg =  if error.kind == pRpc:
                    error.rpcError.message
                  else:
                    $error.apiError
      event = CallRpcEvent(error: errorMsg, timestamp: timestamp)
      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    response = callResult.get
    event = CallRpcEvent(response: $response, timestamp: timestamp)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc getPrice*(tokenSymbol: string, fiatCurrency: string)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let price = status.getPrice(tokenSymbol, fiatCurrency)

  if price.isErr:
    let
      event = GetPriceEvent(error: $price.error)
      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    event = GetPriceEvent(symbol: tokenSymbol, currency: fiatCurrency,
      price: price.get, timestamp: timestamp)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc setPriceTimeout*(priceTimeout: int)
  {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  updatePricesTimeout = (priceTimeout * 1000).milliseconds

  let
    event = SetPriceTimeoutEvent(timeout: priceTimeout, timestamp: timestamp)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc sendTransaction*(fromAddress: EthAddress, transaction: Transaction,
  password: string) {.task(kind=no_rts, stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  let dir = status.dataDir / "keystore"
  let sendTransactionResult = await status.sendTransaction(fromAddress,
    transaction, password, dir)

  if sendTransactionResult.isErr:
    let
      error = sendTransactionResult.error
      errorMsg = if error.kind == pRpc:
                   error.rpcError.message
                 else:
                   $error.apiError

      event = SendTransactionEvent(error: errorMsg, timestamp: timestamp)
      eventEnc = event.encode

    trace "task sent error event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    response = sendTransactionResult.get
    event = SendTransactionEvent(response: $response, timestamp: timestamp)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc getTopics*(): seq[ContentTopic] {.task(kind=rts, stoppable=false).} =
  let
    task = taskArg.taskName
    topics = status.getTopics()

  trace "task returned result to sender", task, result=topics
  asyncSpawn chanReturnToSender.send(topics.encode.safe)

proc stopContext*() {.task(kind=rts, stoppable=false).} =
  let task = taskArg.taskName

  stopped = true
  discard await status.disconnect()
  discard status.logout()
  discard status.close()

  trace "task returned result to sender", task, result="void", stopped
  asyncSpawn chanReturnToSender.send("done".safe)
