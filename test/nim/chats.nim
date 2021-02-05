import # nim libs
  os, json, options

import # vendor libs
  sqlcipher, json_serialization, web3/conversions as web3_conversions

import # nim-status libs
  ../../nim_status/[chats, database, conversions, contacts, messages]

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd)

var chat = Chat(
  id: "ContactId",
  name: "chat-name",
  color: "blue",
  chatType: 1,
  active: true,
  timestamp: 25,
  deletedAtClockValue: 15,
  publicKey: cast[seq[byte]]("public-key"),
  unviewedMessageCount: 3,
  lastClockValue: 18,
  lastMessage: some(cast[seq[byte]]("lastMessage")),
  members: cast[seq[byte]]("members"),
  membershipUpdates: cast[seq[byte]]("membershipUpdates"),
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
assert len(dbChats) == 2

# getChatById
var dbChat = db.getChatById("ContactId").get()
assert dbChat.active == true and
       dbChat.publicKey == cast[seq[byte]]("public-key") and
       dbChat.unviewedMessageCount == 3

# [mute/unmute]Chat
db.muteChat("ContactId")
dbChat = db.getChatById("ContactId").get()
assert dbChat.muted == true

db.unmuteChat("ContactId")
dbChat = db.getChatById("ContactId").get()
assert dbChat.muted == false

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
  destination: cast[seq[byte]]("default_destination"),
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
  parsedText: cast[seq[byte]]("parsed"),
  rawPayload: cast[seq[byte]]("raw"),
  stickerPack: 0,
  stickerHash: "hash",
  commandId: "command1",
  commandValue: "commandValue",
  commandAddress: "commandAddress",
  commandFrom: "commandFrom",
  commandContract: "commandContract",
  commandTransactionHash: "commandTransactionHash",
  commandSignature: cast[seq[byte]]("commandSignature"),
  commandState: 3,
  audioPayload: cast[seq[byte]]("audioPayload"),
  audioType: 0,
  audioDurationMs: 10,
  audioBase64: "sdf",
  replaceMessage: "message_replacement",
  rtl: false,
  lineCount: 5,
  links: "links",
  mentions: "mentions",
  imagePayload: cast[seq[byte]]("blob"),
  imageType: "type",
  imageBase64: "sdfsdfsdf"
)
db.saveMessage(msg)
msg.id = "msg2"
msg.source = "ContactId1"
msg.localChatId = "ContactId1"
db.saveMessage(msg)

let chatsAfterBlocking = db.blockContact(contact)

var found: bool

# Assert that blockContact deleted entry from user_messages
assert db.getMessageById("msg1").isNone()

# Assert that blockContact deleted entry from chats
assert db.getChatById("ContactId").isNone()

# Assert there is 1 unviewed message from ContactId1
assert len(chatsAfterBlocking) == 1
let chatEntry = chatsAfterBlocking[0]
echo "chatEntry"
echo chatEntry
assert chatEntry.unviewedMessageCount == 1


# deleteChat
db.deleteChat(chat)
dbChats = db.getChats()
# Chat with id=ContactId was deleted by blockContact
assert len(dbChats) == 0

db.close()
removeFile(path)
