ARG OS=nginx
FROM ${OS} as electrum-server

# Create self-signed SSL/TLS certificate
RUN apt update && apt install -y jq && \
    openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/CN=localhost" -days 3650 && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak && \
    mkdir -p /etc/nginx/streams-enabled

COPY nginx.conf /etc/nginx
COPY nginx-entrypoint.sh /usr/local/bin
COPY wait-for-bitcoind.sh /usr/local/bin
RUN chmod +x /usr/local/bin/nginx-entrypoint.sh
RUN chmod +x /usr/local/bin/wait-for-bitcoind.sh

ENTRYPOINT ["/usr/local/bin/nginx-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

EXPOSE 60602
