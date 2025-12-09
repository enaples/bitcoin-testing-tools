#!/usr/bin/env bash
set -e

# Create config file
/usr/local/bin/create-conf.sh

# Wait for bitcoin to be ready
/usr/local/bin/wait-for-bitcoind.sh

# Start daemon
elementsd -datadir=/elementsd

# Wait for log file to be created
while [ ! -f "/elementsd/${ELEMENTS_NETWORK}/debug.log" ]; do
    sleep 1
done

# Tail the log file
exec tail -f "/elementsd/${ELEMENTS_NETWORK}/debug.log"