{ pkgs, stdenv, lib, fetchFromGitHub
# Dependencies
, xcodeWrapper
, writeScript
, androidPkgs
, git 
, platform ? "android"
, arch ? "386"
, fromNim ? false
, api ? "23" } :


let
  ANDROID_NDK_HOME = "${androidPkgs}/ndk-bundle";

  # Used for the -arch parameter
  # passed to clang during iOS builds
  iosArch = lib.getAttr arch {
    "386" = "x86_64";
    "arm" = "armv7";
    "arm64" = "arm64";
  };
  iosSdk = if arch == "386" then "iphonesimulator" else "iphoneos";

  isAndroid = lib.hasPrefix "android" platform;
  isIOS = platform == "ios";

  # Specify host system in order to pick proper toolchain during Android compilation
  osId = builtins.elemAt (builtins.split "\-" stdenv.hostPlatform.system) 2;
  osArch = builtins.elemAt (builtins.split "\-" stdenv.hostPlatform.system) 0;

  androidTargetArch = lib.getAttr arch {
    "386" = "i686";
    "arm" = "arm";
    "arm64" = "aarch64";
  };
  androidTarget = "${if arch == "arm" then "armv7a" else androidTargetArch}-linux-${platform}";

  androidToolPath = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${osId}-${osArch}/bin";
  androidToolPathPrefix = "${androidToolPath}/${androidTargetArch}-linux-${platform}";



  routeHeader = builtins.readFile ./deps/route.h;
  iosIncludes = stdenv.mkDerivation {
    name = "nim-status-ios-includes";
    buildInputs = [ pkgs.coreutils ];
    builder = writeScript "nim-ios-includes.sh"
    ''
      export PATH=${pkgs.coreutils}/bin
      mkdir $out
      cd $out
      mkdir net
      echo "${routeHeader}" > net/route.h
    '';
  };



  isysroot = if isAndroid then 
    "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${osId}-${osArch}/sysroot"             
    else "$(xcrun --sdk ${iosSdk} --show-sdk-path)";

  compilerFlags = if isAndroid then
      "-isysroot ${isysroot} -target ${androidTarget}${api} -fPIC"
      else if isIOS then
      # TODO The conditional for -miphoneos-version-min=8.0 is required,
      # otherwise Nim will complain that thread-local storage is not supported for the current target
      # when expanding 'NIM_THREADVAR' macro
      "-isysroot ${isysroot}  -I${iosIncludes} -fembed-bitcode -arch ${iosArch} ${if fromNim && arch == "arm" then "" else "-m${iosSdk}-version-min=8.0"}"
      else throw "Unsupported platform!";

  linkerFlags = if isAndroid then  
  "--sysroot ${isysroot} -target ${androidTarget}${api}"
  else if isIOS then
  "--sysroot ${isysroot} -arch ${iosArch} -fembed-bitcode ${if fromNim && arch == "arm" then "" else "-m${iosSdk}-version-min=8.0"}"
  else throw "Unsupported platform!";


  iosToolPath = "${xcodeWrapper}/bin";

  compilerVars = if isAndroid then
    ''
      export PATH=${androidToolPath}:$PATH
      export AR=${androidToolPathPrefix}-ar
      export RANLIB=${androidToolPathPrefix}-ranlib
      # go build will use this
      export CC="${androidToolPath}/clang"
      export OS=android

      # This is important, otherwise Nim might not use proper tooling
      mkdir tmp_bin
      ln -s $AR tmp_bin/ar
      ln -s $RANLIB tmp_bin/ranlib
      export PATH=`pwd`/tmp_bin:$PATH
    ''
    else if isIOS then
    ''
      export PATH=${pkgs.binutils-unwrapped}/bin:${iosToolPath}:$PATH
      export OS=ios
      export CC="${iosToolPath}/clang"
    ''
    else throw "Unsupported platform!";

  toolPath = if isAndroid then androidToolPath else iosToolPath;
  hostMap = {
    "386" = "x86";
    "arm" = "arm";
    "arm64" = "aarch64";
  };
  hostFlag = if isAndroid then androidTarget else lib.getAttr arch hostMap;

  # Arg arch -> Nim arch
  nimCpuMap = {
    "386" = "i386";
    "x86_64" = "amd64"; 
    "arm" = "arm"; 
    "arm64" = "arm64";
  };

  nimCpu = if arch=="386" && platform == "ios" then "amd64" else "${lib.getAttr arch nimCpuMap}";
  nimPlatform = "${(if platform == "ios" then "ios" else "android")}";

in {
  "compiler" = compilerFlags;
  "linker" = linkerFlags;
  "vars" = compilerVars;
  "host" = hostFlag;
  "isysroot" = isysroot;
  "isAndroid" = isAndroid;
  "isIOS" = isIOS;
  "toolPath" = toolPath;
  "nimCpu" = nimCpu;
  "nimPlatform" = nimPlatform;
}
