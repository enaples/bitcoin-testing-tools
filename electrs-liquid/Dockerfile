ARG OS=ubuntu
ARG OS_VER=focal
FROM ${OS}:${OS_VER} as electrum-server

# Set TimeZone
ENV TIMEZONE=Europe/Rome
# On one elements node:
# elements-cli -conf=/elementsd/elements.conf getblock $(elements-cli -conf=/elementsd/elements.conf getblockhash 0) 2 | jq .tx[1].vin[0].txid
ENV CUSTOM_LIQUID_ISSUANCE_PREVOUT=""
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

ENV EL_HOST="liquid1"
# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qq -y \
    nano curl gpg jq openssl git cargo clang cmake

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

EXPOSE 60701
ENTRYPOINT ["/usr/local/bin/electrs-entrypoint.sh"]

WORKDIR /root/electrs
CMD exec electrs \
    -vvvv \
    --network "liquidtestnet" \
    --daemon-rpc-addr "liquid1:39884" \
    --parent-network "signet" \
    --cookie "elements:elements" \
    --db-dir "/electrum/db" \
    --jsonrpc-import \
    --http-addr "0.0.0.0:7000" \
    --electrum-rpc-addr "0.0.0.0:60701" \
    --initial-issuance-prevout "${CUSTOM_LIQUID_ISSUANCE_PREVOUT}"