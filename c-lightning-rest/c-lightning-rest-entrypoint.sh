#!/bin/bash
set -Eeuo pipefail

cat <<-EOF >"/c-lightning-REST/cl-rest-config.json"
{
    "PORT": $CLN_REST_PORT,
    "DOCPORT": $CLN_REST_DOCPORT,
    "PROTOCOL": "http",
    "EXECMODE": "test",
    "RPCCOMMANDS": ["*"],
    "DOMAIN": "c-lightning-rest",
    "LNRPCPATH": "/lightningd/signet"
}
EOF

# Wait bitcoind and cln to be ready
source /c-lightning-REST/wait-for-bitcoind.sh

exec "$@"
