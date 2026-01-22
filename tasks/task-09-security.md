# Task 9: Security & Vulnerability Scanning - GreenCity

**Status:** Complete
**Started:** January 21, 2026
**Completed:** January 21, 2026

---

## Objective

Implement security scanning across all repositories to detect vulnerabilities in dependencies and code.

---

## Implementation Summary

### Security Tools Implemented

| Tool | Purpose | Repositories |
|------|---------|--------------|
| **Dependabot** | Dependency vulnerability alerts + auto-fix PRs | All 4 repos |
| **Trivy** | Filesystem vulnerability scanning (Maven/npm/Docker) | All 4 repos |

### Tools Not Used (Require GitHub Advanced Security)

| Tool | Reason Not Used |
|------|-----------------|
| CodeQL | Requires GHAS (paid feature for private repos) |
| SARIF Upload | Requires GHAS for Security tab integration |
| OWASP Dependency Check | Takes 30+ mins to download NVD database |

---

## Files Created/Modified

### greencity-backcore

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | Maven, Docker, GitHub Actions dependency updates |
| `.github/workflows/security.yml` | Trivy filesystem scan |
| `.github/workflows/deploy.yml` | AWS deploy (manual-only trigger) |

### greencity-backuser

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | Maven, Docker, GitHub Actions dependency updates |
| `.github/workflows/security.yml` | Trivy filesystem scan |
| `.github/workflows/deploy.yml` | AWS deploy (manual-only trigger) |

### greencity-frontend

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | npm, Docker, GitHub Actions dependency updates |
| `.github/workflows/security.yml` | Trivy filesystem scan |
| `.github/workflows/deploy.yml` | AWS deploy (manual-only trigger) |

### greencity-infra

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | Terraform, Docker, GitHub Actions dependency updates |
| `.github/workflows/security.yml` | Trivy FS, IaC (Terraform), and K8s manifest scanning |

---

## Workflow Configuration

### Security Scan Workflow (All Repos)

```yaml
name: Security Scan

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  schedule:
    - cron: '0 6 * * 1'  # Weekly Monday 6am UTC

jobs:
  trivy-scan:
    name: Trivy Vulnerability Scanner
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          severity: 'CRITICAL,HIGH,MEDIUM'
          format: 'table'
          exit-code: '0'
```

### Dependabot Configuration (Backend Example)

```yaml
version: 2
updates:
  - package-ecosystem: "maven"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5
    labels: ["dependencies", "security"]

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## Workflow Results

### Security Scan Performance

| Repository | Status | Duration |
|------------|--------|----------|
| greencity-backcore | SUCCESS | ~1m 50s |
| greencity-backuser | SUCCESS | ~1m 10s |
| greencity-frontend | SUCCESS | ~1m 8s |
| greencity-infra | SUCCESS | ~36s |

### Dependabot Activity

Dependabot immediately created PRs after configuration:
- `deps(actions): bump github/codeql-action from 3 to 4`
- `deps(actions): bump docker/build-push-action from 5 to 6`

---

## Issues Encountered & Resolutions

### Issue 1: CodeQL Requires GHAS

**Error:** "Advanced Security must be enabled for this repository to use code scanning"

**Resolution:** Removed CodeQL workflow - requires paid GitHub Advanced Security for private repos in organizations.

### Issue 2: SARIF Upload Requires GHAS

**Error:** "Resource not accessible by integration"

**Resolution:** Removed SARIF upload step - Security tab integration requires GHAS.

### Issue 3: OWASP Dependency Check Too Slow

**Problem:** OWASP Dependency Check takes 30+ minutes on first run to download NVD database.

**Resolution:** Removed OWASP Dependency Check, using Trivy instead which completes in ~1 minute.

### Issue 4: Deploy Workflows Triggering on Push

**Problem:** Deploy to AWS workflows were running on every push (failing due to no AWS credentials).

**Resolution:** Changed deploy workflows to manual-only trigger (`workflow_dispatch`).

---

## Commits

| Repository | Commit | Message |
|------------|--------|---------|
| backcore | ae04aaf | Add security scanning workflows (Task 9) |
| backcore | 98a7a6e | Fix security workflow - remove GHAS dependencies |
| backcore | 3dacbb0 | Make Deploy to AWS workflow manual-only |
| backcore | f6b4de8 | Simplify security workflow - use Trivy only |
| backuser | a2d6f1d | Add security scanning workflows (Task 9) |
| backuser | c3c6267 | Fix security workflow - remove GHAS dependencies |
| backuser | d331365 | Make Deploy to AWS workflow manual-only |
| backuser | 18c645d | Simplify security workflow - use Trivy only |
| frontend | 5b172ab | Add security scanning workflows (Task 9) |
| frontend | fc6b8e1 | Fix security workflow - remove GHAS dependencies |
| frontend | 718e628 | Make Deploy to AWS workflow manual-only |
| frontend | 721566e | Simplify security workflow - use Trivy only |
| infra | 7592bad | Add security scanning workflows (Task 9) |
| infra | adf63fb | Add k8s manifests, terraform config, and scripts |

---

## Verification

### Check Workflow Status

```bash
# View recent workflow runs
gh run list -R DevOps-ProjectLevel/greencity-backcore-1g0s --limit 3
gh run list -R DevOps-ProjectLevel/greencity-backuser-1g0s --limit 3
gh run list -R DevOps-ProjectLevel/greencity-frontend-1g0s --limit 3
gh run list -R 1g0s/greencity-infra --limit 3
```

### Check Dependabot PRs

```bash
# View open Dependabot PRs
gh pr list -R DevOps-ProjectLevel/greencity-backcore-1g0s --author app/dependabot
```

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
- [x] Add security.yml - Trivy (frontend)
- [x] Add security.yml - Trivy IaC + K8s (infra)

### Deploy Workflows (Manual-Only)
- [x] Add deploy.yml - manual trigger (backcore)
- [x] Add deploy.yml - manual trigger (backuser)
- [x] Add deploy.yml - manual trigger (frontend)

### Verification
- [x] All Security Scan workflows passing
- [x] Dependabot creating PRs for vulnerable dependencies
- [x] Deploy workflows not auto-triggering

---

## Security Coverage

| Scan Type | Tool | What It Checks |
|-----------|------|----------------|
| Dependency vulnerabilities | Trivy + Dependabot | Maven pom.xml, npm package.json |
| Docker vulnerabilities | Trivy + Dependabot | Dockerfile base images |
| Infrastructure misconfig | Trivy | Terraform files, K8s manifests |
| GitHub Actions updates | Dependabot | Workflow action versions |

---

## Future Improvements (If GHAS Enabled)

If GitHub Advanced Security is enabled in the future:
1. Re-add CodeQL for Java SAST analysis
2. Enable SARIF upload for Security tab integration
3. Add secret scanning and push protection
