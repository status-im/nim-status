{ pkgs, callPackage, stdenv, lib 
# Dependencies
, platform ? "android"
, arch ? "386"
, api ? "23" } :
let
  src = pkgs.fetchgit {
    url = "https://github.com/status-im/nim-sqlcipher";
    rev = "99e9ed1734f39b3a79a435c091cc505b1d8c2d05";
    sha256 = "14d5mqsi60dgw7wb6ab8a7paw607axblfysf88vmj3qix5z571wg";
    fetchSubmodules = false;
  };

  flags = callPackage ../getFlags.nix {inherit platform arch;};
  openssl = callPackage ./openssl.nix {inherit platform arch;};

  cdefs = "-DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=3"; 
  cflags = "-I${openssl}/include -pthread";

  osId = builtins.elemAt (builtins.split "\-" stdenv.hostPlatform.system) 2;


  sslLdFlags = lib.concatStringsSep " " 
      (["-L${openssl}/lib" "${openssl}/lib/libcrypto.a"]
      ++ lib.optional (osId == "Windows") "-lws2_32");

    ldFlags = if flags.isIOS then "-lpthread" 
    else if osId == "Windows" then "-lwinpthread" 
    else "";
  sqlcipher = stdenv.mkDerivation rec {
    name = "sqlcipher_lib";

    src = pkgs.fetchgit {
      url = "https://github.com/sqlcipher/sqlcipher";
      rev = "50376d07a5919f1777ac983921facf0bf0fc1976";
      sha256 = "0zhww6fpnfflnzp6091npz38ab6cpq75v3ghqvcj5kqg09vqm5na";
      fetchSubmodules = false;
    };
    buildInputs = with pkgs; [ tcl ];

    phases = ["unpackPhase" "configurePhase" "buildPhase" "installPhase"];

    configurePhase = ''
      ${flags.vars}
      echo -e "SQLCipher's SQLite C amalgamation"
      ./configure --with-sysroot=${flags.isysroot} --host=${flags.host} \
          CFLAGS="${cdefs} ${cflags} ${flags.compiler}" \
          LDFLAGS="${ldFlags} ${sslLdFlags} ${flags.linker}"
    '';

    buildPhase = ''
      make sqlite3.c
    '';

    installPhase = ''
      mkdir $out
      cp sqlite3.h $out
      cp sqlite3.c $out
    '';
  };

in 
  stdenv.mkDerivation rec {
  name = "nim-sqlcipher_lib";
  inherit src sqlcipher;
  #buildInputs = with pkgs; [ perl ];

  phases = ["unpackPhase" "buildPhase" "installPhase"];

  buildPhase = ''
    ${flags.vars}
  	echo -e "SQLCipher static library"
    echo ${sqlcipher}
	  mkdir -p lib
    $CC \
      ${cdefs} \
      ${cflags} ${flags.compiler}	\
      ${sqlcipher}/sqlite3.c \
      -c \
      -o lib/sqlcipher.o
    $AR rcs lib/libsqlcipher.a lib/sqlcipher.o
  '';

  installPhase = ''
    mkdir $out
    cp lib/libsqlcipher.a $out
  '';
}
