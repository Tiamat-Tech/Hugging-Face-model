from flask import Flask, Response
import requests
import json
import random

# create our Flask app
app = Flask(__name__)

CG_Keys = [
    "CG-SHVRcN149eTRRWye8m9WcRMp",
    "CG-hfJj5cwMHCojc53CZbqkp9Cm",
    "CG-exoXxbm5nH7RupWVVEgXyAEb",
    "CG-xDakxFq8GTNnvrBoECi7XEEM",
    "CG-MWwrr4qjo1mrnbnTQXiuK5Jt",
    "CG-NQCDyrDtFU8fZ183a3VD4mWR",
    "CG-tYzY9xxiRpiV2GrFxYmXH95q",
    "CG-7rA1whQArU4SE9Ui2DPLD5fJ",
    "CG-B48aWQvXUjgQ97FR9tkij526",
    "CG-SXDL5b7UnwWKAnAi2BjYaeii",
    "CG-d6GjgszPN2oLptEc6Yct3mNS",
    "CG-dYLNoobF2yTLvJd5LeTM9sAD",
    "CG-AzH5ihnSLJkyNAime7BFm72Q",
    "CG-gS72E3HbWK7TZpYBP1MqAA7R",
    "CG-FmVtx7zaAoL6Kum1UjEDeRZV",
    "CG-P6xBDENfHFgFJyWyUzDjEAq8",
    "CG-S1izHbv8o2vEUPoiMtcPVjQG",
    "CG-zs8hNgi2roheqnSkMxctmXCs",
    "CG-Rop8DVkMZYhGDSwDPEoXJY2F",
    "CG-gC1aHMvq5euD63n11vquT8gs",
    "CG-KcMDTvDDQPCwopCwPKvPNpBu"
]

UP_Keys = [
    "UP-920fa918502c41d0bd96b8e8",
    "UP-d6f2d4ec7236440f88476bf9",
    "UP-848833090ed742b1b4155ee2",
    "UP-d83e248df81943ef9087240c",
    "UP-253f4615b5f247fd90b605ae",
    "UP-709bb6647c7e46f2aa8cf0a5",
    "UP-c5cb5cd2cddc4449ac56ef25"
]

def get_memecoin_token(blockheight):
    UP_Key = random.choice(UP_Keys)
    
    upshot_url = f"https://api.upshot.xyz/v2/allora/tokens-oracle/token/{blockheight}"
    headers = {
        'accept': 'application/json',
        'x-api-key': UP_Key
    }
    response = requests.get(upshot_url, headers=headers)
        
    if response.status_code == 200:
        data = response.json()
        name_token = str(data["data"]["token_id"]) #return "boshi"
        return name_token
    else:
        raise ValueError("Unsupported token") 

def get_meme_price(token):
    CG_Key = random.choice(CG_Keys)
    base_url = "https://api.coingecko.com/api/v3/simple/price?ids="
    token_map = {
        'ETH': 'ethereum',
        'SOL': 'solana',
        'BTC': 'bitcoin',
        'BNB': 'binancecoin',
        'ARB': 'arbitrum'
    }
    token = token.upper()
    print(CG_Key)
    if token in token_map:
        url = f"{base_url}{token_map[token]}&vs_currencies=usd"
        headers = {
            "accept": "application/json",
            "x-cg-demo-api-key": CG_Key
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            price = data[token_map[token]]["usd"]
            print(price)
            return price
    else:
        raise ValueError("Unsupported token") 
    return

def get_simple_price(token):
    CG_Key = random.choice(CG_Keys)
    base_url = "https://api.coingecko.com/api/v3/simple/price?ids="
    token_map = {
        'ETH': 'ethereum',
        'SOL': 'solana',
        'BTC': 'bitcoin',
        'BNB': 'binancecoin',
        'ARB': 'arbitrum'
    }
    token = token.upper()
    headers = {
        "accept": "application/json",
        "x-cg-demo-api-key": CG_Key
    }
    if token in token_map:
        url = f"{base_url}{token_map[token]}&vs_currencies=usd"
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            price = data[token_map[token]]["usd"]
            return price
        
    elif token not in token_map:
        token = token.lower()
        url = f"{base_url}{token}&vs_currencies=usd"
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            return data[token]["usd"]
        
    else:
        raise ValueError("Unsupported token") 

@app.route("/collect-price")
def collect_price():
    tokens = [ 'ETH', 'SOL', 'BTC', 'BNB', 'ARB']
    for token in tokens:
        price = get_simple_price(token)
        with open(token + ".txt", "w") as file:
            file.write(str(price))
        
    return Response("Success", status=200, mimetype='application/json')

# define our endpoint
@app.route("/inference/<string:tokenorblockheightorparty>")
def get_inference(tokenorblockheightorparty):
    if tokenorblockheightorparty.isnumeric():
        namecoin = get_memecoin_token(tokenorblockheightorparty)
        price = get_simple_price(namecoin)
        price1 = price + price*0.8/100
        price2 = price - price*0.8/100
        predict_result = str(round(random.uniform(price1, price2), 7))
    elif len(tokenorblockheightorparty) == 3 and tokenorblockheightorparty.isalpha(): 
        try:
            with open(tokenorblockheightorparty + ".txt", "r") as file:
                content = file.read().strip()
            price = float(content)
            price1 = price + price*0.2/100
            price2 = price - price*0.2/100
            predict_result = str(round(random.uniform(price1, price2), 7))
        except Exception as e:
            return Response(json.dumps({"pipeline error": str(e)}), status=500, mimetype='application/json')
        
    else:
        predict_result = str(round(random.uniform(44, 51), 2))
    
    return predict_result

# define predict party
@app.route("/inference/topic11/<string:team>")
def guestTeam(team):
    lowest = 44
    highest = 51
    random_float = str(random.uniform(lowest, highest))
    return Response(random_float, status=200)

# run our Flask app
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8000, debug=True)
