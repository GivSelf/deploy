# GivSelf Deploy

Docker Compose deployment for the GivSelf home energy management system.

Images are pulled from GitHub Container Registry — no building required.

## Quick Start

```bash
git clone https://github.com/GivSelf/deploy.git
cd deploy
cp .env.example .env
```

Edit `.env` with your settings — only 3 values needed:

```env
DB_PASSWORD=your_secure_password
INVERTER_HOST=192.168.1.100      # your inverter's LAN IP
WS_HOST=192.168.1.50             # your Docker host's LAN IP
```

Then:

```bash
docker compose up -d
```

Open `http://your-server:3033` and follow the setup wizard.

## Configuration

### Required (.env)

| Variable | Description |
|----------|-------------|
| `DB_PASSWORD` | Database password (choose anything) |
| `INVERTER_HOST` | Your GivEnergy inverter/dongle IP on the local network |
| `WS_HOST` | Your Docker host's LAN IP (for browser WebSocket connections) |

### Optional (.env)

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_PORT` | `3032` | Server API port (change if 3032 is taken) |
| `WEB_PORT` | `3033` | Web dashboard port (change if 3033 is taken) |
| `DB_NAME` | `givself` | Database name |
| `DB_USER` | `givself` | Database user |
| `ADAPTER_TYPE` | `givenergy` | `givenergy` or `mock` |
| `POLL_INTERVAL_MS` | `10000` | Data collection interval (ms) |

### UI-Configured (no env vars needed)

Everything else is configured through the web UI at `/settings`:

- Dongle serial number
- GivEnergy Cloud API key + inverter serial
- Solcast API key + site ID
- Solar panel geometry (auto-detected from Solcast)

All UI settings persist to the database and survive container restarts.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Web (:3033)     │────▶│  Server (:3032)  │────▶│ TimescaleDB  │
│  ghcr.io/givself │     │  ghcr.io/givself  │     │              │
│  /web:latest     │     │  /server:latest   │     └──────────────┘
└─────────────────┘     └────────┬─────────┘
                                 │
                          ┌──────▼─────────┐
                          │  GivEnergy     │
                          │  Inverter      │
                          │  (Modbus TCP)  │
                          └────────────────┘
```

- **Web** proxies `/api/*` to Server internally via `API_URL`
- **Server** port must be exposed for WebSocket from browsers
- **TimescaleDB** is internal only — no external port needed

## Updating

```bash
docker compose pull
docker compose up -d
```

## Unraid

See `docker-compose.unraid.yml` and `.env.unraid` for Unraid-specific configuration with appdata paths.

## Development

For local development, start only TimescaleDB:

```bash
docker compose -f docker-compose.dev.yml up -d
```

Then run the server and web from source — see their repos.

## License

MIT
