{.push raises: [Defect].}

import # vendor libs
  chronicles, json_serialization

import # status modules
   ./common, ./protocol

logScope:
  topics = "status_private"

type
  StatusEvent* = ref object of RootObj
    timestamp*: int64

  StatusDataEvent*[T] = ref object of StatusEvent
    data*: T

  StatusErrorEvent*[T] = ref object of StatusEvent
    error*: T

  StatusEventKind* = enum
    chat2Message
    chat2MessageError
    publicChatMessage
    publicChatMessageError

  StatusSignal* = tuple[event: StatusEvent, kind: StatusEventKind]

  StatusSignalHandler* = proc(signal: StatusSignal):
    Future[void] {.gcsafe, nimcall.}

  StatusMessageEvent*[T] = ref object of StatusDataEvent[T]
    topic*: ContentTopic

  StatusMessageErrorEvent*[T] = ref object of StatusErrorEvent[T]
    topic*: ContentTopic

  Chat2MessageEvent* = StatusMessageEvent[Chat2Message]

  Chat2MessageErrorEvent* = StatusMessageErrorEvent[Chat2MessageError]

  PublicChatMessageEvent* = StatusMessageEvent[PublicChatMessage]

  PublicChatMessageErrorEvent* = StatusMessageErrorEvent[PublicChatMessageError]

proc encode[T](arg: T): string {.raises: [Defect, IOError].} =
  arg.toJson(typeAnnotations = true)

const defaultStatusSignalHandler*: StatusSignalHandler =
  proc(signal: StatusSignal) {.async, gcsafe, nimcall.} =
    let kind = signal.kind

    try:
      case kind:
        of chat2Message:
          let data = cast[Chat2MessageEvent](signal.event).data
          trace "received data signal", kind, data

        of chat2MessageError:
          let error = cast[Chat2MessageErrorEvent](signal.event).error
          trace "received error signal", kind, error

        of publicChatMessage:
          let data = cast[PublicChatMessageEvent](signal.event).data
          trace "received data signal", kind, data

        of publicChatMessageError:
          let error = cast[PublicChatMessageErrorEvent](signal.event).error
          trace "received error signal", kind, error

    except IOError as e:
      error "failed to encode signal.event for log", kind, error=e.msg
