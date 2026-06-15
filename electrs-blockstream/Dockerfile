ARG OS=ubuntu
ARG OS_VER=focal
FROM ${OS}:${OS_VER}

# Set Env variables
ENV BTC_HOST="btc_sig_miner"
ENV BTC_PORT="38332"
ENV BTC_USER="bitcoin"
ENV BTC_PASS="bitcoin"
ENV BTC_NETWORK="signet"
ENV ELECTRS_DB_DIR="/electrum/db"
ENV ELECTRS_HTTP_PORT="3000"
ENV ELECTRS_ELECTRUM_RPC_PORT="60601"

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qq -y \
    nano curl gpg jq openssl git cargo clang cmake

RUN mkdir -p /electrum

RUN cd /electrum && \
    git clone --depth=1 --branch new-index https://github.com/enaples/blockstream-electrs.git

# Build electrs
RUN cd /electrum/blockstream-electrs && \
    cargo build --locked --release && \
    install -m 0755 -o root -g root -t /usr/local/bin /electrum/blockstream-electrs/target/release/electrs

COPY electrs-entrypoint.sh /usr/local/bin
COPY wait-for-bitcoind.sh /usr/local/bin
RUN chmod +x /usr/local/bin/electrs-entrypoint.sh
RUN chmod +x /usr/local/bin/wait-for-bitcoind.sh

EXPOSE 60501
ENTRYPOINT ["/usr/local/bin/electrs-entrypoint.sh"]

WORKDIR /root/electrs
CMD ["sh", "-c", "exec electrs \
    -vvvv \
    --network \"$BTC_NETWORK\" \
    --daemon-rpc-addr \"$BTC_HOST:$BTC_PORT\" \
    --cookie \"$BTC_USER:$BTC_PASS\" \
    --db-dir \"$ELECTRS_DB_DIR\" \
    --jsonrpc-import \
    --address-search \
    --http-addr \"0.0.0.0:$ELECTRS_HTTP_PORT\" \
    --electrum-rpc-addr \"0.0.0.0:$ELECTRS_ELECTRUM_RPC_PORT\""]