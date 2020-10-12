if defined(release):
  switch("nimcache", "nimcache/release/$projectName")
else:
  switch("nimcache", "nimcache/debug/$projectName")

--threads:on
--opt:speed # -O3
--debugger:native # passes "-g" to the C compiler
--define:ssl # needed by the stdlib to enable SSL procedures

if defined(macosx):
  --dynliboverrideall # don't use dlopen()
  --tlsEmulation:off
  switch("passL", "-lstdc++")
  # https://code.videolan.org/videolan/VLCKit/-/issues/232
  switch("passL", "-Wl,-no_compact_unwind")
  # set the minimum supported macOS version to 10.13
  switch("passC", "-mmacosx-version-min=10.13")
elif defined(windows):
  --tlsEmulation:off
  switch("passL", "-Wl,-as-needed")
else:
  --dynliboverrideall # don't use dlopen()
  # don't link libraries we're not actually using
  switch("passL", "-Wl,-as-needed")

--define:chronicles_line_numbers # useful when debugging

# The compiler doth protest too much, methinks, about all these cases where it can't
# do its (N)RVO pass: https://github.com/nim-lang/RFCs/issues/230
switch("warning", "ObservableStores:off")

# Too many false positives for "Warning: method has lock level <unknown>, but another method has 0 [LockLevel]"
switch("warning", "LockLevel:off")

#########################################
## from the test files

# from os import getEnv
# {.passL: "-L" & getEnv("STATUSGO_LIB_DIR")}
# {.passL: "-lstatus"}
# when defined(linux):
#   {.passL: "-lcrypto"}
#   {.passL: "-lssl"}
#   {.passL: "-lpcre"}
#   when defined(macosx):
#   {.passL: "bottles/openssl/lib/libcrypto.a"}
#   {.passL: "bottles/openssl/lib/libssl.a"}
#   {.passL: "bottles/pcre/lib/libpcre.a"}
#   {.passL: "-framework CoreFoundation".}
#   {.passL: "-framework CoreServices".}
#   {.passL: "-framework IOKit".}
#   {.passL: "-framework Security".}
#   {.passL: "-headerpad_max_install_names".}
