#!/bin/bash
set -Eeuo pipefail

# Generate a new receiving address for c-lightning wallet
ADDR=$(lightning-cli --conf=/lightningd/lightning.conf newaddr | jq '.p2tr' -r)

if [[ $FAUCET_URL == *"onion"* ]]; then
    RESPONSE=`curl --silent --socks5-hostname tor:9050 "http://${FAUCET_URL}:5050/faucet?address=${ADDR}"`
else
    RESPONSE=`curl --silent --insecure "http://${FAUCET_URL}:5000/faucet?address=${ADDR}"`
fi


if [[ $RESPONSE == *"Success"* ]]; then
    echo "Node funded! Wait for on-chain confirmation."
else
    echo "Failed to fund node: $RESPONSE"
fi
