#!/bin/bash
set -Eeuo pipefail

cd /RTL &&
  git checkout v${RTL_VER} &&
  git verify-tag v${RTL_VER} &&
  npm install --omit=dev --legacy-peer-deps

echo "CLN_REST_HOST is set to: ${CLN_REST_HOST}"
echo "BTC_HOST is set to: ${BTC_HOST}"

# Create RTL config file
if [ -f "/RTL/RTL-Config.json" ]; then
  echo "RTL-Config.json already exists, skipping creation"
else
  echo "Creating RTL-Config.json"

  cat <<-EOF >"/RTL/RTL-Config.json"
{
  "multiPass": "password",
  "port": "3000",
  "SSO": {
    "rtlSSO": 0,
    "rtlCookiePath": "",
    "logoutRedirectLink": ""
  },
  "nodes": [
    {
      "index": 1,
      "lnNode": "CLN Node",
      "lnImplementation": "CLN",
      "Authentication": {
        "macaroonPath": "/lightningd",
        "configPath": "/lightningd/config"
      },
      "Settings": {
        "userPersona": "OPERATOR",
        "themeMode": "DAY",
        "themeColor": "INDIGO",
        "fiatConversion": true,
        "currencyUnit": "EUR",
        "logLevel": "ERROR",
        "lnServerUrl": "http://$CLN_REST_HOST:$CLN_REST_PORT",
        "enableOffers": true
      }
    }
  ],
  "defaultNodeIndex": 1
} 
EOF

fi

source /RTL/wait-for-bitcoind.sh

exec "$@"
