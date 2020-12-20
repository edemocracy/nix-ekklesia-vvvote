{ sources ? null
  , tag ? "latest"
  , imageName ? "nix-ekklesia-vvvote"
  , customVarsPath ? ./custom_vars.nix
  , varsOverride ? { } }:
let
  deps = import ./nix/deps.nix { inherit sources; };
  inherit (deps) pkgs;
  inherit (pkgs) lib;
  vvvote = pkgs.callPackage ./. {
    inherit sources customVarsPath varsOverride;
  };

in pkgs.dockerTools.buildImage {
  name = imageName;
  inherit tag;
  contents = [ vvvote ];

  config = {
    Cmd = [ "bin/vvvote-backend.sh" ];
    ExposedPorts = {
      "${builtins.toString vvvote.vars.backend.httpPort}/tcp" = {};
    };
    Entrypoint = pkgs.writeScript "entrypoint.sh" ''
      #!${pkgs.stdenv.shell}
      exec "$@"
    '';
  };
}
