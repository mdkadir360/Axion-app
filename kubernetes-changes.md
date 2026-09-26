# Kubernetes Deployment Changes

This document tracks the migration of AXION-APP from a local Docker Compose environment to a production-grade Kubernetes cluster.

## 1. Architecture Shift
- **Deployment Target**: Azure Kubernetes Service (AKS) / Kubernetes Cluster.
- **Namespace**: `axion-testsop`.
- **Domain Strategy**: Host-based routing via Ingress.
    - Frontend: `https://axion-ui-testsop.online`
    - Backend API: `https://axion-api-testsop.online`
- **CORS Policy**: Backend updated to explicitly allow requests from `https://axion-ui-testsop.online`.

## 2. Infrastructure Components

### Azure DevOps Pipeline (`azure-pipelines.yml`)
Implemented a 6-stage CI/CD pipeline:
1. **Validate**: Static analysis of manifests and code.
2. **Build**: Docker images built with `$(Build.BuildId)` tags.
3. **Push**: Images pushed to `mdkadir360` Docker Hub namespace.
4. **DB Migration**: Automated schema application via K8s Job.
5. **Deploy**: Manifest application via `<KUBERNETES_SERVICE_CONNECTION_NAME>`.
6. **Verify**: Public endpoint health checks.

### Kubernetes Manifests (`k8s/`)
- **Network**: Ingress configured for HTTPS with TLS secret `axion-ui-testsop-tls`.
- **Compute**:
    - `axion-ui`: 2 replicas, resource limits (200m CPU / 256Mi RAM).
    - `axion-ingestion-service`: 2 replicas, resource limits (500m CPU / 512Mi RAM).
    - `axion-telemetry-query-service`: 2 replicas, resource limits (500m CPU / 512Mi RAM).
    - `axion-data-simulator`: 1 replica, background worker.
- **Config**: Database connection strings injected via K8s Secret from Azure DevOps Variable Group `AXION-TESTSOP-SECRETS`.

## 3. Application Refactoring
- **Frontend**: Refactored all hardcoded API URLs to use `import.meta.env.VITE_API_BASE`.
- **Simulator**: Updated target URL to use the internal K8s service name: `http://axion-ingestion-service:8000`.
- **Backends**: Configured to accept `DATABASE_URL` environment variable for flexible DB connectivity.

## 4. Database Automation
- **Mechanism**: Created `k8s/database/migration-job.yaml`.
- **Logic**: Uses `postgres:alpine` image to execute SQL scripts in order from a ConfigMap.
- **Safety**: Scripts are strictly additive (no `DROP` or `TRUNCATE` operations).

## 5. Verification Summary
- **Docker Build**: PASS
- **Pipeline Syntax**: PASS
- **Manifest Dry-Run**: PASS
- **Security Scan**: PASS (No secrets committed to Git)
