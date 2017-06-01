{ lib, fetchurl, stdenv, pkgconfig, 
  php56, curl, freetype, gmp, icu, jansson, libjpeg, libmcrypt, libpng, libxml2, mysql, ncurses, openssl, pcre, python3, readline, zlib }:

stdenv.mkDerivation rec { 
  version = "2.0.15";
  name = "uwsgi-${version}";

  src = fetchurl {
    url = "https://projects.unbit.it/downloads/${name}.tar.gz";
    sha256 = "1zvj28wp3c1hacpd4c6ra5ilwvvfq3l8y6gn8i7mnncpddlzjbjp";
  };

  nativeBuildInputs = [ python3 pkgconfig ];

  configurePhase = ''
    export pluginDir=$out/lib/uwsgi
    substituteAll ${./nixos.ini} buildconf/nixos.ini
  '';


  php = php56.merge {
    flags = {
      embed = {
        configureFlags = [ "--enable-embed" ];
      };

      phpdbg = {
        configureFlags = [ "--enable-phpdbg" ];
      };
    };

    outputs = [ "out" ];
  
    cfg = {
      phpdbgSupport = true;
      embedSupport = true;
      apxs2Support = false;
      imapSupport = false;
      ldapSupport = false;
      postgresqlSupport = false;
      pdo_pgsqlSupport = false;
      sqliteSupport = false;
      ftpSupport = false;
      fpmSupport = false;
      mssqlSupport = false;
      soapSupport = false;
      exifSupport = false;
    };
  };

  basePlugins = "";


  buildInputs = [ 
    curl 
    freetype 
    gmp 
    icu 
    jansson 
    libjpeg 
    libmcrypt
    libpng 
    libxml2 
    mysql.lib 
    ncurses 
    openssl 
    pcre 
    php
    python3 
    readline 
    zlib 
  ];

  passthru = {
    inherit php;
  };

  buildPhase = ''
    mkdir -p $pluginDir
    python3 uwsgiconfig.py --build nixos
    python3 uwsgiconfig.py --plugin plugins/php nixos
    python3 uwsgiconfig.py --plugin plugins/http nixos
  '';

  installPhase = ''
    install -Dm755 uwsgi $out/bin/uwsgi
  '';

  meta = with stdenv.lib; {
    homepage = http://uwsgi-docs.readthedocs.org/en/latest/;
    description = "A fast, self-healing and developer/sysadmin-friendly application container server coded in pure C";
    license = licenses.gpl2;
  };
}
