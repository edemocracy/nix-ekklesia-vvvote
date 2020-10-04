let
server1Conf = import ./custom_vars_local_server_1.nix;
server2Override = self: super: default: {
  serverNumber = 2;
  isTallyServer = false;
  db.name = "vvvote2";
  uwsgi = {
    socketPort = 20002;
    httpPort = 10002;
  };
};
in composeConfig server1Conf server2Override

