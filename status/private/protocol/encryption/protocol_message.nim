import # vendor libs
  protobuf_serialization

export protobuf_serialization

# status protobuf spec
# automatically exports `type ProtocolMessage`
import_proto3 "protobuf/protocol_message.proto"

proc decode*(T: type ProtocolMessage, input: seq[byte]): T =
  Protobuf.decode(input, T)

proc encode*(input: ProtocolMessage): seq[byte] =
  Protobuf.encode(input)
