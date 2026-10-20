# Valkey Cache & Real-Time Queue Store

This directory contains the Docker Compose stack for **Valkey** (the high-performance, open-source drop-in replacement fork (*bản phân nhánh thay thế trực tiếp*) of Redis supported by the Linux Foundation).

In NextTurn, Valkey is used for:
- Real-time queue ticketing numbers and counter state caching.
- Rapid distributed locks (*khóa phân tán*) to avoid race conditions (*tình trạng tương tranh*) during ticket issuing.
- WebSocket session tracking and ticket rate limiting (*giới hạn tần suất yêu cầu*).
- Authentication token blocklists (*danh sách chặn mã xác thực*).

---

## 📁 Directory Structure

```text
valkey/
├── docker-compose.yml       # Valkey service orchestration
├── valkey.conf              # Production-tuned configuration (AOF, LRU eviction, persistence)
├── .env.example             # Template for Valkey configuration
├── .env                     # Local active secrets (ignored by Git)
└── README.md                # Documentation and operational cheatsheet
```

---

## 🔐 Key Features

- **Standard Compatibility (*Khả năng tương thích chuẩn*)**: Fully wire-compatible with Redis 7.2+ protocol and Spring Data Redis (`Lettuce` / `Jedis`).
- **Data Persistence (*Độ bền vững dữ liệu*)**: Configured with both RDB periodic snapshots and AOF (Append-Only File) synchronized every second (`appendfsync everysec`).
- **Memory Protection (*Bảo vệ dung lượng bộ nhớ*)**: Default `maxmemory 512mb` with `volatile-lru` eviction policy so expired tokens and temporary cache keys are purged smoothly.
- **Isolated Stack (*Ngăn xếp độc lập*)**: Runs as an independent compose stack attached to `nextturn-network`.

---

## 🚀 Quickstart

### 1. Ensure Shared Network Exists
Ensure the common bridge network `nextturn-network` is created (only needed once):
```bash
docker network create nextturn-network
```

### 2. Configure Environment Variables
If `.env` does not exist, copy from the template:
```bash
cp .env.example .env
```

### 3. Start Valkey Stack
From within the `infrastructure/valkey` directory:
```bash
docker compose up -d
```
Or from the project root:
```bash
docker compose -f infrastructure/valkey/docker-compose.yml up -d
```

### 4. Verify Connection via CLI
Test the container health and ping Valkey:
```bash
docker exec -it nextturn-valkey valkey-cli -a valkey_dev_secret ping
```
*(Should return `PONG`)*.

To open the interactive CLI:
```bash
docker exec -it nextturn-valkey valkey-cli -a valkey_dev_secret
```

### 5. Stop the Services
```bash
docker compose down
```
*(To also remove the persistent data volume, add `-v`)*.

---

## ☕ Spring Boot Integration (`application.yml`)

To connect NextTurn Spring Boot backend to Valkey:

```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:valkey_dev_secret}
      timeout: 3000ms
```

When running backend inside Docker on `nextturn-network`, set `REDIS_HOST: nextturn-valkey`. When running on the host machine during local development, use `localhost:6379`.
