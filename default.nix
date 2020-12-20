{ sources ? null
  , customVarsPath ? ./custom_vars.nix
  , varsOverride ? {} }:

with builtins;

let
lib = pkgs.lib;
deps = import ./nix/deps.nix { inherit sources; };
inherit (deps) mylib php pkgs vvvote;

# Recursively merge custom settings from customVarsPath into the default config.
# Vars from the default config can be accessed with `super`.
# Config settings can refer to other settings using `self`.
# See `extends` in `nixpkgs/lib/trivial.nix` for details.
vars =
  lib.recursiveUpdate
    (lib.fix'
      (mylib.extendsRec
        (scopedImport { inherit pkgs lib; inherit (mylib) composeConfig; } customVarsPath)
        (import ./default_vars.nix)))
    varsOverride;

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


backendConfigDir = pkgs.runCommand "vvvote-backend-config" {} (''
  mkdir $out
  # linking doesn't work because PHP uses the location of the real file for __DIR__
  cp ${backendConfigFile} $out/config.php
''
+ lib.optionalString (vars.keydir != null) ''
  key_dir=$out/voting-keys
  mkdir $key_dir
  # link public server keys (optional: pass them as argument?)
  ${lib.concatMapStringsSep "\n" (k: "ln -s ${k} $key_dir") publicKeyFiles}

  # link private keys
  ln -s ${keydir}/PermissionServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
''
+ lib.optionalString (vars.keydir != null && vars.isTallyServer) ''
  ln -s ${keydir}/TallyServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
'');

varsForDebugOutput = removeAttrs vars ["__unfix__"];

in pkgs.stdenv.mkDerivation {
  buildInputs = [ vvvote php ];
  name = "nix-ekklesia-vvvote";
  # only run needed phases because unpack fails when src isn't given
  phases = [ "installPhase" "fixupPhase" ];
  installPhase = ''
    mkdir $out
    cp -r ${vvvote}/backend $out
    chmod -R u+w $out

    mkdir -p $out/bin

    cat << EOF > $out/bin/vvvote-backend.sh
    #!${pkgs.runtimeShell}
    cd $out/backend
    export VVVOTE_CONFIG_DIR=${backendConfigDir}
    ${php}/bin/php -S ${vars.backend.httpAddress}:${toString vars.backend.httpPort}
    EOF
    chmod a+x $out/bin/vvvote-backend.sh

    cp ${webclientConfigFile} $out/backend/webclient-sources/config/config.js

    # not needed in production, but helpful for debugging
    ln -s ${vvvote} $out/vvvote
    ln -s ${pkgs.writeText "config.json" (builtins.toJSON varsForDebugOutput)} $out/config.json
  ''
  # optimization: compile webclient
  # running the getclient.php script requires the keys, so we can only do that when a keydir is given
  + lib.optionalString (vars.keydir != null) ''
    mkdir $out/webclient
    cd $out/backend
    export VVVOTE_CONFIG_DIR="${backendConfigDir}"
    php getclient.php > $out/webclient/index.html
  '';

  passthru = { inherit vars; };
}
