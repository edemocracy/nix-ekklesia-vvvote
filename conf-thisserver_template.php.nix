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

/*********************************************************
*  Change the settings to match your database account
*/
$dbInfos = array(
		'dbtype'  => 'mysql',
		'dbhost'  => 'localhost',
		'dbuser'  => 'root',
		'dbpassw' => 'bernAl821',
		'dbname'  => 'election_server1',
		'prefix'  => 'el1_'
);

$debug     = true;

/*
 * Beyond this point in this file, you only need to make changes if you want to configure OAuth2 or externalToken-Auth
************************************************************/

require_once __DIR__ . '/../rsaMyExts.php';

date_default_timezone_set('Europe/Berlin'); // this is only used to avoid a warning message from PHP -> you do not need to adjust it. All dates are in UTC or use explicit time zone offset.

$webclientUrlbase = '../webclient'; // relativ to backend or absolute, no trailing slash

$serverNo = 1;

// load private key
function loadprivatekey($typePrefix, $serverNo, array $publickeys) {

  $serverkey = Array();
  $serverkey['serverName'] = $typePrefix . $serverNo;

  $privateKeyStrWraped = file_get_contents(__DIR__ . "/$typePrefix${serverNo}.privatekey.pem.php");
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
$oauthBEObayern = array(
    'serverId'      => 'BEOBayern',
    'client_id'     => 'vvvote',
    'client_secret' => 'your_client_secret',
    'redirect_uri'  => $configUrlBase . '/modules-auth/oauth/callback.php',
    'mail_identity' => 'voting', // this is used for the sendmail_endp and determines which sender will be used for the mail 
    'mail_sign_it'  => true,     // wheather the mail should be signed by the id server 
    'mail_content'	=> array(    // $electionId will be replaced by the electionId
        'subject' => 'Wahlschein erstellt',
        'body'    => "Hallo!\r\n\r\nSie haben für die Abstimmung >" . '$electionId' . "< einen Wahlschein erstellt.\r\nFalls dies nicht zutreffen sollte, wenden Sie sich bitte umgehend an einen Abstimmungsverantwortlichen.\r\n\r\nFreundliche Grüße\r\nDas Wahlteam\r\n"
        ),
    
    'authorization_endp'    => 'https://beoauth.piratenpartei-bayern.de/oauth2/authorize/',
    'token_endp'            => 'https://beoauth.piratenpartei-bayern.de/oauth2/token/',
    'get_profile_endp'      => 'https://beoauth.piratenpartei-bayern.de/api/v1/user/profile/', /* not needed at the moment */
    'is_in_voter_list_endp' => 'https://beoauth.piratenpartei-bayern.de/api/v1/user/listmember/',
    'get_membership_endp'   => 'https://beoauth.piratenpartei-bayern.de/api/v1/user/membership/',
    'get_auid_endp'			=> 'https://beoauth.piratenpartei-bayern.de/api/v1/user/auid/',
    'sendmail_endp'			=> 'https://beoauth.piratenpartei-bayern.de/api/v1/user/mails/'
);
$oauthConfig = array($oauthBEObayern['serverId'] => $oauthBEObayern);


$pserverkey = loadprivatekey('PermissionServer', $serverNo, $pServerKeys);
// only needed for a tally server, option
$tserverkey = loadprivatekey('TallyServer',      $serverNo, $tServerKeys); // TODO use separate numeration for tally and permission servers
?>
''
