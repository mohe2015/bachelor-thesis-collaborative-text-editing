{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = nixpkgs.lib;
          text-rdt-sbt-launcher-source = lib.fileset.toSource {
            root = ./text-rdt;
            fileset = ./text-rdt/project/build.properties;
          };
          text-rdt-sbt-dependencies-source = lib.fileset.toSource {
            root = ./text-rdt;
            fileset = lib.fileset.unions
              [
                ./text-rdt/build.sbt
                ./text-rdt/project/build.properties
                ./text-rdt/project/plugins.sbt
                ./text-rdt/.jvmopts
              ];
          };
        in
        {
          packages.text-rdt-npm-dependencies = pkgs.buildNpmPackage rec {
            name = "text-rdt-npm-dependencies";
            srcs = lib.fileset.toSource {
              root = ./text-rdt;
              fileset = lib.fileset.union
                ./text-rdt/package.json
                ./text-rdt/package-lock.json;
            };
            dontNpmBuild = true;
            installPhase = ''
              cp -r node_modules $out
            '';
            npmDepsHash = "sha256-ExzlppLRRieu3wmgHf07SE5+eTMjZf2aLTCdoAy3vDA=";
          };

          packages.text-rdt-sbt-launcher-fod = pkgs.stdenv.mkDerivation {
            name = "text-rdt-sbt-launcher-fod";
            srcs = text-rdt-sbt-launcher-source;
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = "sha256-h7mWJ0hUdCMsyELPX8OY+K3M401yoe2wt/uHUFjvuL4=";
            configurePhase = ''
              export SBT_LAUNCHER=$(mktemp -d)
              export SBT_OPTS="-Dsbt.boot.lock=false -Dsbt.boot.directory=$SBT_LAUNCHER"
            '';
            buildPhase = ''
              export ORIGINAL_SOURCE=$(mktemp -d)
              cp -r . $ORIGINAL_SOURCE
              ${pkgs.sbt}/bin/sbt shutdown
            '';
            installPhase = ''
              mkdir $out
              cp -r $ORIGINAL_SOURCE $out/.source
              cp -r $SBT_LAUNCHER $out/launcher
            '';
          };

          packages.text-rdt-sbt-launcher = pkgs.runCommandLocal "text-rdt-sbt-launcher-fod-up-to-date" { } ''
            diff -r ${self.packages.${system}.text-rdt-sbt-launcher-fod}/.source ${text-rdt-sbt-launcher-source} || { echo 'Please update FOD hash for sbt-launcher' ; exit 1; }
            ln -s ${self.packages.${system}.text-rdt-sbt-launcher-fod}/launcher $out
          '';

          packages.text-rdt-sbt-dependencies-fod = pkgs.stdenv.mkDerivation {
            name = "text-rdt-sbt-dependencies-fod";
            srcs = text-rdt-sbt-dependencies-source;
            nativeBuildInputs = [ pkgs.cacert ];
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = "sha256-ECWsjSpf2AkJpW4oedhUUo7/DVriK7hMgIJqGXhJp9I=";
            configurePhase = ''
              export IVY=$(mktemp -d)
              export SBT_OPTS="-Dsbt.boot.lock=false -Dsbt.boot.directory=${self.packages.${system}.text-rdt-sbt-launcher}"
              export COURSIER_CACHE=$(mktemp -d)
            '';
            buildPhase = ''
              export ORIGINAL_SOURCE=$(mktemp -d)
              cp -r . $ORIGINAL_SOURCE
              # this forces the scalablytyped plugin to download dependencies it doesn't download when there are no packages to transform
              mkdir empty
              echo '{ types: "empty.d.ts" }' > empty/package.json
              touch empty/empty.d.ts
              echo '{
                "devDependencies": {
                  "typescript": "^5.4.5"
                },
                "dependencies": {
                  "empty": "./empty"
                }
              }' > package.json
              ${pkgs.nodejs}/bin/npm install # TODO Extract this
              # we need this because the scalajs plugin only downloads its dependencies when calling some task of it
              mkdir -p js/src/main/scala/text_rdt
              echo '
              package text_rdt
              object JSMain {
                @main
                def main(): Unit = {
                }
              }' > js/src/main/scala/text_rdt/JSMain.scala
              ${pkgs.sbt}/bin/sbt "update; fastLinkJS"
            '';
            installPhase = ''
              mkdir $out
              cp -r $ORIGINAL_SOURCE $out/.source
              ${pkgs.coreutils}/bin/cp -r $COURSIER_CACHE $out/dependencies
            '';
          };

          packages.text-rdt-sbt-dependencies = pkgs.runCommandLocal "text-rdt-sbt-dependencies-fod-up-to-date" { } ''
            diff -r ${self.packages.${system}.text-rdt-sbt-dependencies-fod}/.source ${text-rdt-sbt-dependencies-source} || { echo 'Please update FOD hash for sbt-dependencies' ; exit 1; }
            ln -s ${self.packages.${system}.text-rdt-sbt-dependencies-fod}/dependencies $out
          '';

          packages.text-rdt-sbt-scalablytyped = pkgs.stdenv.mkDerivation {
            name = "text-rdt-sbt-scalablytyped";
            srcs = lib.fileset.toSource {
              root = ./text-rdt;
              fileset = lib.fileset.unions
                [
                  ./text-rdt/build.sbt
                  ./text-rdt/project/build.properties
                  ./text-rdt/project/plugins.sbt
                  ./text-rdt/.jvmopts
                  ./text-rdt/package.json
                  ./text-rdt/package-lock.json
                ];
            };
            configurePhase = ''
              export IVY=$(mktemp -d)
              export SBT_OPTS="-Dsbt.ivy.home=$IVY -Dsbt.boot.lock=false -Dsbt.boot.directory=${self.packages.${system}.text-rdt-sbt-launcher}"
              export COURSIER_CACHE=${self.packages.${system}.text-rdt-sbt-dependencies}
              ln -s ${self.packages.${system}.text-rdt-npm-dependencies} node_modules
            '';
            buildPhase = ''
              ${pkgs.sbt}/bin/sbt update
            '';
            installPhase = ''
              mkdir $out
              ${pkgs.coreutils}/bin/cp -r $IVY/ $out/ivy
              ${pkgs.coreutils}/bin/cp -r /build/.cache/scalablytyped/ $out/scalablytyped
            '';
          };

          packages.text-rdt-sbt = pkgs.stdenv.mkDerivation {
            name = "text-rdt-sbt";
            src = ./text-rdt;
            configurePhase = ''
              mkdir /build/.cache
              ln -s ${self.packages.${system}.text-rdt-sbt-scalablytyped}/scalablytyped /build/.cache/
              export SBT_OPTS="-Dsbt.ivy.home=${self.packages.${system}.text-rdt-sbt-scalablytyped}/ivy -Dsbt.boot.lock=false -Dsbt.boot.directory=${self.packages.${system}.text-rdt-sbt-launcher}"
              export COURSIER_CACHE=${self.packages.${system}.text-rdt-sbt-dependencies}
              ln -s ${self.packages.${system}.text-rdt-npm-dependencies} node_modules
            '';
            buildPhase = ''
              ${pkgs.sbt}/bin/sbt compile
            '';
            installPhase = ''
              touch $out
            '';
          };

          packages.text-rdt-frontend = pkgs.stdenv.mkDerivation {
            name = "text-rdt-frontend";
            src = ./text-rdt;
            nativeBuildInputs = [pkgs.sbt];
            configurePhase = ''
              mkdir /build/.cache
              ln -s ${self.packages.${system}.text-rdt-sbt-scalablytyped}/scalablytyped /build/.cache/
              export SBT_OPTS="-Dsbt.ivy.home=${self.packages.${system}.text-rdt-sbt-scalablytyped}/ivy -Dsbt.boot.lock=false -Dsbt.boot.directory=${self.packages.${system}.text-rdt-sbt-launcher}"
              export COURSIER_CACHE=${self.packages.${system}.text-rdt-sbt-dependencies}
              cp -r ${self.packages.${system}.text-rdt-npm-dependencies} node_modules
            '';
            buildPhase = ''
              ${pkgs.nodejs}/bin/npm run build -- --base=./
            '';
            installPhase = ''
              cp -r dist $out
            '';
          };
        }
      );
}
