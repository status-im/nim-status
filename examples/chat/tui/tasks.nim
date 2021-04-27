import # chat libs
  ../task_runner

# how to pass the TaskRunner instance? could be a parameter or maybe it's a
# natural "restriction" to define tasks in location where the TaskRunner
# instance is in scope?

proc bar*() =
  echo "bar"

# define a context proc
