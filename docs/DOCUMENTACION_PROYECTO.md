# Documentación del Proyecto: Microservicios con Arquitectura Distribuida

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Microservicios Implementados](#microservicios-implementados)
4. [Patrones de Diseño](#patrones-de-diseño)
5. [Tecnologías y Stack Tecnológico](#tecnologías-y-stack-tecnológico)
6. [Estrategia de Branching](#estrategia-de-branching)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Infraestructura como Código](#infraestructura-como-código)
9. [Monitoreo y Observabilidad](#monitoreo-y-observabilidad)
10. [Seguridad](#seguridad)
11. [Testing](#testing)
12. [Despliegue](#despliegue)
13. [Estructura del Proyecto](#estructura-del-proyecto)
14. [Comandos de Desarrollo](#comandos-de-desarrollo)

---

## 🎯 Resumen Ejecutivo

Este proyecto implementa una **aplicación de gestión de tareas (TODO)** basada en una arquitectura de microservicios distribuidos. La aplicación demuestra patrones modernos de desarrollo de software, incluyendo:

- **5 microservicios** independientes desarrollados en diferentes tecnologías
- **Arquitectura distribuida** con comunicación asíncrona
- **Trazado distribuido** con Zipkin
- **CI/CD completo** con GitHub Actions
- **Infraestructura como código** con Terraform
- **Monitoreo y observabilidad** con Prometheus y Grafana
- **Estrategia de branching** basada en Scrum

---

## 🏗️ Arquitectura del Sistema

### Diagrama de Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Auth API      │    │   Users API     │
│   (Vue.js)      │◄──►│   (Go)          │◄──►│   (Java/Spring) │
│   Port: 8080    │    │   Port: 8081    │    │   Port: 8083    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   TODOs API     │    │   Redis         │    │   Zipkin        │
│   (Node.js)     │◄──►│   (Message      │    │   (Tracing)     │
│   Port: 8082    │    │    Queue)       │    │   Port: 9411    │
└─────────────────┘    │   Port: 6379    │    └─────────────────┘
         │              └─────────────────┘
         │                       ▲
         ▼                       │
┌─────────────────┐              │
│ Log Processor   │──────────────┘
│ (Python)        │
└─────────────────┘
```

### Características de la Arquitectura

- **Comunicación Síncrona**: APIs REST entre servicios
- **Comunicación Asíncrona**: Redis Pub/Sub para logging
- **Trazado Distribuido**: Zipkin para observabilidad
- **Autenticación Centralizada**: JWT tokens
- **Base de Datos Distribuida**: Cada servicio maneja su propio estado

---

## 🔧 Microservicios Implementados

### 1. **Frontend (Vue.js)**
- **Puerto**: 8080
- **Tecnología**: Vue.js 2.3.3, Bootstrap Vue, Webpack
- **Responsabilidades**: 
  - Interfaz de usuario
  - Gestión de estado con Vuex
  - Enrutamiento con Vue Router
  - Comunicación con APIs backend

### 2. **Auth API (Go)**
- **Puerto**: 8081
- **Tecnología**: Go, Echo framework, JWT
- **Responsabilidades**:
  - Autenticación de usuarios
  - Generación y validación de JWT tokens
  - Integración con Users API
  - Circuit breaker pattern implementado

### 3. **Users API (Java Spring Boot)**
- **Puerto**: 8083
- **Tecnología**: Java 8, Spring Boot, Spring Security
- **Responsabilidades**:
  - Gestión de usuarios
  - Roles y permisos
  - Base de datos H2 en memoria
  - Validación de credenciales

### 4. **TODOs API (Node.js)**
- **Puerto**: 8082
- **Tecnología**: Node.js, Express, Redis
- **Responsabilidades**:
  - CRUD de tareas
  - Cache en memoria
  - Publicación de eventos de logging
  - Middleware de autenticación JWT

### 5. **Log Message Processor (Python)**
- **Tecnología**: Python 3.12, Redis, Zipkin
- **Responsabilidades**:
  - Procesamiento asíncrono de logs
  - Integración con Zipkin para trazado
  - Simulación de procesamiento con delays aleatorios

---

## 🎨 Patrones de Diseño

### 1. **API Gateway Pattern**
- **Implementación**: Nginx como load balancer
- **Ubicación**: `docker-compose-prod.yml`
- **Beneficios**: Punto único de entrada, balanceo de carga

### 2. **Circuit Breaker Pattern**
- **Implementación**: Go breaker en Auth API
- **Código**: `auth-api/main.go` líneas 15-16
- **Beneficios**: Resiliencia ante fallos de servicios

### 3. **Event-Driven Architecture**
- **Implementación**: Redis Pub/Sub
- **Flujo**: TODOs API → Redis → Log Processor
- **Beneficios**: Desacoplamiento, escalabilidad

### 4. **Distributed Tracing**
- **Implementación**: Zipkin
- **Cobertura**: Todos los microservicios
- **Beneficios**: Observabilidad, debugging distribuido

### 5. **Database per Service**
- **Implementación**: Cada servicio maneja su propio estado
- **Ejemplos**: 
  - Users API: H2 en memoria
  - TODOs API: Cache en memoria
- **Beneficios**: Independencia, escalabilidad

### 6. **CQRS (Command Query Responsibility Segregation)**
- **Implementación**: Separación de operaciones de lectura y escritura
- **Ejemplo**: TODOs API separa listado (query) de creación/eliminación (command)

---

## 🛠️ Tecnologías y Stack Tecnológico

### Backend
- **Go**: Auth API (Echo framework)
- **Java 8**: Users API (Spring Boot)
- **Node.js 20**: TODOs API (Express)
- **Python 3.12**: Log Processor

### Frontend
- **Vue.js 2.3.3**: Framework principal
- **Bootstrap Vue**: Componentes UI
- **Vuex**: Gestión de estado
- **Vue Router**: Enrutamiento

### Infraestructura
- **Docker & Docker Compose**: Containerización
- **Redis 7.0**: Message queue y cache
- **Zipkin**: Distributed tracing
- **Nginx**: Load balancer y proxy reverso

### CI/CD
- **GitHub Actions**: Automatización
- **Docker Registry**: ghcr.io
- **Trivy**: Security scanning

### Infraestructura como Código
- **Terraform**: Provisioning
- **Azure**: Cloud provider
- **Kubernetes**: Orquestación (configurado)

### Monitoreo
- **Prometheus**: Métricas
- **Grafana**: Visualización
- **Alertmanager**: Alertas

---

## 🌿 Estrategia de Branching

### Branches Principales
- **`main`**: Código estable para producción
- **`develop`**: Integración de desarrollo
- **`feat/pipeLines`**: Rama específica para pipelines

### Branches de Trabajo
- **`feature/*`**: Nuevas funcionalidades
- **`bugfix/*`**: Corrección de errores
- **`hotfix/*`**: Correcciones urgentes en producción

### Flujo de Trabajo
1. **Desarrollo**: Feature branches desde `develop`
2. **Integración**: PR a `develop` con revisión
3. **Producción**: PR de `develop` a `main`
4. **Hotfixes**: Desde `main` directamente

### Documentación
- **Archivo**: `docs/strategy_branching.md`
- **Metodología**: Basada en Scrum
- **Herramientas**: GitHub PR, Code review

---

## 🚀 CI/CD Pipeline

### Pipeline Principal (`ci-cd-pipeline.yml`)

#### Triggers
- **Push**: `main`, `develop`, `feat/pipeLines`
- **Pull Request**: `main`, `develop`, `feat/pipeLines`

#### Jobs Implementados

1. **Build and Test**
   - **Estrategia**: Matrix build para 5 servicios
   - **Tecnologías**: Node.js 20, Python 3.12, Java 8, Go
   - **Tests**: Unit tests para cada servicio
   - **Docker**: Build y push de imágenes

2. **Security Scan**
   - **Herramienta**: Trivy
   - **Cobertura**: Vulnerabilidades HIGH y CRITICAL
   - **Integración**: GitHub Security tab

3. **Deploy Staging**
   - **Trigger**: Push a `develop`
   - **Acción**: `docker-compose up -d`

4. **Deploy Production**
   - **Trigger**: Push a `main`
   - **Environment**: `production`
   - **Acción**: `docker-compose up -d`

5. **Deploy Preview**
   - **Trigger**: Pull Requests
   - **Acción**: Preview environment para testing

6. **Integration Tests**
   - **Trigger**: Después de deploy staging
   - **Tests**: Health checks de servicios

### Pipeline de Infraestructura (`infrastructure-pipeline.yml`)
- **Trigger**: Cambios en `infrastructure/`
- **Tecnología**: Terraform
- **Cloud**: Azure
- **Recursos**: AKS, Storage, Networking

### Pipeline de Monitoreo (`monitoring-pipeline.yml`)
- **Trigger**: Cron cada 6 horas
- **Funciones**: Health checks, performance tests
- **Herramientas**: k6, Prometheus

---

## ☁️ Infraestructura como Código

### Terraform Configuration

#### Archivos Principales
- **`main.tf`**: Configuración principal
- **`variables.tf`**: Variables de entrada
- **`outputs.tf`**: Outputs del deployment
- **`terraform.tfvars.example`**: Ejemplo de variables

#### Recursos Azure
- **Resource Group**: `microservices-rg`
- **AKS Cluster**: `microservices-aks`
- **Storage Account**: Para persistencia
- **Virtual Network**: Red privada
- **Load Balancer**: Balanceo de carga

#### Configuración Kubernetes
- **Deployments**: Para cada microservicio
- **Services**: Exposición de servicios
- **ConfigMaps**: Configuración
- **Secrets**: Credenciales

### Docker Compose

#### Desarrollo (`docker-compose.yml`)
- **Servicios**: 6 servicios + Redis + Zipkin
- **Red**: `microservices-network`
- **Volúmenes**: Persistencia local

#### Producción (`docker-compose-prod.yml`)
- **Servicios**: 6 servicios + Redis + Zipkin + Elasticsearch
- **Replicas**: Configuradas por servicio
- **Recursos**: Límites de memoria y CPU
- **Monitoreo**: Prometheus + Grafana + Alertmanager

---

## 📊 Monitoreo y Observabilidad

### Distributed Tracing
- **Herramienta**: Zipkin
- **Puerto**: 9411
- **Storage**: Elasticsearch (producción)
- **Cobertura**: Todos los microservicios

### Métricas
- **Herramienta**: Prometheus
- **Puerto**: 9090
- **Configuración**: `monitoring/prometheus.yml`
- **Métricas**: CPU, memoria, requests, latencia

### Visualización
- **Herramienta**: Grafana
- **Puerto**: 3000
- **Dashboards**: Pre-configurados
- **Alertas**: Configuradas en Alertmanager

### Logging
- **Estrategia**: Centralized logging
- **Herramienta**: Log Processor (Python)
- **Storage**: Redis → Zipkin
- **Formato**: JSON estructurado

### Health Checks
- **Implementación**: Endpoints `/health` en cada servicio
- **Monitoreo**: Prometheus scraping
- **Alertas**: Alertmanager rules

---

## 🔒 Seguridad

### Autenticación y Autorización
- **Método**: JWT tokens
- **Secreto**: Configurable via environment
- **Expiración**: Configurable
- **Algoritmo**: HS256

### Vulnerabilidades
- **Scanning**: Trivy en CI/CD
- **Frecuencia**: Cada push/PR
- **Severidad**: HIGH y CRITICAL
- **Acción**: Bloqueo de deployment

### Network Security
- **Redes**: Docker networks aisladas
- **Comunicación**: Solo entre servicios necesarios
- **Puertos**: Exposición mínima necesaria

### Secrets Management
- **Desarrollo**: Variables de entorno
- **Producción**: Azure Key Vault (configurado)
- **Rotación**: Manual (mejora futura)

---

## 🧪 Testing

### Estrategia de Testing

#### Unit Tests
- **Frontend**: Jest (configurado, no implementado)
- **TODOs API**: Jest + Supertest (16 tests)
- **Users API**: JUnit (Spring Boot)
- **Auth API**: Go testing
- **Log Processor**: Pytest (5 tests)

#### Integration Tests
- **Implementación**: Health checks
- **Cobertura**: Todos los servicios
- **Herramienta**: curl + custom scripts

#### End-to-End Tests
- **Implementación**: Performance tests con k6
- **Cobertura**: Flujo completo de usuario
- **Métricas**: Latencia, throughput

### Cobertura de Código
- **TODOs API**: 92.68% (Jest)
- **Log Processor**: 100% (Pytest)
- **Otros**: Por implementar

### Test Automation
- **CI/CD**: Ejecución automática en PRs
- **Reportes**: GitHub Actions artifacts
- **Notificaciones**: Slack/Email (configurado)

---

## 🚢 Despliegue

### Ambientes

#### Desarrollo
- **Comando**: `docker-compose up -d`
- **Servicios**: Todos los microservicios
- **Base de datos**: H2 en memoria, Redis
- **Trazado**: Zipkin con storage en memoria

#### Staging
- **Trigger**: Push a `develop`
- **Comando**: `docker-compose up -d`
- **Diferencias**: Configuración de staging

#### Producción
- **Trigger**: Push a `main`
- **Comando**: `docker-compose -f docker-compose-prod.yml up -d`
- **Características**:
  - Replicas configuradas
  - Límites de recursos
  - Elasticsearch para Zipkin
  - Prometheus + Grafana
  - Nginx load balancer

### Estrategia de Despliegue
- **Método**: Blue-Green (configurado)
- **Rollback**: Docker Compose down/up
- **Health Checks**: Automáticos
- **Monitoring**: Prometheus alerts

---

## 📁 Estructura del Proyecto

```
microservice-app-example/
├── .github/
│   └── workflows/
│       ├── ci-cd-pipeline.yml
│       ├── infrastructure-pipeline.yml
│       └── monitoring-pipeline.yml
├── arch-img/
│   └── Microservices.png
├── auth-api/                    # Go microservice
│   ├── Dockerfile
│   ├── go.mod
│   ├── main.go
│   └── tracing.go
├── frontend/                    # Vue.js frontend
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   ├── src/
│   └── build/
├── infrastructure/              # Terraform IaC
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── log-message-processor/       # Python microservice
│   ├── Dockerfile
│   ├── main.py
│   ├── requirements.txt
│   └── test_main.py
├── monitoring/                  # Monitoring config
│   ├── prometheus.yml
│   ├── alertmanager.yml
│   └── alert_rules.yml
├── scripts/                     # Utility scripts
│   ├── deploy.sh
│   ├── monitor.sh
│   └── test.sh
├── todos-api/                   # Node.js microservice
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   ├── test/
│   └── jest.config.js
├── users-api/                   # Java Spring Boot microservice
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
├── docker-compose.yml           # Development environment
├── docker-compose-prod.yml      # Production environment
└── docs/
    ├── architecture.md
    └── strategy_branching.md
```

---

## 🛠️ Comandos de Desarrollo

### Desarrollo Local

```bash
# Clonar el repositorio
git clone <repository-url>
cd microservice-app-example

# Ejecutar todos los servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar servicios
docker-compose down
```

### Testing

```bash
# Tests de TODOs API
cd todos-api
npm test

# Tests de Log Processor
cd log-message-processor
python -m pytest

# Tests de Users API
cd users-api
mvn test

# Tests de Auth API
cd auth-api
go test ./...
```

### CI/CD

```bash
# Trigger manual de pipeline
git push origin develop

# Ver status de workflows
gh run list

# Ver logs de un job específico
gh run view <run-id>
```

### Infraestructura

```bash
# Inicializar Terraform
cd infrastructure
terraform init

# Plan de deployment
terraform plan

# Aplicar cambios
terraform apply

# Destruir infraestructura
terraform destroy
```

### Monitoreo

```bash
# Health check de servicios
curl http://localhost:8082/version  # TODOs API
curl http://localhost:9411          # Zipkin
curl http://localhost:9090          # Prometheus
curl http://localhost:3000          # Grafana
```

---

## 📈 Métricas y KPIs

### Performance
- **Latencia promedio**: < 500ms
- **Throughput**: 20 requests/segundo
- **Uptime**: 99.9% (objetivo)

### Calidad
- **Cobertura de tests**: 92.68% (TODOs API)
- **Vulnerabilidades**: 0 HIGH/CRITICAL
- **Code review**: 100% de PRs

### DevOps
- **Deployment frequency**: Diario
- **Lead time**: < 1 hora
- **MTTR**: < 30 minutos

---

## 🔮 Roadmap y Mejoras Futuras

### Corto Plazo
- [ ] Implementar tests E2E completos
- [ ] Añadir métricas de negocio
- [ ] Implementar rate limiting
- [ ] Mejorar documentación de APIs

### Mediano Plazo
- [ ] Migrar a Kubernetes nativo
- [ ] Implementar service mesh (Istio)
- [ ] Añadir distributed caching
- [ ] Implementar CQRS completo

