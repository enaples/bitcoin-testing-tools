
# Write a bash func that copy/pastes $1 time the "c-lightning" folder renaming them as "c-lightning-1", "c-lightning-2", etc.

start_ln(){
    # Copy the c-lightning folder an rename it as c-lightning-i with i = 1, 2, 3 that is a parameter of the function
    # $1 = number of c-lightning nodes to create
    
    if [ -z "$1" ]; then
        node_count=0
    else
        node_count=$1
    fi
    
    for i in $(seq "$node_count"); do
        cp -r $(pwd)/c-lightning $(pwd)/c-lightning-$i
    done
}

set_ports(){
    if [ -z "$1" ]; then
        node_count=0
    else
        node_count=$1
    fi
    
    for k in $(seq "$node_count"); do
        # # Change ports in 'conf' file
        # sed -i "s/39735/$(( 39735 + k * 101))/" $(pwd)/c-lightning-$k/lightningd/config
        
        # # Change ports in 'cln-rest-plugin.sh'
        # sed -i "s/3092/$(( 3092 + k * 101))/" $(pwd)/c-lightning-$k/cln-rest-plugin.sh
        # sed -i "s/3092/$(( 4091 + k * 101))/" $(pwd)/c-lightning-$k/cln-rest-plugin.sh
        
        # # Change ports in 'Dockerfile'
        # sed -i "s/39735/$(( 39735 + k * 101))/" $(pwd)/c-lightning-$k/Dockerfile
        
        # Add new ports to 'torcc' file
        
        cat <<- EOF >> "tor/torrc"

		# Lightning-REST $k
		HiddenServiceDir /var/lib/tor/hidden_service_cln-${k}_rest/
		HiddenServiceVersion 3
		HiddenServicePort $(( 8080 + k * 101)) 127.0.0.1:$(( 3092 + k * 101))
		EOF
        
    done
}


create_docker_compose(){
    if [ -z "$1" ]; then
        node_count=0
    else
        node_count=$1
    fi
    
    if [ -z "$2" ]; then
        usage="miner"
    else
        usage=$2
    fi
    
    FILE="docker-compose_${usage}_network.yml"
    
    cat <<- EOF > $FILE
	version: "3.3"
	services:

	EOF
    
    
    if [ $usage = "miner" ]; then
        cat <<- EOF >> $FILE
    btc_sig_miner:
        container_name: btc_sig_miner
        build:
            context: bitcoind_signet_miner_plugnplay
        image: bitcoind_signet_miner
        environment:
            BLOCK_MINING_SEC: 600
        volumes:
            - shared_vol_btc:/bitcoind
        port:
            - "38333:38333"
            - "38332:38332"
        expose:
            - "38333"
            - "38332"

    faucet:
        container_name: faucet
        build:
            context: faucet
        image: faucet_img
        port:
            - "5000:5000"
        expose:
            - "5000"

		EOF
        
    else
        
        cat <<- EOF >> $FILE
    btc_sig_node:
        container_name: btc_sig_node
        build:
            context: bitcoind_signet_node
        image: bitcoind_signet_node
        volumes:
            - shared_vol_btc:/bitcoind
        ports:
            - "38333:38333"
            - "38332:38332"
        expose:
            - "38333"
            - "38332"

		EOF
    fi
    
    cat <<- EOF >> $FILE
    tor:
        container_name: tor
        build:
            context: tor
        image: tor_img
        ports:
            - "9050:9050"
            - "9051:9051"
        expose:
            - "9050"
            - "9051"


    # electrs:
    #     container_name: electrs
    #     build:
    #         context: electrs
    #     image: electrs_img
    #     volumes:
    #     - shared_vol_btc:/bitcoind
    #     ports:
    #         - "60601:60601"
    #     expose:
    #         - "60601"



    # nginx:
    #     container_name: nginx
    #     build:
    #         context: nginx
    #     image: nginx_img
    #     ports:
    #         - "60602:60602"
    #     expose:
    #         - "60602"


    c-lightning:
        container_name: c-lightning
        build:
            context: c-lightning
        image: core_lightning
        volumes:
            - shared_vol_ln:/lightningd
        ports:
            - "39735:39735"
            - "3092:3092"
        expose:
            - "39735"
            - "3092"


    lnbits:
        container_name: lnbits
        build:
            context: lnbits
        image: lnbits_img
        volumes:
            - shared_vol_ln:/lightningd
        ports:
            - "7000:7000"
        expose:
            - "7000"


    rtl:
        container_name: rtl
        build:
            context: rtl
        image: rtl_img
        volumes:
            - shared_vol_ln:/lightningd
        ports:
            - "3000:3000"
        expose:
            - "3000"


	EOF
    
    
    for i in $(seq "$node_count"); do
        cat <<- EOF >> $FILE

    c-lightning-$i:
        container_name: c-lightning-$i
        build:
            context: c-lightning
        image: core_lightning
        environment:
            CL_PORT: $(( 39735 + i * 101))
            CLN_PORT: $(( 3092 + i * 101))
            CLN_DOCPORT: $(( 4091 + i * 101))
        volumes:
            - shared_vol_ln-$i:/lightningd
        ports:
            - "$(( 39735 + i * 101)):$(( 39735 + i * 101))"
            - "$(( 3092 + i * 101)):$(( 3092 + i * 101))"
            - "$(( 4091 + i * 101)):$(( 4091 + i * 101))"
        expose:
            - "$(( 39735 + i * 101))"
            - "$(( 3092 + i * 101))"
            - "$(( 4091 + i * 101))"
		EOF
    done
    
    cat <<- EOF >> $FILE
volumes:
    shared_vol_btc:
    shared_vol_ln:
	EOF
    
    for j in $(seq "$node_count"); do
        cat <<- EOF >> $FILE
    shared_vol_ln-$j:
		EOF
    done
    
}

start_with(){
    if [ -z "$1" ]; then
        node_count=0
    else
        node_count=$1
    fi
    
    if [ -z "$2" ]; then
        usage="miner"
    else
        usage=$2
    fi
    
    # start_ln $node_count
    
    set_ports $node_count
    
    create_docker_compose $node_count $usage
}

function connect() {
    if [ "$#" -ne 2 ]; then
        echo "Error: Exactly two arguments are required."
        return 1
    fi
    
    if [ $1 = 0 ]; then
        PREFIX1=""
    else
        PREFIX1="-$1"
    fi
    
    if [ $2 = 0 ]; then
        PREFIX2=""
    else
        PREFIX2="-$2"
    fi
    
    first_node_info=$(docker exec c-lightning$PREFIX1 lightning-cli --lightning-dir=/lightningd getinfo)
    first_node_id=$(echo $first_node_info | jq -r ".id")
    first_node_addr=$(echo $first_node_info | jq -r ".address[].address")
    first_node_port=$(echo $first_node_info | jq -r ".address[].port")
    
    docker exec c-lightning$PREFIX2 lightning-cli --lightning-dir=/lightningd connect $first_node_id@$first_node_addr:$first_node_port
}


function open_channel(){
    if [ "$#" -ne 3 ]; then
        echo "Error: Exactly three arguments are required."
        return 1
    fi
    
    if [ $1 = 0 ]; then
        PREFIX1=""
    else
        PREFIX1="-$1"
    fi
    
    if [ $2 = 0 ]; then
        PREFIX2=""
    else
        PREFIX2="-$2"
    fi
    
    
    FUND1=$(docker exec c-lightning$PREFIX1 lightning-cli --lightning-dir=/lightningd listfunds | jq -r ".outputs" | jq "length<=0")
    FUND2=$(docker exec c-lightning$PREFIX2 lightning-cli --lightning-dir=/lightningd listfunds | jq -r ".outputs" | jq "length<=0")
    CLN_ID1=$(docker exec c-lightning$PREFIX1 lightning-cli --lightning-dir=/lightningd getinfo | jq -r ".id")
    CLN_ID2=$(docker exec c-lightning$PREFIX2 lightning-cli --lightning-dir=/lightningd getinfo | jq -r ".id")
    
    ALREADY_OPENED=$(docker exec c-lightning$PREFIX1 lightning-cli --lightning-dir=/lightningd listpeerchannels | jq --arg CLN_ID2 $CLN_ID2 '.channels[] | select(.peer_id == $CLN_ID2)')
    if [[ $ALREADY_OPENED == true ]]; then
        AMOUNT=$(docker exec c-lightning$PREFIX1 lightning-cli --lightning-dir=/lightningd listpeerchannels | jq  --arg CLN_ID $CLN_ID1 '.channels[] | select(.peer_id == $CLN_ID1) | .total_msat')
        echo "Channel altready opened between $1 and $2 of $AMOUNT"
    else
        connect $1 $2 > /dev/null 2>&1
        if [[ $FUND1 == false ]]; then
            docker exec c-lightning$PREFIX1 lightning-cli --lightning-dir=/lightningd fundchannel $CLN_ID2 $3
            elif [[ $FUND2 == false ]]; then
            docker exec c-lightning$PREFIX2 lightning-cli --lightning-dir=/lightningd fundchannel $CLN_ID1 $3
        else
            echo "Not enough funds in nodes $1 and $2"
        fi
    fi
}