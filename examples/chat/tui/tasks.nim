import # chat libs
  ./common

export common

logScope:
  topics = "chat"

# EventTUI types are defined in ./common because procs in this module and
# `dispatch` et al. in ./events make use of them

proc foo*() =
  echo "foo"
