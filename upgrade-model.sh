#!/bin/bash

BOLD="\033[1m"
UNDERLINE="\033[4m"
DARK_YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0;32m"


echo -e "${CYAN}Upgrade app.py made by rejump hugging model (Y/N):${RESET}"
read -p "" installdep
echo

if [[ "$installdep" =~ ^[Yy]$ ]]; then

    echo -e "${CYAN}Clone & Replace old file :${RESET}"
    echo
	rm -rf app.py
	rm -rf requirements.txt
    wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/app.py -O /root/allora-huggingface-walkthrough/app.py
    wget -q https://raw.githubusercontent.com/ReJumpLabs/Hugging-Face-model/main/requirements.txt -O /root/allora-huggingface-walkthrough/requirements.txt
    wait
	
	echo -e "${CYAN}Rebuild and run a model :${RESET}"
	
	echo
    execute_with_prompt 'docker compose down'
    echo
	
	echo
    execute_with_prompt 'docker compose up --build -d'
    echo
	
	echo
    execute_with_prompt 'docker compose logs -f'
    echo
	
else
    echo -e "${CYAN}Fuck you bro :${RESET}"
    
fi

echo
echo -e "==============XONG & BU BU BU==============="

