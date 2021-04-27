import # chat libs
  ./worker

type WorkerPool* = ref object of Worker
  size: int

proc new*(T: type WorkerPool, id: int, size: int = 8): T =
  T(id: id, size: size)

proc `$`*(self: WorkerPool): string =
  $(id: self.id, running: self.running, size: self.size)

proc start*(self: WorkerPool) =
  echo "starting worker pool with id " &
    $self.id &
    " (" & $self.size & " threads)..."
  self.running = true

proc stop*(self: WorkerPool) =
  echo "stopping worker pool with id " &
     $self.id &
     " (" & $self.size & " threads)..."
  self.running = false
