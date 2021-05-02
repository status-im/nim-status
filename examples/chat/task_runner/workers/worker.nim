import # chat libs
  ../tasks

export tasks

type Worker* = ref object of RootObj
  context*: Context
  name*: string
