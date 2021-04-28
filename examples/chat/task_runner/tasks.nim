import # vendor libs
  chronos, json_serialization

export json_serialization

type
  Task* = proc(arg: string): Future[void] {.gcsafe, nimcall.}
  TaskKind* = enum async, async_rts, sync, sync_rts # rts == "return to sender"
  TaskArg* = ref object of RootObj
    kind*: TaskKind
    tptr*: ByteAddress # pointer to task proc
  TaskArgRts* = ref object of TaskArg
    cptr*: ByteAddress # pointer to return-channel for sender

proc decode*[T](arg: string): T =
  Json.decode(arg, T, allowUnknownFields = true)

proc encode*[T](arg: T): string =
  arg.toJson(typeAnnotations = true)
