self: {
  debug = true;
  keydir = null;
  # By default, keys are linked from keydir to the Nix store. Activate the following setting to copy them instead.
  # !!!WARNING: private keys will be world-readable in the Nix store when this is set to true!!!
  copyKeysToStore = false;
  serverNumber = 1; # position of this server, starts with 1
  # urls for the backend servers. The first server is pos 1, the second pos 2 and so on.
  backendUrls = [ "http://localhost:10001/" "http://localhost:10002/" ];
  idServerUrl = "https://id.localhost";
  hostingOrganisationUrl = "";

  tallyServerNumber = 1; # which server acts as tally server? (starts at 1!)
  votePort = 10001;
  webclientPort = 10003;
  webclientUrl = "http://localhost:${toString self.webclientPort}";
  useAnonServer = true;

  isTallyServer = self.tallyServerNumber == self.serverNumber;

  db = {
    name = "vvvote";
    host = "localhost";
    port = "3307";
    user = "vvvote";
    password = "vvvote";
    prefix = "";
  };

  uwsgi = {
    socketPort = 20001;
    socketAddress = "127.0.0.1";
    httpPort = 10001;
    httpAddress = "127.0.0.1";
  };

  oauth = {
    serverId = "ekklesia";
    serverDescription = "ID Server";
    clientIds =  [ "vvvote" "vvvote2" ];
    clientSecrets = [ "vvvote" "vvvote2" ];
    oauthUrl = self.idServerUrl + "/";
    resourcesUrl = self.idServerUrl + "/";
  };
}
