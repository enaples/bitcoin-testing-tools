#!/bin/bash
set -Eeuo pipefail

source /usr/local/bin/create-conf.sh

exec "$@"