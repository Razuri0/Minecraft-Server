# Minecraft-Server

Docker Compose stack for running a Minecraft server (Vanilla, Fabric, NeoForge, or Forge) with routing, file distribution, reverse proxying, and dynamic DNS.

## Stack Overview

This repository includes:

- `server`: Minecraft server (`itzg/minecraft-server:java25-graalvm`)
- `mc-router`: domain-based Minecraft router (`itzg/mc-router`)
- `miniserve`: simple HTTP file server for `./data`
- `npm`: Nginx Proxy Manager for reverse proxy and TLS (`80`, `443`, `81`)
- `ddns`: DuckDNS updater container

Persistent game files are stored in `./serverdata`.

## Files

- `docker-compose.yml`: service definitions and runtime configuration
- `.env.example`: template for all user-specific values (copy to `.env`)
- `.env`: your actual configuration (gitignored, never commit this)
- `Makefile`: `make setup` creates `.env`, sets `PUID`/`PGID`, detects NUMA node 0 CPUs and writes `MC_CPUSET` into `.env`
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

Run one-time setup, which sets `PUID`/`PGID` and `MC_CPUSET` automatically:

```bash
make setup
```

Alternativly setup .evn and botPolicy.yaml manually

Copy the template and fill in your values:

```bash
cp .env.example .env
cp botPolicy.yaml.example botPolicy.yaml
```

Then edit `.env`:

- `MC_DOMAIN`: domain players connect with (routed by `mc-router`)
- `MC_VERSION`: Minecraft version, e.g. `1.21.11` or `LATEST`
- `MC_TYPE`: `VANILLA`, `FABRIC`, `NEOFORGE`, or `FORGE`
- `MOD_LOADER_VERSION`: loader version for the chosen type; empty = latest/recommended
- `MC_MEMORY`: JVM heap size, e.g. `10G`
- `MC_CPUSET`: CPUs to pin the server to on multi-CPU (NUMA) machines; empty = all CPUs
- `TZ`, `DUCKDNS_SUBDOMAINS`, `DUCKDNS_TOKEN`: DuckDNS updater settings

If using the setup script machine's NUMA topology is automatically detected and node 0 CPU list is written into `MC_CPUSET` in `.env` (left empty on single-CPU machines, where pinning is unnecessary). Re-run it after hardware changes.

## Start

```bash
make run
make ps
```

Check logs (Ctrl+C to exit):

```bash
make logs
```

Open Minecraft Console (Ctrl+P followed by Ctrl+Q to exit)

```bash
make console
```

## Access

- Minecraft entrypoint: host TCP `25565` (via `mc-router`)
- Nginx Proxy Manager UI: `http://<host>:81`
- Public web/file endpoint: configure in NPM to route to `miniserve`

## Common Commands

Start/stop/restart:

```bash
make run
make stop
make restart
```

Follow logs from all services (`make logs`), or a single one:

```bash
make logs
docker compose logs -f server
docker compose logs -f mc-router
```

Run `make` with no arguments to list all available commands.

## Minecraft Service Notes

Server type, Minecraft version, mod loader version, memory, and CPU pinning are all set in `.env` (see above). CPU pinning (`MC_CPUSET`) is meant for multi-CPU machines: pinning the server to the CPUs of one NUMA node keeps its memory local. Run `make setup` to detect and set it automatically.

for more information see [Itzg/minecraft](https://docker-minecraft-server.readthedocs.io/en/latest/)

The server mounts `./serverdata:/data`, so all world/config files persist across container restarts.


## Backups

At minimum, back up:

- `.env`
- `serverdata/`
- `data/`
- `npm/data/`
- `npm/letsencrypt/`

Run `make backup` to write a timestamped archive of all of the above:

```bash
make backup   # -> minecraft-backup-YYYY-MM-DD.tar.gz
```

## Updates

```bash
make update   # docker compose pull && up -d
```