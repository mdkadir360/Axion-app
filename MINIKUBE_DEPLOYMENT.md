# MINIKUBE DEPLOYMENT GUIDE

This guide explains how to deploy AXION-APP to a local Minikube cluster.

## 1. Prerequisites
- Minikube installed and running.
- kubectl installed.
- Docker Desktop installed and running.
- PostgreSQL running on Windows host.

## 2. Local Setup
### Docker Environment
Ensure Minikube uses your local Docker runtime to avoid pushing/pulling images:
```powershell
minikube docker-env | Invoke-Expression
```

### PostgreSQL Connectivity
The application connects to PostgreSQL on the Windows host via `host.minikube.internal:5432`. Ensure your `pg_hba.conf` allows connections from the Minikube network range.

## 3. Deployment Steps
### Step 1: Create Namespace
```powershell
kubectl apply -f k8s/minikube/namespace.yaml
```

### Step 2: Create Secrets
Replace placeholders with your actual local PostgreSQL credentials:
```powershell
kubectl create secret generic axion-secrets `
  -n axion-minikube `
  --from-literal=DATABASE_URL="postgresql://postgres:your_password@host.minikube.internal:5432/axiondb" `
  --from-literal=POSTGRES_USER="postgres" `
  --from-literal=POSTGRES_PASSWORD="your_password" `
  --from-literal=POSTGRES_DB="axiondb"
```

### Step 3: Deploy Application
```powershell
kubectl apply -k k8s/minikube/
```

## 4. Accessing the Application
Since these are NodePort services, use minikube to get the URLs:

### Frontend
```powershell
minikube service axion-ui -n axion-minikube --url
```

### Telemetry Query API
```powershell
minikube service axion-telemetry-query-service -n axion-minikube --url
```

### Swagger UI
Append `/docs` to the Query API URL obtained above.

## 5. Verification
- **Pods**: `kubectl get pods -n axion-minikube`
- **Logs**: `kubectl logs -f -l app=axion-ingestion-service -n axion-minikube`
- **Data Flow**: Verify simulator is running and telemetry is appearing in the UI.

## 6. Cleanup
```powershell
kubectl delete -f k8s/minikube/
kubectl delete namespace axion-minikube
```
