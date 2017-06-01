let
	pkgUrl = "https://d3g5gsiof5omrk.cloudfront.net/nixpkgs/nixpkgs-17.09pre106045.7369fd0b51/nixexprs.tar.xz";
in
	import ( builtins.fetchTarball pkgUrl ) {}
