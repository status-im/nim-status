import # std libs
  std/macros

import # client libs
  ./common, ../client/common as client_common

export common

# Events -----------------------------------------------------------------------

macro `&`[T; A, B: static int](a: array[A, T], b: array[B, T]): untyped =
  result = nnkBracket.newTree()

  let
    a = a.getImpl()
    b = b.getImpl()

  for val in a: result.add val
  for val in b: result.add val

const events = clientEvents & TuiEvents

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

# Commands ---------------------------------------------------------------------

macro values[K, V](a: Table[K, V]): untyped =
  result = nnkBracket.newTree()

  let a = a.getImpl()

  for val in a[1][1]:
    if val[0] != newLit(0): result.add val[2]

const commands = values(commands)

macro commandCases*(): untyped =
  result = newStmtList()

  let argsId = ident("args")

  var casenode = newNimNode(nnkCaseStmt)
  casenode.add(ident("commandType"))

  for command in commands:
    let commandType = ident(command)
    var
      ofbranch = newNimNode(nnkOfBranch)
      ofstmt = newStmtList()

    ofbranch.add(newLit(command))
    ofstmt.add(quote do: waitFor self.command(`commandType`.new(`argsId`)))
    ofbranch.add(ofstmt)
    casenode.add(ofbranch)

  result.add(casenode)

macro commandSplitCases*(): untyped =
  result = newStmtList()

  let
    argsId = ident("args")
    argsRawId = ident("argsRaw")

  var casenode = newNimNode(nnkCaseStmt)
  casenode.add(ident("command"))

  for command in commands:
    let commandType = ident(command)
    var
      ofbranch = newNimNode(nnkOfBranch)
      ofstmt = newStmtList()

    ofbranch.add(newLit(command))
    ofstmt.add(quote do: `argsId` = `commandType`.split(`argsRawId`))
    ofbranch.add(ofstmt)
    casenode.add(ofbranch)

  result.add(casenode)

macro buildCommandHelp*(): untyped =
  result = newStmtList()

  let helpId = ident("_help_")
  result.add quote do:
    var `helpId`: seq[HelpText] = @[]

  for command in commands:
    let
      commandType = ident(command)
    result.add(quote do: `helpId`.add(`commandType`.help()))

  result.add quote do:
    `helpId`
