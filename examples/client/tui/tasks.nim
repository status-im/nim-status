import # vendor libs
  stew/byteutils

import # client libs
  ./common

export common

logScope:
  topics = "tui"

const
  ESCAPE* = "ESCAPE"
  RETURN* = "RETURN"

type ByteArray = array[0..3, byte]

proc readInput*() {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  var
    bytes: ByteArray
    expected = 1
    got = 0
    input = 0

  let
    event = InputReady(ready: true)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

  # assume terminal uses UTF-8 encoding; which encoding is actually used by the
  # terminal/env/OS that launched the client program should probably be detected
  # early in ../../client and if it's not UTF-8 then the client program should
  # maybe exit immediately with an error/explanation; it could be possible to
  # support other terminal/environment/OS encodings, but for now this is a
  # simplifying assumption for the sake of implementing `readInput`

  while workerRunning[].load():
    if input != -1: trace "task waiting for input", task
    input = getch().int
    if not workerRunning[].load():
      trace "task stopped", task
      break
    if input != -1:
      trace "task received input", input, task
      var
        eventEnc: string
        shouldSend = false
      if input > 255 or input == 10 or input == 27:
        var event: InputKey
        if input == 10:
          event = InputKey(key: input, name: RETURN)
        elif input == 27:
          event = InputKey(key: input, name: ESCAPE)
        else:
          event = InputKey(key: input, name: $keyname(input.cint))
        eventEnc = event.encode
        shouldSend = true

      else:
        if expected == 1:
          if input >= 240:
            expected = 4
          elif input >= 224:
            expected = 3
          elif input >= 192:
            expected = 2

        bytes[got] = input.byte
        got = got + 1

        if got == expected:
          let event = InputString(
            str: string.fromBytes(bytes[0..(expected - 1)]))
          eventEnc = event.encode
          shouldSend = true
          expected = 1
          got = 0

      if shouldSend:
        trace "task sent event to host", event=eventEnc, task
        asyncSpawn chanSendToHost.send(eventEnc.safe)