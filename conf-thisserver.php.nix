with vars;
''
<?php
/**
 * return 404 if called directly
 */
if(count(get_included_files()) < 2) {
	header('HTTP/1.0 404 Not Found');
	echo "<h1>404 Not Found</h1>";
	echo "The page that you have requested could not be found.";
	exit;
}


// general config
$debug     = ${if debug then "true" else "false"};
$serverNo = ${toString server_number};


// DB config
$dbInfos = array(
		'dbtype'  => 'mysql',
		'dbhost'  => '${db.host}',
		'dbuser'  => '${db.user}',
		'dbpassw' => '${db.password}',
		'dbname'  => '${db.name}',
		'prefix'  => '${db.prefix}'
);


// key loading
require_once __DIR__ . '/../rsaMyExts.php';

date_default_timezone_set('Europe/Berlin');

$webclientUrlbase = '${webclient_url}';

function loadprivatekey($typePrefix, $serverNo, array $publickeys) {

  $serverkey = Array();
  $serverkey['serverName'] = $typePrefix . $serverNo;

  $privateKeyStrWraped = file_get_contents(__DIR__ . "/" . $typePrefix . "${toString server_number}.privatekey.pem.php");
  // extract the key from that file (when created with admin.php there are php markers around it in order to make apache execute it instead of delivering it)
  $privateKeyStr =  preg_replace('/.*(-----BEGIN RSA PRIVATE KEY-----(.*)-----END RSA PRIVATE KEY-----).*/mDs', '$1', $privateKeyStrWraped);
  $serverkey['privatekey'] = $privateKeyStr;

  // extract public key from private key
  $rsa       = new rsaMyExts();
  $rsa->loadKey($serverkey['privatekey']);
  $rsapub    = new rsaMyExts();
  $serverkey['publickey'] = $rsapub->_convertPublicKey($rsa->modulus, $rsa->publicExponent);

  // tests if .publickey matches to the public key in this .privatekey file
  $rsa       = new rsaMyExts();
  $rsa->loadKey($serverkey['publickey']);
  $i = find_in_subarray($publickeys, 'name', $serverkey['serverName']);
  $test = $rsa->modulus->compare($publickeys[$i]['modulus']);
  if ($test !== 0) throw ('internal server configuration error: .publickey does not match the .privatekey for ' . $serverkey['serverName']);
  return $serverkey;
}

$urltmp = parse_url($pServerUrlBases[$serverNo -1]);
if (! isset($urltmp['port']) || ($urltmp['port'] == 0)) {
	switch ($urltmp['scheme']) {
		case 'http':  $urltmp['port'] =  80; break;
		case 'https': $urltmp['port'] = 443; break;
		default: die('$pServerUrlBases must start with >http< or >https<');
	}
}


// OAuth 2.0 config
$configUrlBase = $pServerUrlBases[$serverNo -1];
$oauthEkklesia = array(
    'serverId'      => '${oauth.server_id}',
    'client_id'     => '${builtins.elemAt oauth.client_ids (server_number - 1)}',
    'client_secret' => '${builtins.elemAt oauth.client_secrets (server_number - 1)}',
    'redirect_uri'  => $configUrlBase . '/modules-auth/oauth/callback.php',
    'mail_identity' => 'voting', // this is used for the sendmail_endp and determines which sender will be used for the mail 
    'mail_sign_it'  => true,     // wheather the mail should be signed by the id server 
    'mail_content'	=> array(    // $electionId will be replaced by the electionId
        'subject' => 'Wahlschein erstellt',
        'body'    => "Hallo!\r\n\r\nSie haben für die Abstimmung >" . '$electionId' . "< einen Wahlschein erstellt.\r\nFalls dies nicht zutreffen sollte, wenden Sie sich bitte umgehend an einen Abstimmungsverantwortlichen.\r\n\r\nFreundliche Grüße\r\nDas Wahlteam\r\n"
        ),
    
    'authorization_endp'    => '${oauth.endpoints.authorization}',
    'token_endp'            => '${oauth.endpoints.token}',
    'is_in_voter_list_endp' => '${oauth.endpoints.is_in_voter_list}',
    'get_membership_endp'   => '${oauth.endpoints.get_membership}',
    'get_auid_endp'			=> '${oauth.endpoints.get_auid}',
    'sendmail_endp'			=> '${oauth.endpoints.sendmail}'
);

$oauthConfig = array($oauthEkklesia['serverId'] => $oauthEkklesia);
$pserverkey = loadprivatekey('PermissionServer', $serverNo, $pServerKeys);
${if is_tally_server then "$tserverkey = loadprivatekey('TallyServer', $serverNo, $tServerKeys);" else ""}
?>
''
