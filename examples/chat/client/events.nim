import # vendor libs
  web3/ethtypes

import # chat libs
  ./common

import # nim-status libs
  ../../../nim_status/client

export common

logScope:
  topics = "chat client"

type
  ClientEvent* = ref object of Event

  AddWalletAccountEvent* = ref object of ClientEvent
    name*: string
    address*: Address
    error*: string
    timestamp*: int64

  CreateAccountEvent* = ref object of ClientEvent
    account*: PublicAccount
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
  "AddWalletAccountEvent",
  "CreateAccountEvent",
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

proc listenToStatus(self: ChatClient) {.async.} =
  let worker = self.taskRunner.workers["status"].worker
  while self.running and self.taskRunner.running.load():
    let event = await worker.chanRecvFromWorker.recv()
    asyncSpawn self.events.send(event)

proc listen*(self: ChatClient) {.async.} =
  asyncSpawn self.listenToStatus()
