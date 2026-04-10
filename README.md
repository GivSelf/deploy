# GivSelf Deploy

Docker Compose deployment for the GivSelf home energy management system.

## Quick Start

```bash
git clone https://github.com/GivSelf/deploy.git
cd deploy
```

Create a `docker-compose.yml`:

```yaml
services:
  timescaledb:
    image: timescale/timescaledb:latest-pg16
    restart: unless-stopped
    environment:
      POSTGRES_DB: givself
      POSTGRES_USER: givself
      POSTGRES_PASSWORD: changeme    # ← change this
    volumes:
      - db_data:/home/postgres/pgdata/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U givself"]
      interval: 10s
      timeout: 5s
      retries: 5

  server:
    image: ghcr.io/givself/server:latest
    restart: unless-stopped
    depends_on:
      timescaledb:
        condition: service_healthy
    ports:
      - "3032:3032"
    environment:
      PORT: "3032"
      DATABASE_URL: postgres://givself:changeme@timescaledb:5432/givself
      ADAPTER_TYPE: givenergy
      INVERTER_HOST: "192.168.1.100"  # ← your inverter IP

  web:
    image: ghcr.io/givself/web:latest
    restart: unless-stopped
    ports:
      - "3033:3000"
    environment:
      HOSTNAME: "0.0.0.0"
      API_URL: "http://server:3032"
      WS_URL: "ws://YOUR_SERVER_IP:3032"  # ← your server's LAN IP

volumes:
  db_data:
```

Then:

```bash
docker compose pull
docker compose up -d
```

Open `http://your-server-ip:3033` and follow the setup wizard.

## What You Need to Configure

Only **3 things** need to be set in the compose file:

| Setting | Where | Example |
|---------|-------|---------|
| Database password | `POSTGRES_PASSWORD` + `DATABASE_URL` | `changeme` → your password |
| Inverter IP | `INVERTER_HOST` | Your GivEnergy dongle's IP on the LAN |
| Server LAN IP | `WS_URL` | Your Docker host's IP (for WebSocket) |

**Everything else** is configured through the web UI after first launch:

- Dongle serial number
- GivEnergy Cloud API key + inverter serial
- Solcast API key + site ID
- Solar panel geometry (auto-detected from Solcast)

All UI settings persist to the database and survive container restarts.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Web (:3033) │────▶│ Server(:3032)│────▶│ TimescaleDB  │
│  Next.js     │     │ Fastify      │     │ PostgreSQL   │
└─────────────┘     └──────┬───────┘     └──────────────┘
                           │
                    ┌──────▼───────┐
                    │ GivEnergy    │
                    │ Inverter     │
                    │ (Modbus TCP) │
                    └──────────────┘
```

- **Web** proxies `/api/*` to Server internally. Only port 3033 needs to be exposed to users.
- **Server** port 3032 must be exposed for WebSocket connections from browsers.
- **TimescaleDB** is internal only — no external port needed.

## Unraid

See `docker-compose.unraid.yml` and `.env.unraid` for Unraid-specific configuration with appdata paths.

## Development

For local development, use the dev compose which only starts TimescaleDB:

```bash
docker compose -f docker-compose.dev.yml up -d
# TimescaleDB available at localhost:5433
```

Then run the server and web app from source — see their respective repos.

## License

MIT
