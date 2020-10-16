{ sources ? null,
  customVarsPath ? ./custom_vars.nix, varsOverride ? {} }:

let
lib = pkgs.lib;
deps = import ./nix/deps.nix { inherit sources; };
inherit (deps) mylib php uwsgi pkgs;

# Recursively merge custom settings from customVarsPath into the default config.
# Vars from the default config can be accessed with `super`.
# Config settings can refer to other settings using `self`.
# See `extends` in `nixpkgs/lib/trivial.nix` for details.
vars =
  (lib.fix'
    (mylib.extendsRec
      (scopedImport { inherit pkgs lib; inherit (mylib) composeConfig; } customVarsPath)
      (import ./default_vars.nix))) // varsOverride;

vvvote = pkgs.callPackage ./vvvote.nix { inherit vars php; };

startscript = pkgs.writeScriptBin "vvvote-backend.sh" (with vars.backend; ''
  cd ${vvvote}/backend
  ${php}/bin/php -S ${httpAddress}:${toString httpPort} "$@"
'');

adminscript = pkgs.writeScriptBin "vvvote-admin.sh" ''
  cd ${vvvote}/backend
  ${php}/bin/php -f admin/admin.php "$@"
'';

varsForDebugOutput = removeAttrs vars ["__unfix__"];

in pkgs.stdenv.mkDerivation {
  name = "nix-ekklesia-vvvote";
  # only run needed phases because unpack fails when src isn't given
  phases = [ "installPhase" "fixupPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${startscript}/bin/vvvote-backend.sh $out/bin/
    ln -s ${adminscript}/bin/vvvote-admin.sh $out/bin/

    # not needed in production, but helpful for debugging
    ln -s ${vvvote} $out/vvvote
    ln -s ${pkgs.writeText "config.json" (builtins.toJSON varsForDebugOutput)} $out/config.json
  '';

  shellHook = ''
    export PATH=$PATH:${php}/bin:${adminscript}/bin
  '';

  passthru = { inherit vars; };
}
