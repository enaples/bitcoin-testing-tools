#!/bin/sh
# Starts the Greenlight testserver with its nodes peering with the LSP.
#
# GL_TESTING_LSP (<node_id>@<host>:<port>) is used as is when set. Otherwise the
# node id is read from GL_LSP_NODE_ID_FILE, which cln writes on its volume (mounted
# here read-only) once it is up, and combined with GL_LSP_ADDR. A recreated cln
# with a new node id therefore needs no configuration change.
set -e

# The scheduler keeps its nodes in memory, so every start is a fresh server:
# drop the previous certificates instead of handing out stale ones.
rm -rf /data/gl-testserver /data/client.env

if [ -z "$GL_TESTING_LSP" ] && [ -n "$GL_LSP_NODE_ID_FILE" ]; then
    echo "Waiting for the LSP node id in $GL_LSP_NODE_ID_FILE"
    tries=0
    until [ -s "$GL_LSP_NODE_ID_FILE" ]; do
        tries=$((tries + 1))
        if [ "$tries" -ge 120 ]; then
            echo "LSP node id not found after 10 minutes, starting without one"
            break
        fi
        sleep 5
    done
    if [ -s "$GL_LSP_NODE_ID_FILE" ]; then
        export GL_TESTING_LSP="$(cat "$GL_LSP_NODE_ID_FILE")@$GL_LSP_ADDR"
    fi
fi

echo "LSP: ${GL_TESTING_LSP:-none}"
exec gltestserver run --directory /data "$@"
