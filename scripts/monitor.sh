#!/bin/bash

# Microservices Monitoring Script
# Usage: ./scripts/monitor.sh [action]
# Actions: status, logs, metrics, alerts

set -e

ACTION=${1:-status}

echo "📊 Microservices Monitoring - $ACTION"

# Function to show service status
show_status() {
    echo "🔍 Service Status:"
    echo "=================="
    
    # Check Docker Compose services
    if [ -f "docker-compose-simple.yml" ]; then
        echo "Docker Compose Services:"
        docker-compose -f docker-compose-simple.yml ps
        echo ""
    fi
    
    # Check individual service health
    echo "Health Checks:"
    echo "=============="
    
    # TODOs API
    if curl -s -f http://localhost:8082/version > /dev/null 2>&1; then
        echo "✅ TODOs API (port 8082) - Healthy"
    else
        echo "❌ TODOs API (port 8082) - Unhealthy"
    fi
    
    # Zipkin
    if curl -s -f http://localhost:9411 > /dev/null 2>&1; then
        echo "✅ Zipkin (port 9411) - Healthy"
    else
        echo "❌ Zipkin (port 9411) - Unhealthy"
    fi
    
    # Redis
    if docker exec microservice-app-example-redis-1 redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis (port 6379) - Healthy"
    else
        echo "❌ Redis (port 6379) - Unhealthy"
    fi
}

# Function to show service logs
show_logs() {
    local service=${2:-all}
    
    echo "📋 Service Logs:"
    echo "==============="
    
    if [ "$service" = "all" ]; then
        docker-compose -f docker-compose-simple.yml logs --tail=50
    else
        docker-compose -f docker-compose-simple.yml logs --tail=50 $service
    fi
}

# Function to show metrics
show_metrics() {
    echo "📈 Service Metrics:"
    echo "=================="
    
    # Docker stats
    echo "Docker Container Stats:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
    
    # Service-specific metrics
    echo "Service Response Times:"
    echo "----------------------"
    
    # TODOs API response time
    if command -v curl &> /dev/null; then
        response_time=$(curl -o /dev/null -s -w '%{time_total}' http://localhost:8082/version 2>/dev/null || echo "N/A")
        echo "TODOs API: ${response_time}s"
    fi
    
    # Zipkin response time
    if command -v curl &> /dev/null; then
        response_time=$(curl -o /dev/null -s -w '%{time_total}' http://localhost:9411 2>/dev/null || echo "N/A")
        echo "Zipkin: ${response_time}s"
    fi
    
    # Redis ping time
    if docker exec microservice-app-example-redis-1 redis-cli ping > /dev/null 2>&1; then
        echo "Redis: < 1ms"
    else
        echo "Redis: N/A"
    fi
}

# Function to show alerts
show_alerts() {
    echo "🚨 Service Alerts:"
    echo "================="
    
    # Check for error logs
    echo "Error Logs (last 10):"
    docker-compose -f docker-compose-simple.yml logs --tail=100 | grep -i error | tail -10 || echo "No errors found"
    echo ""
    
    # Check for warning logs
    echo "Warning Logs (last 10):"
    docker-compose -f docker-compose-simple.yml logs --tail=100 | grep -i warning | tail -10 || echo "No warnings found"
    echo ""
    
    # Check service health
    echo "Health Status:"
    unhealthy_services=()
    
    if ! curl -s -f http://localhost:8082/version > /dev/null 2>&1; then
        unhealthy_services+=("TODOs API")
    fi
    
    if ! curl -s -f http://localhost:9411 > /dev/null 2>&1; then
        unhealthy_services+=("Zipkin")
    fi
    
    if ! docker exec microservice-app-example-redis-1 redis-cli ping > /dev/null 2>&1; then
        unhealthy_services+=("Redis")
    fi
    
    if [ ${#unhealthy_services[@]} -eq 0 ]; then
        echo "✅ All services are healthy"
    else
        echo "❌ Unhealthy services: ${unhealthy_services[*]}"
    fi
}

# Function to generate monitoring report
generate_report() {
    local report_file="monitoring-report-$(date +%Y%m%d-%H%M%S).md"
    
    echo "📊 Generating monitoring report: $report_file"
    
    cat > $report_file << EOF
# Microservices Monitoring Report
Generated: $(date)

## Service Status
EOF
    
    # Add service status to report
    docker-compose -f docker-compose-simple.yml ps >> $report_file
    
    cat >> $report_file << EOF

## Health Checks
EOF
    
    # Add health checks to report
    if curl -s -f http://localhost:8082/version > /dev/null 2>&1; then
        echo "✅ TODOs API - Healthy" >> $report_file
    else
        echo "❌ TODOs API - Unhealthy" >> $report_file
    fi
    
    if curl -s -f http://localhost:9411 > /dev/null 2>&1; then
        echo "✅ Zipkin - Healthy" >> $report_file
    else
        echo "❌ Zipkin - Unhealthy" >> $report_file
    fi
    
    if docker exec microservice-app-example-redis-1 redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis - Healthy" >> $report_file
    else
        echo "❌ Redis - Unhealthy" >> $report_file
    fi
    
    cat >> $report_file << EOF

## Resource Usage
EOF
    
    # Add resource usage to report
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" >> $report_file
    
    cat >> $report_file << EOF

## Recent Logs
EOF
    
    # Add recent logs to report
    docker-compose -f docker-compose-simple.yml logs --tail=20 >> $report_file
    
    echo "✅ Monitoring report generated: $report_file"
}

# Main monitoring logic
case $ACTION in
    "status")
        show_status
        ;;
    "logs")
        show_logs $@
        ;;
    "metrics")
        show_metrics
        ;;
    "alerts")
        show_alerts
        ;;
    "report")
        generate_report
        ;;
    "all")
        show_status
        echo ""
        show_metrics
        echo ""
        show_alerts
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Available actions: status, logs, metrics, alerts, report, all"
        exit 1
        ;;
esac

echo "🎉 Monitoring completed!"
