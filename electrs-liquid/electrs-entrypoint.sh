#!/bin/bash
set -Eeuo pipefail

source /usr/local/bin/wait-for-elementsd.sh

# CMD is passed in exec form, so Docker does not expand the ${VARS} in it.
# Expand each argument here (envsubst-style) before exec'ing electrs.
args=()
for arg in "$@"; do
    args+=("$(eval echo "$arg")")
done

exec "${args[@]}"
