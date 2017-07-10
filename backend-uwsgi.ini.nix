with vars.uwsgi; with builtins; ''
  [uwsgi]
  plugins = 0:php
  socket = ${socket_address}:${toString socket_port}
  http = ${http_address}:${toString http_port}
  project_dir = ${vvvote}/backend
  php-docroot = %(project_dir)
  php-allowed-ext = .php
  php-allowed-ext = .inc
''
