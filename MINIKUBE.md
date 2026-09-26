# AXION-APP MINIKUBE DEPLOYMENT GUIDE

This guide provides complete step-by-step instructions for deploying the AXION application locally using Minikube.

## 1. Overview

### Purpose
The Minikube deployment allows developers and DevOps engineers to run the full AXION stack in a local Kubernetes environment, mimicking a production-like architecture with isolated services and persistent storage.

### Architecture
The deployment consists of several microservices orchestrated by Kubernetes, with all components residing within the `axion-minikube` namespace.

### Components
- **axion-postgres**: PostgreSQL 16 database running as a StatefulSet for persistence.
- **axion-database-schema**: Authoritative SQL scripts used to initialize the database.
- **axion-ingestion-service**: FastAPI service that receives and stores telemetry data.
- **axion-telemetry-query-service**: FastAPI service that provides API access to stored telemetry.
- **axion-data-simulator**: Service that generates mock telemetry data for testing.
- **axion-ui**: React-based dashboard for visualizing telemetry data.

### Data Flow
`Data Simulator` $\rightarrow$ `Ingestion Service` $\rightarrow$ `PostgreSQL` $\rightarrow$ `Telemetry Query Service` $\rightarrow$ `UI`

---

## 2. Prerequisites

The following tools must be installed on your Windows host:
- **Git**: For repository management.
- **Docker Desktop**: Required as the Minikube driver.
- **Minikube**: For the local Kubernetes cluster.
- **kubectl**: Kubernetes command-line tool.
- **PowerShell**: For running deployment scripts.

*Tested with current supported versions of the above tools.*

---

## 3. Clone Repository

```powershell
git clone <repository-url>
cd <repository-directory>
git checkout feature/minikube
```
*Note: All Minikube-specific deployment configurations are maintained on the `feature/minikube` branch.*

---

## 4. Start Minikube

Start the local cluster using the Docker driver:

```powershell
minikube start
```

Verify the cluster status and IP:
```powershell
minikube status
minikube ip
```

---

## 5. Build Minikube Docker Images

The deployment uses local images to avoid dependency on external registries. Build the following images using the provided Dockerfiles:

- `axion-ingestion-service:minikube`
- `axion-telemetry-query-service:minikube`
- `axion-data-simulator:minikube`
- `axion-ui:minikube`

Ensure you have configured your shell to use the Minikube Docker daemon:
```powershell
minikube docker-env | Invoke-Expression
```

---

## 6. Load Images into Minikube

Load the built images directly into the Minikube node:

```powershell
minikube image load axion-ingestion-service:minikube
minikube image load axion-telemetry-query-service:minikube
minikube image load axion-data-simulator:minikube
minikube image load axion-ui:minikube
```

---

## 7. Database Configuration

### Architecture
PostgreSQL runs inside the Minikube cluster as a `StatefulSet` named `axion-postgres`.
- **Service**: `axion-postgres`
- **Port**: `5432`
- **Database**: `axiondb`

Internal services connect to the database using the internal DNS name: `axion-postgres:5432`.

### Creating the Secret
Do not commit passwords to Git. Create the required Kubernetes secret manually:

```powershell
kubectl create secret generic axion-postgres-secret `
  -n axion-minikube `
  --from-literal=POSTGRES_DB="axiondb" `
  --from-literal=POSTGRES_USER="postgres" `
  --from-literal=POSTGRES_PASSWORD="your_password" `
  --from-literal=DATABASE_URL="postgresql://postgres:your_password@axion-postgres:5432/axiondb"
```
*Alternatively, use `k8s/minikube/postgres-secret.yaml.example` as a template.*

---

## 8. Authoritative Database Migration

The database schema is defined by authoritative SQL files in the `axion-database-schema/` directory:
- `01-extensions.sql`: Enables `pgcrypto` and `uuid-ossp`.
- `02-telemetry.sql`: Creates the `telemetry` table.

### Migration Process
1. **ConfigMap**: The SQL scripts are stored in the `axion-db-schema` ConfigMap.
2. **Job**: The `axion-db-migration` Job runs a `postgres:16-alpine` container.
3. **Logic**: The Job waits for `axion-postgres` to be ready, then executes the SQL scripts in order.

The resulting `telemetry` table includes:
- `device_id`, `device_type`, `refinery_region`, `timestamp`, `temperature`, `vibration`, `current`, `created_at`.

---

## 9. Create/Apply Minikube Resources

Apply all configurations using Kustomize:

```powershell
kubectl apply -k k8s/minikube
```
This creates all resources within the `axion-minikube` namespace.

---

## 10. Verify Deployment

Check the status of all components:

```powershell
kubectl get pods -n axion-minikube
kubectl get svc -n axion-minikube
kubectl get pvc -n axion-minikube
kubectl get jobs -n axion-minikube
```

**Expected States:**
- `axion-postgres-0`: Running / Ready
- `axion-ingestion-service`: Running / Ready
- `axion-telemetry-query-service`: Running / Ready
- `axion-data-simulator`: Running / Ready
- `axion-ui`: Running / Ready
- `axion-db-migration`: Completed

---

## 11. Access UI and API

Since the services use `NodePort`, you can access them via the Minikube IP or a tunnel.

### Preferred Method (Tunnel)
Use the `minikube service` command to create a localhost tunnel:

**UI Access:**
```powershell
minikube service axion-ui -n axion-minikube --url
```

**Query API Access:**
```powershell
minikube service axion-telemetry-query-service -n axion-minikube --url
```

### Fallback (Direct IP)
Retrieve the Minikube IP and NodePorts:
```powershell
minikube ip
kubectl get svc -n axion-minikube
```
Access via `http://<minikube-ip>:<node-port>`.

---

## 12. Swagger UI

The Telemetry Query API provides automatic documentation.
Access it by appending `/docs` to the Query API URL obtained in the previous step.

---

## 13. End-to-End Validation

Verify the full data pipeline:
`Simulator` $\rightarrow$ `Ingestion` $\rightarrow$ `PostgreSQL` $\rightarrow$ `Query API` $\rightarrow$ `UI`

### Log Inspection
```powershell
kubectl logs deployment/axion-data-simulator -n axion-minikube
kubectl logs deployment/axion-ingestion-service -n axion-minikube
kubectl logs deployment/axion-telemetry-query-service -n axion-minikube
kubectl logs deployment/axion-ui -n axion-minikube
```

### Data Verification
Verify that telemetry rows exist in the database using a temporary pod:
```powershell
kubectl run pg-check --rm -it --image=postgres:16-alpine -n axion-minikube -- psql -h axion-postgres -U postgres -d axiondb -c "SELECT count(*) FROM telemetry;"
```

---

## 14. Troubleshooting

### A. Pod CrashLoopBackOff
Check logs for the failing pod:
```powershell
kubectl logs <pod-name> -n axion-minikube
```

### B. PostgreSQL Authentication Failure
Verify the `axion-postgres-secret`. Credentials are initialized when the PVC is first created. If you change the secret, you must delete the PVC to reset the DB:
```powershell
kubectl delete pvc axion-postgres-pvc -n axion-minikube
```

### C. Database Schema Errors
Ensure the authoritative SQL files in `axion-database-schema/` are used. Rerun the migration job:
```powershell
kubectl delete job axion-db-migration -n axion-minikube
kubectl apply -f k8s/minikube/postgres/migration-job.yaml
```

### D. UI Opens but API Doesn't Work
The UI runs in your browser, so it cannot resolve internal K8s DNS. The `VITE_API_BASE` must be a URL reachable from your Windows host (the NodePort or tunnel URL).

### E. NodePort Inaccessible from Windows
If the Docker driver is used, direct IP access may be blocked. Always use:
```powershell
minikube service <service-name> -n axion-minikube --url
```

### F. Migration Job Failure
Check the migration logs:
```powershell
kubectl logs job/axion-db-migration -n axion-minikube
```

### G. Telemetry Query Readiness Failure
Ensure probes target `/devices`. Check the `deployment.yaml` for `axion-telemetry-query-service` to verify the `readinessProbe` path.

---

## 15. Cleanup / Delete Deployment

### Using the Script
```powershell
.\scripts\delete-minikube.ps1
```

### Manual Fallback
```powershell
kubectl delete namespace axion-minikube
```
*Warning: Deleting the `axion-postgres-pvc` removes all local telemetry data.*

---

## 16. Redeploy From Scratch

For a complete fresh start:
1. `minikube start`
2. Build local images (`:minikube` tags)
3. `minikube image load <images>`
4. Create `axion-postgres-secret`
5. `kubectl apply -k k8s/minikube`
6. Verify `axion-postgres` is Running
7. Execute `axion-db-migration`
8. Verify all pods are Ready
9. Test API and UI access
10. Verify telemetry data flow

---

## 17. Important Development Notes

- **Environment**: Minikube is for local dev/test only.
- **Isolation**: Minikube PostgreSQL is entirely separate from any host-installed PostgreSQL.
- **Secrets**: NEVER commit real Kubernetes Secret values to Git.
- **UI Config**: `VITE_API_BASE` is a build-time configuration for the UI.
- **DNS**: Internal DNS (e.g., `axion-postgres`) only works for pods inside the cluster.

---

## 18. Quick Reference

| Action | Command |
| :--- | :--- |
| Start Cluster | `minikube start` |
| Cluster IP | `minikube ip` |
| Deploy All | `kubectl apply -k k8s/minikube` |
| Get Pods | `kubectl get pods -n axion-minikube` |
| Get Services | `kubectl get svc -n axion-minikube` |
| UI Tunnel | `minikube service axion-ui -n axion-minikube --url` |
| API Tunnel | `minikube service axion-telemetry-query-service -n axion-minikube --url` |
| Delete All | `.\scripts\delete-minikube.ps1` |
