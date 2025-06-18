# Etapa 1: Construir frontend de React
FROM node:20-alpine as build
WORKDIR /app

COPY package*.json ./
COPY ./src ./src
COPY ./public ./public

RUN npm ci && npm run build

# Etapa 2: Producción + Puppeteer
FROM node:20-slim

ENV NODE_ENV=production
ENV CHROME_PATH=/usr/bin/chromium

WORKDIR /app

# Instalar Chromium y dependencias necesarias para Puppeteer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    chromium \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libgbm1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    wget \
    unzip \
    ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copiar archivos necesarios
COPY package*.json ./
COPY server ./server
COPY .lighthouseci ./.lighthouseci
COPY --from=build /app/build ./build

# Instalar dependencias sin ejecutar scripts (para que Puppeteer no descargue Chromium)
RUN npm ci --omit=dev --ignore-scripts

# Instalar Puppeteer global si lo necesitas (opcional)
# RUN npm install -g puppeteer

# Puerto que expone la app si aplica
EXPOSE 3000

# Comando de arranque
CMD ["npm", "start"]
