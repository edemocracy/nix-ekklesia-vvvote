let
server1Conf = import ./custom_vars_local_server_1.nix;
dockerOverride = self: super: default: {
  backend = {
    httpAddress = "0.0.0.0";
  };
  db = {
    host = "172.17.0.1";
  };
};
in composeConfig server1Conf dockerOverride

