import re

let rePubKey = re("^[0-9a-f]+$", {reIgnoreCase})

proc isHexString*(str: string): bool =
  str.len > 2 and
  str.len mod 2 == 0 and
  str[0..1] == "0x" and
  match(str[2..str.len-1], rePubKey)

proc isPubKey*(str: string): bool =
  str.len == 132 and
  str[0..3] == "0x04" and
  match(str[2..str.len-1], rePubKey)
