import # vendor libs
  libp2p/[crypto/crypto],
  waku/common/utils/nat,
  waku/v2/node/[wakunode2]

# ------------------------------------------------------------------------------

import std/[tables, strformat, strutils, times, httpclient, json, sequtils, random, options]
import confutils, chronicles, chronos, stew/shims/net as stewNet,
       eth/keys, bearssl, stew/[byteutils, endians2],
       nimcrypto/pbkdf2
import libp2p/[switch,                   # manage transports, a single entry point for dialing and listening
               crypto/crypto,            # cryptographic functions
               stream/connection,        # create and close stream read / write connections
               multiaddress,             # encode different addressing schemes. For example, /ip4/7.7.7.7/tcp/6543 means it is using IPv4 protocol and TCP
               peerinfo,                 # manage the information of a peer, such as peer ID and public / private key
               peerid,                   # Implement how peers interact
               protobuf/minprotobuf,     # message serialisation/deserialisation from and to protobufs
               protocols/protocol,       # define the protocol base type
               protocols/secure/secio,   # define the protocol of secure input / output, allows encrypted communication that uses public keys to validate signed messages instead of a certificate authority like in TLS
               muxers/muxer]             # define an interface for stream multiplexing, allowing peers to offer many protocols over a single connection
import   waku/v2/node/[wakunode2, waku_payload],
         waku/v2/protocol/waku_message,
         waku/v2/protocol/waku_store/waku_store,
         waku/v2/protocol/waku_filter/waku_filter,
         waku/v2/protocol/waku_lightpush/waku_lightpush,
         waku/v2/utils/peers,
         waku/common/utils/nat

# ------------------------------------------------------------------------------

export crypto, nat, wakunode2

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

proc selectRandomNode*(fleetStr: string): string =
  let
    fleet = newHttpClient().getContent("https://fleets.status.im")
    nodes = toSeq(
      fleet.parseJson(){"fleets", "wakuv2." & fleetStr, "waku"}.pairs())

  nodes[rand(nodes.len - 1)].val.getStr()
