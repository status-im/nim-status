import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  json_serialization, sqlcipher, stew/byteutils

import # status lib
  status/private/[conversions, chats, database, messages,
                  migrations/sql_scripts_app]

import # test modules
  ./test_helpers

procSuite "messages":
  asyncTest "messages":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let db = initializeDB(path, password)

    var msg = Message(
      id: "msg1",
      whisperTimestamp: 0,
      source: "ContactId",
      destination: "default_destination".toBytes(),
      text: "text",
      contentType: 0,
      username: "user1",
      timestamp: 25,
      chatId: "chat-id",
      localChatId: "local-chat-id",
      hide: false,
      responseTo: "user1",
      messageType: 0,
      clockValue: 0,
      seen: false,
      outgoingStatus: "Delivered",
      parsedText: "parsed".toBytes(),
      rawPayload: "raw".toBytes(),
      stickerPack: 0,
      stickerHash: "hash",
      commandId: "command1",
      commandValue: "commandValue",
      commandAddress: "commandAddress",
      commandFrom: "commandFrom",
      commandContract: "commandContract",
      commandTransactionHash: "commandTransactionHash",
      commandSignature: "commandSignature".toBytes(),
      commandState: 3,
      audioPayload: "audioPayload".toBytes(),
      audioType: 0,
      audioDurationMs: 10,
      audioBase64: "sdf",
      replaceMessage: "message_replacement",
      rtl: false,
      lineCount: 5,
      links: "links",
      mentions: "mentions",
      imagePayload: "blob".toBytes(),
      imageType: "type",
      imageBase64: "sdfsdfsdf"
    )

    # saveMessage
    db.saveMessage(msg)

    # getMessageById
    var dbMsg = db.getMessageById("msg1").get()

    check:
      dbMsg.links == "links" and
        dbMsg.timestamp == 25 and
        dbMsg.username == "user1"

    # markAllRead
    db.markAllRead("local-chat-id")
    dbMsg = db.getMessageById("msg1").get()

    check:
      dbMsg.seen == true

    # markMessagesSeen
    msg.id = "msg2"
    db.saveMessage(msg)

    var chat = Chat(
      id: "local-chat-id",
      name: "chat-name",
      color: "blue",
      chatType: 1,
      active: true,
      timestamp: 25,
      deletedAtClockValue: 15,
      publicKey: "public-key".toBytes(),
      unviewedMessageCount: 3,
      lastClockValue: 18,
      lastMessage: some("lastMessage".toBytes()),
      members: "members".toBytes(),
      membershipUpdates: "membershipUpdates".toBytes(),
      profile: "profile",
      invitationAdmin: "invitationAdmin",
      muted: false,
    )
    db.saveChat(chat)
    db.markMessagesSeen("local-chat-id", @["msg1", "msg2"])
    dbMsg = db.getMessageById("msg2").get()
    var dbChat = db.getChatById("local-chat-id").get()

    check:
      dbMsg.seen == true and dbChat.unviewedMessageCount == 0

    # deleteMessage
    db.deleteMessage(msg)
    var found: bool
    try:
      discard db.getMessageById("msg2").get()
      found = true
    except:
      found = false

    check:
      found == false

    db.close()
    removeFile(path)
