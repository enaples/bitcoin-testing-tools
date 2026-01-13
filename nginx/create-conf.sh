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

http {
    server {
        listen 8080;
        server_name ${BLOCKSTREAM_ELECTRS_HOST};

        # Serve the Esplora frontend (static files)
        location / {
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;

            # Handle preflight requests
            if (\$request_method = 'OPTIONS') {
                return 204;
            }

            proxy_pass http://${BLOCKSTREAM_ELECTRS_HOST}:7070;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
        }

        # Proxy HTTP API requests to the electrs-blockstream bitcoin
        location /api/ {
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;

            # Handle preflight requests
            if (\$request_method = 'OPTIONS') {
                return 204;
            }

            # Remove /api prefix and forward to backend
            rewrite ^/api/(.*) /\$1 break;

            proxy_pass http://${BLOCKSTREAM_ELECTRS_HOST}:7070;

            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            # Timeouts (optional, adjust as needed)
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
    }

    server {
        listen 9000;
        server_name ${ELEMENTS_ELECTRS_HOST};

        # Serve the Esplora frontend (static files)
        location / {
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;

            # Handle preflight requests
            if (\$request_method = 'OPTIONS') {
                return 204;
            }

            proxy_pass http://${ELEMENTS_ELECTRS_HOST}:7000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
        }

        # Proxy HTTP API requests to the electrs-blockstream elements
        location /api/ {
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;

            # Handle preflight requests
            if (\$request_method = 'OPTIONS') {
                return 204;
            }

            # Remove /api prefix and forward to backend
            rewrite ^/api/(.*) /\$1 break;

            proxy_pass http://${ELEMENTS_ELECTRS_HOST}:7000;

            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            # Timeouts (optional, adjust as needed)
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
    }
}

EOF