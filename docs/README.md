# Microservices Application - Polyglot Architecture

[![Build Status](https://github.com/gerson05/microservice-app-example/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/gerson05/microservice-app-example/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Azure](https://img.shields.io/badge/Cloud-Azure-blue.svg)](https://azure.microsoft.com/)

## 📚 Documentación Completa

Este proyecto incluye documentación técnica detallada basada en la implementación real:

### 📖 Documentación Principal
- **[📋 DOCUMENTACION_PROYECTO.md](./DOCUMENTACION_PROYECTO.md)** - Documentación completa del proyecto con arquitectura, patrones, CI/CD y estructura
- **[🔧 TECHNICAL_DETAILS.md](./TECHNICAL_DETAILS.md)** - Detalles técnicos, justificaciones y patrones implementados (Circuit Breaker, Cache Aside, Auto Scaling)
- **[🏗️ ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md)** - Diagramas de arquitectura detallados con Mermaid

### 📋 Documentación Específica
- **[🌿 strategy_branching.md](./strategy_branching.md)** - Estrategia de branching basada en Scrum
- **[🏛️ architecture.md](./architecture.md)** - Arquitectura general del sistema

## 🚀 Inicio Rápido

### Desarrollo Local
```bash
# 1. Clonar el repositorio
git clone https://github.com/gerson05/microservice-app-example.git
cd microservice-app-example

# 2. Ejecutar con Docker Compose
docker-compose up -d

# 3. Acceder a la aplicación
# Frontend: http://localhost:8080
# Zipkin: http://localhost:9411
# Grafana: http://localhost:3000
```

### Producción (Azure Container Apps)
```bash
# 1. Configurar Azure CLI
az login
az account set --subscription <subscription-id>

# 2. Ejecutar script de despliegue
bash container-apps/deploy-fixed-v2.sh
```

## 🏗️ Arquitectura

Sistema de microservicios poliglota que incluye:

- **Frontend**: Vue.js (Puerto 8080)
- **Auth API**: Go (Puerto 8081)
- **Todos API**: Node.js (Puerto 8082)
- **Users API**: Spring Boot (Puerto 8083)
- **Log Processor**: Python
- **Observabilidad**: Zipkin + Elasticsearch + Prometheus + Grafana

## 🛠️ Stack Tecnológico

### Frontend
- **Vue.js 2.3.3** + Bootstrap Vue 0.22.1 + Vue Router 2.6.0 + Vuex 2.3.1
- **Webpack** + Nginx (producción)

### Backend
- **Auth API**: Go 1.22.2 + Echo v3.3.10 + JWT-Go v3.2.0 + GoBreaker v1.0.0
- **Users API**: Java 1.8 + Spring Boot 1.5.6 + H2 Database
- **TODOs API**: Node.js + Express 4.15.4 + Memory-cache 0.2.0 + Redis 2.8.0
- **Log Processor**: Python 3.12 + Redis >=4.0.0 + Py-zipkin

### Infraestructura
- **Containerización**: Docker + Docker Compose
- **Cloud**: Azure AKS + Terraform
- **Message Queue**: Redis 7.0-alpine
- **Observabilidad**: Zipkin + Elasticsearch 7.17.0 + Prometheus + Grafana

### DevOps
- **CI/CD**: GitHub Actions + GitHub Container Registry
- **Security**: Trivy vulnerability scanning
- **Testing**: Jest + Pytest + JUnit + Maven Surefire

## 📊 Características Implementadas

### 🏗️ Arquitectura
- ✅ **5 Microservicios Políglotas**: Vue.js, Go, Java Spring Boot, Node.js, Python
- ✅ **Comunicación Híbrida**: HTTP REST + Redis Pub/Sub
- ✅ **Trazabilidad Distribuida** con Zipkin + Elasticsearch
- ✅ **Infraestructura como Código** con Terraform + Docker Compose

### 🔒 Seguridad y Resiliencia
- ✅ **Autenticación JWT** centralizada entre servicios
- ✅ **Circuit Breaker Pattern** en Auth API (GoBreaker)
- ✅ **Cache Aside Pattern** en TODOs API (Memory-cache)
- ✅ **Auto Scaling** configurado por servicio

### 🚀 DevOps y Monitoreo
- ✅ **CI/CD Pipeline** completo con GitHub Actions
- ✅ **Testing** con Jest, Pytest, JUnit (92.68% cobertura TODOs API)
- ✅ **Security Scanning** con Trivy
- ✅ **Monitoreo Completo** con Prometheus + Grafana + Alertmanager
- ✅ **Health Checks** automáticos

## 🎯 Patrones de Diseño Implementados

### 1. Circuit Breaker Pattern
- **Implementación**: Auth API (Go) con GoBreaker
- **Configuración**: 3 fallos consecutivos abren el circuito
- **Beneficio**: Protege contra fallos en cascada

### 2. Cache Aside Pattern
- **Implementación**: TODOs API (Node.js) con Memory-cache
- **Flujo**: Check cache → Cache miss → Load from DB → Store in cache
- **Beneficio**: 90% reducción en latencia de respuesta

### 3. Auto Scaling Pattern
- **Implementación**: Docker Compose con réplicas configuradas
- **Configuración**: TODOs API (3 réplicas), otros servicios (2 réplicas)
- **Beneficio**: Manejo de carga variable y mejor utilización de recursos

## 🔧 Configuración

### Variables de Entorno Requeridas
```bash
# Azure
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_RESOURCE_GROUP=microservices-rg
ACR_NAME=microservicesacr

# Redis
REDIS_HOST=microservices-redis.redis.cache.windows.net
REDIS_PORT=6380
REDIS_PASSWORD=your-redis-password

# JWT
JWT_SECRET=your-jwt-secret
```

## 🧪 Pruebas

```bash
# Pruebas unitarias por servicio
cd auth-api && go test ./...
cd users-api && mvn test
cd todos-api && npm test
cd log-message-processor && python -m pytest

# Pruebas de integración
docker-compose up -d
curl -f http://localhost:8081/version  # Auth API
curl -f http://localhost:8082/version  # Todos API
curl -f http://localhost:8083/actuator/health  # Users API
```

## 📈 Monitoreo

- **Zipkin**: http://localhost:9411 (trazabilidad distribuida)
- **Grafana**: http://localhost:3000 (dashboards)
- **Prometheus**: http://localhost:9090 (métricas)

## 🗺️ Navegación Rápida

### Para Desarrolladores
- **[📋 DOCUMENTACION_PROYECTO.md](./DOCUMENTACION_PROYECTO.md)** - Documentación completa del proyecto
- **[🔧 TECHNICAL_DETAILS.md](./TECHNICAL_DETAILS.md)** - Detalles técnicos y justificaciones
- **[🏗️ ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md)** - Diagramas de arquitectura

### Para Arquitectos
- **[🏛️ architecture.md](./architecture.md)** - Arquitectura general del sistema
- **[🌿 strategy_branching.md](./strategy_branching.md)** - Estrategia de branching

### Para DevOps
- **[🚀 Inicio Rápido](#-inicio-rápido)** - Comandos de desarrollo y producción
- **[🧪 Pruebas](#-pruebas)** - Testing y validación
- **[📈 Monitoreo](#-monitoreo)** - Herramientas de observabilidad

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

**📚 Documentación completa disponible en la carpeta `docs/`**

