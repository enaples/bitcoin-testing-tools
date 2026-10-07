from decimal import Decimal, InvalidOperation
import os

from flask import Flask, redirect, render_template, request, session, url_for
import requests

BTC_HOST = os.environ.get("BTC_HOST", "localhost")
RPC_URL = f"http://{BTC_HOST}:38332/"
RPC_AUTH = ("bitcoin", "bitcoin")

# /faucet always sends this amount: the other containers rely on it to fund themselves
LEGACY_AMOUNT = Decimal("1.5")
MIN_AMOUNT = Decimal("0.00001")
MAX_AMOUNT = Decimal(os.environ.get("FAUCET_MAX_AMOUNT", "10"))
PRESET_AMOUNTS = [Decimal(a) for a in ("0.1", "0.5", "1", "1.5", "5")]
# sat/vB, same fee rate the faucet has always paid
FEE_RATE = 5000.0
SATOSHI = Decimal("0.00000001")

api = Flask(__name__)
api.secret_key = os.urandom(32)


class RpcError(Exception):
    pass


def rpc(method, *params):
    try:
        response = requests.post(
            RPC_URL,
            auth=RPC_AUTH,
            headers={"content-type": "text/plain;"},
            json={"jsonrpc": "1.0", "id": "faucet", "method": method, "params": list(params)},
            timeout=30)
    except requests.RequestException:
        raise RpcError("bitcoind is not reachable, try again in a moment.")
    try:
        body = response.json(parse_float=Decimal)
    except ValueError:
        raise RpcError(f"bitcoind answered with HTTP {response.status_code}.")
    if body.get("error"):
        raise RpcError(body["error"]["message"])
    return body["result"]


def send(address, amount):
    return rpc("sendtoaddress", address, float(amount), "", "", False, True, None, "unset", None, FEE_RATE)


def format_btc(amount):
    text = format(amount.quantize(SATOSHI), "f").rstrip("0").rstrip(".")
    return text or "0"


def parse_amount(text):
    try:
        amount = Decimal(text)
    except InvalidOperation:
        raise ValueError("Enter the amount as a number, e.g. 0.5.")
    if not amount.is_finite():
        raise ValueError("Enter the amount as a number, e.g. 0.5.")
    if amount != amount.quantize(SATOSHI):
        raise ValueError("Bitcoin amounts have at most 8 decimal places.")
    if not MIN_AMOUNT <= amount <= MAX_AMOUNT:
        raise ValueError(f"Choose an amount between {format_btc(MIN_AMOUNT)} and {format_btc(MAX_AMOUNT)} BTC.")
    return amount


def render_page(status=200, **context):
    try:
        balance = "{:,.2f}".format(rpc("getbalance"))
        height = rpc("getblockcount")
    except RpcError:
        balance = height = None
    return render_template(
        "index.html",
        balance=balance,
        height=height,
        presets=[format_btc(a) for a in PRESET_AMOUNTS if a <= MAX_AMOUNT],
        min_amount=format_btc(MIN_AMOUNT),
        max_amount=format_btc(MAX_AMOUNT),
        legacy_amount=format_btc(LEGACY_AMOUNT),
        **context), status


@api.route("/", methods=["GET"])
def index():
    return render_page(sent=session.pop("sent", None))


@api.route("/", methods=["POST"])
def request_coins():
    address = request.form.get("address", "").strip()
    amount_text = request.form.get("amount", "").strip()
    try:
        if not address:
            raise ValueError("Enter the address that should receive the coins.")
        amount = parse_amount(amount_text)
        if not rpc("validateaddress", address)["isvalid"]:
            raise ValueError("That is not a valid signet address.")
        balance = rpc("getbalance")
        if amount > balance:
            raise ValueError(f"The faucet only has {format_btc(balance)} BTC left.")
        txid = send(address, amount)
    except ValueError as e:
        return render_page(400, error=str(e), address=address, amount=amount_text)
    except RpcError as e:
        return render_page(502, error=str(e), address=address, amount=amount_text)

    # Redirect after sending so a page refresh doesn't send the coins again
    session["sent"] = {"txid": txid, "amount": format_btc(amount), "address": address}
    return redirect(url_for("index"))


@api.route("/faucet", methods=["GET"])
def get_faucet():
    # Used by the other containers' funding scripts, which look for "Success" in the answer
    try:
        send(request.args.get("address", ""), LEGACY_AMOUNT)
    except RpcError as e:
        return f"Error: {e}", 500
    return "Success"
