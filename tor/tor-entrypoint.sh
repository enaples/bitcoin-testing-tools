#!/bin/bash
set -Eeuo pipefail

source /usr/local/bin/wait-for-bitcoind.sh

source /usr/local/bin/create-conf.sh

exec "$@"