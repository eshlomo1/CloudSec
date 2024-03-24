import requests
import json

# Set your API key
api_key = "Bearer sk-xxxxxxxx"

# Set the API endpoint URL
url = "https://api.openai.com/v1/engines/text-davinci-003/completions"

# Set the request headers
headers = {
    "Authorization": api_key,
    "Content-Type": "application/json"
}

# Set the request body
body = {
    "prompt": "Are you familiar with Microsoft Sentinel?",
    "temperature": 1.0,
    "max_tokens": 100
}

# Send the HTTP request to the API endpoint
response = requests.post(url, headers=headers, json=body)

# Parse the response
response_data = response.json()

# Extract the completion text from the response
completion_text = response_data["choices"][0]["text"]

# Print the response
print(completion_text)