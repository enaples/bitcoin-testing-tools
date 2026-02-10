#!/bin/bash
set -Eeuo pipefail

# Sync system clock to prevent Tor clock-skew issues (common with Docker Desktop on macOS)
ntpdate -s pool.ntp.org || echo "Warning: NTP sync failed, continuing with current clock"

/usr/local/bin/wait-for-bitcoind.sh
/usr/local/bin/create-conf.sh

# Add hidden services (skips automatically if host is unreachable or already configured)
add_hidden nginx hidden_service_electrs_romanz 60602 60602
add_hidden nginx hidden_service_electrs_blockstream 60502 60502
add_hidden cln hidden_service_cl_rest 8080 3010
add_hidden faucet hidden_service_faucet 5050 5000

exec "$@"