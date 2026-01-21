#!/bin/bash
set -Eeuo pipefail

# Create config file if it doesn't exist
if [ ! -f "/etc/tor/torrc" ]; then
    /usr/local/bin/create-conf.sh
fi

exec "$@"