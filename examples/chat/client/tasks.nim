import # chat libs
  ./events, ./waku

export events, waku

logScope:
  topics = "chat"

type
  StatusArg* = ref object of ContextArg
    chatConfig*: ChatConfig

var
  # using `ptr ChatConfig` is a workaround because some fields of `ChatConfig`
  # are type `ValidIpAddress` which has `{.requiresInit.}` pragma
  chatConfig {.threadvar.}: ptr ChatConfig
  nick {.threadvar.}: string
  wakuNode {.threadvar.}: WakuNode
  wakuState {.threadvar.}: WakuState

proc statusContext*(arg: ContextArg) {.async, gcsafe, nimcall.} =
  let arg = cast[StatusArg](arg)
  chatConfig = addr arg.chatConfig
  wakuState = WakuState.stopped

proc startChat2Waku*(username: string) {.task(kind=no_rts, stoppable=false).} =
  if wakuState != WakuState.stopped: return

  wakuState = WakuState.starting
  nick = username

  let
    (extIp, extTcpPort, extUdpPort) = setupNat(chatConfig[].nat, clientId,
     Port(uint16(chatConfig[].tcpPort) + chatConfig[].portsShift),
     Port(uint16(chatConfig[].udpPort) + chatConfig[].portsShift))

    wakuNode = WakuNode.init(
      chatConfig[].nodekey,
      chatConfig[].listenAddress,
      Port(uint16(chatConfig[].tcpPort) + chatConfig[].portsShift),
      extIp,
      extTcpPort
    )

  await wakuNode.start()

  wakuNode.mountRelay(chatConfig[].topics.split(" "),
    rlnRelayEnabled = chatConfig[].rlnRelay,
    relayMessages = chatConfig[].relay) # Indicates if node is capable to relay messages

  wakuNode.mountKeepalive()

  wakuState = WakuState.started

proc stopChat2Waku*() {.task(kind=no_rts, stoppable=false).} =
  if wakuState != WakuState.started: return

  wakuState = WakuState.stopping
  try:
    # this line is failing with an un-catchable error; node instance is
    # probably not fully setup/torn-down and/or there are some missing imports
    # as of now
    await wakuNode.stop()
  except Exception as e:
    trace "WHAT HAPPENED???", error=e.msg
  wakuState = WakuState.stopped


# ------------------------------------------------------------------------------

# let message = UserMessage(
#   message: "message " & $counter & " to " & nick,
#   timestamp: ...,
#   username: ...
# )
# asyncSpawn chanSendToHost.send(message.encode.safe)
