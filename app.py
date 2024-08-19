from flask import Flask, Response
import requests
import json
import pandas as pd
import torch
from chronos import ChronosPipeline

# Tạo Flask app
app = Flask(__name__)

# Định nghĩa mô hình Hugging Face sẽ sử dụng
model_name = "amazon/chronos-t5-tiny"

# Tải mô hình khi ứng dụng khởi động để tránh lỗi pipeline
try:
    pipeline = ChronosPipeline.from_pretrained(
        model_name,
        device_map="auto",
        torch_dtype=torch.bfloat16,
    )
except Exception as e:
    pipeline = None
    print(f"Failed to load pipeline: {e}")

def get_coingecko_url(token):
    base_url = "https://api.coingecko.com/api/v3/coins/"
    token_map = {
        'ETH': 'ethereum',
        'SOL': 'solana',
        'BTC': 'bitcoin',
        'BNB': 'binancecoin',
        'ARB': 'arbitrum'
    }
    
    token = token.upper()
    if token in token_map:
        url = f"{base_url}{token_map[token]}/market_chart?vs_currency=usd&days=1&interval=minute"
        return url
    else:
        raise ValueError("Unsupported token")

@app.route("/inference/<string:token>")
def get_inference(token):
    """Tạo dự đoán cho token đã cho."""
    if pipeline is None:
        return Response(json.dumps({"error": "Pipeline is not available"}), status=500, mimetype='application/json')

    try:
        url = get_coingecko_url(token)
    except ValueError as e:
        return Response(json.dumps({"error": str(e)}), status=400, mimetype='application/json')

    headers = {
        "accept": "application/json",
        "x-cg-demo-api-key": "CG-"  # Thay bằng API key của bạn
    }

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        df = pd.DataFrame(data["prices"])
        df.columns = ["date", "price"]
        df["date"] = pd.to_datetime(df["date"], unit='ms')
        df = df.tail(20)  # Lấy 20 phút cuối cùng
    else:
        return Response(json.dumps({"Failed to retrieve data from the API": str(response.text)}), 
                        status=response.status_code, 
                        mimetype='application/json')

    context = torch.tensor(df["price"].values)
    prediction_length = 20  # Dự đoán cho 20 phút

    try:
        forecast = pipeline.predict(context, prediction_length)
        forecast_mean = forecast[0].mean(dim=1).tolist()  # Tính giá trị trung bình
        return Response(json.dumps(forecast_mean), status=200, mimetype='application/json')
    except Exception as e:
        return Response(json.dumps({"error": str(e)}), status=500, mimetype='application/json')

# Chạy Flask app
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8000, debug=True)




