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
ENV ONETIME_TOKEN=s.C*************
ENV VAULT_ADDR=https://vault-cluster.vault.[VAULT PUBLIC ADDRESS].aws.hashicorp.cloud:8200

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

RUN curl --header "X-Vault-Token: $ONETIME_TOKEN" --header "X-Vault-Namespace: admin" $VAULT_ADDR/v1/cubbyhole/private/access-token | jq -r .data.token > /app/secrets/wrapping_token

RUN WRAPPING_TOKEN=`cat /app/secrets/wrapping_token` && rm -f /app/secrets/wrapping_token && curl --header "X-Vault-Token: $WRAPPING_TOKEN" --header "X-Vault-Namespace: admin" --request POST $VAULT_ADDR/v1/sys/wrapping/unwrap | jq -r .auth.client_token > /app/secrets/vault_token

RUN VAULT_TOKEN=`cat /app/secrets/vault_token` && rm -f /app/secrets/vault_token && curl --header "X-Vault-Token: $VAULT_TOKEN" --header "X-Vault-Namespace: admin" https://vault-cluster.vault.868cd5c7-b7f6-4809-88be-8b6a0b5ea33f.aws.hashicorp.cloud:8200/v1/secret/data/dev --output /app/secrets/temp

RUN ADDR=`cat /app/secrets/temp | jq -r .data.data.private | jq -r .address` && sed -i "s/ADDR/$ADDR/g" /app/secrets/accounts.js
RUN PRIVATE=`cat /app/secrets/temp | jq -r .data.data.private` && sed -i "s/PRIVATE/$PRIVATE/g" /app/secrets/accounts.js

EXPOSE 3000

CMD ["sh", "-c", "PWKEY=`cat /app/secrets/temp | jq -r .data.data.passphrase` && rm -f /app/secrets/temp && npm run start:${WHICHNET} ${PWKEY}"]
#CMD ["sh", "-c", "npm run start:test 123"]
