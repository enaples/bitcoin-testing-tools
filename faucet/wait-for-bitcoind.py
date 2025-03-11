import time
import requests
from app import api
import os
BTC_HOST = os.environ.get("BTC_HOST", "localhost")

print("Waiting for bitcoind to be fund...")
url = f"http://{BTC_HOST}:38332/"
auth = ("bitcoin", "bitcoin")
headers = {"content-type": "text/plain;"}

while True:
    time.sleep(5)
    try:
        response = requests.post(
            url,
            auth=auth,
            headers=headers,
            json={"jsonrpc": "1.0",
                  "id": "faucet",
                  "method": "getblockchaininfo",
                  "params": []})
        result = response.json()
        if result["result"]["blocks"] > 100:
            print("bitcoind is ready to spend coinbase outputs")
            break
    except Exception as e:
        print(e)
        time.sleep(1)

if __name__ == '__main__':
    api.run(debug=True, host="0.0.0.0")
