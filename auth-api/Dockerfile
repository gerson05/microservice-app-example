# Auth API Dockerfile
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copiar mod y sum
COPY go.mod go.sum ./
RUN go mod download

# Copiar el resto del código
COPY . .

# Compilar todo el proyecto, no solo main.go
RUN go build -o auth-api .

# Final stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/auth-api .

EXPOSE 8081

ENV AUTH_API_PORT=8081
ENV JWT_SECRET=myfancysecret
ENV USERS_API_ADDRESS=http://users-api:8083

CMD ["./auth-api"]
