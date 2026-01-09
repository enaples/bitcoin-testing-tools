#!/bin/bash
set -Eeuo pipefail

# Wait for bitcoin to be sync
/usr/local/bin/wait-for-bitcoind.sh

# Create nginx conf
/usr/local/bin/create-conf.sh

exec "$@"