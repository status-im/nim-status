{.push raises: [Defect].}

import # std libs
  std/[json, marshal, options, sequtils, strformat]

import # vendor libs
  sqlcipher

import # status modules
  ./chatmessages/common as chatmessages, ./common, ./contacts, ./conversions,
  ./messages

export chatmessages, common

proc getChats*(db: DbConn): DbResult[seq[Chat]]
  {.raises: [AssertionError, Defect].} =

  try:
    var chat: Chat
    let query = fmt"""SELECT   *
                      FROM     {chat.tableName}"""

    ok db.all(Chat, query)

  except ConversionError: err MarshalFailure
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getChatById*(db: DbConn, id: string): DbResult[Option[Chat]]
  {.raises: [AssertionError, Defect].} =

  try:
    var chat: Chat
    let query = fmt"""SELECT   *
                      FROM     {chat.tableName}
                      WHERE    {ChatCol.Id} = ?"""

    ok db.one(Chat, query, id)

  except ConversionError: err MarshalFailure
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc saveChat*(db: DbConn, chat: Chat): DbResult[void] =
  try:
    let query = fmt"""INSERT INTO chats(
      {ChatCol.Id},
      {ChatCol.Name},
      {ChatCol.Color},
      {ChatCol.ChatType},
      {ChatCol.Active},
      {ChatCol.Timestamp},
      {ChatCol.DeletedAtClockValue},
      {ChatCol.PublicKey},
      {ChatCol.UnviewedMessageCount},
      {ChatCol.LastClockValue},
      {ChatCol.LastMessage},
      {ChatCol.Members},
      {ChatCol.MembershipUpdates},
      {ChatCol.Muted},
      {ChatCol.InvitationAdmin},
      {ChatCol.Profile},
      {ChatCol.CommunityId},
      {ChatCol.Accepted},
      {ChatCol.Joined},
      {ChatCol.SyncedTo},
      {ChatCol.SyncedFrom},
      {ChatCol.UnviewedMentionsCount},
      {ChatCol.Description}
      )
      VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
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
      chat.muted,
      chat.invitationAdmin,
      chat.profile,
      chat.communityId,
      chat.accepted,
      chat.joined,
      chat.syncedTo,
      chat.syncedFrom,
      chat.unviewedMentionsCount,
      chat.description)

    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc muteChat*(db: DbConn, chatId: string): DbResult[void] {.raises: [].} =
  try:
    var chat: Chat
    let query = fmt"""UPDATE  {chat.tableName}
                      SET     {ChatCol.Muted} = 1
                      WHERE   {ChatCol.Id} = ?"""

    db.exec(query, chatId)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc unmuteChat*(db: DbConn, chatId: string): DbResult[void] {.raises: [].} =
  try:
    var chat: Chat
    let query = fmt"""UPDATE  {chat.tableName}
                      SET     {ChatCol.Muted} = 0
                      WHERE   {ChatCol.Id} = ?"""

    db.exec(query, chatId)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc deleteChat*(db: DbConn, chat: Chat): DbResult[void] {.raises: [].} =
  try:
    var tblChat: Chat
    let query = fmt"""DELETE FROM {tblChat.tableName}
                      WHERE       {ChatCol.Id} = ?"""

    db.exec(query, chat.id)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc deleteOneToOneChat*(db: DbConn, contactId: string): DbResult[void]
  {.raises: [].} =
  # Delete one-to-one chat

  try:
    var chat: Chat
    let query = fmt"""DELETE
                      FROM    {chat.tableName}
                      WHERE   id = ?"""

    db.exec(query, contactId)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc updateLastMessage*(db: DbConn, chatId: string,
  lastMessage: Option[Message]): DbResult[void] {.raises: [Defect,
  UnpackError].} =
  # Updates the last message for a chat

  try:
    var chat: Chat
    let query = fmt"""UPDATE  {chat.tableName}
                      SET     {ChatCol.LastMessage} = ?
                      WHERE   {ChatCol.Id} = ?"""

    db.exec(query, lastMessage, chatId)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc blockContact*(db: DbConn, contact: Contact): DbResult[seq[Chat]] =
  # BlockContact updates a contact, deletes all the messages and 1-to-1 chat,
  # updates the unread messages count and returns a map with the new count

  # Delete messages
  ?db.deleteContactMessages(contact.id)

  # Update contact
  ?db.saveContact(contact)

  # Delete one-to-one chat
  ?db.deleteOneToOneChat(contact.id)

  # Recalculate denormalized fields
  ?db.updateAllUnviewedMessageCounts()

  # update last message for all chats
  var chats = ?getChats(db)
  # var lastResultErr: DbError
  var chatsModified: seq[Chat] = @[]

  for chat in chats:
    var chatModified = chat
    let lastMessage = ?db.getLastMessage(chat.id)
    chatModified.lastMessage = lastMessage
    chatsModified.add chatModified
    ?db.updateLastMessage(chat.id, lastMessage)

  # return the updated chats
  return ok chatsModified
