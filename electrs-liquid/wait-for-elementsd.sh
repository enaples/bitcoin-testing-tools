#!/bin/bash
set -Eeuo pipefail

echo Waiting for liquid to mine blocks...
until curl --silent --user $ELM_USER:$ELM_PASS --data-binary '{"jsonrpc": "1.0", "id": "electrs-liquid", "method": "getblockchaininfo", "params": []}' -H 'content-type: text/plain;' http://$ELM_HOST:$ELM_PORT/ | jq -e ".result.blocks > 10" > /dev/null 2>&1
do
    echo -n "."
    sleep 1
done
