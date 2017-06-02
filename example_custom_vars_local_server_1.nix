# Override default settings for server 1.
self: default: {
  # Other settings defined here could refer to this value by using `self.id_server_url`.
  # The original value from the default config can be accessed with `default.id_server_url`.
  id_server_url = "http://idserver.example.com";
  # Selective overriding of settings in nested sets is supported. Other default settings in `db` will be kept, only 'db.name' is changed.
  db.name = "vvvote_example";
}
