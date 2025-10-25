# devops-dashboard

A DevOps showcase with two NestJS microservices (`users-service`, `tasks-service`) deployed via Helm to Kubernetes (AKS), with CI/CD and IaC.

## Quick start (local)
```bash
# Users service
cd services/users-service
npm install
npm run build
npm run start:prod  # http://localhost:3001

# Tasks service
cd ../tasks-service
npm install
npm run build
npm run start:prod  # http://localhost:3002
```

## Docker build
```bash
docker build -t users-service:local services/users-service
docker run -p 3001:3001 users-service:local

docker build -t tasks-service:local services/tasks-service
docker run -p 3002:3002 tasks-service:local
```

## Helm deploy (example)
```bash
# After pushing images to ACR and having kubeconfig for AKS
helm upgrade --install users-service charts/users-service --set image.repository=YOUR_ACR.azurecr.io/users-service --set image.tag=latest
helm upgrade --install tasks-service charts/tasks-service --set image.repository=YOUR_ACR.azurecr.io/tasks-service --set image.tag=latest
```
