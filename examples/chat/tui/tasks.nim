import # chat libs
  ./common

export common

logScope:
  topics = "chat"

# EventTUI types are defined in ./common because procs in this module and
# `dispatch` et al. in ./events make use of them

type
  ReadInputTaskArg = ref object of TaskArg

const readInputTask: Task = proc(argEnc: string) {.async, gcsafe, nimcall.} =
  let
    arg = decode[ReadInputTaskArg](argEnc)
    chanSendToHost = cast[WorkerChannel](arg.chanSendToHost)

  var running = cast[ptr Atomic[bool]](arg.running)

  while running[].load():
    echo "hi from readInputTask"
    await chanSendToHost.send("hi".encode.safe)
    await sleepAsync 1.seconds

proc readInput*(taskRunner: TaskRunner, workerName: string) {.async.} =
  let
    worker = taskRunner.workers[workerName].worker
    chanSendToHost = worker.chanRecvFromWorker
    chanSendToWorker = worker.chanSendToWorker
    arg = ReadInputTaskArg(
      chanSendToHost: cast[ByteAddress](chanSendToHost),
      name: "readInputTask",
      running: cast[ByteAddress](addr taskRunner.running),
      task: cast[ByteAddress](readInputTask)
    )

  await chanSendToWorker.send(arg.encode.safe)
