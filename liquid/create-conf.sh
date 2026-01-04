cat <<- EOF > "/elementsd/elements.conf"
# Use a custom chain name to ensure we use CCustomParams logic
# avoiding hardcoded defaults in CLiquidTestNetParams
chain=${ELEMENTS_NETWORK}

# RPC Credentials
rpcuser=elements
rpcpassword=elements
daemon=1
server=1
listen=1
txindex=1

# Validate pegin: 1 = check against bitcoind, 0 = trust (for testing/genesis gen)
validatepegin=${VALIDATEPEGIN:-0}

# Parent chain RPC connection
mainchainrpcport=38332
mainchainrpchost=btc_sig_miner
mainchainrpcuser=bitcoin
mainchainrpcpassword=bitcoin

# ===== NETWORK SECTION =====
[${ELEMENTS_NETWORK}]
# ===== PARENT CHAIN CONFIGURATION =====
# Logic: If a parent genesis hash is provided, we enable parent chain mode
con_signed_blocks=${SIGNED_BLOCK:-1}
con_has_parent_chain=${PARENT_CHAIN:-1}
$([ -n "${PARENTGENESISBLOCKHASH}" ] && echo "parentgenesisblockhash=${PARENTGENESISBLOCKHASH}")

# Pegin confirmation depth
peginconfirmationdepth=${PEGIN_CONFIRMATION_DEPTH:-10}

# ===== ISSUANCE & ECONOMICS =====
initialfreecoins=${INITIALFREECOINS:-2100000000000000}
fallbackfee=0.0002
anyonecanspendaremine=1
acceptunlimitedissuances=1
acceptdiscountct=1
multi_data_permitted=1

# Fedpeg script - OP_TRUE for easy testing
fedpegscript=${FEDPEGSCRIPT:-51}

# ===== ADDRESS PREFIXES =====
# Explicitly set these to override defaults, allowing us to use any chain name
bech32_hrp=${BECH32_HRP:-tex}
blech32_hrp=${BLECH32_HRP:-tlq}
pubkeyprefix=${PUBKEY_PREFIX:-36}
scriptprefix=${SCRIPT_PREFIX:-19}
blindedprefix=${BLINDED_PREFIX:-23}
secretprefix=${SECRET_PREFIX:-239}

# Parent chain prefixes (Bitcoin Signet)
parent_bech32_hrp=${PARENT_BECH32_HRP:-tb}
parent_blech32_hrp=${PARENT_BLECH32_HRP:-tb}
parentpubkeyprefix=${PARENT_PUBKEY_PREFIX:-111}
parentscriptprefix=${PARENT_SCRIPT_PREFIX:-196}

# Network Ports
rpcport=${ELEMENTS_RPCPORT}
port=${ELEMENTS_PORT}
rpcbind=0.0.0.0:${ELEMENTS_RPCPORT}
rpcallowip=0.0.0.0/0
whitelist=0.0.0.0/0

# Custom magic bytes
$([ -n "${MAGIC_NUMBER}" ] && echo "pchmessagestart=${MAGIC_NUMBER}")

# Block signing details
$([ -n "${SIGNBLOCKSCRIPT}" ] && echo "signblockscript=${SIGNBLOCKSCRIPT}")
$([ -n "${CON_MAX_BLOCK_SIG_SIZE}" ] && echo "con_max_block_sig_size=${CON_MAX_BLOCK_SIG_SIZE}")
$([ -n "${EVBPARAMS}" ] && echo "evbparams=${EVBPARAMS}")
EOF
