import # vendor libs
  stew/byteutils

import # client modules
  ./common

logScope:
  topics = "tui"

type ByteArray = array[0..3, byte]

proc readInput*() {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  var
    bytes: ByteArray
    expected = 1
    got = 0
    input = 0

  let
    event = InputReadyEvent(ready: true)
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
      if input > 255 or input == 8 or input == 10 or input == 27 or
         input == 127:
        var event: InputKeyEvent
        if input == 8:
          # interpret as backspace key
          event = InputKeyEvent(key: 263, name: $keyname(263.cint))
        elif input == 10:
          event = InputKeyEvent(key: input, name: RETURN)
        elif input == 27:
          event = InputKeyEvent(key: input, name: ESCAPE)
        elif input == 127:
          if defined(macosx):
            # interpret as backspace key
            event = InputKeyEvent(key: 263, name: $keyname(263.cint))
          else:
            # interpret as delete key
            event = InputKeyEvent(key: 330, name: $keyname(330.cint))
        else:
          event = InputKeyEvent(key: input, name: $keyname(input.cint))
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
          let event = InputStringEvent(
            str: string.fromBytes(bytes[0..(expected - 1)]))
          eventEnc = event.encode
          shouldSend = true
          expected = 1
          got = 0

      if shouldSend:
        trace "task sent event to host", event=eventEnc, task
        asyncSpawn chanSendToHost.send(eventEnc.safe)
