ARG OS=ubuntu
ARG OS_VER=focal
FROM ${OS}:${OS_VER} as os-base

# Set TimeZone
ENV TIMEZONE=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qq -y --no-install-recommends \
    libpq-dev curl unzip jq bash-completion gpg gpg-agent xz-utils nmap nano xxd \
    autoconf automake build-essential git libtool libgmp-dev libsqlite3-dev \
    python3 python3-pip net-tools zlib1g-dev libsodium-dev gettext \
    valgrind shellcheck cppcheck libsecp256k1-dev dirmngr

RUN pip3 install --upgrade pip && \
    pip3 install mako && \
    pip3 install --user poetry

FROM os-base as cln-install

# Install nodejs
RUN curl https://nodejs.org/dist/v20.10.0/node-v20.10.0-linux-x64.tar.xz | tar -xJv && \
    cp -r node-v20.10.0-linux-x64/bin /usr/ && \
    cp -r node-v20.10.0-linux-x64/include /usr/ && \
    cp -r node-v20.10.0-linux-x64/lib /usr/ && \
    cp -r node-v20.10.0-linux-x64/share /usr/ && \
    rm -rf node-v20.10.0-linux-x64

# Get bitcoin-cli
# Install bitcoind
ENV BITCOIND_VER="24.0.1"
COPY bitcoind-download.sh /usr/local/bin
RUN chmod +x /usr/local/bin/bitcoind-download.sh
RUN bitcoind-download.sh

# Install c-lightning
ENV CL_VER="23.02"
ENV CL_PORT=39735
COPY c-lightning-download.sh /usr/local/bin
RUN chmod +x /usr/local/bin/c-lightning-download.sh
RUN c-lightning-download.sh

# Plugins
ENV CLN_REST_VER="0.10.5"
ENV CLN_PORT=3092
ENV CLN_DOCPORT=4091

ADD https://raw.githubusercontent.com/ElementsProject/lightning/master/contrib/lightning-cli.bash-completion /usr/share/bash-completion/completions/lightning-cli

# COPY lightningd /data

COPY c-lightning-entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/c-lightning-entrypoint.sh
COPY create-config.sh /usr/local/bin
RUN chmod +x /usr/local/bin/create-config.sh
COPY fund-c-lightning.sh /usr/local/bin
RUN chmod +x /usr/local/bin/fund-c-lightning.sh
COPY logtail.sh /usr/local/bin
RUN chmod +x /usr/local/bin/logtail.sh
COPY wait-for-bitcoind.sh /usr/local/bin
RUN chmod +x /usr/local/bin/wait-for-bitcoind.sh
COPY cln-rest-plugin.sh /usr/local/bin
RUN chmod +x /usr/local/bin/cln-rest-plugin.sh
COPY cli /usr/local/bin
RUN chmod +x /usr/local/bin/cli

EXPOSE $CL_PORT
ENTRYPOINT ["/usr/local/bin/c-lightning-entrypoint.sh"]

# Show logs from beginning and keep following
CMD ["/usr/local/bin/logtail.sh"]
