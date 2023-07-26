FROM node:18.14.1

WORKDIR /usr/src/app

COPY . .

RUN npm install

USER node

ENTRYPOINT ["node", "./bin/www"]
