#!/bin/bash
set -Eeuo pipefail

# Download the Bitcoin Core release for the target architecture, verify it against
# the release SHA256SUMS and install into /out:
#   /out/usr/bin                               bitcoind and the CLI tools
#   /out/data/contrib/signet                   signet miner
#   /out/data/test/functional/test_framework   python modules imported by the miner
#   /out/usr/share/bash-completion/completions bash completions
# The miner and the completions come from the source tarball of the same release,
# so they always match the installed binaries.
# TODO: add gpg verification on SHA256SUMS

case "${TARGETARCH}" in
    amd64) ARCH=x86_64 ;;
    arm64) ARCH=aarch64 ;;
    *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;;
esac

BTC_URL=https://bitcoincore.org/bin/bitcoin-core-${BITCOIND_VER}
BIN_FILE=bitcoin-${BITCOIND_VER}-${ARCH}-linux-gnu.tar.gz
SRC_FILE=bitcoin-${BITCOIND_VER}.tar.gz
SRC_DIR=bitcoin-${BITCOIND_VER}

echo "Downloading Bitcoin Core ${BITCOIND_VER} for ${ARCH}"
cd /tmp
curl -fsSLO ${BTC_URL}/${BIN_FILE}
curl -fsSLO ${BTC_URL}/${SRC_FILE}
curl -fsSLO ${BTC_URL}/SHA256SUMS

for file in ${BIN_FILE} ${SRC_FILE}; do
    grep " ${file}$" SHA256SUMS | sha256sum -c -
done

# Binaries (bitcoin-qt and test_bitcoin are left out)
tar -xzf ${BIN_FILE}
install -D -t /out/usr/bin \
    ${SRC_DIR}/bin/bitcoind ${SRC_DIR}/bin/bitcoin-cli ${SRC_DIR}/bin/bitcoin-util \
    ${SRC_DIR}/bin/bitcoin-tx ${SRC_DIR}/bin/bitcoin-wallet

# Signet miner and the test_framework it imports
mkdir -p /out/data
tar -xzf ${SRC_FILE} -C /out/data --strip-components=1 \
    ${SRC_DIR}/contrib/signet ${SRC_DIR}/test/functional/test_framework
chmod +x /out/data/contrib/signet/miner

# Bash completions
COMPLETIONS=/out/usr/share/bash-completion/completions
mkdir -p ${COMPLETIONS}
for tool in bitcoind bitcoin-cli bitcoin-tx; do
    tar -xzf ${SRC_FILE} -O ${SRC_DIR}/contrib/completions/bash/${tool}.bash > ${COMPLETIONS}/${tool}
done
