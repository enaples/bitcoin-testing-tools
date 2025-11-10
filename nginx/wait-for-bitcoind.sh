#!/bin/bash
set -Eeuo pipefail

echo Waiting for bitcoind to mine blocks...
until curl --silent --user bitcoin:bitcoin --data-binary '{"jsonrpc": "1.0", "id": "nginx", "method": "getblockchaininfo", "params": []}' -H 'content-type: text/plain;' http://btc_sig_miner:38332/ | jq -e ".result.blocks > 11" > /dev/null 2>&1
do
    echo -n "."
    sleep 1
done
echo Bitcoind started!
