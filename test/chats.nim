import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, secp256k1, sqlcipher, stew/byteutils

import # status lib
  status/private/[chats, contacts, conversions, database, messages]

import # test modules
  ./test_helpers

procSuite "chats":
  asyncTest "chats":
    let
      password = "qwerty"
      path = currentSourcePath.parentDir() & "/build/my.db"
      bip44PublicKey = SkPublicKey.fromHex(
        "0x03ddb90a4f67a81adf534bc19ed06d1546a3cad16a3b2995e18e3d7af823fe5c9a").get
    removeFile(path)
    var db: DbConn
    try:
      db = initializeDB(path, password)
    except DbError as e:
      echo "error initing db: " & e.msg

    let
      message = Message(
        id: "test",
        whisperTimestamp: 123
      )

    var chat = Chat(
      id: "ContactId",
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

    # saveChat
    db.saveChat(chat)

    # getChats
    chat.id = "ContactId1"
    db.saveChat(chat)

    var dbChats = db.getChats()

    check:
      len(dbChats) == 2

    # getChatById
    var dbChat = db.getChatById("ContactId").get()

    check:
      dbChat.active == true
      dbChat.publicKey.get == bip44PublicKey
      dbChat.unviewedMessageCount == 3

    # [mute/unmute]Chat
    db.muteChat("ContactId")
    dbChat = db.getChatById("ContactId").get()

    check:
      dbChat.muted == true

    db.unmuteChat("ContactId")
    dbChat = db.getChatById("ContactId").get()

    check:
      dbChat.muted == false

    # blockContact
    let contact = Contact(
      id: "ContactId",
      address: some("0xdeadbeefdeadbeefdeadbeefdeadbeef11111111".parseAddress),
      name: some("TheUsername1"),
      ensVerified: true,
      ensVerifiedAt: 11111,
      lastENSClockValue: 111,
      ensVerificationRetries: 1,
      alias: some("Teenage Mutant NinjaTurtle"),
      identicon: "ABCDEF",
      photo: some("ABC"),
      lastUpdated: 11111,
      systemTags: @["tag11","tag12","tag13"],
      deviceInfo: @[ContactDeviceInfo(installationId: "ABC1", timestamp: 11, fcmToken: "ABC1")],
      tributeToTalk: some("ABC1"),
      localNickname: some("ABC1")
    )

    db.saveContact(contact)

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
      localChatId: "ContactId",
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
    db.saveMessage(msg)
    msg.id = "msg2"
    msg.source = "ContactId1"
    msg.localChatId = "ContactId1"
    db.saveMessage(msg)

    let chatsAfterBlocking = db.blockContact(contact)

    check:
      # Assert that blockContact deleted entry from user_messages
      db.getMessageById("msg1").isNone()
      # Assert that blockContact deleted entry from chats
      db.getChatById("ContactId").isNone()
      # Assert there is 1 unviewed message from ContactId1
      len(chatsAfterBlocking) == 1

    let chatEntry = chatsAfterBlocking[0]
    echo "chatEntry"
    echo chatEntry

    check:
      chatEntry.unviewedMessageCount == 1

    # deleteChat
    db.deleteChat(chat)
    dbChats = db.getChats()

    check:
      # Chat with id=ContactId was deleted by blockContact
      len(dbChats) == 0

    db.close()
    removeFile(path)
