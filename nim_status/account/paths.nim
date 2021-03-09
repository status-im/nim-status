import strutils
import stew/[results]
import ./types

const HARDENED_INDEX: uint32 = cast[uint32](1 shl 31);

proc isNonHardened*(self: PathLevel): bool = (self.uint32 and HARDENED_INDEX) == 0

func parse*(T: type PathLevel, value: string): PathLevelResult =
  var child: string
  var mask: uint32

  if value.endsWith("'"):
    child = value[0..^2]
    mask = HARDENED_INDEX
  else:
    child = value
    mask = 0

  let index: uint32 = parseUInt(child).uint32
  if (index and HARDENED_INDEX) == 0:
    PathLevelResult.ok(PathLevel (index or mask))
  else:
    PathLevelResult.err("Invalid index number")

proc toBEBytes*(x: PathLevel): array[4, byte] =
  # BigEndian
  result[3] = ((x.uint32 shr  0) and 0xff).byte
  result[2] = ((x.uint32 shr  8) and 0xff).byte
  result[1] = ((x.uint32 shr 16) and 0xff).byte
  result[0] = ((x.uint32 shr 24) and 0xff).byte

iterator pathNodes*(path: KeyPath): PathLevelResult =
  try:
    for elem in path.string.split("/"):
      if elem == "m": continue
      yield PathLevel.parse(elem)
  except ValueError:
    doAssert false, "Invalid Key Path"
