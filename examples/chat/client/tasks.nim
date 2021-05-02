import # chat libs
  ../task_runner

# how to pass the TaskRunner instance? could be a parameter or maybe it's a
# natural "restriction" to define tasks in location where the TaskRunner
# instance is in scope? Can maybe have a simple template that invokes the
# createTask template

proc foo*() =
  echo "foo"

# define a Context proc
