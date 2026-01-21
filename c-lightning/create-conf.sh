cat <<- EOF > "/lightningd/lightning.conf"
network=signet
bitcoin-rpcuser=bitcoin
bitcoin-rpcpassword=bitcoin
bitcoin-rpcconnect=$BTC_HOST
bitcoin-rpcport=38332
lightning-dir=/lightningd
rescan=0

clnrest-port=$CLNREST_PORT

developer
experimental-dual-fund
experimental-splicing
large-channels

ignore-fee-limits=true
log-level=debug
log-file=/lightningd/lightningd.log

# network
tor-service-password=bitcoin
proxy=tor:9050

bind-addr=$(hostname -f):$CLN_PORT
addr=statictor:tor:9051/torport=$CLN_PORT
EOF