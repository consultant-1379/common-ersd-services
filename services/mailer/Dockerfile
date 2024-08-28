FROM armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/node:8.9.4-alpine

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN npm install \
&& npm cache clean --force

EXPOSE 3001

RUN apk --update add python

CMD ["npm", "start"]
