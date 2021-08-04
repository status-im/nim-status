import # vendor libs
  protobuf_serialization

export protobuf_serialization

# status protobuf spec
# automatically exports `type ApplicationMetadataMessage`
import_proto3 "protobuf/application_metadata_message.proto"

proc decode*(T: type ApplicationMetadataMessage, input: seq[byte]): T =
  Protobuf.decode(input, T)

proc encode*(input: ApplicationMetadataMessage): seq[byte] =
  Protobuf.encode(input)
