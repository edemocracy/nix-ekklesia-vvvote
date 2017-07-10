{ pkgs ? import ./nixpkgs.nix,
  customVarsPath ? ./custom_vars.nix, varsOverride ? {}, imageName ? "nix-ekklesia-vvvote" }:

let 
  vvvote = pkgs.callPackage ./. { inherit pkgs customVarsPath varsOverride; };

in pkgs.dockerTools.buildImage {
  name = imageName;
  contents = [ vvvote ];

  config = {
    Cmd = [ "bin/vvvote_backend-uwsgi.sh" ];
    ExposedPorts = { 
      "${builtins.toString vvvote.vars.uwsgi.http_port}/tcp" = {}; 
    };
    Entrypoint = pkgs.writeScript "entrypoint.sh" ''
      #!${pkgs.stdenv.shell}
      exec "$@"
    '';
  };
}
