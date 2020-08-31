import
  chronicles, chronos,
  eth/[keys, p2p],
  waku/protocol/v1/waku_protocol,
  waku/node/v1/waku_helpers,
  config

const clientId = "nim-status/v0.0.1/linux-amd64" # TODO

proc start*(config: WakuNodeConf) =
  let
    rng = keys.newRng()
    # Set up the address according to NAT information.
    (ip, tcpPort, udpPort) = setupNat(config.nat, clientId, config.tcpPort,
      config.udpPort, config.portsShift)
    address = Address(ip: ip, tcpPort: tcpPort, udpPort: udpPort)

  # Create Ethereum Node
  var node = newEthereumNode(config.nodekey, # Node identifier
    address, # Address reachable for incoming requests
    1, # Network Id, only applicable for ETH protocol
    nil, # Database, not required for Waku
    clientId, # Client id string
    addAllCapabilities = false, # Disable default all RLPx capabilities
    rng = rng)

  node.addCapability Waku # Enable only the Waku protocol.

  # Set up the Waku configuration.
  let wakuConfig = WakuConfig(
    powRequirement: config.minimumPoW,
    isLightNode: config.lightClient, # Full node
    maxMsgSize: waku_protocol.defaultMaxMsgSize,
    topics: none(seq[waku_protocol.Topic]), # empty topic interest
    bloom: if config.bloomFilterMode: some(fullBloom()) else: none(Bloom) # Full bloom filter
  )
  
  node.configureWaku(wakuConfig)

  # Optionally direct connect to a set of nodes.
  if config.staticnodes.len > 0:
    connectToNodes(node, config.staticnodes)

  # Connect to the network, which will make the node start listening and/or
  # connect to bootnodes, and/or start discovery.
  # This will block until first connection is made, which in this case can only
  # happen if we directly connect to nodes (step above) or if an incoming
  # connection occurs, which is why we use a callback to exit on errors instead of
  # using `await`.
  let connectedFut = node.connectToNetwork(@[],
    true, # Enable listening
    false # Disable discovery (only discovery v4 is currently supported)
    )
  connectedFut.callback = proc(data: pointer) {.gcsafe.} =
    {.gcsafe.}:
      if connectedFut.failed:
        fatal "connectToNetwork failed", msg = connectedFut.readError.msg
        quit(1)
