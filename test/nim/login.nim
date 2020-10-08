import ../../nim_status
import test_helpers
import utils

import chronos
import os
import unittest

var success = false

proc checkMessage(message: string): void =
  echo "SIGNAL RECEIVED:\n" & message
  if message == """{"type":"node.login","event":{}}""":
    success = true

procSuite "nim_status":
  asyncTest "login":
    var onSignal = proc(message: cstring) {.cdecl.} =
      setupForeignThreadGC()
      checkMessage($message)
      tearDownForeignThreadGc()

    setSignalEventCallback(onSignal)
    resetDirectories() # Recreates the data and nobackup dir
    init()

    # Call either `createAccountAndLogin("somePassword")` to create a new random account
    # Or: `restoreAccountAndLogin("cattle act enable unable own music material canvas either shoe must junior", "somePassword")`
    # If no password is specified, it will use "qwerty"
    # There's a `login("somePassword")` function that will login the first
    # account. It assumes the directories have been already set.
    discard createAccountAndLogin("somePassword")

    var seconds = 0

    while seconds < 300:
      if success:
        break
      echo "..."
      sleep 1000
      seconds += 1

    check:
      success == true
