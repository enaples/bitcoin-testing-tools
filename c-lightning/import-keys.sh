#!/bin/bash
set -Eeuo pipefail

# Import the GPG keys of the CLN developers from contrib/keys of the release tag

KEYS_REPO="/tmp/cln-keys"
KEYS_DIR="${KEYS_REPO}/contrib/keys"

# keys.openpgp.org strips user IDs from most signer keys, so gpg refuses them.
# Fetch only contrib/keys from the release tag instead of the whole repo.
echo "Fetching keys from the lightning repo (v${CLN_VER})..."
git clone --depth=1 --branch v${CLN_VER} --filter=blob:none --sparse \
    https://github.com/ElementsProject/lightning.git ${KEYS_REPO}
git -C ${KEYS_REPO} sparse-checkout set contrib/keys

# Check if there are any .txt files in the directory
shopt -s nullglob dotglob
KEY_FILES=("$KEYS_DIR"/*.txt)
shopt -u nullglob dotglob

if [ ${#KEY_FILES[@]} -eq 0 ]; then
    echo "No .txt files found in '$KEYS_DIR'."
    exit 1
fi

echo "Found ${#KEY_FILES[@]} key file(s) to import."
echo "-----------------------------------"

# Import each key file
SUCCESS_COUNT=0
FAIL_COUNT=0

for key_file in "${KEY_FILES[@]}"; do
    echo "Importing: $(basename "$key_file")"

    # GPG import can return non-zero exit codes for warnings, so we only look at the output
    GPG_OUTPUT=$(gpg --import "$key_file" 2>&1 || true)
    if grep -qE "imported: [1-9]" <<< "$GPG_OUTPUT"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "✓ Successfully imported: $(basename "$key_file")"
    elif grep -q "not changed" <<< "$GPG_OUTPUT"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "✓ Already imported: $(basename "$key_file")"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "✗ Failed to import: $(basename "$key_file")"
    fi
    echo "-----------------------------------"
done

# Summary
echo "Import complete!"
echo "Successfully imported: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"
