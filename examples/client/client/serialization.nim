import # vendor libs
  eth/common, json_serialization

proc writeValue*(writer: var JsonWriter, value: ChainId) =
  writeValue(writer, uint64 value)

proc readValue*(reader: var JsonReader, value: var ChainId) =
  value = ChainId reader.readValue(uint64)