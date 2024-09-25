#!/bin/bash

git clone https://github.com/allora-network/allora-huggingface-walkthrough
cp /root/wl_formated.txt /root/allora-huggingface-walkthrough/wl_formated.txt

wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/app.py -O /root/allora-huggingface-walkthrough/app.py
wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/requirements.txt -O /root/allora-huggingface-walkthrough/requirements.txt

NUM_WL=$(wc -l < $HOME/wl_formated.txt)

if ! grep -q "export NUM_WL=" ~/.bash_profile; then
    echo "export NUM_WL=$NUM_WL" >> ~/.bash_profile
fi

source ~/.bash_profile

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
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
            "InferenceEndpoint": "http://inference:8000/inference/{Token}",
            "Token": "ETH"
            }
        },
        {
            "topicId": 3,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
            "InferenceEndpoint": "http://inference:8000/inference/{Token}",
            "Token": "BTC"
            }
        },
        {
            "topicId": 5,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 15,
            "parameters": {
            "InferenceEndpoint": "http://inference:8000/inference/{Token}",
            "Token": "SOL"
            }
        },
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
  | .[:80] 
  | .[].key
  | "http://" + .
')

random_endpoints=$(echo "$endpoints" | shuf -n 50)

fixed_endpoints=$(for i in {1..5}; do echo "https://allora-testnet-rpc.itrocket.net"; done)

# Ghi cả danh sách endpoint từ JSON và 10 dòng cố định vào file
echo "$endpoints" > rpc_list.txt
echo "$fixed_endpoints" >> rpc_list.txt
echo "$random_endpoints" >> rpc_list.txt
cp /root/rpc_list.txt /root/allora-huggingface-walkthrough/rpc_list.txt

dir_path="$HOME/allora-huggingface-walkthrough"
rpc_file="$HOME/allora-huggingface-walkthrough/rpc_list.txt"
if [ ! -f "$rpc_file" ]; then
    echo "File rpc_list.txt không tồn tại!"
    exit 1
fi
mapfile -t rpc_list < "$rpc_file"

get_random_rpc() {
    local rpc_index=$((RANDOM % ${#rpc_list[@]}))
    local rpc_value=${rpc_list[$rpc_index]}
    unset rpc_list[$rpc_index]
    rpc_list=("${rpc_list[@]}")
    echo "$rpc_value"
}
for file in "$dir_path"/wl_*.json; do
    echo "Updating file $file..."
    
    new_nodeRpc=$(get_random_rpc)
    
    jq --arg new_nodeRpc "$new_nodeRpc" '.wallet.nodeRpc = $new_nodeRpc' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    if [ $? -eq 0 ]; then
        echo "Successfully updated $file with new RPC: $new_nodeRpc"
    else
        echo "Failed to update $file"
        exit 1
    fi
done
echo "All config files have been updated."
