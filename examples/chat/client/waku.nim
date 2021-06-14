import # vendor libs
  libp2p/[crypto/crypto],
  waku/common/utils/nat,
  waku/v2/node/[wakunode2]

export crypto, nat, wakunode2

type
  PrivateKey* = crypto.PrivateKey
  Topic* = wakunode2.Topic
  WakuState* = enum stopped, starting, started, stopping

const
  PayloadV1* {.booldefine.} = false
  DefaultTopic* = "/waku/2/default-waku/proto"
