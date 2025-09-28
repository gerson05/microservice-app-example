# Azure Container Apps Deployment

Este directorio contiene la configuración para desplegar los microservicios en Azure Container Apps.

## 📁 Estructura

```
container-apps/
├── apps.json                      # Configuración de todas las aplicaciones
├── deploy-container-apps.sh       # Script completo de despliegue
├── quick-deploy.sh                # Script rápido para testing
├── deploy-fixed.sh                # Script con mejoras
└── README.md                      # Esta documentación
```

## 🚀 Despliegue Rápido

### Opción 1: Script Rápido (Solo Frontend)
```bash
# Despliegue rápido para testing
./container-apps/quick-deploy.sh
```

### Opción 2: Script Completo
```bash
# Editar variables en deploy-container-apps.sh
vim container-apps/deploy-container-apps.sh

# Ejecutar despliegue completo
./container-apps/deploy-container-apps.sh
```

### Opción 2: Comandos Manuales

#### 1. Crear Container Apps Environment
```bash
az containerapp env create \
  --name microservices-env \
  --resource-group microservices-rg \
  --location "East US"
```

#### 2. Desplegar cada aplicación
```bash
# Frontend (acceso externo)
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

# Auth API (acceso interno)
az containerapp create \
  --name auth-api-app \
  --resource-group microservices-rg \
  --environment microservices-env \
  --image microservicesacr.azurecr.io/auth-api:latest \
  --target-port 8081 \
  --ingress internal \
  --cpu 0.25 \
  --memory 512Mi

# Todos API (acceso interno)
az containerapp create \
  --name todos-api-app \
  --resource-group microservices-rg \
  --environment microservices-env \
  --image microservicesacr.azurecr.io/todos-api:latest \
  --target-port 8082 \
  --ingress internal \
  --cpu 0.25 \
  --memory 512Mi

# Users API (acceso interno)
az containerapp create \
  --name users-api-app \
  --resource-group microservices-rg \
  --environment microservices-env \
  --image microservicesacr.azurecr.io/users-api:latest \
  --target-port 8083 \
  --ingress internal \
  --cpu 0.5 \
  --memory 1Gi

# Log Processor (sin ingress)
az containerapp create \
  --name log-processor-app \
  --resource-group microservices-rg \
  --environment microservices-env \
  --image microservicesacr.azurecr.io/log-message-processor:latest \
  --cpu 0.1 \
  --memory 256Mi
```

## 🔧 Configuración

### Variables de Entorno
Cada aplicación tiene sus propias variables de entorno configuradas:

- **Frontend**: `NODE_ENV`, `AUTH_API_ADDRESS`, `TODOS_API_ADDRESS`
- **Auth API**: `JWT_SECRET`, `USERS_API_ADDRESS`, `ZIPKIN_URL`
- **Todos API**: `JWT_SECRET`, `REDIS_HOST`, `REDIS_PORT`, `ZIPKIN_URL`
- **Users API**: `JWT_SECRET`, `SPRING_REDIS_HOST`, `SPRING_ZIPKIN_BASEURL`
- **Log Processor**: `REDIS_HOST`, `REDIS_PORT`, `ZIPKIN_URL`

### Recursos Asignados
- **Frontend**: 0.5 CPU, 1Gi RAM (1-3 réplicas)
- **Auth API**: 0.25 CPU, 512Mi RAM (1-3 réplicas)
- **Todos API**: 0.25 CPU, 512Mi RAM (1-5 réplicas)
- **Users API**: 0.5 CPU, 1Gi RAM (1-3 réplicas)
- **Log Processor**: 0.1 CPU, 256Mi RAM (1-2 réplicas)

## 📊 Monitoreo

### Ver logs
```bash
# Logs de una aplicación específica
az containerapp logs show \
  --name frontend-app \
  --resource-group microservices-rg \
  --follow

# Logs de todas las aplicaciones
az containerapp list \
  --resource-group microservices-rg \
  --query "[].name" \
  --output tsv | \
  xargs -I {} az containerapp logs show \
  --name {} \
  --resource-group microservices-rg
```

### Escalar aplicaciones
```bash
# Escalar frontend a 5 réplicas
az containerapp update \
  --name frontend-app \
  --resource-group microservices-rg \
  --min-replicas 2 \
  --max-replicas 5

# Escalar todos-api a 10 réplicas
az containerapp update \
  --name todos-api-app \
  --resource-group microservices-rg \
  --min-replicas 3 \
  --max-replicas 10
```

### Ver estado de las aplicaciones
```bash
# Listar todas las aplicaciones
az containerapp list \
  --resource-group microservices-rg \
  --output table

# Ver detalles de una aplicación
az containerapp show \
  --name frontend-app \
  --resource-group microservices-rg
```

## 🌐 URLs de Acceso

Después del despliegue, obtén las URLs:

```bash
# URL del frontend
az containerapp show \
  --name frontend-app \
  --resource-group microservices-rg \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv

# URL de monitoreo
az containerapp show \
  --name monitoring-app \
  --resource-group microservices-rg \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv
```

## 🔐 Secretos

Los secretos se configuran automáticamente en el script de despliegue:

- `jwt-secret`: Secreto JWT para autenticación
- `redis-connection-string`: Cadena de conexión a Azure Redis
- `acr-password`: Contraseña del Azure Container Registry
- `grafana-password`: Contraseña de Grafana

## 🧹 Limpieza

Para eliminar todas las aplicaciones:

```bash
# Eliminar todas las aplicaciones
az containerapp list \
  --resource-group microservices-rg \
  --query "[].name" \
  --output tsv | \
  xargs -I {} az containerapp delete \
  --name {} \
  --resource-group microservices-rg \
  --yes

# Eliminar el environment
az containerapp env delete \
  --name microservices-env \
  --resource-group microservices-rg \
  --yes
```

## 🔄 CI/CD

El workflow de GitHub Actions está configurado para:

1. **Build**: Construir imágenes Docker y subirlas a ACR
2. **Deploy**: Desplegar automáticamente a Container Apps en producción
3. **Update**: Actualizar aplicaciones existentes con nuevas imágenes

### Secrets necesarios en GitHub:
- `AZURE_CREDENTIALS`: Credenciales de Azure
- `ACR_USERNAME`: Usuario del ACR
- `ACR_PASSWORD`: Contraseña del ACR

## 🆘 Troubleshooting

### Aplicación no inicia
```bash
# Ver logs detallados
az containerapp logs show \
  --name <app-name> \
  --resource-group microservices-rg \
  --follow

# Ver eventos
az containerapp show \
  --name <app-name> \
  --resource-group microservices-rg \
  --query "properties.template.containers[0].probes"
```

### Problemas de conectividad
```bash
# Verificar configuración de red
az containerapp env show \
  --name microservices-env \
  --resource-group microservices-rg \
  --query "properties.vnetConfiguration"
```

### Problemas de recursos
```bash
# Ver uso de recursos
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/microservices-rg/providers/Microsoft.App/containerApps/frontend-app \
  --metric "CpuUsage" \
  --interval PT1M
```
