# Diagramas de Arquitectura - Microservicios

## 📋 Tabla de Contenidos

1. [Arquitectura General del Sistema](#arquitectura-general-del-sistema)
2. [Arquitectura de Desarrollo](#arquitectura-de-desarrollo)
3. [Arquitectura de Producción](#arquitectura-de-producción)
4. [Flujo de Datos y Comunicación](#flujo-de-datos-y-comunicación)
5. [Arquitectura de Seguridad](#arquitectura-de-seguridad)
6. [Arquitectura de Monitoreo](#arquitectura-de-monitoreo)
7. [Arquitectura de CI/CD](#arquitectura-de-cicd)
8. [Arquitectura de Infraestructura](#arquitectura-de-infraestructura)

---

## 🏗️ Arquitectura General del Sistema

### Diagrama de Alto Nivel

```mermaid
graph TB
    subgraph "Cliente"
        U[Usuario]
    end
    
    subgraph "Frontend Layer"
        F[Frontend<br/>Vue.js 2.3.3<br/>Puerto: 8080]
    end
    
    subgraph "API Gateway Layer"
        N[Nginx<br/>Load Balancer<br/>Puerto: 80/443]
    end
    
    subgraph "Microservicios"
        A[Auth API<br/>Go 1.22.2<br/>Puerto: 8081]
        U_API[Users API<br/>Java Spring Boot 1.5.6<br/>Puerto: 8083]
        T[TODOs API<br/>Node.js<br/>Puerto: 8082]
        L[Log Processor<br/>Python 3.12]
    end
    
    subgraph "Infraestructura"
        R[Redis 7.0<br/>Message Queue<br/>Puerto: 6379]
        Z[Zipkin<br/>Distributed Tracing<br/>Puerto: 9411]
        E[Elasticsearch 7.17.0<br/>Trace Storage<br/>Puerto: 9200]
    end
    
    subgraph "Monitoreo"
        P[Prometheus<br/>Métricas<br/>Puerto: 9090]
        G[Grafana<br/>Dashboards<br/>Puerto: 3000]
        AM[Alertmanager<br/>Alertas<br/>Puerto: 9093]
    end
    
    U --> F
    F --> N
    N --> A
    N --> U_API
    N --> T
    
    A --> U_API
    T --> R
    L --> R
    L --> Z
    
    A --> Z
    U_API --> Z
    T --> Z
    F --> Z
    
    Z --> E
    
    A --> P
    U_API --> P
    T --> P
    F --> P
    
    P --> G
    P --> AM
```

### Componentes y Responsabilidades

| Componente | Tecnología | Puerto | Responsabilidad |
|------------|------------|--------|-----------------|
| **Frontend** | Vue.js 2.3.3 | 8080 | Interfaz de usuario, gestión de estado |
| **Auth API** | Go 1.22.2 | 8081 | Autenticación, JWT tokens, Circuit Breaker |
| **Users API** | Java Spring Boot 1.5.6 | 8083 | Gestión de usuarios, roles, H2 DB |
| **TODOs API** | Node.js | 8082 | CRUD tareas, Cache Aside, Redis Pub/Sub |
| **Log Processor** | Python 3.12 | - | Procesamiento asíncrono de logs |
| **Redis** | Redis 7.0 | 6379 | Message queue, cache |
| **Zipkin** | Zipkin | 9411 | Distributed tracing |
| **Elasticsearch** | ES 7.17.0 | 9200 | Almacenamiento de traces |

---

## 🛠️ Arquitectura de Desarrollo

### Docker Compose - Desarrollo Local

```mermaid
graph TB
    subgraph "Docker Network: microservices-network"
        subgraph "Frontend"
            F[Frontend Container<br/>Vue.js + Nginx<br/>Port: 8080]
        end
        
        subgraph "Microservicios"
            A[Auth API Container<br/>Go + Echo<br/>Port: 8081]
            U[Users API Container<br/>Java + Spring Boot<br/>Port: 8083]
            T[TODOs API Container<br/>Node.js + Express<br/>Port: 8082]
            L[Log Processor Container<br/>Python<br/>No Port]
        end
        
        subgraph "Infraestructura"
            R[Redis Container<br/>Redis 7.0-alpine<br/>Port: 6379]
            Z[Zipkin Container<br/>OpenZipkin<br/>Port: 9411]
        end
    end
    
    subgraph "Host Machine"
        DEV[Desarrollador<br/>localhost:8080]
    end
    
    DEV --> F
    F --> A
    F --> U
    F --> T
    A --> U
    T --> R
    L --> R
    L --> Z
    A --> Z
    U --> Z
    T --> Z
    F --> Z
```

### Configuración de Red

```yaml
# docker-compose.yml
networks:
  microservices-network:
    driver: bridge
```

**Características del Desarrollo:**
- **Red aislada**: `microservices-network` (bridge)
- **Puertos expuestos**: Solo los necesarios para desarrollo
- **Volúmenes**: Código montado para hot-reload
- **Variables de entorno**: Configuración de desarrollo

---

## 🚀 Arquitectura de Producción

### Docker Compose - Producción

```mermaid
graph TB
    subgraph "Production Environment"
        subgraph "Load Balancer"
            N[Nginx<br/>Load Balancer<br/>Port: 80/443]
        end
        
        subgraph "Application Layer"
            F1[Frontend Replica 1<br/>Vue.js + Nginx]
            F2[Frontend Replica 2<br/>Vue.js + Nginx]
            
            A1[Auth API Replica 1<br/>Go + Echo]
            A2[Auth API Replica 2<br/>Go + Echo]
            
            U1[Users API Replica 1<br/>Java + Spring Boot]
            U2[Users API Replica 2<br/>Java + Spring Boot]
            
            T1[TODOs API Replica 1<br/>Node.js + Express]
            T2[TODOs API Replica 2<br/>Node.js + Express]
            T3[TODOs API Replica 3<br/>Node.js + Express]
            
            L1[Log Processor Replica 1<br/>Python]
            L2[Log Processor Replica 2<br/>Python]
        end
        
        subgraph "Data Layer"
            R[Redis<br/>Message Queue + Cache<br/>Port: 6379]
            E[Elasticsearch<br/>Trace Storage<br/>Port: 9200]
        end
        
        subgraph "Observability"
            Z[Zipkin<br/>Distributed Tracing<br/>Port: 9411]
            P[Prometheus<br/>Metrics<br/>Port: 9090]
            G[Grafana<br/>Dashboards<br/>Port: 3000]
            AM[Alertmanager<br/>Alerts<br/>Port: 9093]
        end
    end
    
    N --> F1
    N --> F2
    N --> A1
    N --> A2
    N --> U1
    N --> U2
    N --> T1
    N --> T2
    N --> T3
    
    F1 --> A1
    F2 --> A2
    A1 --> U1
    A2 --> U2
    
    T1 --> R
    T2 --> R
    T3 --> R
    L1 --> R
    L2 --> R
    
    L1 --> Z
    L2 --> Z
    Z --> E
    
    A1 --> P
    A2 --> P
    U1 --> P
    U2 --> P
    T1 --> P
    T2 --> P
    T3 --> P
    
    P --> G
    P --> AM
```

### Configuración de Réplicas

```yaml
# docker-compose-prod.yml
deploy:
  replicas: 2  # Frontend, Auth API, Users API, Log Processor
  replicas: 3  # TODOs API (mayor carga)
  resources:
    limits:
      memory: 256M-512M
    reservations:
      memory: 128M-256M
```

---

## 🔄 Flujo de Datos y Comunicación

### Flujo de Autenticación

```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant A as Auth API
    participant U_API as Users API
    participant Z as Zipkin
    
    U->>F: 1. Login (username, password)
    F->>A: 2. POST /login
    A->>U_API: 3. GET /users/{username}
    U_API-->>A: 4. User data
    A->>A: 5. Validate credentials
    A->>A: 6. Generate JWT token
    A-->>F: 7. JWT token + user info
    F->>F: 8. Store token in Vuex
    F-->>U: 9. Redirect to dashboard
    
    Note over A,U_API: Circuit Breaker Protection
    Note over A,Z: Distributed Tracing
```

### Flujo de Operaciones TODOs

```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant T as TODOs API
    participant R as Redis
    participant L as Log Processor
    participant Z as Zipkin
    
    U->>F: 1. Create/Update/Delete TODO
    F->>T: 2. API call with JWT
    T->>T: 3. Validate JWT
    T->>T: 4. Check cache (Cache Aside)
    alt Cache Miss
        T->>T: 5. Load from "database"
        T->>T: 6. Store in cache
    end
    T->>T: 7. Process operation
    T->>R: 8. Publish log event
    T-->>F: 9. Response
    F-->>U: 10. Update UI
    
    R->>L: 11. Consume log event
    L->>Z: 12. Send trace data
    L->>L: 13. Process log (delay simulation)
```

### Patrones de Comunicación

```mermaid
graph LR
    subgraph "Síncrona (HTTP REST)"
        F[Frontend] -->|HTTP| A[Auth API]
        A -->|HTTP| U[Users API]
        F -->|HTTP| T[TODOs API]
    end
    
    subgraph "Asíncrona (Redis Pub/Sub)"
        T -->|Publish| R[Redis]
        R -->|Subscribe| L[Log Processor]
    end
    
    subgraph "Trazado (Zipkin)"
        F -->|Traces| Z[Zipkin]
        A -->|Traces| Z
        U -->|Traces| Z
        T -->|Traces| Z
        L -->|Traces| Z
    end
```

---

## 🔒 Arquitectura de Seguridad

### Autenticación y Autorización

```mermaid
graph TB
    subgraph "Cliente"
        U[Usuario]
        B[Browser]
    end
    
    subgraph "Frontend"
        F[Vue.js App]
        S[Vuex Store]
        A[Auth Plugin]
    end
    
    subgraph "Backend"
        A_API[Auth API]
        U_API[Users API]
        T_API[TODOs API]
    end
    
    subgraph "Seguridad"
        JWT[JWT Tokens]
        CB[Circuit Breaker]
        MW[JWT Middleware]
    end
    
    U --> B
    B --> F
    F --> A
    A --> S
    S --> JWT
    
    F -->|Bearer Token| A_API
    A_API -->|Validate| U_API
    A_API -->|Generate| JWT
    
    F -->|Bearer Token| T_API
    T_API -->|Validate| MW
    MW -->|Authorize| T_API
    
    A_API -->|Protect| CB
    CB -->|Fallback| A_API
```

### Flujo de Seguridad JWT

```mermaid
sequenceDiagram
    participant C as Cliente
    participant F as Frontend
    participant A as Auth API
    participant U as Users API
    participant T as TODOs API
    
    C->>F: 1. Login request
    F->>A: 2. POST /login (credentials)
    A->>U: 3. GET /users/{username}
    U-->>A: 4. User data
    A->>A: 5. Validate password
    A->>A: 6. Generate JWT (HS256)
    A-->>F: 7. JWT token + claims
    F->>F: 8. Store in Vuex
    
    Note over C,T: Subsequent Requests
    
    C->>F: 9. API request
    F->>T: 10. GET /todos (Bearer JWT)
    T->>T: 11. Verify JWT signature
    T->>T: 12. Check expiration
    T->>T: 13. Extract claims
    T-->>F: 14. Authorized response
```

---

## 📊 Arquitectura de Monitoreo

### Stack de Observabilidad

```mermaid
graph TB
    subgraph "Aplicación"
        F[Frontend]
        A[Auth API]
        U[Users API]
        T[TODOs API]
        L[Log Processor]
    end
    
    subgraph "Trazado Distribuido"
        Z[Zipkin<br/>Port: 9411]
        E[Elasticsearch<br/>Port: 9200]
    end
    
    subgraph "Métricas"
        P[Prometheus<br/>Port: 9090]
        G[Grafana<br/>Port: 3000]
    end
    
    subgraph "Alertas"
        AM[Alertmanager<br/>Port: 9093]
        AR[Alert Rules]
    end
    
    F -->|Traces| Z
    A -->|Traces| Z
    U -->|Traces| Z
    T -->|Traces| Z
    L -->|Traces| Z
    
    Z -->|Store| E
    
    F -->|Metrics| P
    A -->|Metrics| P
    U -->|Metrics| P
    T -->|Metrics| P
    
    P -->|Query| G
    P -->|Alerts| AM
    AM -->|Rules| AR
```

### Configuración de Métricas

```yaml
# monitoring/prometheus.yml
scrape_configs:
  - job_name: 'todos-api'
    static_configs:
      - targets: ['todos-api:8082']
    metrics_path: '/metrics'
    scrape_interval: 5s
    
  - job_name: 'users-api'
    static_configs:
      - targets: ['users-api:8083']
      
  - job_name: 'auth-api'
    static_configs:
      - targets: ['auth-api:8081']
```

---

## 🚀 Arquitectura de CI/CD

### GitHub Actions Pipeline

```mermaid
graph TB
    subgraph "GitHub Repository"
        C[Code Push/PR]
    end
    
    subgraph "GitHub Actions"
        subgraph "Build & Test"
            BT[Build & Test Job]
            MT[Matrix Strategy]
            F_T[Frontend Tests]
            A_T[Auth API Tests]
            U_T[Users API Tests]
            T_T[TODOs API Tests]
            L_T[Log Processor Tests]
        end
        
        subgraph "Security"
            S[Security Scan]
            T[Trivy Scanner]
        end
        
        subgraph "Deploy"
            DS[Deploy Staging]
            DP[Deploy Production]
            DPREV[Deploy Preview]
        end
        
        subgraph "Integration"
            IT[Integration Tests]
            HC[Health Checks]
        end
    end
    
    subgraph "Container Registry"
        CR[GitHub Container Registry<br/>ghcr.io]
    end
    
    subgraph "Environments"
        STAGING[Staging Environment]
        PROD[Production Environment]
        PREV[Preview Environment]
    end
    
    C --> BT
    BT --> MT
    MT --> F_T
    MT --> A_T
    MT --> U_T
    MT --> T_T
    MT --> L_T
    
    BT --> S
    S --> T
    
    S --> DS
    S --> DP
    S --> DPREV
    
    DS --> IT
    IT --> HC
    
    BT --> CR
    CR --> STAGING
    CR --> PROD
    CR --> PREV
```

### Pipeline Stages

```mermaid
graph LR
    subgraph "Pipeline Stages"
        A[1. Checkout] --> B[2. Setup Languages]
        B --> C[3. Install Dependencies]
        C --> D[4. Run Tests]
        D --> E[5. Build Docker Images]
        E --> F[6. Push to Registry]
        F --> G[7. Security Scan]
        G --> H[8. Deploy]
        H --> I[9. Integration Tests]
    end
```

---

## ☁️ Arquitectura de Infraestructura

### Azure + Terraform

```mermaid
graph TB
    subgraph "Azure Cloud"
        subgraph "Resource Group: microservices-rg"
            subgraph "Virtual Network"
                subgraph "AKS Cluster"
                    subgraph "Node Pool"
                        N1[Node 1]
                        N2[Node 2]
                    end
                    
                    subgraph "Pods"
                        P1[Frontend Pods]
                        P2[Auth API Pods]
                        P3[Users API Pods]
                        P4[TODOs API Pods]
                        P5[Log Processor Pods]
                    end
                end
                
                subgraph "Storage"
                    S[Azure Storage Account]
                end
                
                subgraph "Database"
                    R[Azure Redis Cache]
                end
            end
        end
        
        subgraph "Monitoring"
            M[Azure Monitor]
            L[Log Analytics]
        end
    end
    
    subgraph "Terraform"
        T[Terraform State]
        I[Infrastructure Code]
    end
    
    T --> I
    I --> AKS
    I --> S
    I --> R
    I --> M
```

### Terraform Configuration

```hcl
# infrastructure/main.tf
resource "azurerm_kubernetes_cluster" "microservices" {
  name                = "microservices-aks"
  location            = azurerm_resource_group.microservices.location
  resource_group_name = azurerm_resource_group.microservices.name
  dns_prefix          = "microservices"
  
  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2s_v3"
  }
  
  identity {
    type = "SystemAssigned"
  }
}
```

---

## 🔧 Patrones de Diseño Implementados

### 1. Circuit Breaker Pattern

```mermaid
graph LR
    subgraph "Auth API"
        A[Request] --> B{Circuit State}
        B -->|Closed| C[Call Users API]
        B -->|Open| D[Return Error]
        B -->|Half-Open| E[Test Call]
        
        C -->|Success| F[Success Response]
        C -->|Failure| G[Increment Failures]
        E -->|Success| H[Close Circuit]
        E -->|Failure| I[Open Circuit]
    end
```

### 2. Cache Aside Pattern

```mermaid
graph TB
    subgraph "TODOs API"
        R[Request] --> C{Cache Hit?}
        C -->|Yes| D[Return Cached Data]
        C -->|No| E[Load from Database]
        E --> F[Store in Cache]
        F --> G[Return Data]
    end
```

### 3. Auto Scaling Pattern

```mermaid
graph TB
    subgraph "Docker Compose"
        M[Monitor Metrics] --> T{Threshold?}
        T -->|High Load| S[Scale Up]
        T -->|Low Load| D[Scale Down]
        T -->|Normal| M
        
        S --> R1[Add Replicas]
        D --> R2[Remove Replicas]
    end
```

---

## 📈 Métricas y KPIs

### Métricas de Aplicación

| Métrica | Valor Objetivo | Implementación |
|---------|----------------|----------------|
| **Latencia P95** | < 500ms | Prometheus + Grafana |
| **Throughput** | 100 req/s | Prometheus scraping |
| **Disponibilidad** | 99.9% | Health checks |
| **Error Rate** | < 1% | Circuit breaker |

### Métricas de Infraestructura

| Métrica | Valor Objetivo | Herramienta |
|---------|----------------|-------------|
| **CPU Usage** | < 70% | Prometheus |
| **Memory Usage** | < 80% | Prometheus |
| **Disk Usage** | < 85% | Prometheus |
| **Network Latency** | < 100ms | Prometheus |

---

## 🎯 Resumen de Arquitectura

### Características Principales

1. **Microservicios Políglotas**: 5 servicios en diferentes tecnologías
2. **Comunicación Híbrida**: HTTP REST + Redis Pub/Sub
3. **Observabilidad Completa**: Zipkin + Prometheus + Grafana
4. **Seguridad JWT**: Autenticación centralizada
5. **Patrones de Resiliencia**: Circuit Breaker, Cache Aside, Auto Scaling
6. **Infraestructura como Código**: Terraform + Docker Compose
7. **CI/CD Automatizado**: GitHub Actions con multi-language support

### Beneficios de la Arquitectura

- **Escalabilidad**: Servicios independientes escalables
- **Resiliencia**: Patrones de fallo y recuperación
- **Observabilidad**: Trazado distribuido y métricas
- **Seguridad**: JWT y validación centralizada
- **Mantenibilidad**: Código modular y testeable
- **Despliegue**: Automatizado y confiable

---

*Esta documentación de diagramas de arquitectura refleja la implementación real del sistema de microservicios, basada en el código fuente y configuraciones actuales del proyecto.*
