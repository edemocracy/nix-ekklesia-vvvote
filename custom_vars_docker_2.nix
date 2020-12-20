let
server2Conf = scopedImport { inherit composeConfig; } ./custom_vars_local_server_2.nix;
dockerOverride = self: super: default: {
  backend = {
    httpAddress = "0.0.0.0";
  };
  db = {
    host = "172.17.0.1";
  };
};
in composeConfig server2Conf dockerOverride

