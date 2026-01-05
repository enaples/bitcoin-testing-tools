ARG OS=ubuntu
ARG OS_VER=jammy
FROM ${OS}:${OS_VER} as os-base

# Install reference: https://support.torproject.org/apt/tor-deb-repo

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qq -y apt-transport-https wget gpg jq curl

COPY tor.list /etc/apt/sources.list.d

RUN wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | \
    gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

FROM os-base AS tor-service

# Install Tor
RUN apt-get update 
RUN apt-get install -qq -y tor deb.torproject.org-keyring
RUN apt-get install -y dnsutils
COPY create-conf.sh /usr/local/bin
RUN chmod +x /usr/local/bin/create-conf.sh
COPY tor-entrypoint.sh /usr/local/bin/tor-entrypoint.sh
RUN chmod +x /usr/local/bin/tor-entrypoint.sh
COPY wait-for-bitcoind.sh /usr/local/bin
RUN chmod +x /usr/local/bin/wait-for-bitcoind.sh

RUN usermod -a -G debian-tor root

EXPOSE 9050 9051

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/tor-entrypoint.sh"]
CMD ["tor"]
