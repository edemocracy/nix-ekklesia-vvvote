{ sources ? null }:
let
  deps = import ./nix/deps.nix { inherit sources; };
  inherit (deps) pkgs glibcLocales;
  inherit (pkgs) lib stdenv;
  caBundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

in pkgs.mkShell {
  name = "vvvote";
  buildInputs = deps.shellInputs;
  shellHook = ''
    export PATH=${deps.shellPath}:$PATH
    # A pure nix shell breaks SSL for git and nix tools which is fixed by setting
    # the path to the certificate bundle.
    export SSL_CERT_FILE=${caBundle}
    export NIX_SSL_CERT_FILE=${caBundle}
  '' +
  lib.optionalString (pkgs.stdenv.hostPlatform.libc == "glibc") ''
    export LOCALE_ARCHIVE=${glibcLocales}/lib/locale/locale-archive
  '';
}
