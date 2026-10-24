# ==============================================================================
# NextTurn Infrastructure Makefile
# Điều phối các dịch vụ hạ tầng (MySQL, Caddy, Keycloak, Valkey) và mạng Podman nội bộ
# Target Environment: Oracle Linux 9 (ARM64 / aarch64)
# ==============================================================================

# Environment Adaptive Tooling (Windows Local / Oracle Linux Server)
ifeq ($(OS),Windows_NT)
	CONTAINER_ENGINE ?= docker
	COMPOSE          ?= docker compose
	INIT_NETWORK     ?= powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (docker network ls --filter name=^nextturn-network$$ -q)) { docker network create nextturn-network; Write-Host 'Shared network created.' } else { Write-Host 'Shared network ready.' }"
else
	CONTAINER_ENGINE ?= podman
	COMPOSE          ?= podman compose
	INIT_NETWORK     := bash ./init-network.sh
endif

# Compose File Paths
COMPOSE_ROOT     := docker-compose.yml
COMPOSE_MYSQL    := mysql/docker-compose.yml
COMPOSE_CADDY    := caddy/docker-compose.yml
COMPOSE_KEYCLOAK := keycloak/docker-compose.yml
COMPOSE_VALKEY   := valkey/docker-compose.yml

# Colors for terminal output
CYAN  := \033[36m
GREEN := \033[32m
RESET := \033[0m

.DEFAULT_GOAL := help

# ------------------------------------------------------------------------------
# 📖 Help & Discovery
# ------------------------------------------------------------------------------
.PHONY: help
help:
	@echo ""
	@echo "NextTurn Infrastructure Control Hub (Podman / Oracle Linux 9 ARM64)"
	@echo "===================================================================="
	@echo "Usage: make [target]"
	@echo ""
	@echo "Global Orchestration:"
	@echo "  make up               - Initialize Podman network and start ALL services (MySQL, Caddy, Keycloak, Valkey)"
	@echo "  make down             - Stop ALL services"
	@echo "  make restart          - Restart ALL services"
	@echo "  make ps               - Display running status of all containers (Process Status)"
	@echo "  make status           - Alias for make ps"
	@echo "  make logs             - Stream logs from all services"
	@echo "  make network          - Ensure shared Podman network 'nextturn-network' exists"
	@echo "  make clean            - Teardown all services and delete persistent volumes"
	@echo ""
	@echo "MySQL Database:"
	@echo "  make up-mysql         - Start MySQL database container"
	@echo "  make down-mysql       - Stop MySQL database container"
	@echo "  make restart-mysql    - Restart MySQL database container"
	@echo "  make logs-mysql       - Stream logs from MySQL"
	@echo "  make cli-mysql        - Open interactive MySQL shell"
	@echo "  make seed-mysql       - Seed initial central tenants into MySQL nextturn_master"
	@echo ""
	@echo "Keycloak IAM Stack:"
	@echo "  make up-keycloak      - Start Keycloak IAM (connected to MySQL schema)"
	@echo "  make down-keycloak    - Stop Keycloak IAM"
	@echo "  make restart-keycloak - Restart Keycloak IAM"
	@echo "  make logs-keycloak    - Stream logs from Keycloak"
	@echo ""
	@echo "Valkey In-Memory Cache:"
	@echo "  make up-valkey        - Start Valkey container"
	@echo "  make down-valkey      - Stop Valkey container"
	@echo "  make restart-valkey   - Restart Valkey container"
	@echo "  make logs-valkey      - Stream logs from Valkey"
	@echo "  make cli-valkey       - Open interactive Valkey CLI"
	@echo ""
	@echo "Caddy Ingress & Frontend Host:"
	@echo "  make up-caddy         - Start Caddy ingress & static frontend host"
	@echo "  make down-caddy       - Stop Caddy"
	@echo "  make restart-caddy    - Restart Caddy"
	@echo "  make logs-caddy       - Stream logs from Caddy"
	@echo "  make reload-caddy     - Reload Caddy configuration without downtime"
	@echo ""

# ------------------------------------------------------------------------------
# 🌐 Common Network Management (Podman Network)
# ------------------------------------------------------------------------------
.PHONY: network
network:
	@$(INIT_NETWORK)

# ------------------------------------------------------------------------------
# 🚀 Global Infrastructure (All Stacks)
# ------------------------------------------------------------------------------
.PHONY: up up-all
up: up-all
up-all: network
	@echo "Starting all infrastructure services via $(COMPOSE)..."
	$(COMPOSE) -f $(COMPOSE_ROOT) up -d
	@echo "All infrastructure services are running."

.PHONY: down down-all
down: down-all
down-all:
	@echo "Stopping all infrastructure services..."
	$(COMPOSE) -f $(COMPOSE_ROOT) down
	@echo "All infrastructure services stopped."

.PHONY: restart restart-all
restart: restart-all
restart-all: down-all up-all

.PHONY: ps status
ps: status
status:
	$(COMPOSE) -f $(COMPOSE_ROOT) ps

.PHONY: logs logs-all
logs: logs-all
logs-all:
	$(COMPOSE) -f $(COMPOSE_ROOT) logs -f

.PHONY: clean
clean:
	@echo "Stopping all services and removing persistent volumes..."
	$(COMPOSE) -f $(COMPOSE_ROOT) down -v
	@echo "Volumes cleaned."

# ------------------------------------------------------------------------------
# 🐬 MySQL Relational Database Stack
# ------------------------------------------------------------------------------
.PHONY: up-mysql
up-mysql: network
	@echo "Starting MySQL database container..."
	$(COMPOSE) -f $(COMPOSE_MYSQL) up -d
	@echo "MySQL running on port 3306 (internal alias: nextturn-mysql)."

.PHONY: down-mysql
down-mysql:
	@echo "Stopping MySQL database..."
	$(COMPOSE) -f $(COMPOSE_MYSQL) down

.PHONY: restart-mysql
restart-mysql: down-mysql up-mysql

.PHONY: logs-mysql
logs-mysql:
	$(COMPOSE) -f $(COMPOSE_MYSQL) logs -f mysql

.PHONY: cli-mysql
cli-mysql:
	$(CONTAINER_ENGINE) exec -it nextturn-mysql mysql -uroot -proot

.PHONY: seed-mysql
seed-mysql:
	@echo "Seeding central master database..."
	$(CONTAINER_ENGINE) exec -i nextturn-mysql mysql -unextturn -pnextturn_dev_secret nextturn_master < mysql/seed/01_seed_central_tenants.sql
	@echo "Central master database seeded successfully."

# ------------------------------------------------------------------------------
# 🔐 Keycloak Identity & Access Management (IAM)
# ------------------------------------------------------------------------------
.PHONY: up-keycloak
up-keycloak: network
	@echo "Starting Keycloak stack..."
	$(COMPOSE) -f $(COMPOSE_KEYCLOAK) up -d
	@echo "Keycloak stack started on port 8180 (connecting to MySQL schema)."

.PHONY: down-keycloak
down-keycloak:
	@echo "Stopping Keycloak stack..."
	$(COMPOSE) -f $(COMPOSE_KEYCLOAK) down

.PHONY: restart-keycloak
restart-keycloak: down-keycloak up-keycloak

.PHONY: logs-keycloak
logs-keycloak:
	$(COMPOSE) -f $(COMPOSE_KEYCLOAK) logs -f keycloak

# ------------------------------------------------------------------------------
# ⚡ Valkey In-Memory Cache
# ------------------------------------------------------------------------------
.PHONY: up-valkey
up-valkey: network
	@echo "Starting Valkey cache..."
	$(COMPOSE) -f $(COMPOSE_VALKEY) up -d
	@echo "Valkey running on port 6379."

.PHONY: down-valkey
down-valkey:
	@echo "Stopping Valkey cache..."
	$(COMPOSE) -f $(COMPOSE_VALKEY) down

.PHONY: restart-valkey
restart-valkey: down-valkey up-valkey

.PHONY: logs-valkey
logs-valkey:
	$(COMPOSE) -f $(COMPOSE_VALKEY) logs -f valkey

.PHONY: cli-valkey
cli-valkey:
	$(CONTAINER_ENGINE) exec -it nextturn-valkey valkey-cli

# ------------------------------------------------------------------------------
# 🌐 Caddy Reverse Proxy & Ingress Gateway
# ------------------------------------------------------------------------------
.PHONY: up-caddy
up-caddy: network
	@echo "Starting Caddy ingress gateway..."
	$(COMPOSE) -f $(COMPOSE_CADDY) up -d
	@echo "Caddy running on ports 80, 443."

.PHONY: down-caddy
down-caddy:
	@echo "Stopping Caddy ingress gateway..."
	$(COMPOSE) -f $(COMPOSE_CADDY) down

.PHONY: restart-caddy
restart-caddy: down-caddy up-caddy

.PHONY: logs-caddy
logs-caddy:
	$(COMPOSE) -f $(COMPOSE_CADDY) logs -f caddy

.PHONY: reload-caddy
reload-caddy:
	$(CONTAINER_ENGINE) exec -it nextturn-caddy caddy reload --config /etc/caddy/Caddyfile
