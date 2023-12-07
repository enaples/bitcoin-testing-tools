cat <<- EOF > "/lightningd/config"
network=signet
bitcoin-rpcuser=bitcoin
bitcoin-rpcpassword=bitcoin
bitcoin-rpcconnect=0.0.0.0
bitcoin-rpcport=38332

log-level=debug
log-file=/lightningd/lightningd.log
autocleaninvoice-cycle=86400
autocleaninvoice-expired-by=86400

# network
tor-service-password=bitcoin
proxy=127.0.0.1:9050
bind-addr=0.0.0.0:$CL_PORT
addr=statictor:127.0.0.1:9051/torport=$CL_PORT
EOF