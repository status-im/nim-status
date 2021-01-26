import
  chronos,
  chronicles,
  confutils,
  stew/results,
  unittest,
  waku/v2/node/[config, wakunode2],
  waku/v2/protocol/waku_message

import
  ../../nim_status/waku,
  ./test_helpers

# This test suite is essentially a "smoke test" for using nim-waku v2 from
# within nim-status and should be replaced by tests focused on nim-status'
# particular usage of nim-waku as the nim-status library evolves

procSuite "waku node":
  asyncTest "basic subscribe and publish":
    let
      futures = [newFuture[int](), newFuture[int]()]
      message1 = WakuMessage(payload: cast[seq[byte]]("hello"),
        contentTopic: ContentTopic(1))
      message2 = WakuMessage(payload: cast[seq[byte]]("world"),
        contentTopic: ContentTopic(1))
      done = WakuMessage(payload: cast[seq[byte]]("test done"),
        contentTopic: ContentTopic(1))
      timeout = 5.minutes
      topic = "testing"
    var nodeConfig = WakuNodeConf.load()
    nodeConfig.portsShift = 5432
    let node = initNode(nodeConfig)
    var successes = 0

    proc handler(topic: Topic, data: seq[byte]) {.async.} =
      let
        message = WakuMessage.init(data).value
        payload = cast[string](message.payload)
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
    await node.mountRelay()
    await node.subscribe(topic, handler)
    await node.publish(topic, message1)
    await node.publish(topic, message2)
    await node.publish(topic, done)

    check:
      await allFutures(futures).withTimeout(timeout)
