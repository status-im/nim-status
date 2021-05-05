import # chat libs
  ../task_runner

# Everything below is experimental atm

# ------------------------------------------------------------------------------

type
  HelloTaskArg = ref object of TaskArg
    to: string

# `no_rts` task
const helloTaskImpl: Task = proc(argEncoded: string) {.async, gcsafe, nimcall.} =
  let arg = decode[HelloTaskArg](argEncoded)
  echo "!!! this is " & arg.tname  & " saying 'hello' to " & arg.to & " !!!"

proc helloTask*(taskRunner: TaskRunner, workerName: string, to: string) =
  var
    chanToHost: WorkerChannel
    chanToWorker: WorkerChannel
  let
    kind = taskRunner.workers[workerName].kind
    worker = taskRunner.workers[workerName].worker

  case kind
    of pool:
      let workerPool = cast[PoolWorker](worker)
      chanToHost = workerPool.chanRecvFromPool
      chanToWorker = workerPool.chanSendToPool
    of thread:
      let workerThread = cast[ThreadWorker](worker)
      chanToHost = workerThread.chanRecvFromThread
      chanToWorker = workerThread.chanSendToThread

  let arg = HelloTaskArg(
    # does it need to be `cast[ByteAddress](cast[pointer](chanToHost))` ?
    # when implementing example `rts` task can check
    hcptr: cast[ByteAddress](chanToHost),
    tname: "helloTask",
    tptr: cast[ByteAddress](helloTaskImpl),
    to: to
  )
  chanToWorker.sendSync(arg.encode.safe)

# when `createTask` template/macro is implemented, would prefer to write
# something like...

# createTask "helloTask", taskRunner, workerName, no_rts, (to: string):
#   echo "!!! this is " & arg.tname  & " saying 'hello' to " & arg.to & " !!!"

# NOTE: would need helper template in this module that wraps `createTask`;
# `helloTask` would likely itself be that helper template instead of being a
# proc

# ------------------------------------------------------------------------------

# maybe global decl involving `{.threadvar.}` could be wrapped inside a
# `createContext` template/macro

var someName {.threadvar.}: string

proc experimentalContext*(arg: ContextArg) {.async, gcsafe, nimcall.} =
  someName = "baz"

type
  Hello2TaskArg = ref object of TaskArg

# `no_rts` task
const hello2TaskImpl: Task = proc(argEncoded: string) {.async, gcsafe, nimcall.} =
  let arg = decode[Hello2TaskArg](argEncoded)
  echo "!!! this is " & arg.tname  & " saying 'hello' to " & someName & " !!!"

proc hello2Task*(taskRunner: TaskRunner, workerName: string) =
  let worker = cast[ThreadWorker](taskRunner.workers[workerName].worker)
  let arg = Hello2TaskArg(
    hcptr: cast[ByteAddress](worker.chanSendToThread),
    tname: "hello2Task",
    tptr: cast[ByteAddress](hello2TaskImpl)
  )
  worker.chanSendToThread.sendSync(arg.encode.safe)
