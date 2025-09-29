# Microservices Application - Polyglot Architecture

[![Build Status](https://github.com/gerson05/microservice-app-example/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/gerson05/microservice-app-example/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Azure](https://img.shields.io/badge/Cloud-Azure-blue.svg)](https://azure.microsoft.com/)

## 📚 Documentación Completa

Este proyecto incluye documentación técnica detallada:

- **[📖 DOCUMENTATION.md](./DOCUMENTATION.md)** - Documentación principal del proyecto
- **[🔧 TECHNICAL_DETAILS.md](./TECHNICAL_DETAILS.md)** - Detalles técnicos y justificaciones
- **[🏗️ ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md)** - Diagramas de arquitectura

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

## 🛠️ Tecnologías

- **Frontend**: Vue.js, Bootstrap Vue, Webpack
- **Backend**: Go (Echo), Java (Spring Boot), Node.js (Express), Python
- **Infraestructura**: Docker, Azure Container Apps, Azure Redis Cache
- **Observabilidad**: Zipkin, Elasticsearch, Prometheus, Grafana
- **CI/CD**: GitHub Actions, Azure Container Registry

## 📊 Características

- ✅ **Arquitectura de Microservicios** con diferentes tecnologías
- ✅ **Trazabilidad Distribuida** con Zipkin
- ✅ **Autenticación JWT** entre servicios
- ✅ **Circuit Breaker Pattern** para resiliencia
- ✅ **Escalado Automático** en Azure Container Apps
- ✅ **Monitoreo Completo** con Prometheus y Grafana
- ✅ **CI/CD Pipeline** automatizado
- ✅ **Seguridad** con HTTPS y autenticación

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

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 👥 Autores

- **Gerson** - *Desarrollo inicial* - [gerson05](https://github.com/gerson05)

## 🙏 Agradecimientos

- Curso de DevOps y Arquitectura de Microservicios
- Comunidad de desarrolladores de microservicios
- Documentación de Azure Container Apps

---

**Para más información, consulta la [documentación completa](./DOCUMENTATION.md)**