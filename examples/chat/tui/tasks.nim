import # chat libs
  ./common

export common

logScope:
  topics = "chat"

type
  ReadInputTaskArg = ref object of TaskArg

const
  ESCAPE* = "ESCAPE"
  RETURN* = "RETURN"

const readInputTask: Task = proc(argEnc: string) {.async, gcsafe, nimcall.} =
  let
    arg = decode[ReadInputTaskArg](argEnc)
    chanSendToHost = cast[WorkerChannel](arg.chanSendToHost)
    task = arg.name

  var
    bytes: seq[byte] = @[]
    discarded = false
    expected = 1
    input = 0
    running = cast[ptr Atomic[bool]](arg.running)

  let
    event = InputReady(ready: true)
    eventEnc = event.encode

  trace "task sent event to host", event=eventEnc, task
  asyncSpawn chanSendToHost.send(eventEnc.safe)

  # assume terminal uses UTF-8 encoding; which encoding is actually used by the
  # terminal/env/OS that launched the chat program should probably be detected
  # early in ../../chat and if it's not UTF-8 then the chat program should
  # maybe exit immediately with an error/explanation; it could be possible to
  # support other terminal/environment/OS encodings, but for now this is a
  # simplifying assumption for the sake of implementing `readInputTask`

  while running[].load():
    if input != -1: trace "task waiting for input", task
    input = getch().int
    if not running[].load():
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

        bytes.add input.byte

        if bytes.len == expected:
          let event = InputString(str: cast[string](bytes))
          eventEnc = event.encode
          shouldSend = true
          bytes = @[]
          expected = 1

      if shouldSend:
        trace "task sent event to host", event=eventEnc, task
        asyncSpawn chanSendToHost.send(eventEnc.safe)

proc readInput*(taskRunner: TaskRunner, workerName: string) {.async.} =
  let
    worker = taskRunner.workers[workerName].worker
    chanSendToHost = worker.chanRecvFromWorker
    chanSendToWorker = worker.chanSendToWorker
    arg = ReadInputTaskArg(
      chanSendToHost: cast[ByteAddress](chanSendToHost),
      name: "readInput",
      running: cast[ByteAddress](addr taskRunner.running),
      task: cast[ByteAddress](readInputTask)
    )

  asyncSpawn chanSendToWorker.send(arg.encode.safe)
