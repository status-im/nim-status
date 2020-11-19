import # nim libs
  json, options, strutils, strformat
import # vendor libs
  web3/conversions as web3_conversions, web3/ethtypes,
  sqlcipher, json_serialization, json_serialization/[reader, writer, lexer],
  stew/byteutils

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


  Chat* = object
    id* {.serializedFieldName($ChatType.Id), dbColumnName($ChatCol.Id).}: string
    name* {.serializedFieldName($ChatType.Name), dbColumnName($ChatCol.Name).}: string
    color* {.serializedFieldName($ChatType.Color), dbColumnName($ChatCol.Color).}: string
    chatType* {.serializedFieldName($ChatType.ChatType), dbColumnName($ChatCol.ChatType).}: int
    active* {.serializedFieldName($ChatType.Active), dbColumnName($ChatCol.Active).}: bool
    timestamp* {.serializedFieldName($ChatType.Timestamp), dbColumnName($ChatCol.Timestamp).}: int
    deletedAtClockValue* {.serializedFieldName($ChatType.DeletedAtClockValue), dbColumnName($ChatCol.DeletedAtClockValue).}: int
    publicKey* {.serializedFieldName($ChatType.PublicKey), dbColumnName($ChatCol.PublicKey).}: seq[byte]
    unviewedMessageCount* {.serializedFieldName($ChatType.UnviewedMessageCount), dbColumnName($ChatCol.UnviewedMessageCount).}: int
    lastClockValue* {.serializedFieldName($ChatType.LastClockValue), dbColumnName($ChatCol.LastClockValue).}: int
    lastMessage* {.serializedFieldName($ChatType.LastMessage), dbColumnName($ChatCol.LastMessage).}: seq[byte]
    members* {.serializedFieldName($ChatType.Members), dbColumnName($ChatCol.Members).}: seq[byte]
    membershipUpdates* {.serializedFieldName($ChatType.MembershipUpdates), dbColumnName($ChatCol.MembershipUpdates).}: seq[byte]
    profile* {.serializedFieldName($ChatType.Profile), dbColumnName($ChatCol.Profile).}: string
    invitationAdmin* {.serializedFieldName($ChatType.InvitationAdmin), dbColumnName($ChatCol.InvitationAdmin).}: string
    muted* {.serializedFieldName($ChatType.Muted), dbColumnName($ChatCol.Muted).}: bool


proc getChats*(db: DbConn): seq[Chat] = 
  let query = """SELECT * from chats"""

  result = db.all(Chat, query)

proc getChatById*(db: DbConn, id: string): Option[Chat] = 
  let query = """SELECT * from chats where id = ?"""
  
  result = db.one(Chat, query, id)

proc saveChat*(db: DbConn, chat: Chat) = 
  let query = fmt"""INSERT INTO chats(
    {$ChatCol.Id},
    {$ChatCol.Name},
    {$ChatCol.Color},
    {$ChatCol.ChatType},
    {$ChatCol.Active},
    {$ChatCol.Timestamp},
    {$ChatCol.DeletedAtClockValue},
    {$ChatCol.PublicKey},
    {$ChatCol.UnviewedMessageCount},
    {$ChatCol.LastClockValue},
    {$ChatCol.LastMessage},
    {$ChatCol.Members},
    {$ChatCol.MembershipUpdates},
    {$ChatCol.Profile},
    {$ChatCol.InvitationAdmin},
    {$ChatCol.Muted})
    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) 
  """

  db.exec(query, 
    chat.id,
    chat.name,
    chat.color,
    chat.chatType,
    chat.active,
    chat.timestamp,
    chat.deletedAtClockValue,
    chat.publicKey,
    chat.unviewedMessageCount,
    chat.lastClockValue,
    chat.lastMessage,
    chat.members,
    chat.membershipUpdates,
    chat.profile,
    chat.invitationAdmin,
    chat.muted)

proc deleteChat*(db: DbConn, chat: Chat) =
  let query = fmt"""DELETE FROM chats where id = ?"""

  db.exec(query, chat.id)
