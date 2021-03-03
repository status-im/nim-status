{ pkgs, stdenv, lib, fetchFromGitHub
# Dependencies
, callPackage
, xcodeWrapper
, writeScript
, androidPkgs
, git 
, platform ? "android"
, arch ? "386"
, api ? "23" } :


let
  src = pkgs.fetchurl {
    name = "openssl-source.tar.gz";
    url = "https://www.openssl.org/source/openssl-1.1.1h.tar.gz";
    sha256 = "5c9ca8774bd7b03e5784f26ae9e9e6d749c9da2438545077e6b3d755a06595d9";

  };

  flags = callPackage ../getFlags.nix {inherit platform arch;};
  androidConfigureArchMap = {
    "386" = "x86";
    "arm" = "arm";
    "arm64" = "arm64";
  };

  iosConfigureArchMap = {
    "386" = "iossimulator";
    "arm" = "ios";
    "arm64" = "ios64";
  };

  configureArch = if flags.isAndroid then "android-${lib.getAttr arch androidConfigureArchMap}"
                  else if flags.isIOS then "${lib.getAttr arch iosConfigureArchMap}-xcrun"
                  else throw "Unsupported platform!";
  configureFlags = if flags.isAndroid then "-D__ANDROID_API__=${api}"
                   else if flags.isIOS then ""
                   else throw "Unsupported platform!";

  compilerFlags = if flags.isAndroid then "" else flags.compiler;
  linkerFlags = if flags.isAndroid then "" else flags.linker;

  ANDROID_NDK_HOME = "${androidPkgs}/ndk-bundle";
in stdenv.mkDerivation rec {
  name = "openssl_lib";
  inherit src ANDROID_NDK_HOME;
  buildInputs = with pkgs; [ perl ];

  phases = ["unpackPhase" "configurePhase" "buildPhase" "installPhase"];

  configurePhase = ''
    source $stdenv/setup

    ${flags.vars}
    patchShebangs .
	  ./Configure ${configureArch} ${configureFlags} CFLAGS="${compilerFlags}" LDFLAGS="${linkerFlags}" -no-shared
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out
    mkdir $out/include
    mkdir $out/lib
    cp -r include/* $out/include/
    cp libcrypto.a $out/lib
    cp libssl.a $out/lib
  '';
}
