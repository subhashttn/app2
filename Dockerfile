FROM node:18 AS builder

WORKDIR /app
COPY package.json ./
RUN npm install

COPY server.js .
RUN npm run build


FROM node:18-alpine

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package.json package-lock.json ./

EXPOSE 80
CMD ["node", "dist/server.js"]
