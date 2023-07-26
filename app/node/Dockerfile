FROM node:18.14.1

WORKDIR /usr/src/app

COPY . .

RUN npm --verbose install

USER node

ENTRYPOINT ["node", "./bin/www"]
