# Log Message Processor Dockerfile
FROM python:3.6-alpine

# Install build dependencies
RUN apk add --no-cache gcc musl-dev

WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Set environment variables
ENV REDIS_HOST=redis
ENV REDIS_PORT=6379
ENV REDIS_CHANNEL=log_channel
ENV ZIPKIN_URL=http://zipkin:9411/api/v2/spans

# Start the application
CMD ["python", "main.py"]
