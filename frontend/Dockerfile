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

# CMD que especifica EXACTAMENTE qué variables reemplazar
CMD ["/bin/sh", "-c", "envsubst '${AUTH_API_URL} ${TODOS_API_URL} ${ZIPKIN_URL}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]