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

proc newTaskRunner*(): TaskRunner =
  new(result)
  result.marathon = newMarathon()

proc init*(self: TaskRunner) =
  self.marathon.init()

proc teardown*(self: TaskRunner) =
  self.marathon.teardown()
