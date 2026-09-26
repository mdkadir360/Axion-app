# DEPLOYMENT_GUIDE.md

## 1. Architecture Overview
The Axion platform is an Industrial IoT telemetry and monitoring system. It consists of a data ingestion pipeline for real-time sensor readings and a query-driven dashboard for monitoring asset health.

## 2. Repository Overview
- **axion-database-schema**: PostgreSQL schema definitions and migration scripts.
- **axion-ingestion-service**: FastAPI service that receives telemetry and writes to PostgreSQL.
- **axion-telemetry-query-service**: FastAPI service that reads telemetry for the UI.
- **axion-data-simulator**: Python script simulating industrial device traffic.
- **axion-ui**: React-based monitoring dashboard served via Nginx.

## 3. Service Dependency Diagram
```
axion-ui
   |
   v
axion-telemetry-query-service
   |
   v
PostgreSQL Database <---- axion-ingestion-service <---- axion-data-simulator
```

## 4. Database Architecture
- **Engine**: PostgreSQL 13+
- **Schema**: Single database (`axiondb`) containing `telemetry` and (optionally) `alerts` tables.
- **Extension**: Requires `pgcrypto` for UUID generation.

## 5. PostgreSQL Setup
### Connection Parameters
- **DB_HOST**: `<POSTGRES_HOST>` (e.g., `postgres-db` in Docker)
- **DB_PORT**: `5432`
- **DB_NAME**: `axiondb`
- **DB_USER**: `<DATABASE_USER>`
- **DB_PASSWORD**: `<DATABASE_PASSWORD>`

### Setup Sequence
1. Create database `axiondb`.
2. Execute `01-extensions.sql`.
3. Execute `02-telemetry.sql`.

## 6. Required Environment Variables
| Service | Variable | Purpose | Placeholder |
|---|---|---|---|
| Ingestion | `DATABASE_URL` | DB Connection String | `postgresql://<USER>:<PASS>@<HOST>:5432/axiondb` |
| Query | `DATABASE_URL` | DB Connection String | `postgresql://<USER>:<PASS>@<HOST>:5432/axiondb` |
| Query | `PORT` | Service Port | `8000` |
| Simulator | `API_URL` | Ingestion Endpoint | `http://axion-ingestion-service:8000/api/v1/telemetry/ingest` |
| Simulator | `INTERVAL_SECONDS` | Polling Rate | `5` |

## 7. Backend URLs
- **Ingestion Service**: `http://axion-ingestion-service:8000`
- **Query Service**: `http://axion-telemetry-query-service:8000`

## 8. Frontend URLs
- **UI Application**: `http://localhost:80`
- **API Target**: `http://axion-telemetry-query-service:8000` (Current code uses `https://api.axionsystems.de`)

## 9. Authentication
Currently, the system uses **Open Access**. No JWT or API Key authentication is implemented in the source code.

## 10. Token/Secret Requirements
- **Database Password**: Required for all backend services.
- **API Tokens**: None currently required.

## 11. CORS Configuration
- **Current State**: `allow_origins=["*"]` in both FastAPI services.
- **Recommended**: Restrict to the UI domain in production.

## 12. Docker Architecture
### Container Strategy
- **PostgreSQL**: Official `postgres:alpine` image.
- **Backends**: Custom images based on `python:3.12-slim`.
- **UI**: Custom image based on `node:20-alpine` (build) and `nginx:alpine` (serve).

### Networking
All services should reside on a single Docker bridge network.

## 13. Deployment Order
1. **PostgreSQL**: Start container.
2. **Database Schema**: Apply `.sql` scripts in order.
3. **Ingestion Service**: Start container.
4. **Query Service**: Start container.
5. **Data Simulator**: Start container.
6. **UI**: Build and start container.

## 14. Exact Files to Modify
| Repository | File | Change | Reason |
|---|---|---|---|
| axion-ui | `src/App.tsx` | Update `API_BASE` | Point to deployed Query Service |
| axion-ui | `src/components/pages/DashboardView.tsx` | Update `API_BASE` | Point to deployed Query Service |
| axion-ui | `src/components/pages/HistoricalTrends.tsx` | Update `API_BASE` | Point to deployed Query Service |
| axion-ingestion-service | `config.py` | Parametrize `DATABASE_URL` | Remove hardcoded fallback |
| axion-telemetry-query-service | `config.py` | Parametrize `DATABASE_URL` | Remove hardcoded fallback |

## 15. Exact Commands to Run
### DB Setup
`psql -h <HOST> -U <USER> -d axiondb -f 01-extensions.sql`
`psql -h <HOST> -U <USER> -d axiondb -f 02-telemetry.sql`

### Service Start (Manual)
`uvicorn main:app --host 0.0.0.0 --port 8000`

## 16. Database Migration Steps
1. **Connect**: `psql -h localhost -U postgres`
2. **Create DB**: `CREATE DATABASE axiondb;`
3. **Run scripts**: Use the order defined in section 5.

## 17. Service Startup Steps
1. Ensure PostgreSQL is healthy.
2. Set `DATABASE_URL` environment variable.
3. Launch Backend services.
4. Launch Simulator.

## 18. Health Check Commands
- **Ingestion**: `curl http://axion-ingestion-service:8000/health`
- **Query**: `curl http://axion-telemetry-query-service:8000/dashboard/summary`
- **DB**: `pg_isready -h <HOST>`

## 19. API Testing
`curl -X POST http://axion-ingestion-service:8000/api/v1/telemetry/ingest -d '{"deviceId":"TEST","deviceType":"PUMP","refineryRegion":"NORTH","timestamp":"2026-01-01T00:00:00Z","metrics":{"temperature":50,"vibration":2,"current":10}}'`

## 20. Frontend Testing
Navigate to `http://localhost:80` and verify the KPI Strip and Asset List are populated.

## 21. Troubleshooting
- **DB Connectivity**: Check if `host.docker.internal` is needed for Windows hosts.
- **CORS**: Verify browser console for "Cross-Origin Request Blocked".
- **Port Conflict**: Ensure port 8000 is not used by multiple services on the same host IP.

## 22. Security Checklist
- [ ] Remove hardcoded DB password from `config.py`.
- [ ] Restrict CORS `allow_origins`.
- [ ] Implement JWT Authentication.
- [ ] Set up HTTPS/SSL for UI and API.

## 23. Production Readiness Checklist
- [ ] Use managed PostgreSQL (RDS/Cloud SQL).
- [ ] Implement centralized logging.
- [ ] Configure resource limits in Docker.
- [ ] Set up health check probes in orchestrator.

## 24. Application Login

Username:
mdkadir360@gmail.com

Password:
[configured securely in frontend]
