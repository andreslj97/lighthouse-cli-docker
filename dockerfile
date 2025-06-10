# FASE 1: Build del frontend React
FROM node:20-alpine as build
WORKDIR /app

# Instalar dependencias y construir React
COPY package*.json ./
COPY ./src ./src
COPY ./public ./public

RUN npm install && npm run build

# FASE 2: Backend con Express + Lighthouse CLI
FROM node:20-alpine
WORKDIR /app

# Copiar solo lo necesario del backend
COPY package*.json ./
COPY ./server ./server

# Copiar configuración y archivos necesarios para Lighthouse CI
COPY .lighthouseci ./.lighthouseci
COPY server/lighthouserc.json ./server/lighthouserc.json

# Copiar la carpeta build generada por React
COPY --from=build /app/build ./build

# Instalar solo dependencias necesarias para producción
RUN npm install --omit=dev && npm install @lhci/cli@0.15.0 --save-dev

EXPOSE 3000

CMD ["npm", "start"]
