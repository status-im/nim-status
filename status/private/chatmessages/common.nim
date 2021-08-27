{.push raises: [Defect].}

import # std libs
  std/[options, strformat]

import # vendor modules
  json_serialization, secp256k1, sqlcipher

import # nim-status modules
  ../common

type
  ChatType* {.pure.} = enum
    Id = "id",
    Name = "name",
    Color = "color",
    ChatType = "chatType",
    Active = "active",
    Timestamp = "timestamp",
    DeletedAtClockValue = "deletedAtClockValue",
    PublicKey = "publicKey",
    UnviewedMessageCount = "unviewedMessageCount",
    LastClockValue = "lastClockValue",
    LastMessage = "lastMessage",
    Members = "members",
    MembershipUpdates = "membershipUpdates"
    Profile = "profile",
    InvitationAdmin = "invitationAdmin",
    Muted = "muted"

  ChatCol* {.pure.} = enum
    Id = "id",
    Name = "name",
    Color = "color",
    ChatType = "type",
    Active = "active",
    Timestamp = "timestamp",
    DeletedAtClockValue = "deleted_at_clock_value",
    PublicKey = "public_key",
    UnviewedMessageCount = "unviewed_message_count",
    LastClockValue = "last_clock_value",
    LastMessage = "last_message",
    Members = "members",
    MembershipUpdates = "membership_updates"
    Profile = "profile",
    InvitationAdmin = "invitation_admin",
    Muted = "muted"

  Chat* {.dbTableName("chats").} = object
    id* {.serializedFieldName($ChatType.Id), dbColumnName($ChatCol.Id).}: string
    name* {.serializedFieldName($ChatType.Name), dbColumnName($ChatCol.Name).}: string
    color* {.serializedFieldName($ChatType.Color), dbColumnName($ChatCol.Color).}: string
    chatType* {.serializedFieldName($ChatType.ChatType), dbColumnName($ChatCol.ChatType).}: int
    active* {.serializedFieldName($ChatType.Active), dbColumnName($ChatCol.Active).}: bool
    timestamp* {.serializedFieldName($ChatType.Timestamp), dbColumnName($ChatCol.Timestamp).}: int
    deletedAtClockValue* {.serializedFieldName($ChatType.DeletedAtClockValue), dbColumnName($ChatCol.DeletedAtClockValue).}: int
    publicKey* {.serializedFieldName($ChatType.PublicKey), dbColumnName($ChatCol.PublicKey).}: Option[SkPublicKey]
    unviewedMessageCount* {.serializedFieldName($ChatType.UnviewedMessageCount), dbColumnName($ChatCol.UnviewedMessageCount).}: int
    lastClockValue* {.serializedFieldName($ChatType.LastClockValue), dbColumnName($ChatCol.LastClockValue).}: int
    lastMessage* {.serializedFieldName($ChatType.LastMessage), dbColumnName($ChatCol.LastMessage).}: Option[Message]
    # TODO: members should be a concrete type
    members* {.serializedFieldName($ChatType.Members), dbColumnName($ChatCol.Members).}: seq[byte]
    # TODO: membershipUpdates should be a concrete type
    membershipUpdates* {.serializedFieldName($ChatType.MembershipUpdates), dbColumnName($ChatCol.MembershipUpdates).}: seq[byte]
    profile* {.serializedFieldName($ChatType.Profile), dbColumnName($ChatCol.Profile).}: string
    invitationAdmin* {.serializedFieldName($ChatType.InvitationAdmin), dbColumnName($ChatCol.InvitationAdmin).}: string
    muted* {.serializedFieldName($ChatType.Muted), dbColumnName($ChatCol.Muted).}: bool

  MessageType* {.pure.} = enum
    Id = "id",
    WhisperTimestamp = "whisperTimestamp",
    Source = "source",
    Destination = "destination",
    Text = "text",
    ContentType = "contentType",
    Username = "username",
    Timestamp = "timestamp",
    ChatId = "chatId",
    LocalChatId = "localChatId",
    Hide = "hide",
    ResponseTo = "responseTo",
    MessageType = "messageType",
    ClockValue = "clockValue",
    Seen = "seen",
    OutgoingStatus = "outgoingStatus",
    ParsedText = "parsedText",
    RawPayload = "rawPayload",
    StickerPack = "stickerPack",
    StickerHash = "stickerHash",
    CommandId = "commandId",
    CommandValue = "commandValue",
    CommandAddress = "commandAddress",
    CommandFrom = "commandFrom",
    CommandContract = "commandContract",
    CommandTransactionHash = "commandTransactionHash",
    CommandSignature = "commandSignature",
    CommandState = "commandState",
    AudioPayload = "audioPayload",
    AudioType = "audioType",
    AudioDurationMs = "audioDurationMs",
    AudioBase64 = "audioBase64",
    ReplaceMessage = "replaceMessage",
    Rtl = "rtl",
    LineCount = "lineCount",
    Links = "links",
    Mentions = "mentions",
    ImagePayload = "imagePayload",
    ImageType = "imageType",
    ImageBase64 = "imageBase64"

  MessageCol* {.pure.} = enum
    Id = "id",
    WhisperTimestamp = "whisper_timestamp",
    Source = "source",
    Destination = "destination",
    Text = "text",
    ContentType = "content_type",
    Username = "username",
    Timestamp = "timestamp",
    ChatId = "chat_id",
    LocalChatId = "local_chat_id",
    Hide = "hide",
    ResponseTo = "response_to",
    MessageType = "message_type",
    ClockValue = "clock_value",
    Seen = "seen",
    OutgoingStatus = "outgoing_status",
    ParsedText = "parsed_text",
    RawPayload = "raw_payload",
    StickerPack = "sticker_pack",
    StickerHash = "sticker_hash",
    CommandId = "command_id",
    CommandValue = "command_value",
    CommandAddress = "command_address",
    CommandFrom = "command_from",
    CommandContract = "command_contract",
    CommandTransactionHash = "command_transaction_hash",
    CommandSignature = "command_signature",
    CommandState = "command_state",
    AudioPayload = "audio_payload",
    AudioType = "audio_type",
    AudioDurationMs = "audio_duration_ms",
    AudioBase64 = "audio_base64",
    ReplaceMessage = "replace_message",
    Rtl = "rtl",
    LineCount = "line_count",
    Links = "links",
    Mentions = "mentions",
    ImagePayload = "image_payload",
    ImageType = "image_type",
    ImageBase64 = "image_base64"

  Message* {.dbTableName("user_messages").} = object
    id* {.serializedFieldName($MessageType.Id), dbColumnName($MessageCol.Id).}: string
    whisperTimestamp* {.serializedFieldName($MessageType.WhisperTimestamp), dbColumnName($MessageCol.WhisperTimestamp).}: int
    source* {.serializedFieldName($MessageType.Source), dbColumnName($MessageCol.Source).}: string
    destination* {.serializedFieldName($MessageType.Destination), dbColumnName($MessageCol.Destination).}: seq[byte]
    text* {.serializedFieldName($MessageType.Text), dbColumnName($MessageCol.Text).}: string
    contentType* {.serializedFieldName($MessageType.ContentType), dbColumnName($MessageCol.ContentType).}: int
    username* {.serializedFieldName($MessageType.Username), dbColumnName($MessageCol.Username).}: string
    timestamp* {.serializedFieldName($MessageType.Timestamp), dbColumnName($MessageCol.Timestamp).}: int
    chatId* {.serializedFieldName($MessageType.ChatId), dbColumnName($MessageCol.ChatId).}: string
    localChatId* {.serializedFieldName($MessageType.LocalChatId), dbColumnName($MessageCol.LocalChatId).}: string
    hide* {.serializedFieldName($MessageType.Hide), dbColumnName($MessageCol.Hide).}: bool
    responseTo* {.serializedFieldName($MessageType.ResponseTo), dbColumnName($MessageCol.ResponseTo).}: string
    messageType* {.serializedFieldName($MessageType.MessageType), dbColumnName($MessageCol.MessageType).}: int
    clockValue* {.serializedFieldName($MessageType.ClockValue), dbColumnName($MessageCol.ClockValue).}: int
    seen* {.serializedFieldName($MessageType.Seen), dbColumnName($MessageCol.Seen).}: bool
    outgoingStatus* {.serializedFieldName($MessageType.OutgoingStatus), dbColumnName($MessageCol.OutgoingStatus).}: string
    parsedText* {.serializedFieldName($MessageType.ParsedText), dbColumnName($MessageCol.ParsedText).}: seq[byte]
    rawPayload* {.serializedFieldName($MessageType.RawPayload), dbColumnName($MessageCol.RawPayload).}: seq[byte]
    stickerPack* {.serializedFieldName($MessageType.StickerPack), dbColumnName($MessageCol.StickerPack).}: int
    stickerHash* {.serializedFieldName($MessageType.StickerHash), dbColumnName($MessageCol.StickerHash).}: string
    commandId* {.serializedFieldName($MessageType.CommandId), dbColumnName($MessageCol.CommandId).}: string
    commandValue* {.serializedFieldName($MessageType.CommandValue), dbColumnName($MessageCol.CommandValue).}: string
    commandAddress* {.serializedFieldName($MessageType.CommandAddress), dbColumnName($MessageCol.CommandAddress).}: string
    commandFrom* {.serializedFieldName($MessageType.CommandFrom), dbColumnName($MessageCol.CommandFrom).}: string
    commandContract* {.serializedFieldName($MessageType.CommandContract), dbColumnName($MessageCol.CommandContract).}: string
    commandTransactionHash* {.serializedFieldName($MessageType.CommandTransactionHash), dbColumnName($MessageCol.CommandTransactionHash).}: string
    commandSignature* {.serializedFieldName($MessageType.CommandSignature), dbColumnName($MessageCol.CommandSignature).}: seq[byte]
    commandState* {.serializedFieldName($MessageType.CommandState), dbColumnName($MessageCol.CommandState).}: int
    audioPayload* {.serializedFieldName($MessageType.AudioPayload), dbColumnName($MessageCol.AudioPayload).}: seq[byte]
    audioType* {.serializedFieldName($MessageType.AudioType), dbColumnName($MessageCol.AudioType).}: int
    audioDurationMs* {.serializedFieldName($MessageType.AudioDurationMs), dbColumnName($MessageCol.AudioDurationMs).}: int
    audioBase64* {.serializedFieldName($MessageType.AudioBase64), dbColumnName($MessageCol.AudioBase64).}: string
    replaceMessage* {.serializedFieldName($MessageType.ReplaceMessage), dbColumnName($MessageCol.ReplaceMessage).}: string
    rtl* {.serializedFieldName($MessageType.Rtl), dbColumnName($MessageCol.Rtl).}: bool
    lineCount* {.serializedFieldName($MessageType.LineCount), dbColumnName($MessageCol.LineCount).}: int
    links* {.serializedFieldName($MessageType.Links), dbColumnName($MessageCol.Links).}: string
    mentions* {.serializedFieldName($MessageType.Mentions), dbColumnName($MessageCol.Mentions).}: string
    imagePayload* {.serializedFieldName($MessageType.ImagePayload), dbColumnName($MessageCol.ImagePayload).}: seq[byte]
    imageType* {.serializedFieldName($MessageType.ImageType), dbColumnName($MessageCol.ImageType).}: string
    imageBase64* {.serializedFieldName($MessageType.ImageBase64), dbColumnName($MessageCol.ImageBase64).}: string

proc getLastMessage*(db: DbConn, chatId: string): DbResult[Option[Message]]
  {.raises: [AssertionError].} =

  try:
    var message: Message
    let query = fmt"""SELECT    *
                      FROM      {message.tableName}
                      WHERE     {MessageCol.LocalChatId} = ?
                      ORDER BY  {MessageCol.ClockValue} DESC
                      LIMIT     1"""
    ok db.one(Message, query, chatId)
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc resetUnviewedMessageCount*(db: DbConn, chatId: string): DbResult[void]
  {.raises: [].} =

  try:
    var chat: Chat
    let chatQuery = fmt"""UPDATE  {chat.tableName}
                          SET     {ChatCol.UnviewedMessageCount} = 0
                          WHERE   {ChatCol.Id} = ?"""
    db.exec(chatQuery, chatId)
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc updateAllUnviewedMessageCounts*(db: DbConn): DbResult[void]
  {.raises: [].} =
  # Recalculate denormalized fields

  try:
    var
      chat: Chat
      message: Message
    let query = fmt"""UPDATE  {chat.tableName}
                      SET     {ChatCol.UnviewedMessageCount} =
                              (
                                SELECT  COUNT(1)
                                FROM    {message.tableName}
                                WHERE   {MessageCol.Seen} = 0 AND
                                        {MessageCol.LocalChatId} =
                                          {chat.tableName}.{ChatCol.Id}
                              )"""
    db.exec(query)
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc updateUnviewedMessageCount*(db: DbConn, chatId: string): DbResult[void]
  {.raises: [].} =

  try:
    var
      chat: Chat
      message: Message
    let chatQuery = fmt"""UPDATE  {chat.tableName}
                          SET     {ChatCol.UnviewedMessageCount} =
                                  (
                                    SELECT  COUNT(1)
                                    FROM    {message.tableName}
                                    WHERE   {MessageCol.LocalChatId} = ? AND
                                            {MessageCol.Seen} = 0
                                  )
                          WHERE {ChatCol.Id} = ?"""
    db.exec(chatQuery, chatId, chatId)
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError
