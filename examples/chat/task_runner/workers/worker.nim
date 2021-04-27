type Worker* = ref object of RootObj
  id*: int
  running*: bool

proc `$`*(self: Worker): string =
  $(id: self.id, running: self.running)
