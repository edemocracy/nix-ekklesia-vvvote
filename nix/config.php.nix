with vars;
with builtins;
let
	toPhpString = s: "'${toString s}'";
	toPhpBool = s: if s then "true" else "false";
	toPhpStringArray = ll: "array(${lib.concatMapStringsSep ", " toPhpString ll})";
in ''
<?php
$config = array (

		// URLs of all Vvvote (permission) servers
		// point to the URL where the /api/ is contained (api will be added automatically)
		// no trailing slash
		// At least 2 servers are needed.
		// This value must be the same on all Vvvote (permission) servers.
		'pServerUrlBases' => ${toPhpStringArray backendUrls},

		// TCP-Port of the Vvvote (tally) servers (currently only the first one is used)
		// Do not use SSL/TLS here. Why? The Vvvote-client uses an anonymizing service for
		// sending the vote. The anonymizing service strips off the browser's fingerprint
		// which cannot be done in an SSL/TLS connection. Anyway, the transmitted data itself
		// is encrypted by the Vvvote client using RSA/AES encryption
		// uncomment, if you need to change it..
		// This value must be the same on all Vvvote (permission) servers.
		// defaults to 'tServerStoreVotePorts' => array ('80', '80'),
		'tServerStoreVotePorts' => array (${toPhpString votePort}, ${toPhpString votePort}),


		// URL to your organisations's website
		// will be used as link for your organisation's logo
		// put the logo of your organisation in config, name it 'logo_brand_47x51.svg'
		'linkToHostingOrganisation' => '${hostingOrganisationUrl}',

		// URL to the about page (German: Impressum)
		'aboutUrl' => '#',

		// Number of this server. Numbering starts with 1 and must correspond to the sequence
		// given in >pServerUrlBases< above
		'serverNo' => ${toString serverNumber},

		// If debug is set and some error occurs, Vvvote will send possibly sensetive data
		// to the client which gives more information what caused the error.
		// defaults to false. In a productive environment, always set this to false.
		'debug' => ${toPhpBool debug},

		// put the credentials for the database connection here
		'dbInfos' => array (
				'dbtype' => 'mysql', // Only "mysql" is tested
				'dbhost' => '${db.host}',
				'dbuser' => '${db.user}',
				'dbpassw'=> '${db.password}',
				'dbname' => '${db.name}',
				// All table names will be prefixed with this prefix. It does not have any functional effect.
				'prefix' => '${db.prefix}'
		),


		// You can use an oAuth2 server or external tokens in order to check the users for egibility
		// Vvvote can handle several auth servers - just add another array in the
		// 'oauthConfig' resp. 'externalTokenConfig' array.
		// The "cmrcx-Basisentscheid" uses external-token-auth, whereas the ekklesia ID-Server uses oAuth2.
		// For oAuth2, types "ekklesia" and "keycloak" are supported.

		// In case you are using oAuth2, fill in the following section
		// Vvvote can handle several auth servers - just add another array.
		'oauth2Config' => array (
				array (
						// This is arbitrary, must be unique and is set in the new election request in order to
						// request this auth config
						// It must match the according value in the portal configuration
						'serverId' => '${oauth.serverId}',

						// Short server description: Shown in webclient
						'serverDesc' 	=>	'${oauth.serverDesc}',

						// OAuth2 client-ID needed for authentication at the OAuth2 server
						// The client Ids of all vvvote servers are needed here, because the webclient need to
						// know them all. This server picks his own based on $serverNo
						// Vvvote uses "authorization code" flow. Maybe you have to set this option in
						// the oAuth2 server config resp. in the vvvote account there.
						'client_ids' => ${toPhpStringArray oauth.clientIds},

						// OAuth2 client secret needed for authentication at the OAuth2 server
						'client_secret' => '${oauth.clientSecret}',

						// Hint for the configuration of the oAuh2 server:
						// Most oAuth2 servers require that you provide a callback-URL in order to make the authorization work.
						// This URL will be: [pServerUrlBase of this server] + '/api/v1/modules-auth/oauth/callback.php', e.g. https://demo.vvvote.de/api/v1/modules-auth/oauth2/callback

						// For oAuth2 server, currently "ekklesia" and "keycloak" are supported.
						// Type "ekklesia" uses a long list of endpoints, see loadconfig.php for details.
						// Type "keycloak" uses the following endpoints:
						// * "/token/" (in order to obtain the access_token),
						// * "userinfo" (in order to obtain all relevant userinfo [claims: "eligible": true/false, "roles": array, "verified": true/false]
						// membership and voter lists are currently not supported by the keycloak server.
						// roles is an array of hirachical departments a user is a member of (e.g. ["KV Düsseldorf", "LV NRW", "Deutschland"])
						'type' => 'keycloak',

						// keycloak:
						// You can use vvvote/doc/vvvote_keycoak_config_[1|2]_example.js to import the basic config
						// into keycloak (in keycloak: clients --> create --> import select file).
						// Use vvvote/doc/vvvote_keycoak_config_1_example.js for the first Vvvote server.
						// Use vvvote/doc/vvvote_keycoak_config_2_example.js for the seconde Vvvote server.
						// In keycloak, the first vvvote server should be set to requiere user consent
						// while the second vvvote server must set to not requiere user consent
						// (in keycloak: "clients" -> "edit" -> "settings" -> "Consent Required" must be off
						// for the second Vvvote server because no interaction is allowed).

						// default scopes requested for keycloak: "eligible user_roles verified" but you can set different scopes by uncommenting the following line
						//'scope' => 'eligible user_roles verified ekklesia_notify',

						// You must use SSL/TLS here as the oAuth2 security relies on it.
						// In order to do so:
						// Copy the certificate (.pem)-file in backend/config and name it <serverId>.pem (you can easily use a webbrowser to obtain that file).
						// Make sure the .pem file contains the complete certificate chain to the root certifitace. You can easily concat them.
						// You can use retrieve-tls-chains.php to automatically obtain all needed certificate chains and save them in the right place.
						// Or, on linux, you can use the following command (replacing [hostname.domain] acordingly twice(!) and [serverId]:
						// echo "" | openssl s_client -connect [hostname.domain]:443 -servername [hostname.domain] -prexit 2>/dev/null | sed -n -e '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p' >[serverId.pem]

						// ekklesia: The oaut2 URL before the /oaut2/ part, e.g. https://beoauth.piratenpartei-bayern.de/
						// keycloak: get this info from the admin interface of the keycloak server: client --> installation
						'oauth_url' => '${oauth.oauthUrl}',

						// id-server: The ressources URL including the version part, e.g. https://beoauth.piratenpartei-bayern.de/api/v1/
						// keycloak: get this info from: /auth/realms/{realm}/.well-known/openid-configuration, eg. https://keycloak.test.ekklesiademocracy.org/auth/realms/test/.well-known/openid-configuration
						'ressources_url' => '${oauth.resourcesUrl}',

						// Data usage note shown in the client before redirecting to the keycloak server
						// Array of language codes as defined in webclient-sources/i18n/vvvote_*.js: there the 'lang' field,
						// currently supported: 'de', 'en_US', 'fr'.
						// If the user chooses a language for which no string is given here, the content of the
						// first element of the array will be displayed.
						// The Text may not exceed 1 line, the layout may be corrupted otherwiese.
						'serverUsageNote' => array(
								'en_US' => '${oauth.serverUsageNote.en_US}',
								'de'    => '${oauth.serverUsageNote.de}',
								'fr'    => '${oauth.serverUsageNote.fr}'
						),

						// Authorization data for the notify server (using http basic authentication)
						// this only applies to keycloak / special notify server
						'notify_client_id' => '${oauth.notifyClientId}',
						'notify_client_secret' => '${oauth.notifyClientSecret}',
						'notify_url' => '${oauth.notifyUrl}',

						// wheather the mail should be signed by the oAuh2 ressource server
						'mail_sign_it' => true,

						// Subject and content of the mail to be send to the user who generated a voting certificate.
						// $electionId will be replaced by the electionId in subject and body
						'mail_content_subject' => '${mailContentSubject}',
						'mail_content_body' => '${mailContentBody}'
				),
		), // end oauth config

		// If you use the default dirs, nothing needs to be changed here.
		// It can be absolut (URL allowed) or relativ to api/v1/index.php
		// defaults to '../../webclient/';
		// uncomment, if you need to change the default.
		'webclientUrlbase' => '${webclientUrl}'
);
?>
''
