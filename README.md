# NextTurn Infrastructure

This directory contains containerized service definitions and orchestration for the NextTurn platform, partitioned into technology-specific stacks operating on a shared bridge network.

---

## 🏗️ High-Level Architecture

All infrastructure services connect to a common bridge network named `nextturn-network`. This enables service-to-service communication via Docker DNS while allowing each technology stack to be deployed, scaled, or restarted independently without interrupting the others.

```mermaid
flowchart TD
    subgraph Client["Clients & Browser"]
        User["User Browser / Mobile PWA"]
    end

    subgraph IngressLayer["Unified Ingress Gateway (Caddy)"]
        Caddy["Caddy Reverse Proxy<br/>(:80, :443, :2019)<br/>nextturn-caddy"]
    end

    subgraph DockerNetwork["Shared Bridge Network: nextturn-network"]
        subgraph KeycloakStack["IAM Stack (Keycloak)"]
            Keycloak["Keycloak 26 Server<br/>(:8180 -> :8080)<br/>nextturn-keycloak"]
        end

        subgraph DatabaseStack["Relational Database (MySQL 8.4)"]
            MySQL[("MySQL 8.4 Server<br/>(:3306)<br/>nextturn-mysql<br/>(schemas: nextturn_db, keycloak_iam)")]
        end

        subgraph ValkeyStack["Cache & Real-Time Queue (Valkey)"]
            Valkey[("Valkey 8.0 In-Memory Store<br/>(:6379)<br/>nextturn-valkey")]
        end

        subgraph AppServices["Application Workloads"]
            Backend["Spring Boot Backend<br/>(host.docker.internal:8080)"]
            Frontend["NextTurn Web App<br/>(host.docker.internal:3000)"]
        end
    end

    User -->|HTTP / HTTPS / WSS| Caddy
    Caddy -->|/realms/*, /admin/*| Keycloak
    Caddy -->|/api/*, /ws/*| Backend
    Caddy -->|/*| Frontend
    Keycloak -->|JDBC (keycloak_iam)| MySQL
    Backend -->|JDBC (nextturn_db)| MySQL
    Backend -->|Cache / Queue tickets / PubSub| Valkey
    Backend -->|JWT validation / Introspection| Keycloak
```

---

## 📁 Directory Layout

```text
infrastructure/
├── .gitignore                   # Ignores sensitive .env files across all stacks
├── Makefile                     # Multi-stack orchestration controls (up, down, restart, logs)
├── README.md                    # Infrastructure master documentation
├── docker-compose.yml           # Root compose orchestrator (merges all stacks via include)
├── init-network.sh              # Bash script to create Podman shared 'nextturn-network'
│
├── mysql/                       # 🐬 Relational Database (MySQL 8.4 LTS)
│   ├── docker-compose.yml       # MySQL container, volume & network definitions
│   ├── initdb/
│   │   └── 01-init-schemas.sql  # Automated schema & user provisioning (nextturn_db, keycloak_iam)
│   ├── .env.example             # Template for passwords and ports
│   ├── .env                     # Local active secrets (ignored by Git)
│   └── README.md                # MySQL operational guide
│
├── caddy/                       # 🌐 Unified Ingress Gateway & Reverse Proxy
│   ├── docker-compose.yml       # Caddy container, volume & network definitions
│   ├── Caddyfile                # Ingress routing rules for Keycloak, Backend API, and Frontend
│   ├── .env.example             # Template for Caddy ports, domain, and upstream endpoints
│   ├── .env                     # Local active secrets (ignored by Git)
│   └── README.md                # Caddy operational guide
│
├── keycloak/                    # 🔐 Identity & Access Management (OIDC / OAuth 2.0)
│   ├── docker-compose.yml       # Keycloak orchestration (connects to Oracle MySQL HeatWave)
│   ├── realm-imports/
│   │   └── realm-nextturn.json  # Starter realm with 4 NextTurn roles & OIDC clients
│   ├── .env.example             # Template for Keycloak admin credentials & HeatWave endpoint
│   ├── .env                     # Local active secrets (ignored by Git)
│   └── README.md                # Keycloak operational guide
│
└── valkey/                      # ⚡ High-Performance Cache & Real-Time Queue Store
    ├── docker-compose.yml       # Valkey container and persistent storage definitions
    ├── .env.example             # Template for Valkey port & password
    ├── .env                     # Local active secrets (ignored by Git)
    └── README.md                # Valkey operational guide
```

---

## 🌐 Common Network (`nextturn-network`)

Every technology stack references the common network as `external: true`:

```yaml
networks:
  nextturn-network:
    name: nextturn-network
    external: true
```

### Why a Shared Network?
1. **Service Discovery**: Caddy can reach Keycloak via `nextturn-keycloak:8080` and Valkey via `nextturn-valkey:6379` using Podman internal DNS without exposing sensitive ports publicly.
2. **Decoupled Lifecycle**: Running `podman compose down` inside `valkey/` will never disconnect or delete the network used by `keycloak/` or `caddy/`.

### Network Initialization (Podman on Linux)
Before starting services for the first time, initialize the common Podman network:

```bash
chmod +x init-network.sh
./init-network.sh
```

Or directly via the Podman CLI:
```bash
podman network create --driver bridge nextturn-network
```

---

## 🔌 Port Allocation & Conflict Prevention

All host ports are intentionally offset to avoid collisions with standard local development processes:

| Technology | Container Name | Host Port | Internal Port | Purpose / Note |
| :--- | :--- | :--- | :--- | :--- |
| **MySQL** | `nextturn-mysql` | **`3306`** | `3306` | Relational DB (`nextturn_db`, `keycloak_iam`) |
| **Caddy** | `nextturn-caddy` | **`80`**, **`443`** | `80`, `443` | Unified Ingress / SSL Gateway & Frontend Host |
| **Caddy Admin** | `nextturn-caddy` | **`2019`** | `2019` | Metrics & Dynamic Config API |
| **Keycloak** | `nextturn-keycloak` | **`8180`** | `8080` | IAM Server (Offset from Spring Boot `8080`) |
| **Valkey** | `nextturn-valkey` | **`6379`** | `6379` | High-speed cache & queue ticket datastore |

---

## 🚀 Operational Workflows

### Option A: Run Individual Technology Stacks

### Option A: Using Makefile (Recommended)

You can manage the entire lifecycle with `make`:

```bash
# Global targets
make up               # Creates network and starts all services (Caddy, Keycloak, Valkey)
make down             # Stops all services
make restart          # Restarts all services
make ps               # Shows status of all containers
make logs             # Streams logs from all services
make clean            # Teardowns all containers and purges persistent volumes

# Technology-specific targets
make up-keycloak      # Start Keycloak & Postgres
make down-keycloak    # Stop Keycloak & Postgres
make logs-keycloak    # Stream Keycloak logs

make up-valkey        # Start Valkey cache
make down-valkey      # Stop Valkey cache
make logs-valkey      # Stream Valkey logs
make cli-valkey       # Open interactive Valkey CLI

make up-caddy         # Start Caddy reverse proxy
make down-caddy       # Stop Caddy reverse proxy
make logs-caddy       # Stream Caddy logs
make reload-caddy     # Reload Caddyfile without stopping container
```

### Option B: Run Individual Technology Stacks Directly

You can also run and inspect each stack independently via Docker Compose:

```bash
# 1. Keycloak IAM & PostgreSQL
cd keycloak
docker compose up -d
docker compose logs -f keycloak

# 2. Valkey In-Memory Cache
cd ../valkey
docker compose up -d
docker exec -it nextturn-valkey valkey-cli -a valkey_dev_secret ping

# 3. Caddy Reverse Proxy
cd ../caddy
docker compose up -d
docker compose logs -f caddy
```

### Option C: Orchestrate All Stacks Concurrently via Compose

From the `infrastructure/` directory, use the root compose file:

```bash
# Ensure common network is created
./init-network.sh

# Start all infrastructure stacks
podman compose up -d

# Check status of all containers
podman compose ps

# Follow logs from all services
podman compose logs -f

# Shut down all stacks (networks & volumes remain intact)
podman compose down
```

---

## 🛠️ Individual Service Documentation

- [Caddy Ingress Guide](file:///d:/Ryan/Web_project/NextTurn/infrastructure/caddy/README.md)
- [Keycloak IAM Guide](file:///d:/Ryan/Web_project/NextTurn/infrastructure/keycloak/README.md)
- [Valkey Cache Guide](file:///d:/Ryan/Web_project/NextTurn/infrastructure/valkey/README.md)
