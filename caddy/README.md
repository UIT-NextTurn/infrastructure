# Caddy Ingress Gateway & Reverse Proxy

This directory contains the Podman Compose stack for **Caddy** (an enterprise-grade HTTP/2 & HTTP/3 reverse proxy and TLS termination gateway).

In NextTurn, Caddy serves as the **Unified Ingress Gateway**, consolidating traffic over the shared Podman network `nextturn-network` and routing incoming requests to:
1. **Keycloak Authentication & IAM Server** (`/realms/*`, `/admin/*`, `/resources/*`, `/js/*`, `/auth*`)
2. **NextTurn Spring Boot Backend REST APIs & Real-time SSE** (`/api/*`, `/actuator/*`, `/swagger-ui/*`, `/v3/api-docs/*`)
3. **NextTurn Frontend Web Client** (`/*` default fallback to Next.js on port 3000)

---

## 📁 Directory Structure

```text
caddy/
├── docker-compose.yml       # Caddy container, volume & network definitions
├── Caddyfile                # Ingress routing rules, security headers & upstream proxies
├── .env.example             # Template for Caddy ports, domain, and upstream endpoints
├── .env                     # Local active configuration (ignored by Git)
└── README.md                # Operational guide & deployment cheatsheet
```

---

## 🌐 Ingress Routing Map

| Path Pattern | Handler | Target Upstream | Description |
| :--- | :--- | :--- | :--- |
| `/admin*`, `/realms*`, `/resources*`, `/js*`, `/auth*` | Reverse Proxy | `{$KEYCLOAK_UPSTREAM:nextturn-keycloak:8080}` | Keycloak Identity & Access Management |
| `/api/*`, `/actuator/*`, `/swagger-ui/*`, `/v3/api-docs/*` | Reverse Proxy | `{$BACKEND_UPSTREAM:nextturn-backend:8080}` | Spring Boot REST APIs, OpenAPI docs & SSE events |
| `/*` (default fallback) | Reverse Proxy | `nextturn-frontend:3000` | NextTurn Frontend Web Application (Next.js) |

---

## ⚙️ Key Ingress Features

- **Automatic SSL/TLS**: When `NEXTTURN_DOMAIN` is set to a public domain, Caddy automatically provisions and renews Let's Encrypt certificates.
- **Modern Compression**: Automatically applies `zstd` and `gzip` compression to all eligible text and JSON payloads.
- **Security Hardening**:
  - Injects `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, and `Referrer-Policy: strict-origin-when-cross-origin`.
  - Configures `Content-Security-Policy: frame-ancestors *;` to permit embedding the NextTurn booking widget across third-party portals.
  - Strips the `Server` header to prevent server software fingerprinting.
- **Host Resolution**:
  - Configured with `extra_hosts` (`host.docker.internal` / `host.containers.internal`) to allow seamless proxying to host-running backend servers during development.

---

## 🚀 Quickstart

### 1. Ensure Shared Podman Network Exists
```bash
bash ../init-network.sh
```

### 2. Configure Environment Variables
If `.env` does not exist, copy from the template:
```bash
cp .env.example .env
```

Key variables in `.env`:
- `NEXTTURN_DOMAIN`: Domain name (default: `localhost`).
- `CADDY_HTTP_PORT`: Host HTTP port (default: `80`).
- `CADDY_HTTPS_PORT`: Host HTTPS port (default: `443`).
- `CADDY_ADMIN_PORT`: Admin API port (default: `2019`).
- `KEYCLOAK_UPSTREAM`: Address of Keycloak container (default: `nextturn-keycloak:8080`).
- `BACKEND_UPSTREAM`: Address of Spring Boot backend (default: `host.containers.internal:8080`).

---

## 🛠️ Management Commands

Manage Caddy using the root infrastructure Makefile:

```bash
# Start Caddy
make up-caddy

# Follow logs
make logs-caddy

# Reload Caddyfile without downtime
make reload-caddy

# Stop Caddy
make down-caddy
```
