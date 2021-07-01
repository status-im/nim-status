import # std libs
  std/[os, strutils]

import # chat libs
  ./events, ./waku_chat2

import # nim-status libs
  ../../nim_status/[account, accounts, alias, client, identicon, multiaccount]

export events

logScope:
  topics = "chat client"

type
  StatusArg* = ref object of ContextArg
    chatConfig*: ChatConfig

var
  conf {.threadvar.}: ChatConfig
  connected {.threadvar.}: bool
  contentTopic {.threadvar.}: ContentTopic
  contextArg {.threadvar.}: StatusArg
  nick {.threadvar.}: string
  subscribed {.threadvar.}: bool
  status {.threadvar.}: StatusObject
  wakuNode {.threadvar.}: WakuNode
  wakuState {.threadvar.}: WakuState

when PayloadV1:
  var
    symKey {.threadvar.}: SymKey
    symKeyGenerated {.threadvar.}: bool

proc resetContext() {.gcsafe, nimcall.} =
  connected = false
  nick = ""
  subscribed = false
  wakuNode = nil
  wakuState = WakuState.stopped

proc statusContext*(arg: ContextArg) {.async, gcsafe, nimcall.} =
  # set threadvar values that are never reset, i.e. persist across login/logout
  contextArg = cast[StatusArg](arg)
  conf = contextArg.chatConfig
  contentTopic = conf.contentTopic
  status = StatusObject.new(conf.dataDir)

  # threadvar `symKeyGenerated` is a special case because it depends on
  # compile-time `PayloadV1` value and because the value of its counterpart
  # `symKey` only needs to be set once, i.e. it also persists across
  # login/logout; but note that `symKey` itself is set for the first time in
  # task `startWakuChat2` as an optimization for TUI startup time
  when PayloadV1: symKeyGenerated = false

  # re/set threadvars that don't persist across login/logout
  resetContext()

proc new(T: type UserMessage, wakuMessage: WakuMessage): T =
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
     timestamp = epochTime().int64
     username = "[unknown]"

  T(message: message, timestamp: timestamp, username: username)

proc generateMultiAccount*(password: string) {.task(kind=no_rts, stoppable=false).} =
  let
    paths = @[PATH_WALLET_ROOT, PATH_EIP_1581, PATH_WHISPER, PATH_DEFAULT_WALLET]
    multiAccounts = status.multiAccountGenerateAndDeriveAddresses(12, 1, password,
      paths)
    multiAccount = multiAccounts[0]
    dir = status.dataDir / "keystore"

  dir.createDir()
  status.multiAccountStoreDerivedAccounts(multiAccount, password, dir)

  let
    timestamp = epochTime().int64
    whisperAcct = multiAccount.accounts[2]
    account = accounts.Account(
      name: whisperAcct.publicKey.generateAlias(),
      identicon: whisperAcct.publicKey.identicon(),
      keycardPairing: "",
      keyUid: whisperAcct.keyUid # whisper key-uid
    )

  status.saveAccount(account)
  # TODO: status.login(account.keyUid, password)

  let
    event = CreateAccountResult(account: account, timestamp: timestamp)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc listAccounts*() {.task(kind=no_rts, stoppable=false).} =
  let
    accounts = status.getAccounts()
    event = ListAccountsResult(accounts: accounts, timestamp: epochTime().int64)
    eventEnc = event.encode
    task = taskArg.taskName

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc startWakuChat2*(username: string) {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  if wakuState != WakuState.stopped: return
  wakuState = WakuState.starting

  nick = username

  when PayloadV1:
    # generate `symKey` here instead of `statusContext` to decrease startup
    # time of `TaskRunner` instance and therefore time to first paint of TUI
    if not symKeyGenerated:
      symKey = generateSymKey(contentTopic)
      symKeyGenerated = true

  let (extIp, extTcpPort, extUdpPort) = setupNat(conf.nat, clientId,
    Port(uint16(conf.tcpPort) + conf.portsShift),
    Port(uint16(conf.udpPort) + conf.portsShift))

  var nodekey: waku_chat2.crypto.PrivateKey

  if $conf.nodekey == "":
    nodekey = waku_chat2.crypto.PrivateKey.random(Secp256k1,
      waku_chat2.keys.newRng()[]).tryGet()
  else:
    nodekey = waku_chat2.crypto.PrivateKey(scheme: Secp256k1,
      skkey: SkPrivateKey.init(
        waku_chat2.utils.fromHex($conf.nodekey)).tryGet())

  wakuNode = WakuNode.init(nodekey, ValidIpAddress.init($conf.listenAddress),
    Port(uint16(conf.tcpPort) + conf.portsShift), extIp, extTcpPort)

  await wakuNode.start()

  wakuNode.mountRelay(conf.topics.split(" "),
    rlnRelayEnabled = conf.rlnRelay,
    relayMessages = conf.relay)

  wakuNode.mountLibp2pPing()

  let
    fleet = conf.fleet
    staticnodes = conf.staticnodes

  if staticnodes.len > 0:
    info "Connecting to static peers", nodes=staticnodes
    await wakuNode.connectToNodes(staticnodes)

  elif fleet != WakuFleet.none:
    info "Static peers not configured, choosing one at random", fleet
    let node = await selectRandomNode($fleet)

    info "Connecting to peer", node
    await wakuNode.connectToNodes(@[node])

  connected = true

  if conf.swap: wakuNode.mountSwap()

  if conf.relay:
    proc handler(topic: waku_chat2.Topic, data: seq[byte]) {.async, gcsafe.} =
      let decoded = WakuMessage.init(data)

      if decoded.isOk():
        let message = decoded.get()
        trace "decoded WakuMessage", message

        let
          event = UserMessage.new(message)
          eventEnc = event.encode

        trace "task sent event to host", event=eventEnc, task
        asyncSpawn chanSendToHost.send(eventEnc.safe)

      else:
        let error = decoded.error
        error "received invalid WakuMessage", error

    let topic = cast[waku_chat2.Topic](waku_chat2.DefaultTopic)
    wakuNode.subscribe(topic, handler)

    subscribed = true

  if conf.keepAlive: wakuNode.startKeepalive()

  wakuState = WakuState.started

  let
    event = NetworkStatus(online: true)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc stopWakuChat2*() {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  if wakuState != WakuState.started: return
  wakuState = WakuState.stopping

  await wakuNode.stop()
  resetContext()

  let
    event = NetworkStatus(online: false)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

proc publishWakuChat2*(message: string) {.task(kind=no_rts, stoppable=false).} =
  if wakuState != WakuState.started or not connected: return

  let
    chat2pb = Chat2Message.init(nick, message).encode()
    wakuMessage = WakuMessage(payload: chat2pb.buffer,
      contentTopic: contentTopic, version: 0)

  asyncSpawn wakuNode.publish(waku_chat2.DefaultTopic, wakuMessage)
