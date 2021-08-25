import # status lib
  status/api/[accounts, networks, opensea, tokens, wallet]

import # client modules
  ./common

logScope:
  topics = "client"

type
  ClientEvent* = ref object of Event

  AddCustomTokenEvent* = ref object of ClientEvent
    address*: string
    color*: string
    decimals*: uint
    error*: string
    name*: string
    symbol*: string

  AddWalletAccountEvent* = ref object of ClientEvent
    address*: Address
    name*: string
    error*: string

  CreateAccountEvent* = ref object of ClientEvent
    account*: PublicAccount
    error*: string

  DeleteCustomTokenEvent* = ref object of ClientEvent
    address*: string
    error*: string

  CallRpcEvent* = ref object of ClientEvent
    error*: string
    response*: string

  GetAssetsEvent* = ref object of ClientEvent
    assets*: seq[Asset]
    error*: string

  GetCustomTokensEvent* = ref object of ClientEvent
    error*: string
    tokens*: seq[Token]

  DeleteWalletAccountEvent* = ref object of ClientEvent
    address*: string
    error*: string
    name*: string

  GetPriceEvent* = ref object of ClientEvent
    currency*: string
    error*: string
    price*: float
    symbol*: string

  ImportMnemonicEvent* = ref object of ClientEvent
    account*: PublicAccount
    error*: string

  JoinTopicEvent* = ref object of ClientEvent
    topic*: ContentTopic

  LeaveTopicEvent* = ref object of ClientEvent
    topic*: ContentTopic

  ListAccountsEvent* = ref object of ClientEvent
    accounts*: seq[PublicAccount]
    error*: string

  ListNetworksEvent* = ref object of ClientEvent
    networks*: seq[Network]
    error*: string

  ListWalletAccountsEvent* = ref object of ClientEvent
    accounts*: seq[WalletAccount]
    error*: string

  LoginEvent* = ref object of ClientEvent
    account*: PublicAccount
    error*: string
    loggedin*: bool

  LogoutEvent* = ref object of ClientEvent
    error*: string
    loggedin*: bool

  WakuConnectionEvent* = ref object of ClientEvent
    error*: string
    online*: bool

  SendMessageEvent* = ref object of ClientEvent
    error*: string
    sent*: bool

  SendTransactionEvent* = ref object of ClientEvent
    error*: string
    response*: string

  SetPriceTimeoutEvent* = ref object of ClientEvent
    error*: string
    timeout*: int

  SwitchNetworkEvent* = ref object of ClientEvent
    error*: string
    networkId*: string

  UserMessageEvent* = ref object of ClientEvent
    message*: string
    topic*: ContentTopic
    username*: string

const
  clientEvents* = [
    "AddCustomTokenEvent",
    "AddWalletAccountEvent",
    "CallRpcEvent",
    "CreateAccountEvent",
    "DeleteCustomTokenEvent",
    "DeleteWalletAccountEvent",
    "GetCustomTokensEvent",
    "GetAssetsEvent",
    "GetPriceEvent",
    "ImportMnemonicEvent",
    "JoinTopicEvent",
    "LeaveTopicEvent",
    "ListAccountsEvent",
    "ListNetworksEvent",
    "ListWalletAccountsEvent",
    "LoginEvent",
    "LogoutEvent",
    "SendMessageEvent",
    "SendTransactionEvent",
    "SetPriceTimeoutEvent",
    "SwitchNetworkEvent",
    "UserMessageEvent",
    "WakuConnectionEvent"
  ]

  status = "status"

proc listenToStatus(self: Client) {.async.} =
  let worker = self.taskRunner.workers[status].worker
  while self.running and self.taskRunner.running.load():
    let event = await worker.chanRecvFromWorker.recv()
    asyncSpawn self.events.send(event)

proc listen*(self: Client) {.async.} =
  asyncSpawn self.listenToStatus()
