# example for reusing custom settings from server 1. Only the differences are specified here.
let
server1Conf = import ./vars_local_server_1.nix;
# `super` accesses settings from server 1 here
server2Override = self: super: default: {
  server_number = 2;
  db.name = "vvvote2";
  backend = {
    httpPort = 10002;
  };
};
# merge overrides for server 2 into the server 1 config
in composeConfig server1Conf server2Override

