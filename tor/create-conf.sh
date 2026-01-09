cat <<- 'EOF_HEADER' > /etc/tor/torrc
ControlPort 0.0.0.0:9051
SOCKSPort 0.0.0.0:9050
CookieAuthentication 1
HashedControlPassword 16:E380FE879AE8380E60C786B3908666C620ECA8D7DAA1AB44B058E3BF64
CookieAuthFileGroupReadable 1
EOF_HEADER

# Function to add hidden service if nslookup succeeds
add_hidden_service() {
    local service_name=$1
    local service_dir=$2
    local service_port=$3
    local target_port=$4
    
        cat <<- EOF >> /etc/tor/torrc
# $service_name
HiddenServiceDir /var/lib/tor/$service_dir/
HiddenServiceVersion 3
HiddenServicePort $service_port $service_name:$target_port
EOF
}

# Add hidden services only if nslookup succeeds
add_hidden_service "nginx" "hidden_service_electrs_romanz" "60602" "60602"
add_hidden_service "nginx" "hidden_service_electrs_liquid" "60702" "60702"
add_hidden_service "nginx" "hidden_service_electrs_blockstream" "60502" "60502"
add_hidden_service "cln" "hidden_service_cl_rest" "8080" "3010"
add_hidden_service "faucet" "hidden_service_faucet" "5050" "5000"
# add_hidden_service "lnbits" "hidden_service_lnbits" "7070" "7000"
add_hidden_service "mempool_web" "hidden_service_mempool" "80" "8080"