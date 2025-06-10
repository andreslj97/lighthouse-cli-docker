# FASE 1: Build de React
FROM node:20-alpine as build
WORKDIR /app
COPY package*.json ./
COPY ./src ./src
COPY ./public ./public
RUN npm install
RUN npm run build

# FASE 2: Backend con Express
FROM node:20-alpine
WORKDIR /app

# Copiar solo lo necesario para backend
COPY package*.json ./
COPY ./server ./server

# Copiar build del frontend
COPY --from=build /app/build ./build

RUN npm install --only=production

EXPOSE 3000

CMD ["npm", "start"]
