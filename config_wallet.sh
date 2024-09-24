#!/bin/bash

NUM_WL=$(wc -l < $HOME/wl_formated.txt)

if ! grep -q "export NUM_WL=" ~/.bash_profile; then
    echo "export NUM_WL=$NUM_WL" >> ~/.bash_profile
fi

source ~/.bash_profile

mkdir -p allora_backup
mv $HOME/allora-huggingface-walkthrough/wl* $HOME/allora_backup/

# Doc file wl_formated.txt va tao cac file cau hinh
i=1
while IFS='|' read -r address mnemonic; do\
    mnemonic_clean=$(echo "$mnemonic" | tr -d '\n' | tr -s ' ')

    cat <<EOF > $HOME/allora-huggingface-walkthrough/wl_${i}_config.json

{
    "wallet": {
        "addressKeyName": "wl${i}",
        "addressRestoreMnemonic": "${mnemonic_clean}",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.5,
        "nodeRpc": "https://allora-rpc.testnet.allora.network/",
        "maxRetries": 2,
        "delay": 1,
        "submitTx": true
    },
    "worker": [
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 8,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BNB"
            }
        },
        {
            "topicId": 9,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ARB"
            }
        }
    ]
}
EOF
    i=$((i+1))
done < $HOME/wl_formated.txt

json_data=$(curl -s https://server-3.itrocket.net/testnet/allora/.rpc_combined.json)

endpoints=$(echo "$json_data" | jq -r '
  to_entries 
  | map(select(.value.tx_index == "on")) 
  | sort_by(.value.latest_block_height | tonumber) 
  | reverse 
  | .[:50] 
  | .[].key
  | "http://" + .
')

# Add more 10 row "https://allora-testnet-rpc.itrocket.net"
fixed_endpoints=$(for i in {1..15}; do echo "https://allora-testnet-rpc.itrocket.net"; done)

echo "$endpoints" > rpc_list.txt
echo "$fixed_endpoints" >> rpc_list.txt

