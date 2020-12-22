import os, tables, strutils
import stew/byteutils

var upScripts = initOrderedTable[string, string]()
var downScripts = initOrderedTable[string, string]()

for kind, path in walkDir(currentSourcePath.parentDir):
  let (dir, name, ext) = splitFile(path)
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
echo "import tables\n"
echo "var migrationUp*:OrderedTable[string, seq[byte]] = {"
for name, query in upScripts.pairs():
  echo "  \"" & name & "\": " & query.toBytes().print & ","
echo "}.toOrderedTable\n"
echo "var migrationDown*:OrderedTable[string, seq[byte]] = {"
for name, query in downScripts.pairs():
  echo "  \"" & name & "\": " & query.toBytes().print & ","
echo "}.toOrderedTable\n"