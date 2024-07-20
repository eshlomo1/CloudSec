# This PowerShell script connects to the Azure Open AI
## The main goals is to run a "prompt engineers" 
### Models list - https://platform.openai.com/docs/models/model-endpoint-compatibility

# Get your API key here: https://platform.openai.com/account/api-keys #
# Set your API key
$apiKey = "Bearer sk-xxxxxxxx"

# Set the API endpoint URL
$url = "https://api.openai.com/v1/engines/text-davinci-003/completions"

# Set the request headers
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

# Set the request body
$body = @{
    "prompt" = "Are you familiar with Microsoft Sentinel?"
    "temperature" = 1.0
    "max_tokens" = 100
}

# Send the HTTP request to the API endpoint
$response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body ($body | ConvertTo-Json)

# Print the response
Write-Host $response.choices.text