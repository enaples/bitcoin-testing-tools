ARG OS=ubuntu
ARG OS_VER=noble
FROM ${OS}:${OS_VER} AS os-base

# Set TimeZone
ENV TIMEZONE=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qq -y \
    jq curl autoconf automake build-essential git libtool libsqlite3-dev libffi-dev \
    python3 python3-pip net-tools zlib1g-dev libsodium-dev gettext lowdown \
    valgrind libpq-dev shellcheck cppcheck libsecp256k1-dev lowdown protobuf-compiler

# Install Rust via rustup (newer version than apt packages)
ENV PATH="/root/.cargo/bin:/root/.local/bin:$PATH"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

FROM os-base AS cln-install

# Get bitcoin-cli
# Install bitcoind
ENV BITCOIND_VER="28.1"
ENV BTC_HOST="btc_sig_miner"
ENV FAUCET_URL="faucet"
COPY bitcoind-download.sh /usr/local/bin
RUN chmod +x /usr/local/bin/bitcoind-download.sh
RUN bitcoind-download.sh

# Install c-lightning
ENV CL_VER="25.12"
ENV CL_PORT=39735
COPY c-lightning-download.sh /usr/local/bin
RUN chmod +x /usr/local/bin/c-lightning-download.sh
COPY import-keys.sh /usr/local/bin
RUN chmod +x /usr/local/bin/import-keys.sh
RUN c-lightning-download.sh

ADD https://raw.githubusercontent.com/ElementsProject/lightning/master/contrib/lightning-cli.bash-completion /usr/share/bash-completion/completions/lightning-cli

# COPY lightningd /data
COPY c-lightning-entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/c-lightning-entrypoint.sh
COPY create-conf.sh /usr/local/bin
RUN chmod +x /usr/local/bin/create-conf.sh
COPY fund-c-lightning.sh /usr/local/bin
RUN chmod +x /usr/local/bin/fund-c-lightning.sh
COPY logtail.sh /usr/local/bin
RUN chmod +x /usr/local/bin/logtail.sh
COPY wait-for-bitcoind.sh /usr/local/bin
RUN chmod +x /usr/local/bin/wait-for-bitcoind.sh
COPY cli /usr/local/bin
RUN chmod +x /usr/local/bin/cli

EXPOSE $CL_PORT
ENTRYPOINT ["/usr/local/bin/c-lightning-entrypoint.sh"]

# Show logs from beginning and keep following
CMD ["/usr/local/bin/logtail.sh"]
