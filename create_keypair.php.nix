''#!/usr/bin/env php
<?php

require_once '${vvvoteBackend}/Math/BigInteger.php';
require_once '${vvvoteBackend}/Crypt/RSA.php';
require_once '${vvvoteBackend}/tools.php';

define('CRYPT_RSA_MODE', CRYPT_RSA_MODE_INTERNAL); // this is needed because otherwise openssl (if present) needs special configuration in openssl.cnf when creating a new key pair

if (count($argv) < 4) {
    print 'usage: ./create_keypair.php <targetDir> <p|t> <serverIdNumber>' . "\np: for permission server\nt: for tallying server\n"; exit(1);
}

$targetDir = $argv[1];
switch ($argv[2]) {
    case 'p': case 'P': $type = 'PermissionServer'; $bitlength =  2048; break; // only 512 because blinding in JavaScript will take more than 5 minutes for 2048
    case 't': case 'T': $type = 'TallyServer';      $bitlength = 2048; break;
    default:
        print "Error: Argument 2 must be either 'p' or 't'";
        exit(1);
}
$thisServerName = $type . $argv[3];

$crypt_rsa = new Crypt_RSA();
$keypair = $crypt_rsa->createKey($bitlength);

// save private key to file
$keystr = str_replace('\/', '/', json_encode($keypair));
file_put_contents("$targetDir/$thisServerName.privatekey.pem.php", "<?php\r\n/* \r\n" . $keypair['privatekey'] . "\r\n*/\r\n?>");

// save public key to file
$crypt_rsa->loadKey($keypair['publickey']);
$pubkey = array( // fields defined by JSON Web Key http://openid.net/specs/draft-jones-json-web-key-03.html
        'alg'   => 'RSA', // only RSA is supported by vvvote
        'mod'   => base64url_encode($crypt_rsa->modulus->toBytes()),
        'exp'   => base64url_encode($crypt_rsa->exponent->toBytes())
);
echo '<br>n: ' . base64url_encode($crypt_rsa->modulus->toBytes());
echo '<br>k: ' . $crypt_rsa->k;
echo '<br>exp: ' . base64url_encode($crypt_rsa->exponent->toBytes());
echo "<br>\r\n";
$pubkeystr = str_replace('\/', '/', json_encode($pubkey));
file_put_contents("$targetDir/$thisServerName.publickey", $keypair['publickey']); //$pubkeystr
?>
''
