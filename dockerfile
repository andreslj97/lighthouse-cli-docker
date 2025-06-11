# FASE 1: Build del frontend React
FROM node:20-alpine as build
WORKDIR /app

COPY package*.json ./
COPY ./src ./src
COPY ./public ./public

RUN npm install && npm run build

# FASE 2: Backend + Lighthouse CI + Chromium
FROM node:20-slim

RUN apt-get update && \
    apt-get install -y chromium wget unzip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ENV CHROME_PATH=/usr/bin/chromium
ENV LIGHTHOUSE_CHROMIUM_PATH=/usr/bin/chromium
ENV NODE_ENV=production

WORKDIR /app

COPY package*.json ./
COPY ./server ./server
COPY .lighthouseci ./.lighthouseci
COPY server/lighthouserc.json ./server/lighthouserc.json
COPY --from=build /app/build ./build

# Instala solo producción + LHCI
RUN npm install --omit=dev && npm install -g @lhci/cli

EXPOSE 3000

# Puedes usar una entrada para que ejecute Lighthouse automáticamente
#CMD ["sh", "-c", "npm start & sleep 5 && npm run lhci"]
CMD ["sh", "-c", "npm start & sleep 5 && npx lhci autorun"]

