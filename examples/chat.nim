## chat.nim is an example program demonstrating usage of nim-status, nim-waku,
## nim-task-runner, and nim-ncurses

when not(compileOption("threads")):
  {.fatal: "Please compile this program with the --threads:on option!".}

import # chat libs
  ./chat/tui

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

logScope:
  topics = "chat"

proc main() {.async.} =
  let chatConfig = handleConfig(ChatConfig.load())

  notice "program started"

  var
    tui = ChatTUI.new(chatConfig)
    tuiPtr {.threadvar.}: pointer

  tuiPtr = cast[pointer](tui)
  proc stop() {.noconv.} = waitFor cast[ChatTUI](tuiPtr).stop()
  setControlCHook(stop)

  await tui.start()
  while tui.running: poll()

  notice "program exited"

when isMainModule: waitFor main()
