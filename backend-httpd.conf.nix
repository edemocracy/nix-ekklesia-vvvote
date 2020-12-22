{ lib, php, vvvote, apacheHttpd, vars }:

with builtins;

let
  phpMajorVersion = lib.versions.major (lib.getVersion php);

  modules = [
    "authn_core"
    "authz_core"
    "log_config"
    "mime"
    "negotiation"
    "alias"
    "rewrite"
    "unixd"
    "slotmem_shm" "socache_shmcb"
    "mpm_event"
    { name = "php${phpMajorVersion}"; path = "${php}/modules/libphp${phpMajorVersion}.so"; }
  ];

  listen = with vars; "${backend.httpAddress}:${toString backend.httpPort}";

in ''
${let
    mkModule = module:
      if isString module then { name = module; path = "${apacheHttpd}/modules/mod_${module}.so"; }
      else if isAttrs module then { inherit (module) name path; }
      else throw "Expecting either a string or attribute set including a name and path.";
  in
    lib.concatMapStringsSep "\n" (module: "LoadModule ${module.name}_module ${module.path}") (lib.unique (map mkModule modules))
}

TypesConfig ${apacheHttpd}/conf/mime.types
Include ${apacheHttpd}/conf/extra/httpd-default.conf
Include ${apacheHttpd}/conf/extra/httpd-languages.conf

ServerName localhost

AddHandler type-map var
AddType application/x-httpd-php .php

ErrorLog /dev/stderr
LogLevel notice
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
CustomLog /dev/stdout combined

TraceEnable off

Listen ${listen} http

<VirtualHost ${listen}>
  DocumentRoot "backend"
</VirtualHost>
''
