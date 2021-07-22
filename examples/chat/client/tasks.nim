import # std libs
  std/[os, strutils, sets, sugar, times]

import # nim-status libs
  ../../nim_status/[conversions, client, database],
  ../../nim_status/extkeys/[paths, types]

import # chat libs
  ./events, ./waku_chat2

export conversions, events

logScope:
  topics = "chat client"

type
  StatusArg* = ref object of ContextArg
    chatConfig*: ChatConfig

  StatusState* = enum loggedout, loggingin, loggedin, loggingout

  WakuState* = enum stopped, starting, started, stopping

const DefaultTopic = waku_chat2.DefaultTopic

var
  conf {.threadvar.}: ChatConfig
  connected {.threadvar.}: bool
  contentTopics {.threadvar.}: OrderedSet[ContentTopic]
  contextArg {.threadvar.}: StatusArg
  extIp {.threadvar.}: Option[ValidIpAddress]
  extTcpPort {.threadvar.}: Option[Port]
  extUdpPort {.threadvar.}: Option[Port]
  natIsSetup {.threadvar.}: bool
  nick {.threadvar.}: string
  nodekey {.threadvar.}: waku_chat2.crypto.PrivateKey
  nodekeyGenerated {.threadvar.}: bool
  subscribed {.threadvar.}: bool
  status {.threadvar.}: StatusObject
  statusState {.threadvar.}: StatusState
  wakuNode {.threadvar.}: WakuNode
  wakuState {.threadvar.}: WakuState

proc resetContext() {.gcsafe, nimcall.} =
  connected = false
  nick = ""
  subscribed = false
  wakuNode = nil
  wakuState = WakuState.stopped

proc statusContext*(arg: ContextArg) {.async, gcsafe, nimcall,
  raises: [Defect].} =

  # set threadvar values that are never reset, i.e. persist across
  # waku chat2 dis/connect
  contextArg = cast[StatusArg](arg)
  conf = contextArg.chatConfig

  let contentTopicsStr = conf.contentTopics.strip()
  if contentTopicsStr != "":
    contentTopics = contentTopicsStr.split(" ").toOrderedSet()

  # threadvar `natIsSetup` is a special case because the values of its
  # counterparts `ext[Ip,TcpPort,UdpPort]` only need to be set once, i.e. they
  # also persists across waku chat2 dis/connect; but note that
  # `ext[Ip,TcpPort,UdpPort]` themselves are set for the first time in task
  # `startWakuChat2` as a program startup optimization
  natIsSetup = false

  # threadvar `nodekeyGenerated` is a special case like `natIsSetup`, see
  # previous comment
  nodekeyGenerated = false

  status = StatusObject.new(conf.dataDir)
  # threadvar `statusState` is currently out of scope re: "resetting the
  # context"; the relevant code/logic can be reconsidered in the future, was
  # originally implemented in context of `startWakuChat2` and `stopWakuChat2`
  statusState = StatusState.loggedout

  # re/set threadvars that don't persist across waku chat2 dis/connect
  resetContext()

proc new(T: type UserMessageEvent, wakuMessage: WakuMessage): T =
  let topic = wakuMessage.contentTopic
  var
    message: string
    timestamp: int64
    username: string

  let protoResult = Chat2Message.init(wakuMessage.payload)

  if protoResult.isOk:
    let chat2Message = protoResult[]
    message = string.fromBytes(chat2Message.payload)
    timestamp = chat2Message.timestamp
    username = chat2Message.nick
  else:
     # could happen if one/more clients on the same network/topic are able to
     # communicate but are using incompatible encodings for some reason
     message = string.fromBytes(wakuMessage.payload)
     timestamp = getTime().toUnix
     username = "[unknown]"

  T(message: message, timestamp: timestamp, topic: topic, username: username)

proc addWalletAccount*(name: string,
  password: string) {.task(kind=no_rts, stoppable=false).} =

  let timestamp = getTime().toUnix

  if statusState != StatusState.loggedin:
    let
      eventNotLoggedIn = AddWalletAccountEvent(error: "Not logged in, " &
        "cannot create a new wallet account.",
        timestamp: timestamp)
      eventNotLoggedInEnc = eventNotLoggedIn.encode
      task = taskArg.taskName

    trace "task sent event to host", event=eventNotLoggedInEnc, task
    asyncSpawn chanSendToHost.send(eventNotLoggedInEnc.safe)
    return

  let
    dir = status.dataDir / "keystore"
    # Hardcode bip39Passphrase to empty string. Can be enabled in UI later if
    # needed.
    walletAccountResult = status.addWalletAccount(name, password, dir) 

  if walletAccountResult.isErr:
    let
      event = AddWalletAccountEvent(error: "Error creating wallet account, " &
        "error: " & walletAccountResult.error, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    walletAccount = walletAccountResult.get
    walletName = walletAccount.name.get("")
    event = AddWalletAccountEvent(name: walletName,
      address: walletAccount.address, timestamp: timestamp)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc addWalletPrivateKey*(name: string, privateKey: string, password: string)
  {.task(kind=no_rts, stoppable=false).} =

  let timestamp = getTime().toUnix

  if statusState != StatusState.loggedin:
    let
      eventNotLoggedIn = AddWalletAccountEvent(error: "Not logged in, " &
        "cannot add a new wallet account.",
        timestamp: timestamp)
      eventNotLoggedInEnc = eventNotLoggedIn.encode
      task = taskArg.taskName

    trace "task sent event to host", event=eventNotLoggedInEnc, task
    asyncSpawn chanSendToHost.send(eventNotLoggedInEnc.safe)
    return

  let
    dir = status.dataDir / "keystore"
    walletAccountResult = status.addWalletPrivateKey(privateKey, name, password,
      dir) 

  if walletAccountResult.isErr:
    let
      event = AddWalletAccountEvent(error: "Error adding wallet account, " &
        "error: " & walletAccountResult.error, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    walletAccount = walletAccountResult.get
    walletName = walletAccount.name.get("")
    event = AddWalletAccountEvent(name: walletName,
      address: walletAccount.address, timestamp: timestamp)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc addWalletSeed*(name: string, mnemonic: string, password: string,
  bip39Passphrase: string) {.task(kind=no_rts, stoppable=false).} =

  let timestamp = getTime().toUnix

  if statusState != StatusState.loggedin:
    let
      eventNotLoggedIn = AddWalletAccountEvent(error: "Not logged in, " &
        "cannot add a new wallet account.",
        timestamp: timestamp)
      eventNotLoggedInEnc = eventNotLoggedIn.encode
      task = taskArg.taskName

    trace "task sent event to host", event=eventNotLoggedInEnc, task
    asyncSpawn chanSendToHost.send(eventNotLoggedInEnc.safe)
    return

  let
    dir = status.dataDir / "keystore"
    walletAccountResult = status.addWalletSeed(Mnemonic mnemonic, name,
      password, dir, bip39Passphrase) 

  if walletAccountResult.isErr:
    let
      event = AddWalletAccountEvent(error: "Error adding wallet account, " &
        "error: " & walletAccountResult.error, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    walletAccount = walletAccountResult.get
    walletName = walletAccount.name.get("")
    event = AddWalletAccountEvent(name: walletName,
      address: walletAccount.address, timestamp: timestamp)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc createAccount*(password: string) {.task(kind=no_rts, stoppable=false).} =
  let timestamp = getTime().toUnix

  if statusState != StatusState.loggedout:
    let
      eventNotLoggedOut = AddWalletAccountEvent(error: "You must be logged " &
        "out to create a new account.",
        timestamp: timestamp)
      eventNotLoggedOutEnc = eventNotLoggedOut.encode
      task = taskArg.taskName

    trace "task sent event to host", event=eventNotLoggedOutEnc, task
    asyncSpawn chanSendToHost.send(eventNotLoggedOutEnc.safe)
    return

  let
    dir = status.dataDir / "keystore"
    # Hardcode bip39Passphrase to empty string. Can be enabled in UI later if
    # needed.
    publicAccountResult = status.createAccount(12, "", password, dir)

  if publicAccountResult.isErr:
    let
      event = CreateAccountEvent(error: "Error creating account, error: " &
        publicAccountResult.error, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    account = publicAccountResult.get
    event = CreateAccountEvent(account: account, timestamp: timestamp)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc importMnemonic*(mnemonic: string, bip39Passphrase: string,
  password: string) {.task(kind=no_rts, stoppable=false).} =

  let
    timestamp = getTime().toUnix
    dir = status.dataDir / "keystore"
    importedResult = status.importMnemonic(Mnemonic mnemonic, bip39Passphrase,
      password, dir)

  if importedResult.isErr:
    let
      event = ImportMnemonicEvent(error: "Error importing mnemonic: " &
        importedResult.error, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    account = importedResult.get
    event = ImportMnemonicEvent(account: account, timestamp: timestamp)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc joinTopic*(topic: string) {.task(kind=no_rts, stoppable=false).} =
  if not contentTopics.contains(topic):
    contentTopics.incl(topic)
    trace "joined topic", contentTopic=topic
  else:
    trace "topic already joined", contentTopic=topic

  let
    event = JoinTopicEvent(timestamp: getTime().toUnix(), topic: topic)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc leaveTopic*(topic: string) {.task(kind=no_rts, stoppable=false).} =
  if contentTopics.contains(topic):
    contentTopics.excl(topic)
    trace "left topic", contentTopic=topic
  else:
    trace "topic not joined, no need to leave", contentTopic=topic

  let
    event = LeaveTopicEvent(timestamp: getTime().toUnix(), topic: topic)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc listAccounts*() {.task(kind=no_rts, stoppable=false).} =
  let
    accounts = status.getPublicAccounts()
    event = ListAccountsEvent(accounts: accounts, timestamp: getTime().toUnix)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc listWalletAccounts*() {.task(kind=no_rts, stoppable=false).} =
  let accounts = status.getWalletAccounts()
  if accounts.isErr:
    let
      event = ListWalletAccountsEvent(error: accounts.error)
      eventEnc = event.encode
      task = taskArg.taskName

    trace "task sent errored event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    event = ListWalletAccountsEvent(accounts: accounts.get,
      timestamp: getTime().toUnix)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc login*(account: int,
  password: string) {.task(kind=no_rts, stoppable=false).} =

  let task = taskArg.taskName

  if statusState != StatusState.loggedout: return
  statusState = StatusState.loggingin

  let allAccounts = status.getPublicAccounts()

  var
    event: LoginEvent
    eventEnc: string
    numberedAccount: PublicAccount
    keyUid: string

  if account < 1 or account > allAccounts.len:
    statusState = StatusState.loggedout

    event = LoginEvent(error: "bad account number", loggedin: false)
    eventEnc = event.encode

  else:
    numberedAccount = allAccounts[account - 1]
    keyUid = numberedAccount.keyUid

    try:
      let loginResult = status.login(keyUid, password)
      if loginResult.isErr:
        statusState = StatusState.loggedout
        event = LoginEvent(error: loginResult.error, loggedin: false)
        eventEnc = event.encode

        trace "task sent event to host", event=eventEnc, task
        asyncSpawn chanSendToHost.send(eventEnc.safe)
        return

      statusState = StatusState.loggedin

      event = LoginEvent(account: loginResult.get, error: "",
        loggedin: true)
      eventEnc = event.encode

    except SqliteError as e:
      error "task encountered a database error", error=e.msg, task

      statusState = StatusState.loggedout

      event = LoginEvent(
        error: "login failed with database error, maybe wrong password?",
        loggedin: false)

      eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc logout*() {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  if statusState != StatusState.loggedin: return
  statusState = StatusState.loggingout

  var
    event: LogoutEvent
    eventEnc: string

  try:
    let logoutResult = status.logout()
    if logoutResult.isErr:
      statusState = StatusState.loggedin
      event = LogoutEvent(error: logoutResult.error, loggedin: true)
      eventEnc = event.encode

      trace "task sent event to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)
      return

    statusState = StatusState.loggedout

    event = LogoutEvent(error: "", loggedin: false)
    eventEnc = event.encode

  except SqliteError as e:
    error "task encountered a database error", error=e.msg, task

    statusState = StatusState.loggedin

    event = LogoutEvent(error: "logout failed with database error.",
      loggedin: true)

    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc startWakuChat2*(username: string) {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  if wakuState != WakuState.stopped: return
  wakuState = WakuState.starting

  nick = username

  # invoke `setupNat` here instead of `statusContext` to decrease startup time
  # of `TaskRunner` instance; doing so here also avoids e.g. possibly
  # triggering an OS dialog re: permitting network activity until the time a
  # waku node initially connects to the network
  if not natIsSetup:
    (extIp, extTcpPort, extUdpPort) = setupNat(conf.nat, clientId,
      Port(uint16(conf.tcpPort) + conf.portsShift),
      Port(uint16(conf.udpPort) + conf.portsShift))

    natIsSetup = true

  # generate `nodekey` here instead of `statusContext` to decrease startup
  # time of `TaskRunner` instance and therefore time to first paint of TUI
  if not nodekeyGenerated:
    if $conf.nodekey == "":
      nodekey = waku_chat2.crypto.PrivateKey.random(Secp256k1,
        waku_chat2.keys.newRng()[]).tryGet()
    else:
      nodekey = waku_chat2.crypto.PrivateKey(scheme: Secp256k1,
        skkey: SkPrivateKey.init(
          waku_chat2.utils.fromHex($conf.nodekey)).tryGet())

    nodekeyGenerated = true

  wakuNode = WakuNode.init(nodekey, ValidIpAddress.init($conf.listenAddress),
    Port(uint16(conf.tcpPort) + conf.portsShift), extIp, extTcpPort)

  await wakuNode.start()

  wakuNode.mountRelay(conf.topics.split(" "), rlnRelayEnabled = conf.rlnRelay,
    relayMessages = conf.relay)

  wakuNode.mountLibp2pPing()

  let
    fleet = conf.fleet
    staticnodes = conf.staticnodes

  if staticnodes.len > 0:
    info "connecting to static peers", nodes=staticnodes
    await wakuNode.connectToNodes(staticnodes)

  elif fleet != WakuFleet.none:
    info "static peers not configured, choosing one at random", fleet
    let node = await selectRandomNode($fleet)

    info "connecting to peer", node
    await wakuNode.connectToNodes(@[node])

  connected = true

  if conf.swap: wakuNode.mountSwap()

  if (conf.storenode != "") or (conf.store == true):
    wakuNode.mountStore(persistMessages = conf.persistMessages)

    var storenode: Option[string]

    if conf.storenode != "":
      storenode = some(conf.storenode)

    elif conf.fleet != WakuFleet.none:
      info "store nodes not configured, choosing one at random", fleet
      storenode = some(await selectRandomNode($fleet))

    if storenode.isSome():
      info "connecting to storenode", storenode
      wakuNode.wakuStore.setPeer(parsePeerInfo(storenode.get()))

      proc handler(response: HistoryResponse) {.gcsafe.} =
        let
          wakuMessages = response.messages
          count = wakuMessages.len

        trace "handling historical messages", count

        for message in wakuMessages:
          let
            event = UserMessageEvent.new(message)
            eventEnc = event.encode

          trace "task sent event to host", event=eventEnc, task
          asyncSpawn chanSendToHost.send(eventEnc.safe)

      let contentFilters = collect(newSeq):
        for contentTopic in contentTopics:
          HistoryContentFilter(contentTopic: contentTopic)

      await wakuNode.query(HistoryQuery(contentFilters: contentFilters),
        handler)

  if conf.lightpushnode != "":
    mountLightPush(wakuNode)
    wakuNode.wakuLightPush.setPeer(parsePeerInfo(conf.lightpushnode))

  if conf.filternode != "":
    wakuNode.mountFilter()
    wakuNode.wakuFilter.setPeer(parsePeerInfo(conf.filternode))

    proc handler(message: WakuMessage) {.gcsafe.} =
      trace "handling filtered message", contentTopic=message.contentTopic

      let
        event = UserMessageEvent.new(message)
        eventEnc = event.encode

      trace "task sent event to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)

    let contentFilters = collect(newSeq):
      for contentTopic in contentTopics:
        ContentFilter(contentTopic: contentTopic)

    await wakuNode.subscribe(FilterRequest(contentFilters: contentFilters,
      pubSubTopic: DefaultTopic, subscribe: true), handler)

  if conf.relay:
    proc handler(topic: waku_chat2.Topic, data: seq[byte]) {.async, gcsafe.} =
      trace "handling relayed message", topic

      let decoded = WakuMessage.init(data)

      if decoded.isOk():
        let message = decoded.get()
        trace "decoded WakuMessage", message

        let contentTopic = message.contentTopic

        if not (contentTopic in contentTopics):
          trace "ignored message for unjoined topic", contentTopic,
            joined=contentTopics

        else:
          let
            event = UserMessageEvent.new(message)
            eventEnc = event.encode

          trace "task sent event to host", event=eventEnc, task
          asyncSpawn chanSendToHost.send(eventEnc.safe)

      else:
        let error = decoded.error
        error "received invalid WakuMessage", error

    wakuNode.subscribe(DefaultTopic, handler)

    subscribed = true

  if conf.keepAlive: wakuNode.startKeepalive()

  wakuState = WakuState.started

  let
    event = NetworkStatusEvent(online: true)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc stopWakuChat2*() {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  if wakuState != WakuState.started: return
  wakuState = WakuState.stopping

  if not wakuNode.wakuFilter.isNil():
    let contentFilters = collect(newSeq):
      for contentTopic in contentTopics:
        ContentFilter(contentTopic: contentTopic)

    await wakuNode.unsubscribe(FilterRequest(contentFilters: contentFilters,
      pubSubTopic: DefaultTopic, subscribe: false))

  wakuNode.unsubscribeAll(DefaultTopic)

  await wakuNode.stop()
  resetContext()

  let
    event = NetworkStatusEvent(online: false)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc lightpushHandler(response: PushResponse) {.gcsafe.} =
  trace "received lightpush response", response

proc publishWakuChat2*(message: string) {.task(kind=no_rts, stoppable=false).} =
  if wakuState != WakuState.started or not connected: return

  let chat2pb = Chat2Message.init(nick, message).encode()

  if contentTopics.len < 1:
    trace "message not published, no topics joined", joined=contentTopics,
      message, nick

  else:
    trace "published message to all joined topics", joined=contentTopics,
      message, nick

    for contentTopic in contentTopics:
      let wakuMessage = WakuMessage(payload: chat2pb.buffer,
        contentTopic: contentTopic, version: 0)

      if not wakuNode.wakuLightPush.isNil():
        asyncSpawn wakuNode.lightpush(DefaultTopic, wakuMessage,
          lightpushHandler)
      else:
        asyncSpawn wakuNode.publish(DefaultTopic, wakuMessage, conf.rlnRelay)
