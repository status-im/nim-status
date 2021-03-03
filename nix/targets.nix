{
  config ? {},
  pkgs ? import ./pkgs.nix { inherit config; }
}:

let
  inherit (pkgs) stdenv callPackage;

  main = callPackage ./nim-status {};
in {
  inherit main;
}
