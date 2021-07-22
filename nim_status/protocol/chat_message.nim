import # vendor libs
  protobuf_serialization

export protobuf_serialization

# nim-status protobuf spec
# automatically exports `type ChatMessage`
import_proto3 "protobuf/chat_message.proto"

proc decode*(T: type ChatMessage, input: seq[byte]): T =
  Protobuf.decode(input, T)

proc encode*(input: ChatMessage): seq[byte] =
  Protobuf.encode(input)
