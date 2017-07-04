{ pkgs ? import ./nixpkgs.nix, 
  customVarsPath ? ./custom_vars.nix, vars_override ? null }:

let
lib = pkgs.lib;
mylib = pkgs.callPackage ./mylib.nix {};
php = uwsgi.php;
uwsgi = pkgs.callPackage ./uwsgi.nix {};

# Recursively merge custom settings from customVarsPath into the default config.
# Vars from the default config can be accessed with `super`.
# Config settings can refer to other settings using `self`.
# See `extends` in `nixpkgs/lib/trivial.nix` for details.
vars = if vars_override != null then vars_override
  else lib.fix' 
    (mylib.extendsRec 
      (scopedImport { inherit pkgs lib; inherit (mylib) composeConfig; } customVarsPath) 
      (import ./default_vars.nix));

vvvote = pkgs.callPackage ./vvvote.nix { inherit vars php; };

uwsgiConfig = pkgs.writeText "vvvote_backend-uwsgi.ini" (scopedImport { inherit vars vvvote; } ./backend-uwsgi.ini.nix);

startscript = pkgs.writeScriptBin "vvvote_backend-uwsgi.sh" ''
  ${uwsgi}/bin/uwsgi ${uwsgiConfig} "$@"
'';

adminscript = pkgs.writeScriptBin "vvvote-admin.sh" ''
  cd ${vvvote}/backend
  ${php}/bin/php -f admin.php "$@"
'';

keyscript = pkgs.writeScriptBin "vvvote-create-keypair.sh" (scopedImport { inherit vvvote; } ./create_keypair.php.nix);
webclientScript = pkgs.writeScriptBin "serve-webclient.py" (scopedImport { inherit vars vvvote; } ./serve-webclient.py.nix);

varsForDebugOutput = removeAttrs vars ["__unfix__"];

in pkgs.stdenv.mkDerivation {
  name = "nix-ekklesia-vvvote";
  # only run needed phases because unpack fails when src isn't given
  phases = [ "installPhase" "fixupPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${startscript}/bin/vvvote_backend-uwsgi.sh $out/bin/
    ln -s ${adminscript}/bin/vvvote-admin.sh $out/bin/
    ln -s ${keyscript}/bin/vvvote-create-keypair.sh $out/bin/
    ln -s ${webclientScript}/bin/serve-webclient.py $out/bin/

    # not needed in production, but helpful for debugging
    ln -s ${uwsgiConfig} $out/vvvote_backend-uwsgi.ini
    ln -s ${vvvote} $out/vvvote
    ln -s ${pkgs.writeText "config.json" (builtins.toJSON varsForDebugOutput)} $out/config.json
  '';

  shellHook = ''
    export PATH=$PATH:${php}/bin:${adminscript}/bin:${keyscript}/bin
  '';
}
