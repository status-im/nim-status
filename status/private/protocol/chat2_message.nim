{.push raises: [Defect].}

import # std libs
  std/times

import # vendor libs
  libp2p/protobuf/minprotobuf

import # status modules
  ../util

export ProtoBuffer, ProtoResult

type
  Chat2Message* = object
    nick*: string
    payload*: seq[byte]
    timestamp*: int64

  Chat2MessageError* = enum
    GetFieldError = "chat2: error getting field from protobuffer"

proc decode*(T: type Chat2Message, input: seq[byte]):
  Result[Chat2Message, Chat2MessageError] =

  var
    msg = Chat2Message()
    timestamp: uint64

  let pb = input.initProtoBuffer

  discard ? pb.getField(1, timestamp).mapErrTo(GetFieldError)
  msg.timestamp = int64(timestamp)
  discard ? pb.getField(2, msg.nick).mapErrTo(GetFieldError)
  discard ? pb.getField(3, msg.payload).mapErrTo(GetFieldError)

  ok(msg)

proc encode*(message: Chat2Message): ProtoBuffer =
  var pb = initProtoBuffer()

  pb.write(1, uint64(message.timestamp))
  pb.write(2, message.nick)
  pb.write(3, message.payload)

  return pb

proc init*(T: type Chat2Message, nick: string, message: string): T =
  let
    payload = message.toBytes
    timestamp = getTime().toUnix

  T(nick: nick, payload: payload, timestamp: timestamp)
