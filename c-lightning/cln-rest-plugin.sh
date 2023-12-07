# Add cln-REST plugin config to c-lightning config
mkdir -p /lightningd/cln-plugins \
&& cd /lightningd/cln-plugins \
&& curl -# -sLO  https://github.com/Ride-The-Lightning/c-lightning-REST/archive/refs/tags/v${CLN_REST_VER}.tar.gz \
&& curl -# -sLO  https://github.com/Ride-The-Lightning/c-lightning-REST/releases/download/v${CLN_REST_VER}/v${CLN_REST_VER}.tar.gz.asc \
&& curl -# -sLO  https://keybase.io/suheb/pgp_keys.asc \
&& gpg --import pgp_keys.asc \
&& gpg --verify v${CLN_REST_VER}.tar.gz.asc v${CLN_REST_VER}.tar.gz \
&& tar xvf v${CLN_REST_VER}.tar.gz \
&& rm v${CLN_REST_VER}.tar.gz \
&& cd c-lightning-REST-${CLN_REST_VER} \
&& npm install \
&& echo "{
  \"PORT\": $CLN_PORT,
  \"DOCPORT\": $CLN_DOCPORT,
  \"PROTOCOL\": \"http\",
  \"EXECMODE\": \"test\",
  \"RPCCOMMANDS\": [\"*\"],
  \"DOMAIN\": \"localhost\",
  \"LNRPCPATH\": \"/lightningd/signet\",
}" > cl-rest-config.json

echo "# cln-rest-plugin
plugin=/lightningd/cln-plugins/c-lightning-REST-${CLN_REST_VER}/clrest.js
rest-port=$CLN_PORT
rest-docport=$CLN_DOCPORT
rest-execmode=test
rest-protocol=http
rest-lnrpcpath=/lightningd/signet" >> "/lightningd/config"