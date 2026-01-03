# Meeting Link Validation & Metadata Detection
# List of example meeting IDs to test (replace with realistic guesses or ranges in a red team engagement)
# ------
$meetingIDs = @(
    "9326104760483?p=qNQLE0zB46OrGZwoLh",  # First meeting ID and token - this is a hypothetical link used for testing
    "1234567890123?p=abcdeg", # Second test meeting link with a different meeting ID and a simple token
    "9876543210987?p=qwertu" # Third example with another made-up meeting ID and a common token pattern
)

# Base URL
$baseURL = "https://teams.live.com/meet/"

# Headers to simulate a real browser
$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/119.0.0.0 Safari/537.36"
}

foreach ($id in $meetingIDs) {
    $fullURL = "$baseURL$id"
    try {
        $response = Invoke-WebRequest -Uri $fullURL -Headers $headers -Method GET -MaximumRedirection 3 -ErrorAction Stop
        Write-Host "`nURL: $fullURL"
        Write-Host "Status Code: $($response.StatusCode)"
        Write-Host "Final URI: $($response.BaseResponse.ResponseUri)"
        Write-Host "Content Length: $($response.RawContentLength)"
        if ($response.Content -match "Join now|Enter name|Sign in") {
            Write-Host "[+] Possible open meeting or metadata found!" -ForegroundColor Green
        } else {
            Write-Host "[-] No meeting indicators found." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nURL: $fullURL"
        Write-Host "[-] Error or invalid link: $($_.Exception.Message)" -ForegroundColor Red
    }
}
