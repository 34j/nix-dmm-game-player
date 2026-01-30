# nix-dmm-game-player

DMM Game Player (Windows app) packaged as a Nix flake and run via Wine.

This flake intentionally **runs the upstream installer at first launch** (inside the Wine prefix) and then launches the installed `DMMGamePlayer.exe`.

## Installation

```bash
NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:34j/nix-dmm-game-player#dmm-game-player
```

or

`flake.nix`:

```nix
{
    inputs = {
        # you should already have something like this
        # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        dmm-game-player.url = "github:34j/nix-dmm-game-player";
        dmm-game-player.inputs.nixpkgs.follows = "nixpkgs";
    };
    # you should already have something like this
    # outputs = {self, nixpkgs, ...}@inputs: {
    #     nixosConfigurations = {
    #         "..." = nixpkgs.lib.nixosSystem{
    #             specialArgs = { inherit inputs; };
    #         };
    #     };
    #     homeConfigurations = {
    #         "...@..." = home-manager.lib.homeManagerConfiguration {
    #             extraSpecialArgs = { inherit inputs; };
    #         };
    #     };
    # };
}

```

`NixOS`:

```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [ inputs.dmm-game-player.packages.${pkgs.stdenv.hostPlatform.system}.dmm-game-player ];
}
```

or `Home Manager`:

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [ inputs.dmm-game-player.packages.${pkgs.stdenv.hostPlatform.system}.dmm-game-player ];
}
```

## Usage

```shell
dmm-game-player
```

This will:

- Creates a Wine prefix in `~/.local/share/dmm-game-player`, which could be overridden by setting the `$WINEPREFIX` environment variable.
- Install DMM Game Player if no `DMMGamePlayer.exe` is found in the Wine prefix.
- Launch the installed `DMMGamePlayer.exe`.
  - You need to log in with your DMM account to use it. The `dmm-game-player` package includes a `desktopItem` to pass login information from your native (Linux) browser to the Wine application.

## Advanced usage

```shell
dmm-game-player --help
```
