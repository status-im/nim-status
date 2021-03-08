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
  name = "nim-status-go_lib";
  inherit src platform arch;
  buildInputs = with pkgs; [ nim which];

  phases = ["unpackPhase" "preBuildPhase" "buildPhase" "installPhase"];

  preBuildPhase = ''
    echo 'switch("passC", "${flags.compiler}")' >> config.nims
    echo 'switch("passL", "${flags.linker}")' >> config.nims
    echo 'switch("cpu", "${flags.nimCpu}")' >> config.nims
    echo 'switch("os", "${flags.nimPlatform}")' >> config.nims

    echo 'put "${flags.nimCpu}.${flags.nimPlatform}.clang.path", "${flags.toolPath}"' >> config.nims
    echo 'put "${flags.nimCpu}.${flags.nimPlatform}.clang.exe", "clang"' >> config.nims
    echo 'put "${flags.nimCpu}.${flags.nimPlatform}.clang.linkerexe", "clang"' >> config.nims

    mkdir ./nim_status/c/go/include
    cp ${nimBase} ./nim_status/c/go/include/nimbase.h

    mkdir nimbledeps
    ln -sf ${nimblepath} nimbledeps/pkgs

    # Migrations
	  # nim c --cc:clang --verbosity:0 nim_status/migrations/sql_generate.nim
	  # nim_status/migrations/sql_generate nim_status/migrations/accounts > nim_status/migrations/sql_scripts_accounts.nim
	  # nim_status/migrations/sql_generate nim_status/migrations/app > nim_status/migrations/sql_scripts_app.nim
  '';

  buildPhase = ''
    ${flags.vars}

    echo -e "Building Nim-Status Go shim"
    export INCLUDE_PATH=./include
    export NIMBLE_DIR=`pwd`/nimbledeps


    # Need -d:nimEmulateOverflowChecks,
    # otherwise compiler will complain about
    # undefined nimMulInt/nimAddInt functions
    # https://github.com/nim-lang/Nim/issues/13645#issuecomment-601037942
    # https://github.com/nim-lang/Nim/pull/13692

    # nim c \
    #   --cincludes:$INCLUDE_PATH \
    #   --app:staticLib \
    #   --cc:clang \
    #   --header \
    #   --nimcache:nimcache/nim_status_go \
    #   --noMain \
    #   -d:nimEmulateOverflowChecks \
    #   --threads:on \
    #   --tlsEmulation:off \
    #   -o:nim_status_go.a \
    #   nim_status/c/go/shim.nim

    echo '### nimble_dir'
    echo $NIMBLE_DIR
    nim --version

  	nim c \
		--app:staticLib \
		--header \
		--nimcache:nimcache/nim_status \
		--noMain \
		--threads:on \
		--tlsEmulation:off \
		-o:nim_status.a \
		nim_status/c/shim.nim


  '';

  installPhase = ''
    mkdir $out
    cp nimcache/nim_status_go/shim.h $out/nim_status.h
    cp ./nim_status/c/go/include/nimbase.h $out/
    mv nim_status_go.a $out/libnim_status.a
  '';
}
