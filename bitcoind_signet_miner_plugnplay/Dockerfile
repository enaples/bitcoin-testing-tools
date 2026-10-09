# syntax=docker/dockerfile:1
ARG OS_VER=noble
ARG BITCOIND_VER=28.1
ARG DEBIAN_FRONTEND=noninteractive

##################################
### Building Stage: Bitcoin Core binaries, signet miner and bash completions
##################################
FROM ubuntu:${OS_VER} AS bitcoin
ARG TARGETARCH
ARG BITCOIND_VER
ARG DEBIAN_FRONTEND
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends curl ca-certificates
COPY --chmod=755 bitcoind-download.sh /usr/local/bin/
RUN bitcoind-download.sh

##################################
### Final runtime image
##################################
FROM ubuntu:${OS_VER}
ARG DEBIAN_FRONTEND
# python3 runs the signet miner (standard library only), jq is used by the scripts
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends \
    python3 jq bash-completion tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV TZ=Europe/Rome
ENV WALLET="sig_miner_wallet"
ENV POISSON=true

COPY --from=bitcoin /out/ /

# Fail the build if bitcoind or the miner's python imports are broken
RUN bitcoind -version | head -1 && /data/contrib/signet/miner --help > /dev/null

# Copy bitcoind configuration directory
COPY bitcoind /data
COPY bashrc /root/.bashrc
COPY --chmod=755 cli bitcoind-entrypoint.sh mine.sh /usr/local/bin/

# Healthy once bitcoind answers and the first 101 blocks are mined, so the
# coinbase outputs are spendable. The long start period covers slow hardware.
HEALTHCHECK --interval=10s --timeout=5s --start-period=30m \
    CMD [ "$(bitcoin-cli -datadir=/bitcoind getblockcount)" -gt 100 ] || exit 1

# bitcoind P2P
EXPOSE 38333/tcp
# bitcoind signet RPC
EXPOSE 38332/tcp
# zmqpubrawblock
EXPOSE 28332/tcp
# zmqpubrawtx
EXPOSE 28333/tcp

WORKDIR /bitcoind
ENTRYPOINT ["/usr/local/bin/bitcoind-entrypoint.sh"]

# Start mining on custom signet
CMD ["/usr/local/bin/mine.sh"]
