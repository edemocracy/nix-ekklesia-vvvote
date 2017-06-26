{ pkgs ? import ./nixpkgs.nix, 
  customVarsPath ? ./custom_vars.nix, vars_override ? null }:

let
uwsgi = pkgs.callPackage ./uwsgi.nix {};
php = uwsgi.php;
lib = pkgs.lib;
# variant of lib.extends which uses recursive set merging instead of //
extendsRec = f: rattrs: self: let super = rattrs self; in lib.recursiveUpdate super (f self super);

# Can be used to extend a custom configuration. 
# The extension `g` can access settings from the customized configuration with `super` and default values with `default`.
# Based on lib.composeExtensions using recursive set merging instead of //.
composeConfig =
  f: g: self: default:
    let fApplied = f self default;
        super = lib.recursiveUpdate default fApplied;
    in lib.recursiveUpdate fApplied (g self super default);

# Recursively merge custom settings from customVarsPath into the default config.
# Vars from the default config can be accessed with `super`.
# Config settings can refer to other settings using `self`.
# See `extends` in `nixpkgs/lib/trivial.nix` for details.
vars = if vars_override != null then vars_override
  else lib.fix' (extendsRec (scopedImport { inherit pkgs lib composeConfig; } customVarsPath) (import ./default_vars.nix) );

vvvoteFrontend = pkgs.callPackage ./vvvote_frontend.nix { inherit vars; };
vvvoteBackend = pkgs.callPackage ./vvvote_backend.nix { inherit vars vvvoteFrontend; };

uwsgiConfig = pkgs.writeText "vvvote_backend-uwsgi.ini" ''
  [uwsgi]
  plugins = 0:php
  socket = ${vars.uwsgi.socket}
  http = ${vars.uwsgi.http}
  project_dir = ${vvvoteBackend}
  php-docroot = %(project_dir)
  php-allowed-ext = .php
  php-allowed-ext = .inc
'';

startscript = pkgs.writeScriptBin "vvvote_backend-uwsgi.sh" ''
  ${uwsgi}/bin/uwsgi ${uwsgiConfig} "$@"
'';


adminscript = pkgs.writeScriptBin "vvvote-admin.sh" ''
  cd ${vvvoteBackend}
  ${php}/bin/php -f admin.php "$@"
'';

keyscript = pkgs.writeScriptBin "vvvote-create-keypair.sh" (scopedImport { inherit vvvoteBackend; } ./create_keypair.php.nix);

frontendScript = pkgs.writeScriptBin "vvvote_frontend-server.py" ''
  #!/usr/bin/env python3
  import http.server
  import socketserver
  import os

  PORT = ${toString vars.webclient_port}
  os.chdir("${vvvoteFrontend}")

  class Handler(http.server.SimpleHTTPRequestHandler):
      def end_headers(self):
          self.send_custom_headers()
          super().end_headers()

      def send_custom_headers(self):
          self.send_header("Access-Control-Allow-Origin", "*")


  with socketserver.TCPServer(("", PORT), Handler) as httpd:
      print("serving at port", PORT)
      httpd.serve_forever()
'';


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
    ln -s ${frontendScript}/bin/vvvote_frontend-server.py $out/bin/

    # not needed in production, but helpful for debugging
    ln -s ${uwsgiConfig} $out/vvvote_backend-uwsgi.ini
    ln -s ${vvvoteBackend} $out/vvvote_backend
    ln -s ${vvvoteFrontend} $out/vvvote_frontend
    ln -s ${pkgs.writeText "config.json" (builtins.toJSON varsForDebugOutput)} $out/config.json
  '';

  shellHook = ''
    export PATH=$PATH:${php}/bin:${adminscript}/bin:${keyscript}/bin
  '';
}
