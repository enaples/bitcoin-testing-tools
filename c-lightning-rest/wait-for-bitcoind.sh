#!/bin/bash
set -Eeuo pipefail

# Wait 110 in orde to make sure bitcoind
# and cln are running
echo Waiting for bitcoind to mine blocks...
until curl --silent --user bitcoin:bitcoin --data-binary '{"jsonrpc": "1.0", "id": "cln-rest", "method": "getblockchaininfo", "params": []}' -H 'content-type: text/plain;' http://${BTC_HOST}:38332/ | jq -e ".result.blocks > 103" >/dev/null 2>&1; do
    echo -n "."
    sleep 1
done
