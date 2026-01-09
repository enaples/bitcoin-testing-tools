ARG OS=ubuntu
ARG OS_VER=focal
FROM ${OS}:${OS_VER} as electrum-server

# Set TimeZone
ENV TIMEZONE=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

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

ENV BTC_HOST="btc_sig_miner"

COPY electrs-entrypoint.sh /usr/local/bin
COPY wait-for-bitcoind.sh /usr/local/bin
RUN chmod +x /usr/local/bin/electrs-entrypoint.sh
RUN chmod +x /usr/local/bin/wait-for-bitcoind.sh

EXPOSE 60501
ENTRYPOINT ["/usr/local/bin/electrs-entrypoint.sh"]

WORKDIR /root/electrs
CMD exec electrs \
    -vvvv \
    --network "signet" \
    --daemon-rpc-addr "btc_sig_miner:38332" \
    --cookie "bitcoin:bitcoin" \
    --db-dir "/electrum/db" \
    --jsonrpc-import \
    --http-addr "0.0.0.0:7070" \
    --electrum-rpc-addr "0.0.0.0:60501" 