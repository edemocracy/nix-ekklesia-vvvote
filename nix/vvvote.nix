{ pkgs, lib, php, vvvoteSrc, disableAnonServer ? false }:

pkgs.stdenv.mkDerivation {
  name = "vvvote";
  src = vvvoteSrc;

  patches =
    lib.optional disableAnonServer ./0001-disable-anon-server.patch;

  dontBuild = true; # nothing to build for this PHP / JS app ;)
  installPhase = ''
    cp -r . $out
    cp -r $out/backend/modules-auth/oauth $out/backend/modules-auth/oauth2
    mv $out/backend/webclient-sources/config/config-example.js $out/backend/webclient-sources/config/config.js
  '';
}
