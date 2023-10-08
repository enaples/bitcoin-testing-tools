#!/bin/bash
set -Eeuo pipefail

# Generate a new receiving address for c-lightning wallet
ADDR=$(lightning-cli --lightning-dir=/lightningd newaddr | jq '.bech32' -r)

# Bitcoin faucet .onion address
FAUCET_URL=localhost

if [[ $FAUCET_URL == *"onion"* ]]; then
    RESPONSE=`curl --silent --socks5-hostname localhost:9050 "${FAUCET_URL}:5050/faucet?address=${ADDR}"`
else
    RESPONSE=`curl --silent "${FAUCET_URL}:5000/faucet?address=${ADDR}"`
fi


if [[ $RESPONSE == *"Success"* ]]; then
    echo "Node funded! Wait for on-chain confirmation."
else
    echo "Failed to fund node: $RESPONSE"
fi
