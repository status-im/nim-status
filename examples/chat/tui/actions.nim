import # chat libs
  ./commands

export commands

logScope:
  topics = "chat"

# action and command (see ./commands) procs are `{.async.}` for the convenience
# of e.g. interaction with channels and tasks. However, they should be
# self-contained with respect to their effects (with allowance for `await`-ing
# or `waitFor`-ing invocation of another `{.async.}` proc or blocking until
# return of a synchronous proc), i.e. other than invoking tasks (to do work on
# other threads) or sending to a channel (using `asyncSpawn`), they *should
# not* spawn independent asynchronous routines to cause side effects in the
# main thread that would happen *after* the current action/command has
# returned. They should also return as soon as possible and should be
# considered to effectively "block the main thread" while they are
# executing. The time budget for an action, from start to finish and including
# the execution time of procs it may call, is 16 milliseconds so as to maintain
# at least 60 FPS in the TUI.

proc dispatch*(self: ChatTUI, command: string) {.gcsafe, nimcall.}

# InputKeuy --------------------------------------------------------------------

proc action*(self: ChatTUI, event: InputKey) {.async, gcsafe, nimcall.} =
  # handle special keys e.g. arrow keys, ESCAPE, F1, RETURN, et al.
  let
    key = event.key
    name = event.name

  case name:
    of ESCAPE:
      discard

    of RETURN:
      let command = self.currentInput

      if command.strip(trailing = false) != "":
        self.currentInput = ""
        trace "TUI reset current input", currentInput=self.currentInput

        self.clearInput()
        self.dispatch(command)

    else:
      discard

# InputReady -------------------------------------------------------------------

proc action*(self: ChatTUI, event: InputReady) {.async, gcsafe, nimcall.} =
  let
    ready = event.ready

  if ready:
    self.inputReady = true
    self.drawScreen()

# InputString ------------------------------------------------------------------

proc action*(self: ChatTUI, event: InputString) {.async, gcsafe, nimcall.} =
  let
    input = event.str
    shouldPrint = if not self.inputReady: false else: true

  self.currentInput = self.currentInput & input
  trace "TUI updated current input", currentInput=self.currentInput

  if shouldPrint: self.printInput(input)

# UserMessage ------------------------------------------------------------------

proc action*(self: ChatTUI, event: UserMessage) {.async, gcsafe, nimcall.} =
  discard

# ------------------------------------------------------------------------------

proc dispatch*(self: ChatTUI, command: string) {.gcsafe, nimcall.} =
  var (cmd, args, isCmd) = parse(command)

  if isCmd:
    # before `case..of` for commands, check against an "available commands set"
    # that will vary depending on the state of the TUI, e.g. if already logged
    # in or login is in progress, then login command shouldn't be invokable but
    # logout command should be invokable

    # should be able to gen the following code with a template and constant
    # `seq[string]` that contains the names of all the types in ./commands that
    # derive from the Command type defined in that module
    case cmd:
      # of ...:

      of "Help":
        waitFor self.command(Help.new(args))

      of "Login":
        waitFor self.command(Login.new(args))

      of "Logout":
        waitFor self.command(Logout.new(args))

      of "SendMessage":
        waitFor self.command(SendMessage.new(args))

  else:
    # should print an error/explanation to the screen as well
    error "TUI received malformed or unknown command", command
