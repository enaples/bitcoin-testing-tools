cat <<- EOF > /etc/tor/torrc
ControlPort 0.0.0.0:9051
SOCKSPort 0.0.0.0:9050
CookieAuthentication 1
HashedControlPassword 16:E380FE879AE8380E60C786B3908666C620ECA8D7DAA1AB44B058E3BF64
CookieAuthFileGroupReadable 1
# Electrum server
HiddenServiceDir /var/lib/tor/hidden_service_electrs/
HiddenServiceVersion 3
HiddenServicePort 60602 $(nslookup nginx | awk '/^Address: / { print $2 }'):60602
# Lightning-REST
HiddenServiceDir /var/lib/tor/hidden_service_cln_rest/
HiddenServiceVersion 3
HiddenServicePort 8080 $(nslookup c-lightning-rest | awk '/^Address: / { print $2 }'):3092
# Faucet
HiddenServiceDir /var/lib/tor/hidden_service_faucet/
HiddenServiceVersion 3
HiddenServicePort 5050 $(nslookup faucet | awk '/^Address: / { print $2 }'):5000
# Hidden service LNbits
HiddenServiceDir /var/lib/tor/hidden_service_lnbits/
HiddenServiceVersion 3
HiddenServicePort 7070 $(nslookup lnbits | awk '/^Address: / { print $2 }'):7000
EOF