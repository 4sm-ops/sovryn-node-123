# Sovryn Node deployment guide

## What is a Sovryn Node?

A Sovryn Node is the part of the Sovryn dapp that monitors the continuous marginal trading on the platform. It's main functions are as follows:

**Liquidation of expired positions**
The Nodes are check if leveraged trading positions on the platform are above liquidation levels (the trade margin is in excess of the maintenance margin). The nodes automatically liquidate positions if they fail this check and the liquidation criteria is met. The node then contacts both the liquidator and the liquidated and reports the outcome.

**Rollover of open positions**
When the maximum loan duration has been exceeded, the position will need to be rolled over. The function "rollover" on the protocol contract extends the loan duration by the maximum term (currently 28 days for margin trades) and pays the interest to the lender. The callers reward is 0.1% of the position size and also receives 2x the gas cost (using the fast gas price as base for the calculation).

**Taking advantage of arbitrage opportunities on the AMM**
Earning money through arbitrage in situations where the expected price from the AMM deviates more than 2% from the oracle price for an asset. The node buys the side which is off.

## What is Akash?

The Akash Platform is a deployment platform for hosting and managing containers where users can run any Cloud-Native application. The Akash Platform is built with a set of cloud management services including Kubernetes to orchestrate and manage containers.

Useful links:
https://docs.akash.network

## 1. Prepare new repo

1.1 Create new repo, copy files from official repository https://github.com/DistributedCollective/Sovryn-Node

```shell script
git clone https://github.com/DistributedCollective/Sovryn-Node
```

Useful links:

https://github.com/ovrclk/awesome-akash/tree/master/sovryn-node

## 2. Telegram bot and chat configuration

Sovryn node uses Telegram chat/bot to send notifications about new transactions and errors.

2.1 Use https://t.me/BotFather  to create new bot (`/newbot` command).
Also you can use `/help` for more specified options to your bot and [official telegram helps](https://core.telegram.org/bots#6-botfather)

![Create Telegram Bot!](/images/telegram01.png "Create Telegram Bot")

2.2 Get API token.
`id:apiToken`
for i.e. `1876066462:AAF1nDRouq1rOqhjrJIo5eCWuC3-ktQ8iSI`

![Get API token!](/images/telegram02.png "Get API token")

2.3 Create new chat and add created telegram bot. Send some messages to newly created chat.

2.4 Use following URL to get Chat ID starting with ("-") symbol: https://api.telegram.org/bot[BOT-API-TOKEN]/getUpdates

for i.e. ` curl https://api.telegram.org/botBOT-API-TOKEN]/getUpdates`
and you'll get response `{"ok":true,"result":[]}`

![Get API token!](/images/telegram03.png "Get API token")

2.5 To receive notifications on telegram write API token in a file **/secrets/telegram.js**

```
export default "[telegram-bot-token]";
```

and write Chat ID to **/config/config_mainnet.js and /config/config_testnet.js** files.

```
sovrynInternalTelegramId: -492690059,
```

## 3. Create wallet in RSK blockchain and export keys

To trade on Sovryn, you will need to set up a Web3 wallet that is compatible with the RSK chain (Rootstock).

### Testnet Wallet setup

3.1 Go to the **Metamask** website and download the latest version of the Metamask Wallet extension.

3.2 Install and have the Metamask extension active in your browser.

3.3 Open Metamask and register on it. (Do not forget to save your recovery phrase!)

3.4 Click the circle in the upper right of the wallet **→ Settings → Networks →** click the **Add Network** button and enter the following **RSK Network** settings.

* **Network Name:** RSK Testnet
* **New RPC URL:** https://public-node.testnet.rsk.co
* **Chain ID:** 31
* **Currency Symbol:** tRBTC
* **Block Explorer URL:** https://explorer.testnet.rsk.co

3.5 Hit Save and make sure you are switched to the RSK Mainnet. 

3.6 Request some tRBTC from https://faucet.rsk.co

3.7 Save your public key from Metamask and export your private key: **→ Account → Account Details → Export private key**. That will be your credentials of the liquidator/rollover/arbitrage wallets credentials

### Useful links
https://wiki.sovryn.app/en/getting-started/wallet-setup

## 4. Convert keys to Keystore v3 format and put them into HashiCorp Vault 

### Private key security

A private key is a sophisticated form of cryptography that allows a user to access their cryptocurrency.
Original Sovryn Node repository keeps private key \[or private key password\] in a clear text format in accounts.js file (or in \*.yml file EVN section).

Following guidline aims to protect private key using HashiCorp Vault. The wrapped secret can be unwrapped using the single-use wrapping token. Even the user or the system created the initial token won't see the original value.

Key principles are:
* Avoid storing crypto wallet private key in a repo and in an image
* Try to avoid using long lived Vault access tokens in a running Akash container

![Securing private key Concept!](/images/Sovryn%20Vault%20interaction%20diagram%20v01.png "Securing private key Concept")

### HashiCorp Cloud Platform (HCP) setup // Cloud Vault Cluster

1. Create a Vault Cluster in HCP (https://portal.cloud.hashicorp.com)

Official instructions are available here: https://learn.hashicorp.com/tutorials/cloud/get-started-vault?in=vault/cloud

### Secure private key delivery // Cubbyhole Response Wrapping

We use Vault's cubbyhole response wrapping approach where the initial token is stored in the cubbyhole secrets engine. The wrapped secret can be unwrapped using the single-use wrapping token. Even the user or the system created the initial token won't see the original value. The wrapping token is short-lived and can be revoked just like any other tokens so that the risk of unauthorized access can be minimized.

All secrets are namespaced under **your token**. If that token expires or is revoked, all the secrets in its cubbyhole are revoked as well.

It is not possible to reach into another token's cubbyhole even as the root user. This is an important difference between the cubbyhole and the key/value secrets engine. The secrets in the key/value secrets engine are accessible to any token for as long as its policy allows it.

Benefits of using the response wrapping:

* It provides cover by ensuring that the value being transmitted across the wire is not the actual secret. It's a reference to the secret.
* It provides malfeasance detection by ensuring that only a single party can ever unwrap the token and see what's inside
* It limits the lifetime of the secret exposure

![cubbyhole!](/images/vault-cubbyhole01.png "Vault cubbyhole")

### Create Vault access token

1. Install Vault CLI client.

Use official guideline. https://www.vaultproject.io/docs/install

2. Define environment variables, authenticate and create new access token.

```
# Export env variables for Vault
export VAULT_ADDR="https://vault-cluster.vault.[VAULT PUBLIC ADDRESS].aws.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
read -s token
export VAULT_TOKEN=$token

# To make sure that we'are authenticated run following command
vault token lookup 

# Create a policy for the node
cat << EOF > node-policy.hcl
path "secret/data/dev" {
  capabilities = [ "read" ]
}
EOF

vault policy write node-policy node-policy.hcl

# Enable key/value v2 secrets engine at secret/ if it's not enabled already
 vault secrets enable -path=secret kv-v2
```
To make node working we need to update **accounts.js** file with the credentials of the liquidator/rollover/arbitrage wallets.
You have 2 options
* \[Insecure\] you can specify pKey instead of ks to just use the private key
* \[Secure\] ks = encrypted keystore file in v3 standard. (Do not forget to save your keystore password!)
Here post we'll demonstrate secure method.

Install python3, pip3 and web3 library.

```
pip3 install web3
```
We have prepared simple [python3 script](https://github.com/rustamabdullin/sovryn-node-123/blob/main/pkey_encrypt) to generate keystore v3 JSON and to send it to HashiCorp Vault.

Script will prompt to enter Private Key and Passphrase to generate Keystore v3 JSON
Also script will ask such data as VAULT_ADDR, VAULT_NAMESPACE, VAULT_TOKEN to automatically store credentials in HashiCorp Vault.\n
Script also checks if these variables present as env variables.

In example showed below user hasn't specified Vault variables in env and he will be prompted to enter them manually.
```
[user@localhost sovryn-node-123-main]$ python3 pkey_encrypt.py 
Private key (Input hidden): 
Passphrase (Input hidden): 
Confirm pass (Input hidden): 
Vault address: https://vault-cluster.vault.[VAULT PUBLIC ADDRESS].aws.hashicorp.cloud:8200
Vault secret path: /v1/secret/data/dev
Vault namespace: admin
Vault token (Input hidden): 
Private key and passphrase has been written to a Vault
```

```
# Generating one-time token that'll be used on a node to get wrapping token.
ONETIME_TOKEN=`vault token create -use-limit=2 -policy=default | grep -w token | awk '{print $2}'`

# Generating wrapping token that'll be used for retrieving the secret
WRAPPING_TOKEN=`vault token create -policy=node-policy -wrap-ttl=300 | grep -w "wrapping_token:" | awk '{print $2}'`

# Store wrapping token in a cubbyhole storage using newly generated token that'll expire in the next one use
VAULT_TOKEN="$ONETIME_TOKEN" vault write cubbyhole/private/access-token token="$WRAPPING_TOKEN"

# Put this token to deploy.yml that will be used when creating the Akashi deployment
sed -i "s/ONE_TIME_TOKEN/$ONETIME_TOKEN/" deploy.yml 
```

3. Update Docker image

```
################## NODE SIDE ##################
# Get wrapping token via one-time token
export VAULT_ADDR="https://vault-cluster.vault.[VAULT PUBLIC ADDRESS].aws.hashicorp.cloud:8200"
WRAPPING_TOKEN=`curl --header "X-Vault-Token: $ONETIME_TOKEN" \
    --header "X-Vault-Namespace: admin"  \
     $VAULT_ADDR/v1/cubbyhole/private/access-token | jq -r .data.token #| sed 's/"//g'`

# Unwrap the token
VAULT_TOKEN=`curl --header "X-Vault-Token: $WRAPPING_TOKEN" \
        --header "X-Vault-Namespace: admin" \
        --request POST \
        $VAULT_ADDR/v1/sys/wrapping/unwrap | jq -r .auth.client_token`

# Get the secret
curl --header "X-Vault-Token: $VAULT_TOKEN" \
        --header "X-Vault-Namespace: admin" \
        $VAULT_ADDR/v1/secret/data/dev | jq -r .data.data.private

```




## 5. Create Docker image and publish to repository

5.1 Review and update **Dockerfile** \[Update ENV section\].

5.2 Create new public DockerHub repo.

5.3 Build your image:

```
docker build -t [DockerHub account name]/[DockerHub repo name] . --no-cache
```

5.4 \[Optional\] Run your container in local Docker

```
docker run -p 3000:3000 [DockerHub account name]/[DockerHub repo name]:latest
```

5.5 Login to DockerHub with AccessKey and push your image

```
docker login --username [DockerHub account name]/[DockerHub repo name]
docker push [DockerHub account name]/[DockerHub repo name]:latest
```

## 6. Install Akash and create account

6.1 Use following guide to install Akash

https://docs.akash.network/start/install

6.2 Create new Akash account

Consider using following bash script (update **akash** binary path or update **PATH** env variable).

```
#!/bin/bash

AKASH_KEY_NAME="[YOUR KEY NAME HERE"
AKASH_KEYRING_BACKEND="os"

/opt/homebrew/bin/akash --keyring-backend "$AKASH_KEYRING_BACKEND" keys add "$AKASH_KEY_NAME"
```

\[IMPORTANT!!!\] Save your account address and mnemonic phrase.

Useful links:
https://docs.akash.network/start/wallet

## 7. Akash deployment instructions

Consider using following bash script. Properly update \[VARIABLE VALUES\]. Run commands one by one.
```
#!/bin/bash 

AKASH_NET="https://raw.githubusercontent.com/ovrclk/net/master/mainnet"
AKASH_VERSION="$(curl -s "$AKASH_NET/version.txt")"
export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")"
curl -s "$AKASH_NET/api-nodes.txt" 
AKASH_NODE="http://rpc.mainnet.akash.dual.systems:80"

AKASH_KEY_NAME="[AKASH ACCOUNT NAME]"
AKASH_KEYRING_BACKEND="os"
ACCOUNT_ADDRESS="[AKASH ACCOUNT ADDRESS]"

#STEP 0 - Create Certificate
#/opt/homebrew/bin/akash tx cert create client --chain-id $AKASH_CHAIN_ID --keyring-backend $AKASH_KEYRING_BACKEND --from $AKASH_KEY_NAME --node "http://rpc.mainnet.akash.dual.systems:80" --fees 5000uakt

#STEP 1 - Create deployment, get DSEQ into $DSEQ
#/opt/homebrew/bin/akash tx deployment create akash-sovryn-deploy.yml --from $AKASH_KEY_NAME --keyring-backend $AKASH_KEYRING_BACKEND --node "http://rpc.mainnet.akash.dual.systems:80" --chain-id $AKASH_CHAIN_ID -y --fees 5000uakt

#STEP 2 - Check BIDs
DSEQ=[DSEQ from previous STEP]
#/opt/homebrew/bin/akash query market bid list --owner=$ACCOUNT_ADDRESS --node $AKASH_NODE --dseq $DSEQ

#STEP 3 - Accept a bid by creating lease, get provider into $PROVIDER
DSEQ=[DSEQ from previous STEP]
GSEQ=[QSEQ from previous STEP]
OSEQ=[OSEQ from previous STEP]
PROVIDER="[PROVIDER from previous STEP]"
#/opt/homebrew/bin/akash tx market lease create --chain-id $AKASH_CHAIN_ID --node $AKASH_NODE --owner $ACCOUNT_ADDRESS --dseq $DSEQ --gseq $GSEQ --oseq $OSEQ --provider $PROVIDER --from $AKASH_KEY_NAME --fees 5000uakt --keyring-backend $AKASH_KEYRING_BACKEND

#STEP 4 - Check lease status
#/opt/homebrew/bin/akash query market lease list --owner $ACCOUNT_ADDRESS --node $AKASH_NODE --dseq $DSEQ

#STEP 5 - Upload our manifest, wait for spinup
#/opt/homebrew/bin/akash provider send-manifest akash-sovryn-deploy.yml --keyring-backend $AKASH_KEYRING_BACKEND --node $AKASH_NODE --from=$AKASH_KEY_NAME --provider=$PROVIDER --dseq $DSEQ --log_level=info --home ~/.akash

#STEP 6 - Check the lease status
#/opt/homebrew/bin/akash provider lease-status --node $AKASH_NODE --home ~/.akash --dseq $DSEQ --from $AKASH_KEY_NAME --provider $PROVIDER --keyring-backend $AKASH_KEYRING_BACKEND

#STEP 7 - Check logs
#/opt/homebrew/bin/akash provider lease-logs --dseq=$DSEQ --from=$ACCOUNT_ADDRESS --provider=$PROVIDER

#STEP 9 - Close deployment
#/opt/homebrew/bin/akash tx deployment close --node $AKASH_NODE --chain-id $AKASH_CHAIN_ID --dseq $DSEQ --owner $ACCOUNT_ADDRESS --from $AKASH_KEY_NAME --keyring-backend $AKASH_KEYRING_BACKEND -y --fees 5000uakt
```

## Troubleshooting

1. Consider test docker image, secrets and telegram chat in local Docker

2. Use Telegram chat to make sure that Sovryn Node is active

## To Be Done

### Security. Securing Akash deployment
### Security. Hardening Sovryn Node
