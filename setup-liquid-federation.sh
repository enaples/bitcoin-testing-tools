#!/bin/bash
set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

# Bitcoin signet configuration
BTC_CONTAINER="btc_sig_miner"
NETWORK_NAME="bitcoin-testing-tools_default"

# Liquid configuration
LIQUID_IMAGE="liquid:23.2.1"
NUM_NODES=5              # Total number of federation nodes
REQUIRED_SIGS=3          # M in M-of-N multisig
BASE_RPC_PORT=39884      # Starting RPC port
BASE_P2P_PORT=39886      # Starting P2P port
BLOCK_TIME=5            # Seconds between blocks

# Validation
if [ $REQUIRED_SIGS -gt $NUM_NODES ]; then
    echo "Error: REQUIRED_SIGS cannot be greater than NUM_NODES"
    exit 1
fi

# ============================================================================
echo "=== Liquid Federation Setup (Signed Blocks) ==="

# Step 1: Extract Bitcoin parameters
echo "Step 1: Extracting Bitcoin signet parameters..."
SIGNETCHALLENGE=$(docker exec $BTC_CONTAINER grep "signetchallenge=" /bitcoind/bitcoin.conf | cut -d'=' -f2)
GENESIS_HASH=$(docker exec $BTC_CONTAINER bitcoin-cli -conf=/bitcoind/bitcoin.conf -rpcuser=bitcoin -rpcpassword=bitcoin getblockhash 0)
MAGIC_NUMBER=$(docker exec $BTC_CONTAINER cat /bitcoind/sig_magic.txt)

if [ -z "$SIGNETCHALLENGE" ] || [ -z "$GENESIS_HASH" ] || [ -z "$MAGIC_NUMBER" ]; then
    echo "Error: Failed to extract Bitcoin parameters."
    exit 1
fi
echo "  Params extracted successfully."

# ============================================================================
# SETUP PHASE: Generate Keys & Config
# ============================================================================
echo ""
echo "Step 2: Starting temporary setup node to generate keys..."

TEMP_CONTAINER="liquid_setup"
TEMP_VOLUME="liquid_setup_vol"

# clean up previous runs
docker rm -f $TEMP_CONTAINER 2>/dev/null || true
docker volume rm -f $TEMP_VOLUME 2>/dev/null || true

# Start 1 node for setup
docker run -d --name $TEMP_CONTAINER \
    -v ${TEMP_VOLUME}:/elementsd \
    --network $NETWORK_NAME \
    -e ELEMENTS_NETWORK=liquidsignet \
    -e PARENTGENESISBLOCKHASH=$GENESIS_HASH \
    -e VALIDATEPEGIN=0 \
    -e MAGIC_NUMBER=$MAGIC_NUMBER \
    -e EVBPARAMS="dynafed:0:::" \
    $LIQUID_IMAGE > /dev/null

echo "  Waiting for setup node initialization..."
sleep 5

echo "Step 3: Generating $NUM_NODES key pairs..."
declare -a PUBKEYS
declare -a PRIVKEYS

for i in $(seq 1 $NUM_NODES); do
    WALLET_NAME="wallet_$i"
    
    # 1. Create a distinct wallet for each future node
    docker exec $TEMP_CONTAINER elements-cli -conf=/elementsd/elements.conf -named createwallet wallet_name=$WALLET_NAME > /dev/null
    
    # 2. Generate Address (Legacy for compatibility)
    ADDR=$(docker exec $TEMP_CONTAINER elements-cli -conf=/elementsd/elements.conf -rpcwallet=$WALLET_NAME getnewaddress "" legacy)
    
    # 3. Extract PubKey
    PUBKEY=$(docker exec $TEMP_CONTAINER elements-cli -conf=/elementsd/elements.conf -rpcwallet=$WALLET_NAME getaddressinfo $ADDR | jq -r '.pubkey')
    PUBKEYS[$i]=$PUBKEY
    
    # 4. Extract PrivKey
    PRIVKEYS[$i]=$(docker exec $TEMP_CONTAINER elements-cli -conf=/elementsd/elements.conf -rpcwallet=$WALLET_NAME dumpprivkey $ADDR)
    
    echo "  Keypair $i generated."
done

echo "Step 4: Constructing Multisig..."
# Build JSON array of pubkeys
PUBKEY_JSON="["
for i in $(seq 1 $NUM_NODES); do
    [ $i -gt 1 ] && PUBKEY_JSON="${PUBKEY_JSON},"
    PUBKEY_JSON="${PUBKEY_JSON}\"${PUBKEYS[$i]}\""
done
PUBKEY_JSON="${PUBKEY_JSON}]"

# Create Multisig (using the first wallet to run the command)
MULTISIG=$(docker exec $TEMP_CONTAINER elements-cli -conf=/elementsd/elements.conf -rpcwallet=wallet_1 createmultisig $REQUIRED_SIGS "$PUBKEY_JSON")
REDEEMSCRIPT=$(echo $MULTISIG | jq -r '.redeemScript')

echo "  Redeem Script: $REDEEMSCRIPT"

# Cleanup Setup Node
echo "  Cleaning up temporary setup node..."
docker rm -f $TEMP_CONTAINER > /dev/null
docker volume rm -f $TEMP_VOLUME > /dev/null

# ============================================================================
# LAUNCH PHASE: Start Federation
# ============================================================================
echo ""
echo "Step 5: Launching Federation ($NUM_NODES nodes)..."

for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    VOLUME_NAME="bitcoin-testing-tools_shared_vol_liquid$i"
    RPC_PORT=$((BASE_RPC_PORT + 1000 * (i - 1)))
    P2P_PORT=$((BASE_P2P_PORT + 1000 * (i - 1)))
    
    # Clean up
    docker rm -f $CONTAINER_NAME 2>/dev/null || true
    docker volume rm -f $VOLUME_NAME 2>/dev/null || true
    
    # Note: CON_MAX_BLOCK_SIG_SIZE set to 3000 to allow multisig
    docker run -d \
        --name $CONTAINER_NAME \
        -v ${VOLUME_NAME}:/elementsd \
        --network $NETWORK_NAME \
        -e ELEMENTS_NETWORK=liquidsignet \
        -e PARENTGENESISBLOCKHASH=$GENESIS_HASH \
        -e VALIDATEPEGIN=1 \
        -e SIGNETCHALLENGE=$SIGNETCHALLENGE \
        -e MAGIC_NUMBER=$MAGIC_NUMBER \
        -e ELEMENTS_RPCPORT=$RPC_PORT \
        -e ELEMENTS_PORT=$P2P_PORT \
        -e SIGNBLOCKSCRIPT=$REDEEMSCRIPT \
        -e PEGIN_CONFIRMATION_DEPTH=1 \
        -e FEDPEGSCRIPT=$REDEEMSCRIPT \
        -e CON_MAX_BLOCK_SIG_SIZE=3000 \
        -e EVBPARAMS="dynafed:0:::" \
        -p $RPC_PORT:$RPC_PORT \
        $LIQUID_IMAGE > /dev/null
        
    echo "  Started $CONTAINER_NAME (RPC: $RPC_PORT, P2P:$P2P_PORT)"
done

echo "  Waiting 10s for federation to stabilize..."
sleep 10

# ============================================================================
# PROVISIONING PHASE: Import Keys & Connect
# ============================================================================
echo ""
echo "Step 6: Importing unique keys into each node..."

for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    
    # Create default wallet
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf -named createwallet wallet_name=federated > /dev/null
    
    # Import ONLY this node's private key
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf importprivkey ${PRIVKEYS[$i]} > /dev/null
    
    echo "  Node $i ready."
done

echo ""
echo "Step 7: Interconnecting nodes..."
# Connect every node to node 1 to ensure P2P mesh
IP_NODE1=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' liquid1)

for i in $(seq 2 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf addnode "$IP_NODE1:$BASE_P2P_PORT" "onetry" > /dev/null
done
echo "  Nodes interconnected."

# ============================================================================
# CREATE MINING SCRIPT
# ============================================================================
echo ""
echo "Step 8: Creating mining script..."

cat > liquid_miner.sh << 'MINER_SCRIPT_EOF'
#!/bin/bash
set -e

# ============================================================================
# LIQUID BLOCK MINER
# This script is auto-generated by setup_liquid_federation.sh
# ============================================================================

# Configuration (injected during setup)
REDEEMSCRIPT="__REDEEMSCRIPT__"
REQUIRED_SIGS=__REQUIRED_SIGS__
NUM_NODES=__NUM_NODES__
BLOCK_TIME=__BLOCK_TIME__
BASE_P2P_PORT=__BASE_P2P_PORT__
LOG_FILE="liquid_miner_debug.log"

# Function to log both to screen and file
log() {
    echo "$@" | tee -a "$LOG_FILE"
}

# Make sure that main wallet is loaded
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    log "  Loading default wallet on $CONTAINER_NAME"
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf loadwallet federated 2>&1 >/dev/null || true
done

# Connect every node to node 1 to ensure P2P mesh
IP_NODE1=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' liquid1)

for i in $(seq 2 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf addnode "$IP_NODE1:$BASE_P2P_PORT" "onetry" > /dev/null
done
echo "  Nodes interconnected."

log "Give time to sync blocks..."
### TODO: use while to verify every node is on the same page in terms of best chain
sleep 5

# Rotate log file (only at script startup)
rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        ROTATED_LOG="liquid_miner_debug_${TIMESTAMP}.log"
        mv "$LOG_FILE" "$ROTATED_LOG"
        echo "Previous log rotated to: $ROTATED_LOG"
    fi
}

# ============================================================================
# STARTUP: Rotate old log
# ============================================================================

# Rotate the old log file if it exists
rotate_log

# ============================================================================
# MAIN MINING LOOP
# ============================================================================

log "=== Liquid Block Miner Started ==="
log "Time: $(date)"
log "Redeem Script: $REDEEMSCRIPT"
log "Required Signatures: $REQUIRED_SIGS"
log "Total Nodes: $NUM_NODES"
log "Block Time: ${BLOCK_TIME}s"
log ""

while true; do
    
    log "-----------------------------------"
    log "Mining Tick: $(date)"

    # Select random nodes for this block
    SELECTED_NODES=($(shuf -i 1-$NUM_NODES -n $REQUIRED_SIGS))
    log "Selected nodes for signing: ${SELECTED_NODES[*]}"
    
    # 1. Propose Block
    log "Step 1: Requesting new block template from liquid1..."
    PROPOSAL_HEX=$(docker exec liquid1 elements-cli -conf=/elementsd/elements.conf getnewblockhex 2>&1)
    
    if [ -z "$PROPOSAL_HEX" ] || echo "$PROPOSAL_HEX" | grep -q "error"; then
        log "ERROR: getnewblockhex failed or returned empty"
        log "Response: $PROPOSAL_HEX"
        sleep 5
        continue
    fi
    log "  Block template received: ${PROPOSAL_HEX}"
    
    # 2. Collect Signatures
    log "Step 2: Collecting $REQUIRED_SIGS signatures..."
    SIGS_ARRAY="["
    
    for idx in "${!SELECTED_NODES[@]}"; do
        NODE_NUM=${SELECTED_NODES[$idx]}
        CONTAINER_NAME="liquid$NODE_NUM"
        log "  Requesting signature from $CONTAINER_NAME..."
        
        SIG_RES=$(docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf signblock "$PROPOSAL_HEX" "$REDEEMSCRIPT" 2>&1 | jq -c '.[0]' 2>&1)
        
        if [ $? -ne 0 ] || [ -z "$SIG_RES" ]; then
            log "  ERROR: Failed to get signature from $CONTAINER_NAME"
            log "  Response: $SIG_RES"
            sleep 5
            continue 2
        fi
        
        if [ $idx -gt 0 ]; then
            SIGS_ARRAY="${SIGS_ARRAY},"
        fi
        SIGS_ARRAY="${SIGS_ARRAY}${SIG_RES}"
        log "  ✓ Signature from node $NODE_NUM collected"
    done
    SIGS_ARRAY="${SIGS_ARRAY}]"
    
    log "Step 3: Combining signatures..."
    log "  Signatures array: ${SIGS_ARRAY}" # Show first 100 chars
    
    # 3. Combine Signatures
    COMBINED_RES=$(docker exec liquid1 elements-cli -conf=/elementsd/elements.conf combineblocksigs "$PROPOSAL_HEX" "$SIGS_ARRAY" "$REDEEMSCRIPT" 2>&1)
    
    if [ $? -ne 0 ]; then
        log "ERROR: combineblocksigs failed"
        log "Response: $COMBINED_RES"
        sleep 5
        continue
    fi
    
    SIGNED_BLOCK_HEX=$(echo "$COMBINED_RES" | jq -r '.hex' 2>&1)
    IS_COMPLETE=$(echo "$COMBINED_RES" | jq -r '.complete' 2>&1)
    
    if [ "$IS_COMPLETE" != "true" ]; then
        log "ERROR: Block signature not complete"
        log "Combined response: $COMBINED_RES"
        sleep 5
        continue
    fi
    log "  ✓ Block fully signed"
    
    # 4. Submit Block
    log "Step 4: Submitting block to network..."
    SUBMIT_RES=$(docker exec liquid1 elements-cli -conf=/elementsd/elements.conf submitblock "$SIGNED_BLOCK_HEX" 2>&1)
    
    if [ -z "$SUBMIT_RES" ]; then
        log "  ✓ Block accepted by network"
        
        # Get current block height for confirmation
        BLOCK_HEIGHT=$(docker exec liquid1 elements-cli -conf=/elementsd/elements.conf getblockcount 2>&1)
        log "  Current block height: $BLOCK_HEIGHT"
    else
        log "  WARNING: submitblock returned: $SUBMIT_RES"
    fi
    
    log ""
    log "Waiting ${BLOCK_TIME}s until next block..."
    sleep $BLOCK_TIME
done
MINER_SCRIPT_EOF

# Replace placeholders with actual values
# Use sed in a cross-platform way (works on both Linux and macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS requires empty string after -i
    sed -i '' "s|__REDEEMSCRIPT__|$REDEEMSCRIPT|g" liquid_miner.sh
    sed -i '' "s|__REQUIRED_SIGS__|$REQUIRED_SIGS|g" liquid_miner.sh
    sed -i '' "s|__NUM_NODES__|$NUM_NODES|g" liquid_miner.sh
    sed -i '' "s|__BLOCK_TIME__|$BLOCK_TIME|g" liquid_miner.sh
    sed -i '' "s|__BASE_P2P_PORT__|$BASE_P2P_PORT|g" liquid_miner.sh
else
    # Linux sed
    sed -i "s|__REDEEMSCRIPT__|$REDEEMSCRIPT|g" liquid_miner.sh
    sed -i "s|__REQUIRED_SIGS__|$REQUIRED_SIGS|g" liquid_miner.sh
    sed -i "s|__NUM_NODES__|$NUM_NODES|g" liquid_miner.sh
    sed -i "s|__BLOCK_TIME__|$BLOCK_TIME|g" liquid_miner.sh
    sed -i "s|__BASE_P2P_PORT__|$BASE_P2P_PORT|g" liquid_miner.sh
fi

# Make the script executable
chmod +x liquid_miner.sh

echo "  Mining script created: liquid_miner.sh"
echo ""
echo "=== Setup Complete ==="
echo ""
echo "To start mining, run:"
echo "  ./liquid_miner.sh"
echo ""
echo "To run in background:"
echo "  nohup ./liquid_miner.sh &"
echo ""
echo "To monitor logs:"
echo "  tail -f liquid_miner_debug.log"