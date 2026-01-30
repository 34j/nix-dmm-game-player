{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:

    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
          config.allowUnfreePredicate = pkg: true;
        };
      in
      {
        packages = {
          default = self.packages.${system}.dmm-game-player;
          inherit (pkgs.callPackage ./pkgs/dmm-game-player { }) dmm-game-player;
        };
      }
    );
}
