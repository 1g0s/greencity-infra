Greencity project
Project Overview
The main aim of “GreenCity” project is to teach people in a playful and challenging way to have an eco-friendly lifestyle. A user can view on the map places that have some eco-initiatives or suggest discounts for being environmentally aware (for instance, coffee shops that give a discount if a customer comes with their own cup). А user can start doing an environment-friendly habit and track their progress with a habit tracker.

There are three parts: backcore, backuser, and frontend

Key Features
Authentication and Registration: Users can create an account.

А user can start doing an environment-friendly habit and track their progress with a habit tracker…

Backcore Repository git@github.com:DevOps-ProjectLevel/greencity-backcore-1g0s.git

Backuser Repository git@github.com:DevOps-ProjectLevel/greencity-backuser-1g0s.git

Frontend Repository git@github.com:DevOps-ProjectLevel/greencity-frontend-1g0s.git

---

## Tasks

### Core Tasks (in order)
1. Setup a Webapp
2. Deploying a Containerized Web Application
3. Implement Infrastructure as Code
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

### Existing Infrastructure
- ✅ Frontend: Azure Pipelines CI/CD, Helm chart
- ✅ Backend: Spring profiles for Docker/dev/prod
- ⚠️ Missing: Backend Dockerfiles, docker-compose, backend Helm charts

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

### Task 4: CI/CD Pipeline

**Objective:** Implement automated CI/CD pipelines with GitHub Actions

**Deliverables:**
- [x] BackCore CI workflow - Maven build, JUnit tests, JaCoCo coverage
- [x] BackUser CI workflow - Maven build, JUnit tests, JaCoCo coverage
- [x] Docker build workflow - Build & push all 3 images to ghcr.io

**Note:** Frontend already has Azure Pipelines CI/CD (kept as-is)

**Status:** IMPLEMENTED (January 11, 2026)

> **Full Report:** [tasks/task-04-cicd.md](tasks/task-04-cicd.md)

---

### Progress Tracking

| Task | Status | Notes |
|------|--------|-------|
| 1. Setup Webapp | ✅ Complete | All services running, network accessible |
| 2. Containerization | ✅ Verified | All images built, tested, all 4 containers healthy |
| 3. Infrastructure as Code | ⏭️ Skipped | Merged into Task 8 (Cloud Migration) |
| 4. CI/CD Pipeline | ✅ Implemented | GitHub Actions + ghcr.io (backends), Azure Pipelines (frontend) |
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

---

## Task Completion Reports

All detailed task completion reports are maintained in the `tasks/` directory:

| Task | Report |
|------|--------|
| Task 1: Setup Webapp | [tasks/task-01-setup-webapp.md](tasks/task-01-setup-webapp.md) |
| Task 2: Containerization | [tasks/task-02-containerization.md](tasks/task-02-containerization.md) |
| Task 4: CI/CD Pipeline | [tasks/task-04-cicd.md](tasks/task-04-cicd.md) |
