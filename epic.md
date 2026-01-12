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
   - Deploy couple servers
   - Set up Apache or Nginx as a load balancer
   - Try different load-balancing algorithms and options
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
├── docker-compose.prod.yml  # Production deployment
├── .env.prod.example        # Environment template
├── epic.md                  # This file
├── README.md                # Quick start guide
└── tasks/                   # Task completion reports
    ├── task-01-setup-webapp.md
    ├── task-02-containerization.md
    └── task-04-cicd.md
```

### Component Repos Include
- ✅ Frontend: Azure Pipelines CI/CD, Helm chart
- ✅ Backend: Spring profiles for Docker/dev/prod
- ✅ Dockerfiles (all 3 repos)
- ✅ CI workflows (.github/workflows/ci.yml) for backends

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

**Objective:** Provision local development/test infrastructure using Infrastructure as Code tools

**Requirements:**
- Vagrant for VM provisioning (VirtualBox provider)
- Ansible for configuration management and application deployment
- Reproducible local environment that mirrors production

**Deliverables:**
- [ ] Vagrantfile - Define VM(s) for the application stack
- [ ] Ansible inventory - Host definitions
- [ ] Ansible playbooks - Provision and deploy application
  - [ ] Install Docker, Java 21, and dependencies
  - [ ] Deploy PostgreSQL container
  - [ ] Deploy backcore container
  - [ ] Deploy backuser container
  - [ ] Deploy frontend container
- [ ] README for IaC setup instructions

**Infrastructure:**
| VM | Purpose | Resources |
|----|---------|-----------|
| greencity-vm | Full stack deployment | 2 CPU, 6GB RAM |

**Status:** ⬜ Not Started

---

### Task 4: CI/CD Pipeline

**Objective:** Implement automated CI/CD pipelines with GitHub Actions

**Deliverables:**
- [x] BackCore CI workflow - Maven build, JUnit tests, JaCoCo coverage
- [x] BackUser CI workflow - Maven build, JUnit tests, JaCoCo coverage
- [x] Docker build workflow - Build & push all 3 images to ghcr.io
- [x] CHECKOUT_TOKEN secret - Cross-repo access for Docker builds
- [x] Code formatting fixes - All Java files pass formatter validation

**Container Images (ghcr.io):**
```
ghcr.io/1g0s/greencity-backcore:latest
ghcr.io/1g0s/greencity-backuser:latest
ghcr.io/1g0s/greencity-frontend:latest
```

**Note:** Frontend already has Azure Pipelines CI/CD (kept as-is)

**Status:** ✅ VERIFIED COMPLETE (January 12, 2026)

> **Full Report:** [tasks/task-04-cicd.md](tasks/task-04-cicd.md)

---

### Progress Tracking

| Task | Status | Notes |
|------|--------|-------|
| 1. Setup Webapp | ✅ Complete | All services running, network accessible |
| 2. Containerization | ✅ Verified | All images built, tested, all 4 containers healthy |
| 3. Infrastructure as Code | ⬜ Not Started | Vagrant + Ansible local provisioning |
| 4. CI/CD Pipeline | ✅ Verified | All CI passing, Docker images on ghcr.io |
| 5. Load Balancing | ⬜ Not Started | |
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

---

## Task Completion Reports

All detailed task completion reports are maintained in the `tasks/` directory:

| Task | Report |
|------|--------|
| Task 1: Setup Webapp | [tasks/task-01-setup-webapp.md](tasks/task-01-setup-webapp.md) |
| Task 2: Containerization | [tasks/task-02-containerization.md](tasks/task-02-containerization.md) |
| Task 4: CI/CD Pipeline | [tasks/task-04-cicd.md](tasks/task-04-cicd.md) |
