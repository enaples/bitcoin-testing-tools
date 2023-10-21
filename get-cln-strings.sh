#!/bin/bash

# run-in-node: Run a command inside a docker container, using the bash shell

function get-cln-id(){
    if [ "$#" -ne 1 ]; then
        echo "Error: Exactly two arguments are required."
        return 1
    fi
    
    if [ $1 = 0 ]; then
        PREFIX=""
    else
        PREFIX="-$1"
    fi
    
    CLN_ONION=$(docker exec c-lightning$PREFIX lightning-cli --lightning-dir=/lightningd getinfo | jq -r ".address[].address")
    CLN_PORT=$(docker exec c-lightning$PREFIX lightning-cli --lightning-dir=/lightningd getinfo | jq -r ".address[].port")
    CLN_ID=$(docker exec c-lightning$PREFIX lightning-cli --lightning-dir=/lightningd getinfo | jq -r ".id")
    
    CLN_CONNECT_STR=$CLN_ID@$CLN_ONION:$CLN_PORT
    echo $CLN_CONNECT_STR
}

function get-cln-rest(){
    if [ "$#" -ne 1 ]; then
        echo "Error: Exactly one argument is required."
        return 1
    fi
    
    if [ $1 = 0 ]; then
        PREFIX=""
    else
        PREFIX="-$1"
    fi
    CLN_REST=$(docker exec tor cat /var/lib/tor/hidden_service_cln${PREFIX}_rest/hostname)
    CLN_REST_MACAROON=$(docker exec c-lightning$PREFIX xxd -ps -u -c 1000 /lightningd/cln-plugins/c-lightning-REST-0.10.5/certs/access.macaroon)
    CLN_REST_PORT=$(( 8080 + $1 * 101))
    REST_STR="c-lightning-rest://http://${CLN_REST}:$CLN_REST_PORT?&macaroon=${CLN_REST_MACAROON}&protocol=http"
    echo $REST_STR
}

function get-qrs(){
    if [ "$#" -ne 1 ]; then
        echo "Error: Exactly two arguments are required."
        return 1
    fi
    ID_STR=$(get-cln-id $1)
    REST_STR=$(get-cln-rest $1)
    curl -so "ZeusControl$PREFIX.png"  "https://api.qrserver.com/v1/create-qr-code/?data=$(jq -s -R -r @uri <<< "$REST_STR")&format=png&size=512x512&margin=10"
    curl -so "peerID$PREFIX.png" "https://api.qrserver.com/v1/create-qr-code/?data=$(jq -s -R -r @uri <<< "$ID_STR")&format=png&size=512x512&margin=10"
}
