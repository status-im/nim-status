import # vendor libs
  chronicles, task_runner

import # chat libs
  ./marathon

export marathon, task_runner

logScope:
  topics = "task-runner"

type
  TaskRunner* = ref object
    marathon*: Marathon

proc new*(T: type TaskRunner): T =
  T(marathon: Marathon.new())

proc init*(self: TaskRunner) =
  self.marathon.init()

proc teardown*(self: TaskRunner) =
  self.marathon.teardown()
