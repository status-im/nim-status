{.push raises: [Defect].}

import # vendor libs
  eth/keys, protobuf_serialization

export protobuf_serialization

# status protobuf spec
# automatically exports `type ChatMessage`
import_proto3 "protobuf/chat_message.proto"

type
  PublicChatMessage* = object
    alias*: string
    message*: ChatMessage
    pubkey*: PublicKey
    timestamp*: int64

  PublicChatMessageError* = enum
    BadKey        = "pubchat: symmetric key derived from content topic had " &
                      "incorrect length"
    DecodeFailed  = "pubchat: failed to decode message protobuf"
    DecryptFailed = "pubchat: failed to decrypt message payload"
    NoAlias       = "pubchat: failed to generate alias from public key in " &
                      "message"
    NoPublicKey   = "pubchat: failed to get public key from message"

proc decode*(T: type ChatMessage, input: seq[byte]):
  T {.raises: [Defect, ProtobufReadError].} =

  Protobuf.decode(input, T)

proc encode*(input: ChatMessage): seq[byte] =
  Protobuf.encode(input)
