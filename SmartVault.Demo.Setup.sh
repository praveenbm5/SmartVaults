#!/bin/bash

#####################################

bitcoin-cli -named createwallet wallet_name="POC" descriptors=false >/dev/null 2>&1

#User - Keys

#UserPriv="cUrRAGYGV9Lj7yk7qFMZxxVeFTFqgt6BuJheb4EgVMafHef8f9p9"
#UserPub="023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416"

echo "-------------"
echo "Generating User's Priv-Pub-Addr"
echo "-------------"

UserAdrs=$(bitcoin-cli getnewaddress)
UserPriv=$(bitcoin-cli dumpprivkey "$UserAdrs")
UserPub=$(bitcoin-cli getaddressinfo "$UserAdrs" | jq -r .pubkey)

echo "Private Key: $UserPriv"
echo "Public Key: $UserPub"
echo "Address: $UserAdrs"

#Ledger - Keys

#LedgerPriv="cS71P5KPZbgGYhkXfTomFNYxq2NRccQb8Zkw3XEQkMVnQdSvAYQn"
#LedgerPub="03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b"

echo "-------------"
echo "Generating Ledger's Priv-Pub-Addr"
echo "-------------"

LedgerAdrs=$(bitcoin-cli getnewaddress)
LedgerPriv=$(bitcoin-cli dumpprivkey "$LedgerAdrs")
LedgerPub=$(bitcoin-cli getaddressinfo "$LedgerAdrs" | jq -r .pubkey)

echo "Private Key: $LedgerPriv"
echo "Public Key: $LedgerPub"
echo "Address: $LedgerAdrs"

#####################################

echo "-------------"
echo "Generating blocks to bootstrap Bitcoin RegTest Blockchain"
echo "-------------"

bitcoin-cli generatetoaddress 101 "$UserAdrs" >/dev/null 2>&1
#bitcoin-cli importaddress "$UserAdrs"
echo "Done"

utxo_txid_1=$(bitcoin-cli listunspent | jq -r '.[0] | .txid')
utxo_vout_1=$(bitcoin-cli listunspent | jq -r '.[0] | .vout')

# Create Deposit Transaction

echo "-------------"
echo "Deposit Tx Redeem Script"
echo "-------------"

#####################################################################
# Deposit Transaction - Script / Smart Contract - Ivy Lang
#
# contract Deposit(
#   user: PublicKey,
#   ledger: PublicKey,
#   val: Value
# ) 
# {
#   clause spend(userSig: Signature, ledgerSig: Signature) {
#     verify checkMultiSig([user, ledger], [userSig, ledgerSig])
#     unlock val
#   }
# }
#####################################################################

#DepositTxRedeemScript="2103cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b21023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f41600547a547a527152ae"
DepositTxRedeemScript="21${LedgerPub}21${UserPub}00547a547a527152ae"

echo $DepositTxRedeemScript

echo "-------------"
echo "Checking Deposit Tx Redeem Script"
echo "-------------"

bitcoin-cli decodescript "$DepositTxRedeemScript"

# bitcoin-cli decodescript $DepositTxRedeemScript
# {
#   "asm": "03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b 023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416 0 4 OP_ROLL 4 OP_ROLL 2 OP_2ROT 2 OP_CHECKMULTISIG",
#   "type": "nonstandard",
#   "p2sh": "2N67fe2umeVqEvKP9pDho7U44WFEB6qwSkf",
#   "segwit": {
#     "asm": "0 60ab4558df4445fdcae68eba8810c6febcae467e88e2a1ac0f1c2169d449a759",
#     "hex": "002060ab4558df4445fdcae68eba8810c6febcae467e88e2a1ac0f1c2169d449a759",
#     "reqSigs": 1,
#     "type": "witness_v0_scripthash",
#     "addresses": [
#       "bcrt1qvz452kxlg3zlmjhx36agsyxxl672u3n73r32rtq0rsskn4zf5avs0ye2zj"
#     ],
#     "p2sh-segwit": "2NEe9XKk3mDrc6FEZvoa19KGmE55bVpKb2L"
#   }
# }

DepositTxOutputAddress=$(bitcoin-cli decodescript "$DepositTxRedeemScript" | jq -r .segwit.address)

echo "-------------"
echo "Deposit Tx - Script to Address"
echo "-------------"

echo $DepositTxOutputAddress

read -r -d '' DepositTxInputs <<-EOM
    [
        {
            "txid": "$utxo_txid_1",
            "vout": $utxo_vout_1
        }
    ]
EOM

read -r -d '' DepositTxOutputs <<-EOM
    [
        {
            "$DepositTxOutputAddress": 49.999
        }
    ]
EOM

echo "-------------"
echo "Creating Unsigned Deposit Tx"
echo "-------------"

DepositTx=$(bitcoin-cli createrawtransaction "$DepositTxInputs" "$DepositTxOutputs")

echo "Done"

echo "-------------"
echo "Unsigned Deposit Tx"
echo "-------------"

echo $DepositTx

echo "-------------"
echo "Checking Unsigned Deposit Tx"
echo "-------------"

bitcoin-cli decoderawtransaction "$DepositTx"

echo "-------------"
echo "Signing the Deposit Tx"
echo "-------------"

DepositTxSigned=$(bitcoin-cli signrawtransactionwithkey "$DepositTx"  "[\"$UserPriv\"]" | jq -r '.hex')
echo "Done"

echo "-------------"
echo "Signed Deposit Tx"
echo "-------------"

echo $DepositTxSigned

echo "-------------"
echo "Checking Signed Deposit Tx"
echo "-------------"

bitcoin-cli decoderawtransaction "$DepositTxSigned"

DepositTxID=$(bitcoin-cli decoderawtransaction "$DepositTxSigned" | jq -r '.txid')
DepositTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$DepositTxSigned" | jq '.vout[0] | .scriptPubKey.hex')
DepositTxAmount=$(bitcoin-cli decoderawtransaction "$DepositTxSigned" | jq '.vout[0] | .value')

echo "-------------"
echo "Provsional Tx Redeem Script"
echo "-------------"

#####################################################################
# Provisional Transaction - Script / Smart Contract - Ivy Lang
#
# contract SmartVault(
#   user: PublicKey,
#   ledger: PublicKey,
#   userDelay: Duration,
#   ledgerDelay: Duration,
#   val: Value
# ) 
# {  
#   /* Option : 1 [1000] */
#   clause User(userSig: Signature) {
#     verify checkSig(user, userSig)
#     verify older(userDelay)
#     unlock val
#   }
#   /* Option : 2 [5000] */
#   clause Ledger(ledgerSig: Signature) {
#     verify checkSig(ledger, ledgerSig)
#     verify older(ledgerDelay)
#     unlock val
#   }
#   /* Option : 3 */
#   clause MultiSig(userSig: Signature, ledgerSig: Signature) {
#     verify checkMultiSig([user, ledger], [userSig, ledgerSig])
#     unlock val
#   }
# }
#####################################################################

UserDelay=1000
echo "Setting Option 1 (User Private-Key Only) Delay to $UserDelay"
UserDelayCoded=$(python3 helpers/number_coding.py --encode $UserDelay) #500=f401

LedgerDelay=5000
echo "Setting Option 2 (Ledger Private-Key Only) Delay to $LedgerDelay"
LedgerDelayCoded=$(python3 helpers/number_coding.py --encode $LedgerDelay) #2500=c409

echo "Hex:"
ProvTxRedeemScript="02${LedgerDelayCoded}02${UserDelayCoded}21${LedgerPub}21${UserPub}54795287637b757b757b7500547a547a527152ae67547a6375777b7cadb2755167777b757b7cadb275516868"

echo $ProvTxRedeemScript

echo "-------------"
echo "Checking Provisional Tx Redeem Script"
echo "-------------"

bitcoin-cli decodescript "$ProvTxRedeemScript"

# Ref:
# bitcoin-cli decodescript $ProvTxRedeemScript
# {
#   "asm": "2500 500 03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b 023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416 4 OP_PICK 2 OP_EQUAL OP_IF OP_ROT OP_DROP OP_ROT OP_DROP OP_ROT OP_DROP 0 4 OP_ROLL 4 OP_ROLL 2 OP_2ROT 2 OP_CHECKMULTISIG OP_ELSE 4 OP_ROLL OP_IF OP_DROP OP_NIP OP_ROT OP_SWAP OP_CHECKSIGVERIFY OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ELSE OP_NIP OP_ROT OP_DROP OP_ROT OP_SWAP OP_CHECKSIGVERIFY OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ENDIF OP_ENDIF",
#   "type": "nonstandard",
#   "p2sh": "2NALhW1somHP9ifDFc6YjzbTPfUB8dbgNuL",
#   "segwit": {
#     "asm": "0 20d29d4c1268eef833fd1d9a25fc2881dd36ab55c92e56f10a0e81b557e8ef95",
#     "hex": "002020d29d4c1268eef833fd1d9a25fc2881dd36ab55c92e56f10a0e81b557e8ef95",
#     "reqSigs": 1,
#     "type": "witness_v0_scripthash",
#     "addresses": [
#       "bcrt1qyrff6nqjdrh0svlarkdztlpgs8wnd264eyh9dug2p6qm24lga72srtvven"
#     ],
#     "p2sh-segwit": "2N63Rp9WJEvkVviV6Hbx1qmV7JaKv2jZAyU"
#   }
# }

echo "-------------"
echo "Provisional Tx - Script to Address"
echo "-------------"

ProvTxOutputAddress=$(bitcoin-cli decodescript "$ProvTxRedeemScript" | jq -r .segwit.address)

echo $ProvTxOutputAddress

###########

read -r -d '' ProvTxInputs <<-EOM
    [
        {
            "txid": "$DepositTxID",
            "vout": 0
        }
    ]
EOM

read -r -d '' ProvTxOutputs <<-EOM
    [
        {
            "$ProvTxOutputAddress": 49.998
        }
    ]
EOM

echo "-------------"
echo "Creating Unsigned Provisional Tx"
echo "-------------"

ProvTx=$(bitcoin-cli createrawtransaction "$ProvTxInputs" "$ProvTxOutputs")

echo $ProvTx

echo "-------------"
echo "Checking Unsigned Prov Tx Created by User"
echo "-------------"

bitcoin-cli decoderawtransaction "$ProvTx"

echo "-------------"
echo "Simulating the transfer of Unsigned Provisional Tx copy"
echo "to Ledger!"
echo "-------------"

echo "[U] --> Unsigned Provisional Tx --> [L]"

echo "-------------"
echo "Ledger signs the Unsigned Provisional Tx"
echo "with his Private Key"
echo "-------------"

LedgerSignatureProv=$(python3 helpers/sign_tx.py $ProvTx 0 $DepositTxAmount $DepositTxRedeemScript $LedgerPriv SIGHASH_ALL True)

echo "-------------"
echo "ProvTx - Ledger's Signature"
echo "-------------"

echo $LedgerSignatureProv

echo "-------------"
echo "Simulating the transfer of Partially Signed Provisional Tx"
echo "to User!"
echo "-------------"

echo "[L] --> Partially Signed Provisional Tx --> [U]"

####################################

echo "-------------"
echo "User signs the Unsigned Provisional Tx"
echo "with his Private Key"
echo "-------------"

UserSignatureProv=$(python3 helpers/sign_tx.py $ProvTx 0 $DepositTxAmount $DepositTxRedeemScript $UserPriv SIGHASH_ALL True)

echo "-------------"
echo "ProvTx - User Signature"
echo "-------------"

echo $UserSignatureProv

echo "-------------"
echo "Simulating the transfer of Partially Signed Provisional Tx copy"
echo "to Ledger!"
echo "-------------"

echo "[U] --> Partially Signed Provisional Tx --> [L]"

#######################################
#
# Deositor will broadcast DepositTx
# after receiving the
# Partially Signed Prov. Tx with
# Ledger's signature already added to it
#
#######################################

echo "-------------"
echo "User signs & broadcasts the Deposit Tx"
echo "after receiving the Partially signed Provisional Tx"
echo "-------------"

#Broadcast DepositTx
bitcoin-cli sendrawtransaction "$DepositTxSigned" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Generating Block to confirm the Deposit Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$UserAdrs" >/dev/null 2>&1

DepositTxBlock=$(bitcoin-cli getbestblockhash)

echo "Deposit Tx Block: $DepositTxBlock"

echo "-------------"
echo "Confirmed Deposit Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$DepositTxID" true "$DepositTxBlock"

echo "-------------"
echo "***Smart Vault Setup Complete!***"
echo "-------------"

#####################################

echo "User is now assured of his"
echo "Bitcoin's safety and security"
echo "as his Bitcoin is now in Joint Custody and"
echo "rest everything is managed using the"
echo "Partially Signed Provisional Transactions"
echo "with User and Ledger after the Smart Vault setup!"
echo "-------------"

read -n 1 -s -r -p "Press any key to continue..."
echo ""