import
  std/[os,options],
  confutils, chronicles, chronos,
  stew/shims/net as stewNet,
  libp2p/crypto/[crypto,secp],
  eth/keys,
  json_rpc/[rpcclient, rpcserver],
  waku/v2/node/[config, wakunode2],
  waku/common/utils/nat

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
