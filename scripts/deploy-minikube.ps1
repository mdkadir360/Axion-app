# Local Minikube Deployment Script
# This script automates the deployment of AXION-APP to Minikube.

Write-Host "Checking Prerequisites..." -ForegroundColor Cyan
if (!(Get-Command minikube -ErrorAction SilentlyContinue)) { Write-Error "Minikube not found"; exit }
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) { Write-Error "kubectl not found"; exit }

Write-Host "Starting Minikube..." -ForegroundColor Cyan
minikube status > $null 2>&1
if ($LASTEXITCODE -ne 0) { minikube start }

Write-Host "Configuring Docker Environment..." -ForegroundColor Cyan
Write-Host "Ensure you have run: minikube docker-env | Invoke-Expression" -ForegroundColor Yellow

Write-Host "Deploying AXION to Minikube..." -ForegroundColor Cyan
kubectl apply -f k8s/minikube/namespace.yaml

Write-Host "Checking for PostgreSQL Secret..." -ForegroundColor Yellow
# Check if the secret exists
$secretExists = kubectl get secret axion-postgres-secret -n axion-minikube -o jsonpath='{.metadata.name}' 2>$null
if (!$secretExists) {
    Write-Host "PostgreSQL Secret 'axion-postgres-secret' not found." -ForegroundColor Red
    Write-Host "Please create it manually using the following command (replacing placeholders):" -ForegroundColor White
    Write-Host "kubectl create secret generic axion-postgres-secret -n axion-minikube --from-literal=POSTGRES_DB=axiondb --from-literal=POSTGRES_USER=postgres --from-literal=POSTGRES_PASSWORD=<your-password> --from-literal=DATABASE_URL=postgresql://postgres:<your-password>@axion-postgres:5432/axiondb" -ForegroundColor Gray
    Write-Host "Then rerun this script." -ForegroundColor Yellow
    exit
}

kubectl apply -k k8s/minikube/

Write-Host "Waiting for PostgreSQL..." -ForegroundColor Cyan
kubectl rollout status statefulset/axion-postgres -n axion-minikube

Write-Host "Running Database Migrations..." -ForegroundColor Cyan
kubectl delete job axion-db-migration -n axion-minikube 2>$null
kubectl apply -f k8s/minikube/postgres/migration-job.yaml
kubectl wait --for=condition=complete job/axion-db-migration -n axion-minikube --timeout=60s

Write-Host "Waiting for rollout of application services..." -ForegroundColor Cyan
kubectl rollout status deployment/axion-ui -n axion-minikube
kubectl rollout status deployment/axion-ingestion-service -n axion-minikube
kubectl rollout status deployment/axion-telemetry-query-service -n axion-minikube

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Frontend URL: $(minikube service axion-ui -n axion-minikube --url)"
Write-Host "API URL: $(minikube service axion-telemetry-query-service -n axion-minikube --url)"
