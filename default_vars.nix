self: {
  debug = true;
  keydir = null;
  server_number = 1; # position of this server, starts with 1
  # urls for the backend servers. The first server is pos 1, the second pos 2 and so on.
  backend_urls = [ "http://localhost:10001/" "http://localhost:10002/" ];
  id_server_url = "https://id.localhost";

  is_tally_server = true;
  vote_port = 80;

  db = {
    name = "vvvote";
    host = "localhost";
    port = "3307";
    user = "vvvote";
    password = "vvvote";
    prefix = "";
  };

  uwsgi = {
    socket = ":20001";
    http = ":10001";
  };

  oauth = {
    server_id = "ekklesia";
    client_id = "vvvote";
    client_secret = "vvvote";
    endpoints = {
      authorization = self.id_server_url + "/oauth/authorize/";
      token = self.id_server_url + "/oauth/token/";
      is_in_voter_list = self.id_server_url + "/api/v1/user/listmember/";
      get_membership = self.id_server_url + "/api/v1/user/membership/";
      get_auid = self.id_server_url + "/api/v1/user/auid/";
      sendmail = self.id_server_url + "/api/v1/user/mails/";
    };
  };
}
