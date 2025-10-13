{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    gleam2nix = {
      url = "git+https://git.isincredibly.gay/srxl/gleam2nix?ref=v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
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
        let
          gleam = pkgs.gleam;
          erlang = pkgs.beamMinimalPackages.erlang;
        in
        {
          packages = {
            default = self'.packages.tsvfmt;
            tsvfmt = inputs.gleam2nix.lib.${pkgs.system}.buildGleamApplication {
              pname = "tsvfmt";
              version = "2.0.0";
              src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;
              gleamNix = import ./gleam.nix;
              gleam = gleam;
              erlang = erlang;
            };
          };

          apps = {
            default = self'.apps.tsvfmt;
            tsvfmt = {
              type = "app";
              program = pkgs.lib.getExe self'.packages.tsvfmt;
            };
          };

          devShells.default = pkgs.mkShell {
            name = "tsvfmt";
            packages = [
              gleam
              pkgs.just
              erlang # We need escript installed to run the tests
            ]
            # Pre-commit
            ++ [
              # keep-sorted start
              inputs'.gleam2nix.packages.gleam2nix
              pkgs.deadnix
              pkgs.keep-sorted
              pkgs.markdownlint-cli2
              pkgs.nixfmt
              pkgs.nodePackages.prettier
              pkgs.omnix
              pkgs.pre-commit
              pkgs.python312Packages.pre-commit-hooks
              pkgs.ratchet
              pkgs.toml-sort
              pkgs.typos
              pkgs.zizmor
              # keep-sorted end
            ];
            shellHook = "pre-commit install --overwrite";
          };
          formatter = pkgs.nixfmt-tree;
        };
    };
}
