# Microservices Makefile
# Usage: make [target]

.PHONY: help build test deploy monitor clean

# Default target
help:
	@echo "Microservices Management Commands:"
	@echo "=================================="
	@echo "build          - Build all Docker images"
	@echo "test           - Run all tests"
	@echo "test-unit      - Run unit tests only"
	@echo "test-integration - Run integration tests only"
	@echo "test-e2e       - Run end-to-end tests only"
	@echo "test-performance - Run performance tests only"
	@echo "deploy-dev     - Deploy to development environment"
	@echo "deploy-staging - Deploy to staging environment"
	@echo "deploy-prod    - Deploy to production environment"
	@echo "monitor        - Show service status and metrics"
	@echo "monitor-logs   - Show service logs"
	@echo "monitor-alerts - Show service alerts"
	@echo "clean          - Clean up Docker containers and images"
	@echo "setup          - Initial setup and configuration"

# Build targets
build:
	@echo "Building all Docker images..."
	docker-compose -f docker-compose-simple.yml build

build-staging:
	@echo "Building staging images..."
	docker-compose -f docker-compose-staging.yml build

build-prod:
	@echo "Building production images..."
	docker-compose -f docker-compose-prod.yml build

# Test targets
test:
	@echo "Running all tests..."
	./scripts/test.sh all

test-unit:
	@echo "Running unit tests..."
	./scripts/test.sh unit

test-integration:
	@echo "Running integration tests..."
	./scripts/test.sh integration

test-e2e:
	@echo "Running end-to-end tests..."
	./scripts/test.sh e2e

test-performance:
	@echo "Running performance tests..."
	./scripts/test.sh performance

# Deploy targets
deploy-dev:
	@echo "Deploying to development environment..."
	./scripts/deploy.sh dev all

deploy-staging:
	@echo "Deploying to staging environment..."
	./scripts/deploy.sh staging all

deploy-prod:
	@echo "Deploying to production environment..."
	./scripts/deploy.sh prod all

# Monitor targets
monitor:
	@echo "Showing service status and metrics..."
	./scripts/monitor.sh all

monitor-status:
	@echo "Showing service status..."
	./scripts/monitor.sh status

monitor-logs:
	@echo "Showing service logs..."
	./scripts/monitor.sh logs

monitor-metrics:
	@echo "Showing service metrics..."
	./scripts/monitor.sh metrics

monitor-alerts:
	@echo "Showing service alerts..."
	./scripts/monitor.sh alerts

monitor-report:
	@echo "Generating monitoring report..."
	./scripts/monitor.sh report

# Cleanup targets
clean:
	@echo "Cleaning up Docker containers and images..."
	docker-compose -f docker-compose-simple.yml down
	docker-compose -f docker-compose-staging.yml down
	docker-compose -f docker-compose-prod.yml down
	docker system prune -f

clean-images:
	@echo "Cleaning up Docker images..."
	docker image prune -f

clean-volumes:
	@echo "Cleaning up Docker volumes..."
	docker volume prune -f

# Setup targets
setup:
	@echo "Setting up microservices environment..."
	@echo "Creating necessary directories..."
	mkdir -p monitoring nginx/ssl
	@echo "Copying environment configuration..."
	cp env.example .env
	@echo "Setup completed! Please update .env file with your configuration."

# Development targets
dev:
	@echo "Starting development environment..."
	docker-compose -f docker-compose-simple.yml up -d

dev-logs:
	@echo "Showing development logs..."
	docker-compose -f docker-compose-simple.yml logs -f

dev-stop:
	@echo "Stopping development environment..."
	docker-compose -f docker-compose-simple.yml down

# Staging targets
staging:
	@echo "Starting staging environment..."
	docker-compose -f docker-compose-staging.yml up -d

staging-logs:
	@echo "Showing staging logs..."
	docker-compose -f docker-compose-staging.yml logs -f

staging-stop:
	@echo "Stopping staging environment..."
	docker-compose -f docker-compose-staging.yml down

# Production targets
prod:
	@echo "Starting production environment..."
	docker-compose -f docker-compose-prod.yml up -d

prod-logs:
	@echo "Showing production logs..."
	docker-compose -f docker-compose-prod.yml logs -f

prod-stop:
	@echo "Stopping production environment..."
	docker-compose -f docker-compose-prod.yml down

# Health check targets
health:
	@echo "Running health checks..."
	./scripts/monitor.sh status

# Security targets
security-scan:
	@echo "Running security scan..."
	docker run --rm -v $(PWD):/app aquasec/trivy fs /app

# Backup targets
backup:
	@echo "Creating backup..."
	docker-compose -f docker-compose-simple.yml exec redis redis-cli BGSAVE
	@echo "Backup completed"

# Restore targets
restore:
	@echo "Restoring from backup..."
	@echo "Please implement restore logic based on your backup strategy"
