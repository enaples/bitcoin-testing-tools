#!/bin/bash
set -Eeuo pipefail

/usr/local/bin/create-conf.sh

exec "$@"