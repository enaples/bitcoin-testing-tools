#!/bin/bash
set -Eeuo pipefail

# Wait for bitcoin to be sync
/usr/local/bin/wait-for-bitcoind.sh

# Create config file if it doesn't exist
if [ ! -f "/etc/tor/torrc" ]; then
    /usr/local/bin/create-conf.sh
fi

exec "$@"