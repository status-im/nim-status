import # chat libs
  ../task_runner

type
  HelloTaskArg = ref object of TaskArg
    to: string

# `no_rts` task
const helloTaskImpl: Task = proc(argEncoded: string) {.async, gcsafe, nimcall.} =
  let arg = decode[HelloTaskArg](argEncoded)
  echo "!!! this is " & arg.tname  & " saying 'hello' to " & arg.to & " !!!"

proc helloTask*(taskRunner: TaskRunner, workerName: string, to: string) =
  let worker = cast[WorkerThread](taskRunner.workers[workerName].worker)
  let arg = HelloTaskArg(
    hcptr: cast[ByteAddress](cast[pointer](worker.chanSendToThread)),
    tname: "helloTask",
    tptr: cast[ByteAddress](helloTaskImpl),
    to: to
  )
  worker.chanSendToThread.sendSync(arg.encode.safe)

# when `createTask` template/macro is implemented, would prefer to write
# something like...

# createTask "helloTask", taskRunner, workerName, no_rts, (to: string):
#   echo "!!! this is " & arg.tname  & " saying 'hello' to " & arg.to & " !!!"

# NOTE: would need helper template in this module that wraps `createTask`;
# `helloTask` would likely itself be that helper template instead of being a
# proc

# ------------------------------------------------------------------------------

proc experimentalContext*(arg: ContextArg) {.async, gcsafe, nimcall.} =
  var someName {.threadvar.}: string
  someName = "baz"
  echo "theoretically I set the context"

type
  Hello2TaskArg = ref object of TaskArg

# `no_rts` task
const hello2TaskImpl: Task = proc(argEncoded: string) {.async, gcsafe, nimcall.} =
  var someName {.threadvar.}: string # init'd by the context proc
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
