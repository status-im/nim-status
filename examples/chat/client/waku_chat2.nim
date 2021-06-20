import # std libs
  std/[json, options, random, sequtils, strutils, tables, times, uri]

import # vendor libs
  bearssl, chronicles, chronos, chronos/apps/http/httpclient, eth/keys,
  libp2p/[crypto/crypto, crypto/secp, multiaddress, muxers/muxer, peerid,
          peerinfo, protobuf/minprotobuf, protocols/protocol,
          protocols/secure/secio, stream/connection, switch],
  nimcrypto/[pbkdf2, utils],
  stew/[byteutils, endians2, results],
  waku/common/utils/nat,
  waku/v2/node/[waku_payload, wakunode2],
  waku/v2/protocol/[waku_filter/waku_filter, waku_lightpush/waku_lightpush,
                    waku_message, waku_store/waku_store]

export
  byteutils, crypto, keys, minprotobuf, nat, results, secp, utils, waku_message,
  wakunode2

logScope:
  topics = "chat client"

type
  Chat2Message* = object
    nick*: string
    payload*: seq[byte]
    timestamp*: int64

  PrivateKey* = crypto.PrivateKey

  Topic* = wakunode2.Topic

  WakuState* = enum stopped, starting, started, stopping

const
  DefaultTopic* = "/waku/2/default-waku/proto"
  PayloadV1* {.booldefine.} = false

# Initialize the default random number generator, only needs to be called once:
# https://nim-lang.org/docs/random.html#randomize
randomize()

proc encode*(message: Chat2Message): ProtoBuffer =
  result = initProtoBuffer()
  result.write(1, uint64(message.timestamp))
  result.write(2, message.nick)
  result.write(3, message.payload)

proc init*(T: type Chat2Message, buffer: seq[byte]): ProtoResult[T] =
  var msg = Chat2Message()
  let pb = initProtoBuffer(buffer)

  var timestamp: uint64
  discard ? pb.getField(1, timestamp)
  msg.timestamp = int64(timestamp)

  discard ? pb.getField(2, msg.nick)
  discard ? pb.getField(3, msg.payload)

  ok(msg)

proc init*(T: type Chat2Message, nick: string, message: string): T =
  let
    payload = message.toBytes()
    timestamp = getTime().toUnix()

  T(nick: nick, payload: payload, timestamp: timestamp)

proc generateSymKey*(contentTopic: ContentTopic): SymKey =
  var
    ctx: HMAC[sha256]
    symKey: SymKey

  if pbkdf2(ctx, contentTopic.toBytes(), "", 65356, symKey) != sizeof(SymKey):
    raise (ref Defect)(msg: "Should not occur as array is properly sized")

  symKey

proc selectRandomNode*(fleetStr: string): Future[string] {.async.} =
  let
    url = "https://fleets.status.im"
    response = await fetch(HttpSessionRef.new(), parseUri(url))
    fleet = string.fromBytes(response.data)
    nodes = toSeq(
      fleet.parseJson(){"fleets", "wakuv2." & fleetStr, "waku"}.pairs())

  return nodes[rand(nodes.len - 1)].val.getStr()
