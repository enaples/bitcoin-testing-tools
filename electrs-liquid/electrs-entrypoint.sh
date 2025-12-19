#!/bin/bash
set -Eeuo pipefail

source /usr/local/bin/wait-for-elementsd.sh

exec "$@"
