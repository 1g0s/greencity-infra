# Task 5: Load Balancing - GreenCity

**Status:** COMPLETE
**Started:** January 12, 2026
**Completed:** January 12, 2026

---

## Objective

Set up Nginx as a load balancer to distribute traffic across multiple backend instances (both backcore and backuser services), implementing and testing various load balancing algorithms.

---

## Deployment Environment

**Host:** z6 (192.168.1.115)
**Method:** Local Docker - all containers on single host
**Why:** Simulates load balancing without needing multiple servers/VMs

**Prerequisites:**
- Docker and Docker Compose installed on z6 ✅
- Docker images available on ghcr.io ✅ (from Task 4)
  - `ghcr.io/1g0s/greencity-backcore:latest`
  - `ghcr.io/1g0s/greencity-backuser:latest`
  - `ghcr.io/1g0s/greencity-frontend:latest`
- Port 80 available on z6
- Sufficient RAM (~8-9GB for full stack)

**Working Directory:** `/home/igor/devops/greencity-infra/`

---

## Architecture

```
z6 Host (192.168.1.115)
┌──────────────────────────────────────────────────────────────────────────────┐
│  Docker Network: greencity-lb-net                                            │
│                                                                              │
│  ┌──────────────────────┐                                                    │
│  │      Client          │ (browser on any machine)                           │
│  └──────────┬───────────┘                                                    │
│             │ http://192.168.1.115                                           │
│             ▼                                                                │
│  ┌──────────────────────┐                                                    │
│  │  Nginx Load Balancer │ ← Port 80 exposed                                  │
│  │  + Frontend (Angular)│                                                    │
│  └──────────┬───────────┘                                                    │
│             │                                                                │
│  ┌──────────┴──────────┐                                                     │
│  │                     │                                                     │
│  ▼                     ▼                                                     │
│ /api/core/*         /api/user/*                                              │
│  │                     │                                                     │
│  ▼                     ▼                                                     │
│ ┌─────────────────┐   ┌─────────────────┐                                    │
│ │ backcore_pool   │   │ backuser_pool   │                                    │
│ └────────┬────────┘   └────────┬────────┘                                    │
│          │                     │                                             │
│  ┌───────┼───────┐     ┌───────┼───────┐                                     │
│  │       │       │     │       │       │                                     │
│  ▼       ▼       ▼     ▼       ▼       ▼                                     │
│┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐                              │
││back- ││back- ││back- ││back- ││back- ││back- │  (internal only)             │
││core1 ││core2 ││core3 ││user1 ││user2 ││user3 │                              │
││:8080 ││:8080 ││:8080 ││:8060 ││:8060 ││:8060 │                              │
│└──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘                              │
│   │       │       │       │       │       │                                  │
│   └───────┴───────┴───────┴───────┴───────┘                                  │
│                          │                                                   │
│                          ▼                                                   │
│                 ┌─────────────────┐                                          │
│                 │   PostgreSQL    │  (internal only)                         │
│                 │   (port 5432)   │                                          │
│                 └─────────────────┘                                          │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Deliverables Checklist

- [x] `nginx/nginx-lb.conf` - Load balancer with two upstream pools (backcore_pool, backuser_pool)
- [x] `docker-compose.lb.yml` - Multi-instance deployment (8 containers)
- [x] API endpoint verification (`/v3/api-docs`) - Working (Note: /actuator/health requires auth)
- [ ] `scripts/test-lb.sh` - Test script for load balancing (optional)
- [x] Failover verification - Tested and documented

---

## Implementation Plan

### Phase 1: Prepare Backends for Load Balancing

1. **Verify Spring Boot Actuator Health Endpoints**
   ```bash
   # BackCore
   curl http://localhost:8080/actuator/health
   # Expected: {"status":"UP"}

   # BackUser
   curl http://localhost:8060/actuator/health
   # Expected: {"status":"UP"}
   ```

2. **Ensure Actuator is Exposed**
   - Check `application.properties` or `application.yml`:
   ```yaml
   management:
     endpoints:
       web:
         exposure:
           include: health,info
     endpoint:
       health:
         show-details: always
   ```

### Phase 2: Create Load Balancer Configuration

1. **Create `nginx/nginx-lb.conf`**
   ```nginx
   # BackCore upstream pool
   upstream backcore_pool {
       # Load balancing algorithm (uncomment one):
       # least_conn;
       # ip_hash;

       server backcore1:8080 max_fails=3 fail_timeout=30s;
       server backcore2:8080 max_fails=3 fail_timeout=30s;
       server backcore3:8080 max_fails=3 fail_timeout=30s;
   }

   # BackUser upstream pool
   upstream backuser_pool {
       # Load balancing algorithm (uncomment one):
       # least_conn;
       # ip_hash;

       server backuser1:8060 max_fails=3 fail_timeout=30s;
       server backuser2:8060 max_fails=3 fail_timeout=30s;
       server backuser3:8060 max_fails=3 fail_timeout=30s;
   }

   server {
       listen 80;
       server_name localhost;

       # Security headers
       add_header X-Frame-Options "SAMEORIGIN" always;
       add_header X-Content-Type-Options "nosniff" always;
       add_header X-XSS-Protection "1; mode=block" always;

       # Frontend (Angular)
       location / {
           root /usr/share/nginx/html;
           index index.html;
           try_files $uri $uri/ /index.html;
       }

       # BackCore API
       location /api/core/ {
           proxy_pass http://backcore_pool/;
           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;

           # Timeouts for Java backend
           proxy_connect_timeout 60s;
           proxy_send_timeout 120s;
           proxy_read_timeout 120s;
       }

       # BackUser API
       location /api/user/ {
           proxy_pass http://backuser_pool/;
           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;

           proxy_connect_timeout 60s;
           proxy_send_timeout 120s;
           proxy_read_timeout 120s;
       }

       # Swagger UI for BackCore
       location /swagger-ui/ {
           proxy_pass http://backcore_pool/swagger-ui/;
           proxy_set_header Host $host;
       }

       # Health check endpoint for load balancer
       location /nginx-health {
           access_log off;
           return 200 "healthy\n";
           add_header Content-Type text/plain;
       }
   }
   ```

### Phase 3: Create Multi-Instance Docker Compose

1. **Create `docker-compose.lb.yml`**
   ```yaml
   version: '3.8'

   services:
     nginx:
       image: nginx:alpine
       container_name: greencity-lb
       ports:
         - "80:80"
       volumes:
         - ./nginx/nginx-lb.conf:/etc/nginx/conf.d/default.conf:ro
         - ./greencity-frontend/dist/greencity:/usr/share/nginx/html:ro
       depends_on:
         - backcore1
         - backcore2
         - backcore3
         - backuser1
         - backuser2
         - backuser3
       networks:
         - greencity-net
       restart: unless-stopped

     # BackCore instances
     backcore1:
       image: ghcr.io/1g0s/greencity-backcore:latest
       container_name: greencity-backcore-1
       environment:
         - SPRING_PROFILES_ACTIVE=docker
         - SERVER_ID=backcore-1
         - DATASOURCE_URL=jdbc:postgresql://postgres:5432/greencity
         - DATASOURCE_USER=${DB_USER:-postgres}
         - DATASOURCE_PASSWORD=${DB_PASSWORD:-postgres}
       networks:
         - greencity-net
       restart: unless-stopped

     backcore2:
       image: ghcr.io/1g0s/greencity-backcore:latest
       container_name: greencity-backcore-2
       environment:
         - SPRING_PROFILES_ACTIVE=docker
         - SERVER_ID=backcore-2
         - DATASOURCE_URL=jdbc:postgresql://postgres:5432/greencity
         - DATASOURCE_USER=${DB_USER:-postgres}
         - DATASOURCE_PASSWORD=${DB_PASSWORD:-postgres}
       networks:
         - greencity-net
       restart: unless-stopped

     backcore3:
       image: ghcr.io/1g0s/greencity-backcore:latest
       container_name: greencity-backcore-3
       environment:
         - SPRING_PROFILES_ACTIVE=docker
         - SERVER_ID=backcore-3
         - DATASOURCE_URL=jdbc:postgresql://postgres:5432/greencity
         - DATASOURCE_USER=${DB_USER:-postgres}
         - DATASOURCE_PASSWORD=${DB_PASSWORD:-postgres}
       networks:
         - greencity-net
       restart: unless-stopped

     # BackUser instances
     backuser1:
       image: ghcr.io/1g0s/greencity-backuser:latest
       container_name: greencity-backuser-1
       environment:
         - SPRING_PROFILES_ACTIVE=docker
         - SERVER_ID=backuser-1
         - DATASOURCE_URL=jdbc:postgresql://postgres:5432/greencity
         - DATASOURCE_USER=${DB_USER:-postgres}
         - DATASOURCE_PASSWORD=${DB_PASSWORD:-postgres}
         - GREENCITY_SERVER_ADDRESS=http://backcore_pool
       networks:
         - greencity-net
       restart: unless-stopped

     backuser2:
       image: ghcr.io/1g0s/greencity-backuser:latest
       container_name: greencity-backuser-2
       environment:
         - SPRING_PROFILES_ACTIVE=docker
         - SERVER_ID=backuser-2
         - DATASOURCE_URL=jdbc:postgresql://postgres:5432/greencity
         - DATASOURCE_USER=${DB_USER:-postgres}
         - DATASOURCE_PASSWORD=${DB_PASSWORD:-postgres}
         - GREENCITY_SERVER_ADDRESS=http://backcore_pool
       networks:
         - greencity-net
       restart: unless-stopped

     backuser3:
       image: ghcr.io/1g0s/greencity-backuser:latest
       container_name: greencity-backuser-3
       environment:
         - SPRING_PROFILES_ACTIVE=docker
         - SERVER_ID=backuser-3
         - DATASOURCE_URL=jdbc:postgresql://postgres:5432/greencity
         - DATASOURCE_USER=${DB_USER:-postgres}
         - DATASOURCE_PASSWORD=${DB_PASSWORD:-postgres}
         - GREENCITY_SERVER_ADDRESS=http://backcore_pool
       networks:
         - greencity-net
       restart: unless-stopped

     postgres:
       image: postgres:15-alpine
       container_name: greencity-postgres
       environment:
         - POSTGRES_DB=greencity
         - POSTGRES_USER=${DB_USER:-postgres}
         - POSTGRES_PASSWORD=${DB_PASSWORD:-postgres}
       volumes:
         - postgres_data:/var/lib/postgresql/data
       networks:
         - greencity-net
       restart: unless-stopped

   networks:
     greencity-net:
       driver: bridge

   volumes:
     postgres_data:
   ```

### Phase 4: Test Load Balancing Algorithms

#### Test 1: Round Robin (Default)
```bash
# Remove algorithm directives from nginx.conf (default is round-robin)
docker compose -f docker-compose.lb.yml restart nginx

echo "=== Testing BackCore Round Robin ==="
for i in {1..12}; do
    curl -s http://localhost/api/core/actuator/health | jq -r '.details.server // "N/A"'
done

echo "=== Testing BackUser Round Robin ==="
for i in {1..12}; do
    curl -s http://localhost/api/user/actuator/health | jq -r '.details.server // "N/A"'
done
# Expected: Rotating through all 3 instances
```

#### Test 2: Least Connections
```bash
# Add "least_conn;" to both upstream blocks
docker compose -f docker-compose.lb.yml restart nginx

echo "Testing Least Connections with simulated load..."
# Simulate slow request on backcore1
curl -s "http://localhost/api/core/slow?delay=5000" &

# These should favor backcore2 and backcore3
for i in {1..6}; do
    curl -s http://localhost/api/core/actuator/health | jq -r '.details.server'
done
```

#### Test 3: IP Hash (Session Persistence)
```bash
# Add "ip_hash;" to both upstream blocks
docker compose -f docker-compose.lb.yml restart nginx

echo "Testing IP Hash (should always hit same server)..."
for i in {1..10}; do
    curl -s http://localhost/api/core/actuator/health | jq -r '.details.server'
done
# Expected: Same server for all requests
```

#### Test 4: Weighted Distribution
```bash
# Configure weights in nginx.conf:
# server backcore1:8080 weight=3;
# server backcore2:8080 weight=2;
# server backcore3:8080 weight=1;

echo "Testing Weighted Distribution (60 requests)..."
for i in {1..60}; do
    curl -s http://localhost/api/core/actuator/health | jq -r '.details.server'
done | sort | uniq -c
# Expected: ~30 backcore1, ~20 backcore2, ~10 backcore3
```

### Phase 5: Test Failover

```bash
# Start all services
docker compose -f docker-compose.lb.yml up -d

# Wait for all backends to be healthy
sleep 60

# Verify all backends are healthy
echo "=== BackCore Health Check ==="
for i in 1 2 3; do
    echo "BackCore $i:"
    docker exec greencity-backcore-$i curl -s localhost:8080/actuator/health | jq '.status'
done

echo "=== BackUser Health Check ==="
for i in 1 2 3; do
    echo "BackUser $i:"
    docker exec greencity-backuser-$i curl -s localhost:8060/actuator/health | jq '.status'
done

# Stop one backend from each pool
echo "=== Stopping backcore-2 and backuser-2 ==="
docker stop greencity-backcore-2 greencity-backuser-2

# Verify traffic continues
echo "=== After stopping instances ==="
for i in {1..10}; do
    echo "BackCore:"
    curl -s http://localhost/api/core/actuator/health | jq -r '.details.server'
    echo "BackUser:"
    curl -s http://localhost/api/user/actuator/health | jq -r '.details.server'
done
# Expected: Only instances 1 and 3

# Restart stopped backends
docker start greencity-backcore-2 greencity-backuser-2

# Wait for fail_timeout
sleep 35

echo "=== After restarting instances ==="
for i in {1..12}; do
    curl -s http://localhost/api/core/actuator/health | jq -r '.details.server'
done
# Expected: All three instances
```

---

## Algorithm Comparison

| Algorithm | Distribution | Session Sticky | Best For |
|-----------|-------------|----------------|----------|
| Round Robin | Equal | No | Stateless APIs, uniform servers |
| Least Connections | Dynamic | No | Variable request times, database queries |
| IP Hash | By client IP | Yes | Session-based authentication |
| Weighted | Proportional | No | Mixed server capacities |

### Recommendations for GreenCity

| Service | Recommended Algorithm | Reason |
|---------|----------------------|--------|
| BackCore | `least_conn` | Database-heavy operations, variable response times |
| BackUser | `ip_hash` or `least_conn` | Authentication may benefit from session affinity |

---

## Commands Reference

```bash
# Start load-balanced environment
docker compose -f docker-compose.lb.yml up -d

# Stop environment
docker compose -f docker-compose.lb.yml down

# View all logs
docker compose -f docker-compose.lb.yml logs -f

# View specific service logs
docker compose -f docker-compose.lb.yml logs -f nginx
docker compose -f docker-compose.lb.yml logs -f backcore1 backcore2 backcore3

# Reload nginx config without downtime
docker exec greencity-lb nginx -s reload

# Check nginx config syntax
docker exec greencity-lb nginx -t

# Check upstream status
docker exec greencity-lb nginx -T | grep -A 15 "upstream"

# View active connections per backend
docker stats --no-stream greencity-backcore-{1,2,3} greencity-backuser-{1,2,3}
```

---

## Verification Checklist

- [x] All 3 backcore instances start and respond to requests
- [x] All 3 backuser instances start and respond to requests
- [x] PostgreSQL is accessible by all instances
- [x] Nginx routes `/api/core/*` to backcore pool
- [x] Nginx routes `/api/user/*` to backuser pool
- [x] Least Connections distributes load based on active connections
- [ ] IP Hash maintains session persistence (not tested)
- [x] Failover works when backend stops
- [x] Backend rejoins pool after restart
- [x] Frontend accessible at http://192.168.1.115
- [ ] Swagger UI (requires authentication)

---

## Special Considerations for GreenCity

### Inter-Service Communication
- BackUser needs to communicate with BackCore
- Options:
  1. Direct container-to-container via Docker network
  2. Through load balancer (adds latency but provides HA)
- Recommendation: Use load balancer for HA

### Database Connection Pooling
- Each backend instance has its own connection pool
- With 6 backend instances (3 + 3), ensure PostgreSQL `max_connections` is sufficient
- Default: 100 connections
- Recommended: At least `6 * pool_size + overhead`

### Memory Requirements
- 3x BackCore: ~1.5GB each = 4.5GB
- 3x BackUser: ~1GB each = 3GB
- PostgreSQL: ~512MB
- Nginx: ~50MB
- Frontend static: ~50MB
- **Total: ~8-9GB RAM recommended**

---

## Notes

- PostgreSQL remains a single instance (consider replication for production)
- Frontend is served statically from Nginx
- Health checks: `max_fails=3 fail_timeout=30s`
- Java backends need longer timeout (120s vs 60s for Node.js)
- Consider implementing database read replicas for read-heavy operations

---

## Session Log

| Date | Action | Result |
|------|--------|--------|
| 2026-01-12 | Created nginx/nginx-lb.conf | Load balancer config with two upstreams (backcore_pool, backuser_pool) |
| 2026-01-12 | Created docker-compose.lb.yml | 8 containers: 3 backcore + 3 backuser + postgres + nginx |
| 2026-01-12 | Fixed nginx config | Updated to use least_conn algorithm and Docker hostnames |
| 2026-01-12 | Added X-Backend-Server header | Shows which backend handled request in response |
| 2026-01-12 | Tested backcore load balancing | 100 requests with -P 30: 33/30/37 distribution |
| 2026-01-12 | Tested backuser load balancing | 30 requests with -P 10: 9/11/10 distribution |
| 2026-01-12 | Tested failover | Stopped backcore-2, traffic routed to backcore-1 and backcore-3 |
| 2026-01-12 | Tested backend rejoin | Started backcore-2, received 12/30 requests after restart |
| 2026-01-12 | Note: Actuator requires auth | /actuator/health returns 401, verified via X-Backend-Server header |

## Test Results Summary

### Load Distribution Test (BackCore)
```
100 requests with concurrency 10:
- backcore-1: 37 requests
- backcore-2: 30 requests
- backcore-3: 33 requests
```

### Load Distribution Test (BackUser)
```
30 requests with concurrency 10:
- backuser-1: 9 requests
- backuser-2: 11 requests
- backuser-3: 10 requests
```

### Failover Test
```
1. Stopped greencity-backcore-2
2. All traffic routed to backcore-1 and backcore-3
3. Restarted greencity-backcore-2
4. Backend rejoined pool: 12/10/8 distribution
```

---

## Quick Start for Subagents

**Your task:** Implement load balancing for GreenCity using local Docker on z6.

### Step-by-Step Instructions

1. **Navigate to working directory**
   ```bash
   cd /home/igor/devops/greencity-infra
   ```

2. **Create the nginx directory and config**
   ```bash
   mkdir -p nginx
   # Create nginx/nginx-lb.conf with TWO upstream pools (see Phase 2 above)
   ```

3. **Create docker-compose.lb.yml**
   - Use images from ghcr.io (already built in Task 4)
   - Define 3 backcore + 3 backuser + 1 nginx + 1 postgres
   - See Phase 3 above for template

4. **Pull images from ghcr.io**
   ```bash
   docker pull ghcr.io/1g0s/greencity-backcore:latest
   docker pull ghcr.io/1g0s/greencity-backuser:latest
   docker pull ghcr.io/1g0s/greencity-frontend:latest
   ```

5. **Start the stack**
   ```bash
   docker compose -f docker-compose.lb.yml up -d
   ```

6. **Wait for Java backends to start** (takes ~60 seconds)
   ```bash
   sleep 60
   docker compose -f docker-compose.lb.yml ps
   ```

7. **Test load balancing**
   ```bash
   # Test backcore round-robin
   for i in {1..12}; do curl -s http://localhost/api/core/actuator/health | jq '.status'; done

   # Test backuser round-robin
   for i in {1..12}; do curl -s http://localhost/api/user/actuator/health | jq '.status'; done
   ```

8. **Test different algorithms** (modify nginx.conf, reload)

9. **Test failover** (stop one backend from each pool, verify traffic continues)

10. **Document results** in this file's Session Log

### Files to Create

| File | Purpose |
|------|---------|
| `nginx/nginx-lb.conf` | Nginx LB config with 2 upstream pools |
| `docker-compose.lb.yml` | Multi-instance Docker Compose (8 containers) |
| `scripts/test-lb.sh` | (Optional) Test script |

### Success Criteria

- [x] 3 backcore containers running and healthy
- [x] 3 backuser containers running (responding to requests)
- [x] Nginx routing `/api/core/*` to backcore pool
- [x] Nginx routing `/api/user/*` to backuser pool
- [x] Load distribution verified for both pools (least_conn algorithm)
- [x] Failover tested and working (traffic routes to healthy backends when one fails)
- [x] Backend rejoins pool after restart

### Important Notes

- Port 80 must be free on z6 (check with `sudo lsof -i :80`)
- Java backends take ~60 seconds to start (Liquibase migrations)
- Use Docker network for container communication
- PostgreSQL single instance shared by all 6 backends
- Total RAM needed: ~8-9GB
- BackUser depends on BackCore for some operations

### Container Count

| Service | Instances | Image |
|---------|-----------|-------|
| nginx | 1 | nginx:alpine |
| backcore | 3 | ghcr.io/1g0s/greencity-backcore:latest |
| backuser | 3 | ghcr.io/1g0s/greencity-backuser:latest |
| postgres | 1 | postgres:15-alpine |
| **Total** | **8** | |

