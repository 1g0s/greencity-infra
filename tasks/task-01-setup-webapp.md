# Task 1: Setup a Webapp - Completion Report

**Project:** GreenCity
**Status:** COMPLETED
**Date:** January 6, 2026
**Environment:** z6 workstation (192.168.1.115)

---

## Architecture Diagram

```mermaid
graph TB
    subgraph "External Access"
        USER[User/Browser]
        NET[Local Network<br/>192.168.1.0/24]
    end

    subgraph "Host: z6 (192.168.1.115)"
        subgraph "Docker Network: greencity-net"
            PG[(PostgreSQL 15<br/>Port: 5434-5432<br/>DB: greencity)]
            BC[greencity-backcore<br/>Java 21 + Maven<br/>Spring Boot 3.2.2<br/>Port: 8080]
            BU[greencity-backuser<br/>Java 21 + Maven<br/>Spring Boot 3.2.2<br/>Port: 8060]
        end

        subgraph "Native Process"
            FE[greencity-frontend<br/>Angular 9.1.15<br/>Node 14<br/>Port: 4200]
        end

        subgraph "Firewall (UFW)"
            FW[Ports Allowed:<br/>4200, 8080, 8060]
        end
    end

    USER --> NET
    NET --> FW
    FW --> FE
    FW --> BC
    FW --> BU
    FE --> BC
    FE --> BU
    BC --> PG
    BU --> PG
    BC <--> BU
```

## Service Communication Flow

```mermaid
sequenceDiagram
    participant U as User Browser
    participant FE as Frontend<br/>:4200
    participant BC as BackCore<br/>:8080
    participant BU as BackUser<br/>:8060
    participant DB as PostgreSQL<br/>:5434

    U->>FE: HTTP Request
    FE->>BC: API Call (habits, places, news)
    BC->>DB: Query Data
    DB-->>BC: Return Data
    BC-->>FE: JSON Response

    FE->>BU: API Call (auth, users)
    BU->>DB: Query Users
    DB-->>BU: Return Users
    BU-->>FE: JSON Response

    BC->>BU: Internal API (user validation)
    BU-->>BC: User Data

    FE-->>U: Rendered Page
```

## Infrastructure Topology

```mermaid
graph LR
    subgraph "Docker Infrastructure"
        direction TB
        N[greencity-net<br/>Bridge Network]
        V1[greencity_pgdata<br/>Volume]
        V2[greencity_maven_cache<br/>Volume]
    end

    subgraph "Containers"
        C1[greencity-postgres]
        C2[greencity-backcore]
        C3[greencity-backuser]
    end

    subgraph "Native Processes"
        P1[Angular Dev Server<br/>npx ng serve]
    end

    N --- C1
    N --- C2
    N --- C3
    V1 --> C1
    V2 --> C2
    V2 --> C3
```

## Service Status Summary

| Service | Container/Process | Port | Status | Health |
|---------|-------------------|------|--------|--------|
| PostgreSQL | `greencity-postgres` | 5434->5432 | Running | Healthy |
| BackCore API | `greencity-backcore` | 8080 | Running | Started in 13.2s |
| BackUser API | `greencity-backuser` | 8060 | Running | Started in 7.1s |
| Frontend | Native (npx ng serve) | 4200 | Running | Compiled successfully |

## Access URLs

| Service | Local URL | Network URL |
|---------|-----------|-------------|
| Frontend | http://localhost:4200 | http://192.168.1.115:4200 |
| BackCore API | http://localhost:8080 | http://192.168.1.115:8080 |
| BackCore Swagger | http://localhost:8080/swagger-ui.html | http://192.168.1.115:8080/swagger-ui.html |
| BackUser API | http://localhost:8060 | http://192.168.1.115:8060 |
| BackUser Swagger | http://localhost:8060/swagger-ui.html | http://192.168.1.115:8060/swagger-ui.html |

## Files Created

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Docker infrastructure for PostgreSQL + Java backends |
| UFW rules | Firewall ports 4200, 8060 opened for local network |

## Technology Stack Deployed

```mermaid
graph TB
    subgraph "Frontend Layer"
        A1[Angular 9.1.15]
        A2[TypeScript 3.8.3]
        A3[Node.js 14.21.3]
        A4[npm 6.14.18]
    end

    subgraph "Backend Layer"
        B1[Java 21]
        B2[Spring Boot 3.2.2]
        B3[Maven 3.9]
        B4[Liquibase 4.25.1]
    end

    subgraph "Data Layer"
        D1[PostgreSQL 15]
        D2[Hibernate/JPA]
    end

    subgraph "Infrastructure"
        I1[Docker 24.x]
        I2[Docker Compose]
        I3[UFW Firewall]
    end

    A1 --> B1
    A1 --> B2
    B1 --> D1
    B2 --> D2
    D2 --> D1
```

## Environment Configuration

**Docker Compose Services:**
- PostgreSQL with health checks
- Java backends with Maven build + Spring profiles
- Shared Maven cache volume for faster rebuilds
- Isolated Docker network (greencity-net)

**Environment Variables Set:**
- Database: `DATASOURCE_URL`, `DATASOURCE_USER`, `DATASOURCE_PASSWORD`
- Profile: `PROFILE=docker`
- Azure Storage: Placeholder values (features disabled)
- Google APIs: Placeholder values (features disabled)
- Email: Placeholder values (features disabled)

## Quick Commands Reference

```bash
# Start all services
cd /home/igor/devops/project-green-city
docker compose up -d

# Start frontend (separate terminal)
source ~/.nvm/nvm.sh && nvm use 14
cd /home/igor/devops/project-green-city/greencity-frontend
npx ng serve --host 0.0.0.0 --port 4200 --disable-host-check

# View logs
docker logs greencity-backcore -f
docker logs greencity-backuser -f
docker logs greencity-postgres -f

# Stop all services
docker compose down

# Restart backends (after code changes)
docker compose restart backcore backuser
```

## Known Limitations (Development Mode)

| Feature | Status | Reason |
|---------|--------|--------|
| Email sending | Disabled | Placeholder credentials |
| Google OAuth | Disabled | Placeholder credentials |
| Azure Storage | Disabled | Placeholder credentials |
| Google Maps | Disabled | Placeholder API key |
| File uploads | Disabled | No storage configured |

## Verification & Health Checks

**Service Status:**

| Service | Port | Expected Response | Status |
|---------|------|-------------------|--------|
| PostgreSQL | 5434 | `pg_isready` accepts connections | OK |
| Backend Core | 8080 | HTTP 302 (redirect to Swagger) | OK |
| Backend User | 8060 | HTTP 302 (redirect to Swagger) | OK |
| Frontend | 4200 | HTTP 200 | OK |

**Quick Health Check Script:**
```bash
#!/bin/bash
# GreenCity Health Check

echo "=== GreenCity Health Check ==="

# Database
docker exec greencity-postgres pg_isready -U greencity -d greencity && echo "PostgreSQL: OK" || echo "PostgreSQL: FAILED"

# Backend Core
curl -s http://localhost:8080/swagger-ui.html -o /dev/null -w "%{http_code}" | grep -q 302 && echo "Backend Core: OK" || echo "Backend Core: FAILED"

# Backend User
curl -s http://localhost:8060/swagger-ui.html -o /dev/null -w "%{http_code}" | grep -q 302 && echo "Backend User: OK" || echo "Backend User: FAILED"

# Frontend
curl -s http://localhost:4200 -o /dev/null -w "%{http_code}" | grep -q 200 && echo "Frontend: OK" || echo "Frontend: FAILED"
```

**Available Test Suites:**

| Component | Test Framework | Command |
|-----------|----------------|---------|
| Backend Core | JUnit 5 + TestContainers | `docker exec greencity-backcore mvn test` |
| Backend User | JUnit 5 + TestContainers | `docker exec greencity-backuser mvn test` |
| Frontend | Karma/Jasmine (if configured) | `cd greencity-frontend && npm test` |

**API Endpoints for Manual Testing:**
- Swagger UI (Core): http://localhost:8080/swagger-ui.html
- Swagger UI (User): http://localhost:8060/swagger-ui.html
- Frontend App: http://localhost:4200

## Lessons Learned

1. **Code Formatter Required:** Maven build fails without running `mvn formatter:format` first
2. **Azure Env Vars Mandatory:** `AZURE_CONNECTION_STRING` required even with placeholders
3. **Shared Database:** Both backends use same PostgreSQL database with Liquibase migrations
4. **Service Dependencies:** BackCore calls BackUser for user validation
5. **Angular CLI:** Must use `npx ng serve` (CLI not globally installed)
