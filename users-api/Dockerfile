# users-api/Dockerfile - multi-stage build

# Stage 1: build with Maven (uses Java 8 to match the project)
FROM maven:3.6.3-jdk-8 AS builder
WORKDIR /app

# Copy Maven wrapper and project files
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Copy source and build
COPY src ./src

# Ensure wrapper is executable and build the project (skip tests to speed up)
RUN chmod +x mvn || true
RUN mvn -B -DskipTests clean package

# Stage 2: runtime
FROM openjdk:8-jre-alpine
WORKDIR /app

COPY --from=builder /app/target/*.jar ./users-api.jar

# Expose port and run
EXPOSE 8083
ENV SERVER_PORT=8083
CMD ["java", "-jar", "./users-api.jar"]