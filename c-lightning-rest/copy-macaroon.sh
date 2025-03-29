# copy macaroon in /lightningd if it does not exist
if [ ! -f "/lightningd/access.macaroon" ]; then
    echo "Coping macaroon to /lightningd"
    cp /c-lightning-REST/certs/access.macaroon /lightningd/access.macaroon
fi