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
    
    if ip_address=$(nslookup "$service_name" 2>/dev/null | awk '/^Address: / { print $2; exit }') && [ -n "$ip_address" ]; then
        cat <<- EOF >> /etc/tor/torrc
# $service_name
HiddenServiceDir /var/lib/tor/$service_dir/
HiddenServiceVersion 3
HiddenServicePort $service_port $ip_address:$target_port
EOF
    fi
}

# Add hidden services only if nslookup succeeds
add_hidden_service "nginx" "hidden_service_electrs" "60603" "60603"
add_hidden_service "cln" "hidden_service_cl_rest" "8080" "3010"
add_hidden_service "faucet" "hidden_service_faucet" "5050" "5000"
add_hidden_service "lnbits" "hidden_service_lnbits" "7070" "7000"