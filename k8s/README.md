# Kubernetes Deployment Commands

## Prerequisites
1. Azure CLI installed and logged in
2. kubectl installed
3. AKS cluster running

## Connect to AKS
```bash
az aks get-credentials --resource-group microservices-rg --name microservices-aks
```

## Deploy all services
```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n microservices
kubectl get services -n microservices
kubectl get ingress -n microservices
```

## Individual service deployment
```bash
# Deploy specific services
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/monitoring/
```

## Monitoring and debugging
```bash
# View logs
kubectl logs -f deployment/frontend -n microservices
kubectl logs -f deployment/auth-api -n microservices
kubectl logs -f deployment/todos-api -n microservices
kubectl logs -f deployment/users-api -n microservices

# Port forwarding for local access
kubectl port-forward service/frontend-service 8080:8080 -n microservices
kubectl port-forward service/zipkin-service 9411:9411 -n microservices
kubectl port-forward service/grafana-service 3000:3000 -n microservices
kubectl port-forward service/prometheus-service 9090:9090 -n microservices
```

## Scaling services
```bash
# Scale deployments
kubectl scale deployment frontend --replicas=3 -n microservices
kubectl scale deployment todos-api --replicas=5 -n microservices
```

## Cleanup
```bash
# Delete all resources
kubectl delete -f k8s/
```
