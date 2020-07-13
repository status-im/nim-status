{.passL:"vendor/status-go/build/bin/libstatus.a"}

import ../src/nim_status
import utils
import chronicles
import os

var onSignal: SignalCallback = proc(message: cstring) {.cdecl.} = 
  setupForeignThreadGC()
  echo message
  tearDownForeignThreadGc()
setSignalEventCallback(onSignal)

resetDirectories() # Recreates the data and nobackup dir

init()

# Call either createAccountAndLogin("somePassword") to create a new random account
# or restoreAccountAndLogin("cattle act enable unable own music material canvas either shoe must junior", "somePassword")
# if no password is specified, it will use "qwerty"

let publicKey = createAccountAndLogin("somePassword")


# There's a login("somePassword") function that will login the first account. It assumes the directories have been already set.


# TODO: wait for a {"type":"node.login" signal to know that you have already logged in. These signals are available in onSignal ^
while true:

  echo "..."
  sleep(1000)



