"""
Signs Bitcoin Txs using provided private-key and data

Usage:

python3 sign_tx.py [tx_hex] [input] [value] [script] [private_key] [SIGHASH_ALL/SIGHASH_SINGLE] [segwit]

Example:

$ python3 sign_tx.py \
02000000010e2dfb9476c26f45168a5b7ae9812614a255c1e53104f5ecce64cccccf9d691b0000000000fdffffff01c0e4022a010000002200205e208dd78133e38c661ac66e747f5b377a20028795bf1639acf28a643e2fc2e800000000 \
0 \
4999900000 \
21026232c28fadf5bc5562444f4a64b681bc80c9b71c43606669f0841c01c4ee6a5a21034d295a062d0cb5fa923ce67703943def1584bc7a9099596e9920af4c86f0412100547a547a527152ae \
cTwDQLZia1oRq7cMFRY6kFprKjbibNASwt4wJXJkyaLGzPSqvGAS \
SIGHASH_ALL \
True

"""
from cryptos import *
import sys, json, argparse

def sign_tx(tx, input, script, private_key, hascode, segwit, ):
    # Sign input
    signature = multisign(tx, input, script, private_key, hascode, segwit)  # Sign all inputs with the provided private key

    return signature

def main():
    parser = argparse.ArgumentParser(description="Sign inputs of a Bitcoin transaction. Usage: python3 sign_tx.py [tx_hex] [input] [value] [script] [private_key] [SIGHASH_ALL/SIGHASH_SINGLE] [segwit]")
    parser.add_argument("tx_hex", help="Raw transaction hex string")
    parser.add_argument("input", help="Input index to sign")
    parser.add_argument("value", help="Amount in sats")
    parser.add_argument("script", help="Redeem/Witness Script")
    parser.add_argument("private_key", help="Private key for signing transaction inputs.")
    parser.add_argument("hashcode", help="SIGHASH_ALL, SIGHASH_SINGLE, etc.")
    parser.add_argument("segwit", help="Is segwith - True or False")

    args = parser.parse_args()
    
    # Deserialize the transaction from the raw hex
    tx = deserialize(args.tx_hex)
    tx["ins"][int(args.input)]["value"] = int(float(args.value)*10**8)
    print("Original Tx:", file=sys.stderr)
    print(json.dumps(tx, indent=4), file=sys.stderr)

    # Sign the transaction inputs with the provided private keys
    signature = sign_tx(tx, int(args.input), args.script, args.private_key, eval(args.hashcode), True if args.segwit == "True" else False)

    print("Signature:", file=sys.stderr)
    print(signature, file=sys.stderr)
    
    # Output the final transaction hex with signatures
    print(signature)

if __name__ == "__main__":
    main()