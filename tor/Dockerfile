ARG OS=ubuntu
ARG OS_VER=focal
FROM ${OS}:${OS_VER} as os-base

# Install reference: https://support.torproject.org/apt/tor-deb-repo

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qq -y apt-transport-https wget gpg dnsutils

COPY tor.list /etc/apt/sources.list.d

RUN wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | \
    gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

FROM os-base as tor-service

# Install Tor
RUN apt-get update && apt-get install -qq -y tor deb.torproject.org-keyring
COPY create-config.sh /usr/local/bin
RUN chmod +x /usr/local/bin/create-config.sh

RUN usermod -a -G debian-tor root

EXPOSE 9050 9051

WORKDIR /root
CMD ["tor"]
