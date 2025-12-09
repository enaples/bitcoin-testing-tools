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
$([ -n "${PARENTGENESISBLOCKHASH}" ] && echo "con_has_parent_chain=1")
$([ -n "${PARENTGENESISBLOCKHASH}" ] && echo "parentgenesisblockhash=${PARENTGENESISBLOCKHASH}")

# Signet uses signed blocks. If you have a custom challenge, set it here.
# If using standard signet architecture, this script is required for validation.
$([ -n "${SIGNETCHALLENGE}" ] && echo "con_parent_chain_signblockscript=${SIGNETCHALLENGE}")

# Signet PoW limit
con_parentpowlimit=00000377ae000000000000000000000000000000000000000000000000000000

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

# Disable PAK enforcement
enforce_pak=${ENFORCE_PAK:-0}

# ===== ADDRESS PREFIXES =====
# Explicitly set these to override defaults, allowing us to use any chain name
bech32_hrp=${BECH32_HRP:-tex}
blech32_hrp=${BLECH32_HRP:-tlq}
pubkeyprefix=${PUBKEY_PREFIX:-36}
scriptprefix=${SCRIPT_PREFIX:-19}
blindedprefix=${BLINDED_PREFIX:-23}
secretprefix=${SECRET_PREFIX:-239}

# Parent chain prefixes (Bitcoin Signet)
parent_bech32_hrp=tb
parentpubkeyprefix=111
parentscriptprefix=196

# Network Ports
rpcport=${ELEMENTS_RPCPORT}
port=${ELEMENTS_PORT}

# Custom magic bytes
$([ -n "${MAGIC_NUMBER}" ] && echo "pchmessagestart=${MAGIC_NUMBER}")

# Block signing details
# $([ -n "${SIGNBLOCKSCRIPT}" ] && echo "signblockscript=${SIGNBLOCKSCRIPT}")
# $([ -n "${CON_MAX_BLOCK_SIG_SIZE}" ] && echo "con_max_block_sig_size=${CON_MAX_BLOCK_SIG_SIZE}")
EOF
