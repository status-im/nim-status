{.passL:"vendor/status-go/build/bin/libstatus.a"}

import ../src/nim_status

echo "Executing test 1"
assert hashMessage("qwerty") == """{"result":"0xfeeeea836fc42840b42a5af9bdcdab1d0e3a9b5168bf46fa25c3704c810eadbe"}"""