# The code in ./task_runner is intended for eventual inclusion in:
# https://github.com/status-im/nim-task-runner

# The implementation in this repo is the "second nursery" for refining the
# concepts and code involved; the "first nursery" was status-desktop.

import # chat libs
  ./task_runner/impl, ./task_runner/macros

export impl, macros

logScope:
  topics = "task_runner"
