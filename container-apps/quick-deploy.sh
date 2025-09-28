#!/bin/bash

# Quick deployment script for Azure Container Apps
# Minimal configuration for testing

set -e

RESOURCE_GROUP="microservices-rg"
ENVIRONMENT_NAME="microservices-env"
ACR_NAME="microservicesacr"
SUBSCRIPTION_ID="403f7746-fa08-44b9-bf1b-63d2cacef9f1"

echo "🚀 Quick deployment to Azure Container Apps..."

# Check if logged in
if ! az account show &> /dev/null; then
    echo "📝 Logging in to Azure..."
    az login
fi

# Set subscription
echo "🔧 Setting subscription..."
az account set --subscription $SUBSCRIPTION_ID

# Create resource group
echo "📦 Creating resource group..."
az group create --name $RESOURCE_GROUP --location "East US" || echo "Resource group exists"

# Create Container Apps Environment
echo "🌍 Creating Container Apps Environment..."
az containerapp env create \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location "East US" || echo "Environment exists"

# Get ACR info
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer --output tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query passwords[0].value --output tsv)

echo "ACR: $ACR_LOGIN_SERVER"

# Deploy Frontend (simplified)
echo "🎨 Deploying Frontend..."
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
  --max-replicas 2 \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --env-vars NODE_ENV=production || \
az containerapp update \
  --name frontend-app \
  --resource-group $RESOURCE_GROUP \
  --image $ACR_LOGIN_SERVER/frontend:latest

# Get URL
FRONTEND_URL=$(az containerapp show --name frontend-app --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" --output tsv)
echo "✅ Frontend deployed: https://$FRONTEND_URL"

echo "📊 Status:"
az containerapp list --resource-group $RESOURCE_GROUP --query "[].{Name:name,Status:properties.provisioningState}" --output table
