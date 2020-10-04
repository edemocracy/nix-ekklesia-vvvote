self: default: {
  #keydir = /home/ts/data_git/vvvote/keys;
  copyKeysToStore = true;
  uwsgi.httpAddress = "";
  useAnonServer = false;
  idServerUrl = "https://keycloak.test.ekklesiademocracy.org";
  oauth.clientIds = [ "vvvote_local" "vvvote2_local" ];
}
