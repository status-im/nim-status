import # std libs
  std/[macros, unicode]

import # chat libs
  ./impl

macro task*(kind: static TaskKind, stoppable: static bool, body: untyped): untyped =
  result = newStmtList()

  const
    star = "*"
    syncPost = "Sync"
    taskArgPost = "TaskArg"
    taskPost = "Task"

  var
    exported = false
    starId = ident(star)
    taskArgTypeId = ident(taskArgPost)
    taskArgTypeDerivedId: NimNode
    taskName: string
    taskNameId: NimNode
    taskNameImplId: NimNode
    taskNameSyncId: NimNode
    taskReturnTypeId: NimNode

  if kind(body[0]) == nnkPostfix and body[0][0] == ident(star):
    exported = true
    taskName = strVal(body[0][1])
    taskNameId = ident(taskName)

  else:
    taskNameId = body[0]
    taskName = strVal(taskNameId)

  taskArgTypeDerivedId = ident(taskName.capitalize & taskArgPost)
  taskNameImplId = ident(taskName & taskPost)
  taskNameSyncId = ident(taskName & syncPost)
  taskReturnTypeId = body[3][0]

  let
    chanReturnToSenderId = ident("chanReturnToSender")
    serializedPointerTypeId = ident("ByteAddress")
    taskStoppedId = ident("taskStopped")

  # The repetitiveness of some code below could/should be cleaned up with
  # additional metaprogramming (and probably more informed use of shortcuts and
  # helpers provided by Nim's macros module); there can be a task options
  # object for which e.g. the `stoppable` field is a boolean flag, but then
  # also a helper object/table with the same fields/keys but the values are
  # tuples of the type names and field names to be added to the type derived
  # from TaskArg; the fields of the supplied/default options object can be
  # iterated over and the proper nnkIdentDefs, etc. can be built according to
  # the options values and info in the helper object/table; the same (or very
  # similar) technique could be used to allow e.g. specification of a
  # TaskRunner instance and/or worker name and/or `ptr Atomic[bool]` (for
  # stopping the task) in the options object, which would then affect whether
  # parameters for those things are included in the type signatures of the
  # constructed procs or instead baked into their bodies.

  var
    taskArgTypeDef = newNimNode(nnkTypeDef)
    objDef = newNimNode(nnkObjectTy)
    recList = newNimNode(nnkRecList)

  taskArgTypeDef.add(taskArgTypeDerivedId)
  taskArgTypeDef.add(newEmptyNode())
  objDef.add(newEmptyNode())
  objDef.add(newNimNode(nnkOfInherit).add(taskArgTypeId))

  if kind == rts:
    var
      objParam = newNimNode(nnkIdentDefs)
      post = newNimNode(nnkPostfix)

    post.add(starId)
    post.add(chanReturnToSenderId)
    objParam.add(post)
    objParam.add(serializedPointerTypeId)
    objParam.add(newEmptyNode())
    recList.add(objParam)

  if stoppable == true:
    var
      objParam = newNimNode(nnkIdentDefs)
      post = newNimNode(nnkPostfix)

    post.add(starId)
    post.add(taskStoppedId)
    objParam.add(post)
    objParam.add(serializedPointerTypeId)
    objParam.add(newEmptyNode())
    recList.add(objParam)

  for nn in body[3]:
    if kind(nn) == nnkIdentDefs:
      var
        objParam = newNimNode(nnkIdentDefs)
        post = newNimNode(nnkPostfix)

      post.add(starId)
      post.add(nn[0])
      objParam.add(post)
      objParam.add(nn[1])
      objParam.add(nn[2])
      recList.add(objParam)

  objDef.add(recList)
  taskArgTypeDef.add(newNimNode(nnkRefTy).add(objDef))
  result.add(newNimNode(nnkTypeSection).add(taskArgTypeDef))

  let
    asyncPragmaId = ident("async")
    atomicTypeId = ident("Atomic")
    boolTypeId = ident("bool")
    futureTypeId = ident("Future")
    taskArgId = ident("taskArg")
    taskArgEncId = ident("taskArgEncoded")
    chanSendToHostId = ident("chanSendToHost")
    chanSendToWorkerId = ident("chanSendToWorker")
    stoppedId = ident("stopped")
    taskRunnerId = ident("taskRunner")
    taskRunnerTypeId = ident("TaskRunner")
    workerChannelTypeId = ident("WorkerChannel")
    workerId = ident("worker")
    workerNameId = ident("workerName")
    workerNameTypeId = ident("string")
    workerRunningId = ident("workerRunning")

  var
    atomPtr = newNimNode(nnkPtrTy)
    atomBracket = newNimNode(nnkBracketExpr)

  atomBracket.add(atomicTypeId)
  atomBracket.add(boolTypeId)
  atomPtr.add(atomBracket)

  let
    taskStoppedTypeId = atomPtr
    workerRunningTypeId = atomPtr

  var impl = newStmtList()

  impl.add quote do:
    let
      `taskArgId` = decode[`taskArgTypeDerivedId`](`taskArgEncId`)
      `chanSendToHostId` = cast[`workerChannelTypeId`](`taskArgId`.`chanSendToHostId`)

  if kind == rts:
    impl.add quote do:
      let `chanReturnToSenderId` = cast[`workerChannelTypeId`](`taskArgId`.`chanReturnToSenderId`)

  if stoppable == true:
    impl.add quote do:
      var `taskStoppedId` = cast[`taskStoppedTypeId`](`taskArgId`.`taskStoppedId`)

  impl.add quote do:
    var `workerRunningId` = cast[`workerRunningTypeId`](`taskArgId`.`workerRunningId`)

  for nn in body[3]:
    if kind(nn) == nnkIdentDefs:
      let id = nn[0]
      impl.add quote do:
        let `id` = `taskArgId`.`id`

  impl.add(body[6])

  result.add quote do:
    const `taskNameImplId`: Task = proc(`taskArgEncId`: string) {.async, gcsafe, nimcall.} =
      `impl`

  var
    taskBody = newStmtList()
    taskSyncBody = newStmtList()
    taskProcDef = newNimNode(nnkProcDef)
    taskProcSyncDef = newNimNode(nnkProcDef)
    taskProcParams = newNimNode(nnkFormalParams)
    stoppedIdentDefs = newNimNode(nnkIdentDefs)
    taskRunnerIdentDefs = newNimNode(nnkIdentDefs)
    workerNameIdentDefs = newNimNode(nnkIdentDefs)

  taskProcDef.add(taskNameId)
  taskProcDef.add(newEmptyNode())
  taskProcDef.add(body[2])
  taskProcParams.add(newEmptyNode())
  taskRunnerIdentDefs.add(taskRunnerId)
  taskRunnerIdentDefs.add(taskRunnerTypeId)
  taskRunnerIdentDefs.add(newEmptyNode())
  taskProcParams.add(taskRunnerIdentDefs)
  workerNameIdentDefs.add(workerNameId)
  workerNameIdentDefs.add(workerNameTypeId)
  workerNameIdentDefs.add(newEmptyNode())
  taskProcParams.add(workerNameIdentDefs)
  if stoppable == true:
    stoppedIdentDefs.add(stoppedId)
    stoppedIdentDefs.add(taskStoppedTypeId)
    stoppedIdentDefs.add(newEmptyNode())
    taskProcParams.add(stoppedIdentDefs)

  for nn in body[3]:
    if kind(nn) == nnkIdentDefs:
      taskProcParams.add(nn)

  taskProcDef.add(taskProcParams)
  taskProcDef.add(newNimNode(nnkPragma).add(asyncPragmaId))
  taskProcDef.add(newEmptyNode())

  copyChildrenTo(taskProcDef, taskProcSyncDef)
  taskProcSyncDef[0] = taskNameSyncId
  taskProcSyncDef[4] = newEmptyNode()

  if kind == rts:
    if kind(taskReturnTypeId) != nnkEmpty:
      var futureBracket = newNimNode(nnkBracketExpr)
      futureBracket.add(futureTypeId)
      futureBracket.add(taskReturnTypeId)
      taskProcDef[3][0] = futureBracket

    taskProcSyncDef[3][0] = taskReturnTypeId

  taskBody.add quote do:
    let
      `workerId` = taskRunner.workers[workerName].worker
      `chanSendToHostId` = `workerId`.chanRecvFromWorker
      `chanSendToWorkerId` = `workerId`.chanSendToWorker

  if kind == rts:
    taskBody.add quote do:
      let `chanReturnToSenderId` = newWorkerChannel()

  taskBody.add quote do:
    let `taskArgId` = `taskArgTypeDerivedId`(
      `chanSendToHostId`: cast[`serializedPointerTypeId`](`chanSendToHostId`),
      task: cast[`serializedPointerTypeId`](`taskNameImplId`),
      taskName: `taskName`,
      `workerRunningId`: cast[`serializedPointerTypeId`](addr taskRunner.running)
    )

  if kind == rts:
    var
      objField = newNimNode(nnkExprColonExpr)
      objConstructor = taskBody[if kind == rts: 2 else: 1][0][2]

    objField.add(chanReturnToSenderId)
    objField.add quote do: cast[`serializedPointerTypeId`](`chanReturnToSenderId`)
    objConstructor.add(objField)

  if stoppable == true:
    var
      objField = newNimNode(nnkExprColonExpr)
      objConstructor = taskBody[if kind == rts: 2 else: 1][0][2]

    objField.add(taskStoppedId)
    objField.add quote do: cast[`serializedPointerTypeId`](`stoppedId`)
    objConstructor.add(objField)

  for nn in body[3]:
    var
      objField = newNimNode(nnkExprColonExpr)
      objConstructor = taskBody[if kind == rts: 2 else: 1][0][2]

    if kind(nn) == nnkIdentDefs:
      objField.add(nn[0])
      objField.add(nn[0])
      objConstructor.add(objField)

  if kind == rts:
    taskBody.add quote do:
      `chanReturnToSenderId`.open()

  copyChildrenTo(taskBody, taskSyncBody)

  taskBody.add quote do:
    asyncSpawn `chanSendToWorkerId`.send(`taskArgId`.encode.safe)

  taskSyncBody.add quote do:
    `chanSendToWorkerId`.sendSync(`taskArgId`.encode.safe)

  if kind == rts:
    if kind(taskReturnTypeId) != nnkEmpty:
      taskBody.add quote do:
        let res = decode[`taskReturnTypeId`]($(await `chanReturnToSenderId`.recv()))
        `chanReturnToSenderId`.close()
        return res

      taskSyncBody.add quote do:
        let res = decode[`taskReturnTypeId`]($`chanReturnToSenderId`.recvSync())
        `chanReturnToSenderId`.close()
        return res

    else:
      taskBody.add quote do:
        discard $(await `chanReturnToSenderId`.recv())
        `chanReturnToSenderId`.close()

      taskSyncBody.add quote do:
        discard $`chanReturnToSenderId`.recvSync()
        `chanReturnToSenderId`.close()

  taskProcDef.add(taskBody)
  taskProcSyncDef.add(taskSyncBody)

  result.add(taskProcDef)
  result.add(taskProcSyncDef)

  if exported:
    result.add quote do:
      export `taskArgTypeDerivedId`, `taskNameId`, `taskNameSyncId`, `taskNameImplId`

  # debug ----------------------------------------------------------------------
  # echo toStrLit(result)

# The approach below doesn't work because unexpected things can happen with the
# AST of `body`, at least that's that what I observed; can look into a
# different approach:
# https://github.com/beef331/kashae/blob/master/src/kashae.nim#L204-L220
# (that approach was recommended in #main channel of the official Nim discord
# server when I asked about the unexpected AST things)

# macro task*(kind: TaskKind, body: untyped): untyped =
#   result = newStmtList()
#   result.add(quote do: task(`kind`, false, `body`))
#
# macro task*(stoppable: bool, body: untyped): untyped =
#   result = newStmtList()
#   result.add(quote do: task(no_rts, `stoppable`, `body`))
#
# macro task*(body: untyped): untyped =
#   result = newStmtList()
#   result.add(quote do: task(no_rts, false, `body`))
