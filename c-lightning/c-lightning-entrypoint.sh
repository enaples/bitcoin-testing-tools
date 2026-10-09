#!/bin/bash
set -Eeuo pipefail

# Create config file if it doesn't exist
if [ ! -f "/lightningd/lightning.conf" ]; then
    /usr/local/bin/create-conf.sh
fi

# Wait for bitcoind to be ready
usr/local/bin/wait-for-bitcoind.sh

# Dropped until lightningd answers again, so readers never get a stale id
rm -f /lightningd/node_id

echo Starting c-lightning...
lightningd --conf=/lightningd/lightning.conf --daemon

until lightning-cli --conf=/lightningd/lightning.conf getinfo >/dev/null 2>&1; do
    sleep 1
done
echo "Startup complete"

# Published for the other services on this volume (gl-testserver peers with it).
# Written then renamed, so a reader never sees a partial id.
lightning-cli --conf=/lightningd/lightning.conf getinfo | jq -r .id > /lightningd/node_id.tmp
mv /lightningd/node_id.tmp /lightningd/node_id
sleep 2

if [[ $(lightning-cli --conf=/lightningd/lightning.conf listfunds | jq -r ".outputs" | jq "length <= 0") == "true" ]]; then
    echo "Funding c-lightning wallet"
    source /usr/local/bin/fund-c-lightning.sh
else
    echo "c-lightning already funded."
fi

exec "$@"
