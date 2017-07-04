{ pkgs, lib, vars }:

let 
common = pkgs.callPackage ./common.nix { inherit pkgs; };
thisConfig = scopedImport { inherit vars lib; } ./conf-thisserver.php.nix;
allConfig = scopedImport { inherit vars lib; } ./conf-allservers.php.nix;
webclientConfig = scopedImport { inherit vars lib; } ./config.js.nix;

thisConfigFile = pkgs.writeText "conf-thisserver.php" thisConfig;
allConfigFile = pkgs.writeText "conf-allservers.php" allConfig;
webclientConfigFile = pkgs.writeText "config.js" webclientConfig;
keydir = toString vars.keydir;

publicKeyFiles = if (vars.keydir == null) then [] else
  map (i: "${keydir}/PermissionServer${toString i}.publickey") (lib.range 1 (builtins.length vars.backend_urls));

in 
pkgs.stdenv.mkDerivation {
  name = "vvvote";
  inherit (common) src;

  patches = [ ./0001-always-use-internal-ssl.patch ];

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
    ln -s ${webclientConfigFile} $webclient_config_dir/config.js
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
  '';
}
