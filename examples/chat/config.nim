import # std libs
  std/[os, strutils]

import # vendor libs
  chronicles, confutils, confutils/std/net, eth/keys,
  libp2p/[crypto/crypto, crypto/secp], nimcrypto/utils

proc defaultDataDir*(): string =
  # logic here could evolve to something more complex (e.g. platform-specific)
  # like the `defaultDataDir()` of status-desktop
  joinPath(getCurrentDir(), "data")

proc defaultLogFile*(): string =
  joinPath(defaultDataDir(), "chat.log")

type
  WakuFleet* =  enum
    none
    prod
    test

  ChatConfig* = object
    dataDir* {.
      defaultValue: defaultDataDir()
      desc: "Chat data directory. Default is ${PWD}/data. If supplied path " &
            "is relative it will be resolved from ${PWD}"
      name: "data-dir"
    .}: string

    logFile* {.
      defaultValue: defaultLogFile()
      desc: "Chat log file. Default is ./chat.log relative to --data-dir " &
            "(see above). If supplied path is relative it will be resolved " &
            "from ${PWD}"
      name: "log-file"
    .}: string

    logLevel* {.
      desc: "Select the log level"
      defaultValue: LogLevel.INFO
      name: "log-level"
    .}: LogLevel

    # Waku ---------------------------------------------------------------------
    # (adapted from: nim-waku/examples/v2/config_chat2.nim)

    # General node config

    nodekey* {.
      desc: "P2P node private key as 64 char hex string"
      defaultValue: crypto.PrivateKey.random(Secp256k1,
        keys.newRng()[]).tryGet()
      name: "waku-nodekey"
    .}: crypto.PrivateKey

    listenAddress* {.
      defaultValue: defaultListenAddress(config)
      desc: "Listening address for the LibP2P traffic"
      name: "waku-listen-address"
    .}: ValidIpAddress

    tcpPort* {.
      desc: "TCP listening port"
      defaultValue: 60000
      name: "waku-tcp-port"
    .}: Port

    udpPort* {.
      desc: "UDP listening port"
      defaultValue: 60000
      name: "waku-udp-port"
    .}: Port

    portsShift* {.
      desc: "Add a shift to all port numbers"
      defaultValue: 0
      name: "waku-ports-shift"
    .}: uint16

    nat* {.
      desc: "Specify method to use for determining public address. " &
            "Must be one of: any, none, upnp, pmp, extip:<IP>"
      defaultValue: "any"
      name: "waku-nat"
    .}: string

    # Persistence config

    dbPath* {.
      desc: "The database path for peristent storage"
      defaultValue: ""
      name: "waku-db-path"
    .}: string

    persistPeers* {.
      desc: "Enable peer persistence: true|false"
      defaultValue: false
      name: "waku-persist-peers"
    .}: bool

    persistMessages* {.
      desc: "Enable message persistence: true|false"
      defaultValue: false
      name: "waku-persist-messages"
    .}: bool

    # Relay config

    relay* {.
      desc: "Enable relay protocol: true|false"
      defaultValue: true
      name: "waku-relay"
    .}: bool

    rlnRelay* {.
      desc: "Enable spam protection through rln-relay: true|false"
      defaultValue: false
      name: "waku-rln-relay"
    .}: bool

    staticnodes* {.
      desc: "Peer multiaddr to directly connect with. Argument may be repeated"
      name: "waku-staticnode"
    .}: seq[string]

    keepAlive* {.
      desc: "Enable keep-alive for idle connections: true|false"
      defaultValue: false
      name: "waku-keep-alive"
    .}: bool

    topics* {.
      desc: "Default topics to subscribe to (space separated list)"
      defaultValue: "/waku/2/default-waku/proto"
      name: "waku-topics"
    .}: string

    # Store config

    store* {.
      desc: "Enable store protocol: true|false"
      defaultValue: true
      name: "waku-store"
    .}: bool

    storenode* {.
      desc: "Peer multiaddr to query for storage"
      defaultValue: ""
      name: "waku-storenode"
    .}: string

    # Filter config

    filter* {.
      desc: "Enable filter protocol: true|false"
      defaultValue: false
      name: "waku-filter"
    .}: bool

    filternode* {.
      desc: "Peer multiaddr to request content filtering of messages"
      defaultValue: ""
      name: "waku-filternode"
    .}: string

    # Swap config

    swap* {.
      desc: "Enable swap protocol: true|false"
      defaultValue: true
      name: "waku-swap"
    .}: bool

    # Lightpush config

    lightpush* {.
      desc: "Enable lightpush protocol: true|false"
      defaultValue: false
      name: "waku-lightpush"
    .}: bool

    lightpushnode* {.
      desc: "Peer multiaddr to request lightpush of published messages"
      defaultValue: ""
      name: "waku-lightpushnode"
    .}: string

    # JSON-RPC config

    rpc* {.
      desc: "Enable Waku JSON-RPC server: true|false"
      defaultValue: true
      name: "waku-rpc"
    .}: bool

    rpcAddress* {.
      desc: "Listening address of the JSON-RPC server"
      defaultValue: ValidIpAddress.init("127.0.0.1")
      name: "waku-rpc-address"
    .}: ValidIpAddress

    rpcPort* {.
      desc: "Listening port of the JSON-RPC server"
      defaultValue: 8545
      name: "waku-rpc-port"
    .}: uint16

    rpcAdmin* {.
      desc: "Enable access to JSON-RPC Admin API: true|false"
      defaultValue: false
      name: "waku-rpc-admin"
    .}: bool

    rpcPrivate* {.
      desc: "Enable access to JSON-RPC Private API: true|false"
      defaultValue: false
      name: "waku-rpc-private"
    .}: bool

    # Metrics config

    metricsServer* {.
      desc: "Enable the metrics server: true|false"
      defaultValue: false
      name: "waku-metrics-server"
    .}: bool

    metricsServerAddress* {.
      desc: "Listening address of the metrics server"
      defaultValue: ValidIpAddress.init("127.0.0.1")
      name: "waku-metrics-server-address"
    .}: ValidIpAddress

    metricsServerPort* {.
      desc: "Listening HTTP port of the metrics server"
      defaultValue: 8008
      name: "waku-metrics-server-port"
    .}: uint16

    metricsLogging* {.
      desc: "Enable metrics logging: true|false"
      defaultValue: false
      name: "waku-metrics-logging"
    .}: bool

    # Chat2 configuration

    fleet* {.
      desc: "Select the fleet to connect to"
      defaultValue: WakuFleet.prod
      name: "waku-fleet"
    .}: WakuFleet

    contentTopic* {.
      desc: "Content topic for chat messages"
      defaultValue: "/toy-chat/2/huilong/proto"
      name: "waku-content-topic"
    .}: string

# NOTE: Keys are different in nim-libp2p
proc parseCmdArg*(T: type crypto.PrivateKey, p: TaintedString): T =
  try:
    let key = SkPrivateKey.init(utils.fromHex(p)).tryGet()
    # XXX: Here at the moment
    result = crypto.PrivateKey(scheme: Secp256k1, skkey: key)
  except CatchableError as e:
    raise newException(ConfigurationError, "Invalid private key")

proc completeCmdArg*(T: type crypto.PrivateKey,
  val: TaintedString): seq[string] =

  return @[]

proc parseCmdArg*(T: type ValidIpAddress, p: TaintedString): T =
  try:
    result = ValidIpAddress.init(p)
  except CatchableError as e:
    raise newException(ConfigurationError, "Invalid IP address")

proc completeCmdArg*(T: type ValidIpAddress, val: TaintedString): seq[string] =
  return @[]

proc parseCmdArg*(T: type Port, p: TaintedString): T =
  try:
    result = Port(parseInt(p))
  except CatchableError as e:
    raise newException(ConfigurationError, "Invalid Port number")

proc completeCmdArg*(T: type Port, val: TaintedString): seq[string] =
  return @[]

func defaultListenAddress*(conf: ChatConfig): ValidIpAddress =
  # TODO: How should we select between IPv4 and IPv6
  # Maybe there should be a config option for this.
  (static ValidIpAddress.init("0.0.0.0"))

proc handleConfig*(config: ChatConfig): ChatConfig =
  let
    dataDir = absolutePath(expandTilde(config.dataDir))
    logFile =
      if config.dataDir != defaultDataDir() and
         config.logFile == defaultLogFile():
        joinPath(dataDir, extractFilename(defaultLogFile()))
      else:
        absolutePath(expandTilde(config.logFile))

  var cfg = config
  cfg.dataDir = dataDir
  cfg.logFile = logFile

  createDir(dataDir)
  discard defaultChroniclesStream.output.open(logFile, fmAppend)

  return cfg
