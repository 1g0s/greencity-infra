# GreenCity Infrastructure

DevOps infrastructure and orchestration for the GreenCity project.

## Project Overview

GreenCity teaches people to have an eco-friendly lifestyle through gamification. Users can view eco-initiatives on a map, track environmental habits, and earn rewards.

## Component Repositories

| Component | Repository | Technology |
|-----------|------------|------------|
| Backend Core | [greencity-backcore](https://github.com/DevOps-ProjectLevel/greencity-backcore-1g0s) | Java 21, Spring Boot |
| Backend User | [greencity-backuser](https://github.com/DevOps-ProjectLevel/greencity-backuser-1g0s) | Java 21, Spring Boot |
| Frontend | [greencity-frontend](https://github.com/DevOps-ProjectLevel/greencity-frontend-1g0s) | Angular 9 |

## Infrastructure Files

```
├── docker-compose.yml          # Development environment
├── docker-compose.prod.yml     # Production deployment
├── .env.prod.example           # Environment template
├── .github/workflows/          # CI/CD workflows
│   └── docker.yml              # Docker build & push
├── epic.md                     # Project tasks & progress
└── tasks/                      # Task completion reports
    ├── task-01-setup-webapp.md
    ├── task-02-containerization.md
    └── task-04-cicd.md
```

## Quick Start

### Development
```bash
# Clone component repos
git clone git@github.com:DevOps-ProjectLevel/greencity-backcore-1g0s.git greencity-backcore
git clone git@github.com:DevOps-ProjectLevel/greencity-backuser-1g0s.git greencity-backuser
git clone git@github.com:DevOps-ProjectLevel/greencity-frontend-1g0s.git greencity-frontend

# Start all services
docker compose up -d

# Or run frontend natively
cd greencity-frontend && npm install && npx ng serve --host 0.0.0.0
```

### Production
```bash
# Build images
docker build -t greencity-backcore:prod ./greencity-backcore
docker build -t greencity-backuser:prod ./greencity-backuser
docker build -t greencity-frontend:prod ./greencity-frontend

# Create environment file
cp .env.prod.example .env.prod
# Edit .env.prod with real values

# Run production stack
docker compose -f docker-compose.prod.yml up -d
```

## Task Progress

| Task | Status | Tag |
|------|--------|-----|
| 1. Setup Webapp | ✅ Complete | `task-1` |
| 2. Containerization | ✅ Complete | `task-2` |
| 3. Infrastructure as Code | ⏭️ Skipped | - |
| 4. CI/CD Pipeline | ✅ Complete | `task-4` |
| 5. Load Balancing | ⬜ Pending | - |
| 6. Automation | ⬜ Pending | - |
| 7. Kubernetes | ⬜ Pending | - |
| 8. Cloud Migration | ⬜ Pending | - |

## Container Images

Production images are pushed to GitHub Container Registry:

```
ghcr.io/<owner>/greencity-backcore:latest
ghcr.io/<owner>/greencity-backuser:latest
ghcr.io/<owner>/greencity-frontend:latest
```

## Documentation

- [epic.md](epic.md) - Full project overview and task details
- [tasks/](tasks/) - Individual task completion reports
