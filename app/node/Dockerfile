FROM node:18.14.1

WORKDIR /usr/src/app

COPY . .

RUN npm install

ENTRYPOINT [ "node", "./bin/www" ]
