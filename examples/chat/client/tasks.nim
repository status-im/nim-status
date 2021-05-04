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
  var hcptr: ByteAddress
  let workerKind = taskRunner.workers[workerName].kind

  # !!!!!!!!! there's definitely a race condition in worker pool where
  # !!!!!!!!! sometimes helloTask is executed when went to a pool, but not
  # !!!!!!!!! always; probably a race re: taskQueue and allReady in worker_pool

  # the following code is ugly, but only serves the purpose of exploring how a
  # task could be executed on a WorkerThread or WorkerPool without the code
  # invoking the task needing to differentiate except for `workerName`; the
  # `createTask` template/macro should help paper over such complications
  case workerKind
    of pool:
      let worker = cast[WorkerPool](taskRunner.workers[workerName].worker)
      hcptr = cast[ByteAddress](cast[pointer](worker.chanRecvFromPool))
    of thread:
      let worker = cast[WorkerThread](taskRunner.workers[workerName].worker)
      hcptr = cast[ByteAddress](cast[pointer](worker.chanRecvFromThread))
  let arg = HelloTaskArg(
    hcptr: hcptr,
    tname: "helloTask",
    tptr: cast[ByteAddress](helloTaskImpl),
    to: to
  )
  case workerKind
    of pool:
      let worker = cast[WorkerPool](taskRunner.workers[workerName].worker)
      worker.chanSendToPool.sendSync(arg.encode.safe)
    of thread:
      let worker = cast[WorkerThread](taskRunner.workers[workerName].worker)
      worker.chanSendToThread.sendSync(arg.encode.safe)

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
  let worker = cast[WorkerThread](taskRunner.workers[workerName].worker)
  let arg = Hello2TaskArg(
    hcptr: cast[ByteAddress](cast[pointer](worker.chanSendToThread)),
    tname: "hello2Task",
    tptr: cast[ByteAddress](hello2TaskImpl)
  )
  worker.chanSendToThread.sendSync(arg.encode.safe)
