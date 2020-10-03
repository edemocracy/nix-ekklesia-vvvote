self: default: {
  keydir = /home/ts/data_git/vvvote/keys;
  copy_keys_to_store = true;
  uwsgi.http_address = "";
  use_anon_server = false;
  id_server_url = "https://testid.televotia.ch";
  oauth.client_ids = [ "vvvote_local" "vvvote2_local" ];
}
