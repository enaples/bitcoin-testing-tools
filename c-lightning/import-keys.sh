#!/bin/bash

# Import GPG signing keys based on architecture

# Get the machine architecture
ARCHITECTURE=$(uname -m)

KEYS_DIR="/tmp/lightning/contrib/keys"

case "$ARCHITECTURE" in
    x86_64)
        # keys.openpgp.org strips user IDs from most signer keys, so gpg refuses them.
        # Fetch only contrib/keys from the release tag instead of the whole repo.
        echo "Detected x86_64 architecture - fetching keys from the lightning repo..."
        git clone --depth=1 --branch v${CLN_VER} --filter=blob:none --sparse \
            https://github.com/ElementsProject/lightning.git /tmp/lightning
        git -C /tmp/lightning sparse-checkout set contrib/keys
        ;;

    aarch64|arm64)
        echo "Detected ARM architecture ($ARCHITECTURE) - importing keys from local files..."
        ;;

    *)
        echo "Error: Unsupported architecture '$ARCHITECTURE'"
        echo "Supported architectures: x86_64, aarch64, arm64"
        exit 1
        ;;
esac

# Check if the directory exists
if [ ! -d "$KEYS_DIR" ]; then
    echo "Error: Directory '$KEYS_DIR' not found."
    exit 1
fi

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

    # GPG import can return non-zero exit codes for warnings, so we capture the output
    if gpg --import "$key_file" 2>&1 | tee /tmp/gpg_output.txt | grep -qE "imported: [1-9]"; then
        ((SUCCESS_COUNT++))
        echo "✓ Successfully imported: $(basename "$key_file")"
    else
        # Check if key was already imported
        if grep -q "not changed" /tmp/gpg_output.txt; then
            ((SUCCESS_COUNT++))
            echo "✓ Already imported: $(basename "$key_file")"
        else
            ((FAIL_COUNT++))
            echo "✗ Failed to import: $(basename "$key_file")"
        fi
    fi
    echo "-----------------------------------"
done

# Summary
echo "Import complete!"
echo "Successfully imported: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"

echo "GPG key import process finished."
exit 0