#!/bin/bash

# Microservices Deployment Script
# Usage: ./scripts/deploy.sh [environment] [service]
# Environment: dev, staging, prod
# Service: all, frontend, todos-api, users-api, auth-api, log-processor

set -e

ENVIRONMENT=${1:-dev}
SERVICE=${2:-all}

echo "🚀 Starting deployment to $ENVIRONMENT environment..."

# Function to deploy a specific service
deploy_service() {
    local service=$1
    local env=$2
    
    echo "📦 Deploying $service to $env..."
    
    case $service in
        "frontend")
            if [ "$env" = "prod" ]; then
                docker-compose -f docker-compose-prod.yml up -d frontend
            else
                docker-compose -f docker-compose-simple.yml up -d frontend
            fi
            ;;
        "todos-api")
            if [ "$env" = "prod" ]; then
                docker-compose -f docker-compose-prod.yml up -d todos-api
            else
                docker-compose -f docker-compose-simple.yml up -d todos-api
            fi
            ;;
        "users-api")
            if [ "$env" = "prod" ]; then
                docker-compose -f docker-compose-prod.yml up -d users-api
            else
                docker-compose -f docker-compose-simple.yml up -d users-api
            fi
            ;;
        "auth-api")
            if [ "$env" = "prod" ]; then
                docker-compose -f docker-compose-prod.yml up -d auth-api
            else
                docker-compose -f docker-compose-simple.yml up -d auth-api
            fi
            ;;
        "log-processor")
            if [ "$env" = "prod" ]; then
                docker-compose -f docker-compose-prod.yml up -d log-processor
            else
                docker-compose -f docker-compose-simple.yml up -d log-processor
            fi
            ;;
        "all")
            if [ "$env" = "prod" ]; then
                docker-compose -f docker-compose-prod.yml up -d
            else
                docker-compose -f docker-compose-simple.yml up -d
            fi
            ;;
        *)
            echo "❌ Unknown service: $service"
            exit 1
            ;;
    esac
    
    echo "✅ $service deployed successfully to $env"
}

# Function to run health checks
health_check() {
    local service=$1
    local env=$2
    
    echo "🔍 Running health checks for $service..."
    
    case $service in
        "todos-api")
            response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/version)
            if [ $response -eq 401 ]; then
                echo "✅ TODOs API is healthy"
            else
                echo "❌ TODOs API health check failed: $response"
                exit 1
            fi
            ;;
        "zipkin")
            response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9411)
            if [ $response -eq 200 ]; then
                echo "✅ Zipkin is healthy"
            else
                echo "❌ Zipkin health check failed: $response"
                exit 1
            fi
            ;;
        "redis")
            docker exec microservice-app-example-redis-1 redis-cli ping > /dev/null
            if [ $? -eq 0 ]; then
                echo "✅ Redis is healthy"
            else
                echo "❌ Redis health check failed"
                exit 1
            fi
            ;;
    esac
}

# Main deployment logic
echo "🔧 Preparing deployment..."

# Pull latest images
echo "📥 Pulling latest images..."
docker-compose -f docker-compose-simple.yml pull

# Deploy services
deploy_service $SERVICE $ENVIRONMENT

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Run health checks
echo "🏥 Running health checks..."
health_check "todos-api" $ENVIRONMENT
health_check "zipkin" $ENVIRONMENT
health_check "redis" $ENVIRONMENT

echo "🎉 Deployment completed successfully!"
echo "📊 Services status:"
docker-compose -f docker-compose-simple.yml ps
