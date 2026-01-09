cat <<- EOF > "/etc/nginx/nginx.conf"
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

stream {
    upstream ${ROMANZ_ELECTRS_HOST} {
        server ${ROMANZ_ELECTRS_HOST}:60601;
    }

    server {
        listen 60602 ssl;
        proxy_pass ${ROMANZ_ELECTRS_HOST};

        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout 4h;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
    }

    upstream ${ELEMENTS_ELECTRS_HOST} {
        server ${ELEMENTS_ELECTRS_HOST}:60701;
    }

    server {
        listen 60702 ssl;
        proxy_pass ${ELEMENTS_ELECTRS_HOST};

        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout 4h;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
    }

    upstream ${BLOCKSTREAM_ELECTRS_HOST} {
        server ${BLOCKSTREAM_ELECTRS_HOST}:60501;
    }

    server {
        listen 60502 ssl;
        proxy_pass ${BLOCKSTREAM_ELECTRS_HOST};

        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout 4h;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
    }
}

EOF