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

RUN curl --header "X-Vault-Token: $ONETIME_TOKEN" --header "X-Vault-Namespace: admin" $VAULT_ADDR/v1/cubbyhole/private/access-token | jq -r .data.token > /app/secrets/wrapping_token

RUN WRAPPING_TOKEN=`cat /app/secrets/wrapping_token` && rm -f /app/secrets/wrapping_token && curl --header "X-Vault-Token: $WRAPPING_TOKEN" --header "X-Vault-Namespace: admin" --request POST $VAULT_ADDR/v1/sys/wrapping/unwrap | jq -r .auth.client_token > /app/secrets/vault_token

RUN VAULT_TOKEN=`cat /app/secrets/vault_token` && rm -f /app/secrets/vault_token && curl --header "X-Vault-Token: $VAULT_TOKEN" --header "X-Vault-Namespace: admin" "$VAULT_ADDR/v1/secret/data/dev" --output /app/secrets/temp

RUN ADDR=`cat /app/secrets/temp | jq -r .data.data.private | jq -r .address` && sed -i "s/ADDR/$ADDR/g" /app/secrets/accounts.js
RUN PRIVATE=`cat /app/secrets/temp | jq -r .data.data.private` && sed -i "s/PRIVATE/$PRIVATE/g" /app/secrets/accounts.js

EXPOSE 3000

#CMD ["sh", "-c", "PWKEY=`cat /app/secrets/temp | jq -r .data.data.passphrase` && rm -f /app/secrets/temp && npm run start:${WHICHNET} ${PWKEY}"]
CMD ["sh", "-c", "npm run start:${WHICHNET}"]
