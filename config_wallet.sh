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
rpc_file="$HOME/allora-huggingface-walkthrough/rpc_list.txt"
rpc_usage_file="$HOME/allora-huggingface-walkthrough/rpc_usage.txt"

if [ ! -f "$rpc_usage_file" ]; then
    mapfile -t rpc_list < "$rpc_file"
    for rpc in "${rpc_list[@]}"; do
        echo "$rpc:0" >> "$rpc_usage_file"
    done
fi

# Function to get a random RPC that has been used fewer than 10 times
get_random_rpc() {
    mapfile -t rpc_list < "$rpc_file"
    
    # Check if the rpc_list is empty
    if [ ${#rpc_list[@]} -eq 0 ]; then
        echo "Error: RPC list is empty!"
        exit 1
    fi

    # Pick a random index from the rpc_list
    random_index=$((RANDOM % ${#rpc_list[@]}))
    rpc="${rpc_list[$random_index]}"

    # Return the randomly selected RPC
    echo "$rpc"
}

# Process each JSON config file
for file in "$dir_path"/wl_*.json; do
    # Check if the file exists and is readable
    if [ ! -f "$file" ]; then
        echo "Error: File $file not found or not readable."
        continue
    fi

    echo "Updating file $file..."

    # Get a random RPC from the list
    new_nodeRpc=$(get_random_rpc)

    # Check if an RPC was successfully fetched
    if [ -z "$new_nodeRpc" ]; then
        echo "Error: Failed to fetch a valid RPC."
        exit 1
    fi

    # Debugging: Print the new RPC being applied
    echo "New RPC to be applied: $new_nodeRpc"

    # Update the JSON config file with the new RPC
    jq --arg new_nodeRpc "$new_nodeRpc" '.wallet.nodeRpc = $new_nodeRpc' "$file" > "${file}.tmp"

    # Check if jq was successful
    if [ $? -eq 0 ]; then
        mv "${file}.tmp" "$file"
        echo "Successfully updated $file with new RPC: $new_nodeRpc"
    else
        echo "Failed to update $file with jq. Check file structure and jq command."
        exit 1
    fi
done

echo "All config files have been updated."
