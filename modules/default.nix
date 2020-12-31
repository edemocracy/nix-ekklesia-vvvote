{ config, lib, pkgs, ... }:

with builtins;

let
  cfg = config.services.ekklesia.vvvote;

  vars =
    lib.recursiveUpdate
      (lib.fix (import ../default_vars.nix))
      cfg.settings;

  serveApp = pkgs.callPackage ../nix/serve_app.nix {
    listen = "${cfg.address}:${toString cfg.port}";
    logToJournald = true;
    backendConfigDir = pkgs.callPackage ../nix/config_dir.nix {
      inherit vars;
    };
    compileWebclient = cfg.compileWebclient && cfg.settings.privateKeydir != null;
    pidfile = "/run/vvvote/vvvote_backend.pid";
  };

  nginxConfig = pkgs.callPackage ../nix/nginx_config.nix { };

in {
  options = with lib; {
    services.ekklesia.vvvote = {
      enableBackend = mkEnableOption "vvvote backend";
      backendPrefix = mkOption {
        type = types.str;
        default = "/backend";
      };
      backendHostname = mkOption {
        type = types.str;
      };
      enableWebclient = mkEnableOption "vvvote webclient";
      webclientPrefix = mkOption {
        type = types.str;
        default = "";
      };
      webclientHostname = mkOption {
        type = types.str;
      };

      user = mkOption {
        type = types.str;
        default = "vvvote";
        description = "User to run VVVote backend";
      };

      compileWebclient = mkOption {
        type = types.bool;
        default = false;
      };

      group = mkOption {
        type = types.str;
        default = "vvvote";
        description = "Group to run VVVote backend";
      };

      port = mkOption {
        type = types.int;
        default = 10001;
        description = "Port for backend app server";
      };

      address = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address for backend app server";
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = types.attrs;
          options = {
            serverNumber = mkOption {
              type = types.ints.positive;
              default = 1;
            };
            privateKeydir = mkOption {
              type = with types; (either path str);
            };
            publicKeydir = mkOption {
              type = types.path;
            };
          };
        };
        default = {};
        description = "Additional config options given as attribute set.";
      };
    };
  };

  config = lib.mkMerge [

    (lib.mkIf cfg.enableBackend {
      services.nginx.virtualHosts."${cfg.backendHostname}".locations =
        nginxConfig.backendLocation serveApp cfg.backendPrefix;

      systemd.services.ekklesia-vvvote = {

        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${serveApp}/bin/vvvote-backend.sh";
          DeviceAllow = [
            "/dev/stderr"
            "/dev/stdout"
          ];
          DevicePolicy = "strict";
          RuntimeDirectory = "vvvote";
          X-ServeApp = serveApp;
        };
      };

      users.users.vvvote = {
        home = "/run/vvvote";
      };

      users.groups.vvvote = { };
    })

    (lib.mkIf cfg.enableWebclient {
      services.nginx.virtualHosts."${cfg.webclientHostname}".locations =
        nginxConfig.webclientLocation serveApp cfg.webclientPrefix;
    })

  ];
}
