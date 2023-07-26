FROM node:18.14.1

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y wget

COPY . .

RUN npm install

USER node

ENTRYPOINT ["node", "./bin/www"]
