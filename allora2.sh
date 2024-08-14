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

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Requirement for running allora-worker-node${RESET}"
echo
echo -e "${BOLD}${DARK_YELLOW}Operating System : Ubuntu 22.04${RESET}"
echo -e "${BOLD}${DARK_YELLOW}CPU : Min of 1/2 core.${RESET}"
echo -e "${BOLD}${DARK_YELLOW}RAM : 2 to 4 GB.${RESET}"
echo -e "${BOLD}${DARK_YELLOW}Storage : SSD or NVMe with at least 5GB of space.${RESET}"
echo

echo -e "${CYAN}Do you meet all of these requirements? (Y/N):${RESET}"
read -p "" response
echo

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
    
    echo -e "${BOLD}${DARK_YELLOW}Installing Go...${RESET}"
    execute_with_prompt 'cd $HOME'
    echo
    execute_with_prompt 'ver="1.21.3" && wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"'
    echo
    execute_with_prompt 'sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"'
    echo
    execute_with_prompt 'rm "go$ver.linux-amd64.tar.gz"'
    echo
    execute_with_prompt 'echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile'
    echo
    execute_with_prompt 'source $HOME/.bash_profile'
    echo
    echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
    source .bash_profile
    
    echo -e "${BOLD}${DARK_YELLOW}Checking go version...${RESET}"
    execute_with_prompt 'go version'
    echo

    echo -e "${BOLD}${DARK_YELLOW}Install allocmd...${RESET}"
    execute_with_prompt 'pip install allocmd --upgrade'
    echo
fi

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Continuce Installing worker node...${RESET}"
rm -rf basic-coin-prediction-node
git clone https://github.com/allora-network/basic-coin-prediction-node
cd basic-coin-prediction-node
wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/app.py -O /root/basic-coin-prediction-node/app.py
wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/main.py -O /root/basic-coin-prediction-node/main.py
wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/requirements.txt -O /root/basic-coin-prediction-node/requirements.txt
echo

echo -e "${BOLD}${DARK_YELLOW}Create new Wallet:${RESET}"

allorad keys add testwallet
wait

echo
echo -e "${BOLD}${DARK_YELLOW}Copy mnemonic phrase & paste here:${RESET}"
allorad keys add testwallet --recover --keyring-backend test --unarmored-hex --unsafe
echo
wait

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Continuce config worker node...${RESET}"

printf 'Copy mnemonic phrase testwallet & paste here: '
read HEX

if [ -f config.json ]; then
    rm config.json
    echo "Removed existing config.json file."
fi

cat <<EOF > config.json
{
    "wallet": {
        "addressKeyName": "testwallet",
        "addressRestoreMnemonic": "${HEX}",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://sentries-rpc.testnet-1.testnet.allora.network/",
        "maxRetries": 1,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 4,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BTC"
            }
        }
        {
            "topicId": 6,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "SOL"
            }
        }
    ]
}
EOF

execute_with_prompt 'chmod +x init.config'
execute_with_prompt './init.config'

echo

echo -e "${BOLD}${DARK_YELLOW}Faucet fund address worker:${RESET}"
curl -L https://faucet.testnet-1.testnet.allora.network/send/allora-testnet-1/$(allorad keys  show testwallet -a --keyring-backend test)
sleep 5
curl -L https://faucet.testnet-1.testnet.allora.network/send/allora-testnet-1/$(allorad keys  show testwallet -a --keyring-backend test)
sleep 10
curl -L https://faucet.testnet-1.testnet.allora.network/send/allora-testnet-1/$(allorad keys  show testwallet -a --keyring-backend test)
sleep 7

echo
wait

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Building and starting Docker containers...${RESET}"
docker compose up --build -d
echo

echo -e "${BOLD}${DARK_YELLOW}Checking running Docker containers...${RESET}"
docker compose logs -f
