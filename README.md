Nix-Ekklesia-VVVote
===================

Set of Nix expressions for building and installing VVVote, intended for use with the Ekklesia eDemocracy project.


## Quick Test Installation In Four Steps

This should work on all Linux distributions and MacOS. You need the [Nix package manager](https://nixos.org/nix) (version > 1.8) and a running MySQL server.

### What Will Happen?

-   Step 3 creates two MySQL databases. Please read the SQL script before executing it!
-   The last step downloads all missing dependencies. It may take some minutes on the first run. Dependencies are installed to `/nix/store`.
-   Server keys and logfiles are placed in the subdir `quickstart`. Keys are overwritten on each run, log files are appended.

### How Is It Done?

1. Clone the repository: `git clone https://github.com/dpausp/nix-ekklesia-vvvote`
2. Go to the nix-ekklesia-vvvote directory: `cd nix-ekklesia-vvvote`
3. Create the MySQL databases and grant access: `mysql prepare-databases.sql` (mysql call depends on your MySQL configuration)
4. Run VVVote: `./vvvote-quickstart`

The last line in the output should say _serving at port 10003_.
You can visit `http://localhost:10003` now.

## Nix Files In This Repo

-   `vvvote.nix`: This Nix expression builds and installs a VVVote (backend + webclient) instance
-   `uwsgi.nix`: Custom uwsgi with PHP support
-   `default.nix`: Runs the installation process. Builds config
-   `src.nix`: Controls which VVVote version is used
-   `nixpkgs.nix`: Controls which nixpkgs version is used for build tools and VVVote dependencies
-   `conf-allservers.php.nix, conf-thisserver.php.nix, config.js.nix`: VVVote configuration template files
- `*vars*.nix`: vars files contain the settings that influence the build process or customize the configuration files built from templates.


## Configuring, Building And Installing VVVote

VVVote configuration files are created by Nix in the installation process. Default settings are in `default_vars.nix` which can be overridden by custom config expressions.
To configure two instances, copy `example_custom_vars_local_server_1.nix` and `example_custom_vars_local_server_2.nix` to `custom_vars_local_server_1.nix` resp. `custom_vars_local_server_2.nix` and read the comments in both files.

See the `vvvote-local` script as an example how to build and run the two VVVote backend instances. The first one is also used to serve the webclient to users.

## Building VVVote Docker Images

The Nix expression in `docker.nix` builds image tars that can be used with Docker.  (Private) keys must be copied to the Nix store and then to the image, so the setting `copy_keys_to_store` must be set to `true` and `keydir` must be a path, absolute or relative (without double quotes). `uwsgi.http_address` should be set to `""` (empty string) so HTTP can be reached from outside the container.

Have a look at `vvvote-build-docker-images` to see how to build and import images into Docker.
