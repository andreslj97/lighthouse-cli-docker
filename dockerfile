# FASE 1: Build del frontend React
FROM node:20-alpine as build
WORKDIR /app

# Copiamos solo lo necesario para instalar dependencias y construir
COPY package*.json ./
COPY ./src ./src
COPY ./public ./public

RUN npm ci && npm run build

# FASE 2: Backend + Lighthouse CI + Chromium
FROM node:20-slim

# Evita recomendaciones e instala solo lo necesario
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        chromium \
        wget \
        unzip \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Variables de entorno necesarias para Lighthouse
ENV CHROME_PATH=/usr/bin/chromium
ENV LIGHTHOUSE_CHROMIUM_PATH=/usr/bin/chromium
ENV NODE_ENV=production

WORKDIR /app

# Copiamos solo lo necesario para producción
COPY package*.json ./
COPY ./server ./server
COPY .lighthouseci ./.lighthouseci
COPY server/lighthouserc.json ./server/lighthouserc.json
COPY --from=build /app/build ./build

# Instala solo dependencias de producción + Lighthouse CI global
RUN npm ci --omit=dev && npm install -g @lhci/cli

# Crear usuario no-root
RUN useradd -m lhciuser
USER lhciuser

EXPOSE 3000

CMD ["npm", "start"]
