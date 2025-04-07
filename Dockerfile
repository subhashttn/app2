FROM node:18 AS buildstage

WORKDIR /app

COPY package.json .

RUN npm install


COPY . .



FROM node:18-alpine 

WORKDIR /app

COPY --from=buildstage /app .

EXPOSE 3000

CMD ["node", "server.js"]
