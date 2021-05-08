import # vendor libs
  chronos, json_serialization

export json_serialization

type
  ContextArg* = ref object of RootObj
  Context* = proc(arg: ContextArg): Future[void] {.gcsafe, nimcall.}
  Task* = proc(arg: string): Future[void] {.gcsafe, nimcall.}
  TaskKind* = enum no_rts, rts # rts := "return to sender"
  TaskArg* = ref object of RootObj
    chanSendToHost*: ByteAddress # pointer to channel for sending to host
    name*: string # name of task
    running*: ByteAddress # pointer to task runner's `.running` Atomic[bool]
    task*: ByteAddress # pointer to task proc
  TaskArgRts* = ref object of TaskArg
    chanReturnToSender*: ByteAddress # pointer to return-channel for sender

const emptyContext*: Context =
  proc(arg: ContextArg) {.async, gcsafe, nimcall.} = discard

proc decode*[T](arg: string): T =
  Json.decode(arg, T, allowUnknownFields = true)

proc encode*[T](arg: T): string =
  arg.toJson(typeAnnotations = true)
