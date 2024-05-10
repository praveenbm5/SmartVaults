"""
Adds witness data to Bitcoin Tx using Python Cryptos library

Usage: python3 add_witness.py [tx_hex] [witness-1] [witness-2] .. [witness-n]

Requirements:

pip install cryptos

https://github.com/primal100/pybitcointools

cryptos library is a fork of original bitcoin library by Vitalik Buterin(now abandoned) 

"""

from cryptos import *
import sys, json, argparse

def main():
    parser = argparse.ArgumentParser(description="Add custom witness data to a Bitcoin transaction. Usage: python3 add_witness.py [tx_hex] [witness-1] [witness-2] .. [witness-n]")
    parser.add_argument("tx_hex", help="Raw transaction hex string")
    parser.add_argument("custom_witness_data", nargs="+", help="Custom witness elements provided as arbitrary number of arguements")

    args = parser.parse_args()
    
    # Create a transaction object from the raw hex
    tx = deserialize(args.tx_hex)
    print("Unsigned Tx", file=sys.stderr)
    print(json.dumps(tx, indent=4), file=sys.stderr)

    """
    witness array has objects with 2 properties

    number: number of elements in the witness stack
    scriptCode: witness stack serialized as element size in bytes (hex) followed by element data (hex) one after the other

    Ex:

    4730440220588bce5d1a6a277ea402c4b1cdc6e4e3e4c3137e9b092e2ac6c5ec35a8e2bff5022071ab43e1391d897094885e4835c57f283de1628fbb13268c7cfcc3b7cd9794c0012103106d4795e3772fd742ba1b9b4b049a7e988e85d0340c5dd69277e3f0eea3ed9b

    47 (71 in hex)
    30440220588bce5d1a6a277ea402c4b1cdc6e4e3e4c3137e9b092e2ac6c5ec35a8e2bff5022071ab43e1391d897094885e4835c57f283de1628fbb13268c7cfcc3b7cd9794c001
    21 (33 in hex)
    03106d4795e3772fd742ba1b9b4b049a7e988e85d0340c5dd69277e3f0eea3ed9b
    """

    # Add custom witness data
    custom_witness_data = ""
    witness_size = 0
    
    for data in args.custom_witness_data:
        witness_size += 1

        if isinstance(data, int):
            data = f'{data:x}'
            if len(data) % 2 != 0 and int(data) != 0:
                data = '0' + data        

        length = int(len(data)/2)
        length = f'{length:x}'
        if len(length) % 2 != 0 and int(data) != 0:
            length = '0' + length  

        custom_witness_data += length
        custom_witness_data += data

    tx["witness"] = [{"number": witness_size, "scriptCode" : custom_witness_data}]
    
    # https://bitcoin.stackexchange.com/questions/84041/whats-the-segwit-transaction-serialization-flag-field-for
    tx["marker"] = 0 #Bip144
    tx["flag"] = 1 #Bip144

    # Serialize the transaction
    tx_hex_witness = serialize(tx)
    print("Signed Tx", file=sys.stderr)
    print(json.dumps(tx, indent=4), file=sys.stderr)
    
    print(tx_hex_witness)

if __name__ == "__main__":
    main()


