{ sources ? null
  , customVarsPath ? ./custom_vars.nix
  , varsOverride ? {} }:

with builtins;

let
  deps = import ./nix/deps.nix { inherit sources; };
  inherit (deps) mylib php pkgs vvvote apacheHttpd;
  lib = pkgs.lib;

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

  listen = with vars; "${backend.httpAddress}:${toString backend.httpPort}";
  pidfile = "/dev/shm/vvvote_${toString vars.serverNumber}.pid";
  compileWebclient = vars.compileWebclient && vars.privateKeydir != null;

  backendConfigDir = pkgs.callPackage ./nix/config_dir.nix { inherit sources vars; };
  serveApp = pkgs.callPackage ./nix/serve_app.nix { inherit sources backendConfigDir listen pidfile compileWebclient; };

in serveApp
