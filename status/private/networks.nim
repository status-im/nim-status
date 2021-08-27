{.push raises: [Defect].}

import # std libs
  std/[options, strformat]

import # vendor libs
  json_serialization,
  json_serialization/[lexer, reader, writer],
  json_serialization/std/options as json_options

import # nim-status modules
  ./common

type
  UpstreamConfig* = object
    enabled* {.serializedFieldName("Enabled").}: bool
    url* {.serializedFieldName("URL").}: string

  NetworkConfig* = object
    dataDir* {.serializedFieldName("DataDir").}: string
    networkId* {.serializedFieldName("NetworkId").}: NetworkId
    upstreamConfig* {.serializedFieldName("UpstreamConfig").}: UpstreamConfig

  Network* = object
    config* {.serializedFieldName("config").}: NetworkConfig
    etherscanLink* {.serializedFieldName("etherscan-link").}: Option[string]
    id* {.serializedFieldName("id").}: string
    name*: string

# set via `nim c` param `-d:INFURA_TOKEN:[token]`; should be set in CI/release builds
const INFURA_TOKEN {.strdefine.} = "220a1abb4b6943a093c35d0ce4fb0732" # @TODO: remove this
# TODO: allow runtime override via environment variable; core contributors can set a
# release token in this way for local development. INFURA_TOKEN needs to be constant
# due to GC safety requirements. We could allow the Infura token to be passed in
# to the `createAccount`/`importMnemonic` procs to allow override at runtime by
# implementing clients.

const DEFAULT_NETWORKS* = @[
  Network(
    id: "testnet_rpc",
    etherscanLink: "https://ropsten.etherscan.io/address/".some,
    name: "Ropsten with upstream RPC",
    config: NetworkConfig(
      networkId: NetworkId.Ropsten,
      dataDir: "/ethereum/testnet_rpc",
      upstreamConfig: UpstreamConfig(
        enabled: true,
        url: "wss://ropsten.infura.io/ws/v3/" & INFURA_TOKEN
      )
    )
  ),
  Network(
    id: "rinkeby_rpc",
    etherscanLink: "https://rinkeby.etherscan.io/address/".some,
    name: "Rinkeby with upstream RPC",
    config: NetworkConfig(
      networkId: NetworkId.Rinkeby,
      dataDir: "/ethereum/rinkeby_rpc",
      upstreamConfig: UpstreamConfig(
        enabled: true,
        url: "wss://rinkeby.infura.io/ws/v3/" & INFURA_TOKEN
      )
    )
  ),
  Network(
    id: "goerli_rpc",
    etherscanLink: "https://goerli.etherscan.io/address/".some,
    name: "Goerli with upstream RPC",
    config: NetworkConfig(
      networkId: NetworkId.Goerli,
      dataDir: "/ethereum/goerli_rpc",
      upstreamConfig: UpstreamConfig(
        enabled: true,
        url: "https://goerli.blockscout.com/"
      )
    )
  ),
  Network(
    id: "mainnet_rpc",
    etherscanLink: "https://etherscan.io/address/".some,
    name: "Mainnet with upstream RPC",
    config: NetworkConfig(
      networkId: NetworkId.Mainnet,
      dataDir: "/ethereum/mainnet_rpc",
      upstreamConfig: UpstreamConfig(
        enabled: true,
        url: "wss://mainnet.infura.io/ws/v3/" & INFURA_TOKEN
      )
    )
  ),
  Network(
    id: "xdai_rpc",
    etherscanLink: string.none,
    name: "xDai Chain",
    config: NetworkConfig(
      networkId: NetworkId.XDai,
      dataDir: "/ethereum/xdai_rpc",
      upstreamConfig: UpstreamConfig(
        enabled: true,
        url: "https://dai.poa.network"
      )
    )
  ),
  Network(
    id: "poa_rpc",
    etherscanLink: string.none,
    name: "Mainnet with upstream RPC",
    config: NetworkConfig(
      networkId: NetworkId.Poa,
      dataDir: "/ethereum/poa_rpc",
      upstreamConfig: UpstreamConfig(
        enabled: true,
        url: "https://core.poa.network"
      )
    )
  )]

const NODE_CONFIG* = fmt"""{{
  "BrowsersConfig": {{
    "Enabled": true
  }},
  "ClusterConfig": {{
    "Enabled": true
  }},
  "DataDir": "./ethereum/mainnet",
  "EnableNTPSync": true,
  "KeyStoreDir": "./keystore",
  "LogEnabled": true,
  "LogFile": "geth.log",
  "LogLevel": "INFO",
  "MailserversConfig": {{
    "Enabled": true
  }},
  "Name": "StatusDesktop",
  "NetworkId": 1,
  "NoDiscovery": false,
  "PermissionsConfig": {{
    "Enabled": true
  }},
  "Rendezvous": true,
  "RequireTopics": {{
    "whisper": {{
      "Max": 2,
      "Min": 2
    }}
  }},
  "ShhextConfig": {{
    "BackupDisabledDataDir": "./",
    "DataSyncEnabled": true,
    "InstallationID": "aef27732-8d86-5039-a32e-bdbe094d8791",
    "MailServerConfirmations": true,
    "MaxMessageDeliveryAttempts": 6,
    "PFSEnabled": true,
    "VerifyENSContractAddress": "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
    "VerifyENSURL": "wss://mainnet.infura.io/ws/v3/{INFURA_TOKEN}",
    "VerifyTransactionChainID": 1,
    "VerifyTransactionURL": "wss://mainnet.infura.io/ws/v3/{INFURA_TOKEN}"
  }},
  "StatusAccountsConfig": {{
    "Enabled": true
  }},
  "UpstreamConfig": {{
    "Enabled": true,
    "URL": "wss://mainnet.infura.io/ws/v3/{INFURA_TOKEN}"
  }},
  "WakuConfig": {{
    "BloomFilterMode": null,
    "Enabled": true,
    "LightClient": true,
    "MinimumPoW": 0.001
  }},
  "WalletConfig": {{
    "Enabled": true
  }}
}}"""

const DEFAULT_NETWORK_NAME* = "mainnet_rpc"
