# Minecraft-Server

Docker-based Minecraft stack with:

- Fabric Minecraft server (Java 25 image)
- Miniserve for sharing files (modpacks, configs, etc.)
- Anubis bot/challenge proxy in front of Miniserve
- Nginx Proxy Manager (NPM) for reverse proxy and TLS
- DuckDNS client for dynamic DNS updates

## Overview

This repository hosts a self-managed Minecraft setup using Docker Compose.
The game server data is persisted under `serverdata/`, while file-sharing and reverse-proxy components are included in the same stack.

## Services

Defined in `docker-compose.yml`:

- `server`: Minecraft Fabric server (`itzg/minecraft-server:java25`)
- `miniserve`: Simple HTTP file server for the `data/` folder
- `anubis`: Bot mitigation/challenge layer targeting Miniserve
- `npm`: Nginx Proxy Manager (ports `80`, `443`, `81`)
- `ddns`: DuckDNS updater container

## Repository Layout

- `docker-compose.yml`: Main stack definition
- `botPolicy.yaml`: Anubis bot/challenge policy
- `serverdata/`: Persistent Minecraft server data and world files
- `data/`: Files exposed through Miniserve
- `npm/data/`: Nginx Proxy Manager runtime state
- `npm/letsencrypt/`: TLS certificates for Nginx Proxy Manager

## Prerequisites

- Docker Engine 24+
- Docker Compose plugin (`docker compose`)
- A host with enough RAM for Java + containers (this stack is configured for 10G JVM heap)

## Quick Start

1. Clone/open this repository on your server host.
2. Review and update environment placeholders in `docker-compose.yml`:
	 - `SUBDOMAINS=<DUCKDNS_SUBDOMAIN>`
	 - `TOKEN=<DUCKDNS_TOKEN>`
3. Start the stack:

```bash
docker compose up -d
```

4. Check container health/logs:

```bash
docker compose ps
docker compose logs -f server
```

5. Connect Minecraft client to your server host/IP on port `25565`.

## Common Operations

Start/stop/restart:

```bash
docker compose up -d
docker compose stop
docker compose restart
```

Follow logs:

```bash
docker compose logs -f server
docker compose logs -f anubis
docker compose logs -f npm
```

Graceful Minecraft console access:

```bash
docker attach minecraft-server
# Detach without stopping: Ctrl+P, Ctrl+Q
```

## Minecraft Configuration

Core Minecraft settings are in `serverdata/server.properties`.

Current notable settings:

- `enable-rcon=true`
- `server-port=25565`
- `max-players=20`
- `difficulty=easy`
- `gamemode=survival`

Fabric + version selection is controlled by compose environment values:

- `TYPE=FABRIC`
- `VERSION=1.21.11`
- `FABRIC_VERSION=0.18.5`

## Web and File Access

- Miniserve serves `./data` internally on container port `8080`.
- Anubis listens on host port `8923` and proxies to Miniserve.
- Nginx Proxy Manager admin UI is exposed on `http://<host>:81`.

Use NPM to create your public reverse proxy hostnames and TLS certs.

## Security Notes

- Do not commit real credentials/tokens.
- Replace placeholder DuckDNS values before deployment.
- Rotate sensitive values if they were ever exposed (for example RCON password).
- Restrict firewall rules to only required inbound ports (`25565`, `80`, `443`, and admin `81` only if needed).
- Consider disabling direct host exposure of services that are only needed internally.

## Backup

At minimum, back up:

- `serverdata/world/`
- `serverdata/server.properties`
- `serverdata/ops.json`, `serverdata/whitelist.json`, `serverdata/banned-*.json`
- `npm/data/` and `npm/letsencrypt/`

Example quick backup:

```bash
tar -czf minecraft-backup-$(date +%F).tar.gz serverdata npm/data npm/letsencrypt data
```

## Updating

1. Pull updated images:

```bash
docker compose pull
```

2. Recreate containers:

```bash
docker compose up -d
```

3. Verify logs and server startup:

```bash
docker compose logs --tail=200 server
```

## Troubleshooting

- Server not reachable:
	- Verify `docker compose ps` shows `server` running.
	- Confirm firewall/NAT forwards TCP `25565`.
- File server blocked/challenged unexpectedly:
	- Review `botPolicy.yaml` and `docker compose logs -f anubis`.
- Reverse proxy issues:
	- Check NPM logs and host configuration in the NPM admin panel.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).