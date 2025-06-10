# FASE 1: Build del frontend React
FROM node:20-alpine as build
WORKDIR /app

# Copiar archivos necesarios para build
COPY package*.json ./
COPY ./src ./src
COPY ./public ./public

RUN npm install && npm run build

# FASE 2: Backend + Lighthouse CI
FROM node:20-slim

# Instala Chromium (versión ligera)
RUN apt-get update && \
    apt-get install -y wget ca-certificates fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 libnspr4 libnss3 libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 xdg-utils --no-install-recommends && \
    wget -q https://storage.googleapis.com/chrome-for-testing-public/121.0.6167.85/linux/x64/chrome-linux64.zip && \
    unzip chrome-linux64.zip && \
    mv chrome-linux64 /opt/chrome && \
    ln -s /opt/chrome/chrome /usr/bin/chromium && \
    rm -rf /var/lib/apt/lists/* chrome-linux64.zip

ENV CHROME_PATH=/usr/bin/chromium

WORKDIR /app

# Copiar backend y configuración
COPY package*.json ./
COPY ./server ./server
COPY .lighthouseci ./.lighthouseci
COPY server/lighthouserc.json ./server/lighthouserc.json

# Copiar frontend ya compilado
COPY --from=build /app/build ./build

# Instalar dependencias necesarias
RUN npm install --omit=dev && npm install @lhci/cli@0.15.0 --save-dev

EXPOSE 3000

CMD ["npm", "start"]
