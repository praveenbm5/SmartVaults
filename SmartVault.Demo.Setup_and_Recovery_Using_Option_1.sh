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
# as Ledger's private-key is lost or 
# is not responding to Vault Termination Requests
# (Requires only User's private-key)
#
#######################################

echo "-------------"
echo "Simulating the recovery process by User"
echo "when Ledger's private-key is lost or" 
echo "when Ledger is not responding to Vault Termination Requests"
echo "(Requires only User's private-key)"
echo "-------------"

read -n 1 -s -r -p "Press any key to start recovery..."
echo ""

echo "-------------"
echo "User signs the Partially Signed"
echo "Provisional Tx received from Ledger"
echo "with his Private Key"
echo "-------------"

echo "Done"

## Reusing the previously computed UserSignatureProv to reduce 
## code redundancy for this POC

echo "-------------"
echo "User's Private Key Generated Signature for Provisional Tx:"
echo "-------------"

echo $UserSignatureProv

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
# User will broadcast ProvTx
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
echo "Simulating Recovery by User Using" # [Customize This in accordance with Option]
echo "***Option 1*** of Provisonal Tx"
echo "(Using just User Private Key)"
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
            "sequence": $UserDelay
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
echo "User Signs the Recovery Tx"
echo "-------------"

UserSignatureRecov=$(python3 helpers/sign_tx.py $RecovTx 0 $ProvTxAmount $ProvTxRedeemScript $UserPriv SIGHASH_ALL True)

echo "-------------"
echo "Recovery Tx - User's Signature"
echo "-------------"
echo $UserSignatureRecov

echo "-------------"
echo "Fully Signed Recovery Tx:"
echo "-------------"

# [Customize This in accordance with Option]
# Do not use "00" to select the option for recovery. Use "0"
# https://bitcoin.stackexchange.com/questions/122822/why-is-my-p2wsh-op-if-notif-argument-not-minimal
RecovTxSigned=$(python3 helpers/add_witness.py $RecovTx $UserSignatureRecov 0 $ProvTxRedeemScript)

echo $RecovTxSigned

echo "-------------"
echo "Checking Fully Signed Recovery Tx:"
echo "-------------"

bitcoin-cli decoderawtransaction "$RecovTxSigned"

RecovTxID=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq -r '.txid')
RecovTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq '.vout[0] | .scriptPubKey.hex')

#######################################
#
# User will broadcast RecovTx
# to intiative recovery
#
#######################################

echo "-------------"
echo "Creating Blocks to satisfy Timelocks"
echo "-------------"

#Create blocks to unlock the timelock [Customize This in accordance with Option]
bitcoin-cli generatetoaddress $UserDelay "$UserAdrs" >/dev/null 2>&1
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
