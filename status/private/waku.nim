{.push raises: [Defect].}

# imports and exports in this module need to be checked, some don't seem to be
# necessary even though the compiler doesn't warn about unused imports

import # std libs
  std/[json, options, random, sequtils, strutils, tables, uri]

import # vendor libs
  bearssl, chronos, chronos/apps/http/httpclient, eth/keys,
  libp2p/[crypto/crypto, crypto/secp, multiaddress, muxers/muxer, peerid,
          peerinfo, protocols/protocol, stream/connection, switch],
  nimcrypto/utils,
  stew/[byteutils, endians2, results, shims/net],
  waku/common/utils/nat,
  waku/v2/node/wakunode2,
  waku/v2/protocol/[waku_filter/waku_filter, waku_lightpush/waku_lightpush,
                    waku_message, waku_store/waku_store],
  waku/v2/utils/peers,
  waku/whisper/whisper_types

export # modules
  byteutils, crypto, keys, nat, net, peers, results, secp, wakunode2,
  whisper_types

type
  PrivateKey* = crypto.PrivateKey

  Topic* = wakunode2.Topic

  WakuFleet* = enum none, prod, test

const DefaultTopic* = "/waku/2/default-waku/proto"

proc selectRandomNode*(fleetStr: string): Future[string] {.async.} =
  let
    url = "https://fleets.status.im"
    response = await fetch(HttpSessionRef.new(), parseUri(url))
    fleet = string.fromBytes(response.data)
    nodes = toSeq(
      fleet.parseJson(){"fleets", "wakuv2." & fleetStr, "waku"}.pairs())

  return nodes[rand(nodes.len - 1)].val.getStr()
