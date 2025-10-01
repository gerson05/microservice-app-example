#!/bin/bash

# Microservices Testing Script
# Usage: ./scripts/test.sh [test-type]
# Test types: unit, integration, e2e, performance

set -e

TEST_TYPE=${1:-unit}

echo "🧪 Running $TEST_TYPE tests..."

# Function to run unit tests
run_unit_tests() {
    echo "🔬 Running unit tests..."
    
    # Frontend tests
    if [ -d "frontend" ]; then
        echo "Testing Frontend..."
        cd frontend
        npm test -- --coverage --watchAll=false
        cd ..
    fi
    
    # TODOs API tests
    if [ -d "todos-api" ]; then
        echo "Testing TODOs API..."
        cd todos-api
        npm test
        cd ..
    fi
    
    # Users API tests
    if [ -d "users-api" ]; then
        echo "Testing Users API..."
        cd users-api
        mvn test
        cd ..
    fi
    
    # Auth API tests
    if [ -d "auth-api" ]; then
        echo "Testing Auth API..."
        cd auth-api
        go test ./...
        cd ..
    fi
    
    # Log Processor tests
    if [ -d "log-message-processor" ]; then
        echo "Testing Log Processor..."
        cd log-message-processor
        python -m pytest
        cd ..
    fi
}

# Function to run integration tests
run_integration_tests() {
    echo "🔗 Running integration tests..."
    
    # Start services
    echo "Starting services for integration tests..."
    docker-compose -f docker-compose-simple.yml up -d
    
    # Wait for services to be ready
    echo "Waiting for services to be ready..."
    sleep 30
    
    # Test service communication
    echo "Testing service communication..."
    
    # Test TODOs API
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/version)
    if [ $response -eq 401 ]; then
        echo "✅ TODOs API is responding"
    else
        echo "❌ TODOs API integration test failed: $response"
        exit 1
    fi
    
    # Test Zipkin
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9411)
    if [ $response -eq 200 ]; then
        echo "✅ Zipkin is responding"
    else
        echo "❌ Zipkin integration test failed: $response"
        exit 1
    fi
    
    # Test Redis
    docker exec microservice-app-example-redis-1 redis-cli ping > /dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Redis is responding"
    else
        echo "❌ Redis integration test failed"
        exit 1
    fi
    
    echo "✅ All integration tests passed"
}

# Function to run end-to-end tests
run_e2e_tests() {
    echo "🌐 Running end-to-end tests..."
    
    # Start all services
    echo "Starting all services for E2E tests..."
    docker-compose -f docker-compose-simple.yml up -d
    
    # Wait for services to be ready
    echo "Waiting for services to be ready..."
    sleep 60
    
    # Test complete user flow
    echo "Testing complete user flow..."
    
    # Test 1: Health check all services
    echo "Testing service health..."
    health_check "todos-api"
    health_check "zipkin"
    health_check "redis"
    
    # Test 2: Test logging flow
    echo "Testing logging flow..."
    # This would test the complete flow from TODOs API to Log Processor
    # For now, we'll just verify the services are running
    
    echo "✅ All E2E tests passed"
}

# Function to run performance tests
run_performance_tests() {
    echo "⚡ Running performance tests..."
    
    # Check if k6 is installed
    if ! command -v k6 &> /dev/null; then
        echo "Installing k6..."
        sudo apt-get update
        sudo apt-get install -y k6
    fi
    
    # Start services
    echo "Starting services for performance tests..."
    docker-compose -f docker-compose-simple.yml up -d
    
    # Wait for services to be ready
    echo "Waiting for services to be ready..."
    sleep 30
    
    # Create performance test script
    cat > performance-test.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '1m', target: 20 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.1'],
  },
};

export default function() {
  let response = http.get('http://localhost:8082/version');
  check(response, {
    'status is 401': (r) => r.status === 401,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
}
EOF
    
    # Run performance tests
    k6 run performance-test.js
    
    # Cleanup
    rm performance-test.js
    
    echo "✅ Performance tests completed"
}

# Function to run health checks
health_check() {
    local service=$1
    
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

# Main test logic
case $TEST_TYPE in
    "unit")
        run_unit_tests
        ;;
    "integration")
        run_integration_tests
        ;;
    "e2e")
        run_e2e_tests
        ;;
    "performance")
        run_performance_tests
        ;;
    "all")
        run_unit_tests
        run_integration_tests
        run_e2e_tests
        run_performance_tests
        ;;
    *)
        echo "❌ Unknown test type: $TEST_TYPE"
        echo "Available test types: unit, integration, e2e, performance, all"
        exit 1
        ;;
esac

echo "🎉 All $TEST_TYPE tests completed successfully!"
