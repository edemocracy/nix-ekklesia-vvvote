{ pkgs ? import ./nixpkgs.nix, 
  customVarsPath ? ./custom_vars.nix, vars_override ? null }:

let
uwsgi = pkgs.callPackage ./uwsgi.nix {};
php = uwsgi.php;
lib = pkgs.lib;

vars = if vars_override != null then vars_override
  else lib.recursiveUpdate (import ./default_vars.nix) (scopedImport { inherit pkgs lib; } customVarsPath);

thisConfig = scopedImport { inherit vars; } ./conf-thisserver_template.php.nix;
allConfig = scopedImport { inherit vars; } ./conf-allservers_template.php.nix;

thisConfigFile = pkgs.writeText "conf-thisserver.php" thisConfig;
allConfigFile = pkgs.writeText "conf-allservers.php" allConfig;
keydir = toString vars.keydir;

publicKeyFiles = if (vars.keydir == null) then [] else
  map (i: "${keydir}/PermissionServer${toString i}.publickey") (lib.range 1 vars.number_of_servers);


vvvoteBackend = pkgs.stdenv.mkDerivation {
  name = "vvvote";
  src = pkgs.fetchFromGitHub {
    owner = "pfefffer";
    repo = "vvvote";
    rev = "e63ab761eb738455216cfe3d386eaa75504e1e3b";
    sha256 = "0la05r2lkgs9dips2c3fj6wdlqphjjnvj9f5ld22lhgcji7kvf1p";
  };

  propagatedBuildInputs = [];

  dontBuild = true;
  installPhase = ''
    set -x
    config_dir=$out/config
    cp -r $src/backend $out
    chmod u+w -R $out
    # linking doesn't work because PHP uses the location of the real file for __DIR__
    cp ${thisConfigFile} $config_dir/conf-thisserver.php
    cp ${allConfigFile} $config_dir/conf-allservers.php
    rm -f $config_dir/conf*example*.php
  '' 
  + lib.optionalString (vars.keydir != null) ''
    # link public permission server keys (optional: pass them as argument?)
    ${lib.concatMapStringsSep "\n" (k: "ln -s ${k} $config_dir") publicKeyFiles}
    # link private keys
    ln -s ${keydir}/PermissionServer${toString vars.server_number}.privatekey.pem.php $config_dir
    set +x
  '' 
  + lib.optionalString (vars.keydir != null && vars.is_tally_server) ''
    ln -s ${keydir}/TallyServer${toString vars.server_number}.privatekey.pem.php $config_dir
    ln -s ${keydir}/TallyServer${toString vars.server_number}.publickey $config_dir
  '';
};

uwsgiConfig = pkgs.writeText "vvvote-uwsgi-config.ini" ''
  [uwsgi]
  plugins = 0:php
  socket = :8000
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
