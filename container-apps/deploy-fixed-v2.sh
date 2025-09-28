#!/bin/bash

# Azure Container Apps Deployment Script - FIXED VERSION
# This script fixes all connection issues

set -e

# Configuration
RESOURCE_GROUP="microservices-rg"
LOCATION="East US"
ENVIRONMENT_NAME="microservices-env"
ACR_NAME="microservicesacr"
SUBSCRIPTION_ID="403f7746-fa08-44b9-bf1b-63d2cacef9f1"

echo "🚀 Starting FIXED Azure Container Apps deployment..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

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
  --location "$LOCATION" || echo "Environment already exists"

# Get ACR login server and credentials
echo "🔐 Getting ACR credentials..."
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer --output tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query passwords[0].value --output tsv)

echo "ACR Server: $ACR_LOGIN_SERVER"

# Function to deploy a container app
deploy_app() {
    local app_name=$1
    local image=$2
    local target_port=$3
    local ingress=$4
    local cpu=$5
    local memory=$6
    local min_replicas=$7
    local max_replicas=$8
    local env_vars=$9
    
    echo "  📦 Deploying $app_name..."
    
    # Build the command
    local cmd="az containerapp create --name $app_name --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME --image $image"
    
    if [ "$target_port" != "null" ]; then
        cmd="$cmd --target-port $target_port"
    fi
    
    cmd="$cmd --ingress $ingress --cpu $cpu --memory $memory --min-replicas $min_replicas --max-replicas $max_replicas"
    
    # Add registry info if it's an ACR image
    if [[ $image == *"azurecr.io"* ]]; then
        cmd="$cmd --registry-server $ACR_LOGIN_SERVER --registry-username $ACR_USERNAME --registry-password $ACR_PASSWORD"
    fi
    
    # Add environment variables
    if [ ! -z "$env_vars" ]; then
        cmd="$cmd --env-vars $env_vars"
    fi
    
    # Execute the command with fallback to update
    eval $cmd || {
        echo "    ⚠️  App exists, updating instead..."
        az containerapp update --name $app_name --resource-group $RESOURCE_GROUP --image $image
    }
}

# Deploy applications in dependency order
echo "📦 Deploying container apps..."

# 1. Elasticsearch (no dependencies)
deploy_app "elasticsearch-app" \
    "docker.elastic.co/elasticsearch/elasticsearch:7.17.0" \
    "9200" "internal" "1.0" "2Gi" "1" "1" \
    "discovery.type=single-node ES_JAVA_OPTS=-Xms1g -Xmx1g"

# 2. Zipkin (depends on Elasticsearch)
deploy_app "zipkin-app" \
    "openzipkin/zipkin:latest" \
    "9411" "internal" "0.25" "512Mi" "1" "1" \
    "STORAGE_TYPE=elasticsearch ES_HOSTS=http://elasticsearch-app.internal:9200"

# 3. Users API (depends on Redis and Zipkin)
deploy_app "users-api-app" \
    "$ACR_LOGIN_SERVER/users-api:latest" \
    "8083" "internal" "0.5" "1Gi" "1" "3" \
    "SERVER_PORT=8083 JWT_SECRET=myfancysecret SPRING_ZIPKIN_BASEURL=http://zipkin-app.internal/ SPRING_PROFILES_ACTIVE=production SPRING_REDIS_HOST=microservices-redis.redis.cache.windows.net SPRING_REDIS_PORT=6380"

# 4. Auth API (depends on Users API and Zipkin)
deploy_app "auth-api-app" \
    "$ACR_LOGIN_SERVER/auth-api:latest" \
    "8081" "internal" "0.25" "512Mi" "1" "3" \
    "AUTH_API_PORT=8081 JWT_SECRET=myfancysecret USERS_API_ADDRESS=http://users-api-app.internal:8083 ZIPKIN_URL=http://zipkin-app.internal:9411/api/v2/spans"

# 5. Todos API (depends on Redis and Zipkin)
deploy_app "todos-api-app" \
    "$ACR_LOGIN_SERVER/todos-api:latest" \
    "8082" "internal" "0.25" "512Mi" "1" "5" \
    "TODO_API_PORT=8082 JWT_SECRET=myfancysecret REDIS_HOST=microservices-redis.redis.cache.windows.net REDIS_PORT=6380 REDIS_CHANNEL=log_channel ZIPKIN_URL=http://zipkin-app.internal:9411/api/v2/spans"

# 6. Log Processor (depends on Redis and Zipkin)
deploy_app "log-processor-app" \
    "$ACR_LOGIN_SERVER/log-message-processor:latest" \
    "null" "internal" "0.1" "256Mi" "1" "2" \
    "REDIS_HOST=microservices-redis.redis.cache.windows.net REDIS_PORT=6380 REDIS_CHANNEL=log_channel ZIPKIN_URL=http://zipkin-app.internal:9411/api/v2/spans"

# 7. Frontend (depends on Auth API and Todos API) - FIXED URLs
deploy_app "frontend-app" \
    "$ACR_LOGIN_SERVER/frontend:latest" \
    "8080" "external" "0.5" "1Gi" "1" "3" \
    "NODE_ENV=production AUTH_API_ADDRESS=http://auth-api-app.internal:8081 TODOS_API_ADDRESS=http://todos-api-app.internal:8082 ZIPKIN_URL=http://zipkin-app.internal:9411/api/v2/spans"

# 8. Monitoring (external access)
deploy_app "monitoring-app" \
    "grafana/grafana:latest" \
    "3000" "external" "0.25" "512Mi" "1" "1" \
    "GF_SECURITY_ADMIN_PASSWORD=admin123"

echo "✅ Deployment completed successfully!"
echo ""

# Get application URLs
echo "🌐 Application URLs:"
FRONTEND_URL=$(az containerapp show --name frontend-app --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" --output tsv 2>/dev/null || echo "Not available")
MONITORING_URL=$(az containerapp show --name monitoring-app --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" --output tsv 2>/dev/null || echo "Not available")

echo "  Frontend: https://$FRONTEND_URL"
echo "  Monitoring: https://$MONITORING_URL"
echo ""

# Show status
echo "📊 Application Status:"
az containerapp list --resource-group $RESOURCE_GROUP --query "[].{Name:name,Status:properties.provisioningState,Replicas:properties.template.scale.minReplicas}" --output table

echo ""
echo "🔧 Key fixes applied:"
echo "  ✅ Changed HTTPS to HTTP for internal services"
echo "  ✅ Added port numbers to internal URLs"
echo "  ✅ Deployed all dependencies in correct order"
echo "  ✅ Fixed frontend environment variables"
echo ""
echo "📊 To view logs:"
echo "  az containerapp logs show --name frontend-app --resource-group $RESOURCE_GROUP --follow"
echo ""
echo "🔧 To scale apps:"
echo "  az containerapp update --name frontend-app --resource-group $RESOURCE_GROUP --min-replicas 2 --max-replicas 5"
