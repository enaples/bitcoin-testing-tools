cat <<- EOF > "/electrum/electrs.conf"
# Bitcoin Core settings
network = "signet"
daemon_dir = "/bitcoind"
daemon_rpc_addr = "$BTC_HOST:$BTC_RPC_PORT"
daemon_p2p_addr = "$BTC_HOST:$BTC_P2P_PORT"

# Electrs settings
electrum_rpc_addr = "0.0.0.0:60601"
db_dir = "/electrum/db"

# Logging
log_filters = "INFO"
timestamp = true
EOF