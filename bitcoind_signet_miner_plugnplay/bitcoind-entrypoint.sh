#!/bin/bash
set -Eeuo pipefail

# Move bitcoin.conf to /bitcoind
if [ -f "/data/bitcoin.conf" ]; then
    mv /data/bitcoin.conf /bitcoind/bitcoin.conf
    ln -s /bitcoind /root/.
    # If not is assumed that the bitcoin.conf is already in /bitcoind
fi

# Check if there is already the 'signetchallenge' option in 'bitcoin.conf' different from the default
# 'signetchallenge=00000000' added to not download any chain.
echo "===================================="
echo "Signetchallenge creation process"
while read -r line
do
    # Check line by line
    if [[ "$line" == *"signetchallenge=00000000"* ]]; then
        SIGNETCHALLENGE=false
        elif [[ "$line" == *"signetchallenge="* ]]; then
        echo "'signetchallenge' param already present in bitcoin.conf"
        echo "$line"
        SIGNETCHALLENGE=true
    fi
done < "/bitcoind/bitcoin.conf"

if [ $SIGNETCHALLENGE = false ]; then
    # Create a new signetchallenge
    # Start bitcoind
    echo "Starting bitcoind..."
    bitcoind -datadir=/bitcoind -daemon 2>&1 > /dev/null
    
    # Wait for bitcoind startup
    until bitcoin-cli -datadir=/bitcoind -rpcwait getblockchaininfo  > /dev/null 2>&1
    do
        echo -n "."
        sleep 1
    done
    echo "bitcoind started."
    echo "===================================="
    
    # Create a new wallet
    # Uncomment the following line if a custom wallet name is require and comment the `WALLET="wallet"` line.
    # read -p "Enter the name of the wallet: " WALLET
    WALLET="sig_miner_wallet"
    bitcoin-cli -datadir=/bitcoind -named createwallet wallet_name="$WALLET" descriptors=true 2>&1 > /dev/null
    
    # Get the signet script from the 86 descriptor
    ADDR=$(bitcoin-cli -datadir=/bitcoind getnewaddress)
    SCRIPT=$(bitcoin-cli -datadir=/bitcoind getaddressinfo $ADDR | jq -r ".scriptPubKey")
    sed -i "s/signetchallenge=00000000/signetchallenge=$SCRIPT/" /bitcoind/bitcoin.conf
    
    
    # Dumping descriptor wallet privatekey
    WALLETFILE="${WALLET}_privkey.txt"
    bitcoin-cli -datadir=/bitcoind listdescriptors true | jq -r ".descriptors | .[].desc" >> "/bitcoind/${WALLETFILE}"
    
    # Wait for bitcoind shutdown
    echo "Waiting for bitcoind to stop."
    bitcoin-cli -datadir=/bitcoind stop &
    wait
    echo "bitcoind stopped."
    # Removing any downloaded timechain
    rm -rf /bitcoind/signet/ &
    wait
fi

# Start bitcoind
echo "Restarting bitcoind..."
bitcoind -datadir=/bitcoind -daemon

# Wait for bitcoind startup
until bitcoin-cli -datadir=/bitcoind -rpcwait getblockchaininfo  > /dev/null 2>&1
do
    echo -n "."
    sleep 1
done
echo
echo "bitcoind started"

if [ $SIGNETCHALLENGE = false ] || [ ! -e /bitcoind/signet/wallets/$WALLET/wallet.dat ]; then
    # If there is any wallet, create a descriptor wallet
    bitcoin-cli -datadir=/bitcoind -named createwallet wallet_name="$WALLET" blank=true descriptors=true 2>&1 > /dev/null
    echo "================================================"
    echo "Importing descriptors for the private key:"
    line_count=0
    while read line; do
        # Increment the line counter
        line_count=$((line_count+1))
        
        # Check if the line count is even or odd
        if [ $((line_count % 2)) -eq 0 ]; then
            is_even="true"
        else
            is_even="false"
        fi
        
        
        DESCRIPTORS="
        {
            \"desc\": \"${line}\",
            \"timestamp\": 0,
            \"active\": true,
            \"internal\": ${is_even},
            \"range\": [
                0,
                999
            ]
        }"
        
        DESCRIPTORS="[${DESCRIPTORS//[$'\t\r\n ']}]"
        
        bitcoin-cli -datadir=/bitcoind importdescriptors "$DESCRIPTORS" 2>&1 > /dev/null
        
    done < "/bitcoind/${WALLETFILE}"
    echo "$(bitcoin-cli -datadir=/bitcoind listdescriptors)"
    echo "================================================"
else
    # If restarting, load the wallet that already exists, so don't fail if it does,
    # just load the existing wallet:
    echo "================================================"
    echo "Loading the main wallet:"
    WALLET="sig_miner_wallet"
    bitcoin-cli -datadir=/bitcoind loadwallet "$WALLET" 2>&1 >/dev/null
    echo "Bitcoin core wallet \"$WALLET\" loaded."
    echo "================================================"
fi

# Get the signet magic string from bitcoind debug logs


if [ -f "/bitcoind/sig_magic.txt" ]; then
    # If the file exists, check if the magic string is the same
    echo "Signet magic: $(cat /bitcoind/sig_magic.txt)"
else
    # If the file doesn't exist, create it
    SIG_MAGIC=`cat /bitcoind/signet/debug.log | grep -oP 'Signet derived magic \(message start\): \K[a-f0-9]+'`
    echo $SIG_MAGIC > /bitcoind/sig_magic.txt
fi

# Executing CMD
exec "$@"

