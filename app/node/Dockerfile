FROM node:18.14.1

COPY . .

RUN npm install

WORKDIR /usr/src/app

USER node

ENTRYPOINT ["node", "./bin/www"]
