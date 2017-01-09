{ pkgs ? import (builtins.fetchTarball "https://d3g5gsiof5omrk.cloudfront.net/nixos/16.09/nixos-16.09.1445.e9a8853/nixexprs.tar.xz") {}, 
  customVarsPath ? ./custom_vars.nix }:

let
uwsgi = pkgs.callPackage ./uwsgi.nix {};
in uwsgi

