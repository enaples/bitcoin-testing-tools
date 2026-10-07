#!/bin/bash
set -Eeuo pipefail

# Mining modes:
#   POISSON=true   random block intervals, 10 minutes on average (upstream signet miner)
#   POISSON=false  one block every BLOCK_MINING_SEC seconds. Signet retargets the
#                  difficulty every 2016 blocks towards 10 minutes, so shorter
#                  intervals only hold until the difficulty catches up.

CLI="bitcoin-cli -datadir=/bitcoind -rpcwallet=$WALLET"
MINER="/data/contrib/signet/miner"
GRIND="bitcoin-util grind"
BITCOIND_PIDFILE="/bitcoind/signet/bitcoind.pid"

# Block rewards go to the wallet's external taproot descriptor
MINING_DESC=$($CLI listdescriptors | jq -r '.descriptors[] | select(.internal == false and (.desc | startswith("tr("))) | .desc')

# Mine the first 101 blocks back-to-back so the first coinbase outputs are spendable
bootstrap() {
    local blocks
    blocks=$($CLI getblockcount)
    if [ "$blocks" -le 100 ]; then
        echo "Mining the first 101 blocks..."
        $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --min-nbits --descriptor="$MINING_DESC" --max-blocks=$((101 - blocks))
    fi
}

mine_poisson() {
    echo "Mining with Poisson distribution (10 minutes on average)..."
    $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --min-nbits --descriptor="$MINING_DESC" --poisson --ongoing
}

mine_fixed() {
    echo "Mining a block every ${BLOCK_MINING_SEC}s..."
    while true; do
        START=$(date +%s)
        # One block timestamped now (the miner requires a target even if it doesn't schedule here)
        $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --min-nbits --descriptor="$MINING_DESC" --set-block-time=-1 || \
            echo "Failed to mine a block, retrying in ${BLOCK_MINING_SEC}s"
        ELAPSED=$(( $(date +%s) - START ))
        if [ "$ELAPSED" -lt "$BLOCK_MINING_SEC" ]; then
            sleep $(( BLOCK_MINING_SEC - ELAPSED ))
        fi
    done
}

mine() {
    bootstrap
    if [ "$POISSON" = true ]; then
        mine_poisson
    else
        mine_fixed
    fi
}

# docker stop sends SIGTERM to PID 1: stop mining and shut bitcoind down cleanly
# before the container gets killed
shutdown() {
    trap - TERM INT
    kill "$MINER_PID" 2>/dev/null || true
    wait "$MINER_PID" 2>/dev/null || true
    # As PID 1 this script inherits the miner process left behind by the subshell
    # (bitcoind is a child too, so match the miner only)
    pkill -P $$ -f "$MINER" 2>/dev/null || true
    echo "Stopping bitcoind..."
    bitcoin-cli -datadir=/bitcoind stop > /dev/null || true
    while [ -f "$BITCOIND_PIDFILE" ] && kill -0 "$(cat "$BITCOIND_PIDFILE" 2>/dev/null)" 2>/dev/null; do
        sleep 0.5
    done
    echo "bitcoind stopped."
    exit "${1:-0}"
}
trap shutdown TERM INT

# Mine in the background: bash runs a trap only after the foreground command
# returns, while `wait` is interrupted by the signal straight away
mine &
MINER_PID=$!
STATUS=0
wait "$MINER_PID" || STATUS=$?
echo "Miner exited with status ${STATUS}"
shutdown "$STATUS"
