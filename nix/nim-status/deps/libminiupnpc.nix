{pkgs, callPackage, stdenv, lib, newScope, xcodeWrapper, platform, arch}:
let 
  flags = callPackage ../getFlags.nix {inherit platform arch;};

  src = pkgs.fetchgit {
    url = "https://github.com/miniupnp/miniupnp";
    rev = "f5f693876db9b1d1328811ffc4f3ef4903b965ca";
    sha256 = "0h2648m3dzqqv0111a6qkz3lf2af05p0ij7kyrwwajy9s1gl5brk";
    fetchSubmodules = false;
  };

  osId = builtins.elemAt (builtins.split "\-" stdenv.hostPlatform.system) 2;
in stdenv.mkDerivation {
  name = "libminiupnpc";
  inherit src;
  inherit (flags) vars;
  buildInputs = with pkgs; [which];

  phases = ["unpackPhase" "buildPhase" "installPhase"];

  
  buildPhase = ''
    source $stdenv/setup

    ${flags.vars}

    cd miniupnpc

    ${if osId=="Windows" then
		"make -f Makefile.mingw CC=\"$CC\" CFLAGS=\"${flags.compiler}\" libminiupnpc.a"
    else
	  "make CC=\"$CC\" CFLAGS=\"${flags.compiler}\" libminiupnpc.a"
    }
  '';

  installPhase = ''
    mkdir $out
    cp libminiupnpc.a $out
  '';
}

