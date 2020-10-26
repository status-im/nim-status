import
  chronicles,
  confutils,
  eth/keys,
  libp2p/crypto/crypto,
  options,
  stew/shims/net,
  waku/node/common,
  waku/node/v2/[config, waku_types, wakunode2]

# The initial implementation of initNode is by intention a minimum viable usage
# of nim-waku v2 from within nim-status

proc initNode*(config: WakuNodeConf = WakuNodeConf.load()): WakuNode =
  let
    (extIp, extTcpPort, extUdpPort) = setupNat(config.nat, clientId,
      Port(uint16(config.tcpPort) + config.portsShift),
      Port(uint16(config.udpPort) + config.portsShift))
    node = WakuNode.init(config.nodeKey, config.listenAddress,
      Port(uint16(config.tcpPort) + config.portsShift), extIp, extTcpPort)
  result = node
