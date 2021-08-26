import # std libs
  std/[sets, strformat, strutils, sugar, times]

import # vendor libs
  task_runner,
  nimcrypto/keccak

import # status lib
  status/api/accounts

import # client modules
  ../config

export accounts, config, sets, strformat, strutils, task_runner, times

logScope:
  topics = "client"

type
  Event* = ref object of RootObj

  EventChannel* = AsyncChannel[ThreadSafeString]

  # TODO: alphabetise Client above HelpText -- didn't want to interfere with
  # ongoing work
  Client* = ref object
    account*: PublicAccount
    clientConfig*: ClientConfig
    events*: EventChannel
    loggedin*: bool
    online*: bool
    running*: bool
    taskRunner*: TaskRunner
    topics*: OrderedSet[string]
    chats*: Table[string, string]

const
  hashCharSet* = {'#'}
  status* = "status"

proc handleTopic*(topic: string, protocol="proto"): string =
  var t = topic
  let topicSplit = topic.split('/')

  # if event.topic is a properly formatted waku v2 content topic then the
  # whole string will be passed to joinTopic
  if topicSplit.len != 5 or topicSplit[0] != "":
    # otherwise convert it to a properly formatted content topic
    t = topic.strip(true, false, hashCharSet)
    # should end with `/rlp` for real encoding and decoding
    if t != "":
      let hexTopic = "0x" & ($keccak256.digest(t))[0..7].toLowerAscii
      t = fmt"/waku/1/{hexTopic}/{protocol}"

  return t

proc newEventChannel*(): EventChannel =
  newAsyncChannel[ThreadSafeString](-1)
