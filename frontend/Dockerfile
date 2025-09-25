FROM node:14-alpine AS build-stage

RUN apk add --no-cache python3 make g++

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine

COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=build-stage /app/dist /usr/share/nginx/html
RUN rm -f /etc/nginx/conf.d/default.conf

CMD ["/bin/sh", "-c", "envsubst '${AUTH_HOST} ${AUTH_API_PORT} ${TODOS_API_HOST} ${TODO_API_PORT} ${ZIPKIN_HOST} ${ZIPKIN_PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
