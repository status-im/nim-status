import # client modules
  ./commands as cmd, ./common, ./macros

logScope:
  topics = "tui"

proc parse*(commandRaw: string): (string, seq[string], bool) =
  var
    args: seq[string]
    argsRaw: string
    command: string
    commandRaw = commandRaw
    isCommand = false
    maybeCommand: string

  let
    stripped = commandRaw.strip(trailing = false)
    firstSpace = stripped.find(" ")
    argsStart = firstSpace + 1

  if stripped != "" :

    if stripped[0] != '/':
      command = commands[DEFAULT_COMMAND]
      argsRaw = commandRaw
      commandRaw = "/send " & argsRaw
      isCommand = true

    elif stripped.strip() != "/" and
         stripped.len >= 2 and
         stripped[1..^1].strip(trailing = false) == stripped[1..^1]:

      if firstSpace == -1:
        maybeCommand = stripped[1..^1]
      else:
        maybeCommand = stripped[1..<firstSpace]

        if stripped.len == argsStart:
          argsRaw = ""
        else:
          argsRaw = stripped[argsStart..^1]

      if aliases.hasKey(maybeCommand):
        maybeCommand = aliases[maybeCommand]

      if commands.hasKey(maybeCommand):
        command = commands[maybeCommand]
        isCommand = true

  if isCommand:
    commandSplitCases()
    debug "TUI received command", command=commandRaw
    (command, args, true)
  else:
    ("", @[], false)
