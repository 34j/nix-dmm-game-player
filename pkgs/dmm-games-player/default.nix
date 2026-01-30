{
  lib,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  writeShellApplication,
  wineWow64Packages,
  winetricks,
}:

let
  pname = "dmm-games-player";
  version = "5.4.3";

  src = fetchurl {
    url = "https://web.archive.org/web/20250501072014/https://dlapp-dmmgameplayer.games.dmm.com/DMMGamePlayer-Setup-5.4.3.exe";
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
      wineWow64Packages.waylandFull
      winetricks
    ];

    runtimeEnv = {
      WINEARCH = "win64";
    };

    text = ''
      			set -euo pipefail

      			# Usage:
      			# - dmm-games-player            : ensure installed, then launch the EXE
      			# - dmm-games-player %u         : (desktop handler) pass URI to Wine (login flow)
      			# - dmm-games-player build      : initialize prefix only

      			# Where the Wine prefix (Windows-like filesystem + registry) lives.
      			# Users can override this by exporting WINEPREFIX before running.
      			export WINEPREFIX="${"$"}{WINEPREFIX:-$HOME/.nix-wine/${pname}-${version}}"

      			# Store small state (like the discovered installed exe path) inside the prefix.
      			state_dir="$WINEPREFIX/.${pname}"
      			exe_path_file="$state_dir/exe-path"

      			# The installer is fetched by Nix and stored in /nix/store; Wine will run it.
      			installer="${src}"

      			for var in WINEPREFIX WINEARCH; do
      				printf '\e[1;35m%s: \e[0m%s\n' "$var" "${"$"}{!var:-""}"
      			done

      			build() {
      				# Initialize the Wine prefix (creates drive_c, registry, etc.)
      				# and set the Windows version that Wine should emulate.
      				mkdir -p "$WINEPREFIX"
      				mkdir -p "$state_dir"
      				wineboot -u
      				winecfg /v win10
      			}

      			install_if_needed() {
      				# If the installed exe path has already been discovered and it still exists,
      				# skip installation.
      				mkdir -p "$state_dir"

      				if [ -f "$exe_path_file" ]; then
      					exe_path="$(cat "$exe_path_file" || true)"
      					if [ -n "$exe_path" ] && [ -f "$exe_path" ]; then
      						return 0
      					fi
      				fi

      				# Run the installer on first launch.
      				# This is NON-silent (GUI) so the user can complete login/steps manually.
              wine "$installer"

      				# After installation, locate the installed DMMGamePlayer.exe inside drive_c.
      				# Record the first match for subsequent launches.
      				exe_path="$(find "$WINEPREFIX/drive_c" -type f -iname 'DMMGamePlayer.exe' 2>/dev/null | head -n 1 || true)"
      				if [ -z "$exe_path" ]; then
      					echo "Installed DMMGamePlayer.exe not found under $WINEPREFIX/drive_c" >&2
      					exit 1
      				fi
      				printf '%s' "$exe_path" > "$exe_path_file"
      			}

      			handle_uri() {
      				# Forward a URI (e.g. dmmgameplayer://...) into the Windows side.
      				# This matches the common non-Nix wrapper approach:
      				#   WINEDEBUG=-all wine start "$uri"
      				# The association for the custom scheme is expected to be registered
      				# by the installer inside this Wine prefix.
      				uri="$1"
      				install_if_needed
      				WINEDEBUG=-all wine start "$uri"
      			}

      			# CLI behavior:
      			# - boot|build|rebuild: initialize prefix only
      			# - eval <cmd...>: run a command (still performs install_if_needed first)
      			# - default: run the installed DMMGamePlayer.exe
      			case "${"$"}{1:-}" in
      				boot|build|rebuild)
      					build
      					;;
      				*)
      					# If the prefix directory doesn't exist at all, create/initialize it.
      					if [ ! -d "$WINEPREFIX" ]; then
      						build
      					fi

      					# If launched as a URI handler from a native Linux browser,
      					# pass the URI into Wine via `wine start`.
      					case "${"$"}{1:-}" in
      						dmmgameplayer:*|dmmgameplayer://*)
      							handle_uri "$1"
      							wineserver -k
      							exit 0
      							;;
      					esac

      					# Ensure the app is installed (runs installer on first launch).
      					install_if_needed

      					case "${"$"}{1:-}" in
      						eval)
      							shift
      							"$@"
      							;;
      						*)
      							# Launch the installed executable.
      							exe_path="$(cat "$exe_path_file")"
      							wine "$exe_path" "$@"
      							;;
      					esac
      					;;
      			esac

      			# Shut down background Wine processes started by this run.
      			wineserver -k
      		'';
  };

  desktopItem = makeDesktopItem {
    name = "dmm-games-player";
    desktopName = "DMM Game Player";
    exec = "dmm-games-player %u";
    type = "Application";
    terminal = false;
    mimeTypes = [ "x-scheme-handler/dmmgameplayer" ];
  };
in
{
  dmm-games-player = symlinkJoin {
    inherit pname version;
    paths = [
      runner
      desktopItem
    ];
    meta = with lib; {
      description = "DMM Game Player (Windows app) wrapped for Wine";
      homepage = "https://games.dmm.com/";
      license = licenses.unfree;
      platforms = platforms.linux;
      mainProgram = pname;
    };
  };
}
