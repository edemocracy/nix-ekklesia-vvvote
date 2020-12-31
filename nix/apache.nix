# Taken from nixpkgs unstable with optional stuff disabled and added systemd support.
# Needs a bit more preparation (see preConfigure) because we build from the source repo here.
# Apache HTTPD 2.5 supports logging to journald via the systemd API.
# I wanted to disable LDAP but build fails without is (disable module?).

{ stdenv, autoconf, which, fetchFromGitHub, fetchurl, systemd, perl, zlib, apr, aprutil, pcre, libiconv, lynx
, proxySupport ? false
, sslSupport ? false, openssl
, http2Support ? false, nghttp2
, ldapSupport ? true, openldap
, libxml2Support ? false, libxml2
, brotliSupport ? false, brotli
, luaSupport ? false, lua5
}:

let
  inherit (stdenv.lib) optional;

  aprutilSrc = fetchTarball {
    url = "https://www-eu.apache.org/dist/apr/apr-util-1.6.1.tar.bz2";
    sha256 = "16yj12vvp0snq1l61vffl5lgcwc2gznmzbmas5h36n759rrw48ic";
  };

  aprSrc = fetchTarball {
    url = "https://www-eu.apache.org/dist/apr/apr-1.7.0.tar.bz2";
    sha256 = "1l1xc7lc2was6z5hq4zrrycivk56cjds0kc19q3mgmikarcj4x5y";
  };
in

assert sslSupport -> aprutil.sslSupport && openssl != null;
assert ldapSupport -> aprutil.ldapSupport && openldap != null;
assert http2Support -> nghttp2 != null;

stdenv.mkDerivation rec {
  rev = "be4473d84e226ef472b49611fe68127b8100ab13";
  version = "2.5-g${rev}";
  pname = "apache-httpd";

  src = fetchFromGitHub {
    repo = "httpd";
    owner = "apache";
    inherit rev;
    sha256 = "19bdjhjhgisrasg62i0gnpq0z2560f94jf7g4yjx1jz1vqcliayb";
  };

  preConfigure = ''
    ./buildconf --with-apr=${aprSrc} --with-apr-util=${aprutilSrc}
  '';

  # FIXME: -dev depends on -doc
  outputs = [ "out" "dev" "man" "doc" ];
  setOutputFlags = false; # it would move $out/modules, etc.

  buildInputs = [perl systemd autoconf which pcre zlib ] ++
    optional brotliSupport brotli ++
    optional sslSupport openssl ++
    optional ldapSupport openldap ++    # there is no --with-ldap flag
    optional libxml2Support libxml2 ++
    optional http2Support nghttp2 ++
    optional stdenv.isDarwin libiconv;

  prePatch = ''
    sed -i config.layout -e "s|installbuilddir:.*|installbuilddir: $dev/share/build|"
    sed -i support/apachectl.in -e 's|@LYNX_PATH@|${lynx}/bin/lynx|'
  '';

  # Required for ‘pthread_cancel’.
  NIX_LDFLAGS = stdenv.lib.optionalString (!stdenv.isDarwin) "-lgcc_s";

  configureFlags = [
    "--with-apr=${apr.dev}"
    "--with-apr-util=${aprutil.dev}"
    "--with-z=${zlib.dev}"
    "--with-pcre=${pcre.dev}"
    "--disable-maintainer-mode"
    "--disable-debugger-mode"
    "--enable-mods-shared=all"
    "--enable-mpms-shared=all"
    "--enable-cern-meta"
    "--enable-imagemap"
    "--enable-cgi"
    "--includedir=${placeholder "dev"}/include"
    (stdenv.lib.enableFeature proxySupport "proxy")
    (stdenv.lib.enableFeature sslSupport "ssl")
    (stdenv.lib.withFeatureAs libxml2Support "libxml2" "${libxml2.dev}/include/libxml2")
    "--docdir=$(doc)/share/doc"

    (stdenv.lib.enableFeature brotliSupport "brotli")
    (stdenv.lib.withFeatureAs brotliSupport "brotli" brotli)

    (stdenv.lib.enableFeature http2Support "http2")
    (stdenv.lib.withFeature http2Support "nghttp2")

    (stdenv.lib.enableFeature luaSupport "lua")
    (stdenv.lib.withFeatureAs luaSupport "lua" lua5)
  ];

  enableParallelBuilding = true;

  stripDebugList = [ "lib" "modules" "bin" ];

  postInstall = ''
    mkdir -p $doc/share/doc/httpd
    mv $out/manual $doc/share/doc/httpd
    mkdir -p $dev/bin
    mv $out/bin/apxs $dev/bin/apxs
  '';

  passthru = {
    inherit apr aprutil sslSupport proxySupport ldapSupport;
  };

  meta = with stdenv.lib; {
    description = "Apache HTTPD, the world's most popular web server";
    homepage    = "http://httpd.apache.org/";
    license     = licenses.asl20;
    platforms   = stdenv.lib.platforms.linux ++ stdenv.lib.platforms.darwin;
    maintainers = with maintainers; [ lovek323 peti ];
  };
}
