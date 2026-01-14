# Task 3: Infrastructure as Code (Vagrant + Ansible)

**Status:** COMPLETE
**Date:** January 14, 2026
**Duration:** ~2 hours

---

## Objective

Provision a clean Ubuntu VM using Vagrant and deploy the full GreenCity application stack (8 containers with load balancing) using Ansible. This demonstrates Infrastructure as Code principles with reproducible, automated deployments.

---

## Architecture

```
z6 Host (192.168.1.115)
┌────────────────────────────────────────────────────────────────┐
│  VirtualBox                                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  greencity-vm (Ubuntu 22.04)                             │  │
│  │  IP: 192.168.10.20                                       │  │
│  │  RAM: 8GB, CPUs: 2                                       │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Docker (8 containers)                             │  │  │
│  │  │  ├── nginx (load balancer + frontend) :80          │  │  │
│  │  │  ├── backcore1, backcore2, backcore3 :8080         │  │  │
│  │  │  ├── backuser1, backuser2, backuser3 :8060         │  │  │
│  │  │  └── postgres :5432                                │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

---

## Deliverables

### Directory Structure Created

```
greencity-infra/
├── vagrant/
│   └── Vagrantfile                 # VM definition
│
└── ansible/
    ├── ansible.cfg                 # Ansible configuration
    ├── inventory.yml               # Host definitions
    ├── playbook.yml                # Main deployment playbook
    ├── group_vars/
    │   └── all.yml                 # Global variables
    └── roles/
        ├── common/
        │   └── tasks/main.yml      # Base system setup
        ├── docker/
        │   ├── tasks/main.yml      # Docker installation
        │   └── handlers/main.yml   # Docker handlers
        └── app/
            ├── tasks/main.yml      # Application deployment
            ├── templates/
            │   └── env.prod.j2     # Environment template
            └── files/
                ├── docker-compose.lb.yml  # Docker Compose config
                └── nginx-lb.conf          # Nginx LB config
```

### VM Specifications

| Property | Value |
|----------|-------|
| Name | greencity-vm |
| Base Box | ubuntu/jammy64 |
| IP Address | 192.168.10.20 |
| RAM | 8 GB |
| CPUs | 2 |
| Provider | VirtualBox |

### Ansible Roles

| Role | Purpose |
|------|---------|
| **common** | Base packages, timezone, user creation, directories |
| **docker** | Docker CE, Docker Compose plugin, daemon config |
| **app** | Deploy docker-compose, nginx config, start containers |

### Containers Deployed

| Container | Image | Port |
|-----------|-------|------|
| greencity-lb | ghcr.io/1g0s/greencity-frontend:latest | 80 |
| greencity-backcore-1 | ghcr.io/1g0s/greencity-backcore:latest | 8080 |
| greencity-backcore-2 | ghcr.io/1g0s/greencity-backcore:latest | 8080 |
| greencity-backcore-3 | ghcr.io/1g0s/greencity-backcore:latest | 8080 |
| greencity-backuser-1 | ghcr.io/1g0s/greencity-backuser:latest | 8060 |
| greencity-backuser-2 | ghcr.io/1g0s/greencity-backuser:latest | 8060 |
| greencity-backuser-3 | ghcr.io/1g0s/greencity-backuser:latest | 8060 |
| greencity-postgres-lb | postgres:15-alpine | 5432 |

---

## Verification

### Commands Used

```bash
# Create and provision VM
cd /home/igor/devops/greencity-infra/vagrant
vagrant up

# Check container status
vagrant ssh -c "docker ps --format 'table {{.Names}}\t{{.Status}}'"

# Test nginx health
curl http://192.168.10.20/nginx-health

# Test API endpoints
curl http://192.168.10.20/api/core/
curl http://192.168.10.20/v3/api-docs

# Test load balancing (check X-Backend-Server header)
for i in {1..6}; do curl -s -I http://192.168.10.20/api/core/ | grep X-Backend-Server; done

# Test reproducibility
vagrant destroy -f && vagrant up
```

### Test Results

**Nginx Health Check:**
```
$ curl http://192.168.10.20/nginx-health
healthy
```

**Container Status:**
```
NAMES                   STATUS
greencity-lb            Up 2 minutes (healthy)
greencity-backcore-1    Up 2 minutes (running)
greencity-backcore-2    Up 2 minutes (running)
greencity-backcore-3    Up 2 minutes (running)
greencity-backuser-1    Up 2 minutes (running)
greencity-backuser-2    Up 2 minutes (running)
greencity-backuser-3    Up 2 minutes (running)
greencity-postgres-lb   Up 2 minutes (healthy)
```

**Load Balancing Distribution:**
```
$ for i in {1..6}; do curl -s -I http://192.168.10.20/api/core/ | grep X-Backend-Server; done
X-Backend-Server: 172.18.0.9:8080
X-Backend-Server: 172.18.0.3:8080
X-Backend-Server: 172.18.0.2:8080
X-Backend-Server: 172.18.0.9:8080
X-Backend-Server: 172.18.0.3:8080
X-Backend-Server: 172.18.0.2:8080
```

**Reproducibility Test:**
```
$ vagrant destroy -f && vagrant up
# Result: VM recreated successfully, all containers running, application accessible
# PLAY RECAP: ok=25, changed=17, failed=0
```

---

## Access Points

| Service | URL |
|---------|-----|
| Frontend | http://192.168.10.20/ |
| BackCore API | http://192.168.10.20/api/core/ |
| BackUser API | http://192.168.10.20/api/user/ |
| Swagger UI | http://192.168.10.20/swagger-ui/ |
| Nginx Health | http://192.168.10.20/nginx-health |
| Nginx Status | http://192.168.10.20/nginx-status |

---

## Quick Commands

```bash
# Start VM
cd /home/igor/devops/greencity-infra/vagrant
vagrant up

# SSH into VM
vagrant ssh

# Check application status
curl http://192.168.10.20/nginx-health

# View container logs
vagrant ssh -c "docker compose -f /opt/greencity/docker-compose.yml logs -f"

# Destroy and recreate
vagrant destroy -f && vagrant up

# Re-provision without destroying
vagrant provision
```

---

## Notes

### VirtualBox Network Configuration

The VirtualBox host-only network range on z6 is restricted to `192.168.10.0/24` in `/etc/vbox/networks.conf`. The VM IP was set to `192.168.10.20` instead of the originally planned `192.168.56.20`.

### Java Backend Startup Time

Java backends (backcore, backuser) take approximately 2-3 minutes to fully start due to:
- Liquibase database migrations (443 changesets)
- Hibernate initialization
- Spring Boot context loading

The Ansible playbook includes a health check wait that verifies nginx is healthy before completing.

### Environment Variables

Default placeholder values are used for development. For production:
1. Update `ansible/group_vars/all.yml` with real credentials
2. Run `vagrant provision` to apply changes

---

## Success Criteria Met

- [x] `vagrant up` creates VM and provisions it
- [x] Docker installed automatically
- [x] Application stack deployed automatically (8 containers)
- [x] Accessible via VM IP address (192.168.10.20)
- [x] `vagrant destroy -f && vagrant up` reproduces setup
- [x] Load balancing working across backend instances

---

## Files Created

| File | Lines | Purpose |
|------|-------|---------|
| vagrant/Vagrantfile | 29 | VM definition |
| ansible/ansible.cfg | 19 | Ansible config |
| ansible/inventory.yml | 11 | Host inventory |
| ansible/playbook.yml | 45 | Main playbook |
| ansible/group_vars/all.yml | 47 | Variables |
| ansible/roles/common/tasks/main.yml | 42 | Base setup |
| ansible/roles/docker/tasks/main.yml | 65 | Docker install |
| ansible/roles/docker/handlers/main.yml | 5 | Docker handlers |
| ansible/roles/app/tasks/main.yml | 42 | App deployment |
| ansible/roles/app/templates/env.prod.j2 | 33 | Env template |
| ansible/roles/app/files/docker-compose.lb.yml | 287 | Docker Compose |
| ansible/roles/app/files/nginx-lb.conf | 120 | Nginx config |

**Total:** 12 files, ~745 lines of IaC code

---

## Session Log

| Date | Action | Result |
|------|--------|--------|
| 2026-01-14 | Created Vagrant + Ansible IaC structure | All files created |
| 2026-01-14 | First vagrant up attempt | Failed - VirtualBox network restriction |
| 2026-01-14 | Changed VM IP to 192.168.10.20 | VM created successfully |
| 2026-01-14 | First Ansible provision | Failed - handlers in wrong file |
| 2026-01-14 | Fixed handlers to separate file | Provisioning completed |
| 2026-01-14 | Verified all 8 containers running | All healthy |
| 2026-01-14 | Tested load balancing | Working across 3 backends |
| 2026-01-14 | Reproducibility test | `vagrant destroy && vagrant up` successful |
