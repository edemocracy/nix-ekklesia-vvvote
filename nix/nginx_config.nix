{ lib }:
let
  allowedEndpoints = [
    "modules-auth/oauth2/callback"
    "newelection"
    "connectioncheck"
    "getelectionconfig"
    "getclient"
    "getpermission"
    "getresult"
    "getserverinfos"
    "storevote"
  ];
  allowedEndpointStr = lib.concatStringsSep "|" allowedEndpoints;

in {
  backendLocation = serveApp: prefix: {
    "~ ${prefix}/api/v1/(${allowedEndpointStr})$" = {
      proxyPass = "http://${serveApp.listen}";
      extraConfig = ''
        rewrite ${prefix}/api/v1/(.*) /$1.php break;
      '';
    };
  };

  # Works with or without precompiled webclient.
  webclientLocation = serveApp: prefix: {
    "@vvvote_webclient" = {
      proxyPass = "http://${serveApp.listen}/getclient.php$is_args$args";
    };

    "${prefix}/" = {
      tryFiles = "${serveApp}/webclient/ @vvvote_webclient";
    };
  };

}
