with vars.uwsgi; with builtins; ''
  [uwsgi]
  plugins = 0:php
  socket = ${socketAddress}:${toString socketPort}
  http = ${httpAddress}:${toString httpPort}
  project_dir = ${vvvote}/backend
  php-docroot = %(project_dir)
  php-allowed-ext = .php
  php-allowed-ext = .inc
''
