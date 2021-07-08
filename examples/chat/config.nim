import # std libs
  std/[macros, os, strutils]

import # vendor libs
  chronicles, confutils, confutils/std/net

import # chat libs
  ./client/waku_chat2

export confutils, net.ValidIpAddress, net.init

logScope:
  topics = "chat config"

type
  LLevel* = distinct string

  PK* = distinct string

  VIP* = distinct string

  WakuFleet* = enum none, prod, test

const
  defDataDir = "data"
  defDataDirComp = "./" & defDataDir
  defListenAddress = VIP("0.0.0.0")
  defLogFile = "chat.log"
  defLogFileComp = "./" & defDataDir & "/" & defLogFile
  defLogLevel = when defined(release): LLevel("info") else: LLevel("debug")
  defLogLevelChron = when defined(release): INFO else: DEBUG
  defMetricsServerAddress = VIP("127.0.0.1")
  defRpcAddress = VIP("127.0.0.1")

  logLevels = @[
    "TRC", "TRACE", "trc", "trace",
    "DBG", "DEBUG", "dbg", "debug",
    "INF", "INFO", "inf", "info",
    "NOT", "NOTICE", "not", "notice",
    "WRN", "WARN", "wrn", "warn",
    "ERR", "ERROR", "err", "error",
    "FAT", "FATAL", "fat", "fatal",
    "NON", "NONE", "non", "none"
  ]

proc `$`*(input: LLevel): string =
  input.string

proc `$`*(input: PK): string =
  input.string

proc `$`*(input: VIP): string =
  input.string

macro config(): untyped =
  var
    chatConfigId = ident("ChatConfig")
    dataDirLit = newStrLitNode(defDataDirComp)
    filterId = ident("filter")
    swapId = ident("swap")
    logFileLit = newStrLitNode(defLogFileComp)
    logLevelLit = newStrLitNode($defLogLevel)
    lightpushId = ident("lightpush")
    listenAddrLit = newStrLitNode($defListenAddress)
    metricsAddrLit = newStrLitNode($defMetricsServerAddress)
    rpcAddrLit = newStrLitNode($defRpcAddress)

  result = quote do:
    type
      `chatConfigId` = object
        dataDir* {.
          defaultValue: "[placeholder]"
          desc: "Data directory. Relative path will be resolved from ${PWD}"
          name: "data-dir"
        .}: string

        logFile* {.
          defaultValue: "[placeholder]"
          desc: "Log file. Relative path will be resolved from ${PWD}. If " &
                "not specified then chat.log will be written to --data-dir"
          name: "log-file"
        .}: string

        logLevel* {.
          defaultValue: "[placeholder]"
          desc: "Log level. " &
                "Must be one of: trace, debug, info, notice, warn, error, " &
                "fatal, none",
          name: "log-level"
        .}: LLevel

        # Waku -----------------------------------------------------------------
        # (adapted from: nim-waku/examples/v2/config_chat2.nim)

        # General node config

        nodekey* {.
          defaultValue: ""
          desc: "P2P node private key as 64 char hex string, random by default"
          name: "waku-nodekey"
        .}: PK

        listenAddress* {.
          defaultValue: "[placeholder]"
          desc: "Listening address for the LibP2P traffic"
          name: "waku-listen-address"
        .}: VIP

        tcpPort* {.
          defaultValue: 60000
          desc: "TCP listening port"
          name: "waku-tcp-port"
        .}: Port

        udpPort* {.
          defaultValue: 60000
          desc: "UDP listening port"
          name: "waku-udp-port"
        .}: Port

        portsShift* {.
          defaultValue: 0
          desc: "Add a shift to all port numbers"
          name: "waku-ports-shift"
        .}: uint16

        nat* {.
          defaultValue: "any"
          desc: "Specify method to use for determining public address. " &
                "Must be one of: any, none, upnp, pmp, extip:<IP>"
          name: "waku-nat"
        .}: string

        # Persistence config

        dbPath* {.
          defaultValue: ""
          desc: "The database path for peristent storage"
          name: "waku-db-path"
        .}: string

        persistPeers* {.
          defaultValue: false
          desc: "Enable peer persistence: true|false"
          name: "waku-persist-peers"
        .}: bool

        persistMessages* {.
          defaultValue: false
          desc: "Enable message persistence: true|false"
          name: "waku-persist-messages"
        .}: bool

        # Relay config

        relay* {.
          defaultValue: true
          desc: "Enable relay protocol: true|false"
          name: "waku-relay"
        .}: bool

        rlnRelay* {.
          defaultValue: false
          desc: "Enable spam protection through rln-relay: true|false"
          name: "waku-rln-relay"
        .}: bool

        staticnodes* {.
          desc: "Peer multiaddr to directly connect with. Argument may be " &
                "repeated"
          name: "waku-staticnode"
        .}: seq[string]

        keepAlive* {.
          defaultValue: false
          desc: "Enable keep-alive for idle connections: true|false"
          name: "waku-keep-alive"
        .}: bool

        topics* {.
          defaultValue: "/waku/2/default-waku/proto"
          desc: "Default topics to subscribe to (space separated list)"
          name: "waku-topics"
        .}: string

        # Store config

        store* {.
          defaultValue: true
          desc: "Enable store protocol: true|false"
          name: "waku-store"
        .}: bool

        storenode* {.
          defaultValue: ""
          desc: "Peer multiaddr to query for storage"
          name: "waku-storenode"
        .}: string

        # Filter config

        `filterId`* {.
          defaultValue: false
          desc: "Enable filter protocol: true|false"
          name: "waku-filter"
        .}: bool

        filternode* {.
          defaultValue: ""
          desc: "Peer multiaddr to request content filtering of messages"
          name: "waku-filternode"
        .}: string

        # Swap config

        `swapId`* {.
          defaultValue: true
          desc: "Enable swap protocol: true|false"
          name: "waku-swap"
        .}: bool

        # Lightpush config

        `lightpushId`* {.
          defaultValue: false
          desc: "Enable lightpush protocol: true|false"
          name: "waku-lightpush"
        .}: bool

        lightpushnode* {.
          defaultValue: ""
          desc: "Peer multiaddr to request lightpush of published messages"
          name: "waku-lightpushnode"
        .}: string

        # JSON-RPC config

        rpc* {.
          defaultValue: true
          desc: "Enable Waku JSON-RPC server: true|false"
          name: "waku-rpc"
        .}: bool

        rpcAddress* {.
          defaultValue: "[placeholder]"
          desc: "Listening address of the JSON-RPC server"
          name: "waku-rpc-address"
        .}: VIP

        rpcPort* {.
          defaultValue: 8545
          desc: "Listening port of the JSON-RPC server"
          name: "waku-rpc-port"
        .}: uint16

        rpcAdmin* {.
          defaultValue: false
          desc: "Enable access to JSON-RPC Admin API: true|false"
          name: "waku-rpc-admin"
        .}: bool

        rpcPrivate* {.
          defaultValue: false
          desc: "Enable access to JSON-RPC Private API: true|false"
          name: "waku-rpc-private"
        .}: bool

        # Metrics config

        metricsServer* {.
          defaultValue: false
          desc: "Enable the metrics server: true|false"
          name: "waku-metrics-server"
        .}: bool

        metricsServerAddress* {.
          defaultValue: "[placeholder]"
          desc: "Listening address of the metrics server"
          name: "waku-metrics-server-address"
        .}: VIP

        metricsServerPort* {.
          defaultValue: 8008
          desc: "Listening HTTP port of the metrics server"
          name: "waku-metrics-server-port"
        .}: uint16

        metricsLogging* {.
          defaultValue: false
          desc: "Enable metrics logging: true|false"
          name: "waku-metrics-logging"
        .}: bool

        # Chat2 configuration

        fleet* {.
          defaultValue: prod
          desc: "Select the fleet to connect to. " &
                "Must be one of: none, prod, test"
          name: "waku-fleet"
        .}: WakuFleet

        contentTopics* {.
          defaultValue: "/toy-chat/2/huilong/proto"
          desc: "Default content topics for chat messages " &
                "(space separated list)",
          name: "waku-content-topics"
        .}: string

    export `chatConfigId`

  var
    dataDirColonExpr = result[0][0][2][2][0][0][1][0]
    logFileColonExpr = result[0][0][2][2][1][0][1][0]
    logLevelColonExpr = result[0][0][2][2][2][0][1][0]
    listenAddrColonExpr = result[0][0][2][2][4][0][1][0]
    rpcAddrColonExpr = result[0][0][2][2][25][0][1][0]
    metricsAddrColonExpr = result[0][0][2][2][30][0][1][0]

  # inject values derived from constants at the top of this module
  dataDirColonExpr[1] = dataDirLit
  logFileColonExpr[1] = logFileLit
  listenAddrColonExpr[1] = listenAddrLit
  logLevelColonExpr[1] = logLevelLit
  rpcAddrColonExpr[1] = rpcAddrLit
  metricsAddrColonExpr[1] = metricsAddrLit

config()

proc parseCmdArg*(T: type LLevel, p: TaintedString): T =
  if not logLevels.contains(p):
    raise newException(ConfigurationError, "Invalid log level")
  else:
    result = LLevel(p)

proc completeCmdArg*(T: type LLevel, val: TaintedString): seq[string] =
  return @[]

proc parseCmdArg*(T: type PK, p: TaintedString): T =
  try:
    discard waku_chat2.crypto.PrivateKey(scheme: Secp256k1,
      skkey: SkPrivateKey.init(waku_chat2.utils.fromHex(p)).tryGet())
    result = PK(p)
  except CatchableError as e:
    raise newException(ConfigurationError, "Invalid private key")

proc completeCmdArg*(T: type PK, val: TaintedString): seq[string] =
  return @[]

proc parseCmdArg*(T: type VIP, p: TaintedString): T =
  try:
    discard ValidIpAddress.init(p)
    result = VIP(p)
  except CatchableError as e:
    raise newException(ConfigurationError, "Invalid IP address")

proc completeCmdArg*(T: type VIP, val: TaintedString): seq[string] =
  return @[]

proc parseCmdArg*(T: type Port, p: TaintedString): T =
  try:
    result = Port(parseInt(p))
  except CatchableError as e:
    raise newException(ConfigurationError, "Invalid Port number")

proc completeCmdArg*(T: type Port, val: TaintedString): seq[string] =
  return @[]

proc handleConfig*(config: ChatConfig): ChatConfig =
  let
    dataDir = absolutePath(expandTilde(config.dataDir))
    logFile =
      if config.dataDir != defDataDirComp and
         config.logFile == defLogFileComp:
        joinPath(dataDir, extractFilename(defLogFile))
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
      logLevel = defLogLevelChron

  var cfg = config
  cfg.dataDir = dataDir
  cfg.logFile = logFile

  createDir(dataDir)
  setLogLevel(logLevel)
  discard defaultChroniclesStream.output.open(logFile, fmAppend)

  return cfg
