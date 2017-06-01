{ pkgs ? import ./nixpkgs.nix, 
  customVarsPath ? ./custom_vars.nix, vars_override ? null }:

let
uwsgi = pkgs.callPackage ./uwsgi.nix {};
php = uwsgi.php;
lib = pkgs.lib;

vars = if vars_override != null then vars_override
  else lib.recursiveUpdate (import ./default_vars.nix) (scopedImport { inherit pkgs lib; } customVarsPath);

vvvoteBackend = pkgs.callPackage ./vvvote_backend.nix { inherit vars; };

uwsgiConfig = pkgs.writeText "vvvote-uwsgi-config.ini" ''
  [uwsgi]
  plugins = 0:php
  socket = ${vars.uwsgi.socket}
  http = ${vars.uwsgi.http}
  project_dir = ${vvvoteBackend}
  php-docroot = %(project_dir)
  php-allowed-ext = .php
  php-allowed-ext = .inc
'';

startscript = pkgs.writeScriptBin "vvvote-uwsgi.sh" ''
  ${uwsgi}/bin/uwsgi ${uwsgiConfig} "$@"
'';


adminscript = pkgs.writeScriptBin "vvvote-admin.sh" ''
  cd ${vvvoteBackend}
  ${php}/bin/php -f admin.php "$@"
'';


in pkgs.stdenv.mkDerivation {
  name = "nix-ekklesia-vvvote";
  # only run needed phases because unpack fails when src isn't given
  phases = [ "installPhase" "fixupPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${startscript}/bin/vvvote-uwsgi.sh $out/bin/
    ln -s ${adminscript}/bin/vvvote-admin.sh $out/bin/
    
    ln -s ${vvvoteBackend} $out/vvvote_backend
  '';

  shellHook = ''
    export PATH=$PATH:${php}/bin:${adminscript}/bin
  '';
}
