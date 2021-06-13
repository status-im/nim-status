import # chat libs
  ./events

export events

logScope:
  topics = "chat"

var
  chat2WakuRunning {.threadvar.}: bool
  counter {.threadvar.}: int
  nick {.threadvar.}: string

# could eventually have a custom ContextArg for specifying e.g. port number to
# listen on, as well other status/waku settings that were supplied on the
# command-line
proc statusContext*(arg: ContextArg) {.async, gcsafe, nimcall.} =
  chat2WakuRunning = false
  counter = 1

proc startChat2Waku*(username: string) {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  if not chat2WakuRunning:
    chat2WakuRunning = true
    nick = username
    while workerRunning[].load() and chat2WakuRunning:
      await sleepAsync 1.seconds
      let message = UserMessage(
        username: task,
        message: "message " & $counter & " to " & nick
      )
      asyncSpawn chanSendToHost.send(message.encode.safe)
      counter = counter + 1

proc stopChat2Waku*() {.task(kind=no_rts, stoppable=false).} =
  let task = taskArg.taskName

  if chat2WakuRunning: chat2WakuRunning = false
