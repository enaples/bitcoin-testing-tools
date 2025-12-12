#!/bin/bash
set -e

# ============================================================================
# CONFIGURATION - Customize these variables
# ============================================================================

# Bitcoin signet configuration
BTC_CONTAINER="btc_sig_miner"
NETWORK_NAME="bitcoin-testing-tools_default"

# Liquid configuration
LIQUID_IMAGE="liquid:23.3.1"
NUM_NODES=5              # Total number of federation nodes
REQUIRED_SIGS=3          # Number of signatures required (M in M-of-N multisig)
BASE_RPC_PORT=39884      # Starting RPC port (each node gets sequential port)
BASE_P2P_PORT=39886      # Starting P2P port (each node gets sequential port)

# Validation
if [ $REQUIRED_SIGS -gt $NUM_NODES ]; then
    echo "Error: REQUIRED_SIGS ($REQUIRED_SIGS) cannot be greater than NUM_NODES ($NUM_NODES)"
    exit 1
fi

if [ $REQUIRED_SIGS -lt 1 ]; then
    echo "Error: REQUIRED_SIGS must be at least 1"
    exit 1
fi

# ============================================================================

echo "=== Liquid Federation Setup for Bitcoin Custom Signet ==="
echo ""
echo "Configuration:"
echo "  - Federation nodes: $NUM_NODES"
echo "  - Required signatures: $REQUIRED_SIGS (${REQUIRED_SIGS}-of-${NUM_NODES} multisig)"
echo "  - Base RPC port: $BASE_RPC_PORT"
echo "  - Base P2P port: $BASE_P2P_PORT"
echo ""

# Step 1: Extract Bitcoin signet parameters
echo "Step 1: Extracting Bitcoin signet parameters..."

# Get signetchallenge from bitcoin.conf
SIGNETCHALLENGE=$(docker exec $BTC_CONTAINER grep "signetchallenge=" /bitcoind/bitcoin.conf | cut -d'=' -f2)
if [ -z "$SIGNETCHALLENGE" ]; then
    echo "Error: Could not retrieve signetchallenge from bitcoin.conf"
    exit 1
fi
echo "  SIGNETCHALLENGE: $SIGNETCHALLENGE"

# Get genesis block hash
GENESIS_HASH=$(docker exec $BTC_CONTAINER bitcoin-cli -conf=/bitcoind/bitcoin.conf -rpcuser=bitcoin -rpcpassword=bitcoin getblockhash 0)
if [ -z "$GENESIS_HASH" ]; then
    echo "Error: Could not retrieve genesis block hash"
    exit 1
fi
echo "  GENESIS_HASH: $GENESIS_HASH"

# Get magic number
MAGIC_NUMBER=$(docker exec $BTC_CONTAINER cat /bitcoind/sig_magic.txt)
if [ -z "$MAGIC_NUMBER" ]; then
    echo "Error: Could not retrieve magic number"
    exit 1
fi
echo "  MAGIC_NUMBER: $MAGIC_NUMBER"
echo ""

# Step 2: Launch 5 Liquid nodes
echo "Step 2: Launching 5 Liquid nodes..."
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    VOLUME_NAME="bitcoin-testing-tools_shared_vol_liquid$i"
    RPC_PORT=$((BASE_RPC_PORT + i + 1000 * (i - 1)))
    P2P_PORT=$((BASE_P2P_PORT + i + 1000 * (i - 1)))
    
    echo "  Starting $CONTAINER_NAME (RPC: $RPC_PORT, P2P: $P2P_PORT)..."
    
    # Remove container if it exists
    docker rm -f $CONTAINER_NAME 2>/dev/null || true

    # Remvoe volume if it exists
    docker volume rm -f $VOLUME_NAME
    
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
        -e CON_MAX_BLOCK_SIG_SIZE=2 \
        -e EVBPARAMS="dynafed:0:::" \
        $LIQUID_IMAGE
    
    sleep 2
done
echo "  All nodes started. Waiting 10 seconds for initialization..."
sleep 10
echo ""

# Step 3: Create wallets and collect pubkeys
echo "Step 3: Creating wallets and collecting pubkeys..."
declare -a PUBKEYS
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    
    # Wallet must be legacy otherwise the signblock RPC won't work
    echo "  Creating wallet on $CONTAINER_NAME..."
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf createwallet federated
    
    echo "  Generating address and extracting pubkey..."
    ADDR=$(docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf getnewaddress)
    VALID=$(docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf getaddressinfo $ADDR)
    PUBKEY=$(echo $VALID | jq -r '.pubkey')
    PUBKEYS[$i]=$PUBKEY
    
    echo "    Node $i pubkey: $PUBKEY"
done
echo ""

# Step 4: Dump private keys
echo "Step 4: Saving private keys..."
declare -a PRIVKEYS
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    echo "  Dumping privkey from $CONTAINER_NAME..."
    ADDR=$(docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf getnewaddress)
    PRIVKEYS[$i]=$(docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf dumpprivkey $ADDR)
    echo "  ${PRIVKEYS[$i]}"
done
echo ""

# Step 5: Create multisig
echo "Step 5: Creating ${REQUIRED_SIGS}-of-${NUM_NODES} multisig..."

# Build JSON array of pubkeys
PUBKEY_JSON="["
for i in $(seq 1 $NUM_NODES); do
    if [ $i -eq 1 ]; then
        PUBKEY_JSON="${PUBKEY_JSON}\"${PUBKEYS[$i]}\""
    else
        PUBKEY_JSON="${PUBKEY_JSON}, \"${PUBKEYS[$i]}\""
    fi
done
PUBKEY_JSON="${PUBKEY_JSON}]"

echo "  Creating multisig with pubkeys: $PUBKEY_JSON"
MULTISIG=$(docker exec liquid1 elements-cli -conf=/elementsd/elements.conf createmultisig $REQUIRED_SIGS "$PUBKEY_JSON")
echo ""
REDEEMSCRIPT=$(echo $MULTISIG | jq -r '.redeemScript')

if [ -z "$REDEEMSCRIPT" ]; then
    echo "Error: Could not create multisig redeemScript"
    exit 1
fi
echo "  REDEEMSCRIPT: $REDEEMSCRIPT"
echo ""

# Step 6: Dump and create again containers with the new config
echo "Step 6: Dumping containers and run them with new config..."
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    echo "  Stopping $CONTAINER_NAME..."
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf stop || true
    sleep 2
done
sleep 5
echo ""

# Step 7: Wipe data directories
echo "Step 7: Wiping data directories..."
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    echo "  Wiping data on $CONTAINER_NAME..."
    docker exec $CONTAINER_NAME rm -rf /elementsd/liquidsignet
done
echo ""

# Step 8: Update configuration files
echo "Step 8: Updating elements.conf with signblockscript..."
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    echo "  Updating config on $CONTAINER_NAME..."
    docker exec $CONTAINER_NAME sh -c "echo 'signblockscript=$REDEEMSCRIPT' >> /elementsd/elements.conf"
    docker exec $CONTAINER_NAME sh -c "echo 'con_max_block_sig_size=2' >> /elementsd/elements.conf"
    docker exec $CONTAINER_NAME sh -c "echo 'evbparams=dynafed:0:::' >> /elementsd/elements.conf"
done
echo ""

# Step 9: Restart containers
echo "Step 9: Restart containers..."
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    echo "  Restarting container $CONTAINER_NAME..."
    docker restart $CONTAINER_NAME
    sleep 2
done
echo ""

# Step 7: Import keys
echo "Step 7: Importing keys on each node..."
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    echo "  Creating blank wallet on $CONTAINER_NAME..."
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf -named createwallet wallet_name=federated
    
    echo "  Importing privatekey on $CONTAINER_NAME..."
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf importprivkey ${PRIVKEYS[$i]}
    
done
echo ""

# Step 8: Rescan blockchain
echo "Step 8: Rescanning blockchain on each node..."
for i in $(seq 1 $NUM_NODES); do
    CONTAINER_NAME="liquid$i"
    echo "  Rescanning on $CONTAINER_NAME..."
    docker exec $CONTAINER_NAME elements-cli -conf=/elementsd/elements.conf rescanblockchain
done
echo ""

echo "=== Setup Complete ==="
echo ""
echo "Your Liquid federation is now configured with:"
echo "  - $NUM_NODES Liquid nodes (liquid1 through liquid${NUM_NODES})"
echo "  - ${REQUIRED_SIGS}-of-${NUM_NODES} multisig for block signing"
echo "  - Connected to Bitcoin signet: $GENESIS_HASH"
echo ""
echo "Node RPC ports:"
for i in $(seq 1 $NUM_NODES); do
    RPC_PORT=$((BASE_RPC_PORT + i + 1000 * (i - 1)))
    echo "  - liquid$i: $RPC_PORT"
done
echo ""
echo "To check node status, run:"
echo "  docker exec liquid1 elements-cli -conf=/elementsd/elements.conf getblockchaininfo"
echo ""
echo "To generate blocks (requires $REQUIRED_SIGS nodes to sign):"
echo "  docker exec liquid1 elements-cli -conf=/elementsd/elements.conf generatetoaddress 1 <address>"