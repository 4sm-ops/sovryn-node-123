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

## 4. Convert keys to Keystore v3 format

## 5. Create Docker image and publish to repository

## 6. Create Akash account

## 7. Akash deployment instructions

## Security. Hardening Sovryn Node

## Security. Securing private keys

## Security. Securing Akash deployment

## Troubleshooting



