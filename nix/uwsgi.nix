{ lib, fetchurl, stdenv, pkgconfig,
  php74, curl, freetype, gmp, icu, jansson, libjpeg, libmcrypt, libpng, libxml2, mysql, ncurses, openssl, pcre, python3, readline, zlib }:

let
  php = php74.withExtensions ({ enabled, all }:
    []
   );

in stdenv.mkDerivation rec {
  version = "2.0.18";
  name = "uwsgi-${version}";

  src = fetchurl {
    url = "https://projects.unbit.it/downloads/${name}.tar.gz";
    sha256 = "10zmk4npknigmbqcq1wmhd461dk93159px172112vyq0i19sqwj9";
  };

  nativeBuildInputs = [ python3 pkgconfig ];

  configurePhase = ''
    export pluginDir=$out/lib/uwsgi
    substituteAll ${./nixos.ini} buildconf/nixos.ini
  '';



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
    mysql
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
