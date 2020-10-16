{ sources ? null }:
with builtins;

let
  sources_ = if (sources == null) then import ./sources.nix else sources;
  pkgs = import sources_.nixpkgs { };
  niv = (import sources_.niv { }).niv;
  mylib = pkgs.callPackage ./mylib.nix {};
  php = pkgs.php74.withExtensions ({ enabled, all }:
    with all; [ session pdo_mysql gmp json curl ]
   );
  uwsgi = pkgs.uwsgi.override { plugins = [ "php" ]; inherit php; };

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
