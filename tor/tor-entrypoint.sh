#!/bin/bash
set -Eeuo pipefail

# Give time for the other services to start
sleep 3

source /usr/local/bin/create-conf.sh

exec "$@"