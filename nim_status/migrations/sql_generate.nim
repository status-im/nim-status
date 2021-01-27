import os, tables, strutils
import stew/byteutils

var upScripts = initOrderedTable[string, string]()
var downScripts = initOrderedTable[string, string]()

for kind, path in walkDir(paramStr(1)):
  let (_, name, ext) = splitFile(path)
  if ext != ".sql": continue

  let parts = name.split(".")
  let script = parts[0]
  let direction = parts[1]

  case direction:
  of "up":
    upScripts[script] = readFile(path)
  of "down":
    downScripts[script] = readFile(path)
  else:
    echo "Invalid script: ", name
    quit()

proc print(self: seq[byte]): string =
  result &= "@["
  for index, elem in self:
    result &= $elem
    if(index == 0): result &= ".uint8"
    if (index < self.len - 1): result &= ", "
  result &= "]"

upScripts.sort(system.cmp)
downScripts.sort(system.cmp)

echo "# THIS FILE IS AUTOGENERATED - DO NOT MODIFY MANUALY - USE make migrations"
echo "import tables"
echo "import types\n"
echo "proc newMigrationDefinition*(): MigrationDefinition ="
echo "  result = MigrationDefinition()"
echo "  result.migrationUp = initOrderedTable[string, seq[byte]]()"
echo "  result.migrationDown = initOrderedTable[string, seq[byte]]()"
for name, query in upScripts.pairs():
  echo "  result.migrationUp[\"" & name & "\"] = " & query.toBytes().print
for name, query in downScripts.pairs():
  echo "  result.migrationDown[\"" & name & "\"] = " & query.toBytes().print
