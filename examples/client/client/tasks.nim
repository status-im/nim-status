import # std libs
  std/os

from std/sugar import `=>`, collect

import # vendor libs
  stew/byteutils

import # status lib
  status/api/[tokens, wallet],
  status/private/protocol

import # client modules
  ./events, ./waku_chat2

export events

logScope:
  topics = "client"

type
  StatusArg* = ref object of ContextArg
    clientConfig*: ClientConfig

  StatusState* = enum loggedout, loggingin, loggedin, loggingout

  WakuState* = enum stopped, starting, started, stopping

const
  DefaultTopic = waku_chat2.DefaultTopic
  toyChat2App = "toy-chat/2"
  waku1App = "waku/1"

var
  chatAccount {.threadvar.}: Account
  conf {.threadvar.}: ClientConfig
  connected {.threadvar.}: bool
  contentTopics {.threadvar.}: OrderedSet[ContentTopic]
  contextArg {.threadvar.}: StatusArg
  extIp {.threadvar.}: Option[ValidIpAddress]
  extTcpPort {.threadvar.}: Option[Port]
  extUdpPort {.threadvar.}: Option[Port]
  identity {.threadvar.}: seq[byte]
  natIsSetup {.threadvar.}: bool
  nick {.threadvar.}: string
  nodekey {.threadvar.}: waku_chat2.crypto.PrivateKey
  nodekeyGenerated {.threadvar.}: bool
  publicAccount {.threadvar.}: PublicAccount
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
  # waku dis/connect
  contextArg = cast[StatusArg](arg)
  conf = contextArg.clientConfig

  let contentTopicsStr = conf.contentTopics.strip()
  if contentTopicsStr != "":
    contentTopics = contentTopicsStr.split(" ").map(handleTopic)
      .filter(t => t != "").toOrderedSet()

  # threadvar `natIsSetup` is a special case because the values of its
  # counterparts `ext[Ip,TcpPort,UdpPort]` only need to be set once, i.e. they
  # also persists across waku dis/connect; but note that
  # `ext[Ip,TcpPort,UdpPort]` themselves are set for the first time in task
  # `startWakuChat` as a program startup optimization
  natIsSetup = false

  # threadvar `nodekeyGenerated` is a special case like `natIsSetup`, see
  # previous comment
  nodekeyGenerated = false

  status = StatusObject.new(conf.dataDir)
  # threadvar `statusState` is currently out of scope re: "resetting the
  # context"; the relevant code/logic can be reconsidered in the future, was
  # originally implemented in context of `startWakuChat` and `stopWakuChat`
  statusState = StatusState.loggedout

  # re/set threadvars that don't persist across waku dis/connect
  resetContext()

proc new(T: type UserMessageEvent, wakuMessage: WakuMessage): T =
  let
    topic = wakuMessage.contentTopic
    topicSplit = topic.split('/')

  var
    fallback = true
    message: string
    timestamp: int64
    username: string

  # all content topics populated into threadvar `contentTopics` will be
  # compliant with recommendations in waku v2 specs
  # (https://rfc.vac.dev/spec/23/#content-topics) and when split on '/' will
  # have length 5; since our relay handler checks that
  # `wakuMessage.contentTopic` is in `contentTopics` before invoking this
  # constructor, and for now assuming that history and filter nodes would never
  # send us messages for content topics other than those we requested, we can
  # safely access `topicSplit` indices 0..4

  # we know how to properly handle messages for only some content topics:
  # * `/toy-chat/2/{topic-name}/proto`
  # * `/waku/1/{topic-name}/proto` -- should end with `/rlp` for real decoding
  case fmt"{topicSplit[1]}/{topicSplit[2]}":
    of toyChat2App:
      if topicSplit[4] == "proto":
        let protoResult = Chat2Message.init(wakuMessage.payload)
        if protoResult.isOk:
          let chat2Message = protoResult[]
          message = string.fromBytes(chat2Message.payload)
          timestamp = chat2Message.timestamp
          username = chat2Message.nick

          fallback = false

        else:
          error "error decoding toy-chat/2 message", contentTopic=topic,
            error=protoResult, payload=string.fromBytes(wakuMessage.payload)

    of waku1App:
      if topicSplit[4] == "proto": # should be `rlp` for real decoding
        try:
          let
            # will first need to RLP decode payload for real decoding
            protoMsg = protocol.ProtocolMessage.decode(
              wakuMessage.payload)
            appMetaMsg = protocol.ApplicationMetadataMessage.decode(
              protoMsg.public_message)
            chatMsg = protocol.ChatMessage.decode(appMetaMsg.payload)

          # "placeholder handling" of decoded protobuffer that will be iterated
          # along with changes to what data we signal from the client to the
          # TUI and how we display/notify re: that data in the TUI
          message = chatMsg.text
          timestamp = chatMsg.timestamp.int64
          username = generateAlias(
            "0x" & byteutils.toHex(protoMsg.bundles[0].identity))

          fallback = false

        except CatchableError as e:
          error "error decoding waku/1 message", contentTopic=topic,
            error=e.msg, payload=string.fromBytes(wakuMessage.payload)

  if fallback:
    message = string.fromBytes(wakuMessage.payload)
    timestamp = getTime().toUnix
    username = "[unknown]"

    warn "used fallback decoding strategy for unsupported contentTopic",
      contentTopic=topic

  T(message: message, timestamp: timestamp, topic: topic, username: username)

proc addWalletAccount*(name: string,
  password: string) {.task(kind=no_rts, stoppable=false).} =

  let timestamp = getTime().toUnix

  if statusState != StatusState.loggedin:
    let
      eventNotLoggedIn = AddWalletAccountEvent(error: "Not logged in, " &
        "cannot create a new wallet account.", timestamp: timestamp)
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

proc addWalletWatchOnly*(address: string,
  name: string) {.task(kind=no_rts, stoppable=false).} =

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

  var addressParsed: Address
  try:
    addressParsed = address.parseAddress
  except CatchableError as e:
    let
      event = AddWalletAccountEvent(error: "Error adding watch-only wallet " &
        "account: " & e.msg, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let walletAccountResult = status.addWalletWatchOnly(addressParsed, name)

  if walletAccountResult.isErr:
    let
      event = AddWalletAccountEvent(error: "Error adding watch-only wallet " &
        "account: " & walletAccountResult.error, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    walletAccount = walletAccountResult.get
    walletName = if walletAccount.name.isNone: "" else: walletAccount.name.get
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

proc deleteWalletAccount*(index: int, password: string) {.task(kind=no_rts,
  stoppable=false).} =

  let
    task = taskArg.taskName
    timestamp = getTime().toUnix

  if statusState != StatusState.loggedin:
    let
      eventNotLoggedIn = DeleteWalletAccountEvent(error: "Not logged in, " &
        "cannot delete a wallet account.",
        timestamp: timestamp)
      eventNotLoggedInEnc = eventNotLoggedIn.encode
      task = taskArg.taskName

    trace "task sent event with error to host", event=eventNotLoggedInEnc, task
    asyncSpawn chanSendToHost.send(eventNotLoggedInEnc.safe)
    return

  var
    event: DeleteWalletAccountEvent
    numberedAccount: WalletAccount
    address: Address

  let allAccounts = status.getWalletAccounts()
  if allAccounts.isErr:
    event = DeleteWalletAccountEvent(error: "error getting wallet accounts: " &
      allAccounts.error)

  elif index < 1 or index > allAccounts.get.len:
    event = DeleteWalletAccountEvent(error: "bad account index number")

  else:
    numberedAccount = allAccounts.get[index - 1]
    address = numberedAccount.address

    try:
      let
        dir = status.dataDir / "keystore"
        walletResult = status.deleteWalletAccount(address, password,dir)

      if walletResult.isOk:
        let wallet = walletResult.get
        event = DeleteWalletAccountEvent(name: wallet.name.get("(unnamed)"),
          address: $wallet.address, timestamp: timestamp)
      else:
        event = DeleteWalletAccountEvent(error: "Error deleting wallet " &
          "account: " & walletResult.error, timestamp: timestamp)

    except Exception as e:
      event = DeleteWalletAccountEvent(error: "Error deleting wallet " &
        "account, error: " & e.msg, timestamp: timestamp)

  let eventEnc = event.encode
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
    event = JoinTopicEvent(timestamp: getTime().toUnix, topic: topic)
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
    event = LeaveTopicEvent(timestamp: getTime().toUnix, topic: topic)
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

proc login*(account: int, password: string) {.
  task(kind=no_rts, stoppable=false).} =

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

      chatAccount = status.getChatAccount()
      identity = @(chatAccount.publicKey.get.toRaw)
      publicAccount = loginResult.get

      statusState = StatusState.loggedin

      event = LoginEvent(account: publicAccount, error: "", loggedin: true)
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

    chatAccount = Account()
    identity.setLen(0)
    publicAccount = PublicAccount()
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

proc startWakuChat*(username: string) {.task(kind=no_rts, stoppable=false).} =
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

  wakuNode = WakuNode.new(nodekey, ValidIpAddress.init($conf.listenAddress),
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

    proc handler(message: WakuMessage) {.gcsafe, raises: [Defect].} =
      trace "handling filtered message", contentTopic=message.contentTopic

      try:
        let
          event = UserMessageEvent.new(message)
          eventEnc = event.encode

        trace "task sent event to host", event=eventEnc, task
        asyncSpawn chanSendToHost.send(eventEnc.safe)

      except ValueError as e:
        error "error handlinng filtered message", error=e.msg,
          payload=message.payload
      except IOError as e:
        error "error encoding filtered message", error=e.msg

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

proc stopWakuChat*() {.task(kind=no_rts, stoppable=false).} =
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

proc publishWakuChat*(message: string) {.task(kind=no_rts, stoppable=false).} =
  if wakuState != WakuState.started or not connected: return

  if contentTopics.len < 1:
    trace "message not published, no topics joined", joined=contentTopics,
      message, username=nick

  else:
    # all content topics populated into threadvar `contentTopics` will be
    # compliant with recommendations in waku v2 specs
    # (https://rfc.vac.dev/spec/23/#content-topics) and when split on '/' will
    # have length 5; so we can safely access `topicSplit` indices 0..4

    # we know how to properly handle messages for only some content topics:
    # * `/toy-chat/2/{topic-name}/proto`
    # * `/waku/1/{topic-name}/proto` -- should end with `/rlp` for real encoding
    for topic in contentTopics:
      var
        payload: seq[byte]
        unsupported = false

      let topicSplit = topic.split('/')

      case fmt"{topicSplit[1]}/{topicSplit[2]}":
        of toyChat2App:
          if topicSplit[4] == "proto":
            let chat2pb = Chat2Message.init(nick, message).encode()
            payload = chat2pb.buffer

        of waku1App:
          if topicSplit[4] == "proto": # should be `rlp` for real encoding
            let
              chatMsg = protocol.ChatMessage(
                timestamp: getTime().toUnix.uint64, text: message,
                message_type: protocol.PUBLIC_GROUP,
                content_type: protocol.TEXT_PLAIN)

              metaMsg = protocol.ApplicationMetadataMessage(
                payload: chatMsg.encode,
                `type`: protocol.application_metadata_message.CHAT_MESSAGE)

              protoMsg = protocol.ProtocolMessage(
                bundles: @[protocol.Bundle(identity: identity)],
                public_message: metaMsg.encode)

            payload = protoMsg.encode
            # will finally need to RLP encode payload for real encoding

        else:
          unsupported = true

      if unsupported:
        error "cannot publish message for unsupported contentTopic",
          contentTopic=topic, message

      else:
        let wakuMessage = WakuMessage(payload: payload, contentTopic: topic,
                                      version: 0)

        if not wakuNode.wakuLightPush.isNil():
          asyncSpawn wakuNode.lightpush(DefaultTopic, wakuMessage,
            lightpushHandler)

        else:
          asyncSpawn wakuNode.publish(DefaultTopic, wakuMessage, conf.rlnRelay)

proc getCustomTokens*() {.task(kind=no_rts, stoppable=false).} =
  let timestamp = getTime().toUnix

  if statusState != StatusState.loggedin:
    let
      eventNotLoggedIn = GetCustomTokensEvent(error: "Not logged in, " &
        "cannot get custom tokens.",
        timestamp: timestamp)
      eventNotLoggedInEnc = eventNotLoggedIn.encode
      task = taskArg.taskName

    trace "task sent event to host", event=eventNotLoggedInEnc, task
    asyncSpawn chanSendToHost.send(eventNotLoggedInEnc.safe)
    return


  let tokens = status.getCustomTokens()
  if tokens.isErr:
    let
      event = GetCustomTokensEvent(error: tokens.error)
      eventEnc = event.encode
      task = taskArg.taskName

    trace "task sent errored event to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
    return

  let
    event = GetCustomTokensEvent(tokens: tokens.get,
      timestamp: getTime().toUnix)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc addCustomToken*(address: Address, name: string, symbol: string, color: string, decimals: uint) {.task(kind=no_rts, stoppable=false).} =
  let timestamp = getTime().toUnix

  if statusState != StatusState.loggedin:
    let
      eventNotLoggedIn = AddCustomTokenEvent(error: "Not logged in, " &
        "cannot add a new custom token.",
        timestamp: timestamp)
      eventNotLoggedInEnc = eventNotLoggedIn.encode
      task = taskArg.taskName

    trace "task sent event to host", event=eventNotLoggedInEnc, task
    asyncSpawn chanSendToHost.send(eventNotLoggedInEnc.safe)
    return

  try:
    let addResult = status.addCustomToken(address, name, symbol, color, decimals)

    if addResult.isErr:
      let
        event = AddCustomTokenEvent(error: addResult.error,
          timestamp: timestamp)
        eventEnc = event.encode
        task = taskArg.taskName

      trace "task sent errored event to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)
      return
    else:
      let
        token = addResult.get
        event = AddCustomTokenEvent(address: $token.address,
          name: token.name, symbol: token.symbol, color: token.color,
          decimals: token.decimals, timestamp: timestamp)
        eventEnc = event.encode
        task = taskArg.taskName

      trace "task sent event to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)
  except CatchableError as e:
    let
      event = AddCustomTokenEvent(error: "Error adding a custom token, " &
        "error: " & e.msg, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)


proc deleteCustomToken*(index: int) {.task(kind=no_rts, stoppable=false).} =
  let timestamp = getTime().toUnix

  if statusState != StatusState.loggedin:
    let
      eventNotLoggedIn = DeleteCustomTokenEvent(error: "Not logged in, " &
        "cannot delete a custom token.",
        timestamp: timestamp)
      eventNotLoggedInEnc = eventNotLoggedIn.encode
      task = taskArg.taskName

    trace "task sent event to host", event=eventNotLoggedInEnc, task
    asyncSpawn chanSendToHost.send(eventNotLoggedInEnc.safe)
    return

  try:
    let allTokens = status.getCustomTokens().get
    if index > allTokens.len:
      let
        event = DeleteCustomTokenEvent(error: "bad token number")
        eventEnc = event.encode
        task = taskArg.taskName
      trace "task sent event with error to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)
      return

    let
      address = allTokens[index - 1].address
      deleteResult = status.deleteCustomToken(address)

    if deleteResult.isErr:
      let
        event = DeleteCustomTokenEvent(error: deleteResult.error,
          timestamp: timestamp)
        eventEnc = event.encode
        task = taskArg.taskName

      trace "task sent errored event to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)
      return
    else:
      let
        event = DeleteCustomTokenEvent(address: $address, timestamp: timestamp)
        eventEnc = event.encode
        task = taskArg.taskName

      trace "task sent event to host", event=eventEnc, task
      asyncSpawn chanSendToHost.send(eventEnc.safe)
  except CatchableError as e:
    let
      event = DeleteCustomTokenEvent(error: "Error deleting custom token, " &
        "error: " & e.msg, timestamp: timestamp)
      eventEnc = event.encode
      task = taskArg.taskName
    trace "task sent event with error to host", event=eventEnc, task
    asyncSpawn chanSendToHost.send(eventEnc.safe)
