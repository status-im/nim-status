import # nim libs
  os, json, options

import # vendor libs
  sqlcipher, json_serialization, web3/conversions as web3_conversions

import # nim-status libs
  ../../nim_status/lib/[chats, database, conversions]

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd)

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

# saveChat
db.saveChat(chat)

# getChats
chat.id = "local-chat-id-1"
db.saveChat(chat)
var dbChats = db.getChats()
assert len(dbChats) == 2

# getChatById
var dbChat = db.getChatById("local-chat-id").get()
assert dbChat.active == true and
       dbChat.publicKey == cast[seq[byte]]("public-key") and
       dbChat.unviewedMessageCount == 3

# deleteChat
db.deleteChat(chat)
dbChats = db.getChats()
assert len(dbChats) == 1


db.close()
removeFile(path)

