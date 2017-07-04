{ pkgs, lib, vars }:

let 
common = pkgs.callPackage ./common.nix { inherit pkgs; };
config = scopedImport { inherit vars lib; } ./config.js.nix;

configFile = pkgs.writeText "config.js" config;

in 
pkgs.stdenv.mkDerivation {
  name = "vvvote_frontend";
  inherit (common) src;

  dontBuild = true; # nothing to build for this JS app ;)

  patchPhase = ''
    substituteInPlace webclient/index.html --replace ../backend/ ${builtins.head vars.backend_urls}
  '';

  installPhase = ''
    config_dir=$out/config
    cp -r webclient $out
    chmod u+w -R $out
    ln -s ${configFile} $config_dir/config.js
    rm -f $config_dir/config-example.js
  '';
}
