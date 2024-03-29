{.push raises: [Defect].}

import # vendor libs
  chronos, confutils,
  eth/[keys, p2p]
  stew/[byteutils, results],
  stew/shims/net as stewNet,
  waku/v1/[node/waku_helpers, protocol/waku_protocol],
  waku/common/utils/nat


proc startWaku*() =
  # Test waku
  const clientId = "NimStatusWaku"
  let nodeKey = KeyPair.random(keys.newRng()[])
  let rng = keys.newRng()
  let (ipExt, tcpPortExt, udpPortExt) = setupNat("any", clientId, Port(30307), Port(30307))
  let address = if ipExt.isNone(): Address(ip: parseIpAddress("0.0.0.0"), tcpPort: Port(30307),udpPort: Port(30307)) else: Address(ip: ipExt.get(), tcpPort: Port(30307), udpPort: Port(30307))

  # Create Ethereum Node
  var node = newEthereumNode(nodekey, # Node identifier
      address, # Address reachable for incoming requests
      1, # Network Id, only applicable for ETH protocol
      nil, # Database, not required for Waku
      clientId, # Client id string
      addAllCapabilities = false, # Disable default all RLPx capabilities
      rng = rng)

  node.addCapability Waku # Enable only the Waku protocol.

  # Set up the Waku configuration.
  let wakuConfig = WakuConfig(powRequirement: 0.002,
      bloom: some(fullBloom()), # Full bloom filter
      isLightNode: false, # Full node
      maxMsgSize: waku_protocol.defaultMaxMsgSize,
      topics: none(seq[waku_protocol.Topic]) # empty topic interest
    )
  node.configureWaku(wakuConfig)

  let staticNodes = @[
    "enode://6e6554fb3034b211398fcd0f0082cbb6bd13619e1a7e76ba66e1809aaa0c5f1ac53c9ae79cf2fd4a7bacb10d12010899b370c75fed19b991d9c0cdd02891abad@47.75.99.169:443",
    "enode://436cc6f674928fdc9a9f7990f2944002b685d1c37f025c1be425185b5b1f0900feaf1ccc2a6130268f9901be4a7d252f37302c8335a2c1a62736e9232691cc3a@178.128.138.128:443",
    "enode://32ff6d88760b0947a3dee54ceff4d8d7f0b4c023c6dad34568615fcae89e26cc2753f28f12485a4116c977be937a72665116596265aa0736b53d46b27446296a@34.70.75.208:443",
    "enode://23d0740b11919358625d79d4cac7d50a34d79e9c69e16831c5c70573757a1f5d7d884510bc595d7ee4da3c1508adf87bbc9e9260d804ef03f8c1e37f2fb2fc69@47.52.106.107:443",
    "enode://5395aab7833f1ecb671b59bf0521cf20224fe8162fc3d2675de4ee4d5636a75ec32d13268fc184df8d1ddfa803943906882da62a4df42d4fccf6d17808156a87@178.128.140.188:443",
    "enode://5405c509df683c962e7c9470b251bb679dd6978f82d5b469f1f6c64d11d50fbd5dd9f7801c6ad51f3b20a5f6c7ffe248cc9ab223f8bcbaeaf14bb1c0ef295fd0@35.223.215.156:443",
    "enode://b957e51f41e4abab8382e1ea7229e88c6e18f34672694c6eae389eac22dab8655622bbd4a08192c321416b9becffaab11c8e2b7a5d0813b922aa128b82990dab@47.75.222.178:443",
    "enode://66ba15600cda86009689354c3a77bdf1a97f4f4fb3ab50ffe34dbc904fac561040496828397be18d9744c75881ffc6ac53729ddbd2cdbdadc5f45c400e2622f7@178.128.141.87:443",
    "enode://182ed5d658d1a1a4382c9e9f7c9e5d8d9fec9db4c71ae346b9e23e1a589116aeffb3342299bdd00e0ab98dbf804f7b2d8ae564ed18da9f45650b444aed79d509@34.68.132.118:443",
    "enode://8bebe73ddf7cf09e77602c7d04c93a73f455b51f24ae0d572917a4792f1dec0bb4c562759b8830cc3615a658d38c1a4a38597a1d7ae3ba35111479fc42d65dec@47.75.85.212:443",
    "enode://4ea35352702027984a13274f241a56a47854a7fd4b3ba674a596cff917d3c825506431cf149f9f2312a293bb7c2b1cca55db742027090916d01529fe0729643b@134.209.136.79:443",
    "enode://fbeddac99d396b91d59f2c63a3cb5fc7e0f8a9f7ce6fe5f2eed5e787a0154161b7173a6a73124a4275ef338b8966dc70a611e9ae2192f0f2340395661fad81c0@34.67.230.193:443",
    "enode://ac3948b2c0786ada7d17b80cf869cf59b1909ea3accd45944aae35bf864cc069126da8b82dfef4ddf23f1d6d6b44b1565c4cf81c8b98022253c6aea1a89d3ce2@47.75.88.12:443",
    "enode://ce559a37a9c344d7109bd4907802dd690008381d51f658c43056ec36ac043338bd92f1ac6043e645b64953b06f27202d679756a9c7cf62fdefa01b2e6ac5098e@134.209.136.123:443",
    "enode://c07aa0deea3b7056c5d45a85bca42f0d8d3b1404eeb9577610f386e0a4744a0e7b2845ae328efc4aa4b28075af838b59b5b3985bffddeec0090b3b7669abc1f3@35.226.92.155:443",
    "enode://385579fc5b14e04d5b04af7eee835d426d3d40ccf11f99dbd95340405f37cf3bbbf830b3eb8f70924be0c2909790120682c9c3e791646e2d5413e7801545d353@47.244.221.249:443",
    "enode://4e0a8db9b73403c9339a2077e911851750fc955db1fc1e09f81a4a56725946884dd5e4d11258eac961f9078a393c45bcab78dd0e3bc74e37ce773b3471d2e29c@134.209.136.101:443",
    "enode://0624b4a90063923c5cc27d12624b6a49a86dfb3623fcb106801217fdbab95f7617b83fa2468b9ae3de593ff6c1cf556ccf9bc705bfae9cb4625999765127b423@35.222.158.246:443",
    "enode://b77bffc29e2592f30180311dd81204ab845e5f78953b5ba0587c6631be9c0862963dea5eb64c90617cf0efd75308e22a42e30bc4eb3cd1bbddbd1da38ff6483e@47.75.10.177:443",
    "enode://a8bddfa24e1e92a82609b390766faa56cf7a5eef85b22a2b51e79b333c8aaeec84f7b4267e432edd1cf45b63a3ad0fc7d6c3a16f046aa6bc07ebe50e80b63b8c@178.128.141.249:443",
    "enode://a5fe9c82ad1ffb16ae60cb5d4ffe746b9de4c5fbf20911992b7dd651b1c08ba17dd2c0b27ee6b03162c52d92f219961cc3eb14286aca8a90b75cf425826c3bd8@104.154.230.58:443",
    "enode://cf5f7a7e64e3b306d1bc16073fba45be3344cb6695b0b616ccc2da66ea35b9f35b3b231c6cf335fdfaba523519659a440752fc2e061d1e5bc4ef33864aac2f19@47.75.221.196:443",
    "enode://887cbd92d95afc2c5f1e227356314a53d3d18855880ac0509e0c0870362aee03939d4074e6ad31365915af41d34320b5094bfcc12a67c381788cd7298d06c875@178.128.141.0:443",
    "enode://282e009967f9f132a5c2dd366a76319f0d22d60d0c51f7e99795a1e40f213c2705a2c10e4cc6f3890319f59da1a535b8835ed9b9c4b57c3aad342bf312fd7379@35.223.240.17:443",
    "enode://13d63a1f85ccdcbd2fb6861b9bd9d03f94bdba973608951f7c36e5df5114c91de2b8194d71288f24bfd17908c48468e89dd8f0fb8ccc2b2dedae84acdf65f62a@47.244.210.80:443",
    "enode://2b01955d7e11e29dce07343b456e4e96c081760022d1652b1c4b641eaf320e3747871870fa682e9e9cfb85b819ce94ed2fee1ac458904d54fd0b97d33ba2c4a4@134.209.136.112:443",
    "enode://b706a60572634760f18a27dd407b2b3582f7e065110dae10e3998498f1ae3f29ba04db198460d83ed6d2bfb254bb06b29aab3c91415d75d3b869cd0037f3853c@35.239.5.162:443",
    "enode://32915c8841faaef21a6b75ab6ed7c2b6f0790eb177ad0f4ea6d731bacc19b938624d220d937ebd95e0f6596b7232bbb672905ee12601747a12ee71a15bfdf31c@47.75.59.11:443",
    "enode://0d9d65fcd5592df33ed4507ce862b9c748b6dbd1ea3a1deb94e3750052760b4850aa527265bbaf357021d64d5cc53c02b410458e732fafc5b53f257944247760@178.128.141.42:443",
    "enode://e87f1d8093d304c3a9d6f1165b85d6b374f1c0cc907d39c0879eb67f0a39d779be7a85cbd52920b6f53a94da43099c58837034afa6a7be4b099bfcd79ad13999@35.238.106.101:443"
  ]

  connectToNodes(node, staticNodes)

  let connectedFut = node.connectToNetwork(@[],
    true, # Enable listening
    false # Disable discovery (only discovery v4 is currently supported)
    )
  connectedFut.callback = proc(data: pointer) {.gcsafe.} =
    {.gcsafe.}:
    if connectedFut.failed:
      fatal "connectToNetwork failed", msg = connectedFut.readError.msg
      quit(1)

   # Code to be executed on receival of a message on filter.
  proc handler(msg: ReceivedMessage) =
    echo "MSG RECEIVED!"
    if msg.decoded.src.isSome():
    echo "Received message from ", $msg.decoded.src.get(), ": ",       string.fromBytes(msg.decoded.payload)

  let
    symKey: SymKey = hexToByteArray[32]("0xa82a520aff70f7a989098376e48ec128f25f767085e84d7fb995a9815eebff0a")
    topic = hexToByteArray[4]("0x9c22ff5f") # test
    filter = initFilter(symKey = some(symKey), topics = @[topic])
  echo "-------------------------------------------------------------------------------------------------"
  echo node.subscribeFilter(filter, handler)

  runForever()
