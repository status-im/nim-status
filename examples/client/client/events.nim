import # vendor libs
  web3/ethtypes

import # status lib
  status/api/[tokens, wallet]

import # client modules
  ./common

export common

logScope:
  topics = "client"

type
  ClientEvent* = ref object of Event

  AddCustomTokenEvent* = ref object of ClientEvent
    address*: string
    name*: string
    symbol*: string
    color*: string
    decimals*: uint
    error*: string
    timestamp*: int64

  AddWalletAccountEvent* = ref object of ClientEvent
    name*: string
    address*: Address
    error*: string
    timestamp*: int64

  CreateAccountEvent* = ref object of ClientEvent
    account*: PublicAccount
    error*: string
    timestamp*: int64

  DeleteCustomTokenEvent* = ref object of ClientEvent
    address*: string
    error*: string
    timestamp*: int64

  CallRpcEvent* = ref object of ClientEvent
    response*: string
    error*: string
    timestamp*: int64

  GetCustomTokensEvent* = ref object of ClientEvent
    tokens*: seq[Token]
    error*: string
    timestamp*: int64

  DeleteWalletAccountEvent* = ref object of ClientEvent
    name*: string
    address*: string
    error*: string
    timestamp*: int64

  ImportMnemonicEvent* = ref object of ClientEvent
    error*: string
    account*: PublicAccount
    timestamp*: int64

  JoinTopicEvent* = ref object of ClientEvent
    timestamp*: int64
    topic*: string

  LeaveTopicEvent* = ref object of ClientEvent
    timestamp*: int64
    topic*: string

  ListAccountsEvent* = ref object of ClientEvent
    accounts*: seq[PublicAccount]
    error*: string
    timestamp*: int64

  ListWalletAccountsEvent* = ref object of ClientEvent
    accounts*: seq[WalletAccount]
    error*: string
    timestamp*: int64

  LoginEvent* = ref object of ClientEvent
    account*: PublicAccount
    error*: string
    loggedin*: bool

  LogoutEvent* = ref object of ClientEvent
    error*: string
    loggedin*: bool

  NetworkStatusEvent* = ref object of ClientEvent
    online*: bool

  UserMessageEvent* = ref object of ClientEvent
    message*: string
    timestamp*: int64
    topic*: string
    username*: string

const clientEvents* = [
  "AddCustomTokenEvent",
  "AddWalletAccountEvent",
  "CallRpcEvent",
  "CreateAccountEvent",
  "DeleteCustomTokenEvent",
  "DeleteWalletAccountEvent",
  "GetCustomTokensEvent",
  "ImportMnemonicEvent",
  "JoinTopicEvent",
  "LeaveTopicEvent",
  "ListAccountsEvent",
  "ListWalletAccountsEvent",
  "LoginEvent",
  "LogoutEvent",
  "NetworkStatusEvent",
  "UserMessageEvent"
]

proc listenToStatus(self: Client) {.async.} =
  let worker = self.taskRunner.workers["status"].worker
  while self.running and self.taskRunner.running.load():
    let event = await worker.chanRecvFromWorker.recv()
    asyncSpawn self.events.send(event)

proc listen*(self: Client) {.async.} =
  asyncSpawn self.listenToStatus()
