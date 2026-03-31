# Minecraft-Server

Docker Compose stack for running a Fabric Minecraft server with routing, file distribution, reverse proxying, and dynamic DNS.

## Stack Overview

This repository includes:

- `server`: Fabric Minecraft server (`itzg/minecraft-server:java25-graalvm`)
- `mc-router`: domain-based Minecraft router (`itzg/mc-router`)
- `miniserve`: simple HTTP file server for `./data`
- `anubis`: bot/challenge proxy in front of Miniserve
- `npm`: Nginx Proxy Manager for reverse proxy and TLS (`80`, `443`, `81`)
- `ddns`: DuckDNS updater container

Persistent game files are stored in `./serverdata`.

## Files

- `docker-compose.yml`: service definitions and runtime configuration
- `botPolicy.yaml`: Anubis ruleset used by the `anubis` container
- `serverdata/`: Minecraft world, configs, and runtime data
- `data/`: files served by Miniserve
- `npm/data/`: Nginx Proxy Manager application data
- `npm/letsencrypt/`: certificates managed by Nginx Proxy Manager

## Prerequisites

- Docker Engine with Compose plugin (`docker compose`)
- Public domain names (for `mc-router` mappings)
- DuckDNS account/token (if using bundled DDNS service)

## Required Configuration Before First Run

Edit placeholders in `docker-compose.yml`:

1. `mc-router` mapping:

```text
MAPPING=<yourdomain.com>=minecraft-server:25565,<yourdomain2.com>=minecraft-server2:25565
```

2. DuckDNS values for `ddns`:

```text
SUBDOMAINS=<DUCKDNS_SUBDOMAIN>
TOKEN=<DUCKDNS_TOKEN>
TZ=Europe/Berlin
```

## Start

```bash
docker compose up -d
docker compose ps
```

Check startup logs:

```bash
docker compose logs --tail=200 server
docker compose logs --tail=200 mc-router
```

## Access

- Minecraft entrypoint: host TCP `25565` (via `mc-router`)
- Nginx Proxy Manager UI: `http://<host>:81`
- Public web/file endpoint: configure in NPM to route to `anubis`

## Common Commands

Start/stop/restart:

```bash
docker compose up -d
docker compose stop
docker compose restart
```

Follow logs:

```bash
docker compose logs -f server
docker compose logs -f mc-router
docker compose logs -f anubis
docker compose logs -f npm
docker compose logs -f ddns
```

Minecraft console attach:

```bash
docker attach minecraft-server
# Detach without stopping: Ctrl+P, Ctrl+Q
```

## Minecraft Service Notes

Configured in compose:

- `TYPE=FABRIC`
- `VERSION=1.21.11`
- `FABRIC_VERSION=0.18.5`
- `MEMORY=10G`

for more information see [Itzg/minecraft](https://docker-minecraft-server.readthedocs.io/en/latest/)

The server mounts `./serverdata:/data`, so all world/config files persist across container restarts.

## Anubis Policy

`botPolicy.yaml` currently:

- imports built-in deny/allow lists
- allows local/private CIDRs
- allows `robots.txt` and `favicon.ico`
- challenges browser-like user agents
- denies unmatched traffic

Adjust rules if your file distribution endpoint blocks legitimate users.

## Backups

At minimum, back up:

- `serverdata/`
- `data/`
- `npm/data/`
- `npm/letsencrypt/`

Example:

```bash
tar -czf minecraft-backup-$(date +%F).tar.gz serverdata data npm/data npm/letsencrypt
```

## Updates

```bash
docker compose pull
docker compose up -d
```

## Troubleshooting

- Cannot connect to Minecraft:
	- verify `docker compose ps`
	- confirm firewall/NAT for TCP `25565`
	- validate `mc-router` `MAPPING` values
- File endpoint inaccessible:
	- inspect `docker compose logs -f anubis`
	- review `botPolicy.yaml`
- Reverse proxy/TLS problems:
	- inspect `docker compose logs -f npm`
	- verify NPM host entries and certificates

## License

MIT. See [LICENSE](LICENSE).