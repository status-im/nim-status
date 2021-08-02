import # std libs
  std/unittest

import # vendor libs
  chronicles, chronos, confutils,
  stew/[byteutils, results],
  waku/v2/node/[config, wakunode2],
  waku/v2/protocol/waku_message

import # status lib
  status/private/waku

import # test modules
  ./test_helpers

# This test suite is essentially a "smoke test" for using nim-waku v2 from
# within nim-status and should be replaced by tests focused on nim-status'
# particular usage of nim-waku as the nim-status library evolves

procSuite "waku_smoke":
  asyncTest "waku_smoke":
    let
      futures = [newFuture[int](), newFuture[int]()]
      cTopic = "test"
      message1 = WakuMessage(payload: "hello".toBytes(),
        contentTopic: ContentTopic(cTopic))
      message2 = WakuMessage(payload: "world".toBytes(),
        contentTopic: ContentTopic(cTopic))
      done = WakuMessage(payload: "test done".toBytes(),
        contentTopic: ContentTopic(cTopic))
      timeout = 5.minutes
      topic = "testing"
    var nodeConfig = WakuNodeConf.load()
    nodeConfig.portsShift = 5432
    let node = initNode(nodeConfig)
    var successes = 0

    proc handler(topic: Topic, data: seq[byte]) {.async.} =
      let
        message = WakuMessage.init(data).value
        payload = string.fromBytes(message.payload)
      info "message received", topic=topic, payload=payload,
        contentTopic=message.contentTopic
      if payload == "hello":
        futures[0].complete(1)
        successes += 1
      elif payload == "world":
        futures[1].complete(1)
        successes += 1
      elif successes == 2:
        await node.stop()

    await node.start()
    node.mountRelay()
    node.subscribe(topic, handler)
    await node.publish(topic, message1)
    await node.publish(topic, message2)
    await node.publish(topic, done)

    check:
      await allFutures(futures).withTimeout(timeout)
