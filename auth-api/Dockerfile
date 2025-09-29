# Auth API Dockerfile
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copiar mod y sum
COPY go.mod go.sum ./
RUN go mod download

# Copiar el resto del código
COPY . .

# Inicializar módulos y construir
RUN go mod tidy
RUN CGO_ENABLED=0 go build -o auth-api

# Imagen final
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copiar el binario
COPY --from=builder /app/auth-api .

EXPOSE 8080
ENV AUTH_API_PORT=8081
ENV USERS_API_ADDRESS=http://users-api:8083


CMD ["./auth-api"]
