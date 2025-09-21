# Auth API Dockerfile
FROM golang:1.16-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY Gopkg.toml Gopkg.lock ./

# Install dependencies using dep
RUN go get -u github.com/golang/dep/cmd/dep && dep ensure

# Copy source code
COPY . .

# Build the application
RUN go build -o auth-api main.go

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary
COPY --from=builder /app/auth-api .

# Expose port
EXPOSE 8081

# Set environment variables
ENV AUTH_API_PORT=8081
ENV JWT_SECRET=myfancysecret
ENV USERS_API_ADDRESS=http://users-api:8083

# Start the application
CMD ["./auth-api"]
