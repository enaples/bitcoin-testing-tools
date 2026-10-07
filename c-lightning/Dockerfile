# syntax=docker/dockerfile:1
ARG OS_VER=noble
ARG BITCOIND_VER=28.1
ARG CLN_VER=26.06.8
ARG DEBIAN_FRONTEND=noninteractive

##################################
### Building Stage 1: bitcoin-cli 
##################################
FROM ubuntu:${OS_VER} AS bitcoin
ARG TARGETARCH
ARG BITCOIND_VER
ARG DEBIAN_FRONTEND
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends curl ca-certificates
RUN case "${TARGETARCH}" in \
        amd64) ARCH=x86_64 ;; \
        arm64) ARCH=aarch64 ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    BITCOIN_FILE="bitcoin-${BITCOIND_VER}-${ARCH}-linux-gnu.tar.gz" && \
    cd /tmp && \
    curl -fsSLO https://bitcoincore.org/bin/bitcoin-core-${BITCOIND_VER}/${BITCOIN_FILE} && \
    curl -fsSLO https://bitcoincore.org/bin/bitcoin-core-${BITCOIND_VER}/SHA256SUMS && \
    grep " ${BITCOIN_FILE}$" SHA256SUMS | sha256sum -c - && \
    tar -zxf ${BITCOIN_FILE} && \
    install -D bitcoin-${BITCOIND_VER}/bin/bitcoin-cli /out/usr/bin/bitcoin-cli

##################################
### Building Stage 2.a: CLN amd64 -> official signed release binaries
##################################
FROM ubuntu:${OS_VER} AS cln-amd64
ARG CLN_VER
ARG DEBIAN_FRONTEND
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends \
    curl ca-certificates git gnupg xz-utils
COPY --chmod=755 import-keys.sh cln-download-verified.sh /usr/local/bin/

# Pick the release tarball built for the base image's Ubuntu version (e.g. noble -> 24.04)
RUN . /etc/os-release && \
    CLN_FILE=clightning-v${CLN_VER}-Ubuntu-${VERSION_ID}-amd64.tar.xz && \
    cln-download-verified.sh ${CLN_FILE} && \
    mkdir -p /out && \
    tar -xf /tmp/${CLN_FILE} -C /out

##################################
### Building Stage 2.b: CLN arm64 -> no official binaries, compile the signed source release
##################################
FROM ubuntu:${OS_VER} AS cln-arm64
ARG CLN_VER
ARG DEBIAN_FRONTEND
RUN apt-get update -qq && apt-get install -qq -y \
    jq curl autoconf automake build-essential git gnupg unzip libtool libsqlite3-dev libffi-dev \
    python3 python3-pip zlib1g-dev libsodium-dev gettext lowdown \
    libpq-dev libsecp256k1-dev protobuf-compiler

# Install Rust via rustup (newer version than apt packages)
ENV PATH="/root/.cargo/bin:/root/.local/bin:$PATH"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

COPY --chmod=755 import-keys.sh cln-download-verified.sh /usr/local/bin/

# The git tags are signed by keys not always in contrib/keys, so verify the source
# zip against the release SHA256SUMS instead (same check as the amd64 binaries)
RUN cln-download-verified.sh clightning-v${CLN_VER}.zip && \
    cd /tmp && \
    unzip -q clightning-v${CLN_VER}.zip && \
    cd clightning-v${CLN_VER} && \
    ./configure && \
    RUST_PROFILE=release uv run make && \
    RUST_PROFILE=release make install DESTDIR=/out

##################################
### Building Stage 3: pick the CLN stage matching the target platform
##################################
FROM cln-${TARGETARCH} AS cln

##################################
### Final runtime image: only what lightningd and the helper scripts need
##################################
FROM ubuntu:${OS_VER}
ARG CLN_VER
ARG DEBIAN_FRONTEND
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends \
    jq curl ca-certificates bash-completion libpq5 libsodium23 libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=bitcoin /out/ /
COPY --from=cln /out/ /

# Fail the build if any runtime library is missing
RUN lightningd --version && bitcoin-cli --version | head -1

ADD https://raw.githubusercontent.com/ElementsProject/lightning/v${CLN_VER}/contrib/lightning-cli.bash-completion /usr/share/bash-completion/completions/lightning-cli
RUN echo 'alias lightning-cli="lightning-cli --lightning-dir=/lightningd"' >> /root/.bashrc && \
    echo '[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion' >> /root/.bashrc

ENV BTC_HOST="btc_sig_miner"
ENV FAUCET_URL="faucet"
ENV CLNREST_PORT=3010
ENV CLN_PORT=39735

COPY --chmod=755 c-lightning-entrypoint.sh create-conf.sh fund-c-lightning.sh \
    logtail.sh wait-for-bitcoind.sh cli /usr/local/bin/

EXPOSE $CLN_PORT
EXPOSE $CLNREST_PORT
ENTRYPOINT ["/usr/local/bin/c-lightning-entrypoint.sh"]

# Show logs from beginning and keep following
CMD ["/usr/local/bin/logtail.sh"]
