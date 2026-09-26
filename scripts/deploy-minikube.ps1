# Local Minikube Deployment Script
# This script automates the deployment of AXION-APP to Minikube.

Write-Host "Checking Prerequisites..." -ForegroundColor Cyan
if (!(Get-Command minikube -ErrorAction SilentlyContinue)) { Write-Error "Minikube not found"; exit }
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) { Write-Error "kubectl not found"; exit }

Write-Host "Starting Minikube..." -ForegroundColor Cyan
minikube status > $null 2>&1
if ($LASTEXITCODE -ne 0) { minikube start }

Write-Host "Configuring Docker Environment..." -ForegroundColor Cyan
# Note: This part usually requires a new shell. Instructions are in MINIKUBE_DEPLOYMENT.md

Write-Host "Deploying AXION to Minikube..." -ForegroundColor Cyan
kubectl apply -f k8s/minikube/namespace.yaml
Write-Host "Please ensure you have created the 'axion-secrets' secret manually as per MINIKUBE_DEPLOYMENT.md" -ForegroundColor Yellow

kubectl apply -k k8s/minikube/

Write-Host "Waiting for rollout..." -ForegroundColor Cyan
kubectl rollout status deployment/axion-ui -n axion-minikube
kubectl rollout status deployment/axion-ingestion-service -n axion-minikube
kubectl rollout status deployment/axion-telemetry-query-service -n axion-minikube

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Frontend URL: $(minikube service axion-ui -n axion-minikube --url)"
Write-Host "API URL: $(minikube service axion-telemetry-query-service -n axion-minikube --url)"
