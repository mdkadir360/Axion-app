# Cleanup Minikube Deployment
Write-Host "Removing AXION Minikube resources..." -ForegroundColor Cyan
kubectl delete -k k8s/minikube/
kubectl delete namespace axion-minikube
Write-Host "Cleanup complete." -ForegroundColor Green
