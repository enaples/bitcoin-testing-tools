#!/usr/bin/env bash
set -e

# Wait for bitcoin to be ready
/usr/local/bin/wait-for-bitcoind.sh

# Create config file if it doesn't exist
if [ ! -f "/etc/tor/torrc" ]; then
    /usr/local/bin/create-conf.sh
fi

# Start daemon
elementsd -datadir=/elementsd

# Wait for log file to be created
while [ ! -f "/elementsd/${ELEMENTS_NETWORK}/debug.log" ]; do
    sleep 1
done

# Tail the log file
exec tail -f "/elementsd/${ELEMENTS_NETWORK}/debug.log"