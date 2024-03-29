ARG OS=ubuntu
ARG OS_VER=focal
FROM ${OS}:${OS_VER} as bitcoind-node

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    apt-get -y install nano && \
    apt-get install -y bc && \
    apt-get install -yqq \
    curl unzip jq bash-completion

# Install bitcoind
COPY bitcoind-download.sh /usr/local/bin
RUN chmod +x /usr/local/bin/bitcoind-download.sh
RUN bitcoind-download.sh

# bash completion for bitcoind and bitcoin-cli
ENV GH_URL https://raw.githubusercontent.com/bitcoin/bitcoin/master
ENV BC /usr/share/bash-completion/completions
ADD $GH_URL/contrib/completions/bash/bitcoin-cli.bash $BC/bitcoin-cli
ADD $GH_URL/contrib/completions/bash/bitcoind.bash $BC/bitcoind
ADD $GH_URL/contrib/completions/bash/bitcoin-tx.bash $BC/bitcoin-tx

# Copy bitcoind configuration directory
COPY bitcoind /data

COPY cli /usr/local/bin
COPY bashrc /root/.bashrc
COPY bitcoind-entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/bitcoind-entrypoint.sh
COPY fund-bitcoind.sh /usr/local/bin
RUN chmod +x /usr/local/bin/fund-bitcoind.sh
COPY logtail.sh /usr/local/bin
RUN chmod +x /usr/local/bin/logtail.sh

RUN chmod +x /usr/local/bin/cli

# bitcoind P2P
EXPOSE 38333/tcp
# bitcoind regtest RPC
EXPOSE 38332/tcp
# zmqpubrawblock
EXPOSE 28332/tcp
# zmqpubrawtx
EXPOSE 28333/tcp

WORKDIR /bitcoind

# Start custom signet
ENTRYPOINT ["/usr/local/bin/bitcoind-entrypoint.sh"]
CMD ["/usr/local/bin/logtail.sh"]
