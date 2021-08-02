{.push raises: [Defect].}

import # std libs
  std/[options, sequtils, sets, strutils, sugar]

from times import getTime, toUnix

import # vendor libs
  chronicles, chronos, eth/keys as eth_keys, nimcrypto/pbkdf2, stew/byteutils

# status libs
import ../private/waku except ContentTopic
import
  ../private/[alias, protocol, util],
  ./accounts, ./common

export common except setLoginState, setNetworkState
export waku except ContentTopic

logScope:
  topics = "status_api"

type
  Nodekey* = waku.crypto.PrivateKey

  WakuError* = enum
    InvalidKey            = "waku: invalid private key"
    MustBeLoggedIn        = "waku: operation not permitted, must be logged in"
    MustBeOffline         = "waku: operation not permitted, must be offline"
    MustBeOnline          = "waku: operation not permitted, must be online"
    NoChatAccount         = "waku: could not retrieve chat account"
    NoChatAccountName     = "waku: could not retrieve name of chat account"
    NoSendUnsuspportedApp = "waku: cannot send message to unsupported " &
                              "content topic"
    SendNotSupportedWaku1 = "waku: sending messages to public chats is not " &
                              "currently supported"

  WakuResult*[T] = Result[T, WakuError]

proc init*(T: type Nodekey): T =
  Nodekey.random(Secp256k1, waku.keys.newRng()[]).expect(
    "random key generation should never fail")

proc fromHex*(T: type Nodekey, key: string): Result[T, WakuError] =
  if not (key.len == 64 or key.len == 66): return err InvalidKey

  var hex: string

  if key[0..1] == "0x":
    hex = key
  else:
    hex = "0x" & key

  if hex.len == 66 and isHexString(hex).get(false):
    let skkey = ?SkPrivateKey.init(
      waku.utils.fromHex(hex[2..^1])).mapErrTo(InvalidKey)

    ok Nodekey(scheme: Secp256k1, skkey: skkey)
  else:
    err InvalidKey

proc handleChat2Message(self: StatusObject, message: WakuMessage,
  contentTopic: ContentTopic, pubSubTopic: waku.Topic) {.async.} =

  let
    chat2MessageResult = Chat2Message.decode(message.payload)
    timestamp = getTime().toUnix

  if chat2MessageResult.isOk:
    let
      chat2Message = chat2MessageResult.get
      event = Chat2MessageEvent(data: chat2Message, timestamp: timestamp,
        topic: contentTopic)

    asyncSpawn self.signalHandler((event: event,
      kind: StatusEventKind.chat2Message))

  else:
    let
      chat2MessageError = chat2MessageResult.error
      event = Chat2MessageErrorEvent(error: chat2MessageError,
        timestamp: timestamp, topic: contentTopic)

    asyncSpawn self.signalHandler((event: event,
      kind: StatusEventKind.chat2MessageError))

proc handleWaku1Message(self: StatusObject, message: WakuMessage,
  contentTopic: ContentTopic, pubSubTopic: waku.Topic) {.async.} =

  # currently we only support public chat messages

  var
    ctx: HMAC[sha256]
    salt: seq[byte] = @[]
    shortName = contentTopic.shortName
    symKey: SymKey

  let timestamp = getTime().toUnix

  if shortName.startsWith('#'): shortName = shortName[1..^1]

  if pbkdf2(ctx, shortName.toBytes(), salt, 65356, symKey) != sizeof(SymKey):
    let
      publicChatMessageError = PublicChatMessageError.BadKey
      event = PublicChatMessageErrorEvent(error: publicChatMessageError,
        timestamp: timestamp, topic: contentTopic)

    asyncSpawn self.signalHandler((event: event,
      kind: StatusEventKind.publicChatMessageError))

  else:
    let decryptedMessageOption = decode(message.payload,
      none[eth_keys.PrivateKey](), some(symKey))

    if decryptedMessageOption.isNone:
      let
        publicChatMessageError = PublicChatMessageError.DecryptFailed
        event = PublicChatMessageErrorEvent(error: publicChatMessageError,
          timestamp: timestamp, topic: contentTopic)

      asyncSpawn self.signalHandler((event: event,
        kind: StatusEventKind.publicChatMessageError))

    else:
      let decryptedMessage = decryptedMessageOption.get

      try:
        let
          protoMessage = protocol.ProtocolMessage.decode(
            decryptedMessage.payload)

          appMetaMessage = protocol.ApplicationMetadataMessage.decode(
            protoMessage.public_message)

          chatMessage = protocol.ChatMessage.decode(
            appMetaMessage.payload)

          pubkeyOption = decryptedMessage.src

        if pubkeyOption.isNone:
          let
            publicChatMessageError = PublicChatMessageError.NoPublicKey
            event = PublicChatMessageErrorEvent(error: publicChatMessageError,
              timestamp: timestamp, topic: contentTopic)

          asyncSpawn self.signalHandler((event: event,
            kind: StatusEventKind.publicChatMessageError))

        else:
          let
            pubkey = pubkeyOption.get
            aliasResult = generateAlias(
              "0x04" & byteutils.toHex(pubkey.toRaw()))

          if aliasResult.isErr:
            let
              publicChatMessageError = PublicChatMessageError.NoAlias
              event = PublicChatMessageErrorEvent(error: publicChatMessageError,
              timestamp: timestamp, topic: contentTopic)

            asyncSpawn self.signalHandler((event: event,
              kind: StatusEventKind.publicChatMessageError))

          else:
            let
              alias = aliasResult.get
              timestamp = chatMessage.timestamp.int64 div 1000.int64
              publicChatMessage = PublicChatMessage(alias: alias,
                message: chatMessage, pubkey: pubkey, timestamp: timestamp)

              event = PublicChatMessageEvent(data: publicChatMessage,
                timestamp: timestamp, topic: contentTopic)

            asyncSpawn self.signalHandler((event: event,
              kind: StatusEventKind.publicChatMessage))

      except ProtobufReadError as e:
        let
          publicChatMessageError = PublicChatMessageError.DecodeFailed
          event = PublicChatMessageErrorEvent(error: publicChatMessageError,
            timestamp: timestamp, topic: contentTopic)

        asyncSpawn self.signalHandler((event: event,
          kind: StatusEventKind.publicChatMessageError))

proc handleAppMessage(self: StatusObject, message: WakuMessage,
  contentTopic: ContentTopic, pubSubTopic: waku.Topic) {.async.} =

  # we know how to handle messages for only some content topics:
  # * `/toy-chat/2/{topic}/proto`
  # * `/waku/1/{topic-digest}/rfc26`

  if contentTopic.isChat2:
    asyncSpawn self.handleChat2Message(message, contentTopic, pubSubTopic)

  elif contentTopic.isWaku1:
    asyncSpawn self.handleWaku1Message(message, contentTopic, pubSubTopic)

  else:
    trace "ignored message for unsupported app", contentTopic, pubSubTopic

proc handleWakuMessage(self: StatusObject, pubSubTopic: waku.Topic,
  message: WakuMessage) {.async.} =

  let contentTopicResult = ContentTopic.init(message.contentTopic)

  if contentTopicResult.isErr:
    error "received WakuMessage with invalid content topic",
      contentTopic=message.contentTopic, pubSubTopic

    return

  var contentTopic = contentTopicResult.get

  # use our util.includes as a workaround for what seems to be a bug in
  # Nim's std/sets.contains
  if self.topics.includes(contentTopic):
    # is there a better way to do it? `[]` proc doesn't exist for OrderedSet
    let h = contentTopic.hash
    for t in self.topics:
      if t.hash == h: contentTopic.shortName = t.shortName

    asyncSpawn self.handleAppMessage(message, contentTopic, pubSubTopic)

  else:
    trace "ignored message for unjoined topic", contentTopic,
      joined=self.topics, pubSubTopic

proc getTopics*(self: StatusObject): seq[ContentTopic] =
  self.topics.toSeq

proc joinTopic*(self: StatusObject, topic: ContentTopic) =
  self.topics.incl(topic)

proc leaveTopic*(self: StatusObject, topic: ContentTopic) =
  self.topics.excl(topic)

proc lightpushHandler(response: PushResponse) {.gcsafe.} =
  trace "received lightpush response", response

proc sendChat2Message(self: StatusObject, message: string, topic: ContentTopic):
  Future[WakuResult[void]] {.async.} =

  var nick: string
  let chatAccountResult = self.getChatAccount()

  if chatAccountResult.isOk:
    let chatAccount = chatAccountResult.get
    if chatAccount.name.isSome:
      nick = chatAccount.name.get
    else:
      return err NoChatAccountName
  else:
    return err NoChatAccount

  let
    chat2protobuf = Chat2Message.init(nick, message).encode()
    payload = chat2protobuf.buffer
    wakuMessage = WakuMessage(payload: payload, contentTopic: $topic,
      version: 0)

  if not self.wakuNode.wakuLightPush.isNil():
    for pTopic in self.wakuPubSubTopics:
      asyncSpawn self.wakuNode.lightpush(pTopic, wakuMessage, lightpushHandler)

  else:
    for pTopic in self.wakuPubSubTopics:
      asyncSpawn self.wakuNode.publish(pTopic, wakuMessage, self.wakuRlnRelay)

  return ok()

proc sendWaku1Message(self: StatusObject, message: string, topic: ContentTopic):
  Future[WakuResult[void]] {.async.} =

  return err SendNotSupportedWaku1

proc sendMessage*(self: StatusObject, message: string, topic: ContentTopic):
  Future[WakuResult[void]] {.async.} =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  if self.networkState != NetworkState.online:
    return err MustBeOnline

  # we know how to send messages for only some content topics:
  # * `/toy-chat/2/{topic}/proto`
  # * `/waku/1/{topic-digest}/rfc26`

  if topic.isChat2:
    return await self.sendChat2Message(message, topic)

  elif topic.isWaku1:
    return await self.sendWaku1Message(message, topic)

  else:
    return err NoSendUnsuspportedApp

proc addFiltersImpl(self: StatusObject, topics: seq[ContentTopic]):
  Future[WakuResult[void]] {.async.} =

  if not self.wakuNode.wakuFilter.isNil():
    let contentFilters = collect(newSeq):
      for topic in topics:
        ContentFilter(contentTopic: $topic)

    for pTopic in self.wakuPubSubTopics:
      await self.wakuNode.subscribe(FilterRequest(
        contentFilters: contentFilters, pubSubTopic: pTopic, subscribe: true),
        self.wakuFilterHandler)

  else:
    warn "cannot subscribe to filter requests when node's filter is nil"

  return ok()

proc addFilters*(self: StatusObject, topics: seq[ContentTopic]):
  Future[WakuResult[void]] {.async.} =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  if self.networkState != NetworkState.online:
    return err MustBeOnline

  return await self.addFiltersImpl(topics)

proc removeFiltersImpl(self: StatusObject, topics: seq[ContentTopic]):
  Future[WakuResult[void]] {.async.} =

  if not self.wakuNode.wakuFilter.isNil():
    let contentFilters = collect(newSeq):
      for topic in topics:
        ContentFilter(contentTopic: $topic)

    for pTopic in self.wakuPubSubTopics:
      await self.wakuNode.unsubscribe(FilterRequest(
        contentFilters: contentFilters, pubSubTopic: pTopic, subscribe: false))

  else:
    warn "cannot unsubscribe from filter requests when node's filter is nil"

  return ok()

proc removeFilters*(self: StatusObject, topics: seq[ContentTopic]):
  Future[WakuResult[void]] {.async.} =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  if self.networkState != NetworkState.online:
    return err MustBeOnline

  return await self.removeFiltersImpl(topics)

proc queryHistory*(self: StatusObject, topics: seq[ContentTopic]):
  Future[WakuResult[void]] {.async.} =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  if self.networkState != NetworkState.online:
    return err MustBeOnline

  let contentFilters = collect(newSeq):
    for topic in topics:
      HistoryContentFilter(contentTopic: $topic)

  await self.wakuNode.query(HistoryQuery(contentFilters: contentFilters),
    self.wakuHistoryHandler)

  return ok()

proc connect*(self: StatusObject, nodekey = Nodekey.init(),
  extIp = none[ValidIpAddress](), extTcpPort = none[Port](),
  extUdpPort = none[Port](), bindIp = ValidIpAddress.init("0.0.0.0"),
  bindTcpPort = Port(60000), bindUdpPort = Port(60000), portsShift = 0.uint16,
  pubSubTopics = @[waku.DefaultTopic], rlnRelay = false, relay = true,
  fleet = WakuFleet.prod, staticnodes: seq[string] = @[], swapProtocol = true,
  filternode = "", lightpushnode = "", store = true, storenode = "",
  keepalive = false):
  Future[WakuResult[void]] {.async.} =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  if self.networkState != NetworkState.offline:
    return err MustBeOffline

  self.setNetworkState(NetworkState.connecting)

  let
    filter = filternode != ""
    lightpush = lightpushnode != ""
    wakuNode = WakuNode.new(nodekey, bindIp,
      Port(bindTcpPort.uint16 + portsShift), extIp, extTcpPort)

  self.wakuFilter = filter
  self.wakuFilternode = filternode
  self.wakuLightpush = lightpush
  self.wakuLightpushnode = lightpushnode
  self.wakuNode = wakuNode
  self.wakuPubSubTopics = pubSubTopics
  self.wakuRlnRelay = rlnRelay
  self.wakuStore = store
  self.wakuStorenode = storenode

  await wakuNode.start()

  wakuNode.mountRelay(pubSubTopics, rlnRelayEnabled = rlnRelay,
    relayMessages = relay)

  wakuNode.mountLibp2pPing()

  if staticnodes.len > 0:
    info "connecting to static peers", nodes=staticnodes
    await wakuNode.connectToNodes(staticnodes)

  elif fleet != WakuFleet.none:
    info "static peers not configured, choosing one at random", fleet
    let node = await selectRandomNode($fleet)

    info "connecting to peer", node
    await wakuNode.connectToNodes(@[node])

  if swapProtocol: wakuNode.mountSwap()

  if filter:
    proc filterHandler(message: WakuMessage) {.gcsafe, closure.} =
      try:
        discard self.handleWakuMessage(waku.DefaultTopic, message)
      except CatchableError as e:
        error "waku filter handler encountered an unknown error", error=e.msg

    self.wakuFilterHandler = filterHandler

    wakuNode.mountFilter()
    wakuNode.wakuFilter.setPeer(parsePeerInfo(filternode))

    (await self.addFiltersImpl(self.getTopics)).expect(
      "addFilters is not expected to fail in this context")

  if lightpush:
    wakuNode.mountLightPush()
    wakuNode.wakuLightPush.setPeer(parsePeerInfo(lightpushnode))

  if store or storenode != "":
    proc historyHandler(response: HistoryResponse) {.gcsafe, closure.} =
      for message in response.messages:
        try:
          discard self.handleWakuMessage(waku.DefaultTopic, message)
        except CatchableError as e:
          error "waku history handler encountered an unknown error", error=e.msg

    self.wakuHistoryHandler = historyHandler

    wakuNode.mountStore(persistMessages = false)

    var snode: Option[string]

    if storenode != "":
      snode = some(storenode)

    elif fleet != WakuFleet.none:
      info "store nodes not configured, choosing one at random", fleet
      snode = some(await selectRandomNode($fleet))

    if snode.isNone:
      warn "unable to determine a storenode, no connection made"

    else:
      info "connecting to storenode", storenode=snode
      wakuNode.wakuStore.setPeer(parsePeerInfo(snode.get()))

  if relay:
    proc relayHandler(pubSubTopic: waku.Topic, data: seq[byte])
      {.async, gcsafe.} =
      let decoded = WakuMessage.init(data)
      if decoded.isOk():
        let message = decoded.get()
        asyncSpawn self.handleWakuMessage(pubSubTopic, message)
      else:
        error "received invalid WakuMessage", error=decoded.error, pubSubTopic

    for pTopic in pubSubTopics:
      wakuNode.subscribe(pTopic, relayHandler)

  if keepAlive: wakuNode.startKeepalive()

  self.setNetworkState(NetworkState.online)

  return ok()

proc disconnect*(self: StatusObject): Future[WakuResult[void]] {.async.} =
  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  if self.networkState != NetworkState.online:
    return err MustBeOnline

  self.setNetworkState(NetworkState.disconnecting)

  if self.wakuFilter:
    (await self.removeFiltersImpl(self.getTopics)).expect(
      "removeFilters is not expected to fail in this context")

  for pTopic in self.wakuPubSubTopics:
    self.wakuNode.unsubscribeAll(pTopic)

  await self.wakuNode.stop()

  self.wakuFilter = false
  self.wakuFilternode = ""
  self.wakuLightpush = false
  self.wakuLightpushnode = ""
  self.wakuNode = nil
  self.wakuPubSubTopics = @[waku.DefaultTopic]
  self.wakuRlnRelay = false
  self.wakuStore = true
  self.wakuStorenode = ""

  self.setNetworkState(NetworkState.offline)

  return ok()
