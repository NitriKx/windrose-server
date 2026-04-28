# windrose Helm chart

Deploys the [Windrose](https://store.steampowered.com/app/3041230/Windrose/) dedicated server on Kubernetes using the `ghcr.io/nitrikx/windrose-server` Docker image.

---

## Installing

```sh
helm install windrose-server oci://ghcr.io/nitrikx/charts/windrose-server \
  --namespace game-servers --create-namespace \
  --set server.name="My Windrose Server" \
  --set service.loadBalancerIP=192.168.1.100
```

Or with a values file:

```sh
helm install windrose-server oci://ghcr.io/nitrikx/charts/windrose-server \
  --namespace game-servers --create-namespace \
  -f my-values.yaml
```

---

## Values reference

### `image`

| Key | Default | Description |
|---|---|---|
| `image.repository` | `ghcr.io/nitrikx/windrose-server` | Docker image repository. |
| `image.tag` | `latest` | Image tag. Pin to a specific version in production. |
| `image.pullPolicy` | `Always` | Image pull policy. |

### `steam`

| Key | Default | Description |
|---|---|---|
| `steam.updateOnBoot` | `true` | Run `steamcmd app_update` on every pod start. |
| `steam.username` | `""` | Steam username. Leave empty for anonymous login. |
| `steam.password` | `""` | Steam password. |
| `steam.appId` | `4129620` | Steam app ID for the dedicated server tool. |
| `steam.platform` | `windows` | SteamCMD platform override. |
| `steam.validate` | `false` | Validate all file checksums via SteamCMD. |

### `server`

| Key | Default | Description |
|---|---|---|
| `server.name` | `"Windrose Server"` | Server display name shown to players. |
| `server.inviteCode` | `""` | Invite code (min 6 chars, alphanumeric). Auto-generated on first boot if empty. |
| `server.isPasswordProtected` | `false` | Enable password protection. |
| `server.password` | `""` | Server password — only used when `isPasswordProtected` is `true`. |
| `server.maxPlayerCount` | `4` | Maximum concurrent players (4, 6, 8, or 10). |
| `server.region` | `"EU"` | Server browser region — `EU`, `SEA`, or `CIS`. EU covers both EU and NA. Leave empty for automatic selection. |
| `server.note` | `""` | Optional description written to `ServerDescription.json`. |
| `server.directConnectionPort` | `7777` | Game port (UDP + TCP) for direct IP connections. |
| `server.queryPort` | `7778` | Steam server browser query port (UDP). |
| `server.p2pProxyAddress` | `""` | Override the auto-detected IP for NAT punch-through. Leave empty to auto-detect from the pod's network interface. |
| `server.extraArgs` | `"-log"` | Extra arguments passed to the server binary. `-log` enables console output. |

### `world`

World settings are written to `WorldDescription.json` on every pod start — the chart values are always the source of truth.

| Key | Default | Description |
|---|---|---|
| `world.name` | `""` | World display name. Defaults to `server.name` if empty. |
| `world.preset` | `"Medium"` | Difficulty preset — `Easy`, `Medium`, `Hard`, or `Custom`. Use `Custom` to apply the individual multipliers below. |

#### Difficulty multipliers (effective when `world.preset: Custom`)

| Key | Default | Range | Description |
|---|---|---|---|
| `world.mobHealthMultiplier` | `1.0` | 0.2 – 5.0 | Enemy health scaling. |
| `world.mobDamageMultiplier` | `1.0` | 0.2 – 5.0 | Enemy damage scaling. |
| `world.shipHealthMultiplier` | `1.0` | 0.4 – 5.0 | Enemy ship durability. |
| `world.shipDamageMultiplier` | `1.0` | 0.2 – 2.5 | Enemy ship weapon output. |
| `world.boardingDifficultyMultiplier` | `1.0` | 0.2 – 5.0 | Boarding encounter difficulty. |
| `world.coopStatsCorrectionModifier` | `1.0` | 0.0 – 2.0 | Scales enemy HP/posture by player count in co-op. |
| `world.coopShipStatsCorrectionModifier` | `0.0` | 0.0 – 2.0 | Scales enemy ship stats by player count in co-op. |

#### Toggles

| Key | Default | Description |
|---|---|---|
| `world.easyExplore` | `false` | Disable map markers for immersive exploration. |
| `world.coopSharedQuests` | `true` | Quest completions apply to all active players automatically. |
| `world.combatDifficulty` | `"Normal"` | Boss aggression — `Easy`, `Normal`, or `Hard`. |

### `service`

| Key | Default | Description |
|---|---|---|
| `service.type` | `LoadBalancer` | Kubernetes service type. |
| `service.loadBalancerIP` | `""` | Fixed IP for the LoadBalancer. Required for direct connection mode. |
| `service.annotations` | `{}` | Annotations — use for external-dns, MetalLB, cloud LB configuration, etc. |

### `persistence`

Game files and runtime data are stored on two separate PVCs — keeping save data isolated from the large (re-downloadable) Steam install.

| Key | Default | Description |
|---|---|---|
| `persistence.source.size` | `40Gi` | PVC size for game files downloaded by SteamCMD. |
| `persistence.source.storageClass` | `""` | Storage class for the source PVC. NFS/HDD recommended — fast I/O not required. |
| `persistence.source.accessMode` | `ReadWriteOnce` | PVC access mode. |
| `persistence.source.annotations` | `{}` | Annotations on the source PVC — e.g. `k8up.io/backup: "false"`. |
| `persistence.runtime.size` | `40Gi` | PVC size for the runtime copy and world saves. |
| `persistence.runtime.storageClass` | `""` | Storage class for the runtime PVC. Local-path recommended for better I/O. |
| `persistence.runtime.accessMode` | `ReadWriteOnce` | PVC access mode. |
| `persistence.runtime.annotations` | `{}` | Annotations on the runtime PVC — e.g. `k8up.io/backup: "true"`. |

### Other

| Key | Default | Description |
|---|---|---|
| `extraEnv` | `[]` | Additional environment variables injected into the server container. Useful for one-off overrides not covered by the values above. |
| `resources` | see below | Pod resource requests and limits. |
| `nodeSelector` | `{kubernetes.io/os: linux}` | Node selector. |
| `tolerations` | `[]` | Pod tolerations. |
| `affinity` | `{}` | Pod affinity rules. |

Default resources:

```yaml
resources:
  requests:
    cpu: "2"
    memory: 8Gi
  limits:
    memory: 12Gi
```

---

## Networking

The chart exposes three service ports:

| Port | Protocol | Description |
|---|---|---|
| `server.directConnectionPort` (7777) | UDP + TCP | Game traffic |
| `server.queryPort` (7778) | UDP | Steam server browser query port |

Open both on your router/firewall if players connect via direct IP.

---

## Security

The pod runs as **`wineuser` (UID/GID 1000)** with `runAsNonRoot: true`. The pod-level `fsGroup: 1000` ensures PVC and emptyDir mounts are writable by the server process without requiring root.
