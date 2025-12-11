ARG OS=ubuntu
ARG OS_VER=jammy
FROM ${OS}:${OS_VER} AS os-base

# Set TimeZone
# ENV TIMEZONE=Europe/Rome
# RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qq -y curl unzip jq gpg \
    gpg-agent xz-utils nmap nano xxd git libtool libgmp-dev libsqlite3-dev \
    python3 python3-pip net-tools

FROM os-base AS elements-install

# Install c-lightning
ENV ELEMENTSD_VER="23.3.1"
ENV ELEMENTS_NETWORK="liquidsignet"
ENV ELEMENTS_RPCPORT=38884
ENV ELEMENTS_PORT=38886
COPY elementsd-download.sh /usr/local/bin
RUN chmod +x /usr/local/bin/elementsd-download.sh
COPY create-conf.sh /usr/local/bin
RUN chmod +x /usr/local/bin/create-conf.sh
RUN elementsd-download.sh

ADD https://raw.githubusercontent.com/ElementsProject/lightning/master/contrib/lightning-cli.bash-completion /usr/share/bash-completion/completions/lightning-cli

# COPY lightningd /data
COPY elementsd-entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/elementsd-entrypoint.sh
COPY create-conf.sh /usr/local/bin
RUN chmod +x /usr/local/bin/create-conf.sh
COPY wait-for-bitcoind.sh /usr/local/bin
RUN chmod +x /usr/local/bin/wait-for-bitcoind.sh

EXPOSE $ELEMENTS_PORT
EXPOSE $ELEMENTS_RPCPORT
ENTRYPOINT ["/usr/local/bin/elementsd-entrypoint.sh"]