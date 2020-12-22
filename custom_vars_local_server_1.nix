self: default: {
  publicKeydir = /home/ts/data_git/vvvote/public_keys;
  privateKeydir = "/var/tmp/vvvote/private_keys";
  compileWebclient = true;
  copyPrivateKeysToStore = false;
  useAnonServer = false;
  backendUrls = [ "http://localhost/backend1" "http://localhost/backend2" ];
  idServerUrl = "https://keycloak.test.ekklesiademocracy.org/auth/realms/test/protocol/openid-connect/";
  webclientUrl = "http://localhost/vvvote";
  oauth = {
    clientIds = [ "vvvote_neu_local_446" "vvvote_neu_local_447" ];
    clientSecrets = ["d69065d0-fa2a-4cbb-a37a-dc16c3827c84" "34f517b8-9553-4a10-931b-36a2fae1edad"];
    notifyUrl = "https://notify.test.ekklesiademocracy.org/freeform_message";
    notifyClientId = "example_app";
    notifyClientSecret = "eeee";
  };
}
