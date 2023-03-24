self: {
  compileWebclient = true;
  dataProtectionPolicy = {
    default = "Data Protection Policy";
    de = "Datenschutzerklärung";
  };
  debug = false;
  publicKeydir = null;
  privateKeydir = null;
  # By default, private keys are linked from keydir to the Nix store. Activate the following setting to copy them instead.
  # !!!WARNING: private keys will be world-readable in the Nix store when this is set to true!!!
  copyPrivateKeysToStore = false;
  serverNumber = 1; # position of this server, starts with 1
  # urls for the backend servers. The first server is pos 1, the second pos 2 and so on.
  backendUrls = [ "http://localhost:10001" "http://localhost:10002" ];
  idServerUrl = "https://id.localhost";
  hostingOrganisationUrl = "";
  mailContentSubject = "Wahlschein erstellt";
  mailContentBody = ''
    Hallo!

    Sie haben für die Abstimmung >$electionId< einen Wahlschein erstellt.
    Falls dies nicht zutreffen sollte, wenden Sie sich bitte umgehend an einen Abstimmungsverantwortlichen.

    Freundliche Grüße

    Das Wahlteam
  '';

  tallyServerNumbers = [ 1 2 ]; # which server acts as tally server? (starts at 1!)
  anonymizerUrl = "http://anonymouse.org/cgi-bin/anon-www_de.cgi/";
  voteScheme = "http";
  votePort = 80;
  webclientUrl = "http://localhost/vvvote";
  useAnonServer = true;


  isTallyServer = builtins.any (n: self.serverNumber == n) self.tallyServerNumbers;

  db = {
    name = "vvvote";
    host = "localhost";
    user = "vvvote";
    password = "";
    prefix = "";
  };

  backend = {
    httpPort = 10001;
    httpAddress = "127.0.0.1";
  };

  oauth = {
    serverId = "ekklesia";
    serverDesc = "ID Server";
    clientIds =  [ "vvvote" "vvvote2" ];
    clientSecret = "invalidClientSecret";
    extraScopes = [];
    notifyClientId = "example_app";
    notifyClientSecret = "invalidNotifyClientSecret";
    notifyUrl = "https://notify.invalid/freeform_message";
    oauthUrl = self.idServerUrl;
    resourcesUrl = self.idServerUrl;
    serverUsageNote = {
      de = "";
      fr = "";
      en_US = "";
    };
  };
}
