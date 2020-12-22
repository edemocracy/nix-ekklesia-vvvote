{ sources ? null
  , customVarsPath ? ./custom_vars.nix
  , varsOverride ? {} }:

with builtins;

let
lib = pkgs.lib;
deps = import ./nix/deps.nix { inherit sources; };
inherit (deps) mylib php pkgs vvvote apacheHttpd;

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
backendHttpdConfig = pkgs.callPackage ./backend-httpd.conf.nix { inherit vars php lib vvvote apacheHttpd; };

backendConfigFile = pkgs.writeText "config.php" backendConfig;
webclientConfigFile = pkgs.writeText "config.js" webclientConfig;
backendHttpdConfigFile = pkgs.writeText "backend-httpd.conf" backendHttpdConfig;

privateKeydir =
  if (!(isString vars.privateKeydir) && vars.copyPrivateKeysToStore == false) then
    throw ''
      privateKeydir cannot be a path (without quotes) when copyPrivateKeysToStore is not enabled!
      Paths are copied to the Nix store which may be a security risk!

      Use a string with double quotes as keydir and copyPrivateKeysToStore = false to link keys to the Nix store.
      This only works when Nix sandboxing is not enabled.

      If you really want to copy the keys to the Nix store, set copyPrivateKeysToStore = true.''
  else vars.privateKeydir;

publicKeydir = vars.publicKeydir;

permissionPublicKeyFiles = if (vars.publicKeydir == null) then [] else
  map (i: "${publicKeydir}/PermissionServer${toString i}.publickey.pem") (lib.range 1 (length vars.backendUrls));

tallyPublicKeyFiles = if (vars.publicKeydir == null) then [] else
  map (i: "${publicKeydir}/TallyServer${toString i}.publickey.pem") vars.tallyServerNumbers;

publicKeyFiles = permissionPublicKeyFiles ++ tallyPublicKeyFiles;

backendConfigDir = pkgs.runCommand "vvvote-backend-config" {} (''
  mkdir $out
  # linking doesn't work because PHP uses the location of the real file for __DIR__
  cp ${backendConfigFile} $out/config.php
''
+ lib.optionalString (vars.publicKeydir != null) ''
  key_dir=$out/voting-keys
  mkdir $key_dir
  # copy public server keys (optional: pass them as argument?)
  ${lib.concatMapStringsSep "\n" (k: "cp ${k} $key_dir") publicKeyFiles}
''
+ lib.optionalString (vars.privateKeydir != null) ''
  # link private keys
  ln -s ${privateKeydir}/PermissionServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
''
+ lib.optionalString (vars.privateKeydir != null && vars.isTallyServer) ''
  ln -s ${privateKeydir}/TallyServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
'');

varsForDebugOutput = removeAttrs vars ["__unfix__"];

in pkgs.stdenv.mkDerivation {
  buildInputs = [ vvvote php ];
  name = "nix-ekklesia-vvvote";
  # only run needed phases because unpack fails when src isn't given
  phases = [ "installPhase" "fixupPhase" ];
  installPhase = ''
    mkdir $out
    cp -r ${vvvote}/{backend,public} $out
    mkdir -p $out/bin

    cat << EOF > $out/bin/vvvote-backend.sh
    #!${pkgs.runtimeShell}
    export VVVOTE_CONFIG_DIR=${backendConfigDir}
    export PHPRC=${php.phpIni}

    ${apacheHttpd}/bin/httpd \
      -f ${backendHttpdConfigFile} \
      -D FOREGROUND \
      -C "ServerRoot $out" \
      -C "PidFile /dev/shm/vvvote_${toString vars.serverNumber}.pid" \
      "\$@"
    EOF
    chmod a+x $out/bin/vvvote-backend.sh

    chmod -R u+w $out/backend
    cp ${webclientConfigFile} $out/backend/webclient-sources/config/config.js

    # not needed in production, but helpful for debugging
    ln -s ${vvvote} $out/vvvote
    ln -s ${backendConfigDir} $out/config
    ln -s ${pkgs.writeText "vars.json" (builtins.toJSON varsForDebugOutput)} $out/vars.json
  ''
  # optimization: compile webclient
  # running the getclient.php script requires the private keys, so we can only do that when a private keydir is given
  + lib.optionalString (vars.compileWebclient && vars.privateKeydir != null) ''
    mkdir $out/webclient
    cd $out/backend
    export VVVOTE_CONFIG_DIR="${backendConfigDir}"
    php getclient.php > $out/webclient/index.html
  '';

  passthru = { inherit vars; };
}
