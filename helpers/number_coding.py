#!/usr/bin/env python3
import sys, argparse

def encode_compact_integer(number):
    """
    Encodes an integer using Bitcoin's compact integer format.
    """
    if number < 0xfd:
        return number.to_bytes(1, 'little')
    elif number <= 0xffff:
        return number.to_bytes(2, 'little')
    elif number <= 0xffffffff:
        return number.to_bytes(4, 'little')
    else:
        return number.to_bytes(8, 'little')


def decode_compact_integer(encoded_bytes):
    """
    Decodes a compact integer back to its original value.
    """
    if encoded_bytes[0] & 0x80:
        return int.from_bytes(encoded_bytes, byteorder='little', signed=True)
    else:
        return int.from_bytes(encoded_bytes, byteorder='little')

def main():
    parser = argparse.ArgumentParser(description="Bitcoin Compact Integer Tool")
    
    parser.add_argument("--encode", action="store_true", help="Encode the given number")
    parser.add_argument("--decode", action="store_true", help="Decode the given bytes")

    parser.add_argument("number", help="Integer to encode or decode")

    args = parser.parse_args()

    if args.encode:
        encoded_bytes = encode_compact_integer(int(args.number))
        print(f"Encoded bytes (hex): {encoded_bytes.hex()}", file=sys.stderr)
        print(encoded_bytes.hex())
    elif args.decode:
        try:
            decoded_number = decode_compact_integer(bytes.fromhex(args.number))
            print(f"Decoded number: {decoded_number}", file=sys.stderr)
            print(decoded_number)
        except ValueError:
            print("Invalid input. Please provide valid hexadecimal bytes.")
    else:
        print("Please specify either --encode or --decode.")

if __name__ == "__main__":
    main()
