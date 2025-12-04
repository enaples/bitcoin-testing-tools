#!/bin/bash

# Import GPG signing keys based on architecture

set -e  # Exit on error

# Get the machine architecture
ARCHITECTURE=$(uname -m)

case "$ARCHITECTURE" in
    x86_64)
        echo "Detected x86_64 architecture - importing keys from keyserver..."
        
        # Ref. https://docs.corelightning.org/docs/security-policy
        KEYS=(
            "1176 542D A98E 71E1 3372 2EF7 4AC8 CC88 6844 A2D6"  # Blockstream Security Reporting
            "15EE 8D6C AB0E 7F0C F999 BFCB D920 0E6C D1AD B8F1"  # Rusty Russell
            "B731 AAC5 21B0 1385 9313 F674 A26D 6D9F E088 ED58"  # Christian Decker
            "30DE 693A E0DE 9E37 B3E7 EB6B BFF0 F678 10C1 EED1"  # Lisa Neigut
            "0437 4E42 789B BBA9 462E 4767 F3BF 63F2 7474 36AB"  # Alex Myers
            "653B 19F3 3DF7 EFF3 E9D1 C94C C3F2 1EE3 87FF 4CD2"  # Peter Neuroth
            "0CCA 8183 C13A 2389 A9C5 FD29 BFB0 1536 0049 CB56"  # Shahana Farooqui
            "7169 D262 72B5 0A3F 531A A1C2 A57A FC23 1B58 0804"  # Madeline Peach
            "616C 52F9 9D06 12B2 A151 B107 4129 A994 AA7E 9852"  # Blockstream CLN Release
        )
        
        for key in "${KEYS[@]}"; do
            echo "Importing key: $key"
            gpg --keyserver hkps://keys.openpgp.org --recv-keys "$key" || echo "Warning: Failed to import $key"
        done
        ;;
        
    aarch64|arm64)
        echo "Detected ARM architecture ($ARCHITECTURE) - importing keys from local files..."
        
        KEYS_DIR="/tmp/lightning/contrib/keys"
        
        # Check if the directory exists
        if [ ! -d "$KEYS_DIR" ]; then
            echo "Error: Directory '$KEYS_DIR' not found."
            exit 1
        fi
        
        # Check if there are any .txt files in the directory
        shopt -s nullglob
        KEY_FILES=("$KEYS_DIR"/*.txt)
        shopt -u nullglob
        
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
            
            if gpg --import "$key_file" 2>&1; then
                ((SUCCESS_COUNT++))
                echo "✓ Successfully imported: $(basename "$key_file")"
            else
                ((FAIL_COUNT++))
                echo "✗ Failed to import: $(basename "$key_file")"
            fi
            echo "-----------------------------------"
        done
        
        # Summary
        echo "Import complete!"
        echo "Successfully imported: $SUCCESS_COUNT"
        echo "Failed: $FAIL_COUNT"
        ;;
        
    *)
        echo "Error: Unsupported architecture '$ARCHITECTURE'"
        echo "Supported architectures: x86_64, aarch64, arm64"
        exit 1
        ;;
esac

echo "GPG key import process finished."