''
  [uwsgi]
  plugins = 0:php
  socket = ${vars.uwsgi.socket}
  http = ${vars.uwsgi.http}
  project_dir = ${vvvoteBackend}
  php-docroot = %(project_dir)
  php-allowed-ext = .php
  php-allowed-ext = .inc
''