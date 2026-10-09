#!/bin/bash
set -Eeuo pipefail

# Mining modes (upstream signet miner, minimum difficulty):
#   POISSON=true   random block intervals, 10 minutes on average
#   POISSON=false  one block every 10 minutes
# Faster blocks are not possible: signet retargets the difficulty every 2016
# blocks towards 10 minutes, and bitcoin-util grind would end up using every
# CPU core to keep up.

CLI="bitcoin-cli -datadir=/bitcoind -rpcwallet=$WALLET"
MINER="/data/contrib/signet/miner"
GRIND="bitcoin-util grind"
BITCOIND_PIDFILE="/bitcoind/signet/bitcoind.pid"

# Block rewards go to the wallet's external taproot descriptor
MINING_DESC=$($CLI listdescriptors | jq -r '.descriptors[] | select(.internal == false and (.desc | startswith("tr("))) | .desc')

# Fee rates (sat/vB) of the self-payments sent after every new block. Otherwise only coinbases get mined,
# estimatesmartfee has no data and Core Lightning refuses incoming channels
# ("feerates unknown").
# Set FEE_TX_RATES="" to disable.
# In the first 2 blocks after the first 101, you'll see a few "Insufficient funds" 
# failures, because only one coin is spendable yet.
FEE_TX_RATES=${FEE_TX_RATES-1 2 5}
FEE_TX_ADDR=""

send_fee_txs() {
    local rate
    if [ -z "$FEE_TX_ADDR" ]; then
        FEE_TX_ADDR=$($CLI getnewaddress) || return 0
    fi
    for rate in $FEE_TX_RATES; do
        # minconf=1: the estimator ignores transactions with unconfirmed parents
        $CLI -named send outputs="{\"$FEE_TX_ADDR\": 0.0001}" fee_rate="$rate" \
            options='{"minconf": 1}' > /dev/null || \
            echo "Failed to send a ${rate} sat/vB fee transaction"
    done
}

# Mine the first 101 blocks back-to-back so the first coinbase outputs are spendable
bootstrap() {
    local blocks
    blocks=$($CLI getblockcount)
    if [ "$blocks" -le 100 ]; then
        echo "Mining the first 101 blocks..."
        $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --min-nbits --descriptor="$MINING_DESC" --max-blocks=$((101 - blocks))
    fi
}

# The miner picks the block times, so check every 10s for a new
# block and send the fee transactions after it. Skipped until the first
# coinbase is spendable (block 101).
poll_fee_txs() {
    local height last_height=""
    while true; do
        height=$($CLI getblockcount 2>/dev/null) || height=""
        if [ -n "$height" ] && [ "$height" -gt 100 ] && [ "$height" != "$last_height" ]; then
            send_fee_txs
            last_height=$height
        fi
        sleep 10
    done
}

mine() {
    local poisson=()
    bootstrap
    if [ "$POISSON" = true ]; then
        echo "Mining with Poisson distribution (10 minutes on average)..."
        poisson=(--poisson)
    else
        echo "Mining a block every 10 minutes..."
    fi
    $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --min-nbits --descriptor="$MINING_DESC" "${poisson[@]}" --ongoing
}

# docker stop sends SIGTERM to PID 1: stop mining and shut bitcoind down cleanly
# before the container gets killed
shutdown() {
    trap - TERM INT
    if [ -n "${FEE_POLLER_PID:-}" ]; then
        kill "$FEE_POLLER_PID" 2>/dev/null || true
    fi
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
poll_fee_txs &
FEE_POLLER_PID=$!
STATUS=0
wait "$MINER_PID" || STATUS=$?
echo "Miner exited with status ${STATUS}"
shutdown "$STATUS"
