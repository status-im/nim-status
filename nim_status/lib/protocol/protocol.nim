import macros
import strutils
import protobuf_serialization
import protobuf_serialization/files/type_generator

import_proto3 "protocol_message.proto"
import_proto3 "application_metadata_message.proto"

# to use: let x: ProtocolMessage = ProtocolMessage.decode(...)
proc decode*(T: type ProtocolMessage, input: seq[byte]): ProtocolMessage =
  Protobuf.decode(input, ProtocolMessage)

proc toProtocolMessage*(self: seq[byte]): ProtocolMessage =
  ProtocolMessage.decode(self)

proc decode*(T: type ApplicationMetadataMessage, input: seq[byte]): ApplicationMetadataMessage =
  Protobuf.decode(input, ApplicationMetadataMessage)

proc toApplicationMetadataMessage*(self: seq[byte]): ApplicationMetadataMessage =
  ApplicationMetadataMessage.decode(self)

proc getPublicMessage*(self: ProtocolMessage): ApplicationMetadataMessage =
  self.public_message.toApplicationMetadataMessage()

proc getMessageType*(self: ApplicationMetadataMessage): Type =
  self.`type`
