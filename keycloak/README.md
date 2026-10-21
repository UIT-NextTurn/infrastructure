# Keycloak Identity & Access Management (IAM)

This directory contains the Podman Compose stack for **Keycloak** (OIDC / OAuth 2.0 Identity Provider) backed by an external **Oracle MySQL HeatWave** database instance using a dedicated schema.

---

## 📁 Directory Structure

```text
keycloak/
├── docker-compose.yml       # Keycloak service orchestration (connects to MySQL HeatWave)
├── .env.example             # Template for environment secrets
├── .env                     # Local active secrets (ignored by Git)
├── README.md                # Documentation and operational cheatsheet
└── realm-imports/
    └── realm-nextturn.json  # Starter realm with NextTurn 4-tier roles & OIDC clients
```

---

## 🔐 Key Features

- **External MySQL HeatWave Backend**: Rather than running a local database container, Keycloak connects directly to Oracle MySQL HeatWave using an isolated database schema (e.g. `keycloak_iam`).
- **Decoupled Architecture**: Keycloak operates as an independent service attached to the shared Podman network `nextturn-network`.
- **Conflict Prevention**: Keycloak is mapped to host port **`8180`**, avoiding collisions with the NextTurn Spring Boot backend on port **`8080`**.
- **Automated Realm Seeding**: Mounting `./realm-imports` to `/opt/keycloak/data/import` with `--import-realm` imports `realm-nextturn.json` on initial boot.

---

## 🗄️ MySQL HeatWave Database Schema Preparation

Before launching Keycloak for the first time, execute the following SQL statement in your Oracle MySQL HeatWave instance to create the isolated schema and user permissions:

```sql
-- 1. Create dedicated IAM schema
CREATE DATABASE IF NOT EXISTS keycloak_iam 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_0900_ai_ci;

-- 2. Create user (or grant permissions to existing user)
CREATE USER IF NOT EXISTS 'keycloak'@'%' IDENTIFIED BY 'your_strong_password';
GRANT ALL PRIVILEGES ON keycloak_iam.* TO 'keycloak'@'%';
FLUSH PRIVILEGES;
```

---

## 🚀 Quickstart

### 1. Ensure Shared Podman Network Exists
```bash
bash ../init-network.sh
```

### 2. Configure Environment Variables
If `.env` does not exist, copy from the template and set your MySQL HeatWave endpoint:
```bash
cp .env.example .env
```
Key variables in `.env`:
- `MYSQL_HOST`: Private IP or hostname of your MySQL HeatWave DB system.
- `MYSQL_PORT`: `3306`
- `KEYCLOAK_DB_NAME`: `keycloak_iam`
- `KEYCLOAK_DB_USER`: `keycloak`
- `KEYCLOAK_DB_PASSWORD`: Your database password.

### 3. Start Keycloak Stack
```bash
podman compose up -d
```
Or via Makefile from the `infrastructure/` root:
```bash
make up-keycloak
```

### 4. Check Logs
```bash
podman compose logs -f keycloak
# or: make logs-keycloak
```

### 5. Stop Keycloak
```bash
podman compose down
# or: make down-keycloak
```

---

## 🌐 Endpoints & Access Points

| Service | Host URL | Description |
| :--- | :--- | :--- |
| **Keycloak Admin Console** | [http://localhost:8180/admin](http://localhost:8180/admin) | Login with admin credentials from `.env` (`admin`/`admin`) |
| **NextTurn Realm Discovery (OIDC)** | `http://localhost:8180/realms/nextturn/.well-known/openid-configuration` | OpenID Connect metadata for Spring Boot / Frontend |
| **Health Check Probe** | [http://localhost:8180/health/ready](http://localhost:8180/health/ready) | Quarkus readiness probe |
| **Database Backend** | MySQL HeatWave (schema: `keycloak_iam`) | Managed cloud database |
