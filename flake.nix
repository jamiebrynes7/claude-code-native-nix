{
  description =
    "Claude Code - Nix package using official statically compiled binaries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        claude-code = pkgs.callPackage ./package.nix { };
      in {
        packages = {
          default = claude-code;
          claude-code = claude-code;
        };

        apps.default = {
          type = "app";
          program = "${claude-code}/bin/claude";
          meta = {
            description = "Claude Code - AI-powered command line interface";
            homepage = "https://code.claude.com";
            license = "unfree";
            platforms = [
              "x86_64-linux"
              "aarch64-linux"
              "x86_64-darwin"
              "aarch64-darwin"
            ];
          };
        };

        devShells.default =
          pkgs.mkShell { packages = with pkgs; [ nil nixfmt-classic ]; };
      }) // {
        overlays.default = final: prev: {
          claude-code = final.callPackage ./package.nix { };
        };
      };
}
