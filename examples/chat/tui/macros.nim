import # std libs
  std/macros

import # chat libs
  ./common

export common

macro `&`[T; A, B: static int](a: array[A, T], b: array[B, T]): untyped =
  var
    a = a.getImpl
    b = b.getImpl

  result = nnkBracket.newTree

  for val in a:
    result.add val
  for val in b:
    result.add val

const events = clientEvents & TUIEvents

macro eventCases*(): untyped =
  result = newStmtList()

  let eventId = ident("event")

  var casenode = newNimNode(nnkCaseStmt)
  casenode.add(ident("eventType"))

  for event in events:
    let eventType = ident(event)
    var
      ofbranch = newNimNode(nnkOfBranch)
      ofstmt = newStmtList()

    ofbranch.add(newLit(event))
    ofstmt.add(quote do: waitfor self.action(decode[`eventType`](`eventId`)))
    ofbranch.add(ofstmt)
    casenode.add(ofbranch)

  var elsecase = newNimNode(nnkElse)
  elsecase.add(quote do: error "TUI received unknown event type", `eventId`)
  casenode.add(elsecase)

  result.add(casenode)
