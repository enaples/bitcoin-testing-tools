#!/bin/sh
# Run by the official nginx image's entrypoint at container start.
# Creates the self-signed certificate used by the TLS listeners in electrs.conf.stream-template.
set -eu

SSL_DIR=/etc/nginx/ssl

if [ ! -f "$SSL_DIR/nginx-selfsigned.crt" ]; then
    mkdir -p "$SSL_DIR"
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 -subj "/CN=localhost" \
        -keyout "$SSL_DIR/nginx-selfsigned.key" -out "$SSL_DIR/nginx-selfsigned.crt" 2>/dev/null
    echo "$0: created self-signed certificate in $SSL_DIR"
fi
