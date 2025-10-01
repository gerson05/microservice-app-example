## Arquitectura - Microservice App Example

### 1) Diagrama de Contexto
```mermaid
flowchart LR
  User[Usuario] -->|Navega| Frontend[Frontend (Vue)]
  Frontend -->|Login| AuthAPI[Auth API (Go)]
  AuthAPI -->|Valida credenciales| UsersAPI[Users API (Spring Boot)]
  Frontend -->|CRUD Todos (JWT)| TodosAPI[Todos API (Node)]
  TodosAPI -->|Publica eventos| Redis[(Redis Pub/Sub)]
  LogProc[Log Message Processor (Python)] -->|Suscribe| Redis
  %% Observabilidad
  Frontend -. Zipkin spans .-> Zipkin[Zipkin]
  AuthAPI -. Zipkin spans .-> Zipkin
  UsersAPI -. Zipkin spans .-> Zipkin
  TodosAPI -. Zipkin spans .-> Zipkin
  LogProc -. Zipkin spans .-> Zipkin
```

### 2) Diagrama de Componentes/Contenedores
```mermaid
graph TB
  subgraph UI
    FE[Frontend (Vue)]
  end
  subgraph Backend
    A[Auth API (Go)]
    U[Users API (Spring Boot)]
    T[Todos API (Node.js)]
    L[Log Processor (Python)]
  end
  subgraph Infra
    R[(Redis)]
    Z[Zipkin]
  end

  FE -->|/login| A
  A -->|/users (perfil)| U
  FE -->|/todos (JWT)| T
  T -->|pub "create/delete"| R
  L -->|sub "log_channel"| R

  FE -. traces .-> Z
  A  -. traces .-> Z
  U  -. traces .-> Z
  T  -. traces .-> Z
  L  -. traces .-> Z
```

### 3) Despliegue (Docker Compose)
```mermaid
graph LR
  subgraph Host
    subgraph Network: microservices-network
      FE[frontend]
      A[auth-api]
      U[users-api]
      T[todos-api]
      L[log-processor]
      R[(redis:6379)]
      Z[zipkin:9411]
    end
  end

  FE --> A
  FE --> T
  A  --> U
  T  --> R
  L  --> R
  FE -.-> Z
  A  -.-> Z
  U  -.-> Z
  T  -.-> Z
  L  -.-> Z
```

### 4) CI/CD (GitHub Actions) – Flujo
```mermaid
flowchart TD
  push{{Push/PR}} --> CI[Build & Test (matrix: 5 servicios)]
  CI --> Scan[Security Scan (Trivy)]
  Scan -->|branch=develop| Staging[Deploy Staging]
  Scan -->|branch=main| Prod[Deploy Production]
  Staging --> IT[Integration Tests]
```

### 5) Patrones aplicados y sugeridos
- Existentes: JWT Auth, Event-Driven (Redis), Tracing distribuido (Zipkin)
- Sugeridos: Circuit Breaker, Cache-Aside

### 6) Arquitectura en Azure (nube)
```mermaid
flowchart TB
  %% Grupos de recursos y red
  subgraph RG[Resource Group: microservices-rg]
    subgraph VNET[Virtual Network: microservices-vnet]
      subgraph SUBNET_AKS[Subnet: aks-subnet]
        AKS[(AKS Cluster)]
      end
      subgraph SUBNET_APPGW[Subnet: appgw-subnet]
        APPGW[Azure Application Gateway]
      end
    end

    ACR[(Azure Container Registry)]
    KV[(Azure Key Vault)]
    REDIS[(Azure Cache for Redis)]
    LA[(Log Analytics Workspace)]
    AI[(Application Insights)]
  end

  %% Cargas dentro de AKS (namespaces/pods)
  subgraph AKS_NS[AKS Workloads]
    FE[Deployment: frontend]
    AUTH[Deployment: auth-api]
    USERS[Deployment: users-api]
    TODOS[Deployment: todos-api]
    LOGP[Deployment: log-processor]
    ZIPKIN[Deployment: zipkin]
  end

  %% Flujo externo y repositorio de imágenes
  Internet((Internet)) --> APPGW
  APPGW --> FE

  ACR -. images .-> AKS
  KV -. secrets (JWT, Redis keys) .-> AKS
  REDIS <--> TODOS
  REDIS <--> LOGP
  AUTH --> USERS
  FE --> AUTH
  FE --> TODOS

  %% Observabilidad
  AKS -. logs/metrics .-> LA
  AKS -. traces .-> ZIPKIN
  AI <---> USERS
  AI <---> FE
  AI <---> AUTH
  AI <---> TODOS
```

Notas:
- El pipeline construye imágenes en ACR y las despliega en AKS.
- Secretos (p. ej., `JWT_SECRET`, claves de Redis) se referencian desde Key Vault (mediante CSI driver o sincronización de secretos).
- App Gateway expone el frontend y enruta al backend en AKS.
- Redis es un servicio administrado de Azure Cache for Redis.
- Observabilidad con Log Analytics y Application Insights; Zipkin corre como pod en AKS.

### 7) Cómo visualizar/exportar
- Vista rápida: abrir este archivo en un editor con soporte Mermaid (VS Code + extensión Mermaid).
- Online: pegar cada bloque en `https://mermaid.live`.
- Exportar: desde la extensión de VS Code o mermaid-cli.


