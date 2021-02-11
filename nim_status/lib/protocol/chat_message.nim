import macros
import strutils
import protobuf_serialization
import protobuf_serialization/files/type_generator
from protocol import nil

import_proto3 "chat_message.proto"

proc decode*(T: type ChatMessage, input: seq[byte]): ChatMessage =
  Protobuf.decode(input, ChatMessage)

proc toChatMessage(self: seq[byte]): ChatMessage =
  ChatMessage.decode(self)

proc getChatMessage*(self: protocol.ApplicationMetadataMessage): ChatMessage =
  if self.`type` != protocol.Type.CHAT_MESSAGE: 
    raise newException(ValueError, "Message type is not a CHAT_MESSAGE")
  self.payload.toChatMessage()

proc getSticker*(self: ChatMessage): StickerMessage =
  if self.content_type != ContentType.STICKER: 
    raise newException(ValueError, "ChatMessage content type is not STICKER")
  return self.sticker

proc getImage*(self: ChatMessage): ImageMessage =
  if self.content_type != ContentType.IMAGE: 
    raise newException(ValueError, "ChatMessage content type is not IMAGE")
  return self.image

proc getAudio*(self: ChatMessage): AudioMessage =
  if self.content_type != ContentType.AUDIO: 
    raise newException(ValueError, "ChatMessage content type is not AUDIO")
  return self.audio
