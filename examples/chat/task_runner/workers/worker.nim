import # chat libs
  ../tasks

export tasks

type Worker* = ref object of RootObj
  context*: Context
  contextArg*: ContextArg
  name*: string
