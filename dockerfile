# FASE 1: Build del frontend React
FROM node:20-alpine as build
WORKDIR /app

COPY package*.json ./
COPY ./src ./src
COPY ./public ./public

RUN npm install && npm run build

# FASE 2: Backend + Lighthouse CI + Chromium
FROM node:20-slim

# Instala Chromium y utilidades necesarias
RUN apt-get update && \
    apt-get install -y chromium wget unzip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Define la ruta del binario de Chromium para Lighthouse
ENV CHROME_PATH=/usr/bin/chromium
ENV LIGHTHOUSE_CHROMIUM_PATH=/usr/bin/chromium
ENV NODE_ENV=production

WORKDIR /app

# Copia backend y configuración
COPY package*.json ./
COPY ./server ./server
COPY .lighthouseci ./.lighthouseci
COPY server/lighthouserc.json ./server/lighthouserc.json

# Copia frontend compilado
COPY --from=build /app/build ./build

# Instala dependencias (solo producción + Lighthouse CI)
RUN npm install && npm install @lhci/cli@0.15.0

EXPOSE 3000

CMD ["npm", "start"]
