.DEFAULT_GOAL := help
.PHONY: help setup run stop restart logs ps update backup

# Show available commands (default target - runs on bare `make`)
help:
	@echo "Minecraft server stack - available commands:"
	@echo ""
	@echo "  make setup    One-time setup: create .env, set PUID/PGID + cpuset, create data dirs"
	@echo "  make run      Start all containers (docker compose up -d)"
	@echo "  make stop     Stop and remove all containers (docker compose down)"
	@echo "  make restart  Restart all containers"
	@echo "  make logs     Follow logs from all containers (Ctrl+C to exit)"
	@echo "  make ps       Show container status"
	@echo "  make update   Pull newer images and recreate containers"
	@echo "  make backup   Create a timestamped tar.gz of .env and all data dirs"

# One-time setup: creates .env, sets PUID/PGID to the current user, detects the
# NUMA cpuset, seeds the Anubis policy, and pre-creates the bind-mount
# directories as the current user so the non-root containers can write to them
# (Docker would create them as root). Safe to re-run - existing files are kept.
setup:
	@echo "Setting up .env"
	test -f .env || cp .env.example .env

	@echo "Setting PUID/PGID to the current user"
	grep -q '^PUID=' .env && sed -i "s/^PUID=.*/PUID=$$(id -u)/" .env || printf 'PUID=%s\n' "$$(id -u)" >> .env
	grep -q '^PGID=' .env && sed -i "s/^PGID=.*/PGID=$$(id -g)/" .env || printf 'PGID=%s\n' "$$(id -g)" >> .env

	@echo "Detecting NUMA cpuset"
	nodes=$$(ls -d /sys/devices/system/node/node[0-9]* 2>/dev/null | wc -l); \
	if [ "$$nodes" -le 1 ]; then \
		cpuset=""; \
		echo "Single NUMA node detected - no pinning needed, leaving MC_CPUSET empty."; \
	else \
		cpuset=$$(cat /sys/devices/system/node/node0/cpulist); \
		echo "$$nodes NUMA nodes detected - pinning server to node 0 CPUs: $$cpuset"; \
	fi; \
	grep -q '^MC_CPUSET=' .env && sed -i "s/^MC_CPUSET=.*/MC_CPUSET=$$cpuset/" .env || printf 'MC_CPUSET=%s\n' "$$cpuset" >> .env

	@echo "Setting up Anubis bot mitigation policy"
	test -f botPolicy.yaml || cp botPolicy.yaml.example botPolicy.yaml

	@echo "Creating bind-mount directories as the current user"
	mkdir -p serverdata data anubis-data npm/data npm/letsencrypt

	@echo "Setup complete. You can now run 'make run' to start the containers."

# Start all containers, warning first about unedited placeholder config
run:
	@test -f .env || { echo "No .env found - run 'make setup' first."; exit 1; }
	@grep -q '^MC_DOMAIN=mc.example.com' .env && echo "WARNING: MC_DOMAIN is still 'mc.example.com' - edit .env before players can connect." || true
	@grep -q '^DUCKDNS_TOKEN=$$' .env && echo "WARNING: DUCKDNS_TOKEN is empty - the ddns updater will not work until you set it in .env." || true
	docker compose up -d

# Stop and remove all containers
stop:
	docker compose down

# Restart all running containers
restart:
	docker compose restart

# Follow logs from all containers
logs:
	docker compose logs -f

# Attach to the Minecraft server console to view output and send commands. Use Ctrl+P followed by Ctrl+Q to detach without stopping the server.
console:
	docker attach minecraft-server

# Show container status
ps:
	docker compose ps

# Pull newer images and recreate containers
update:
	docker compose pull
	docker compose up -d

# Back up config and persistent data to a timestamped archive
backup:
	tar -czf minecraft-backup-$$(date +%F).tar.gz .env serverdata data npm/data npm/letsencrypt
	@echo "Backup written to minecraft-backup-$$(date +%F).tar.gz"
