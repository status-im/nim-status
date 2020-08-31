proc isHexString*(str: string): bool =
  str.len > 2 and str[0..1] == "0x"
