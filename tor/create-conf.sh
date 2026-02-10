#!/bin/bash
set -Eeuo pipefail

cat <<- EOF_HEADER > "/etc/tor/torrc"
ControlPort $(hostname -f):9051
SOCKSPort $(hostname -f):9050
CookieAuthentication 1
HashedControlPassword 16:E380FE879AE8380E60C786B3908666C620ECA8D7DAA1AB44B058E3BF64
CookieAuthFileGroupReadable 1
CookieAuthFile /var/lib/tor/control_auth_cookie
EOF_HEADER

echo "Base torrc configuration written to /etc/tor/torrc"
