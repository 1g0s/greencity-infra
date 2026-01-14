Greencity project
Project Overview
The main aim of “GreenCity” project is to teach people in a playful and challenging way to have an eco-friendly lifestyle. A user can view on the map places that have some eco-initiatives or suggest discounts for being environmentally aware (for instance, coffee shops that give a discount if a customer comes with their own cup). А user can start doing an environment-friendly habit and track their progress with a habit tracker.

There are three parts: backcore, backuser, and frontend

Key Features
Authentication and Registration: Users can create an account.

A user can start doing an environment-friendly habit and track their progress with a habit tracker.

## Repositories

| Repository | Purpose | URL |
|------------|---------|-----|
| **greencity-infra** | Infrastructure & DevOps | `git@github.com:1g0s/greencity-infra.git` |
| **greencity-backcore** | Java Backend Core API | `git@github.com:DevOps-ProjectLevel/greencity-backcore-1g0s.git` |
| **greencity-backuser** | Java Backend User API | `git@github.com:DevOps-ProjectLevel/greencity-backuser-1g0s.git` |
| **greencity-frontend** | Angular Frontend | `git@github.com:DevOps-ProjectLevel/greencity-frontend-1g0s.git` |

---

## Tasks

### Core Tasks (in order)
1. Setup a Webapp
2. Deploying a Containerized Web Application
3. Implement Infrastructure as Code (Vagrant + Ansible)
4. Implement a Continuous Integration/Continuous Delivery
5. Setup Load Balancing for Webapp
   - Deploy multiple backend instances (backcore and backuser)
   - Set up Nginx as a load balancer
   - Configure and test different load-balancing algorithms (round-robin, least_conn, ip_hash)
   - Implement health checks and failover
6. Implement Automatisation Setup a Webapp
7. Orchestration Web Application via k8s
8. Migrate an Application to the Cloud

### Additional Tasks
- Set up monitoring tools for application performance and infrastructure health
- Configure logging mechanisms for tracking application and system logs
- Monitor resource usage and plan for scalability
- Implement CCI (Continuous Code Inspection)
- Artifact Management

---

## Implementation Plan

### Project Architecture Summary

| Component | Technology | Port |
|-----------|-----------|------|
| **greencity-backcore** | Java 21, Spring Boot 3.2.2, Maven | 8080 |
| **greencity-backuser** | Java 21, Spring Boot 3.2.2, Maven | 8060 |
| **greencity-frontend** | Angular 9.1.15, TypeScript, Node 14 | 80/4200 |
| **Database** | PostgreSQL | 5432 |
| **Storage** | Azure Blob / Google Cloud Storage | - |

### Infrastructure Repository Structure

```
greencity-infra/
├── .github/workflows/
│   └── docker.yml           # Docker build & push to ghcr.io
├── docker-compose.yml       # Development environment
├── docker-compose.prod.yml  # Production deployment (single instance)
├── docker-compose.lb.yml    # Load-balanced deployment (8 containers)
├── nginx/
│   └── nginx-lb.conf        # Nginx load balancer config
├── .env.prod.example        # Environment template
├── epic.md                  # This file
├── README.md                # Quick start guide
└── tasks/                   # Task completion reports
    ├── task-01-setup-webapp.md
    ├── task-02-containerization.md
    ├── task-04-cicd.md
    └── task-05-load-balancing.md
```

### Component Repos Include
- ✅ Frontend: GitHub Actions CI, Azure Pipelines CD, Helm chart
- ✅ Backend: Spring profiles for Docker/dev/prod
- ✅ Dockerfiles (all 3 repos)
- ✅ CI workflows (.github/workflows/ci.yml) for all 3 repos

---

### Task 1: Setup a Webapp

**Objective:** Get all three components running locally

**Steps:**
1. **Database Setup**
   - Deploy PostgreSQL (Docker or local)
   - Create database `greencity`
   - Run Liquibase migrations (auto on startup)

2. **Backend Core Service**
   ```bash
   cd greencity-backcore
   mvn clean package -DskipTests
   java -jar ./core/target/core.jar --spring.profiles.active=dev
   ```

3. **Backend User Service**
   ```bash
   cd greencity-backuser
   mvn clean package -DskipTests
   java -jar ./core/target/core.jar --spring.profiles.active=dev
   ```

4. **Frontend**
   ```bash
   cd greencity-frontend
   npm install
   ng serve --host 0.0.0.0
   ```

**Environment Variables Required:**
```bash
# Database
DATASOURCE_URL=jdbc:postgresql://localhost:5432/greencity
DATASOURCE_USER=postgres
DATASOURCE_PASSWORD=<password>

# Email (Gmail)
EMAIL_ADDRESS=<gmail>
EMAIL_PASSWORD=<app-password>

# Google APIs
GOOGLE_CLIENT_ID=<client-id>
GOOGLE_API_KEY=<api-key>
```

**Deliverables:**
- [x] Local development environment running
- [x] All services communicating
- [x] Database with initial data

**Status:** COMPLETED (January 6, 2026)

> **Full Report:** [tasks/task-01-setup-webapp.md](tasks/task-01-setup-webapp.md)

---

### Task 2: Deploying a Containerized Web Application

**Objective:** Containerize all services with production-ready Dockerfiles

**Deliverables:**
- [x] Dockerfile (backcore) - Multi-stage Maven/JRE build
- [x] Dockerfile (backuser) - Multi-stage Maven/JRE build
- [x] Dockerfile (frontend) - Multi-stage Angular/Nginx build
- [x] nginx.conf - API proxy, SPA routing, security headers
- [x] .dockerignore files - For all 3 repos
- [x] docker-compose.prod.yml - Production configuration
- [x] .env.prod.example - Environment template

**Status:** ✅ VERIFIED COMPLETE (January 11, 2026)

> **Full Report:** [tasks/task-02-containerization.md](tasks/task-02-containerization.md)

---

### Task 3: Infrastructure as Code (Vagrant + Ansible)

**Objective:** Provision clean VM infrastructure and deploy the load-balanced application using IaC tools

**Deployment:** VirtualBox VMs on z6, provisioned by Vagrant, configured by Ansible

**Architecture:**
```
z6 Host (192.168.1.115)
┌────────────────────────────────────────────────────────────────┐
│  VirtualBox                                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  greencity-vm (Ubuntu 22.04)                             │  │
│  │  IP: 192.168.56.20                                       │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Docker                                            │  │  │
│  │  │  ├── nginx (load balancer) :80                     │  │  │
│  │  │  ├── backcore1, backcore2, backcore3 :8080         │  │  │
│  │  │  ├── backuser1, backuser2, backuser3 :8060         │  │  │
│  │  │  └── postgres :5432                                │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

**Requirements:**
- Vagrant 2.x with VirtualBox provider
- Ansible 2.9+ on z6 (control node)
- Clean Ubuntu 22.04 base box
- SSH key-based authentication

**Deliverables:**
- [ ] `vagrant/Vagrantfile` - VM definition (Ubuntu 22.04, 2 CPU, 8GB RAM)
- [ ] `ansible/inventory.yml` - Host definitions
- [ ] `ansible/playbook.yml` - Main deployment playbook
- [ ] `ansible/roles/docker/` - Install Docker and Docker Compose
- [ ] `ansible/roles/app/` - Deploy application stack
- [ ] `ansible/group_vars/` - Environment variables and secrets
- [ ] `README-iac.md` - Setup instructions

**Implementation Steps:**

1. **Create Vagrantfile**
   ```ruby
   Vagrant.configure("2") do |config|
     config.vm.box = "ubuntu/jammy64"
     config.vm.hostname = "greencity-vm"
     config.vm.network "private_network", ip: "192.168.56.20"
     config.vm.provider "virtualbox" do |vb|
       vb.memory = "8192"
       vb.cpus = 2
     end
     config.vm.provision "ansible" do |ansible|
       ansible.playbook = "../ansible/playbook.yml"
     end
   end
   ```

2. **Create Ansible Playbook**
   - Install Docker and Docker Compose
   - Copy docker-compose.lb.yml and nginx config
   - Pull images from ghcr.io
   - Start the application stack (8 containers)

3. **Verify Deployment**
   ```bash
   vagrant up
   curl http://192.168.56.20/api/core/actuator/health
   curl http://192.168.56.20/api/user/actuator/health
   ```

**Verification Commands:**
```bash
# Start VM and provision
cd vagrant && vagrant up

# SSH into VM
vagrant ssh

# Check application status
curl http://192.168.56.20/nginx-health
curl http://192.168.56.20/api/core/v3/api-docs
curl http://192.168.56.20/api/user/v3/api-docs

# Destroy and recreate (test reproducibility)
vagrant destroy -f && vagrant up
```

**Status:** ✅ COMPLETE (January 14, 2026)

> **Full Report:** [tasks/task-03-iac.md](tasks/task-03-iac.md)

---

### Task 4: CI/CD Pipeline

**Objective:** Implement automated CI/CD pipelines with GitHub Actions

**Deliverables:**
- [x] BackCore CI workflow - Maven build, JUnit tests, JaCoCo coverage
- [x] BackUser CI workflow - Maven build, JUnit tests, JaCoCo coverage
- [x] Frontend CI workflow - npm ci, lint, stylelint, build, test
- [x] Docker build workflow - Build & push all 3 images to ghcr.io
- [x] CHECKOUT_TOKEN secret - Cross-repo access for Docker builds
- [x] Code formatting fixes - All Java files pass formatter validation

**Container Images (ghcr.io):**
```
ghcr.io/1g0s/greencity-backcore:latest
ghcr.io/1g0s/greencity-backuser:latest
ghcr.io/1g0s/greencity-frontend:latest
```

**Note:** Frontend also has Azure Pipelines for AKS deployment (kept as-is)

**Status:** ✅ VERIFIED COMPLETE (January 12, 2026)

> **Full Report:** [tasks/task-04-cicd.md](tasks/task-04-cicd.md)

---

### Task 5: Load Balancing

**Objective:** Set up Nginx load balancer to distribute traffic across multiple backend instances

**Deployment:** Local Docker on z6 (192.168.1.115) - all containers on single host

**Architecture:**
```
z6 Host (192.168.1.115)
┌──────────────────────────────────────────────────────────────────────────┐
│  Docker Network: greencity-lb-net                                        │
│                                                                          │
│                      ┌─────────────────┐                                 │
│                      │   Nginx LB      │ ← Port 80 exposed to host       │
│                      │   (port 80)     │                                 │
│                      └────────┬────────┘                                 │
│                               │                                          │
│              ┌────────────────┴────────────────┐                         │
│              │                                 │                         │
│              ▼                                 ▼                         │
│     ┌────────────────┐                ┌────────────────┐                 │
│     │  /api/core/*   │                │  /api/user/*   │                 │
│     │ backcore_pool  │                │ backuser_pool  │                 │
│     └───────┬────────┘                └───────┬────────┘                 │
│             │                                 │                          │
│  ┌──────────┼──────────┐       ┌──────────────┼──────────────┐           │
│  │          │          │       │              │              │           │
│  ▼          ▼          ▼       ▼              ▼              ▼           │
│┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐              │
││backcore││backcore││backcore││backuser││backuser││backuser│              │
││   1    ││   2    ││   3    ││   1    ││   2    ││   3    │              │
││ :8080  ││ :8080  ││ :8080  ││ :8060  ││ :8060  ││ :8060  │              │
│└───┬────┘└───┬────┘└───┬────┘└───┬────┘└───┬────┘└───┬────┘              │
│    │         │         │         │         │         │                   │
│    └─────────┴─────────┴─────────┴─────────┴─────────┘                   │
│                               │                                          │
│                               ▼                                          │
│                      ┌─────────────────┐                                 │
│                      │   PostgreSQL    │ ← Port 5432 (internal)          │
│                      │   (port 5432)   │                                 │
│                      └─────────────────┘                                 │
└──────────────────────────────────────────────────────────────────────────┘
```

**Requirements:**
- Nginx as reverse proxy and load balancer
- Multiple instances for both backcore (3) and backuser (3)
- Health checks with Spring Boot Actuator (`/actuator/health`)
- Session persistence option for stateful scenarios
- Separate upstream pools for each backend service

**Deliverables:**
- [x] `nginx/nginx-lb.conf` - Load balancer configuration with two upstreams
- [x] `docker-compose.lb.yml` - Multi-instance deployment (8 containers)
- [x] Health check endpoint verification (via X-Backend-Server header)
- [x] Load distribution tested with parallel requests
- [x] Failover tested and verified

**Load Balancing Algorithms to Test:**

| Algorithm | Use Case | Configuration |
|-----------|----------|---------------|
| Round Robin | Default, equal distribution | (default) |
| Least Connections | Uneven request processing times | `least_conn;` |
| IP Hash | Session persistence | `ip_hash;` |
| Weighted | Servers with different capacities | `server backcore1:8080 weight=3;` |

**Implementation Steps:**

1. **Create Load Balancer Config with Two Upstreams**
   ```nginx
   upstream backcore_servers {
       least_conn;
       server backcore1:8080 max_fails=3 fail_timeout=30s;
       server backcore2:8080 max_fails=3 fail_timeout=30s;
       server backcore3:8080 max_fails=3 fail_timeout=30s;
   }

   upstream backuser_servers {
       least_conn;
       server backuser1:8060 max_fails=3 fail_timeout=30s;
       server backuser2:8060 max_fails=3 fail_timeout=30s;
       server backuser3:8060 max_fails=3 fail_timeout=30s;
   }

   server {
       location /api/core/ {
           proxy_pass http://backcore_servers;
       }
       location /api/user/ {
           proxy_pass http://backuser_servers;
       }
   }
   ```

2. **Update Docker Compose for Multiple Instances**
   - Define explicit instances in docker-compose.lb.yml
   - Use Docker Compose `deploy.replicas` or separate service definitions

3. **Configure Spring Boot Actuator Health Checks**
   - Ensure `/actuator/health` endpoint is exposed
   - Configure Nginx to use health checks

4. **Test Each Algorithm**
   - Round Robin: Verify equal distribution
   - Least Connections: Simulate slow database queries
   - IP Hash: Verify session stickiness

**Verification Commands:**
```bash
# Test backcore load distribution
for i in {1..10}; do curl -s http://localhost/api/core/actuator/health | jq; done

# Test backuser load distribution
for i in {1..10}; do curl -s http://localhost/api/user/actuator/health | jq; done

# Check Nginx upstream status
docker exec nginx cat /var/log/nginx/access.log | tail -20

# Simulate backend failure
docker stop greencity-backcore-2
# Verify traffic redirects to healthy backends
```

**Status:** ✅ COMPLETE (January 12, 2026)

> **Full Report:** [tasks/task-05-load-balancing.md](tasks/task-05-load-balancing.md)

---

### Progress Tracking

| Task | Status | Notes |
|------|--------|-------|
| 1. Setup Webapp | ✅ Complete | All services running, network accessible |
| 2. Containerization | ✅ Verified | All images built, tested, all 4 containers healthy |
| 3. Infrastructure as Code | ✅ Complete | Vagrant + Ansible, VM at 192.168.10.20 |
| 4. CI/CD Pipeline | ✅ Verified | All CI passing, Docker images on ghcr.io |
| 5. Load Balancing | ✅ Complete | 3+3 backend instances, dual upstream nginx LB, failover working |
| 6. Automation | ⬜ Not Started | |
| 7. Kubernetes | ⬜ Not Started | Frontend has Helm chart |
| 8. Cloud Migration | ⬜ Not Started | |
| Monitoring | ⬜ Not Started | |
| Logging | ⬜ Not Started | |
| CCI | ⬜ Not Started | SonarQube configured |
| Artifact Management | ⬜ Not Started | |

---

## Session Log

| Date | Task | Summary |
|------|------|---------|
| 2026-01-06 | Task 1 | Set up Docker network, PostgreSQL, Java backends, Angular frontend |
| 2026-01-06 | Task 2 | Created Dockerfiles, nginx.conf, docker-compose.prod.yml |
| 2026-01-11 | Task 2 | Built all :prod images, verified full stack (4 containers healthy) |
| 2026-01-11 | Task 4 | Created GitHub Actions CI/CD workflows for backcore, backuser, and Docker builds |
| 2026-01-12 | Infra | Created infrastructure repo with git history and tags for Tasks 1, 2, 4 |
| 2026-01-12 | Task 2,4 | Pushed Dockerfiles, CI workflows to component repos (DevOps-ProjectLevel) |
| 2026-01-12 | Task 4 | Fixed CI builds: applied code formatting (47 files backcore, 1 file backuser) |
| 2026-01-12 | Task 4 | Fixed Docker builds: added CHECKOUT_TOKEN, fixed frontend package-lock.json |
| 2026-01-12 | Task 4 | Verified all CI/CD: BackCore CI ✅, BackUser CI ✅, Docker builds ✅ (3 images on ghcr.io) |
| 2026-01-12 | Task 4 | Added Frontend CI workflow (npm ci, lint, stylelint, build, test) - all passing |
| 2026-01-12 | Task 5 | Created nginx-lb.conf with dual upstreams (backcore_pool, backuser_pool) |
| 2026-01-12 | Task 5 | Created docker-compose.lb.yml with 8 containers (3 backcore + 3 backuser + postgres + nginx) |
| 2026-01-12 | Task 5 | Tested load distribution: backcore 37/30/33, backuser 9/11/10 with concurrent requests |
| 2026-01-12 | Task 5 | Tested failover: stopped backcore-2, traffic routed to healthy backends |
| 2026-01-12 | Task 5 | Verified backend rejoin: restarted backcore-2, received traffic (12/10/8 distribution) |
| 2026-01-14 | Task 3 | Created Vagrant + Ansible IaC structure (12 files, ~745 lines) |
| 2026-01-14 | Task 3 | VM provisioned at 192.168.10.20 with 8 containers (3 backcore, 3 backuser, postgres, nginx) |
| 2026-01-14 | Task 3 | Verified: nginx health, load balancing, reproducibility (vagrant destroy && vagrant up) |

---

## Task Completion Reports

All detailed task completion reports are maintained in the `tasks/` directory:

| Task | Report |
|------|--------|
| Task 1: Setup Webapp | [tasks/task-01-setup-webapp.md](tasks/task-01-setup-webapp.md) |
| Task 2: Containerization | [tasks/task-02-containerization.md](tasks/task-02-containerization.md) |
| Task 3: Infrastructure as Code | [tasks/task-03-iac.md](tasks/task-03-iac.md) |
| Task 4: CI/CD Pipeline | [tasks/task-04-cicd.md](tasks/task-04-cicd.md) |
| Task 5: Load Balancing | [tasks/task-05-load-balancing.md](tasks/task-05-load-balancing.md) |
