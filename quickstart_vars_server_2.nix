let 
server1Conf = import ./quickstart_vars_server_1.nix;
server2Override = self: super: default: {
  server_number = 2;
  is_tally_server = false;
  db.name = "vvvote2";
  uwsgi = {
    socket = ":20002";
    http = ":10002";
  };
};
in composeConfig server1Conf server2Override

