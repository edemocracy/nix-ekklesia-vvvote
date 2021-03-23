{ config, lib, pkgs, ... }:

with builtins;

let
  cfg = config.services.ekklesia.vvvote;

  varsInsecure =
    lib.recursiveUpdate
      (lib.fix (import ../default_vars.nix))
      cfg.settings;

  # Override secrets with placeholders. Will be replaced on startup.
  vars =
    lib.recursiveUpdate
      varsInsecure {
        oauth.clientSecret = "@oauthClientSecret@";
        oauth.notifyClientSecret = "@notifyClientSecret@";
      };

  serveApp = pkgs.callPackage ../nix/serve_app.nix {
    listen = "${cfg.address}:${toString cfg.port}";
    logToJournald = true;
    backendConfigDir = pkgs.callPackage ../nix/config_dir.nix {
      inherit vars;
    };
    inherit (cfg) compileWebclient;
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
        default = "localhost";
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

      createDatabaseLocally = mkOption {
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

      notifyClientSecretFile = mkOption {
        type = types.str;
        description = "Path to file containing the secret for ekklesia-notify";
        default = "/var/lib/vvvote/notifyClientSecret";
      };

      oauthClientSecretFile = mkOption {
        type = types.str;
        description = "Path to file containing the client secret for OAuth 2/OpenID Connect";
        default = "/var/lib/vvvote/oauthClientSecret";
      };

      permissionPrivateKeyFile = mkOption {
        type = with types; nullOr str;
        description = "File name containing the private key relative to privateKeydir (if server acts as permission server)";
        example = "PermissionServer1.privatekey.pem.php";
      };

      privateKeydir = mkOption {
        type = with types; nullOr str;
        description = "Path to directory containing the private keys.";
        example = "/var/lib/vvvote/private-keys";
      };

      tallyPrivateKeyFile = mkOption {
        type = with types; nullOr str;
        description = "File name containing the private key relative to privateKeydir (if server acts as tally server)";
        example = "PermissionServer1.privatekey.pem.php";
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = types.attrs;
          options = {

            db = mkOption {
              default = {};
              type = types.submodule {
                options = {

                  name = mkOption {
                    type = types.str;
                    default = "vvvote";
                  };

                  host = mkOption {
                    type = types.str;
                    default = "localhost";
                  };

                  user = mkOption {
                    type = types.str;
                    default = "vvvote";
                  };

                  prefix = mkOption {
                    type = types.str;
                    default = "";
                  };

                };
              };
            };

            debug = mkOption {
              type = types.bool;
              default = false;
            };

            serverNumber = mkOption {
              type = types.ints.positive;
              default = 1;
            };

            publicKeydir = mkOption {
              type = types.path;
            };

            isTallyServer = mkOption {
              type = types.bool;
              default = true;
            };

            isPermissionServer = mkOption {
              type = types.bool;
              default = true;
            };

          };
        };
        default = {};
        description = "Additional config options given as attribute set.";
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(cfg.createDatabaseLocally && (cfg.settings.db.host != "localhost"));
          message = "Database can only be created on localhost, but host is set to ${cfg.settings.db.host}";
        }
      ];
    }

    (lib.mkIf cfg.createDatabaseLocally {
      services.mysql.ensureDatabases = [ cfg.settings.db.name ];
      services.mysql.ensureUsers = [
        {
          name = cfg.settings.db.user;
          ensurePermissions = {
            "${cfg.settings.db.name}.*" = "ALL PRIVILEGES";
          };
        }
      ];

    })

    (lib.mkIf cfg.enableBackend {

      environment.systemPackages = [
        serveApp.adminscript
      ];

      services.nginx.virtualHosts."${cfg.backendHostname}".locations =
        nginxConfig.backendLocation serveApp cfg.backendPrefix;

      systemd.services.ekklesia-vvvote = {

        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        preStart = let
         replaceDebug = lib.optionalString cfg.settings.debug "-vv";
         replaceSecret = file: var: secretFile:
          "${pkgs.replace}/bin/replace-literal -m 1 ${replaceDebug} -f -e @${var}@ $(< ${secretFile}) ${file}";
          serverNumber = cfg.settings.serverNumber;
        in ''
          cfgdir=$RUNTIME_DIRECTORY
          keydir=$cfgdir/voting-keys
          cp -Lr ${serveApp}/config/* $cfgdir
          chmod u+w -R $cfgdir
          ${replaceSecret "$cfgdir/config.php" "oauthClientSecret" cfg.oauthClientSecretFile}
          ${replaceSecret "$cfgdir/config.php" "notifyClientSecret" cfg.notifyClientSecretFile}
        ''
        + lib.optionalString cfg.settings.isTallyServer ''
          cp ${cfg.privateKeydir}/${cfg.tallyPrivateKeyFile} \
            $keydir/TallyServer${toString serverNumber}.privatekey.pem.php
        ''
        + lib.optionalString cfg.settings.isPermissionServer ''
          cp ${cfg.privateKeydir}/${cfg.permissionPrivateKeyFile} \
            $keydir/PermissionServer${toString serverNumber}.privatekey.pem.php
        '';

        script = ''
          VVVOTE_CONFIG_DIR=$RUNTIME_DIRECTORY ${serveApp}/bin/vvvote-backend.sh
         '';

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          DeviceAllow = [
            "/dev/stderr"
            "/dev/stdout"
          ];
          RuntimeDirectory = "vvvote";
          StateDirectory = "vvvote";
          RestartSec = "5s";
          Restart = "always";
          X-ServeApp = serveApp;

          # Some security hardening.
          # Gets a 1.4 OK score from systemd-analyze security on NixOS 20.09.
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          DevicePolicy = "strict";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          PrivateUsers = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RemoveIPC = true;
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            # deny the following syscall groups
            "~@clock"
            "~@debug"
            "~@module"
            "~@mount"
            "~@reboot"
            "~@cpu-emulation"
            "~@swap"
            "~@obsolete"
            "~@privileged"
            "~@resources"
            "~@raw-io"
            # explicitly allow the following syscall groups
            "@chown"
          ];
          UMask = "077";

        };
        unitConfig = {
          Documentation = [
            "https://github.com/edemocracy/nix-ekklesia-vvvote"
            "https://github.com/vvvote/vvvote"
            "https://www.vvvote.de"
            "https://ekklesiademocracy.org"
          ];
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
