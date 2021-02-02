{ sources ? null
  , backendConfigDir
  , listen ? "127.0.0.1:10000"
  , pidfile ? "/tmp/vvvote.pid"
  , compileWebclient ? false
  , logToJournald ? false
}:
with builtins;

let
  deps = import ./deps.nix { inherit sources; };
  inherit (deps) php pkgs vvvote apacheHttpd;
  lib = pkgs.lib;

  backendHttpdConfig = pkgs.callPackage ./backend-httpd.conf.nix ({
    inherit listen php lib vvvote apacheHttpd;
  } // lib.optionalAttrs logToJournald {
    customLog = "journald";
    errorLog = "journald";
  });
  backendHttpdConfigFile = pkgs.writeText "backend-httpd.conf" backendHttpdConfig;

in pkgs.stdenv.mkDerivation {
  buildInputs = [ php ];
  name = "nix-ekklesia-vvvote";
  # only run needed phases because unpack fails when src isn't given
  phases = [ "installPhase" "fixupPhase" ];
  passthru = { inherit listen; };
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${vvvote}/backend $out
    # not needed in production, but helpful for debugging
    ln -s ${backendConfigDir} $out/config

    cat << EOF > $out/bin/vvvote-backend.sh
    #!${pkgs.runtimeShell}
    export VVVOTE_CONFIG_DIR=\''${VVVOTE_CONFIG_DIR:-${backendConfigDir}}
    echo "using config dir \$VVVOTE_CONFIG_DIR"
    export PHPRC=${php.phpIni}

    ${apacheHttpd}/bin/httpd \
      -f ${backendHttpdConfigFile} \
      -D FOREGROUND \
      -C "ServerRoot $out" \
      -C "PidFile ${pidfile}" \
      "\$@"
    EOF
    chmod a+x $out/bin/vvvote-backend.sh
  ''
  # optimization: compile webclient
  + lib.optionalString compileWebclient ''
    mkdir $out/webclient
    cd $out/backend
    export VVVOTE_CONFIG_DIR="${backendConfigDir}"
    rc=0
    php getclient.php > $out/webclient/index.html || rc=$?
    if [[ $rc != 0 ]]; then
      echo "compiling the webclient failed:"
      cat $out/webclient/index.html
      exit $rc
    fi
  '';
}
