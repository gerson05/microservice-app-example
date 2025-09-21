# Users API Dockerfile
FROM maven:3.6.3-openjdk-8 AS builder

WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Final stage
FROM openjdk:8-jre-alpine

WORKDIR /app

# Copy the jar file
COPY --from=builder /app/target/*.jar app.jar

# Expose port
EXPOSE 8083

# Set environment variables
ENV SERVER_PORT=8083
ENV JWT_SECRET=myfancysecret
ENV SPRING_ZIPKIN_BASEURL=http://zipkin:9411/

# Start the application
CMD ["java", "-jar", "app.jar"]
