# nix-dmm-games-player

DMM Game Player (Windows app) packaged as a Nix flake and run via Wine.

This flake intentionally **runs the upstream installer at first launch** (inside the Wine prefix) and then launches the installed `DMMGamePlayer.exe`.

## Build

This package is `unfree`, so allow it via `NIXPKGS_ALLOW_UNFREE=1` and use `--impure`.

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#dmm-games-player -L
```

## Run

```bash
NIXPKGS_ALLOW_UNFREE=1 nix run --impure .#dmm-games-player -L
```

By default, the Wine prefix is:

- `~/.nix-wine/dmm-games-player-5.4.3`

Override it (recommended if managing multiple prefixes):

```bash
WINEPREFIX="$HOME/.wine-dmm" NIXPKGS_ALLOW_UNFREE=1 nix run --impure .#dmm-games-player -L
```

## CLI options

The flake exposes a single command: `dmm-games-player`.

- `dmm-games-player`
  - Ensures the prefix exists, runs the installer if needed, then launches the installed app.
- `dmm-games-player boot|build|rebuild`
  - Initializes the Wine prefix (`wineboot`, sets Windows version), but does not start the app.
- `dmm-games-player eval <cmd...>`
  - Runs `<cmd...>` directly (not via Wine). Note: the script currently still performs the install check before `eval`.
- `dmm-games-player <URI>`
  - If the first argument looks like a `dmmgameplayer:` URI, it forwards it via `wine start "<URI>"`.

## Native browser login (URI handler)

The package installs a desktop entry that declares:

- `MimeType=x-scheme-handler/dmmgameplayer;`

and executes:

- `dmm-games-player %u`

This is the Nix equivalent of the usual non-Nix guide that registers a `.desktop` file and a wrapper script.

### How to use

1. Ensure the `.desktop` entry is visible to your session.

For ad-hoc usage:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#dmm-games-player
```

For persistent install into your user profile:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure .#dmm-games-player
```

2. Set it as the default handler for the scheme (optional, depends on desktop environment):

```bash
xdg-mime default dmm-games-player.desktop x-scheme-handler/dmmgameplayer
```

3. From a native Linux browser, click a `dmmgameplayer:` link.

- The desktop environment should launch `dmm-games-player %u`.
- The script will install DMM Game Player into the Wine prefix if needed.
- The URI is forwarded into the Windows side via `wine start`, allowing the login flow.

## Notes

- Wine package used: `wineWow64Packages.waylandFull`.
- Installer used: archived `DMMGamePlayer-Setup-5.4.3.exe`.
- The previous build-time extraction approach (unpacking `app-64.7z`) is commented out in `pkgs/dmm-games-player/default.nix`.
