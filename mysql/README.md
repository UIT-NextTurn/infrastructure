# MySQL Relational Database Stack

This directory contains the Podman Compose stack for **MySQL 8.4 LTS** (an enterprise-grade relational database management system (*hệ quản trị cơ sở dữ liệu quan hệ*) with native ARM64 / aarch64 support and full wire-compatibility with Oracle MySQL HeatWave).

In NextTurn, this MySQL service operates on the shared Podman bridge network `nextturn-network`, serving two isolated schemas (*lược đồ cơ sở dữ liệu*):
1. **`nextturn_db`**: Primary business application database for the Spring Boot backend (queues, tickets, counters, multi-tenant configs).
2. **`keycloak_iam`**: Dedicated identity and access management schema used by Keycloak.

---

## 📁 Directory Structure

```text
mysql/
├── docker-compose.yml       # MySQL container, volume & network definitions
├── conf.d/
│   └── my.cnf               # Custom server tuning (UTF8mb4, buffer pool, connection limits)
├── initdb/
│   └── 01-init-schemas.sql  # Automated provisioning script for schemas and user privileges
├── .env.example             # Template for MySQL passwords and ports
├── .env                     # Local active secrets (ignored by Git)
└── README.md                # Operational cheatsheet & connection guides
```

---

## 🔌 Connection Reference

### 1. Connecting from Other Infrastructure Containers on `nextturn-network`
Any service attached to `nextturn-network` (such as Keycloak or a containerized backend) can resolve MySQL using internal Docker/Podman DNS:

| Setting | Value |
| :--- | :--- |
| **Host** | `nextturn-mysql` *(or `mysql`)* |
| **Port** | `3306` |
| **Keycloak JDBC URL** | `jdbc:mysql://nextturn-mysql:3306/keycloak_iam?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC` |
| **Backend JDBC URL** | `jdbc:mysql://nextturn-mysql:3306/nextturn_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC` |

### 2. Connecting from Host Machine (Spring Boot Local Dev, DBeaver, MySQL Workbench)
The MySQL container binds to host port **`3306`**:

| Setting | Value |
| :--- | :--- |
| **Host** | `localhost` *(or `127.0.0.1`)* |
| **Port** | `3306` |
| **Root User** | `root` / `root` |
| **Backend User** | `nextturn` / `nextturn_dev_secret` (database: `nextturn_db`) |
| **Keycloak User** | `keycloak` / `keycloak_dev_secret` (database: `keycloak_iam`) |

---

## 🚀 Quickstart

### 1. Ensure Shared Podman Network Exists
```bash
bash ../init-network.sh
```

### 2. Start MySQL Stack
From within the `infrastructure/mysql` directory:
```bash
podman compose up -d
```
Or from the project root using Makefile:
```bash
make up-mysql
```

### 3. Open Interactive MySQL Shell
```bash
make cli-mysql
# or: podman exec -it nextturn-mysql mysql -uroot -proot
```

### 4. Verify Schemas & Users
Inside the MySQL shell:
```sql
SHOW DATABASES;
-- Expected output includes: nextturn_db, keycloak_iam

SELECT user, host FROM mysql.user WHERE user IN ('keycloak', 'nextturn', 'root');
```

### 5. Stop the Service
```bash
make down-mysql
# or: podman compose down
```
*(To also wipe the persistent volume and start completely fresh, use `podman compose down -v`)*.
