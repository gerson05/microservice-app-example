# Detalles Técnicos - Microservices Application

## 🎯 Justificación Técnica

### ¿Por qué Microservicios?

**Problema a resolver**: Aplicaciones monolíticas tradicionales presentan limitaciones en:
- **Escalabilidad**: Todo el sistema escala junto, incluso componentes que no lo necesitan
- **Tecnología**: Dificultad para adoptar nuevas tecnologías sin afectar todo el sistema
- **Despliegue**: Un cambio pequeño requiere desplegar toda la aplicación
- **Equipos**: Múltiples equipos trabajando en el mismo código base

**Solución**: Arquitectura de microservicios que permite:
- **Escalabilidad independiente**: Cada servicio escala según sus necesidades
- **Tecnología diversa**: Cada servicio puede usar la tecnología más adecuada
- **Despliegue independiente**: Cambios en un servicio no afectan otros
- **Equipos autónomos**: Cada equipo puede trabajar independientemente

### ¿Por qué Arquitectura Poliglota?

**Ventajas**:
1. **Tecnología óptima por servicio**: Go para APIs de alta concurrencia, Java para lógica de negocio compleja
2. **Aprendizaje continuo**: Equipos pueden experimentar con nuevas tecnologías
3. **Resiliencia**: Si una tecnología falla, no afecta todo el sistema
4. **Especialización**: Cada servicio puede optimizarse para su caso de uso específico

## 🏗️ Decisiones de Arquitectura

### 1. Patrón de Comunicación

**Decisión**: Comunicación síncrona HTTP + asíncrona Redis

**Justificación**:
- **HTTP REST**: Simplicidad, estándar, fácil debugging
- **Redis**: Message queue para logs y eventos asíncronos
- **Evitar**: Message brokers complejos (Kafka, RabbitMQ) para simplicidad

### 2. Autenticación y Autorización

**Decisión**: JWT (JSON Web Tokens)

**Justificación**:
- **Stateless**: No requiere almacenamiento de sesiones
- **Escalable**: Funciona bien en arquitecturas distribuidas
- **Estándar**: Ampliamente soportado
- **Seguridad**: Firmado digitalmente, no puede ser modificado

### 3. Observabilidad

**Decisión**: Zipkin + Elasticsearch + Prometheus + Grafana

**Justificación**:
- **Zipkin**: Trazabilidad distribuida estándar
- **Elasticsearch**: Almacenamiento escalable de traces
- **Prometheus**: Métricas de sistema y aplicación
- **Grafana**: Visualización y dashboards

### 4. Infraestructura

**Decisión**: Azure Container Apps

**Justificación**:
- **Serverless**: No gestión de nodos
- **Escalado automático**: Basado en métricas
- **Integración**: Nativa con Azure services
- **Costo**: Solo pagas por lo que usas

## 🔧 Implementación Técnica

### Frontend (Vue.js)

**Tecnologías elegidas**:
- **Vue.js 2.x**: Framework progresivo, curva de aprendizaje suave
- **Bootstrap Vue**: Componentes UI pre-construidos
- **Vue Resource**: Cliente HTTP simple

**Arquitectura**:
```javascript
// Estructura de componentes
App.vue
├── Login.vue (Autenticación)
├── Todos.vue (Gestión de tareas)
├── AppNav.vue (Navegación)
└── common/
    └── Spinner.vue (Loading states)
```

**Configuración de Proxies**:
```javascript
// webpack dev server proxies
proxyTable: {
  '/login': 'http://auth-api:8081',
  '/todos': 'http://todos-api:8082',
  '/zipkin': 'http://zipkin:9411'
}
```

### Auth API (Go)

**Tecnologías elegidas**:
- **Echo Framework**: Ligero, rápido, middleware extensible
- **JWT-Go**: Librería estándar para JWT
- **GoBreaker**: Circuit breaker pattern
- **Zipkin-Go**: Trazabilidad distribuida

**Patrones implementados**:
```go
// Circuit Breaker para resiliencia
cbSettings := gobreaker.Settings{
    Name:        "UsersAPI",
    MaxRequests: 3,
    Interval:    60 * time.Second,
    Timeout:     10 * time.Second,
}
```

**Flujo de autenticación**:
1. Usuario envía credenciales
2. Auth API valida contra Users API
3. Si válido, genera JWT token
4. Token incluye claims (username, role, exp)
5. Frontend almacena token para requests futuros

### Users API (Spring Boot)

**Tecnologías elegidas**:
- **Spring Boot 1.5.6**: Framework maduro para microservicios
- **Spring Security**: Autenticación y autorización
- **Spring Data JPA**: Abstracción de persistencia
- **H2 Database**: Base de datos en memoria para desarrollo

**Configuración de seguridad**:
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter();
    }
}
```

**Modelo de datos**:
```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String username;
    private String firstName;
    private String lastName;
    private UserRole role;
}
```

### Todos API (Node.js)

**Tecnologías elegidas**:
- **Express.js**: Framework minimalista y flexible
- **Redis**: Cache y message queue
- **JWT**: Validación de tokens
- **Zipkin**: Trazabilidad distribuida

**Arquitectura**:
```javascript
// Estructura modular
server.js (Main server)
├── routes.js (API routes)
├── todoController.js (Business logic)
└── middleware/
    ├── auth.js (JWT validation)
    └── tracing.js (Zipkin integration)
```

**Integración con Redis**:
```javascript
const redisClient = require("redis").createClient({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT,
  retry_strategy: function (options) {
    // Retry logic for resilience
  }
});
```

### Log Processor (Python)

**Tecnologías elegidas**:
- **Redis**: Consumo de mensajes
- **Zipkin**: Envío de traces
- **Asyncio**: Procesamiento asíncrono

**Arquitectura**:
```python
async def process_logs():
    while True:
        message = await redis_client.blpop('log_channel')
        if message:
            await send_to_zipkin(message)
```

## 🚀 Despliegue y DevOps

### Containerización

**Estrategia**: Un contenedor por servicio

**Dockerfile optimizado**:
```dockerfile
# Multi-stage build para reducir tamaño
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:16-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
```

### CI/CD Pipeline

**Estrategia**: GitHub Actions con multi-language support

**Pipeline stages**:
1. **Build**: Construcción de imágenes Docker
2. **Test**: Pruebas unitarias por servicio
3. **Security**: Escaneo con Trivy
4. **Deploy**: Despliegue automático a Azure
5. **Monitor**: Verificación de salud

**Configuración de build**:
```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    context: ./${{ matrix.service }}
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Azure Container Apps

**Configuración de servicios**:
```bash
az containerapp create \
  --name frontend-app \
  --resource-group microservices-rg \
  --environment microservices-env \
  --image microservicesacr.azurecr.io/frontend:latest \
  --target-port 8080 \
  --ingress external \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 1 \
  --max-replicas 3
```

**Escalado automático**:
- **Métricas**: CPU, memoria, requests por segundo
- **Políticas**: Escalar basado en concurrent requests
- **Límites**: Min 1, Max 5 réplicas por servicio

## 📊 Observabilidad

### Trazabilidad Distribuida

**Implementación con Zipkin**:
```go
// Go - Auth API
if tracedMiddleware, tracedClient, err := initTracing(zipkinURL); err == nil {
    e.Use(echo.WrapMiddleware(tracedMiddleware))
    userService.Client = tracedClient
}
```

**Flujo de traces**:
1. Request llega al frontend
2. Frontend crea span y llama a Auth API
3. Auth API crea child span y llama a Users API
4. Todos los spans se envían a Zipkin
5. Zipkin almacena en Elasticsearch

### Métricas y Monitoreo

**Prometheus scraping**:
```yaml
scrape_configs:
  - job_name: 'frontend'
    static_configs:
      - targets: ['frontend-app.internal:8080']
  - job_name: 'auth-api'
    static_configs:
      - targets: ['auth-api-app.internal:8081']
```

**Dashboards de Grafana**:
- **Application Metrics**: Requests/sec, latency, error rate
- **Infrastructure Metrics**: CPU, memory, network
- **Business Metrics**: Active users, todos created

## 🔒 Seguridad

### Autenticación JWT

**Token structure**:
```json
{
  "username": "johnd",
  "firstname": "John",
  "lastname": "Doe",
  "role": "USER",
  "exp": 1640995200
}
```

**Validación**:
```javascript
// Frontend - Añadir token a requests
Vue.http.interceptors.push((request, next) => {
  const token = store.state.auth.accessToken
  if (token) {
    request.headers.set('Authorization', 'Bearer ' + token)
  }
  next()
})
```

### Seguridad de Red

**Container Apps**:
- **Ingress interno**: Servicios internos no expuestos
- **Ingress externo**: Solo frontend y monitoring
- **TLS**: HTTPS automático para servicios externos

**Azure Redis Cache**:
- **TLS**: Conexiones encriptadas
- **Autenticación**: Password requerida
- **Red privada**: Solo accesible desde Container Apps

## 🧪 Testing Strategy

### Pruebas Unitarias

**Cobertura por servicio**:
- **Go**: `go test -cover`
- **Java**: Maven Surefire + JaCoCo
- **Node.js**: Jest + Istanbul
- **Python**: pytest + coverage

### Pruebas de Integración

**Docker Compose testing**:
```bash
# Health checks automáticos
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Pruebas de Carga

**K6 performance testing**:
```javascript
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '1m', target: 20 },
    { duration: '30s', target: 0 },
  ],
};
```

## 🔧 Troubleshooting Avanzado

### Debugging de Microservicios

**Herramientas**:
- **Zipkin UI**: Trazabilidad de requests
- **Container logs**: `az containerapp logs show`
- **Prometheus metrics**: Métricas en tiempo real
- **Grafana dashboards**: Visualización de datos

**Comandos útiles**:
```bash
# Ver logs de un servicio específico
az containerapp logs show --name frontend-app --resource-group microservices-rg --follow

# Ver métricas de CPU/memoria
az monitor metrics list --resource /subscriptions/.../frontend-app --metric "CpuUsage"

# Escalar servicio
az containerapp update --name frontend-app --resource-group microservices-rg --min-replicas 2 --max-replicas 5
```

### Problemas Comunes y Soluciones

**1. Circuit Breaker abierto**:
- **Síntoma**: Error 503 en Auth API
- **Causa**: Users API no responde
- **Solución**: Verificar Users API, reiniciar si es necesario

**2. Redis connection timeout**:
- **Síntoma**: Error de conexión a Redis
- **Causa**: Azure Redis Cache no disponible
- **Solución**: Verificar estado del Redis Cache

**3. JWT token inválido**:
- **Síntoma**: Error 401 en requests autenticados
- **Causa**: JWT_SECRET diferente entre servicios
- **Solución**: Verificar variables de entorno

## 📈 Optimizaciones y Mejoras Futuras

### Optimizaciones de Rendimiento

**1. Caching Strategy**:
- **Redis**: Cache de datos frecuentemente accedidos
- **CDN**: Assets estáticos del frontend
- **Database**: Query optimization

**2. Escalado**:
- **Horizontal**: Más réplicas de servicios
- **Vertical**: Más CPU/memoria por contenedor
- **Auto-scaling**: Basado en métricas personalizadas

### Mejoras de Arquitectura

**1. Service Mesh**:
- **Istio**: Gestión de tráfico y seguridad
- **Envoy**: Proxy sidecar para cada servicio
- **mTLS**: Comunicación encriptada entre servicios

**2. Event-Driven Architecture**:
- **Event Sourcing**: Almacenamiento de eventos
- **CQRS**: Separación de comandos y consultas
- **Saga Pattern**: Transacciones distribuidas

**3. Observabilidad Avanzada**:
- **OpenTelemetry**: Estándar de observabilidad
- **Jaeger**: Trazabilidad distribuida
- **ELK Stack**: Logs centralizados

---

*Esta documentación técnica detalla las decisiones de arquitectura, implementación y operaciones del sistema de microservicios, proporcionando una base sólida para el mantenimiento y evolución del proyecto.*
