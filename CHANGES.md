# AXION-APP Deployment Changes

## Date
2026-09-26

## Purpose
Localhost Docker Compose deployment of AXION-APP.

---

## Application Login Credential Change

Old username:
info@devopsinsiders.com

New username:
mdkadir360@gmail.com

Password:
[UPDATED - NOT STORED IN DOCUMENTATION]

- Source of old user: Hardcoded in `axion-ui\src\components\Login.tsx` and `axion-ui\src\components\TopBar.tsx`.
- File/migration changed: `axion-ui\src\components\Login.tsx`, `axion-ui\src\components\TopBar.tsx`.
- Password hashing mechanism: None (Hardcoded string comparison).
- Preserved role: System Admin.
- Database update performed: N/A (Frontend only).
- Test result: PASS.

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

