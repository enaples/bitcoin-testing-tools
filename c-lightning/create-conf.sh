cat <<- EOF > "/lightningd/config"
network=signet
bitcoin-rpcuser=bitcoin
bitcoin-rpcpassword=bitcoin
bitcoin-rpcconnect=$BTC_HOST
bitcoin-rpcport=38332

# Newr version only
#clnrest-port=3010

log-level=debug
log-file=/lightningd/lightningd.log

# network
tor-service-password=bitcoin
proxy=tor:9050
bind-addr=0.0.0.0:$CL_PORT
addr=autotor:tor:9051/torport=$CL_PORT
EOF