# Diagramas de Arquitectura - Microservices Application

## 🏗️ Diagrama de Arquitectura General

```mermaid
graph TB
    subgraph "Cliente"
        U[Usuario / Browser]
    end

    subgraph "Edge/CDN"
        N[Nginx Load Balancer]
    end

    subgraph "Aplicación - Microservicios"
        FE[Frontend<br/>Vue.js<br/>:8080]
        AUTH[Auth API<br/>Go<br/>:8081]
        TODOS[Todos API<br/>Node.js<br/>:8082]
        USERS[Users API<br/>Spring Boot<br/>:8083]
        LOGP[Log Processor<br/>Python]
    end

    subgraph "Observabilidad"
        ZIPKIN[Zipkin<br/>Tracing<br/>:9411]
        ES[Elasticsearch<br/>Storage<br/>:9200]
        PROM[Prometheus<br/>Metrics<br/>:9090]
        GRAF[Grafana<br/>Dashboards<br/>:3000]
        ALERT[Alertmanager<br/>:9093]
    end

    subgraph "Datos / Cache / MQ"
        REDIS[Azure Redis Cache<br/>:6380]
    end

    U -->|HTTPS| N --> FE
    FE -->|JWT Auth| AUTH
    FE -->|API Calls| TODOS
    AUTH -->|User Validation| USERS

    TODOS <-->|Cache/Queue| REDIS
    USERS <-->|Cache| REDIS
    LOGP <-->|Queue| REDIS

    FE -->|Traces| ZIPKIN
    AUTH -->|Traces| ZIPKIN
    TODOS -->|Traces| ZIPKIN
    USERS -->|Traces| ZIPKIN
    LOGP -->|Traces| ZIPKIN
    ZIPKIN -->|Storage| ES

    PROM -.scrape.-> N & FE & AUTH & TODOS & USERS & LOGP & REDIS & ZIPKIN & ES
    GRAF <-->|Dashboards| PROM
    ALERT <-->|Alerts| PROM
```

## 🔄 Flujo de Datos - Autenticación

```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant A as Auth API
    participant UAPI as Users API
    participant Z as Zipkin

    U->>F: 1. Login (username, password)
    F->>A: 2. POST /login
    A->>UAPI: 3. Validate user
    UAPI-->>A: 4. User data
    A->>Z: 5. Send trace
    A-->>F: 6. JWT Token
    F->>F: 7. Store token
    F-->>U: 8. Redirect to dashboard
```

## 🔄 Flujo de Datos - Gestión de TODOs

```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant T as Todos API
    participant R as Redis
    participant L as Log Processor
    participant Z as Zipkin

    U->>F: 1. Create TODO
    F->>T: 2. POST /todos (with JWT)
    T->>T: 3. Validate JWT
    T->>R: 4. Store in cache
    T->>L: 5. Send to log queue
    T->>Z: 6. Send trace
    T-->>F: 7. TODO created
    F-->>U: 8. Update UI
    L->>Z: 9. Process log
```

## 🏢 Infraestructura - Azure Container Apps

```mermaid
graph TB
    subgraph "Azure Cloud"
        subgraph "Resource Group: microservices-rg"
            subgraph "Container Apps Environment"
                subgraph "Microservicios"
                    FE_APP[Frontend App<br/>External Ingress]
                    AUTH_APP[Auth API App<br/>Internal]
                    TODOS_APP[Todos API App<br/>Internal]
                    USERS_APP[Users API App<br/>Internal]
                    LOG_APP[Log Processor App<br/>Internal]
                end
                
                subgraph "Observabilidad"
                    ZIPKIN_APP[Zipkin App<br/>Internal]
                    ES_APP[Elasticsearch App<br/>Internal]
                    MON_APP[Monitoring App<br/>External]
                end
            end
            
            subgraph "Azure Services"
                ACR[Azure Container Registry]
                REDIS_AZURE[Azure Redis Cache]
                KV[Key Vault]
            end
        end
        
        subgraph "CI/CD"
            GHA[GitHub Actions]
        end
    end

    GHA -->|Build & Push| ACR
    ACR -->|Pull Images| FE_APP & AUTH_APP & TODOS_APP & USERS_APP & LOG_APP
    
    FE_APP -->|Internal Calls| AUTH_APP & TODOS_APP
    AUTH_APP -->|Internal Calls| USERS_APP
    TODOS_APP <-->|Cache| REDIS_AZURE
    USERS_APP <-->|Cache| REDIS_AZURE
    LOG_APP <-->|Queue| REDIS_AZURE
    
    FE_APP -->|Traces| ZIPKIN_APP
    AUTH_APP -->|Traces| ZIPKIN_APP
    TODOS_APP -->|Traces| ZIPKIN_APP
    USERS_APP -->|Traces| ZIPKIN_APP
    LOG_APP -->|Traces| ZIPKIN_APP
    ZIPKIN_APP -->|Storage| ES_APP
```

## 🔄 CI/CD Pipeline

```mermaid
graph LR
    subgraph "GitHub Repository"
        CODE[Source Code]
        PR[Pull Request]
        MAIN[Main Branch]
    end
    
    subgraph "GitHub Actions"
        BUILD[Build & Test]
        SEC[Security Scan]
        DEPLOY[Deploy to Azure]
        TEST[Integration Tests]
    end
    
    subgraph "Azure"
        ACR[Container Registry]
        APPS[Container Apps]
    end
    
    CODE -->|Push| PR
    PR -->|Merge| MAIN
    MAIN -->|Trigger| BUILD
    BUILD --> SEC
    SEC --> DEPLOY
    DEPLOY -->|Push Images| ACR
    DEPLOY -->|Deploy| APPS
    APPS --> TEST
```

## 📊 Observabilidad - Stack Completo

```mermaid
graph TB
    subgraph "Aplicación"
        APP1[Frontend]
        APP2[Auth API]
        APP3[Todos API]
        APP4[Users API]
        APP5[Log Processor]
    end
    
    subgraph "Trazabilidad"
        ZIPKIN[Zipkin<br/>Distributed Tracing]
        ES[Elasticsearch<br/>Trace Storage]
    end
    
    subgraph "Métricas"
        PROM[Prometheus<br/>Metrics Collection]
        GRAF[Grafana<br/>Visualization]
        ALERT[Alertmanager<br/>Alerting]
    end
    
    subgraph "Logs"
        LOGS[Centralized Logs]
        ELK[ELK Stack<br/>Optional]
    end
    
    APP1 -->|Traces| ZIPKIN
    APP2 -->|Traces| ZIPKIN
    APP3 -->|Traces| ZIPKIN
    APP4 -->|Traces| ZIPKIN
    APP5 -->|Traces| ZIPKIN
    ZIPKIN -->|Store| ES
    
    APP1 -->|Metrics| PROM
    APP2 -->|Metrics| PROM
    APP3 -->|Metrics| PROM
    APP4 -->|Metrics| PROM
    APP5 -->|Metrics| PROM
    
    PROM -->|Query| GRAF
    PROM -->|Alerts| ALERT
    
    APP1 -->|Logs| LOGS
    APP2 -->|Logs| LOGS
    APP3 -->|Logs| LOGS
    APP4 -->|Logs| LOGS
    APP5 -->|Logs| LOGS
```

## 🔒 Seguridad - Arquitectura de Seguridad

```mermaid
graph TB
    subgraph "Cliente"
        U[Usuario]
        BROWSER[Browser]
    end
    
    subgraph "Edge Security"
        LB[Load Balancer<br/>TLS Termination]
        WAF[Web Application Firewall]
    end
    
    subgraph "Application Security"
        FE[Frontend<br/>JWT Validation]
        AUTH[Auth API<br/>JWT Generation]
        API1[Todos API<br/>JWT Validation]
        API2[Users API<br/>JWT Validation]
    end
    
    subgraph "Data Security"
        REDIS[Redis<br/>TLS + Auth]
        DB[Database<br/>Encrypted]
        KV[Key Vault<br/>Secrets Management]
    end
    
    U -->|HTTPS| BROWSER
    BROWSER -->|HTTPS| LB
    LB -->|HTTPS| WAF
    WAF -->|HTTPS| FE
    
    FE -->|JWT Token| AUTH
    AUTH -->|JWT Token| API1
    AUTH -->|JWT Token| API2
    
    API1 -->|TLS| REDIS
    API2 -->|TLS| REDIS
    API2 -->|TLS| DB
    
    AUTH -->|Secrets| KV
    API1 -->|Secrets| KV
    API2 -->|Secrets| KV
```

## 🚀 Escalabilidad - Patrones de Escalado

```mermaid
graph TB
    subgraph "Load Balancer"
        LB[Azure Load Balancer]
    end
    
    subgraph "Frontend Tier"
        FE1[Frontend Instance 1]
        FE2[Frontend Instance 2]
        FE3[Frontend Instance N]
    end
    
    subgraph "API Tier"
        AUTH1[Auth API Instance 1]
        AUTH2[Auth API Instance 2]
        
        TODOS1[Todos API Instance 1]
        TODOS2[Todos API Instance 2]
        TODOS3[Todos API Instance 3]
        
        USERS1[Users API Instance 1]
        USERS2[Users API Instance 2]
    end
    
    subgraph "Data Tier"
        REDIS[Redis Cluster<br/>High Availability]
        DB[Database<br/>Read Replicas]
    end
    
    LB --> FE1 & FE2 & FE3
    FE1 --> AUTH1 & AUTH2
    FE2 --> AUTH1 & AUTH2
    FE3 --> AUTH1 & AUTH2
    
    FE1 --> TODOS1 & TODOS2 & TODOS3
    FE2 --> TODOS1 & TODOS2 & TODOS3
    FE3 --> TODOS1 & TODOS2 & TODOS3
    
    AUTH1 --> USERS1 & USERS2
    AUTH2 --> USERS1 & USERS2
    
    TODOS1 --> REDIS
    TODOS2 --> REDIS
    TODOS3 --> REDIS
    
    USERS1 --> REDIS & DB
    USERS2 --> REDIS & DB
```

## 🔄 Circuit Breaker Pattern

```mermaid
stateDiagram-v2
    [*] --> Closed : Service Available
    
    Closed --> Open : Failure Threshold Reached
    Closed --> Closed : Success Response
    
    Open --> HalfOpen : Timeout Period
    Open --> Open : Service Still Failing
    
    HalfOpen --> Closed : Success Response
    HalfOpen --> Open : Failure Response
    
    note right of Closed : Normal Operation<br/>All requests pass through
    note right of Open : Service Failing<br/>All requests fail fast
    note right of HalfOpen : Testing Service<br/>Limited requests allowed
```

## 📈 Monitoreo - Métricas y Alertas

```mermaid
graph TB
    subgraph "Aplicación"
        APP[Microservicios]
    end
    
    subgraph "Métricas"
        METRICS[Application Metrics<br/>- Request Rate<br/>- Response Time<br/>- Error Rate<br/>- CPU Usage<br/>- Memory Usage]
    end
    
    subgraph "Prometheus"
        PROM[Prometheus Server<br/>Metrics Collection]
        RULES[Alert Rules<br/>- High Error Rate<br/>- High Latency<br/>- Low Memory<br/>- Service Down]
    end
    
    subgraph "Alerting"
        ALERT[Alertmanager<br/>- Email<br/>- Slack<br/>- PagerDuty]
    end
    
    subgraph "Visualization"
        GRAF[Grafana<br/>- Dashboards<br/>- Real-time Metrics<br/>- Historical Data]
    end
    
    APP -->|Scrape| METRICS
    METRICS -->|Store| PROM
    PROM -->|Query| RULES
    RULES -->|Trigger| ALERT
    PROM -->|Query| GRAF
```

---

*Estos diagramas proporcionan una visión completa de la arquitectura del sistema de microservicios, incluyendo flujos de datos, infraestructura, seguridad, escalabilidad y monitoreo.*
