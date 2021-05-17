{ sources ? null }:
with builtins;

let
  sources_ = if (sources == null) then import ./sources.nix else sources;
  pkgs = import sources_.nixpkgs { };
  mylib = pkgs.callPackage ./mylib.nix {};
  apacheHttpd = pkgs.callPackage ./apache.nix {};
  php = (pkgs.php74.override { inherit apacheHttpd; }).withExtensions ({ enabled, all }:
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
  inherit apacheHttpd pkgs php mylib vvvote adminscript;
  inherit (pkgs) lib glibcLocales;

  shellTools = [
    pkgs.niv
    php
    pkgs.entr
    adminscript
  ];

  shellInputs = shellTools;
  shellPath = lib.makeBinPath shellInputs;
}
