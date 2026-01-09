#!/bin/bash

ADDR=`bitcoin-cli -datadir=/bitcoind getnewaddress`

RESPONSE=`curl --silent --socks5-hostname $TOR_HOST:9050 "${FAUCET_URL}:5050/faucet?address=${ADDR}"`

if [[ $RESPONSE == *"Success"* ]]; then
    echo "Node funded!"
else
    echo "Failed to fund node: $RESPONSE"
fi
