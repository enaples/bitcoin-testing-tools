cat <<- EOF > "/lightningd/lightning.conf"
network=signet
bitcoin-rpcuser=bitcoin
bitcoin-rpcpassword=bitcoin
bitcoin-rpcconnect=$BTC_HOST
bitcoin-rpcport=38332
lightning-dir=/lightningd
rescan=0
# Avoid fee estimation issues 
force-feerates=300/300/300/300

clnrest-port=$CLNREST_PORT
clnrest-host=0.0.0.0

developer
experimental-dual-fund
large-channels

ignore-fee-limits=true
log-level=debug
log-file=/lightningd/lightningd.log

# network
tor-service-password=bitcoin
proxy=tor:9050

bind-addr=$(hostname -f):$CLN_PORT
addr=statictor:tor:9051/torport=$CLN_PORT
database-upgrade=true

### LSP (LSPS2 / JIT channels)
experimental-lsps-client
experimental-lsps2-service
# 32 random bytes, generated once with the config: promises handed to
# clients must stay valid across restarts
experimental-lsps2-promise-secret=$(head -c 32 /dev/urandom | od -An -v -tx1 | tr -d ' \n')
# Opening fee menu the LSPS2 service offers (see lsps2_policy.py)
plugin=/usr/local/lib/cln-plugins/lsps2_policy.py
EOF