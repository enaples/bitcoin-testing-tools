#!/bin/bash
set -Eeuo pipefail

# Create config file
source /usr/local/bin/create-conf.sh

# Move conf to /lightningd
if [ -f "/data/config" ]; then
    mv /data/config /lightningd/config
    ln -s /lightningd /root/.lightning
    # If not is assumed that the config is already in /lightningd
fi


# Wait for bitcoind to be ready
source /usr/local/bin/wait-for-bitcoind.sh

echo Starting c-lightning...
lightningd --lightning-dir=/lightningd --daemon

until lightning-cli --lightning-dir=/lightningd getinfo >/dev/null 2>&1; do
    sleep 1
done
echo "Startup complete"
sleep 2

if [[ $(lightning-cli --lightning-dir=/lightningd listfunds | jq -r ".outputs" | jq "length <= 0") == "true" ]]; then
    echo "Funding c-lightning wallet"
    source /usr/local/bin/fund-c-lightning.sh
else
    echo "c-lightning already funded."
fi

exec "$@"
