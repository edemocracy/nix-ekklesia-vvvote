{ sources ? null
  , vars
}:
with builtins;

let
  deps = import ./deps.nix { inherit sources; };
  inherit (deps) pkgs;
  inherit (pkgs) lib;

  backendConfig = scopedImport { inherit vars lib; } ./config.php.nix;
  backendConfigFile = pkgs.writeText "config.php" backendConfig;
  privacyStatementFile = pkgs.writeText "privacy_statement.txt" vars.dataProtectionPolicy.default;
  privacyStatementDeFile = pkgs.writeText "privacy_statement_de.txt" vars.dataProtectionPolicy.de;

  privateKeydir =
    if (isPath vars.privateKeydir && vars.copyPrivateKeysToStore == false) then
      throw ''
        privateKeydir cannot be a path (without quotes) when copyPrivateKeysToStore is not enabled!
        Paths are copied to the Nix store which may be a security risk!

        Use a string with double quotes as keydir and copyPrivateKeysToStore = false to link keys to the Nix store.
        This only works when Nix sandboxing is not enabled.

        If you really want to copy the keys to the Nix store, set copyPrivateKeysToStore = true.''
    else vars.privateKeydir;

  inherit (vars) publicKeydir;

  permissionPublicKeyFiles = if (publicKeydir == null) then [] else
    map (i: "${publicKeydir}/PermissionServer${toString i}.publickey.pem") (lib.range 1 (length vars.backendUrls));

  tallyPublicKeyFiles = if (publicKeydir == null) then [] else
    map (i: "${publicKeydir}/TallyServer${toString i}.publickey.pem") vars.tallyServerNumbers;

  publicKeyFiles = permissionPublicKeyFiles ++ tallyPublicKeyFiles;

  varsForDebugOutput = removeAttrs vars ["__unfix__"];

in pkgs.runCommand "vvvote-backend-config" {} (''
  mkdir $out
  # linking doesn't work for the config file because PHP uses the location of
  # the real file for __DIR__.
  cp ${backendConfigFile} $out/config.php
  ln -s ${privacyStatementFile} $out/privacy_statement.txt
  ln -s ${privacyStatementDeFile} $out/privacy_statement_de.txt
  # not needed in production, but helpful for debugging
  ln -s ${pkgs.writeText "vars.json" (builtins.toJSON varsForDebugOutput)} $out/vars.json
''
+ lib.optionalString (publicKeydir != null) ''
  key_dir=$out/voting-keys
  mkdir $key_dir
  # copy public server keys (optional: pass them as argument?)
  ${lib.concatMapStringsSep "\n" (k: "ln -s ${k} $key_dir") publicKeyFiles}
''
+ lib.optionalString (privateKeydir != null) ''
  # link private keys
  ln -s ${privateKeydir}/PermissionServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
''
+ lib.optionalString (privateKeydir != null && vars.isTallyServer) ''
  ln -s ${privateKeydir}/TallyServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
'')
