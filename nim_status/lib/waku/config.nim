import chronicles, chronos, eth/keys, strutils, json

type WakuNodeConf* = object
  logLevel*: LogLevel
  tcpPort*: uint16
  udpPort*: uint16
  portsShift*: uint16
  nat*: string
  nodekey*: KeyPair
  staticnodes*: seq[string]
  minimumPoW*: float
  bloom*: bool
  enabled*: bool
  lightClient*: bool
  bloomFilterMode*: bool


proc load*(settings: JsonNode): WakuNodeConf =
  result = WakuNodeConf(
    logLevel: parseEnum[LogLevel](settings{"LogLevel"}.getStr("INFO")),
    # TODO: Determine if the port can be configured
    tcpPort: 30303,
    udpPort: 30303,
    portsShift: 0,
    nat: "any",
    staticnodes: @[],
    enabled: false,
    lightClient: true,
    bloomFilterMode: false,
    minimumPoW: 0.002
  )

  # TODO use a single instance of RNG
  result.nodekey = KeyPair.random(keys.newRng()[])

  if(settings.hasKey("ClusterConfig") and settings["ClusterConfig"].hasKey("StaticNodes") and settings["ClusterConfig"]["StaticNodes"].kind == JArray):
    result.staticnodes = to(settings["ClusterConfig"]["StaticNodes"], seq[string])

  if(settings.hasKey("WakuConfig") and settings["WakuConfig"].kind == JObject):
    result.enabled = settings["WakuConfig"]{"Enabled"}.getBool()
    result.lightClient = settings["WakuConfig"]{"LightClient"}.getBool()
    result.bloomFilterMode = settings["WakuConfig"]{"BloomFilterMode"}.getBool()
    result.minimumPoW = settings["WakuConfig"]{"MinimumPoW"}.getFloat()
