#!/bin/bash

# Azure Container Apps Deployment Script
# This script deploys the microservices to Azure Container Apps

set -e

# Configuration
RESOURCE_GROUP="microservices-rg"
LOCATION="East US"
ENVIRONMENT_NAME="microservices-env"
ACR_NAME="microservicesacr"
SUBSCRIPTION_ID="your-subscription-id"

echo "🚀 Starting Azure Container Apps deployment..."

# Login to Azure (if not already logged in)
echo "📝 Logging in to Azure..."
az login

# Set subscription
echo "🔧 Setting subscription..."
az account set --subscription $SUBSCRIPTION_ID

# Create resource group if it doesn't exist
echo "📦 Creating resource group..."
az group create --name $RESOURCE_GROUP --location "$LOCATION"

# Create Container Apps Environment
echo "🌍 Creating Container Apps Environment..."
az containerapp env create \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION"

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer --output tsv)

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query passwords[0].value --output tsv)

# Deploy each container app
echo "📦 Deploying container apps..."

# Deploy Elasticsearch first (dependency for Zipkin)
echo "  🔍 Deploying Elasticsearch..."
az containerapp create \
  --name elasticsearch-app \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --image docker.elastic.co/elasticsearch/elasticsearch:7.17.0 \
  --target-port 9200 \
  --ingress internal \
  --cpu 1.0 \
  --memory 2Gi \
  --min-replicas 1 \
  --max-replicas 1 \
  --env-vars discovery.type=single-node ES_JAVA_OPTS="-Xms1g -Xmx1g"

# Deploy Zipkin
echo "  🔍 Deploying Zipkin..."
az containerapp create \
  --name zipkin-app \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --image openzipkin/zipkin:latest \
  --target-port 9411 \
  --ingress internal \
  --cpu 0.25 \
  --memory 512Mi \
  --min-replicas 1 \
  --max-replicas 1 \
  --env-vars STORAGE_TYPE=elasticsearch ES_HOSTS="https://elasticsearch-app.internal:9200"

# Deploy Log Processor
echo "  📝 Deploying Log Processor..."
az containerapp create \
  --name log-processor-app \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --image $ACR_LOGIN_SERVER/log-message-processor:latest \
  --ingress internal \
  --cpu 0.1 \
  --memory 256Mi \
  --min-replicas 1 \
  --max-replicas 2 \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --env-vars REDIS_HOST="microservices-redis.redis.cache.windows.net" REDIS_PORT=6380 REDIS_CHANNEL=log_channel ZIPKIN_URL="https://zipkin-app.internal/api/v2/spans"

# Deploy Users API
echo "  👥 Deploying Users API..."
az containerapp create \
  --name users-api-app \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --image $ACR_LOGIN_SERVER/users-api:latest \
  --target-port 8083 \
  --ingress internal \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 1 \
  --max-replicas 3 \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --env-vars SERVER_PORT=8083 JWT_SECRET="myfancysecret" SPRING_ZIPKIN_BASEURL="https://zipkin-app.internal/" SPRING_PROFILES_ACTIVE=production SPRING_REDIS_HOST="microservices-redis.redis.cache.windows.net" SPRING_REDIS_PORT=6380

# Deploy Auth API
echo "  🔐 Deploying Auth API..."
az containerapp create \
  --name auth-api-app \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --image $ACR_LOGIN_SERVER/auth-api:latest \
  --target-port 8081 \
  --ingress internal \
  --cpu 0.25 \
  --memory 512Mi \
  --min-replicas 1 \
  --max-replicas 3 \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --env-vars AUTH_API_PORT=8081 JWT_SECRET="myfancysecret" USERS_API_ADDRESS="https://users-api-app.internal" ZIPKIN_URL="https://zipkin-app.internal/api/v2/spans"

# Deploy Todos API
echo "  ✅ Deploying Todos API..."
az containerapp create \
  --name todos-api-app \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --image $ACR_LOGIN_SERVER/todos-api:latest \
  --target-port 8082 \
  --ingress internal \
  --cpu 0.25 \
  --memory 512Mi \
  --min-replicas 1 \
  --max-replicas 5 \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --env-vars TODO_API_PORT=8082 JWT_SECRET="myfancysecret" REDIS_HOST="microservices-redis.redis.cache.windows.net" REDIS_PORT=6380 REDIS_CHANNEL=log_channel ZIPKIN_URL="https://zipkin-app.internal/api/v2/spans"

# Deploy Frontend
echo "  🎨 Deploying Frontend..."
az containerapp create \
  --name frontend-app \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --image $ACR_LOGIN_SERVER/frontend:latest \
  --target-port 8080 \
  --ingress external \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 1 \
  --max-replicas 3 \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --env-vars NODE_ENV=production AUTH_API_ADDRESS="https://auth-api-app.internal" TODOS_API_ADDRESS="https://todos-api-app.internal" ZIPKIN_URL="https://zipkin-app.internal/api/v2/spans"

# Deploy Monitoring
echo "  📊 Deploying Monitoring..."
az containerapp create \
  --name monitoring-app \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --image $ACR_LOGIN_SERVER/monitoring:latest \
  --target-port 3000 \
  --ingress external \
  --cpu 0.25 \
  --memory 512Mi \
  --min-replicas 1 \
  --max-replicas 1 \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --env-vars GF_SECURITY_ADMIN_PASSWORD="admin123"

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Application URLs:"
echo "  Frontend: https://frontend-app.$(az containerapp env show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --query defaultDomain --output tsv)"
echo "  Monitoring: https://monitoring-app.$(az containerapp env show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --query defaultDomain --output tsv)"
echo ""
echo "📊 To view logs:"
echo "  az containerapp logs show --name frontend-app --resource-group $RESOURCE_GROUP --follow"
echo ""
echo "🔧 To scale apps:"
echo "  az containerapp update --name frontend-app --resource-group $RESOURCE_GROUP --min-replicas 2 --max-replicas 5"
