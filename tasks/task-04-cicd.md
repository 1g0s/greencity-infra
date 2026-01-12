# Task 4: CI/CD Implementation - Completion Report

**Project:** GreenCity
**Status:** ✅ VERIFIED COMPLETE
**Date:** January 11-12, 2026
**Environment:** GitHub Actions + GitHub Container Registry

---

## Deliverables Created

| File | Location | Purpose |
|------|----------|---------|
| BackCore CI workflow | `greencity-backcore/.github/workflows/ci.yml` | Maven build, JUnit tests, JaCoCo coverage |
| BackUser CI workflow | `greencity-backuser/.github/workflows/ci.yml` | Maven build, JUnit tests, JaCoCo coverage |
| Docker build workflow | `.github/workflows/docker.yml` | Build & push all 3 images to ghcr.io |

**Note:** Frontend already has Azure Pipelines CI/CD (kept as-is)

---

## CI/CD Architecture

```mermaid
graph TB
    subgraph "GitHub Repository"
        PUSH[Push / PR]
    end

    subgraph "GitHub Actions"
        subgraph "BackCore CI"
            BC_FMT[Code Formatter]
            BC_CHK[Checkstyle]
            BC_TEST[JUnit Tests]
            BC_COV[JaCoCo Coverage]
            BC_JAR[Build JAR]
        end

        subgraph "BackUser CI"
            BU_FMT[Code Formatter]
            BU_CHK[Checkstyle]
            BU_TEST[JUnit Tests]
            BU_COV[JaCoCo Coverage]
            BU_JAR[Build JAR]
        end

        subgraph "Docker Build (main branch)"
            D_BC[Build BackCore Image]
            D_BU[Build BackUser Image]
            D_FE[Build Frontend Image]
            D_PUSH[Push to ghcr.io]
        end
    end

    subgraph "Azure Pipelines (Existing)"
        AZ_FE[Frontend CI/CD]
        AZ_HELM[Helm Deploy to AKS]
    end

    subgraph "Artifacts"
        GHCR[(GitHub Container Registry)]
        JAR[(JAR Artifacts)]
        COV[(Coverage Reports)]
    end

    PUSH --> BC_FMT
    PUSH --> BU_FMT
    BC_FMT --> BC_CHK
    BC_CHK --> BC_TEST
    BC_TEST --> BC_COV
    BC_COV --> BC_JAR
    BU_FMT --> BU_CHK
    BU_CHK --> BU_TEST
    BU_TEST --> BU_COV
    BU_COV --> BU_JAR

    PUSH -->|main branch| D_BC
    PUSH -->|main branch| D_BU
    PUSH -->|main branch| D_FE
    D_BC --> D_PUSH
    D_BU --> D_PUSH
    D_FE --> D_PUSH
    D_PUSH --> GHCR

    BC_JAR --> JAR
    BU_JAR --> JAR
    BC_COV --> COV
    BU_COV --> COV

    style GHCR fill:#0969da,color:#fff
    style BC_TEST fill:#007396,color:#fff
    style BU_TEST fill:#007396,color:#fff
    style AZ_FE fill:#0078d4,color:#fff
```

---

## Workflow Details

### BackCore CI (`greencity-backcore/.github/workflows/ci.yml`)

**Triggers:** Push, Pull Request (all branches)

**Jobs:**
1. **test** - Run tests with PostgreSQL service
   - Checkout code
   - Setup Java 21 (Temurin)
   - Run code formatter (`mvn formatter:format`)
   - Check code style (`mvn checkstyle:check`)
   - Build and test (`mvn clean test`)
   - Generate JaCoCo coverage report
   - Upload coverage artifact

2. **build** - Build JAR artifact (after test passes)
   - Checkout code
   - Setup Java 21
   - Build JAR (`mvn clean package -DskipTests`)
   - Upload JAR artifact

**Services:**
- PostgreSQL 15 with health checks

**Environment Variables:**
```yaml
DATASOURCE_URL: jdbc:postgresql://localhost:5432/greencity
DATASOURCE_USER: greencity
DATASOURCE_PASSWORD: greencity
```

---

### BackUser CI (`greencity-backuser/.github/workflows/ci.yml`)

Same structure as BackCore CI.

---

### Docker Build (`.github/workflows/docker.yml`)

**Triggers:** Push to main/master, Manual dispatch

**Jobs:**
1. **build-backcore** - Build and push backcore image
   - Uses Docker Buildx
   - Pushes to `ghcr.io/<owner>/greencity-backcore`
   - Tags: `latest`, `<git-sha>`

2. **build-backuser** - Build and push backuser image
   - Uses Docker Buildx
   - Pushes to `ghcr.io/<owner>/greencity-backuser`
   - Tags: `latest`, `<git-sha>`

3. **build-frontend** - Build and push frontend image
   - Uses Docker Buildx
   - Pushes to `ghcr.io/<owner>/greencity-frontend`
   - Tags: `latest`, `<git-sha>`

---

## Container Registry

**Registry:** GitHub Container Registry (ghcr.io)

**Images (Verified January 12, 2026):**
```
ghcr.io/1g0s/greencity-backcore:latest
ghcr.io/1g0s/greencity-backcore:2559791

ghcr.io/1g0s/greencity-backuser:latest
ghcr.io/1g0s/greencity-backuser:2559791

ghcr.io/1g0s/greencity-frontend:latest
ghcr.io/1g0s/greencity-frontend:2559791
```

**Authentication:**
- CI workflows use built-in `GITHUB_TOKEN`
- Docker builds use `CHECKOUT_TOKEN` secret (PAT) for cross-repo checkout

---

## Build Times

| Component | Actual Build Time | Notes |
|-----------|-------------------|-------|
| BackCore CI | ~3 min | Maven + tests + JaCoCo |
| BackUser CI | ~2.5 min | Maven + tests + JaCoCo |
| Docker BackCore | 22s - 4m15s | Cached vs cold build |
| Docker BackUser | 3m7s - 3m27s | Multi-stage Maven build |
| Docker Frontend | 7m2s | Angular build + npm install |

**Optimization:** Maven dependency caching enabled via `actions/setup-java@v4`

---

## Verification Commands

```bash
# Check workflow files exist
ls -la greencity-backcore/.github/workflows/
ls -la greencity-backuser/.github/workflows/
ls -la .github/workflows/

# Validate YAML syntax
yamllint greencity-backcore/.github/workflows/ci.yml
yamllint greencity-backuser/.github/workflows/ci.yml
yamllint .github/workflows/docker.yml
```

---

## Activation Steps

To activate CI/CD pipelines:

1. **Push workflows to GitHub:**
   ```bash
   cd greencity-backcore
   git add .github/workflows/ci.yml
   git commit -m "Add CI workflow"
   git push

   cd ../greencity-backuser
   git add .github/workflows/ci.yml
   git commit -m "Add CI workflow"
   git push

   cd ..
   git add .github/workflows/docker.yml
   git commit -m "Add Docker build workflow"
   git push
   ```

2. **Verify on GitHub:**
   - Go to repository → Actions tab
   - Check workflow runs
   - Fix any issues shown in logs

3. **(Optional) Enable branch protection:**
   - Settings → Branches → Add rule
   - Require status checks to pass before merging

---

## Existing CI/CD (Frontend)

The frontend already has Azure Pipelines configured:
- `azure-pipelines.yml` - Dev pipeline
- `azure-pipelines-prod.yml` - Production pipeline

These deploy to Azure Kubernetes Service via Helm charts.

---

## Issues Resolved (January 12, 2026)

### 1. Code Formatter Validation Failure

**Problem:** CI builds failing with `formatter-maven-plugin:validate` error
```
File 'UserFilterDtoResponse.java' has not been previously formatted
```

**Solution:** Ran `mvn formatter:format` to format all Java files
- BackCore: 47 files formatted
- BackUser: 1 file formatted (SecurityConfig.java)

### 2. Docker Build - Component Repos Not Found

**Problem:** Docker builds failing with path not found errors
```
ERROR: failed to build: unable to prepare context: path "./greencity-backcore" not found
```

**Cause:** Component repos are in DevOps-ProjectLevel org, not in infra repo

**Solution:**
1. Created `CHECKOUT_TOKEN` secret (PAT with repo access)
2. Updated `docker.yml` to checkout each component repo separately:
   ```yaml
   - name: Checkout backcore repo
     uses: actions/checkout@v4
     with:
       repository: DevOps-ProjectLevel/greencity-backcore-1g0s
       token: ${{ secrets.CHECKOUT_TOKEN }}
       path: greencity-backcore
   ```

### 3. Frontend npm ci Sync Error

**Problem:** Frontend Docker build failing with lock file sync error
```
npm ERR! cipm can only install packages when your package.json and package-lock.json are in sync
```

**Solution:** Regenerated `package-lock.json` with `npm install`

---

## Verification Results

| Workflow | Status | Run ID |
|----------|--------|--------|
| BackCore CI | ✅ Passing | [#20934293687](https://github.com/DevOps-ProjectLevel/greencity-backcore-1g0s/actions/runs/20934293687) |
| BackUser CI | ✅ Passing | [#20934296758](https://github.com/DevOps-ProjectLevel/greencity-backuser-1g0s/actions/runs/20934296758) |
| Docker Build | ✅ Passing | [#20934641733](https://github.com/1g0s/greencity-infra/actions/runs/20934641733) |

---

## Next Steps

- [x] Push workflows to GitHub repositories
- [x] Verify CI workflows pass
- [x] Verify Docker builds complete
- [ ] Enable branch protection rules (optional)
- [ ] Add SonarCloud integration (optional)
- [ ] Create Helm charts for backends (optional)
- [ ] Task 5: Load Balancing
