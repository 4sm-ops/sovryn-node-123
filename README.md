# Sovryn Node deployment guide

## 1. Prepare new repo

1.1 Create new repo, copy files from https://github.com/DistributedCollective/Sovryn-Node

## 2. Telegram bot and chat configuration

Sovryn node uses Telegram chat/bot to send notifications about new transactions and errors.

2.1 Use @BotFather default Telegram bot to create new bot (/newbot command).

![Create Telegram Bot!](/images/telegram01.png "Create Telegram Bot")

2.2 Get API token.

![Get API token!](/images/telegram02.png "Get API token")

2.3 Create new chat and add created telegram bot. Send some messages to newly created chat.

2.4 Use following URL to get Chat ID starting with ("-") symbol: https://api.telegram.org/bot[токен_бота]/getUpdates

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

https://wiki.sovryn.app/en/getting-started/wallet-setup

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

## 4. Convert keys to Keystore v3 format

Update **accounts.js** file with the credentials of the liquidator/rollover/arbitrage wallets.
You have 2 options
* \[Insecure\] you can specify pKey instead of ks to just use the private key
* \[Secure\] ks = encrypted keystore file in v3 standard. (Do not forget to save your keystore password!)

```
export default {
    "liquidator": [{
        adr: "",
        ks: ""
    }],
    "rollover": [{
        adr: "",
        ks: ""
    }],
    "arbitrage": [{
        adr: "",
        ks: ""
    }],
}
```

## 5. Create Docker image and publish to repository

## 6. Create Akash account

## 7. Akash deployment instructions

## Security. Hardening Sovryn Node

## Security. Securing private keys

## Security. Securing Akash deployment

## Troubleshooting



