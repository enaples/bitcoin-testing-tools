#!/bin/bash
set -Eeuo pipefail

echo Waiting for bitcoind to mine blocks...
until curl --silent --user $BTC_USER:$BTC_PASS --data-binary '{"jsonrpc": "1.0", "id": "electrs-blockstream", "method": "getblockchaininfo", "params": []}' -H 'content-type: text/plain;' http://$BTC_HOST:$BTC_PORT/ | jq -e ".result.blocks > 10" > /dev/null 2>&1
do
    echo -n "."
    sleep 1
done
