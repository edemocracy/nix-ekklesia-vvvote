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

  vvvote = pkgs.callPackage ./vvvote.nix {
    inherit php;
    vvvoteSrc = sources_.vvvote;
  };

  adminscript = pkgs.writeScriptBin "vvvote-admin.sh" ''
    cd ${vvvote}/backend
    ${php}/bin/php -f admin/admin.php "$@"
  '';


in rec {
  inherit pkgs php mylib vvvote;
  inherit (pkgs) lib glibcLocales;

  shellTools = [
    niv
    php
    pkgs.entr
    adminscript
  ];

  shellInputs = shellTools;
  shellPath = lib.makeBinPath shellInputs;
}
