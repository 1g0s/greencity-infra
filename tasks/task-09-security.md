# Task 9: Security & Vulnerability Scanning - GreenCity

**Status:** Complete
**Started:** January 21, 2026
**Completed:** January 21, 2026

---

## Objective

Implement comprehensive security scanning across all repositories to detect vulnerabilities in dependencies, code, containers, and infrastructure.

---

## Implementation Summary

### Security Tools Implemented

| Tool | Purpose | Repositories |
|------|---------|--------------|
| **Dependabot** | Dependency vulnerability alerts + auto-fix PRs | All 4 repos |
| **Trivy** | Filesystem, Container, and IaC scanning | All 4 repos |
| **CodeQL** | Static Application Security Testing (SAST) | backcore, backuser, frontend |
| **OWASP Dependency-Check** | Java CVE scanning | backcore, backuser |
| **npm audit** | JavaScript vulnerability scanning | frontend |

---

## Files Created

### greencity-backcore

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | Maven, Docker, GitHub Actions dependency updates |
| `.github/workflows/security.yml` | Trivy FS scan + OWASP Dependency Check |
| `.github/workflows/codeql.yml` | Java SAST analysis |

### greencity-backuser

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | Maven, Docker, GitHub Actions dependency updates |
| `.github/workflows/security.yml` | Trivy FS scan + OWASP Dependency Check |
| `.github/workflows/codeql.yml` | Java SAST analysis |

### greencity-frontend

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | npm, Docker, GitHub Actions dependency updates |
| `.github/workflows/security.yml` | Trivy FS scan + npm audit |
| `.github/workflows/codeql.yml` | JavaScript/TypeScript SAST analysis |

### greencity-infra

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | Terraform, Docker, GitHub Actions dependency updates |
| `.github/workflows/security.yml` | Trivy FS, IaC (Terraform), and K8s manifest scanning |

---

## Workflow Schedule

All security workflows run on:
- **Push** to main/master branch
- **Pull requests** to main/master branch
- **Scheduled** weekly on Monday at 6am UTC

---

## Security Scanning Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Security Scanning Pipeline                                              │
│                                                                          │
│  ┌────────────────┐   ┌────────────────┐   ┌────────────────┐           │
│  │   BackCore     │   │   BackUser     │   │   Frontend     │           │
│  │   (Java)       │   │   (Java)       │   │  (Angular)     │           │
│  └───────┬────────┘   └───────┬────────┘   └───────┬────────┘           │
│          │                    │                    │                     │
│          ▼                    ▼                    ▼                     │
│  ┌───────────────────────────────────────────────────────────┐          │
│  │                    Security Scans                          │          │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐  │          │
│  │  │ Dependabot  │ │   Trivy     │ │      CodeQL         │  │          │
│  │  │ (weekly)    │ │   (FS)      │ │     (SAST)          │  │          │
│  │  │ Maven/npm   │ │ CVE scan    │ │ SQL Inj, XSS, etc   │  │          │
│  │  └─────────────┘ └─────────────┘ └─────────────────────┘  │          │
│  │  ┌─────────────┐ ┌─────────────────────────────────────┐  │          │
│  │  │ OWASP Dep-  │ │        npm audit (frontend)         │  │          │
│  │  │ Check (Java)│ │     JavaScript vulnerability scan   │  │          │
│  │  └─────────────┘ └─────────────────────────────────────┘  │          │
│  └───────────────────────────────────────────────────────────┘          │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────┐         │
│  │                     Infrastructure                          │         │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │         │
│  │  │ Dependabot  │ │ Trivy IaC   │ │ Trivy K8s Manifests │   │         │
│  │  │ Terraform   │ │ Terraform   │ │ Kubernetes YAML     │   │         │
│  │  │ modules     │ │ misconfig   │ │ security checks     │   │         │
│  │  └─────────────┘ └─────────────┘ └─────────────────────┘   │         │
│  └────────────────────────────────────────────────────────────┘         │
│                                                                          │
│                              ▼                                           │
│  ┌───────────────────────────────────────────────────────────┐          │
│  │              GitHub Security Tab                           │          │
│  │  • SARIF reports uploaded for all scans                    │          │
│  │  • Vulnerability alerts visible in Security tab            │          │
│  │  • Dependabot PRs auto-created for vulnerable deps         │          │
│  └───────────────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Dependabot Configuration Details

### Backend Repos (backcore, backuser)

```yaml
updates:
  - package-ecosystem: "maven"      # Scan pom.xml
  - package-ecosystem: "docker"     # Scan Dockerfile
  - package-ecosystem: "github-actions"  # Scan workflow actions
```

### Frontend Repo

```yaml
updates:
  - package-ecosystem: "npm"        # Scan package.json
  - package-ecosystem: "docker"     # Scan Dockerfile
  - package-ecosystem: "github-actions"  # Scan workflow actions
```

### Infra Repo

```yaml
updates:
  - package-ecosystem: "terraform"  # Scan Terraform modules
  - package-ecosystem: "docker"     # Scan docker-compose images
  - package-ecosystem: "github-actions"  # Scan workflow actions
```

---

## Security Workflow Features

### Trivy Scans

| Scan Type | Target | Output |
|-----------|--------|--------|
| `fs` (filesystem) | Source code, configs | SARIF + Table |
| `config` (IaC) | Terraform files | SARIF + Table |
| `config` (K8s) | Kubernetes manifests | SARIF + Table |

### CodeQL Analysis

| Language | Query Set |
|----------|-----------|
| Java | security-extended, security-and-quality |
| JavaScript | security-extended, security-and-quality |

### OWASP Dependency Check (Java)

- Scans Maven dependencies for known CVEs
- Fails build on CVSS score >= 9 (Critical)
- HTML report uploaded as artifact

### npm Audit (Frontend)

- Scans npm packages for vulnerabilities
- Reports high and critical severity issues
- JSON report uploaded as artifact

---

## GitHub Security Settings Required

After pushing the workflows, enable these settings in each repository:

### Settings → Security → Code security and analysis

| Setting | Action |
|---------|--------|
| Dependabot alerts | Enable |
| Dependabot security updates | Enable |
| Secret scanning | Enable |
| Push protection | Enable |

---

## Verification

### Check Workflow Runs

```bash
# View recent workflow runs
gh run list -R DevOps-ProjectLevel/greencity-backcore-1g0s
gh run list -R DevOps-ProjectLevel/greencity-backuser-1g0s
gh run list -R DevOps-ProjectLevel/greencity-frontend-1g0s
gh run list -R 1g0s/greencity-infra
```

### Check Security Tab

- https://github.com/DevOps-ProjectLevel/greencity-backcore-1g0s/security
- https://github.com/DevOps-ProjectLevel/greencity-backuser-1g0s/security
- https://github.com/DevOps-ProjectLevel/greencity-frontend-1g0s/security
- https://github.com/1g0s/greencity-infra/security

### View Dependabot Alerts

```bash
gh api repos/DevOps-ProjectLevel/greencity-backcore-1g0s/dependabot/alerts
```

---

## Files Summary

| Repository | Files Added | Total Lines |
|------------|-------------|-------------|
| greencity-backcore | 3 | 174 |
| greencity-backuser | 3 | 174 |
| greencity-frontend | 3 | 172 |
| greencity-infra | 2 | 163 |
| **Total** | **11** | **683** |

---

## Deliverables Checklist

### Dependabot Configuration
- [x] Add dependabot.yml (backcore)
- [x] Add dependabot.yml (backuser)
- [x] Add dependabot.yml (frontend)
- [x] Add dependabot.yml (infra)

### Security Workflows
- [x] Add security.yml - Trivy (backcore)
- [x] Add security.yml - Trivy (backuser)
- [x] Add security.yml - Trivy + npm audit (frontend)
- [x] Add security.yml - Trivy IaC + K8s (infra)
- [x] Add codeql.yml - Java (backcore)
- [x] Add codeql.yml - Java (backuser)
- [x] Add codeql.yml - JavaScript (frontend)

### Commits
- [x] backcore: ae04aaf - Add security scanning workflows (Task 9)
- [x] backuser: a2d6f1d - Add security scanning workflows (Task 9)
- [x] frontend: 5b172ab - Add security scanning workflows (Task 9)
- [x] infra: 7592bad - Add security scanning workflows (Task 9)

### GitHub Settings (Manual Steps Required)
- [ ] Enable Dependabot alerts (backcore)
- [ ] Enable Dependabot alerts (backuser)
- [ ] Enable Dependabot alerts (frontend)
- [ ] Enable Dependabot alerts (infra)
- [ ] Enable Secret Scanning (backcore)
- [ ] Enable Secret Scanning (backuser)
- [ ] Enable Secret Scanning (frontend)
- [ ] Enable Secret Scanning (infra)

---

## Expected Outcomes

After implementation:
- Automatic weekly dependency vulnerability scans (Maven + npm)
- PRs created automatically for vulnerable dependencies
- Static code analysis on every push/PR (Java + JavaScript)
- Container image scanning before deployment
- Terraform misconfiguration detection
- Kubernetes manifest security checks
- Secret leak prevention with push protection

---

## Next Steps

1. **Enable GitHub Security Settings** - Go to Settings → Security → Code security in each repo
2. **Review Initial Findings** - Check Security tab for vulnerability alerts
3. **Fix Critical Issues** - Address CRITICAL and HIGH severity vulnerabilities
4. **Document Accepted Risks** - For false positives or accepted risks
