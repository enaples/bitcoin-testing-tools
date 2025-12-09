#!/bin/bash
set -Eeuo pipefail

# Define mining constants
CLI="bitcoin-cli -datadir=/bitcoind -rpcwallet=$WALLET"
MINER="/data/contrib/signet/miner"
GRIND="bitcoin-util grind"
MINING_DESC=$(cli listdescriptors | jq -r ".descriptors | .[4].desc")

while echo "Start mining... ";
do
    CURRBLOCK=$(bitcoin-cli -datadir=/bitcoind getblockcount)
    echo "Current blockcount: ${CURRBLOCK}"
    if [ $CURRBLOCK -le 100 ]; then
        $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --min-nbits --descriptor=$MINING_DESC --max-blocks=101
    fi
    
    # BITS calibration after 100 blocks
    if [ -f "/bitcoind/nbits_calibration.txt" ]; then
        NBITS=`cat /bitcoind/nbits_calibration.txt`
    else
        echo "Waiting for difficulty calibration..."
        NBITS=`$MINER calibrate --grind-cmd="$GRIND" --seconds=$BLOCK_MINING_SEC | grep -oP 'nbits=\K[a-f0-9]+'`
        echo "The number of bits is: $NBITS"
        echo $NBITS > /bitcoind/nbits_calibration.txt
    fi
    
    if [ "$POISSON" = true ] ; then
        echo "Mining with Poisson distribution..."
        $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --nbits=$NBITS --descriptor=$MINING_DESC --poisson --ongoing
    else
        echo "Mining with fixed interval..."
        $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --nbits=$NBITS --descriptor=$MINING_DESC --ongoing
    fi
done

# If loop is interrupted, stop bitcoind
bitcoin-cli -datadir=/bitcoind stop


