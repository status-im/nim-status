{.push raises: [Defect].}

import # std libs
  std/[json, marshal, options, sequtils, strformat]

import # vendor libs
  sqlcipher

import # status modules
  ./chatmessages/common, ./contacts, ./conversions, ./messages

export common

proc getChats*(db: DbConn): seq[Chat] {.raises: [AssertionError, ChatDbError,
  Defect].} =

  const errorMsg = "Error getting chats from database"

  try:
    var chat: Chat
    let query = fmt"""SELECT   *
                      FROM     {chat.tableName}"""
    result = db.all(Chat, query)
  except ConversionError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)

proc getChatById*(db: DbConn, id: string): Option[Chat] {.raises:
  [AssertionError, ChatDbError, Defect].} =

  const errorMsg = "Error getting chat by id from database"

  try:
    var chat: Chat
    let query = fmt"""SELECT   *
                      FROM     {chat.tableName}
                      WHERE    {ChatCol.Id} = ?"""
    result = db.one(Chat, query, id)
  except ConversionError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)

proc saveChat*(db: DbConn, chat: Chat) {.raises: [Defect, ChatDbError].} =
  const errorMsg = "Error saving chat to database"

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
      {ChatCol.Profile},
      {ChatCol.InvitationAdmin},
      {ChatCol.Muted})
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

  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)

proc muteChat*(db: DbConn, chatId: string) {.raises: [ChatDbError].} =
  const errorMsg = "Error updating chat to muted in the database"
  try:
    var chat: Chat
    let query = fmt"""UPDATE  {chat.tableName}
                      SET     {ChatCol.Muted} = 1
                      WHERE   {ChatCol.Id} = ?"""
    db.exec(query, chatId)
  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)

proc unmuteChat*(db: DbConn, chatId: string) {.raises: [ChatDbError].} =
  const errorMsg = "Error updating chat to unmuted in the database"
  try:
    var chat: Chat
    let query = fmt"""UPDATE  {chat.tableName}
                      SET     {ChatCol.Muted} = 0
                      WHERE   {ChatCol.Id} = ?"""
    db.exec(query, chatId)
  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)

proc deleteChat*(db: DbConn, chat: Chat) {.raises: [ChatDbError].} =
  const errorMsg = "Error deleting chat from the database"
  try:
    var tblChat: Chat
    let query = fmt"""DELETE FROM {tblChat.tableName}
                      WHERE       {ChatCol.Id} = ?"""
    db.exec(query, chat.id)
  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)

proc deleteOneToOneChat*(db: DbConn, contactId: string) {.raises:
  [ChatDbError].} =
  # Delete one-to-one chat

  const errorMsg = "Error deleting one-to-one chat from the database"
  try:
    var chat: Chat
    let query = fmt"""DELETE
                      FROM    {chat.tableName}
                      WHERE   id = ?"""
    db.exec(query, contactId)
  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)

proc updateLastMessage*(db: DbConn, chatId: string,
  lastMessage: Option[Message]) {.raises: [ChatDbError, Defect, UnpackError].} =
  # Updates the last message for a chat

  const errorMsg = "Error updating the last message for a chat in the database"
  try:
    var chat: Chat
    let query = fmt"""UPDATE  {chat.tableName}
                      SET     {ChatCol.LastMessage} = ?
                      WHERE   {ChatCol.Id} = ?"""
    db.exec(query, lastMessage, chatId)
  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)

proc blockContact*(db: DbConn, contact: Contact): seq[Chat] {.raises:
  [ChatDbError, ContactDbError, Defect].} =
  # BlockContact updates a contact, deletes all the messages and 1-to-1 chat,
  # updates the unread messages count and returns a map with the new count

  const errorMsg = "Error blocking contact in the database"
  try:

    # Delete messages
    db.deleteContactMessages(contact.id)

    # Update contact
    db.saveContact(contact)

    # Delete one-to-one chat
    db.deleteOneToOneChat(contact.id)

    # Recalculate denormalized fields
    db.updateAllUnviewedMessageCounts()

    # update last message for all chats
    var chats = getChats(db)
    chats.apply(proc (c: var Chat) =
      c.lastMessage = db.getLastMessage(c.id)
      db.updateLastMessage(c.id, c.lastMessage)
    )

    # return the updated chats
    return chats

  except ChatDbError as e:
    raise e
  except ContactDbError as e:
    raise e
  except MessageDbError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ChatDbError)(parent: e, msg: errorMsg)
