{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem =
        {
          inputs',
          self',
          pkgs,
          ...
        }:
        {
          packages = {
            default = self'.packages.tsvfmt;
            tsvfmt = pkgs.stdenv.mkDerivation (finalAttrs: {
              pname = "tsvfmt";
              version = "1.0.0";

              src = ./.;

              nativeBuildInputs = [ pkgs.zig ];

              zigBuildFlags = [ "-Doptimize=ReleaseSafe" ];

              buildPhase = ''
                runHook preBuild

                # Set up Zig cache directory
                export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
                export ZIG_LOCAL_CACHE_DIR=$TMPDIR/zig-local-cache

                # Build the project
                zig build ${toString finalAttrs.zigBuildFlags}

                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall

                mkdir -p $out/bin
                cp zig-out/bin/tsvfmt $out/bin/

                runHook postInstall
              '';
            });
          };

          apps = {
            default = self'.apps.tsvfmt;
            tsvfmt = {
              type = "app";
              program = "${self'.packages.tsvfmt}/bin/tsvfmt";
            };
          };

          devShells.default = pkgs.mkShell {
            name = "tsvfmt";
            packages =
              [ pkgs.zig ]
              # Pre-commit
              ++ [
                # keep-sorted start
                pkgs.actionlint
                pkgs.deadnix
                pkgs.fd
                pkgs.just
                pkgs.keep-sorted
                pkgs.markdownlint-cli2
                pkgs.nixfmt-rfc-style
                pkgs.nodePackages.prettier
                pkgs.pre-commit
                pkgs.python312Packages.pre-commit-hooks
                pkgs.ratchet
                pkgs.zizmor
                # keep-sorted end
              ];
            shellHook = "pre-commit install --overwrite";
          };
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
