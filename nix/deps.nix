{ sources ? null }:
with builtins;

let
  sources_ = if (sources == null) then import ./sources.nix else sources;
  pkgs = import sources_.nixpkgs { };
  niv = (import sources_.niv { }).niv;
  mylib = pkgs.callPackage ./mylib.nix {};
  php = uwsgi.php;
  uwsgi = pkgs.callPackage ./uwsgi.nix {};

in rec {
  inherit pkgs php mylib uwsgi;
  inherit (pkgs) lib glibcLocales;

  shellTools = [
    niv
    php
    pkgs.entr
    uwsgi
  ];

  shellInputs = shellTools;
  shellPath = lib.makeBinPath shellInputs;
}
