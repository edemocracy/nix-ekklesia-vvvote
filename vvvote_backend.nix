{ pkgs, lib, vars, vvvoteFrontend }:

let 
common = pkgs.callPackage ./common.nix { inherit pkgs; };
thisConfig = scopedImport { inherit vars lib; } ./conf-thisserver.php.nix;
allConfig = scopedImport { inherit vars lib; } ./conf-allservers.php.nix;

thisConfigFile = pkgs.writeText "conf-thisserver.php" thisConfig;
allConfigFile = pkgs.writeText "conf-allservers.php" allConfig;
keydir = toString vars.keydir;

publicKeyFiles = if (vars.keydir == null) then [] else
  map (i: "${keydir}/PermissionServer${toString i}.publickey") (lib.range 1 (builtins.length vars.backend_urls));

in 
pkgs.stdenv.mkDerivation {
  name = "vvvote";
  inherit (common) src;

  patches = [ ./0001-always-use-internal-ssl.patch ];

  postPatch = ''
    substituteInPlace backend/getclient.php --replace ../webclient ${vvvoteFrontend}
  '';

  dontBuild = true; # nothing to build for this PHP app ;)
  installPhase = ''
    config_dir=$out/config
    cp -r backend $out
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
    ln -s ${keydir}/TallyServer${toString vars.tally_server_number}.publickey $config_dir
  '' 
  + lib.optionalString (vars.keydir != null && vars.is_tally_server) ''
    ln -s ${keydir}/TallyServer${toString vars.server_number}.privatekey.pem.php $config_dir
  '';
}
