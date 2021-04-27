import # chat libs
  ./worker

type WorkerThread* = ref object of Worker
  name: string

proc new*(T: type WorkerThread, id: int, name: string): T =
  T(id: id, name: name)

proc `$`*(self: WorkerThread): string =
  $(id: self.id, name: self.name, running: self.running)

proc start*(self: WorkerThread) =
  echo "starting worker thread named " & self.name & "..."
  self.running = true

proc stop*(self: WorkerThread) =
  echo "stopping worker thread named " & self.name & "..."
  self.running = false
