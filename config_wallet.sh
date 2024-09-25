#!/bin/bash

set -e 

rm -rf allora-huggingface-walkthrough
git clone https://github.com/allora-network/allora-huggingface-walkthrough || { echo "Git clone failed"; exit 1; }
cp /root/wl_formated.txt /root/allora-huggingface-walkthrough/wl_formated.txt || { echo "Copy failed"; exit 1; }

wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/app.py -O /root/allora-huggingface-walkthrough/app.py || { echo "Download app.py failed"; exit 1; }
wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/requirements.txt -O /root/allora-huggingface-walkthrough/requirements.txt || { echo "Download requirements.txt failed"; exit 1; }

NUM_WL=$(wc -l < $HOME/wl_formated.txt)

if ! grep -q "export NUM_WL=" ~/.bash_profile; then
    echo "export NUM_WL=$NUM_WL" >> ~/.bash_profile
fi

source ~/.bash_profile

create_config_files() {
    i=1
    while IFS='|' read -r address mnemonic; do
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
}

create_config_files

json_data=$(curl -s https://server-3.itrocket.net/testnet/allora/.rpc_combined.json)
endpoints=$(echo "$json_data" | jq -r 'to_entries | map(select(.value.tx_index == "on")) | sort_by(.value.latest_block_height | tonumber) | reverse | .[:80] | .[].key | "http://" + .')
random_endpoints=$(echo "$endpoints" | shuf -n 50)
fixed_endpoints=$(for i in {1..2}; do echo "https://allora-testnet-rpc.itrocket.net"; done)

echo "$endpoints" > rpc_list.txt
echo "$fixed_endpoints" >> rpc_list.txt
echo "$random_endpoints" >> rpc_list.txt
cp /root/rpc_list.txt /root/allora-huggingface-walkthrough/rpc_list.txt

dir_path="$HOME/allora-huggingface-walkthrough"
rpc_file="$dir_path/rpc_list.txt"
rpc_usage_file="$dir_path/rpc_usage.txt"
MAX_USAGE=5

if [ ! -f "$rpc_usage_file" ]; then
    echo "Initializing rpc_usage.txt..."
    mapfile -t rpc_list < "$rpc_file"
    > "$rpc_usage_file"
    for rpc in "${rpc_list[@]}"; do
        echo "$rpc?0" >> "$rpc_usage_file"
    done
fi

get_random_rpc() {
    mapfile -t rpc_usage_list < "$rpc_usage_file"
    
    if [ ${#rpc_usage_list[@]} -eq 0 ]; then
        echo "Error: RPC usage list is empty!"
        exit 1
    fi

    valid_rpcs=()

    for rpc_line in "${rpc_usage_list[@]}"; do
        rpc=$(echo "$rpc_line" | awk -F'?' '{print $1}')
        usage_count=$(echo "$rpc_line" | awk -F'?' '{print $2}')

        if [ "$usage_count" -lt "$MAX_USAGE" ]; then
            valid_rpcs+=("$rpc_line")
        fi
    done

    if [ ${#valid_rpcs[@]} -eq 0 ]; then
        echo "Error: No RPC with usage count less than $MAX_USAGE found."
        exit 1
    fi

    random_index=$((RANDOM % ${#valid_rpcs[@]}))
    rpc_line="${valid_rpcs[$random_index]}"
    rpc=$(echo "$rpc_line" | awk -F'?' '{print $1}')
    usage_count=$(echo "$rpc_line" | awk -F'?' '{print $2}')

    echo "Selected RPC: $rpc with usage count: $usage_count"

    new_usage_count=$((usage_count + 1))

    for i in "${!rpc_usage_list[@]}"; do
        if [[ "${rpc_usage_list[$i]}" == "$rpc_line" ]]; then
            rpc_usage_list[$i]="$rpc?$new_usage_count"
            break
        fi
    done

    printf "%s\n" "${rpc_usage_list[@]}" > "$rpc_usage_file"

    echo "$rpc"
    return 0
}

for file in "$dir_path"/wl_*.json; do
    echo "Updating file $file..."

    new_nodeRpc=$(get_random_rpc)
    if [ $? -ne 0 ]; then
        echo "Failed to fetch a valid RPC. Skipping file $file."
        continue
    fi

    echo "New RPC for $file: $new_nodeRpc"

    jq --arg new_nodeRpc "$new_nodeRpc" '.wallet.nodeRpc = $new_nodeRpc' "$file" > "${file}.tmp"
    if [ $? -ne 0 ]; then
        echo "jq command failed for file $file. Skipping..."
        continue
    fi

    mv "${file}.tmp" "$file"
    if [ $? -eq 0 ]; then
        echo "Successfully updated $file with new RPC: $new_nodeRpc"
    else
        echo "Failed to update $file"
    fi
done

echo "All config files have been updated."
