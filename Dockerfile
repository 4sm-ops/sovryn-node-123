FROM node:14-slim

ENV WHICHNET=test
ENV KEYPW=T3stS0vryn
ENV LIQUIDATOR_ADDRESS=0x9Af00e58040f2F0FBfb3aCd542F7C5f1A4FAbD70
ENV LIQUIDATOR_PRIVATE_KEY=dde2ec361acec024e78587f605fb8f2f098aacb5c492393e7cca66a42f288664
ENV ROLLOVER_ADDRESS=0x9Af00e58040f2F0FBfb3aCd542F7C5f1A4FAbD70
ENV ROLLOVER_PRIVATE_KEY=dde2ec361acec024e78587f605fb8f2f098aacb5c492393e7cca66a42f288664
ENV ARBITRAGE_ADDRESS=0x9Af00e58040f2F0FBfb3aCd542F7C5f1A4FAbD70
ENV ARBITRAGE_PRIVATE_KEY=dde2ec361acec024e78587f605fb8f2f098aacb5c492393e7cca66a42f288664
ENV TELEGRAM_BOT_KEY=

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
#CMD ["sh", "-c", "npm run start:test 123"]
