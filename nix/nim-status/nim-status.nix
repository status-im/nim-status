{ pkgs, stdenv, lib, fetchFromGitHub
# Dependencies
, xcodeWrapper
, writeScript
, androidPkgs
, newScope
, git 
, platform ? "android"
, arch ? "386"
, api ? "23" } :


let
  callPackage = newScope {};
  src = pkgs.fetchgit {
    url = "https://github.com/status-im/nim-status";
    rev = "40b935eb2676a449745e81eca72be492517f4136";
    sha256 = "1bnilbv76q4mrkkwcl72z99bnmwk45kv9g12m26wvy2dlkr353px";
    fetchSubmodules = false;
  };

  flags = callPackage ./getFlags.nix {inherit platform arch; fromNim = true;};

  nimblepath = callPackage ./deps/nimblepath.nix {};
  nimBase = ./nimbase.h;
in stdenv.mkDerivation rec {
  name = "nim-status_lib";
  inherit src platform arch;
  buildInputs = with pkgs; [ nim which binutils-unwrapped ];

  phases = ["unpackPhase" "preBuildPhase" "buildPhase" "installPhase"];

  preBuildPhase = ''
    mkdir ./nim_status/c/go/include
    mkdir ./include

    ${flags.vars}

    cp ${nimBase} ./nim_status/c/go/include/nimbase.h
    cp ${nimBase} ./include/nimbase.h

    mkdir nimbledeps
    ln -sf ${nimblepath} nimbledeps/pkgs

    export INCLUDE_PATH=`pwd`/include
    export NIMBLE_DIR=`pwd`/nimbledeps


    # Migrations
    nim c --verbosity:1 \
      --cc:clang \
      --overflowChecks:off \
      -d:nimEmulateOverflowChecks \
      --cincludes:$INCLUDE_PATH \
      --nimcache:nimcache/migrations \
      nim_status/migrations/sql_generate.nim

	  nim_status/migrations/sql_generate nim_status/migrations/accounts > nim_status/migrations/sql_scripts_accounts.nim
	  nim_status/migrations/sql_generate nim_status/migrations/app > nim_status/migrations/sql_scripts_app.nim

    echo 'switch("passC", "${flags.compiler}")' >> config.nims
    echo 'switch("passL", "${flags.linker}")' >> config.nims
    echo 'switch("cpu", "${flags.nimCpu}")' >> config.nims
    echo 'switch("os", "${flags.nimPlatform}")' >> config.nims

    echo 'put "${flags.nimCpu}.${flags.nimPlatform}.clang.path", "${flags.toolPath}"' >> config.nims
    echo 'put "${flags.nimCpu}.${flags.nimPlatform}.clang.exe", "clang"' >> config.nims
    echo 'put "${flags.nimCpu}.${flags.nimPlatform}.clang.linkerexe", "clang"' >> config.nims


  '';

  buildPhase = ''
    echo -e "Building Nim-Status Go shim"
    export INCLUDE_PATH=./include
    export NIMBLE_DIR=`pwd`/nimbledeps


    # Need -d:nimEmulateOverflowChecks,
    # otherwise compiler will complain about
    # undefined nimMulInt/nimAddInt functions
    # https://github.com/nim-lang/Nim/issues/13645#issuecomment-601037942
    # https://github.com/nim-lang/Nim/pull/13692

  	nim c \
		--app:staticLib \
    --cc:clang \
    --verbosity:1 \
		--header \
    -d:nimEmulateOverflowChecks \
		--nimcache:nimcache/nim_status \
		--noMain \
		--threads:on \
		--tlsEmulation:off \
		-o:nim_status.a \
		nim_status/c/shim.nim


  '';

  installPhase = ''
    mkdir $out
    cp nimcache/nim_status/shim.h $out/nim_status.h
    cp ./nim_status/c/go/include/nimbase.h $out/
    mv nim_status.a $out/libnim_status.a
  '';
}
