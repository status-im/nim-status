import # vendor libs
  chronos, json_serialization

export json_serialization

type
  Context* = proc(): Future[void] {.gcsafe, nimcall.}
  Task* = proc(arg: string): Future[void] {.gcsafe, nimcall.}
  TaskKind* = enum async, async_rts, sync, sync_rts # rts == "return to sender"
  TaskArg* = ref object of RootObj
    kind*: TaskKind
    tptr*: ByteAddress # pointer to task proc
  TaskArgRts* = ref object of TaskArg
    cptr*: ByteAddress # pointer to return-channel for sender

# the reason it's important to have Context is that in a WorkerPool all of its
# threads need to be setup with the context; while for a WorkerThread that's
# easy to accomplish with an rts task that's called (by user of TaskRunner)
# immediately after the TaskRunner instance has finished starting, it's not so
# easily accomplished for a pool since the task would need to run in every
# thread. So that's effectively what Context is: a proc that will be called
# during thread/s startup of WorkerThread and WorkerPool; may eventually want
# to have ability to automatically serialize and send data from host thread to
# worker and pass it as arg to context, in which case Context signature would
# need to be `(arg: string): Future[void]`;
const emptyContext*: Context = proc() {.async, gcsafe, nimcall.} = discard

proc decode*[T](arg: string): T =
  Json.decode(arg, T, allowUnknownFields = true)

proc encode*[T](arg: T): string =
  arg.toJson(typeAnnotations = true)
