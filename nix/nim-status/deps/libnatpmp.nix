{pkgs, callPackage, stdenv, lib, newScope, xcodeWrapper, platform, arch}:
let 
  flags = callPackage ../getFlags.nix {inherit platform arch;};

  src = pkgs.fetchgit {
    url = "https://github.com/miniupnp/libnatpmp.git";
    rev = "4536032ae32268a45c073a4d5e91bbab4534773a";
    sha256 = "0pq24fha7w7sc3ifyfrpb9ihdbc9zvmlsd56ajy11vg92rzynaxr";
    fetchSubmodules = false;
  };

  osId = builtins.elemAt (builtins.split "\-" stdenv.hostPlatform.system) 2;
in stdenv.mkDerivation {
  name = "libnatpmp";
  inherit src;
  inherit (flags) vars;
  buildInputs = with pkgs; [which];

  phases = ["unpackPhase" "buildPhase" "installPhase"];

  
  buildPhase = ''
    source $stdenv/setup

    ${flags.vars}

    echo "### toolPath"
    echo ${flags.toolPath}

    ${if osId=="Windows" then
    "make --print-data-base CC=\"$CC\" CFLAGS=\"-Wall -Os -DWIN32 -DNATPMP_STATICLIB -DENABLE_STRNATPMPERR -DNATPMP_MAX_RETRIES=4 ${flags.compiler}\" libnatpmp.a"
      else
    "make CC=\"$CC\" CFLAGS=\"-Wall -Os -DENABLE_STRNATPMPERR -DNATPMP_MAX_RETRIES=4 ${flags.compiler}\" libnatpmp.a"
    }
  '';

  installPhase = ''
    mkdir $out
    cp libnatpmp.a $out
  '';
}
