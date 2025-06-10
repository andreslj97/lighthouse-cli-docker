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

# Instala Chromium
RUN apt-get update && \
    apt-get install -y chromium && \
    ln -s /usr/bin/chromium /usr/bin/chromium-browser

WORKDIR /app

# Copiar solo lo necesario del backend
COPY package*.json ./
COPY ./server ./server

# Copiar configuración y archivos necesarios para Lighthouse CI
COPY .lighthouseci ./.lighthouseci
COPY server/lighthouserc.json ./server/lighthouserc.json

# Copiar el frontend compilado
COPY --from=build /app/build ./build

# Instalar dependencias de producción + lhci CLI
RUN npm install --omit=dev && npm install @lhci/cli@0.15.0 --save-dev

# Establecer variable de entorno CHROME_PATH para Lighthouse
ENV CHROME_PATH=/usr/bin/chromium

EXPOSE 3000

CMD ["npm", "start"]
