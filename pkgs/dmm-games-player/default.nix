{
  lib,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  writeShellApplication,
  wineWowPackages,
  winetricks,
}:

let
  pname = "dmm-game-player";
  version = "5.4.3";

  src = fetchurl {
    url = "https://web.archive.org/web/20250501072014/https://dlapp-dmmgameplayer.game.dmm.com/DMMGamePlayer-Setup-5.4.3.exe";
    sha256 = "3454b8d36073bc63ab2107372978929273a8fbd50a5eb81395ed969749075554";
  };

  /*
    	app = stdenvNoCC.mkDerivation {
    		pname = "${pname}-app";
    		inherit version src;

    		nativeBuildInputs = [ p7zip ];

    		dontUnpack = true;

    		buildCommand = ''
    			set -euo pipefail

    			tmp="$TMPDIR/extract"
    			mkdir -p "$tmp/outer" "$out/opt/${pname}"

    			7z x "$src" -o"$tmp/outer" -y > /dev/null
    			7z x "$tmp/outer/\$PLUGINSDIR/app-64.7z" -o"$out/opt/${pname}" -y > /dev/null

    			if [ ! -f "$out/opt/${pname}/DMMGamePlayer.exe" ]; then
    				echo "DMMGamePlayer.exe not found after extraction" >&2
    				exit 1
    			fi
    		'';
    	};
  */

  runner = writeShellApplication {
    name = pname;

    runtimeInputs = [
      wineWowPackages.waylandFull
      winetricks
    ];

    runtimeEnv = {
      WINEARCH = "win64";
    };

    text = ''
      set -euo pipefail

      # Usage:
      # - dmm-game-player                 : ensure installed, then launch the EXE
      # - dmm-game-player install         : rerun the installer (GUI) and refresh exe path
      # - dmm-game-player uri <URI>       : forward URI to Wine (native-browser login flow)

      # The wine prefix to used, may be overridden by setting $WINEPREFIX environment variable.
      export WINEPREFIX="${"$"}{WINEPREFIX:-$HOME/.nix-wine/${pname}}"

      # The installer is fetched by Nix and stored in /nix/store .
      installer="${src}"

      for var in WINEPREFIX WINEARCH; do
        printf '\e[1;35m%s: \e[0m%s\n' "$var" "${"$"}{!var:-""}"
      done

      build() {
        # Initialize the Wine prefix (creates drive_c, registry, etc.)
        # and set the Windows version that Wine should emulate.
        mkdir -p "$WINEPREFIX"
        wineboot -u
        winecfg /v win10
      }

      run_installer() {
        # Run the installer (GUI).
        # This is used on first launch and by the `install` subcommand.
        wine "$installer"
      }

      install_if_needed() {
        if find "$WINEPREFIX/drive_c" -type f -iname 'DMMGamePlayer.exe' -print -quit 2>/dev/null | grep -q .; then
          printf '\e[1;32m%s\e[0m\n' "DMM Game Player: Already installed"
          return 0
        fi

        printf '\e[1;33m%s\e[0m\n' "DMM Game Player: Not installed, running installer..."
        run_installer
      }

      handle_uri() {
        # Forward a URI (e.g. dmmgameplayer://...) into the Windows side.
        uri="$1"
        install_if_needed
        WINEDEBUG=-all wine start "$uri"
      }

      run_app() {
        printf '\e[1;32m%s\e[0m\n' "DMM Game Player: Launching DMM Game Player"
        exe_path="$(find "$WINEPREFIX/drive_c" -type f -iname 'DMMGamePlayer.exe' 2>/dev/null | head -n 1 || true)"
        if [ -z "$exe_path" ]; then
          echo "Installed DMMGamePlayer.exe not found under $WINEPREFIX/drive_c" >&2
          exit 1
        fi
        wine "$exe_path" "$@"
      }

      case "${"$"}{1:-}" in
        install)
          if [ ! -d "$WINEPREFIX" ]; then
            build
          fi
          run_installer
          ;;

        uri)
          if [ "${"$"}#" -lt 2 ]; then
            echo "Usage: ${pname} uri <URI>" >&2
            exit 2
          fi

          if [ ! -d "$WINEPREFIX" ]; then
            build
          fi

          handle_uri "$2"
          ;;

        *)
          # If the prefix directory doesn't exist at all, create/initialize it.
          if [ ! -d "$WINEPREFIX" ]; then
            build
          fi

          # Ensure the app is installed (runs installer on first launch).
          install_if_needed

          case "${"$"}{1:-}" in
            eval)
              shift
              "$@"
              ;;

            *)
              run_app "$@"
              ;;

          esac
          ;;

      esac

      # Shut down background Wine processes started by this run.
      wineserver -k
    '';
  };

  desktopItem = makeDesktopItem {
    name = "dmm-game-player";
    desktopName = "DMM Game Player";
    exec = "dmm-game-player uri %u";
    type = "Application";
    terminal = false;
    mimeTypes = [ "x-scheme-handler/dmmgameplayer" ];
  };
in
{
  dmm-game-player = symlinkJoin {
    inherit pname version;
    paths = [
      runner
      desktopItem
    ];
    meta = with lib; {
      description = "DMM Game Player (Windows app) wrapped for Wine";
      homepage = "https://game.dmm.com/";
      license = licenses.unfree;
      platforms = platforms.linux;
      mainProgram = pname;
    };
  };
}
