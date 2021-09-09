import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  json_serialization, secp256k1, sqlcipher, stew/byteutils

import # status lib
  status/private/[conversions, chats, database, messages]

import # test modules
  ./test_helpers

procSuite "messages":
  asyncTest "messages":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initUserDb(path, password)
    check dbResult.isOk

    let db = dbResult.get

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
    check db.saveMessage(msg).isOk

    # getMessageById
    var dbMsgResult = db.getMessageById("msg1")
    check dbMsgResult.isOk
    var dbMsgOpt = dbMsgResult.get
    check dbMsgOpt.isSome
    var dbMsg = dbMsgOpt.get
    check:
      dbMsg.links == "links" and
        dbMsg.timestamp == 25 and
        dbMsg.username == "user1"

    # markAllRead
    check db.markAllRead("local-chat-id").isOk
    dbMsgResult = db.getMessageById("msg1")
    check dbMsgResult.isOk
    dbMsgOpt = dbMsgResult.get
    check dbMsgOpt.isSome
    dbMsg = dbMsgOpt.get
    check dbMsg.seen == true

    # markMessagesSeen
    msg.id = "msg2"
    check db.saveMessage(msg).isOk
    let
      bip44PublicKey = SkPublicKey.fromHex(
        "0x03ddb90a4f67a81adf534bc19ed06d1546a3cad16a3b2995e18e3d7af823fe5c9a").get
      message = Message(
        id: "test",
        whisperTimestamp: 123
      )

    var chat = Chat(
      id: "local-chat-id",
      name: "chat-name",
      color: "blue",
      chatType: 1,
      active: true,
      timestamp: 25,
      deletedAtClockValue: 15,
      publicKey: bip44PublicKey.some,
      unviewedMessageCount: 3,
      lastClockValue: 18,
      lastMessage: message.some,
      members: "members".toBytes(),
      membershipUpdates: "membershipUpdates".toBytes(),
      profile: "profile",
      invitationAdmin: "invitationAdmin",
      muted: false,
    )
    check:
      db.saveChat(chat).isOk
      db.markMessagesSeen("local-chat-id", @["msg1", "msg2"]).isOk
    dbMsgResult = db.getMessageById("msg2")
    check dbMsgResult.isOk
    dbMsgOpt = dbMsgResult.get
    check dbMsgOpt.isSome
    dbMsg = dbMsgOpt.get
    var dbChatResult = db.getChatById("local-chat-id")
    check dbChatResult.isOk
    var dbChatOpt = dbChatResult.get
    check dbChatOpt.isSome
    var dbChat = dbChatOpt.get
    check:
      dbMsg.seen == true and dbChat.unviewedMessageCount == 0

    # deleteMessage
    check db.deleteMessage(msg).isOk
    dbMsgResult = db.getMessageById("msg2")
    check dbMsgResult.isOk
    dbMsgOpt = dbMsgResult.get
    check dbMsgOpt.isNone

    db.close()
    removeFile(path)
