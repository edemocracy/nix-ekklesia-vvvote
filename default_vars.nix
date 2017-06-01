let base_url = "https://id.localhost";
in rec {
  debug = true;
  server_number = 1;
  number_of_servers = 2;
  keydir = null;
  backend_url_1 = "http://localhost:10001/";
  backend_url_2 = "http://localhost:10002/";
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
      authorization = base_url + "/oauth/authorize/";
      token = base_url + "/oauth/token/";
      is_in_voter_list = base_url + "/api/v1/user/listmember/";
      get_membership = base_url + "/api/v1/user/membership/";
      get_auid = base_url + "/api/v1/user/auid/";
      sendmail = base_url + "/api/v1/user/mails/";
    };
  };
}
