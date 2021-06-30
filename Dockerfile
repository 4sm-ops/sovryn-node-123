FROM node:14-slim

ENV WHICHNET=test
#ENV KEYPW=T3stS0vryn
#ENV VAULT_ADDR="https://vault-cluster.vault.[VAULT PUBLIC ADDRESS].aws.hashicorp.cloud:8200"
#ENV ONETIME_TOKEN=

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
RUN apt-get install -y curl jq

CMD ["sh", "-c", "bash /app/get_secret"]

EXPOSE 3000

#CMD ["sh", "-c", "PWKEY=`cat /app/secrets/temp | jq -r .data.data.passphrase` && rm -f /app/secrets/temp && npm run start:${WHICHNET} ${PWKEY}"]
CMD ["sh", "-c", "npm run start:${WHICHNET}"]
