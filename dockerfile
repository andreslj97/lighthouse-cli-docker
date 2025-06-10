# Fase única: backend + lighthouse
FROM node:20-slim

# Instalar dependencias necesarias + Chromium (vía Debian)
RUN apt-get update && apt-get install -y \
  chromium \
  fonts-liberation \
  libasound2 \
  libnspr4 \
  libnss3 \
  ca-certificates \
  curl \
  gnupg \
  unzip \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

ENV CHROME_PATH=/usr/bin/chromium

WORKDIR /app

# Copiar app (puedes ajustarlo si usas frontend)
COPY package*.json ./
COPY ./server ./server
COPY .lighthouseci ./.lighthouseci
COPY server/lighthouserc.json ./server/lighthouserc.json

RUN npm install && npm install @lhci/cli@0.15.0 --save-dev

CMD ["npx", "lhci", "collect", "--config=server/lighthouserc.json"]
