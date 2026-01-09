ARG OS=nginx
FROM ${OS} as electrum-server

# Create self-signed SSL/TLS certificate
RUN apt update && apt install -y jq && \
    openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/CN=localhost" -days 3650 && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak && \
    mkdir -p /etc/nginx/streams-enabled

ENV BTC_HOST="btc_sig_miner"
ENV ROMANZ_ELECTRS_HOST="electrs"
ENV ELEMENTS_ELECTRS_HOST="liquid_electrs"
ENV BLOCKSTREAM_ELECTRS_HOST="blockstream_electrs"
COPY nginx-entrypoint.sh /usr/local/bin
COPY create-conf.sh /usr/local/bin
RUN chmod +x /usr/local/bin/nginx-entrypoint.sh
RUN chmod +x /usr/local/bin/create-conf.sh

ENTRYPOINT ["/usr/local/bin/nginx-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

EXPOSE 60602
