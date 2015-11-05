FROM node:0.12

COPY . /usr/src/app
WORKDIR /usr/src/app

RUN npm install
RUN npm install -g coffee-script

ENV PATH=node_modules/.bin:$PATH

