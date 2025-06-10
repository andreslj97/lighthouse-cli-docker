# FASE 1: Build del frontend React
FROM node:20-alpine as build
WORKDIR /app

# Instalar dependencias y construir React
COPY package*.json ./
COPY ./src ./src
COPY ./public ./public

RUN npm install && npm run build

# FASE 2: Backend con Express + Lighthouse CI
FROM node:20

# Instalar Chromium desde los paquetes oficiales de Debian
RUN apt-get update && \
    apt-get install -y chromium \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar archivos necesarios
COPY package*.json ./
COPY ./server ./server
COPY .lighthouseci ./.lighthouseci
COPY server/lighthouserc.json ./server/lighthouserc.json

# Copiar build de frontend
COPY --from=build /app/build ./build

# Instalar dependencias de producción y lhci
RUN npm install --omit=dev && npm install @lhci/cli@0.15.0 --save-dev

# Variable para que LHCI encuentre Chromium
ENV CHROME_PATH=/usr/bin/chromium

EXPOSE 3000

CMD ["npm", "start"]
