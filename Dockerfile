FROM node:14-slim

RUN apt-get update && apt-get -y install procps

WORKDIR /app

###

COPY package.json /app
#COPY package-lock.json /app

RUN npm install --loglevel verbose 
RUN npm install -g mocha nodemon

### Add application files

COPY . /app

RUN mkdir -p puplic/dist
RUN npm run build-client

RUN mkdir /app/secrets /app/logs /app/db

RUN mv /app/accounts.js /app/secrets/
RUN mv /app/telegram.js /app/secrets/

EXPOSE 3000

CMD ["sh", "-c", "npm run start:${WHICHNET} ${KEYPW}"]

