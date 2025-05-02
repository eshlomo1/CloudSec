<#
.SYNOPSIS
Provide a brief overview of what the script does.

.DESCRIPTION
This PowerShell script is designed to [insert detailed description of the script's purpose and functionality]. It performs [specific tasks or operations] to achieve [desired outcome].

.PARAMETER [ParameterName]
[Description of the parameter, its purpose, and expected input.]

.EXAMPLE
[Provide an example of how to use the script, including input and expected output.]

.NOTES
Author: Elli Shlomo
Version: 1.1
This script worked on masOS with PowerShell 7.3.1 and Microsoft.Graph module version 1.10.0.

.LINK
#>
# Script Name: Set-EntraIDQRCodePin.ps1
# Official Title: Configure QR Code and PIN for Entra ID User Authentication
# the QRCode is in preview mode so it is not fully copatible with PowerShell.
# Entra App Credentials
$tenantId     = "dbf22f42-add tenant id here" 
$clientId     = "a4721e68-putt app registartion here" 
$clientSecret = "7zk8Q~put you code hete"

# Target user and QR code details
$userUPN   = "Hector@PurpleXlab.onmicrosoft.com"
$pinCode   = "1234567890"
$start     = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")               # Now
$expire    = "2026-05-31T23:59:00Z"                                    # Max 13 months

# Acquire token
$token = (Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Body @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}).access_token

# Construct payload
$body = @{
    standardQRCode = @{
        startDateTime  = $start
        expireDateTime = $expire
    }
    pin = @{
        code = $pinCode
    }
} | ConvertTo-Json -Depth 5

# Send request
$uri = "https://graph.microsoft.com/beta/users/$userUPN/authentication/qrCodePinMethod"

$response = Invoke-RestMethod -Method PUT -Uri $uri -Headers @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
} -Body $body

# Output result
$response | Format-List 
