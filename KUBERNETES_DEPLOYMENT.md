# KUBERNETES DEPLOYMENT GUIDE

## 1. Architecture Overview
The AXION-APP is deployed to a Kubernetes cluster using an Azure DevOps CI/CD pipeline. 

**Public Domains:**
- Frontend: `https://axion-ui-testsop.online`
- Backend API: `https://axion-api-testsop.online`

**Network Flow:**
Browser $\rightarrow$ Ingress $\rightarrow$ K8s Service $\rightarrow$ Pod $\rightarrow$ External PostgreSQL.

## 2. Prerequisites
- Kubernetes Cluster with an Nginx Ingress Controller.
- Docker Hub account: `mdkadir360`.
- Azure DevOps Organization.
- External PostgreSQL instance accessible via `host.docker.internal` or a public IP/hostname.

## 3. Azure DevOps Setup

### Service Connections
Create the following service connections in Azure DevOps:
| Connection Name | Type | Purpose |
|---|---|---|
| `<DOCKERHUB_SERVICE_CONNECTION_NAME>` | Docker Registry | Push images to `mdkadir360` |
| `<KUBERNETES_SERVICE_CONNECTION_NAME>` | Kubernetes | Deploy manifests to the cluster |
| `<AZURE_SERVICE_CONNECTION_NAME>` | Azure Resource Manager | General Azure integration |

### Variable Group: `AXION-TESTSOP-SECRETS`
Create a Variable Group named `AXION-TESTSOP-SECRETS` and add the following (mark as secret):
- `DATABASE_URL`: `postgresql://<user>:<pass>@<host>:5432/axiondb`
- `POSTGRES_HOST`: `<hostname>`
- `POSTGRES_USER`: `<username>`
- `POSTGRES_PASSWORD`: `<password>`
- `POSTGRES_DB`: `axiondb`

## 4. DNS Configuration
The following DNS records must be created to point to the Kubernetes Ingress Load Balancer:

| Hostname | Type | Target |
|---|---|---|
| `axion-ui-testsop.online` | A/CNAME | `<KUBERNETES_INGRESS_PUBLIC_IP>` |
| `axion-api-testsop.online` | A/CNAME | `<KUBERNETES_INGRESS_PUBLIC_IP>` |

## 5. TLS/HTTPS Setup
The application requires HTTPS. The Ingress expects a TLS secret named `axion-ui-testsop-tls` in the `axion-testsop` namespace.

**Manual Setup:**
```bash
kubectl create secret tls axion-ui-testsop-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n axion-testsop
```

## 6. Deployment Process
1. Push code to the `feature/k8s` branch.
2. Azure DevOps pipeline triggers automatically.
3. Pipeline builds images $\rightarrow$ pushes to Docker Hub $\rightarrow$ runs DB migration $\rightarrow$ deploys to K8s.

## 7. Verification & Troubleshooting
- **Pod Status**: `kubectl get pods -n axion-testsop`
- **Ingress Status**: `kubectl get ingress -n axion-testsop`
- **Log Inspection**: `kubectl logs -f <pod-name> -n axion-testsop`
- **DB Migration**: Check `kubectl get jobs -n axion-testsop` for the `axion-db-migration` status.

## 8. Rollback
To rollback to a previous version:
```bash
kubectl rollout undo deployment/axion-ui -n axion-testsop
kubectl rollout undo deployment/axion-telemetry-query-service -n axion-testsop
```
