{ newScope
, callPackage
, mkShell
, writeScript
, writeText
, xcodeWrapper
, pkgs
, stdenv
, lib }:
let
  callPackage = newScope {};

  buildPackage = name: platform: arch: callPackage (./. + "/${name}.nix") {
    inherit platform arch;
  };

  buildArchTree = name: {
     android = {
      x86 = buildPackage name "android" "386";
      arm = buildPackage name "androideabi" "arm";
      arm64 = buildPackage name "android" "arm64";
    };
    ios = {
      x86 = buildPackage name "ios" "386";
      arm = buildPackage name "ios" "arm";
      arm64 = buildPackage name "ios" "arm64";
    };
  };

  buildNimStatus = platform: arch: callPackage ./nim-status.nix {
    inherit platform arch;
  };

  # Metadata common to all builds of status-go
  meta = {
    description = "The Status Go module that consumes go-ethereum.";
    license = lib.licenses.mpl20;
    platforms = with lib.platforms; linux ++ darwin;
  };

  # Source can be changed with a local override from config
  source = callPackage ./status-go-source.nix { };
  
  buildStatusGo = platform: arch: callPackage ./status-go.nix {
    inherit platform arch meta source;
  };

  buildAndroid = buildMap: name: stdenv.mkDerivation {
    name = "${name}-android-builder";
    buildInputs = [ pkgs.coreutils ];
    builder = writeScript "${name}-android-builder.sh"
    ''
      export PATH=${pkgs.coreutils}/bin:$PATH
      mkdir $out

      ln -s ${buildMap.x86} $out/x86
      ln -s ${buildMap.arm} $out/armeabi-v7a
      ln -s ${buildMap.arm64} $out/arm64-v8a
    '';
  };

  # Create a single multi-arch fat binary using lipo
  # Create a single header for multiple target archs
  # by utilizing C preprocessor conditionals
  buildIos = buildMap: name:
    let
      headerIos = writeText "${name}.h" ''
        #if TARGET_CPU_X86_64
        ${builtins.readFile "${buildMap.x86}/${name}.h"}
        #elif TARGET_CPU_ARM
        ${builtins.readFile "${buildMap.arm}/${name}.h"}
        #else
        ${builtins.readFile "${buildMap.arm64}/${name}.h"}
        #endif
      '';
    in stdenv.mkDerivation {
      inherit xcodeWrapper;
      buildInputs = [ pkgs.coreutils ];
      name = "${name}-ios-builder";
      builder = writeScript "${name}-ios-builder.sh"
      ''
        export PATH=${pkgs.coreutils}/bin:${xcodeWrapper}/bin:$PATH
        mkdir $out

        # lipo merges arch-specific binaries into one fat iOS binary
        lipo -create ${buildMap.x86}/lib${name}.a \
             ${buildMap.arm}/lib${name}.a \
             ${buildMap.arm64}/lib${name}.a \
             -output $out/lib${name}.a

        cp ${headerIos} $out/${name}.h
        ${if name=="nim_status" then "cp ${buildMap.arm64}/nimbase.h $out" else ""}
      '';
  };
in rec {
  nim-status = {
    android = {
      x86 = buildNimStatus "android" "386";
      arm = buildNimStatus "androideabi" "arm";
      arm64 = buildNimStatus "android" "arm64";
    };
    ios = {
      x86 = buildNimStatus "ios" "386";
      arm = buildNimStatus "ios" "arm";
      arm64 = buildNimStatus "ios" "arm64";
    };
  };

  status-go = {
    android = {
      x86 = buildStatusGo "android" "386";
      arm = buildStatusGo "androideabi" "arm";
      arm64 = buildStatusGo "android" "arm64";
    };
    ios = {
      x86 = buildStatusGo "ios" "386";
      arm = buildStatusGo "ios" "arm";
      arm64 = buildStatusGo "ios" "arm64";
    };
  };


  # deps

  #libnatpmp = callPackage ./deps/libnatpmp.nix {platform = "android"; arch="386";};
  libnatpmp = buildArchTree "deps/libnatpmp";
  libminiupnpc = buildArchTree "deps/libminiupnpc";
  
  nim-status-android = buildAndroid nim-status.android "nim_status";
  nim-status-ios = buildIos nim-status.ios "nim_status";

  status-go-android = buildAndroid status-go.android "status";
  status-go-ios = buildIos status-go.ios "status";

  android = stdenv.mkDerivation {
      buildInputs = [ pkgs.coreutils ];
      name = "nim-status-go-android-builder";
      builder = writeScript "nim-status-go-android-builder.sh"
      ''
        export PATH=${pkgs.coreutils}/bin:$PATH
        mkdir $out
        for arch in "x86" "armeabi-v7a" "arm64-v8a"; do
          mkdir $out/$arch

          for filename in ${nim-status-android}/$arch/*; do
            ln -sf "$filename" $out/$arch/$(basename $filename)
          done

          for filename in ${status-go-android}/$arch/*; do
            ln -sf "$filename" $out/$arch/$(basename $filename)
          done
        done
      '';
  };

  ios = stdenv.mkDerivation {
      buildInputs = [ pkgs.coreutils ];
      name = "nim-status-go-ios-builder";
      builder = writeScript "nim-status-go-ios-builder.sh"
      ''
        export PATH=${pkgs.coreutils}/bin:$PATH
        mkdir $out
        for filename in ${nim-status-ios}/*; do
          ln -sf "$filename" $out/$(basename $filename)
        done

        for filename in ${status-go-ios}/*; do
          ln -sf "$filename" $out/$(basename $filename)
        done
      '';
  };
  shell = mkShell {
    inputsFrom = [ status-go-android status-go-ios ];
  };
}
