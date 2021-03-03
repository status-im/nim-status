{ stdenv, lib, fetchFromGitHub, buildGo114Package
# Dependencies
, xcodeWrapper
, go, androidPkgs
# metadata and status-go source
, meta, source
, newScope
# build parameters
, platform ? "android"
, arch ? "386"
, api ? "23" }:

let
  inherit (lib) attrNames attrValues getAttr mapAttrs strings concatStringsSep concatMapStrings;

  callPackage = newScope {};
  flags = callPackage ../nim-status/getFlags.nix {inherit platform arch;};

  removeReferences = [ go ];
  removeExpr = refs: ''remove-references-to ${concatMapStrings (ref: " -t ${ref}") refs}'';

  # Params to be set at build time, important for About section and metrics
  goBuildParams = {
    GitCommit = source.rev;
    Version = source.cleanVersion;
  };

  # Shorthands for the built phase

  isAndroid = lib.hasPrefix "android" platform;
  isIOS = platform == "ios";

  buildMode = if isIOS then "c-archive" else "c-shared";
  libraryFileName = if isIOS then "./libstatus.a" else "./libstatus.so";

  goOs = if isAndroid then "android" else "darwin";

  goArch = 
    if isAndroid then arch
    else if isIOS then (if arch == "386" then "amd64" else arch)
    else throw "Unsupported platform!";

  goTags = if isAndroid then "" else " -tags ios ";

in buildGo114Package rec {
  pname = source.repo;
  version = "${source.cleanVersion}-${source.shortRev}-${platform}-${arch}";

  inherit (source) src goPackagePath ;

  ANDROID_HOME = androidPkgs;
  ANDROID_NDK_HOME = "${androidPkgs}/ndk-bundle";

  preBuildPhase = ''
    ${flags.vars} 
    cd go/src/${goPackagePath}
    mkdir -p ./statusgo-lib
    go run cmd/library/*.go > ./statusgo-lib/main.go

  '';

  buildPhase = ''
    runHook preBuildPhase
    echo "Building shared library..."

    export GOOS=${goOs} GOARCH=${goArch} API=${api}

    export CGO_CFLAGS="${flags.compiler}"
    export CGO_LDFLAGS="${flags.linker} ${if isAndroid then "-v -Wl,-soname,libstatus.so" else ""}"
    export CGO_ENABLED=1

    ${flags.vars} 

    go build \
       -v \
      -buildmode=${buildMode} \
      ${goTags} \
      -o ${libraryFileName} \
      $BUILD_FLAGS \
      ./statusgo-lib

    echo "Shared library built:"
    ls -la ./libstatus.*
  '';

  fixupPhase = ''
    find $out -type f -exec ${removeExpr removeReferences} '{}' + || true
  '';

  installPhase = ''
    mkdir -p $out
    cp ./libstatus.* $out/
  '';

  outputs = [ "out" ];
}
