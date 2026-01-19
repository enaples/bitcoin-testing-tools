#!/bin/bash
set -Eeuo pipefail

# Create config file
/usr/local/bin/create-conf.sh

# Move conf to /lightningd
if [ -f "/data/lightning.config" ]; then
    mv /data/lightning.config /lightningd/lightning.config
    ln -s /lightningd /root/.lightning
    # If not is assumed that the config is already in /lightningd
fi


# Wait for bitcoind to be ready
usr/local/bin/wait-for-bitcoind.sh

echo Starting c-lightning...
lightningd --conf=/lightningd/lightning.conf --daemon

until lightning-cli --conf=/lightningd/lightning.conf getinfo >/dev/null 2>&1; do
    sleep 1
done
echo "Startup complete"
sleep 2

if [[ $(lightning-cli --conf=/lightningd/lightning.conf listfunds | jq -r ".outputs" | jq "length <= 0") == "true" ]]; then
    echo "Funding c-lightning wallet"
    source /usr/local/bin/fund-c-lightning.sh
else
    echo "c-lightning already funded."
fi

exec "$@"
