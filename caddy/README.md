# Caddy Ingress Gateway & Frontend Deployment Host

This directory contains the Podman Compose stack for **Caddy** (an enterprise-grade HTTP/2 & HTTP/3 reverse proxy (*máy chủ proxy ngược*) and high-performance static file web server).

In NextTurn, Caddy serves two primary roles:
1. **Frontend Deployment Host (*Máy chủ lưu trữ và triển khai Frontend*)**: Serves the NextTurn frontend application (built SPA / Vite / React / Vue / Next.js static export) directly with automatic SPA client-side routing and optimal asset caching.
2. **Unified Ingress Gateway (*Cổng định tuyến API tập trung*)**: Proxies authentication requests to Keycloak and REST/WebSocket traffic to the Spring Boot backend over the shared Podman network `nextturn-network`.

---

## 📁 Directory Structure

```text
caddy/
├── docker-compose.yml       # Caddy service definition and volume mounts
├── Caddyfile                # Ingress routing rules & static Frontend serving configuration
├── html/                    # 🚀 Frontend deployment directory (mounted to /srv/frontend)
│   └── index.html           # Starter landing page or your production build output (dist/)
├── .env.example             # Template for Caddy ports, domain, and frontend path
├── .env                     # Local active configuration (ignored by Git)
└── README.md                # Operational guide & deployment cheatsheet
```

---

## 🚀 How to Deploy Your Frontend (FE)

### Option 1: Copy Build Files Directly into `caddy/html/` (Default)
When you build your frontend project (e.g. `npm run build` with Vite):
```bash
# Copy your production build artifacts into the caddy/html directory
cp -r /path/to/frontend/dist/* infrastructure/caddy/html/

# Reload Caddy configuration instantly without downtime
make reload-caddy
```

### Option 2: Mount Your Existing Build Directory via `.env`
If you prefer not copying files, set `FRONTEND_STATIC_PATH` in `infrastructure/caddy/.env`:
```env
FRONTEND_STATIC_PATH=../../frontend/dist
```
Then restart Caddy:
```bash
make restart-caddy
```

---

## ⚙️ Caddy Frontend Features

- **SPA Fallback Routing**: Includes `try_files {path} /index.html` so client-side routers (React Router, Vue Router, etc.) resolve direct URLs without 404 errors.
- **Smart Asset Caching**:
  - Static bundles (`/assets/*`, `*.js`, `*.css`, fonts, images) are served with `Cache-Control: public, max-age=31536000, immutable`.
  - `index.html` is served with `Cache-Control: no-cache, no-store, must-revalidate` so users always get the latest version immediately upon new deployments.
- **Modern Compression**: Automatically applies `zstd` and `gzip` compression to all text and JSON payloads.
- **Automatic SSL/TLS**: When `NEXTTURN_DOMAIN` is set to a public domain, Caddy automatically provisions and renews Let's Encrypt certificates.

---

## 🌐 Ingress Routing Map

| Path Pattern | Handler | Target | Description |
| :--- | :--- | :--- | :--- |
| `/*` (default) | Static Web Server | `/srv/frontend` (`html/`) | NextTurn Frontend SPA |
| `/realms/*`, `/admin/*`, `/resources/*` | Reverse Proxy | `nextturn-keycloak:8080` | Keycloak Identity & Access Management |
| `/api/*`, `/actuator/*`, `/swagger-ui/*` | Reverse Proxy | `host.containers.internal:8080` | Spring Boot REST API |
| `/ws/*` | Reverse Proxy + WebSocket | `host.containers.internal:8080` | Spring Boot WebSocket STOMP queue channel |

---

## 🛠️ Management Commands

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
