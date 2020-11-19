import # nim libs
  os, json, options

import # vendor libs
  sqlcipher, json_serialization, web3/conversions as web3_conversions

import # nim-status libs
  ../../nim_status/lib/[messages, database, conversions, chats]

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd)

var msg = Message(
  id: "msg1",
  whisperTimestamp: 0,
  source: "default_source",
  destination: cast[seq[byte]]("default_destination"),
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

# saveMessage
db.saveMessage(msg)

# getMessageById
var dbMsg = db.getMessageById("msg1").get()
assert dbMsg.links == "links" and
       dbMsg.timestamp == 25 and
       dbMsg.username == "user1"

# markAllRead
db.markAllRead("local-chat-id")
dbMsg = db.getMessageById("msg1").get()
assert dbMsg.seen == true

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
  publicKey: cast[seq[byte]]("public-key"),
  unviewedMessageCount: 3,
  lastClockValue: 18,
  lastMessage: cast[seq[byte]]("lastMessage"),
  members: cast[seq[byte]]("members"),
  membershipUpdates: cast[seq[byte]]("membershipUpdates"),
  profile: "profile",
  invitationAdmin: "invitationAdmin",
  muted: false,
)
db.saveChat(chat)
db.markMessagesSeen("local-chat-id", @["msg1", "msg2"])
dbMsg = db.getMessageById("msg2").get()
var dbChat = db.getChatById("local-chat-id").get()
assert dbMsg.seen == true and dbChat.unviewedMessageCount == 0

# deleteMessage
db.deleteMessage(msg)
var found: bool 
try: 
  discard db.getMessageById("msg2").get()
  found = true
except:
  found = false
assert found == false

db.close()
removeFile(path)
