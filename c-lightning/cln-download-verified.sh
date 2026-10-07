#!/bin/bash
set -Eeuo pipefail

# Download a Core-Lightning release file into /tmp and verify it against the
# release SHA256SUMS signed by the CLN release key.
# Usage: cln-download-verified.sh <release file name>
CLN_FILE=$1
CLN_URL=https://github.com/ElementsProject/lightning/releases/download/v${CLN_VER}
CLN_SUMS=SHA256SUMS-v${CLN_VER}
CLN_RELEASE_KEY=616C52F99D0612B2A151B1074129A994AA7E9852

echo "Downloading ${CLN_FILE}"
cd /tmp
curl -fsSLO ${CLN_URL}/${CLN_FILE}
curl -fsSLO ${CLN_URL}/${CLN_SUMS}
curl -fsSLO ${CLN_URL}/${CLN_SUMS}.asc

/usr/local/bin/import-keys.sh

# SHA256SUMS carries signatures from several devs whose keys aren't all in
# contrib/keys, so plain `gpg --verify` exits non-zero. Require a valid
# signature from the CLN release key and no bad signatures instead.
# Ref. https://docs.corelightning.org/docs/security-policy
gpg --status-fd 1 --verify /tmp/${CLN_SUMS}.asc /tmp/${CLN_SUMS} > /tmp/gpg-status.txt 2>/dev/null || true
if grep -q "^\[GNUPG:\] BADSIG" /tmp/gpg-status.txt || \
   ! grep -q "^\[GNUPG:\] VALIDSIG .* ${CLN_RELEASE_KEY}$" /tmp/gpg-status.txt; then
    echo "No valid signature from the CLN release key on ${CLN_SUMS}"
    cat /tmp/gpg-status.txt
    exit 1
fi
echo "Good signature on ${CLN_SUMS} from CLN release key ${CLN_RELEASE_KEY}"

grep " ${CLN_FILE}$" /tmp/${CLN_SUMS} | sha256sum -c -
