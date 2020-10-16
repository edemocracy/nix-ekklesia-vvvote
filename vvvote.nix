with builtins;

{ pkgs, lib, vars, php }:

let
backendConfig = scopedImport { inherit vars lib; } ./config.php.nix;
webclientConfig = scopedImport { inherit vars lib; } ./config.js.nix;

backendConfigFile = pkgs.writeText "config.php" backendConfig;
webclientConfigFile = pkgs.writeText "config.js" webclientConfig;
keydir = if (!(isString vars.keydir) && vars.copyKeysToStore == false) then
  throw ''keydir cannot be a path (without quotes) when copy_keys_to_store is not enabled! Paths are copied to the Nix store which may be a security risk! Use a string with double quotes as keydir and copy_keys_to_store = false to link keys to the Nix store. This only works when Nix sandboxing is not enabled. If you want to copy the keys to the Nix store, set copy_keys_to_store = true.'' else vars.keydir;

permissionPublicKeyFiles = if (vars.keydir == null) then [] else
  map (i: "${keydir}/PermissionServer${toString i}.publickey.pem") (lib.range 1 (length vars.backendUrls));

tallyPublicKeyFiles = if (vars.keydir == null) then [] else
  map (i: "${keydir}/TallyServer${toString i}.publickey.pem") vars.tallyServerNumbers;

publicKeyFiles = permissionPublicKeyFiles ++ tallyPublicKeyFiles;

in
pkgs.stdenv.mkDerivation {
  name = "vvvote";
  #src = scopedImport { inherit pkgs; } ./nix/src.nix;
  src = ../vvvote;

  patches = [ ./0001-always-use-internal-ssl.patch ];

  buildInputs = [ php ];

  dontBuild = true; # nothing to build for this PHP / JS app ;)
  installPhase = ''
    # backend
    backend_config_dir=$out/backend/config
    key_dir=$out/backend/config/voting-keys
    cp -r . $out
    chmod u+w -R $out
    # linking doesn't work because PHP uses the location of the real file for __DIR__
    cp ${backendConfigFile} $backend_config_dir/config.php
    rm -f $backend_config_dir/conf*example*.php

    cp -r $out/backend/modules-auth/oauth $out/backend/modules-auth/oauth2

    # webclient
    webclient_config_dir=$out/webclient/config
    mkdir -p $webclient_config_dir
    cp ${webclientConfigFile} $webclient_config_dir/config.js
    cp ${webclientConfigFile} $out/backend/webclient-sources/config/config.js
    rm -f $webclient_config_dir/config-example.js
  ''
  + lib.optionalString (vars.keydir != null) ''
    # link public server keys (optional: pass them as argument?)
    ${lib.concatMapStringsSep "\n" (k: "ln -s ${k} $key_dir") publicKeyFiles}

    # link private keys
    ln -s ${keydir}/PermissionServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
  ''
  + lib.optionalString (vars.keydir != null && vars.isTallyServer) ''
    ln -s ${keydir}/TallyServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
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
