import # std libs
  std/[macros, os, strutils]

import # vendor libs
  chronicles, confutils, confutils/std/net

import # chat libs
  ./client/waku_chat2

export confutils, net.ValidIpAddress, net.init

type
  LLevel = distinct string

  WakuFleet* =  enum
    none
    prod
    test

proc `$`*(input: LLevel): string =
  input.string

const logLevels = @[
  "TRC", "TRACE", "trc", "trace",
  "DBG", "DEBUG", "dbg", "debug",
  "INF", "INFO", "inf", "info",
  "NOT", "NOTICE", "not", "notice",
  "WRN", "WARN", "wrn", "warn",
  "ERR", "ERROR", "err", "error",
  "FAT", "FATAL", "fat", "fatal",
  "NON", "NONE", "non", "none"
]

const
  defLogLevel =
    when defined(release): LLevel("info")
    else: LLevel("debug")

macro config(): untyped =
  var
    chatConfigId = ident("ChatConfig")
    filterId = ident("filter")
    swapId = ident("swap")
    levelLit = newStrLitNode($defLogLevel)

  result = quote do:
    type
      `chatConfigId` = object
        dataDir* {.
          defaultValue: "./data"
          desc: "Data directory. Relative path will be resolved from ${PWD}"
          name: "data-dir"
        .}: string

        logFile* {.
          defaultValue: "./data/chat.log"
          desc: "Log file. Relative path will be resolved from ${PWD}. If " &
                "not specified then chat.log will be written to --data-dir"
          name: "log-file"
        .}: string

        logLevel* {.
          defaultValue: "info",
          desc: "Log level. " &
                "Must be one of: trace, debug, info, notice, warn, error, " &
                "fatal, none",
          name: "log-level"
        .}: LLevel

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

        `filterId`* {.
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

        `swapId`* {.
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
          desc: "Select the fleet to connect to. " &
                "Must be one of: none, prod, test"
          defaultValue: prod
          name: "waku-fleet"
        .}: WakuFleet

        contentTopic* {.
          desc: "Content topic for chat messages"
          defaultValue: "/toy-chat/2/huilong/proto"
          name: "waku-content-topic"
        .}: string

    export `chatConfigId`

  result[0][0][2][2][2][0][1][0][1] = levelLit

config()

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

proc parseCmdArg*(T: type LLevel, p: TaintedString): T =
  if not logLevels.contains(p):
    raise newException(ConfigurationError, "Invalid log level")
  else:
    result = LLevel(p)

proc completeCmdArg*(T: type LLevel, val: TaintedString): seq[string] =
  return @[]

func defaultListenAddress*(conf: ChatConfig): ValidIpAddress =
  # TODO: How should we select between IPv4 and IPv6
  # Maybe there should be a config option for this.
  (static ValidIpAddress.init("0.0.0.0"))

proc defaultDataDir*(): string =
  # logic here could evolve to something more complex (e.g. platform-specific)
  # like the `defaultDataDir()` of status-desktop
  joinPath(getCurrentDir(), "data")

proc defaultLogFile*(): string =
  joinPath(defaultDataDir(), "chat.log")

proc handleConfig*(config: ChatConfig): ChatConfig =
  let
    dataDir = absolutePath(expandTilde(config.dataDir))
    logFile =
      if config.dataDir != defaultDataDir() and
         config.logFile == defaultLogFile():
        joinPath(dataDir, extractFilename(defaultLogFile()))
      else:
        absolutePath(expandTilde(config.logFile))

  var logLevel: LogLevel

  case $config.logLevel:
    of "TRC", "TRACE", "trc", "trace":
      logLevel = TRACE
    of "DBG", "DEBUG", "dbg", "debug":
      logLevel = DEBUG
    of "INF", "INFO", "inf", "info":
      logLevel = INFO
    of "NOT", "NOTICE", "not", "notice":
      logLevel = NOTICE
    of "WRN", "WARN", "wrn", "warn":
      logLevel = WARN
    of "ERR", "ERROR", "err", "error":
      logLevel = ERROR
    of "FAT", "FATAL", "fat", "fatal":
      logLevel = FATAL
    of "NON", "NONE", "non", "none":
      logLevel = NONE
    else:
      logLevel = when defined(release): INFO else: DEBUG

  var cfg = config
  cfg.dataDir = dataDir
  cfg.logFile = logFile

  createDir(dataDir)
  setLogLevel(logLevel)
  discard defaultChroniclesStream.output.open(logFile, fmAppend)

  return cfg
