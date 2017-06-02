{ pkgs, lib, vars }:

let 
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
  src = pkgs.fetchFromGitHub {
    owner = "pfefffer";
    repo = "vvvote";
    rev = "e63ab761eb738455216cfe3d386eaa75504e1e3b";
    sha256 = "0la05r2lkgs9dips2c3fj6wdlqphjjnvj9f5ld22lhgcji7kvf1p";
  };

  dontBuild = true; # nothing to build for this PHP app ;)
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
}
