# windrose-server

Unofficial Docker image for the [Windrose](https://store.steampowered.com/app/3041230/Windrose/) dedicated server.

Runs the Windows server binary via Wine + SteamCMD on Linux.

**Image:** `ghcr.io/nitrikx/windrose-server`

---

## Quick start

```sh
docker run -d \
  --name windrose \
  -p 7777:7777/udp \
  -p 7777:7777/tcp \
  -p 7778:7778/udp \
  -v windrose-source:/srv/windrose/source \
  -v windrose-runtime:/srv/windrose/runtime \
  -e WINDROSE_SERVER_ARGS="-log" \
  ghcr.io/nitrikx/windrose-server:latest
```

> **Note:** The server download is ~35 GB. The `source` volume needs enough free space on the host.

### docker-compose

```yaml
services:
  windrose:
    image: ghcr.io/nitrikx/windrose-server:latest
    restart: unless-stopped
    ports:
      - "7777:7777/udp"
      - "7777:7777/tcp"
      - "7778:7778/udp"
    volumes:
      - source:/srv/windrose/source
      - runtime:/srv/windrose/runtime
    environment:
      STEAM_UPDATE_ON_BOOT: "true"
      WINDROSE_WORLD_PRESET: "Medium"
      WINDROSE_SERVER_ARGS: "-log"

volumes:
  source:
  runtime:
```

---

## Volumes

| Path | Contents | Backup? |
|---|---|---|
| `/srv/windrose/source` | SteamCMD game files (~35 GB) | No — re-downloadable |
| `/srv/windrose/runtime` | Runtime copy + world saves | **Yes** |
| `/srv/windrose/config` | `ServerDescription.json`, `WorldDescription.json` | Optional — managed by env vars |

---

## Environment variables

### Steam / SteamCMD

| Variable | Default | Description |
|---|---|---|
| `STEAM_UPDATE_ON_BOOT` | `false` | Run `steamcmd app_update` on every container start. |
| `STEAM_USERNAME` | `""` | Steam username. Leave empty for anonymous login (sufficient for the dedicated server tool). |
| `STEAM_PASSWORD` | `""` | Steam password. |
| `STEAMCMD_APP_ID` | `4129620` | Steam app ID for the dedicated server. |
| `STEAMCMD_PLATFORM` | `windows` | SteamCMD platform override. |
| `STEAMCMD_VALIDATE` | `false` | Pass `validate` to SteamCMD to verify all file checksums. |

### Server

| Variable | Default | Description |
|---|---|---|
| `WINDROSE_SERVER_NOTE` | `""` | Optional description written to `ServerDescription.json`. |
| `WINDROSE_P2P_PROXY_ADDRESS` | `""` | Override the auto-detected IP for NAT punch-through. Leave empty to auto-detect. |
| `WINDROSE_SERVER_ARGS` | `-log` | Arguments passed to the server binary. `-log` enables console output. |

### World

Applied to `WorldDescription.json` on every container start.

| Variable | Default | Description |
|---|---|---|
| `WINDROSE_WORLD_NAME` | `""` | World display name. Defaults to server name. |
| `WINDROSE_WORLD_PRESET` | `Medium` | Difficulty preset: `Easy`, `Medium`, `Hard`, or `Custom`. |

#### Difficulty multipliers (effective when `WINDROSE_WORLD_PRESET=Custom`)

| Variable | Default | Range | Description |
|---|---|---|---|
| `WINDROSE_MOB_HEALTH_MULTIPLIER` | `1.0` | 0.2 – 5.0 | Enemy health scaling. |
| `WINDROSE_MOB_DAMAGE_MULTIPLIER` | `1.0` | 0.2 – 5.0 | Enemy damage scaling. |
| `WINDROSE_SHIP_HEALTH_MULTIPLIER` | `1.0` | 0.4 – 5.0 | Enemy ship durability. |
| `WINDROSE_SHIP_DAMAGE_MULTIPLIER` | `1.0` | 0.2 – 2.5 | Enemy ship weapon output. |
| `WINDROSE_BOARDING_DIFFICULTY_MULTIPLIER` | `1.0` | 0.2 – 5.0 | Boarding encounter difficulty. |
| `WINDROSE_COOP_STATS_CORRECTION_MODIFIER` | `1.0` | 0.0 – 2.0 | Scales enemy HP/posture by player count. |
| `WINDROSE_COOP_SHIP_STATS_CORRECTION_MODIFIER` | `0.0` | 0.0 – 2.0 | Scales enemy ship stats by player count. |

#### Toggles

| Variable | Default | Description |
|---|---|---|
| `WINDROSE_EASY_EXPLORE` | `false` | Disable map markers for immersive exploration. |
| `WINDROSE_COOP_SHARED_QUESTS` | `true` | Quest completions apply to all active players. |
| `WINDROSE_COMBAT_DIFFICULTY` | `Normal` | Boss aggression: `Easy`, `Normal`, or `Hard`. |

### Advanced paths

Rarely need changing unless you mount volumes at custom locations.

| Variable | Default | Description |
|---|---|---|
| `SOURCE_DIR` | `/srv/windrose/source` | SteamCMD install target. |
| `RUNTIME_DIR` | `/srv/windrose/runtime` | Runtime copy + saves. |
| `CONFIG_DIR` | `/srv/windrose/config` | Config files directory. |
| `STEAM_STATE_DIR` | `/srv/windrose/runtime/steamcmd` | SteamCMD state/login cache. |
| `WINEPREFIX` | `/srv/windrose/runtime/wine` | Wine prefix. |
| `WINDROSE_EXECUTABLE` | `R5/Binaries/Win64/WindroseServer-Win64-Shipping.exe` | Server binary path relative to `SOURCE_DIR`. |
| `WINDROSE_WINE_COMMAND` | `wine` | Wine command used to launch the binary. |

---

## Networking

| Port | Protocol | Description |
|---|---|---|
| `7777` | UDP + TCP | Game traffic (direct connection mode) |
| `7778` | UDP | Steam server browser query port |

---

## User

The container runs as **`wineuser` (UID/GID 1000)**. Ensure mounted volume directories are writable by this user.

---

## Helm chart

For Kubernetes deployments, see the [`chart/`](chart/) directory and its [README](chart/README.md).
