import # std libs
  std/[macros, unicode]

import # chat libs
  ./impl

# experimental -----------------------------------------------------------------

macro task*(kind: TaskKind, stoppable: bool, body: untyped): untyped =
  result = newStmtList()

  echo(kind)
  echo(stoppable)
  echo()

  echo(treeRepr body)
  echo()

  const
    star = "*"
    syncPost = "Sync"
    taskArgPost = "TaskArg"
    taskPost = "Task"

  var
    exported = ""
    taskArgName: NimNode
    taskName: NimNode
    taskNameImpl: NimNode
    taskNameSync: NimNode

  if kind(body[0]) == nnkPostfix:
    if body[0][0] == ident(star): exported = star

    let taskNameStr = strVal(body[0][1])
    taskArgName = ident(taskNameStr.capitalize & taskArgPost)
    taskName = ident(taskNameStr & exported)
    taskNameImpl = ident(taskNameStr & taskPost)
    taskNameSync = ident(taskNameStr & syncPost & exported)

  else:
    taskName = body[0]
    let taskNameStr = strVal(taskName)
    taskArgName = ident(taskNameStr.capitalize & taskArgPost)
    taskNameImpl = ident(taskNameStr & taskPost)
    taskNameSync = ident(taskNameStr & syncPost)


  echo taskArgName
  echo taskName
  echo taskNameSync
  echo taskNameImpl

  # debug ----------------------------------------------------------------------
  echo toStrLit(result)


macro task*(kind: TaskKind, body: untyped): untyped =
  result = newStmtList()
  result.add(quote do: task(`kind`, false, `body`))


macro task*(stoppable: bool, body: untyped): untyped =
  result = newStmtList()
  result.add(quote do: task(no_rts, `stoppable`, `body`))


macro task*(body: untyped): untyped =
  result = newStmtList()
  result.add(quote do: task(no_rts, false, `body`))


# usage ------------------------------------------------------------------------

proc hello*[T, U](name: string) {.task.} =
  echo "Hello, " & name & "!"
