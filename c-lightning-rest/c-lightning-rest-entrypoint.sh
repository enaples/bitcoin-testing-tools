#!/bin/bash
set -Eeuo pipefail

cat <<-EOF > "/c-lightning-REST/cl-rest-config.json"
{
    "PORT": $CLN_PORT,
    "DOCPORT": $CLN_DOCPORT,
    "PROTOCOL": "http",
    "EXECMODE": "test",
    "RPCCOMMANDS": ["*"],
    "DOMAIN": "localhost",
    "LNRPCPATH": "/lightningd/signet"
}
EOF

# Wait bitcoind and cln to be ready
source /c-lightning-REST/wait-for-bitcoind.sh

# copy macaroon in /lightningd if it does not exist
if [ ! -f "/lightningd/admin.macaroon" ]; then
    cp /c-lightning-REST/certs/access.macaroon /lightningd/access.macaroon
fi

exec "$@"
