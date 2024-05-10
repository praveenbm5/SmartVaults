#!/bin/bash

script_name=$(basename "$0")
echo "Logging all output to logs/$script_name.log"

read -n 1 -s -r -p "Press any key to continue..."
echo ""

exec &> >(tee "logs/$script_name.log")

#####################################

source SmartVault.Demo.Initialize_RegTest_Network.sh

#####################################

source SmartVault.Demo.Setup.sh

#######################################
#
# Now the User is intiating Recovery
# in coordination with Ledger
# as his private-key is lost
# (Requires only Ledger's private-key)
#
#######################################

echo "-------------"
echo "Simulating the recovery process by User"
echo "in coordintion with Ledger"
echo "as his private-key is lost!"
echo "(Requires only Ledger's private-key)"
echo "-------------"

read -n 1 -s -r -p "Press any key to start recovery..."
echo ""

echo "-------------"
echo "Ledger signs the Partially Signed"
echo "Provisional Tx received from User"
echo "with its Private Key"
echo "-------------"

echo "Done"

## Reusing the previously computed LedgerSignatureProv to reduce 
## code redundancy for this POC

echo "-------------"
echo "Ledger's Private Key Generated Signature for Provisional Tx:"
echo "-------------"

echo $LedgerSignatureProv

echo "-------------"
echo "Fully Signed Provisional Tx :"
echo "-------------"

ProvTxSigned=$(python3 helpers/add_witness.py $ProvTx $LedgerSignatureProv $UserSignatureProv $DepositTxRedeemScript)
echo $ProvTxSigned

echo "-------------"
echo "Checking Fully Signed Provisional Tx :"
echo "-------------"

bitcoin-cli decoderawtransaction "$ProvTxSigned"

ProvTxId=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq -r '.txid')
ProvTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq '.vout[0] | .scriptPubKey.hex')
ProvTxAmount=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq '.vout[0] | .value')

#######################################
#
# Ledger will broadcast ProvTx
# to intiative recovery
#
#######################################

echo "-------------"
echo "Vaildate Fully Signed Provisional Tx"
echo "-------------"

#Test ProvTx
bitcoin-cli testmempoolaccept "[ \"$ProvTxSigned\" ]"

echo "-------------"
echo "Broadcast Fully Signed Provisional Tx"
echo "-------------"

#Broadcast ProvTx
bitcoin-cli sendrawtransaction "$ProvTxSigned" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Generating Block to confirm Provisional Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$UserAdrs" >/dev/null 2>&1

echo "Done"

echo "-------------"
echo "Provisional Tx Block:"
echo "-------------"

ProvTxBlock=$(bitcoin-cli getbestblockhash)
echo $ProvTxBlock

echo "-------------"
echo "Confirmed Provisional Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$ProvTxId" true "$ProvTxBlock"

#########################################
#
# User will create a Recovery Tx
# to complete recovery
# 
#########################################

echo "-------------"
echo "Simulating Recovery by User using" # [Customize This in accordance with Option]
echo "***Option 2*** of Provisonal Tx"
echo "(Using just Ledger's Private Key)"
echo "-------------"

echo "Recovery Process - Start"

echo "-------------"
echo "User creates the Recovery Tx"
echo "-------------"

# [Customize this in accordance with Option]
read -r -d '' RecovTxInputs <<-EOM
    [
        {
            "txid": "$ProvTxId",
            "vout": 0,
            "sequence": $LedgerDelay
        }
    ]
EOM

read -r -d '' RecovTxOutputs <<-EOM
    [
        {
            "$UserAdrs": 49.997
        }
    ]
EOM

RecovTx=$(bitcoin-cli createrawtransaction "$RecovTxInputs" "$RecovTxOutputs")
echo "Done"

echo "-------------"
echo "Unsigned Recovery Tx"
echo "-------------"

echo $RecovTx

echo "-------------"
echo "Checking Unsigned Recovery Tx"
echo "-------------"

bitcoin-cli decoderawtransaction "$RecovTx"

echo "-------------"
echo "Simulating the transfer of Unsigned Recovery Tx"
echo "from User to Ledger!"
echo "-------------"

echo "[U] --> Unsigned Provisional Tx --> [L]"

echo "-------------"
echo "Ledger Signs the Recovery Tx"
echo "-------------"

LedgerSignatureRecov=$(python3 helpers/sign_tx.py $RecovTx 0 $ProvTxAmount $ProvTxRedeemScript $LedgerPriv SIGHASH_ALL True)

echo "-------------"
echo "Recovery Tx - Ledger's Signature"
echo "-------------"
echo $LedgerSignatureRecov

echo "-------------"
echo "Fully Signed Recovery Tx:"
echo "-------------"

# [Customize This in accordance with Option]
RecovTxSigned=$(python3 helpers/add_witness.py $RecovTx $LedgerSignatureRecov 01 $ProvTxRedeemScript)

echo $RecovTxSigned

echo "-------------"
echo "Checking Fully Signed Recovery Tx:"
echo "-------------"

bitcoin-cli decoderawtransaction "$RecovTxSigned"

RecovTxID=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq -r '.txid')
RecovTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq '.vout[0] | .scriptPubKey.hex')

#######################################
#
# Ledger will broadcast RecovTx
# to intiative recovery
#
#######################################

echo "-------------"
echo "Creating Blocks to satisfy Timelocks"
echo "-------------"

#Create blocks to unlock the timelock [Customize This in accordance with Option]
bitcoin-cli generatetoaddress $LedgerDelay "$UserAdrs" >/dev/null 2>&1

echo "Done"

echo "-------------"
echo "Vaildating Recovery Tx"
echo "-------------"

bitcoin-cli testmempoolaccept "[ \"$RecovTxSigned\" ]"

echo "-------------"
echo "Broadcasting Recovery Tx"
echo "-------------"

bitcoin-cli sendrawtransaction "$RecovTxSigned" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Generating Block to confirm Recovery Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$UserAdrs" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Recovery Tx Block ID:"
echo "-------------"
RecovTxBlock=$(bitcoin-cli getbestblockhash)
echo $RecovTxBlock

echo "-------------"
echo "Confirmed Recovery Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$RecovTxID" true "$RecovTxBlock"

echo "-------------"
echo "***Recovery Complete!***"
echo "-------------"

##############################

echo "-------------"
echo "Stopping Bitcoind"
echo "-------------"

#stop bitcoind
bitcoin-cli stop
