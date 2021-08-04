import # std libs
  std/tables

type
  MigrationDefinition* = ref object of RootObj
    migrationUp*:OrderedTable[string, seq[byte]]
    migrationDown*:OrderedTable[string, seq[byte]]
