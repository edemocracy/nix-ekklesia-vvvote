{ lib, fetchurl, stdenv, pkgconfig, 
  php56, curl, freetype, gmp, icu, jansson, libjpeg, libmcrypt, libpng, libxml2, mysql, ncurses, openssl, pcre, python3, readline, zlib }:

stdenv.mkDerivation rec { 
  version = "2.0.14";
  name = "uwsgi-${version}";

  src = fetchurl {
    url = "https://projects.unbit.it/downloads/${name}.tar.gz";
    sha256 = "11r829j4fyk7y068arqmwbc9dj6lc0n3l6bn6pr5z0vdjbpx3cr1";
  };

  nativeBuildInputs = [ python3 pkgconfig ];

  configurePhase = ''
    export pluginDir=$out/lib/uwsgi
    substituteAll ${./nixos.ini} buildconf/nixos.ini
  '';


  phpCustom = php56.merge {
    flags = {
      embed = {
        configureFlags = [ "--enable-embed" ];
      };
    };

    cfg = {
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
    phpCustom
    python3 
    readline 
    zlib 
  ];

  passthru = {
    php = phpCustom;
  };

  buildPhase = ''
    mkdir -p $pluginDir
    python3 uwsgiconfig.py --build nixos
    touch unix.h
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
