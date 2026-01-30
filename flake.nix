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
        pkgs = nixpkgs.legacyPackages."${system}";
      in
      {
        packages = {
          default = self.packages.${system}.dmm-games-player;
          inherit (pkgs.callPackage ./pkgs/dmm-games-player { }) dmm-games-player;
        };
      }
    );
}
