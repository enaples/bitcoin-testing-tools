#!/bin/bash
set -Eeuo pipefail

cd /tmp && \
git clone --depth=1 --branch v${PEERSWAP_VER} https://github.com/ElementsProject/peerswap.git

# Install Go (detect OS and architecture)
case "$(uname -s)" in
    Linux)                       GO_OS=linux ;;
    Darwin)                      GO_OS=darwin ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT) GO_OS=windows ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64|amd64)   GO_ARCH=amd64 ;;
    aarch64|arm64)  GO_ARCH=arm64 ;;
    i386|i686)      GO_ARCH=386 ;;
    armv6l|armv7l)  GO_ARCH=armv6l ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

if [ "$GO_OS" = "windows" ]; then
    GO_ARCHIVE="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.zip"
    curl -# -sLO "https://golang.org/dl/${GO_ARCHIVE}"
    GO_INSTALL_DIR="${GO_INSTALL_DIR:-/c/Program Files}"
    mkdir -p "$GO_INSTALL_DIR"
    unzip -q "$GO_ARCHIVE" -d "$GO_INSTALL_DIR"
    export PATH="$PATH:$GO_INSTALL_DIR/go/bin"
else
    GO_ARCHIVE="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
    curl -# -sLO "https://golang.org/dl/${GO_ARCHIVE}"
    tar -C /usr/local -xzf "$GO_ARCHIVE"
    export PATH="$PATH:/usr/local/go/bin"
fi

cd /tmp/peerswap && \
make cln-release