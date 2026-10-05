ARG OS=ubuntu
ARG OS_VER=noble
FROM ${OS}:${OS_VER}
ARG DEBIAN_FRONTEND=noninteractive

# On one elements node:
# elements-cli -conf=/elementsd/elements.conf getblock $(elements-cli -conf=/elementsd/elements.conf getblockhash 0) 2 | jq .tx[1].vin[0].txid
ENV CUSTOM_LIQUID_ISSUANCE_PREVOUT=""
ENV BTC_HOST="btc_sig_miner"
ENV BTC_PORT="38332"
ENV BTC_USER="bitcoin"
ENV BTC_PASS="bitcoin"

ENV ELECTRS_DB_DIR="/electrum/db"
ENV ELECTRS_HTTP_PORT="3030"
ENV ELECTRS_ELECTRUM_RPC_PORT="60701"

ENV ELM_HOST="liquid1"
ENV ELM_PORT="39884"
ENV ELM_USER="elements"
ENV ELM_PASS="elements"
ENV ELM_NETWORK="liquidtestnet"

# Install dependencies
RUN apt-get update -qq && apt-get install -qq -y \
    nano curl gpg jq openssl git build-essential clang cmake

# Install Rust via rustup (apt's cargo is too old to parse recent Cargo.lock files)
ARG RUST_VER=1.95
ENV PATH="/root/.cargo/bin:$PATH"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain ${RUST_VER} --profile minimal

RUN mkdir -p /electrum

RUN cd /electrum && \
    git clone --depth=1 --branch new-index https://github.com/enaples/blockstream-electrs.git

# Build electrs
RUN cd /electrum/blockstream-electrs && \
    cargo build --features liquid --locked --release && \
    install -m 0755 -o root -g root -t /usr/local/bin /electrum/blockstream-electrs/target/release/electrs

COPY electrs-entrypoint.sh /usr/local/bin
COPY wait-for-elementsd.sh /usr/local/bin
RUN chmod +x /usr/local/bin/electrs-entrypoint.sh
RUN chmod +x /usr/local/bin/wait-for-elementsd.sh

EXPOSE $ELECTRS_ELECTRUM_RPC_PORT
EXPOSE $ELECTRS_HTTP_PORT

ENTRYPOINT ["/usr/local/bin/electrs-entrypoint.sh"]

WORKDIR /root/electrs
CMD ["electrs", \
    "-vvvv", \
    "--network", "liquidtestnet", \
    "--parent-network", "signet", \
    "--db-dir", "$ELECTRS_DB_DIR", \
    "--jsonrpc-import", \
    "--daemon-rpc-addr", "$ELM_HOST:$ELM_PORT", \
    "--cookie", "$ELM_USER:$ELM_PASS", \
    "--http-addr", "0.0.0.0:$ELECTRS_HTTP_PORT", \
    "--electrum-rpc-addr", "0.0.0.0:$ELECTRS_ELECTRUM_RPC_PORT", \
    "--initial-issuance-prevout", "$CUSTOM_LIQUID_ISSUANCE_PREVOUT"]