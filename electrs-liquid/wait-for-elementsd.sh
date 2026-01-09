#!/bin/bash
set -Eeuo pipefail

echo Waiting for liquid to mine blocks...
until curl --silent --user elements:elements --data-binary '{"jsonrpc": "1.0", "id": "electrs-liquid", "method": "getblockchaininfo", "params": []}' -H 'content-type: text/plain;' http://$EL_HOST:39884/ | jq -e ".result.blocks > 10" > /dev/null 2>&1
do
    echo -n "."
    sleep 1
done
