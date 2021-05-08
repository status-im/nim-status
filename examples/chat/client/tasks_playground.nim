import # chat libs
  ./events

export events

logScope:
  topics = "chat"

# This module was used to experiment with patterns for no_rts and rts tasks. At
# present it's kept around for easy reference but will eventually be removed.

# When `createTask` template/macro is implemented, would prefer to write
# something like...

# createTask "helloTask", no_rts, (to: string):
#   let
#     taskName = arg.name
#     to = arg.to
#   echo "!!! this is " & name  & " saying 'hello' to " & arg.to & " !!!"

# no_rts -----------------------------------------------------------------------

type
  HelloTaskArg = ref object of TaskArg
    to: string

const helloTaskImpl: Task = proc(argEncoded: string) {.async, gcsafe, nimcall.} =
  let arg = decode[HelloTaskArg](argEncoded)
  echo "!!! this is " & arg.name  & " saying 'hello' to " & arg.to & " !!!"

proc helloTask*(taskRunner: TaskRunner, workerName: string, to: string) =
  let
    worker = taskRunner.workers[workerName].worker
    chanSendToHost = worker.chanRecvFromWorker
    chanSendToWorker = worker.chanSendToWorker
    arg = HelloTaskArg(
      chanSendToHost: cast[ByteAddress](chanSendToHost),
      name: "helloTask",
      running: cast[ByteAddress](addr taskRunner.running),
      task: cast[ByteAddress](helloTaskImpl),
      to: to
    )

  chanSendToWorker.sendSync(arg.encode.safe)

# no_rts -----------------------------------------------------------------------

var someName {.threadvar.}: string

proc hello2Context*(arg: ContextArg) {.async, gcsafe, nimcall.} =
  someName = "baz"

type
  Hello2TaskArg = ref object of TaskArg

const hello2TaskImpl: Task = proc(argEncoded: string) {.async, gcsafe, nimcall.} =
  let arg = decode[Hello2TaskArg](argEncoded)
  echo "!!! this is " & arg.name  & " saying 'hello' to " & someName & " !!!"

proc hello2Task*(taskRunner: TaskRunner, workerName: string) =
  let
    worker = taskRunner.workers[workerName].worker
    chanSendToHost = worker.chanRecvFromWorker
    chanSendToWorker = worker.chanSendToWorker
    arg = Hello2TaskArg(
      chanSendToHost: cast[ByteAddress](chanSendToHost),
      name: "hello2Task",
      running: cast[ByteAddress](addr taskRunner.running),
      task: cast[ByteAddress](hello2TaskImpl)
    )

  chanSendToWorker.sendSync(arg.encode.safe)

# rts --------------------------------------------------------------------------

type
  Hello3TaskArg = ref object of TaskArgRts
    to: string

const hello3TaskImpl: Task = proc(argEncoded: string) {.async, gcsafe, nimcall.} =
  let
    arg = decode[Hello3TaskArg](argEncoded)
    chanReturnToSender = cast[WorkerChannel](arg.chanReturnToSender)

  chanReturnToSender.open()
  await chanReturnToSender.send((arg.to & " YADA YADA YADA").encode.safe)
  chanReturnToSender.close()

proc hello3Task*(taskRunner: TaskRunner, workerName: string,
  to: string): Future[string] {.async.} =
  let
    worker = taskRunner.workers[workerName].worker
    chanReturnToSender = newWorkerChannel()
    chanSendToHost = worker.chanRecvFromWorker
    chanSendToWorker = worker.chanSendToWorker
    arg = Hello3TaskArg(
      chanSendToHost: cast[ByteAddress](chanSendToHost),
      name: "hello3Task",
      running: cast[ByteAddress](addr taskRunner.running),
      task: cast[ByteAddress](hello3TaskImpl),
      chanReturnToSender: cast[ByteAddress](chanReturnToSender),
      to: to
    )

  chanReturnToSender.open()
  await chanSendToWorker.send(arg.encode.safe)
  let res = decode[string]($(await chanReturnToSender.recv()))
  chanReturnToSender.close()
  return res

proc hello3TaskSync*(taskRunner: TaskRunner, workerName: string,
  to: string): string =
  let
    worker = taskRunner.workers[workerName].worker
    chanReturnToSender = newWorkerChannel()
    chanSendToHost = worker.chanRecvFromWorker
    chanSendToWorker = worker.chanSendToWorker
    arg = Hello3TaskArg(
      chanSendToHost: cast[ByteAddress](chanSendToHost),
      name: "hello3Task",
      running: cast[ByteAddress](addr taskRunner.running),
      task: cast[ByteAddress](hello3TaskImpl),
      chanReturnToSender: cast[ByteAddress](chanReturnToSender),
      to: to
    )

  chanReturnToSender.open()
  chanSendToWorker.sendSync(arg.encode.safe)
  let res = decode[string]($chanReturnToSender.recvSync())
  chanReturnToSender.close()
  return res

# no_rts -----------------------------------------------------------------------

var counter {.threadvar.}: int

proc hello4Context*(arg: ContextArg) {.async, gcsafe, nimcall.} =
  counter = 0

type
  Hello4TaskArg = ref object of TaskArg

const hello4TaskImpl: Task = proc(argEncoded: string) {.async, gcsafe, nimcall.} =
  let
    arg = decode[Hello4TaskArg](argEncoded)
    chanSendToHost = cast[WorkerChannel](arg.chanSendToHost)

  var running = cast[ptr Atomic[bool]](arg.running)

  while running[].load():
    counter = counter + 1
    await chanSendToHost.send(counter.encode.safe)
    await sleepAsync 1.milliseconds

proc hello4Task*(taskRunner: TaskRunner, workerName: string) =
  let
    worker = taskRunner.workers[workerName].worker
    chanSendToHost = worker.chanRecvFromWorker
    chanSendToWorker = worker.chanSendToWorker
    arg = Hello4TaskArg(
      chanSendToHost: cast[ByteAddress](chanSendToHost),
      name: "hello4Task",
      running: cast[ByteAddress](addr taskRunner.running),
      task: cast[ByteAddress](hello4TaskImpl)
    )

  chanSendToWorker.sendSync(arg.encode.safe)
