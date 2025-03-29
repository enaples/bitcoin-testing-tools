FROM node:20

# c-lightning-REST parameters
ENV CLN_REST_VER="0.10.5"
ENV CLN_REST_PORT=3092
ENV CLN_REST_DOCPORT=4091

# Hosts
ENV BTC_HOST="btc_sig_miner"

RUN apt update && curl https://keybase.io/suheb/pgp_keys.asc | gpg --import && \
    apt install -y jq && \
    git clone --depth=1 --branch v${CLN_REST_VER} https://github.com/Ride-The-Lightning/c-lightning-REST.git


WORKDIR /c-lightning-REST
RUN git verify-tag v${CLN_REST_VER} && \
    npm install --only prod

COPY c-lightning-rest-entrypoint.sh /c-lightning-REST
RUN chmod +x /c-lightning-REST/c-lightning-rest-entrypoint.sh
COPY wait-for-bitcoind.sh /c-lightning-REST
RUN chmod +x /c-lightning-REST/wait-for-bitcoind.sh
COPY copy-macaroon.sh /c-lightning-REST
RUN chmod +x /c-lightning-REST/copy-macaroon.sh

EXPOSE $CLN_REST_PORT

ENTRYPOINT ["/c-lightning-REST/c-lightning-rest-entrypoint.sh"]

CMD ["node", "cl-rest.js"]

# Copiare l'access.macaroon