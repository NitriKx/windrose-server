#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${RUNTIME_DIR:-/srv/windrose/runtime}"
CONFIG_DIR="${CONFIG_DIR:-/srv/windrose/config}"
LOG_DIR="${LOG_DIR:-/srv/windrose/logs}"
STEAM_STATE_DIR="${STEAM_STATE_DIR:-/srv/windrose/steamcmd}"
SOURCE_EXECUTABLE="${WINDROSE_SOURCE_EXECUTABLE:-WindroseServer.exe}"
EXECUTABLE="${WINDROSE_EXECUTABLE:-R5/Binaries/Win64/WindroseServer-Win64-Shipping.exe}"
WINE_COMMAND="${WINDROSE_WINE_COMMAND:-wine}"
SERVER_ARGS="${WINDROSE_SERVER_ARGS:--log}"

mkdir -p "$RUNTIME_DIR" "$CONFIG_DIR" "$LOG_DIR" "$STEAM_STATE_DIR"

/usr/local/bin/update-source.sh

if [[ ! -f "$RUNTIME_DIR/$SOURCE_EXECUTABLE" ]]; then
  cat <<EOF
Windrose dedicated-server files were not found.

Expected:
  $RUNTIME_DIR/$SOURCE_EXECUTABLE

SteamCMD may not have run yet or failed. Enable STEAM_UPDATE_ON_BOOT and
restart the container.
EOF
  exit 1
fi

if [[ ! -f "$RUNTIME_DIR/$EXECUTABLE" ]]; then
  cat <<EOF
Windrose dedicated-server binary was not found.

Expected:
  $RUNTIME_DIR/$EXECUTABLE

The runtime directory appears incomplete. Re-run with STEAM_UPDATE_ON_BOOT=true
to re-download the game files.
EOF
  exit 1
fi

if [[ ! -d "$WINEPREFIX" ]]; then
  mkdir -p "$WINEPREFIX"
fi

cd "$RUNTIME_DIR"
export WINEPREFIX WINEARCH DISPLAY WINE_COMMAND EXECUTABLE SERVER_ARGS
exec xvfb-run -a bash -lc '
  set -euo pipefail
  wineboot -u >/dev/null 2>&1 || true
  python3 /usr/local/bin/apply_managed_config.py

  # shellcheck disable=SC2086
  "$WINE_COMMAND" "$EXECUTABLE" $SERVER_ARGS &
  server_pid=$!
  trap "kill $server_pid 2>/dev/null || true" INT TERM

  for _ in $(seq 1 60); do
    if [[ -f /srv/windrose/runtime/R5/ServerDescription.json ]]; then
      python3 /usr/local/bin/apply_managed_config.py || true
      break
    fi
    if ! kill -0 "$server_pid" 2>/dev/null; then
      break
    fi
    sleep 2
  done

  wait "$server_pid"
'
