import # std libs
  std/[sets, strformat, strutils]

# std libs
from times import getTime, toUnix

import # vendor libs
  chronicles, chronos, task_runner

import # status lib
  status/api/common

import # client modules
  ./config

export # modules
  chronicles, chronos, common, config, sets, strformat, strutils, task_runner

export # symbols
  getTime, toUnix

type
  Event* = ref object of RootObj
    timestamp*: int64

  EventChannel* = AsyncChannel[ThreadSafeString]

proc newEventChannel*(): EventChannel = newAsyncChannel[ThreadSafeString](-1)
