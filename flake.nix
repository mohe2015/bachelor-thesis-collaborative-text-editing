{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ ];
          };
          lib = pkgs.lib;
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
          configureFonts = ''
            export HOME=$(mktemp -d)
            mkdir -p ~/.local/share/fonts
            cp -r "${pkgs.dejavu_fonts}/share/fonts/truetype/." ~/.local/share/fonts
            cp -r "${pkgs.freefont_ttf}/share/fonts/truetype/." ~/.local/share/fonts
            cp -r "${pkgs.gyre-fonts}/share/fonts/truetype/." ~/.local/share/fonts
            cp -r "${pkgs.liberation_ttf}/share/fonts/." ~/.local/share/fonts
            cp -r "${pkgs.unifont}/share/fonts/." ~/.local/share/fonts
            cp -r "${pkgs.noto-fonts.overrideAttrs rec {
              version = "24.9.1";
              src = pkgs.fetchFromGitHub {
                owner = "notofonts";
                repo = "notofonts.github.io";
                rev = "noto-monthly-release-${version}";
                hash = "sha256-QFRyHTJVz6MzayFvyTjDhc7eTAS4KXY3pqmx48VKNqY=";
              };
               installPhase = ''
              # We check availability in order of variable -> otf -> ttf
              # unhinted -- the hinted versions use autohint
              # maintaining maximum coverage.
              #
              # We have a mix of otf and ttf fonts
              local out_font=$out/share/fonts/noto
            '' + (''
              for folder in $(ls -d fonts/*/); do
                if [[ -d "$folder"unhinted/otf ]]; then
                  install -m444 -Dt $out_font "$folder"unhinted/otf/*.otf
                elif [[ -d "$folder"unhinted/variable ]]; then
                  install -m444 -Dt $out_font "$folder"unhinted/variable/*
                elif [[ -d "$folder"unhinted/variable-ttf ]]; then
                  install -m444 -Dt $out_font "$folder"unhinted/variable-ttf/*.ttf
                else
                  install -m444 -Dt $out_font "$folder"unhinted/ttf/*.ttf
                fi
              done
            '') + ''
              ${pkgs.rename}/bin/rename 's/\[.*\]//' $out/share/fonts/noto/*
            '';
            
            }}/share/fonts/noto/." ~/.local/share/fonts
            ${pkgs.tree}/bin/tree ~/.local/share/fonts | grep NotoSansMono
            ls -lh ~/.local/share/fonts/ | grep NotoSansMono # cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e
            #${pkgs.fontconfig}/bin/fc-list
          '';
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = [ pkgs.bashInteractive pkgs.sbt pkgs.openjdk21 pkgs.nodejs pkgs.vscodium pkgs.openssl ];

            nativeBuildInputs = [ pkgs.pkg-config ];

            JAVA_HOME = pkgs.openjdk21;
          };

          # TOOD IMplement sbt honoring the cores parameter

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
            npmDepsHash = "sha256-+3gXE+zHx8EbcZiEdUvD9uUz6bdgiKy3ptHnWXRkdcc=";
          };

          packages.empty-dependencies = pkgs.buildNpmPackage rec {
            name = "empty-npm-package";
            srcs = ./.nix/fake-project;
            dontNpmBuild = true;
            installPhase = ''
              cp -r node_modules $out
            '';
            npmDepsHash = "sha256-5uTYs6Qm5zRWE51MCtR5PQQXeoXPiBxeamL5XxkLZ1w=";
          };

          packages.text-rdt-sbt-launcher-fod = pkgs.stdenv.mkDerivation {
            name = "text-rdt-sbt-launcher-fod-${text-rdt-sbt-launcher-source}";
            srcs = text-rdt-sbt-launcher-source;
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = "sha256-JkZIyl4h+ZoTGoAu4KiM2jB9We6mHZaMYk+0qJEskzo=";
            configurePhase = ''
              export SBT_LAUNCHER=$(mktemp -d)
              export SBT_OPTS="-Dsbt.boot.lock=false -Dsbt.boot.directory=$SBT_LAUNCHER"
            '';
            buildPhase = ''
              ${pkgs.sbt}/bin/sbt shutdown
            '';
            installPhase = ''
              cp -r $SBT_LAUNCHER $out/
            '';
          };

          packages.text-rdt-sbt-dependencies-fod =
            pkgs.stdenv.mkDerivation {
              name = "text-rdt-sbt-dependencies-fod-${text-rdt-sbt-dependencies-source}";
              srcs = text-rdt-sbt-dependencies-source;
              nativeBuildInputs = [ pkgs.cacert ];
              outputHashMode = "recursive";
              outputHashAlgo = "sha256";
              outputHash = "sha256-9SCW8dlfO0QJ1tew7C8Mr+sTsQ0e9VQOeb3/Xgb/DQY=";
              configurePhase = ''
                export HOME=$(mktemp -d)
                export IVY=$(mktemp -d)
                export COURSIER_CACHE=$(mktemp -d)
                export SBT_OPTS="$SBT_OPTS -Dsbt.boot.lock=false -Dsbt.boot.directory=${self.packages.${system}.text-rdt-sbt-launcher-fod}"
              '';
              buildPhase = ''
                cp -r ${self.packages.${system}.empty-dependencies} node_modules
                cp -r ${./.nix/fake-project}/* .
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
                ${pkgs.coreutils}/bin/cp -r $COURSIER_CACHE $out
              '';
            };

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
              export SBT_OPTS="-Dsbt.ivy.home=$IVY -Dsbt.boot.lock=false -Dsbt.boot.directory=${self.packages.${system}.text-rdt-sbt-launcher-fod}"
              export COURSIER_CACHE=${self.packages.${system}.text-rdt-sbt-dependencies-fod}
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

          packages.async-profiler-converter = pkgs.fetchurl {
            url = "https://github.com/async-profiler/async-profiler/releases/download/v3.0/converter.jar";
            hash = "sha256-5kZTMaZgnfGFLA6Dufw3/eUTmlfBhm/HgRpeXEJ7Y2s=";
          };

          packages.figures = pkgs.stdenv.mkDerivation {
            name = "text-rdt-sbt";
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions
                [
                  ./text-rdt
                  ./latex/figures/gnuplot.txt
                ];
            };
            buildPhase = ''
              ${configureFonts}

              ls -d text-rdt/jvm/figure-benchmark-results/*/ | xargs -I {} bash -c "cd {} && ${pkgs.openjdk}/bin/java -jar ${self.packages.${system}.async-profiler-converter} jfr2flame jfr-cpu.jfr cpu.html"
              ls -d text-rdt/jvm/figure-benchmark-results/*/ | xargs -I {} bash -c "cd {} && ${pkgs.openjdk}/bin/java -jar ${self.packages.${system}.async-profiler-converter} jfr2flame --alloc --simple jfr-cpu.jfr alloc.html"
              export XDG_CACHE_HOME="$(mktemp -d)"
              ${pkgs.gnuplot}/bin/gnuplot latex/figures/gnuplot.txt # todo split into separate derivation # liberation sans
            '';
            installPhase = ''
              cp -r text-rdt/jvm/figure-benchmark-results $out
            '';
          };

          packages.latex = pkgs.stdenv.mkDerivation {
            name = "Bachelor_Thesis_Moritz_Hedtke_Optimizing_Collaborative_Plain_Text_Editing_Algorithms.pdf";
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions
                [
                  ./latex
                ];
            };
            # https://www.google.com/search?q=site%3Amiktex.org+%22caption.sty%22
            # texliveInfraOnly
            nativeBuildInputs = [ pkgs.git (pkgs.texliveBasic.withPackages (ps: with ps; [ latexmk luatex pdfmanagement-testphase tagpdf etoolbox l3experimental tuda-ci urcls koma-script xcolor anyfontsize fontspec xcharter roboto xkeyval adjustbox pgf babel-german microtype unicode-math lualatex-math glossaries-extra glossaries fancyvrb minted upquote caption csquotes biblatex cleveref biber ])) pkgs.python3Packages.pygments ];
            configurePhase = ''
              mkdir -p text-rdt/target
              cp -r ${self.packages.${system}.text-rdt-sbt-tests-thesis} text-rdt/target/pdfs
              mkdir -p text-rdt/jvm
              cp -r ${self.packages.${system}.figures} text-rdt/jvm/figure-benchmark-results
              export HOME=$(mktemp -d)
            '';
            buildPhase = ''
              cd latex
              make
              cd ..
            '';
            installPhase = ''
              cp latex/thesis.pdf $out
            '';
          };

          packages.verapdf = pkgs.maven.buildMavenPackage rec {
            pname = "verapdf";
            version = "1.26.2";

            mvnParameters = "-pl '!installer' -Dverapdf.timestamp=1980-01-01T00:00:02Z -Dproject.build.outputTimestamp=1980-01-01T00:00:02Z";

            src = pkgs.fetchFromGitHub {
              owner = "veraPDF";
              repo = "veraPDF-apps";
              rev = "v1.26.2";
              hash = "sha256-bWj4dX1qRQ2zzfF9GfskvMnrNU9pKC738Zllx6JsFww=";
            };

            mvnHash = "sha256-bqPmEQfTIoZePk5oRi2nFnXbJ7RpSl99FIuHj+P8MxE=";

            nativeBuildInputs = [ pkgs.makeWrapper pkgs.stripJavaArchivesHook ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin $out/share
              install -Dm644 greenfield-apps/target/greenfield-apps-1.26.0.jar $out/share/verapdf.jar
              makeWrapper ${pkgs.jre}/bin/java $out/bin/verapdf-gui --add-flags "-jar $out/share/verapdf.jar"
              makeWrapper ${pkgs.jre}/bin/java $out/bin/verapdf --add-flags "-cp $out/share/verapdf.jar org.verapdf.apps.GreenfieldCliWrapper"

              runHook postInstall
            '';

            meta = {
              description = "Command line and GUI industry supported PDF/A and PDF/UA Validation";
              homepage = "https://github.com/veraPDF/veraPDF-apps";
              license = [ lib.licenses.gpl3Plus /* or */ lib.licenses.mpl20 ];
              maintainers = [ lib.maintainers.mohe2015 ];
            };
          };

          packages.latex-info = (pkgs.runCommand "my-example" { } ''
            ${pkgs.poppler_utils}/bin/pdfinfo ${self.packages.${system}.latex}
            echo -------------------------------------------------------------
            ${pkgs.exiftool}/bin/exiftool ${self.packages.${system}.latex}
            echo -------------------------------------------------------------
            ${self.packages.${system}.verapdf}/bin/verapdf --flavour 3a --format text ${self.packages.${system}.latex}
            echo -------------------------------------------------------------
            ${pkgs.poppler_utils}/bin/pdffonts ${self.packages.${system}.latex} # TODO check no "Type 3"
            cp ${self.packages.${system}.latex} $out
          '');

          packages.text-rdt-sbt-tests-all = self.packages.${system}.text-rdt-sbt-tests-of "test";

          packages.text-rdt-sbt-tests-thesis = self.packages.${system}.text-rdt-sbt-tests-of "testOnly text_rdt.ThesisTestSuite";

          packages.text-rdt-sbt-tests-of = target: pkgs.stdenv.mkDerivation {
            name = "text-rdt-sbt-tests";
            src = ./text-rdt;
            nativeBuildInputs = [ pkgs.sbt ];
            configurePhase = ''
              ${configureFonts}

              mkdir /build/.cache
              ln -s ${self.packages.${system}.text-rdt-sbt-scalablytyped}/scalablytyped /build/.cache/
              export SBT_OPTS="-Dsbt.ivy.home=${self.packages.${system}.text-rdt-sbt-scalablytyped}/ivy -Dsbt.boot.lock=false -Dsbt.boot.directory=${self.packages.${system}.text-rdt-sbt-launcher-fod}"
              export COURSIER_CACHE=${self.packages.${system}.text-rdt-sbt-dependencies-fod}
              cp -r ${self.packages.${system}.text-rdt-npm-dependencies} node_modules
              cp -r ${self.packages.${system}.figures}/. jvm/figure-benchmark-results/
            '';

            PLAYWRIGHT_NODEJS_PATH = "${pkgs.nodejs}/bin/node";
            PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = true;
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = true;
            PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";

            buildPhase = ''
              ${pkgs.nodejs}/bin/npm run build -- --base=./ # TODO split this up
              ${pkgs.nodejs}/bin/npm run preview &
              ${pkgs.sbt}/bin/sbt "textrdtJVM/${target}"
            '';
            installPhase = ''
              cp -r target/pdfs/. $out
              ${pkgs.poppler_utils}/bin/pdffonts $out/empty.pdf
            '';
          };

          # GOAL 1: Build web application
          packages.text-rdt-frontend = pkgs.stdenv.mkDerivation {
            name = "text-rdt-frontend";
            src = ./text-rdt;
            nativeBuildInputs = [ pkgs.sbt ];
            configurePhase = ''
              mkdir /build/.cache
              ln -s ${self.packages.${system}.text-rdt-sbt-scalablytyped}/scalablytyped /build/.cache/
              export SBT_OPTS="-Dsbt.ivy.home=${self.packages.${system}.text-rdt-sbt-scalablytyped}/ivy -Dsbt.boot.lock=false -Dsbt.boot.directory=${self.packages.${system}.text-rdt-sbt-launcher-fod}"
              export COURSIER_CACHE=${self.packages.${system}.text-rdt-sbt-dependencies-fod}
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
