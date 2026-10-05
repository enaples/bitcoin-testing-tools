#!/bin/bash
set -Eeuo pipefail

# Get the machine architecture
architecture=$(uname -m)

# Check the architecture and print the corresponding message
case $architecture in
    x86_64)
        # Pick the release tarball built for the base image's Ubuntu version (e.g. noble -> 24.04)
        . /etc/os-release
        CLN_URL=https://github.com/ElementsProject/lightning/releases/download/v${CLN_VER}
        CLN_FILE=clightning-v${CLN_VER}-Ubuntu-${VERSION_ID}-amd64.tar.xz
        CLN_SUMS=SHA256SUMS-v${CLN_VER}
        echo "Installing Core-Lightning ${CLN_VER} for x86_64 (${CLN_FILE})"

        cd /tmp
        curl -fsSLO ${CLN_URL}/${CLN_FILE}
        curl -fsSLO ${CLN_URL}/${CLN_SUMS}
        curl -fsSLO ${CLN_URL}/${CLN_SUMS}.asc

        /usr/local/bin/import-keys.sh

        # SHA256SUMS carries signatures from several devs whose keys aren't all in
        # contrib/keys, so plain `gpg --verify` exits non-zero. Require a valid
        # signature from the CLN release key and no bad signatures instead.
        # Ref. https://docs.corelightning.org/docs/security-policy
        CLN_RELEASE_KEY=616C52F99D0612B2A151B1074129A994AA7E9852
        gpg --status-fd 1 --verify /tmp/${CLN_SUMS}.asc /tmp/${CLN_SUMS} > /tmp/gpg-status.txt 2>/dev/null || true
        if grep -q "^\[GNUPG:\] BADSIG" /tmp/gpg-status.txt || \
           ! grep -q "^\[GNUPG:\] VALIDSIG .* ${CLN_RELEASE_KEY}$" /tmp/gpg-status.txt; then
            echo "No valid signature from the CLN release key on ${CLN_SUMS}"
            cat /tmp/gpg-status.txt
            exit 1
        fi
        echo "Good signature on ${CLN_SUMS} from CLN release key ${CLN_RELEASE_KEY}"

        grep " ${CLN_FILE}$" /tmp/${CLN_SUMS} | sha256sum -c -
        cd / && tar -xf /tmp/${CLN_FILE}
        rm -rf /tmp/${CLN_FILE} /tmp/${CLN_SUMS} /tmp/${CLN_SUMS}.asc /tmp/gpg-status.txt /tmp/lightning
    ;;
    aarch64|arm64)
        echo "Executables not available for Core-Lightning ${CLN_VER} for ${architecture}"
        echo "Compiling the source code..."

        cd /tmp && \
        git clone --depth=1 --branch v${CLN_VER} https://github.com/ElementsProject/lightning.git

        /usr/local/bin/import-keys.sh

        cd /tmp/lightning && \
        # cln v23.02 was signed by Alex Myers whose key is not under /contrib/keys
        # git verify-tag v${CLN_VER} && \
        ./configure && \
        RUST_PROFILE=release uv run make && \
        RUST_PROFILE=release make install
    ;;
    *)
        echo "Unsupported architecture: ${architecture}"
        exit 1
    ;;
esac

echo "alias lightning-cli=\"lightning-cli --lightning-dir=/lightningd\"
[[ \$PS1 && -f /usr/share/bash-completion/bash_completion ]] && \\
. /usr/share/bash-completion/bash_completion" >> "/root/.bashrc"

# Fail the build if the install didn't produce the binaries
lightningd --version
