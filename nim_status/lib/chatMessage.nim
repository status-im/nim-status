import macros
import strutils
import protobuf_serialization
import protobuf_serialization/files/type_generator


import_proto3 "chat_message.proto"

proc decodeChatMessage*(input: seq[byte]): ChatMessage =
  Protobuf.decode(input, ChatMessage)
