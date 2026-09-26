# AXION-APP Deployment Changes

## Date
2026-09-26

## Purpose
Localhost Docker Compose deployment of AXION-APP.

---

## Minikube PostgreSQL Modernization
Simplified the Minikube deployment by moving PostgreSQL inside the cluster.

**Changes:**
- **Internal Database**: Replaced external Windows host PostgreSQL with a Kubernetes StatefulSet (`axion-postgres`).
- **Persistence**: Added `PersistentVolumeClaim` (5Gi) for database durability.
- **Secret Management**: Introduced `axion-postgres-secret` for database credentials, removing dependency on `axion-secrets`.
- **Automation**: Updated `deploy-minikube.ps1` to handle PostgreSQL readiness and automated database migrations.
- **Migration Job**: Added a Kubernetes Job that initializes the `axiondb` schema using a ConfigMap-based SQL script.
- **Connectivity**: Updated all backend services (Ingestion, Query) to use `axion-postgres:5432`.
- **Independence**: Minikube deployment is now fully decoupled from the Windows host PostgreSQL installation.

---

## Kubernetes Migration (Testsop Environment)
Migration from localhost Docker Compose to Azure DevOps CI/CD and Kubernetes.

**Architecture Change:**
- **Old**: Localhost ports (8080, 8000, 8001).
- **New**: Host-based routing via K8s Ingress.
    - Frontend: `https://axion-ui-testsop.online`
    - Backend API: `https://axion-api-testsop.online`
- **Routing**: Removed `/api` path-based routing in favor of a dedicated API domain for better isolation and simpler CORS management.

**Key Implementations:**
- Created `azure-pipelines.yml` for automated Build $\rightarrow$ Push $\rightarrow$ Migrate $\rightarrow$ Deploy flow.
- Implemented a K8s Job for automated non-destructive database schema migrations.
- Parameterized Frontend API URL using `VITE_API_BASE`.
- Configured K8s manifests with production resource limits and health probes.
- Set up secure secret injection via Azure DevOps Variable Groups.

**Files Created:**
- `azure-pipelines.yml`
- `k8s/namespace.yaml`
- `k8s/ingress.yaml`
- `k8s/configmap/db-scripts-cm.yaml`
- `k8s/secrets/secrets.yaml.template`
- `k8s/ui/deployment.yaml`
- `k8s/ui/service.yaml`
- `k8s/ingestion/deployment.yaml`
- `k8s/ingestion/service.yaml`
- `k8s/telemetry-query/deployment.yaml`
- `k8s/telemetry-query/service.yaml`
- `k8s/data-simulator/deployment.yaml`
- `k8s/database/migration-job.yaml`
- `KUBERNETES_DEPLOYMENT.md`

---

## 1. Architecture Changes
The application is deployed using Docker Compose on Windows.
Browser -> localhost:8080 (UI) -> localhost:8000 (Query API) -> Docker Internal Network -> host.docker.internal:5432 (Host PostgreSQL).

---

## 2. Repository Changes
| Repository | File | Change | Reason |
|---|---|---|---|
| axion-ui | src/App.tsx | API_BASE -> http://localhost:8000 | Localhost connectivity |
| axion-ui | src/components/pages/DashboardView.tsx | API_BASE -> http://localhost:8000 | Localhost connectivity |
| axion-ui | src/components/pages/HistoricalTrends.tsx | API_BASE -> http://localhost:8000 | Localhost connectivity |
| axion-ingestion-service | config.py | Removed hardcoded DB password | Security / Env Var usage |
| axion-telemetry-query-service | config.py | Removed hardcoded DB password | Security / Env Var usage |
| axion-ingestion-service | .env.example | Replaced secrets with placeholders | Security |
| Root | .env | Created local environment config | Required for deployment |
| Root | .env.example | Created template for environment variables | Documentation |
| Root | .gitignore | Added .env | Prevent secret commit |
| Root | docker-compose.yml | Created full application stack | Orchestration |
| Root | DEPLOYMENT_GUIDE.md | Updated for localhost deployment | Documentation |

---

## 3. Frontend Changes
- **Old API**: https://api.axionsystems.de
- **New API**: http://localhost:8000
- **Affected Files**: App.tsx, DashboardView.tsx, HistoricalTrends.tsx
- **Reason**: Browser cannot resolve Docker service names; must use localhost for the exposed port.

---

## 4. Backend Changes
- **axion-ingestion-service**:
  - Configured to use `DATABASE_URL` environment variable.
  - Internal port: 8000, External: 8001.
- **axion-telemetry-query-service**:
  - Configured to use `DATABASE_URL` environment variable.
  - Internal port: 8000, External: 8000.

---

## 5. Docker Changes
- **Dockerfiles**: Preserved existing multi-stage builds.
- **Base Images**: python:3.12-slim, node:20-alpine, nginx:alpine.
- **Ports**: UI (8080), Query (8000), Ingestion (8001).

---

## 6. Docker Compose Changes
- **Services**: axion-ui, axion-ingestion-service, axion-telemetry-query-service, axion-data-simulator.
- **Networking**: Created `axion-network` bridge.
- **DB Connection**: All backends use `host.docker.internal:5432`.
- **Dependencies**: UI depends on Query Service; Simulator depends on Ingestion Service.

---

## 7. Database Changes
- **Database**: axiondb on Windows Host.
- **Scripts Executed**: 01-extensions.sql, 02-telemetry.sql.
- **Data**: Existing data preserved; only schema extensions and tables added.

---

## 8. Environment Variables
- POSTGRES_HOST
- POSTGRES_PORT
- POSTGRES_DB
- POSTGRES_USER
- POSTGRES_PASSWORD
- DATABASE_URL
- API_URL (Simulator)
- INTERVAL_SECONDS (Simulator)

---

## 9. Security Changes
- `.env` explicitly ignored in `.gitignore`.
- Hardcoded DB passwords removed from `config.py`.
- Secrets moved to environment variables.
- All browser-facing communication set to localhost.

---

## 10. Testing Performed
- **Docker Build**: PASS
- **Docker Compose Startup**: PASS
- **PostgreSQL Connectivity**: PASS (via host.docker.internal)
- **Ingestion Health**: PASS (http://localhost:8001/health)
- **Query API**: PASS (http://localhost:8000/dashboard/summary)
- **Frontend**: PASS (http://localhost:8080)
- **Simulator**: PASS (Logs show data flowing to ingestion)
- **End-to-End**: PASS (Telemetry -> DB -> UI)

---

## 11. Docker Images
- mdkadir360/axion-ui:latest
- mdkadir360/axion-ingestion-service:latest
- mdkadir360/axion-telemetry-query-service:latest
- mdkadir360/axion-data-simulator:latest
- **Push Status**: Built locally; pushing attempted but failed due to auth. Local images are current.

---

## 12. Known Issues
- **Docker Hub Auth**: `docker push` failed; requires `docker login` by user.
- **Port 80 Conflict**: UI moved to 8080 because port 80 was occupied on host.

---

## 13. Rollback / Revert Information
- **Files to revert**: UI API_BASE, Backend config.py, docker-compose.yml, .env.
- **Stop Command**: `docker compose down`
- **Revert Code**: Use git checkout if initialized, or manually restore production URLs.
