{ pkgs, lib, vars, php }:

let 
thisConfig = scopedImport { inherit vars lib; } ./conf-thisserver.php.nix;
allConfig = scopedImport { inherit vars lib; } ./conf-allservers.php.nix;
webclientConfig = scopedImport { inherit vars lib; } ./config.js.nix;

thisConfigFile = pkgs.writeText "conf-thisserver.php" thisConfig;
allConfigFile = pkgs.writeText "conf-allservers.php" allConfig;
webclientConfigFile = pkgs.writeText "config.js" webclientConfig;
keydir = if (!(builtins.isString vars.keydir) && vars.copy_keys_to_store == false) then
  throw ''keydir cannot be a path (without quotes) when copy_keys_to_store is not enabled! Paths are copied to the Nix store which may be a security risk! Use a string with double quotes as keydir and copy_keys_to_store = false to link keys to the Nix store. This only works when Nix sandboxing is not enabled. If you want to copy the keys to the Nix store, set copy_keys_to_store = true.'' else vars.keydir;


publicKeyFiles = if (vars.keydir == null) then [] else
  map (i: "${keydir}/PermissionServer${toString i}.publickey") (lib.range 1 (builtins.length vars.backend_urls));

in 
pkgs.stdenv.mkDerivation {
  name = "vvvote";
  src = scopedImport { inherit pkgs; } ./src.nix;

  patches = [ ./0001-always-use-internal-ssl.patch ];

  buildInputs = [ php ];

  postPatch = ''
    substituteInPlace webclient/index.html --replace ../backend/ ${builtins.head vars.backend_urls}
  '';

  dontBuild = true; # nothing to build for this PHP / JS app ;)
  installPhase = ''
    # backend
    backend_config_dir=$out/backend/config
    cp -r . $out
    chmod u+w -R $out
    # linking doesn't work because PHP uses the location of the real file for __DIR__
    cp ${thisConfigFile} $backend_config_dir/conf-thisserver.php
    cp ${allConfigFile} $backend_config_dir/conf-allservers.php
    rm -f $backend_config_dir/conf*example*.php
    
    # webclient
    webclient_config_dir=$out/webclient/config
    cp ${webclientConfigFile} $webclient_config_dir/config.js
    rm -f $webclient_config_dir/config-example.js
  '' 
  + lib.optionalString (vars.keydir != null) ''
    # link public permission server keys (optional: pass them as argument?)
    ${lib.concatMapStringsSep "\n" (k: "ln -s ${k} $backend_config_dir") publicKeyFiles}
    # link private keys
    ln -s ${keydir}/PermissionServer${toString vars.server_number}.privatekey.pem.php $backend_config_dir
    ln -s ${keydir}/TallyServer${toString vars.tally_server_number}.publickey $backend_config_dir
  '' 
  + lib.optionalString (vars.keydir != null && vars.is_tally_server) ''
    ln -s ${keydir}/TallyServer${toString vars.server_number}.privatekey.pem.php $backend_config_dir
  ''
  # optimization: compile webclient
  # running the getclient.php script requires the keys, so we can only do that when a keydir is given
  # maybe that could be fixed in vvvote?
  + lib.optionalString (vars.keydir != null) ''
    build_dir=$PWD
    cd $out/backend
    php getclient.php > $build_dir/index.html
    cd $build_dir
    mv index.html $out/webclient
  '';
}
