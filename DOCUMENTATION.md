# Microservices Application - Polyglot Architecture

## 📋 Tabla de Contenidos
- [Descripción del Proyecto](#descripción-del-proyecto)
- [Arquitectura](#arquitectura)
- [Tecnologías Implementadas](#tecnologías-implementadas)
- [Microservicios](#microservicios)
- [Infraestructura](#infraestructura)
- [Despliegue](#despliegue)
- [Monitoreo y Observabilidad](#monitoreo-y-observabilidad)
- [CI/CD Pipeline](#cicd-pipeline)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Configuración y Variables](#configuración-y-variables)
- [Pruebas](#pruebas)
- [Troubleshooting](#troubleshooting)
- [Contribución](#contribución)

## 🎯 Descripción del Proyecto

Este proyecto implementa una aplicación de microservicios de arquitectura poliglota que demuestra las mejores prácticas en el desarrollo de sistemas distribuidos modernos. La aplicación consiste en un sistema de gestión de tareas (TODOs) con autenticación, trazabilidad distribuida y monitoreo completo.

### Objetivos del Proyecto
- **Demostrar arquitectura de microservicios**: Implementar servicios independientes con diferentes tecnologías
- **Trazabilidad distribuida**: Implementar observabilidad completa con Zipkin y Elasticsearch
- **Escalabilidad**: Diseñar para escalar horizontalmente cada servicio independientemente
- **Resiliencia**: Implementar circuit breakers y manejo de errores robusto
- **DevOps**: Automatizar despliegue y monitoreo con CI/CD

## 🏗️ Arquitectura

### Principios Arquitectónicos

1. **Separación de Responsabilidades**: Cada microservicio tiene una responsabilidad específica
2. **Independencia Tecnológica**: Diferentes lenguajes y frameworks por servicio
3. **Comunicación Asíncrona**: Redis como message broker
4. **Observabilidad**: Trazabilidad completa con Zipkin
5. **Escalabilidad Horizontal**: Cada servicio puede escalarse independientemente

### Flujo de Datos
```
Usuario → Frontend → Auth API → Users API
       ↓
    Todos API ← Redis Cache
       ↓
   Log Processor → Zipkin → Elasticsearch
```

## 🛠️ Tecnologías Implementadas

### Frontend
- **Vue.js 2.x**: Framework progresivo para la interfaz de usuario
- **Bootstrap Vue**: Componentes UI responsivos
- **Vue Resource**: Cliente HTTP para comunicación con APIs
- **Webpack**: Bundling y hot reload en desarrollo

### Backend Services

#### Auth API (Go)
- **Echo Framework**: Web framework ligero y rápido
- **JWT**: Autenticación basada en tokens
- **Circuit Breaker**: Patrón de resiliencia con gobreaker
- **Zipkin**: Trazabilidad distribuida

#### Users API (Spring Boot)
- **Spring Boot 1.5.6**: Framework Java para microservicios
- **Spring Security**: Autenticación y autorización
- **Spring Data JPA**: Persistencia de datos
- **H2 Database**: Base de datos en memoria para desarrollo
- **Redis**: Cache distribuido

#### Todos API (Node.js)
- **Express.js**: Framework web minimalista
- **Redis**: Cache y message queue
- **JWT**: Validación de tokens
- **Zipkin**: Trazabilidad distribuida

#### Log Processor (Python)
- **Redis**: Consumo de mensajes de la cola
- **Zipkin**: Envío de traces
- **Asyncio**: Procesamiento asíncrono

### Infraestructura
- **Docker**: Containerización de servicios
- **Docker Compose**: Orquestación local
- **Azure Container Apps**: Plataforma de contenedores gestionada
- **Azure Redis Cache**: Cache distribuido
- **Azure Container Registry**: Repositorio de imágenes

### Observabilidad
- **Zipkin**: Trazabilidad distribuida
- **Elasticsearch**: Almacenamiento de traces
- **Prometheus**: Métricas y monitoreo
- **Grafana**: Dashboards y visualización
- **Alertmanager**: Gestión de alertas

## 🔧 Microservicios

### 1. Frontend (Vue.js)
**Puerto**: 8080  
**Responsabilidad**: Interfaz de usuario y orquestación de llamadas a APIs

**Características**:
- SPA (Single Page Application) con Vue.js
- Autenticación JWT
- Proxies webpack para desarrollo
- Build optimizado para producción

**Endpoints**:
- `/` - Dashboard principal
- `/login` - Formulario de autenticación
- `/todos` - Gestión de tareas

### 2. Auth API (Go)
**Puerto**: 8081  
**Responsabilidad**: Autenticación y generación de tokens JWT

**Características**:
- Circuit breaker para resiliencia
- Validación de usuarios contra Users API
- Generación de tokens JWT
- Trazabilidad con Zipkin

**Endpoints**:
- `POST /login` - Autenticación de usuarios
- `GET /version` - Health check
- `GET /breaker` - Estado del circuit breaker

### 3. Users API (Spring Boot)
**Puerto**: 8083  
**Responsabilidad**: Gestión de usuarios y roles

**Características**:
- API REST con Spring Boot
- Autenticación JWT
- Cache con Redis
- Base de datos H2 (desarrollo)

**Endpoints**:
- `GET /users` - Lista de usuarios
- `POST /users` - Crear usuario
- `GET /users/{id}` - Obtener usuario

### 4. Todos API (Node.js)
**Puerto**: 8082  
**Responsabilidad**: Gestión de tareas (CRUD)

**Características**:
- API REST con Express.js
- Autenticación JWT
- Cache con Redis
- Message queue para logs

**Endpoints**:
- `GET /todos` - Lista de tareas
- `POST /todos` - Crear tarea
- `DELETE /todos/{id}` - Eliminar tarea

### 5. Log Processor (Python)
**Responsabilidad**: Procesamiento de logs y envío a Zipkin

**Características**:
- Consumidor de Redis queue
- Procesamiento asíncrono
- Envío de traces a Zipkin

## 🏢 Infraestructura

### Desarrollo Local
```yaml
# docker-compose.yml
services:
  redis:          # Cache y message queue
  zipkin:         # Trazabilidad
  elasticsearch:  # Almacenamiento de traces
  users-api:      # Spring Boot
  auth-api:       # Go
  todos-api:      # Node.js
  log-processor:  # Python
  frontend:       # Vue.js
```

### Producción (Azure Container Apps)
- **Container Apps Environment**: Entorno aislado para microservicios
- **Azure Redis Cache**: Cache distribuido y message queue
- **Azure Container Registry**: Repositorio de imágenes Docker
- **Application Insights**: Monitoreo y telemetría

## 🚀 Despliegue

### Desarrollo Local
```bash
# 1. Clonar el repositorio
git clone <repository-url>
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

# 3. Verificar despliegue
az containerapp list --resource-group microservices-rg
```

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

## 📊 Monitoreo y Observabilidad

### Trazabilidad Distribuida (Zipkin)
- **Rastreo de requests**: Seguimiento completo de requests entre servicios
- **Timing**: Medición de latencia en cada servicio
- **Dependencias**: Mapeo de dependencias entre servicios
- **Errores**: Identificación de fallos en la cadena de servicios

### Métricas (Prometheus + Grafana)
- **Métricas de aplicación**: Requests, latencia, errores
- **Métricas de infraestructura**: CPU, memoria, red
- **Dashboards personalizados**: Visualización de KPIs
- **Alertas**: Notificaciones automáticas de problemas

### Logs Centralizados
- **Structured Logging**: Logs estructurados en JSON
- **Correlation IDs**: Identificación de requests únicos
- **Log Aggregation**: Centralización de logs de todos los servicios

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
```yaml
# .github/workflows/ci-cd-pipeline.yml
jobs:
  build-and-test:     # Construcción y pruebas
  security-scan:      # Escaneo de vulnerabilidades
  deploy-staging:     # Despliegue a staging
  deploy-production:  # Despliegue a producción
  integration-tests:  # Pruebas de integración
```

### Características del Pipeline
- **Multi-language support**: Soporte para Go, Java, Node.js, Python
- **Docker builds**: Construcción automática de imágenes
- **Security scanning**: Escaneo con Trivy
- **Automated deployment**: Despliegue automático a Azure
- **Rollback capability**: Capacidad de rollback automático

## 📁 Estructura del Proyecto

```
microservice-app-example/
├── auth-api/                 # Servicio de autenticación (Go)
│   ├── main.go
│   ├── user.go
│   ├── tracing.go
│   └── Dockerfile
├── users-api/                # Servicio de usuarios (Spring Boot)
│   ├── src/main/java/
│   ├── pom.xml
│   └── Dockerfile
├── todos-api/                # Servicio de tareas (Node.js)
│   ├── server.js
│   ├── routes.js
│   ├── package.json
│   └── Dockerfile
├── log-message-processor/    # Procesador de logs (Python)
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/                 # Aplicación frontend (Vue.js)
│   ├── src/
│   ├── build/
│   ├── config/
│   ├── package.json
│   └── Dockerfile
├── container-apps/           # Configuración Azure Container Apps
│   ├── deploy-fixed-v2.sh
│   ├── quick-deploy.sh
│   └── apps.json
├── monitoring/               # Configuración de monitoreo
│   ├── prometheus.yml
│   ├── alertmanager.yml
│   └── alert_rules.yml
├── infrastructure/           # Infraestructura como código (Terraform)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .github/workflows/        # CI/CD Pipeline
│   └── ci-cd-pipeline.yml
├── docker-compose.yml        # Orquestación local
├── docker-compose-prod.yml   # Orquestación producción
└── DOCUMENTATION.md          # Esta documentación
```

## ⚙️ Configuración y Variables

### Variables de Entorno por Servicio

#### Frontend
```bash
NODE_ENV=production
AUTH_API_ADDRESS=http://auth-api-app.internal:8081
TODOS_API_ADDRESS=http://todos-api-app.internal:8082
ZIPKIN_URL=http://zipkin-app.internal:9411/api/v2/spans
```

#### Auth API
```bash
AUTH_API_PORT=8081
JWT_SECRET=myfancysecret
USERS_API_ADDRESS=http://users-api-app.internal:8083
ZIPKIN_URL=http://zipkin-app.internal:9411/api/v2/spans
```

#### Users API
```bash
SERVER_PORT=8083
JWT_SECRET=myfancysecret
SPRING_ZIPKIN_BASEURL=http://zipkin-app.internal/
SPRING_REDIS_HOST=microservices-redis.redis.cache.windows.net
SPRING_REDIS_PORT=6380
```

#### Todos API
```bash
TODO_API_PORT=8082
JWT_SECRET=myfancysecret
REDIS_HOST=microservices-redis.redis.cache.windows.net
REDIS_PORT=6380
REDIS_CHANNEL=log_channel
ZIPKIN_URL=http://zipkin-app.internal:9411/api/v2/spans
```

## 🧪 Pruebas

### Pruebas Unitarias
```bash
# Go (Auth API)
cd auth-api && go test ./...

# Java (Users API)
cd users-api && mvn test

# Node.js (Todos API)
cd todos-api && npm test

# Python (Log Processor)
cd log-message-processor && python -m pytest
```

### Pruebas de Integración
```bash
# Ejecutar con Docker Compose
docker-compose up -d
sleep 30

# Health checks
curl -f http://localhost:8081/version  # Auth API
curl -f http://localhost:8082/version  # Todos API
curl -f http://localhost:8083/actuator/health  # Users API
curl -f http://localhost:9411  # Zipkin
```

### Pruebas de Carga
```bash
# Usando k6 (incluido en monitoring pipeline)
k6 run performance-test.js
```

## 🔧 Troubleshooting

### Problemas Comunes

#### 1. Frontend no se conecta a APIs
**Síntoma**: Error 404 o timeout en llamadas a APIs  
**Solución**: Verificar que todos los servicios estén desplegados y las URLs sean correctas

```bash
# Verificar servicios desplegados
az containerapp list --resource-group microservices-rg

# Verificar logs del frontend
az containerapp logs show --name frontend-app --resource-group microservices-rg
```

#### 2. Error de autenticación
**Síntoma**: Error 401 en llamadas autenticadas  
**Solución**: Verificar que el JWT_SECRET sea el mismo en todos los servicios

#### 3. Redis connection failed
**Síntoma**: Error de conexión a Redis  
**Solución**: Verificar configuración de Azure Redis Cache

```bash
# Verificar Redis
az redis show --name microservices-redis --resource-group microservices-rg
```

#### 4. Zipkin no muestra traces
**Síntoma**: No aparecen traces en Zipkin UI  
**Solución**: Verificar que Elasticsearch esté funcionando y Zipkin esté configurado correctamente

### Comandos de Diagnóstico

```bash
# Ver logs de todos los servicios
az containerapp list --resource-group microservices-rg --query '[].name' --output tsv | \
  xargs -I {} az containerapp logs show --name {} --resource-group microservices-rg

# Ver estado de los servicios
az containerapp list --resource-group microservices-rg --output table

# Escalar un servicio
az containerapp update --name frontend-app --resource-group microservices-rg --min-replicas 2 --max-replicas 5
```

## 🤝 Contribución

### Proceso de Desarrollo
1. **Fork** del repositorio
2. **Feature branch** para nuevas funcionalidades
3. **Commit** con mensajes descriptivos
4. **Push** a la rama feature
5. **Pull Request** para revisión

### Estándares de Código
- **Go**: `gofmt` y `golint`
- **Java**: Maven checkstyle
- **JavaScript**: ESLint
- **Python**: PEP 8

### Testing
- Cobertura mínima del 80%
- Pruebas unitarias para cada servicio
- Pruebas de integración para flujos completos

## 📚 Referencias y Recursos

### Documentación Oficial
- [Vue.js Documentation](https://vuejs.org/)
- [Spring Boot Reference](https://spring.io/projects/spring-boot)
- [Express.js Guide](https://expressjs.com/)
- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)

### Herramientas de Observabilidad
- [Zipkin Documentation](https://zipkin.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Patrones de Microservicios
- [Microservices Patterns](https://microservices.io/)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Distributed Tracing](https://opentracing.io/)

---

## 📞 Contacto

**Desarrollador**: [Tu Nombre]  
**Email**: [tu-email@ejemplo.com]  
**GitHub**: [tu-usuario-github]

---

*Este proyecto fue desarrollado como parte del curso de DevOps y Arquitectura de Microservicios, demostrando las mejores prácticas en el desarrollo de sistemas distribuidos modernos.*
