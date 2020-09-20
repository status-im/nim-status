when defined(macosx):
  import algorithm, strutils

if defined(release):
  switch("nimcache", "nimcache/release/$projectName")
else:
  switch("nimcache", "nimcache/debug/$projectName")

--threads:on
--opt:speed # -O3
--debugger:native # passes "-g" to the C compiler
--dynliboverrideall # don't use dlopen()
--define:ssl # needed by the stdlib to enable SSL procedures

#--cc:"/clang"
# put "i386.android.clang.path", getEnv("ANDROID_NDK") & "/toolchains/llvm/prebuilt/darwin-x86_64/bin"
# put "i386.android.clang.exe", "clang"

# put "i386.android.ar.path", getEnv("ANDROID_NDK") & "/toolchains/llvm/prebuilt/darwin-x86_64/bin"
# put "i386.android.ar.exe", "i686-linux-android-ar"

# put "i386.android.ranlib.path", getEnv("ANDROID_NDK") & "/toolchains/llvm/prebuilt/darwin-x86_64/bin"
# put "i386.android.ranlib.exe", "i686-linux-android-ranlib"

# put "amd64.android.ld.path", getEnv("ANDROID_NDK") & "/toolchains/llvm/prebuilt/darwin-x86_64/bin"
# put "amd64.android.ld.exe", "i686-linux-android-ld"
#switch("passC", "-isysroot " & getEnv("ANDROID_NDK") & "/sysroot -target i686-linux-android23")
#switch("passL", "--sysroot " & getEnv("ANDROID_NDK") & "/platforms/android-23/arch-x86")
#switch("passL", "-target i686-linux-android")

if defined(macosx):
  --tlsEmulation:off
  switch("passL", "-lstdc++")
  # statically linke these libs
  switch("passL", "bottles/openssl/lib/libcrypto.a")
  switch("passL", "bottles/openssl/lib/libssl.a")
  switch("passL", "bottles/pcre/lib/libpcre.a")
  # https://code.videolan.org/videolan/VLCKit/-/issues/232
  switch("passL", "-Wl,-no_compact_unwind")
  # set the minimum supported macOS version to 10.13
  # switch("passC", "-mmacosx-version-min=10.13")
else:
  # dynamically link these libs, since we're opting out of dlopen()
  switch("passL", "-lcrypto")
  switch("passL", "-lssl")
  # don't link libraries we're not actually using
  switch("passL", "-Wl,-as-needed")

--define:chronicles_line_numbers # useful when debugging

# The compiler doth protest too much, methinks, about all these cases where it can't
# do its (N)RVO pass: https://github.com/nim-lang/RFCs/issues/230
switch("warning", "ObservableStores:off")

# Too many false positives for "Warning: method has lock level <unknown>, but another method has 0 [LockLevel]"
switch("warning", "LockLevel:off")

