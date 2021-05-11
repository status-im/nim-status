import # chat libs
  ./common

export common

logScope:
  topics = "chat"

# TUI Event types are defined in ./common because procs in this module and
# `dispatch` et al. in ./events make use of them

type
  ReadInputTaskArg = ref object of TaskArg

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

  # assume the terminal uses UTF-8 encoding; which encoding is actually used by
  # the terminal/environment/OS that launched the chat program should probably
  # be detected early in ../../chat and if it's not UTF-8 then the chat program
  # should exit immediately with an error/explanation; it could be possible to
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
      var eventEnc: string
      if input > 255:
        let event = InputKeyEvent(key: input, name: $keyname(input.cint))
        eventEnc = event.encode
        trace "task sent event to host", event=eventEnc, task
        asyncSpawn chanSendToHost.send(eventEnc.safe)
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
          let event = InputStringEvent(str: cast[string](bytes))
          eventEnc = event.encode
          trace "task sent event to host", event=eventEnc, task
          asyncSpawn chanSendToHost.send(eventEnc.safe)
          bytes = @[]
          expected = 1

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
