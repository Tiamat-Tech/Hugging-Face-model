#!/bin/bash

BOLD="\033[1m"
UNDERLINE="\033[4m"
DARK_YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0;32m"

execute_with_prompt() {
    echo -e "${BOLD}Executing: $1${RESET}"
    if eval "$1"; then
        echo "Command executed successfully."
    else
        echo -e "${BOLD}${DARK_YELLOW}Error executing command: $1${RESET}"
        exit 1
    fi
}


if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${BOLD}${DARK_YELLOW}Error: You do not meet the required specifications. Exiting...${RESET}"
    echo
    exit 1
fi

echo -e "${CYAN}Install dependencies allora, If already install = N? (Y/N):${RESET}"
read -p "" installdep
echo

if [[ "$installdep" =~ ^[Yy]$ ]]; then
    echo -e "${BOLD}${DARK_YELLOW}Updating system dependencies...${RESET}"
    execute_with_prompt "sudo apt update -y && sudo apt upgrade -y"
    echo
    
    echo -e "${BOLD}${DARK_YELLOW}Installing packages...${RESET}"
    execute_with_prompt "sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 -y"
    echo
    
    echo -e "${BOLD}${DARK_YELLOW}Installing python3...${RESET}"
    execute_with_prompt "sudo apt install python3 python3-pip -y"
    echo
    
    echo -e "${BOLD}${DARK_YELLOW}Installing Docker...${RESET}"
    execute_with_prompt 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
    echo
    execute_with_prompt 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
    echo
    execute_with_prompt 'sudo apt-get update'
    echo
    execute_with_prompt 'sudo apt-get install docker-ce docker-ce-cli containerd.io -y'
    echo
    
    echo -e "${BOLD}${DARK_YELLOW}Checking docker version...${RESET}"
    execute_with_prompt 'docker version'
    echo
    
    echo -e "${BOLD}${DARK_YELLOW}Installing Docker Compose...${RESET}"
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    echo
    execute_with_prompt 'sudo curl -L "https://github.com/docker/compose/releases/download/'"$VER"'/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose'
    echo
    execute_with_prompt 'sudo chmod +x /usr/local/bin/docker-compose'
    echo
    
    echo -e "${BOLD}${DARK_YELLOW}Checking docker-compose version...${RESET}"
    execute_with_prompt 'docker-compose --version'
    echo
    
fi

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Continuce Installing worker node...${RESET}"
echo -e "${CYAN}Choose model: 24H HUGGING (Y)/ 10M: Offchain-node (N) :${RESET}"
read -p "" model
echo

if [[ "$model" =~ ^[Yy]$ ]]; then

    echo -e "${CYAN}Installing: 24H HUGGING MODEL :${RESET}"
    echo
    rm -rf basic-coin-prediction-node
    git clone https://github.com/allora-network/basic-coin-prediction-node
    cd basic-coin-prediction-node
    
    #wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/app.py -O /root/basic-coin-prediction-node/app.py
    #wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/main.py -O /root/basic-coin-prediction-node/main.py
    #wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/requirements.txt -O /root/basic-coin-prediction-node/requirements.txt
    wait
else
    echo -e "${CYAN}Installing: 10H Offchain-node :${RESET}"
    git clone https://github.com/allora-network/allora-offchain-node
    cd allora-offchain-node
    echo
fi
echo

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Continuce config worker node...${RESET}"

printf 'Copy mnemonic phrase testwallet & paste here: '
read HEX

if [ -f config.json ]; then
    rm config.json
    echo "Removed existing config.json file."
fi
if [[ "$model" =~ ^[Yy]$ ]]; then
cat <<EOF > config.json
    {
        "wallet": {
            "addressKeyName": "testwallet",
            "addressRestoreMnemonic": "${HEX}",
            "alloraHomeDir": "",
            "gas": "3000000",
            "gasAdjustment": 1.0,
            "nodeRpc": "https://sentries-rpc.testnet-1.testnet.allora.network/",
            "maxRetries": 1,
            "delay": 1,
            "submitTx": false
        },
        "worker": [
            {
                "topicId": 1,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 1,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "ETH"
                }
            },
            {
                "topicId": 2,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 3,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "ETH"
                }
            },
            {
                "topicId": 3,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 5,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "BTC"
                }
            },
            {
                "topicId": 4,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 2,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "BTC"
                }
            },
            {
                "topicId": 5,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 4,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "SOL"
                }
            },
            {
                "topicId": 6,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 5,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "SOL"
                }
            },
            {
                "topicId": 7,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 2,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "ETH"
                }
            },
            {
                "topicId": 8,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 3,
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
else

cat <<EOF > config.json
    {
        "wallet": {
            "addressKeyName": "testwallet",
            "addressRestoreMnemonic": "${HEX}",
            "alloraHomeDir": "",
            "gas": "2000000",
            "gasAdjustment": 1.0,
            "nodeRpc": "https://sentries-rpc.testnet-1.testnet.allora.network/",
            "maxRetries": 1,
            "delay": 1,
            "submitTx": true
        },
         "worker": [
            {
                "topicId": 1,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 1,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "ETH"
                }
            },
            {
                "topicId": 2,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 3,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "ETH"
                }
            },
            {
                "topicId": 3,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 5,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "BTC"
                }
            },
            {
                "topicId": 4,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 2,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "BTC"
                }
            },
            {
                "topicId": 5,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 4,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "SOL"
                }
            },
            {
                "topicId": 6,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 5,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "SOL"
                }
            },
            {
                "topicId": 7,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 2,
                "parameters": {
                    "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                    "Token": "ETH"
                }
            },
            {
                "topicId": 8,
                "inferenceEntrypointName": "api-worker-reputer",
                "loopSeconds": 3,
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
            
        ],
        "reputer": [
          {
            "topicId": 1,
            "reputerEntrypointName": "api-worker-reputer",
            "loopSeconds": 20,
            "minStake": 100000,
            "parameters": {
              "SourceOfTruthEndpoint": "http://source:8000/truth/{Token}/{BlockHeight}",
              "Token": "ethereum"
            }
          },
          {
            "topicId": 3,
            "reputerEntrypointName": "api-worker-reputer",
            "loopSeconds": 22,
            "minStake": 100000,
            "parameters": {
              "SourceOfTruthEndpoint": "http://source:8000/truth/{Token}/{BlockHeight}",
              "Token": "bitcoin"
            }
          },
          {
            "topicId": 4,
            "reputerEntrypointName": "api-worker-reputer",
            "loopSeconds": 24,
            "minStake": 100000,
            "parameters": {
              "SourceOfTruthEndpoint": "http://source:8000/truth/{Token}/{BlockHeight}",
              "Token": "bitcoin"
            }
          },
          {
            "topicId": 5,
            "reputerEntrypointName": "api-worker-reputer",
            "loopSeconds": 26,
            "minStake": 100000,
            "parameters": {
              "SourceOfTruthEndpoint": "http://source:8000/truth/{Token}/{BlockHeight}",
              "Token": "solana"
            }
          },
          {
            "topicId": 6,
            "reputerEntrypointName": "api-worker-reputer",
            "loopSeconds": 28,
            "minStake": 100000,
            "parameters": {
              "SourceOfTruthEndpoint": "http://source:8000/truth/{Token}/{BlockHeight}",
              "Token": "solana"
            }
          },
          {
            "topicId": 7,
            "reputerEntrypointName": "api-worker-reputer",
            "loopSeconds": 30,
            "minStake": 100000,
            "parameters": {
              "SourceOfTruthEndpoint": "http://source:8000/truth/{Token}/{BlockHeight}",
              "Token": "ethereum"
            }
          },
          {
            "topicId": 8,
            "reputerEntrypointName": "api-worker-reputer",
            "loopSeconds": 32,
            "minStake": 100000,
            "parameters": {
              "SourceOfTruthEndpoint": "http://source:8000/truth/{Token}/{BlockHeight}",
              "Token": "binancecoin"
            }
          },
          {
            "topicId": 9,
            "reputerEntrypointName": "api-worker-reputer",
            "loopSeconds": 35,
            "minStake": 100000,
            "parameters": {
              "SourceOfTruthEndpoint": "http://source:8000/truth/{Token}/{BlockHeight}",
              "Token": "arbitrum"
            }
          }
        ]
    }
EOF
fi
echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW} If docker not run when init done, try this ...${RESET}"
execute_with_prompt 'chmod +x init.config'

echo
echo -e "==============RUN: cd basic-coin-prediction-node"
echo -e "==============RUN: cd allora-offchain-node"

echo -e "==============RUN: ./init.config"
echo -e "==============RUN: docker compose up --build -d"
echo -e "==============RUN: docker compose up --build -d"
echo -e "==============VIEW LOGS: docker compose logs -f"
echo

