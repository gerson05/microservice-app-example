# TODOs API Dockerfile
FROM node:8.17.0-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Expose port
EXPOSE 8082

# Set environment variables
ENV TODO_API_PORT=8082
ENV JWT_SECRET=myfancysecret
ENV REDIS_HOST=redis
ENV REDIS_PORT=6379
ENV REDIS_CHANNEL=log_channel
ENV ZIPKIN_URL=http://zipkin:9411/api/v2/spans

# Start the application
CMD ["npm", "start"]
