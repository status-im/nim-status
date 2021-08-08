{.push raises: [Defect].}

import # std libs
  std/[json, options, sequtils, strutils, strformat, sugar]

import # vendor libs
  json_serialization,
  json_serialization/[lexer, reader, writer],
  sqlcipher

import # status modules
  ./chatmessages/common, ./conversions

export common

proc getMessageById*(db: DbConn, id: string): Option[Message] {.raises: [Defect,
  MessageDbError].} =

  const errorMsg = "Error getting message by id from the database"
  try:
    var tblMessages: Message
    let query = fmt"""SELECT   *
                      FROM     {tblMessages.tableName}
                      WHERE    {MessageCol.Id} = ?"""
    result = db.one(Message, query, id)
  except SqliteError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)

proc saveMessage*(db: DbConn, message: Message) {.raises: [MessageDbError].} =

  const errorMsg = "Error saving message in the database"

  try:
    var tblMessages: Message
    let query = fmt"""INSERT INTO   {tblMessages.tableName} (
                                    {MessageCol.Id},
                                    {MessageCol.WhisperTimestamp},
                                    {MessageCol.Source},
                                    {MessageCol.Destination},
                                    {MessageCol.Text},
                                    {MessageCol.ContentType},
                                    {MessageCol.Username},
                                    {MessageCol.Timestamp},
                                    {MessageCol.ChatId},
                                    {MessageCol.LocalChatId},
                                    {MessageCol.Hide},
                                    {MessageCol.ResponseTo},
                                    {MessageCol.MessageType},
                                    {MessageCol.ClockValue},
                                    {MessageCol.Seen},
                                    {MessageCol.OutgoingStatus},
                                    {MessageCol.ParsedText},
                                    {MessageCol.RawPayload},
                                    {MessageCol.StickerPack},
                                    {MessageCol.StickerHash},
                                    {MessageCol.CommandId},
                                    {MessageCol.CommandValue},
                                    {MessageCol.CommandAddress},
                                    {MessageCol.CommandFrom},
                                    {MessageCol.CommandContract},
                                    {MessageCol.CommandTransactionHash},
                                    {MessageCol.CommandSignature},
                                    {MessageCol.CommandState},
                                    {MessageCol.AudioPayload},
                                    {MessageCol.AudioType},
                                    {MessageCol.AudioDurationMs},
                                    {MessageCol.AudioBase64},
                                    {MessageCol.ReplaceMessage},
                                    {MessageCol.Rtl},
                                    {MessageCol.LineCount},
                                    {MessageCol.Links},
                                    {MessageCol.Mentions},
                                    {MessageCol.ImagePayload},
                                    {MessageCol.ImageType},
                                    {MessageCol.ImageBase64})
                      VALUES        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                                    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                                    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"""
    db.exec(query,
      message.id,
      message.whisperTimestamp,
      message.source,
      message.destination,
      message.text,
      message.contentType,
      message.username,
      message.timestamp,
      message.chatId,
      message.localChatId,
      message.hide,
      message.responseTo,
      message.messageType,
      message.clockValue,
      message.seen,
      message.outgoingStatus,
      message.parsedText,
      message.rawPayload,
      message.stickerPack,
      message.stickerHash,
      message.commandId,
      message.commandValue,
      message.commandAddress,
      message.commandFrom,
      message.commandContract,
      message.commandTransactionHash,
      message.commandSignature,
      message.commandState,
      message.audioPayload,
      message.audioType,
      message.audioDurationMs,
      message.audioBase64,
      message.replaceMessage,
      message.rtl,
      message.lineCount,
      message.links,
      message.mentions,
      message.imagePayload,
      message.imageType,
      message.imageBase64)
  except SqliteError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)

proc deleteContactMessages*(db: DbConn, contactId: string) {.raises:
  [MessageDbError].} =

  const errorMsg = "Error deleting contact messages"
  try:
    var message: Message
    let query = fmt"""DELETE
                      FROM    {message.tableName}
                      WHERE   {MessageCol.Source} = ?"""

    db.exec(query, contactId)
  except SqliteError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)

proc deleteMessage*(db: DbConn, message: Message) {.raises: [MessageDbError].} =

  try:
    var tblMessage: Message
    let query = fmt"""DELETE
                      FROM    {tblMessage.tableName}
                      WHERE   {MessageCol.Id} = ?"""

    db.exec(query, message.id)
  except SqliteError as e:
    raise (ref MessageDbError)(parent: e, msg: "Error deleting message")
  except ValueError as e:
    raise (ref MessageDbError)(parent: e, msg: "Error deleting message")

proc markAllRead*(db: DbConn, chatId: string) {.raises: [MessageDbError].} =

  const errorMsg = "Error marking all messages as read"
  try:
    var message: Message
    let query = fmt"""UPDATE  {message.tableName}
                      SET     {MessageCol.Seen} = 1
                      WHERE   {MessageCol.LocalChatId} = ? AND
                              {MessageCol.Seen} != 1"""
    db.exec(query, chatId)

    db.resetUnviewedMessageCount(chatId)
  except ChatDbError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)

proc markMessagesSeen*(db: DbConn, chatId: string, messageIds: seq[string])
  {.raises: [MessageDbError].} =

  var errorMsg = "Error marking messages seen"
  try:
    var message: Message
    let
      quotedIds {.used.} = messageIds.map(id => fmt"'{id}'").join(",")
      query = fmt"""UPDATE  {message.tableName}
                    SET     {MessageCol.Seen} = 1
                    WHERE   {MessageCol.Id} IN ({quotedIds})"""

    db.exec(query)

    db.updateUnviewedMessageCount(chatId)
  except ChatDbError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MessageDbError)(parent: e, msg: errorMsg)
