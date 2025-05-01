<#
.SYNOPSIS

# Enable QR Code PIN Auth Method via Graph API
Enable QR Code (PIN) Authentication Method via Microsoft Graph API (beta)

.DESCRIPTION
Enables the qrCodePin method with a 10-digit PIN and a 395-day QR code lifetime for a specified group.

.REQUIREMENTS
- Microsoft.Graph module
- Beta endpoint access
- Scopes: Policy.ReadWrite.AuthenticationMethod, Directory.Read.All

.NOTES
Author: Elli Shlomo
Version: 1.0
#>

# ---------------------
# PREPARE GRAPH
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph

# ---------------------
# CONNECT TO GRAPH
Connect-MgGraph -Scopes @(
    "Policy.ReadWrite.AuthenticationMethod",
    "Directory.Read.All"
)

# ---------------------
# SET TARGET GROUP ID (replace with your actual group ID)
$groupId = "586216f8-5c95-4ee2-a405-0e1691193cd6"  # QR code-enabled group

# ---------------------
# PREPARE PATCH BODY
$patchBody = @{
    "@odata.type" = "microsoft.graph.qrCodePinAuthenticationMethodConfiguration"
    id = "qrCodePin"
    state = "enabled"
    includeTargets = @(
        @{
            targetType = "group"
            id = $groupId
        }
    )
    excludeTargets = @()
    standardQRCodeLifetimeInDays = 395
    pinLength = 10
} | ConvertTo-Json -Depth 10

# ---------------------
# PATCH REQUEST
$uri = "https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/qrCodePin"

Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body $patchBody -ContentType "application/json"

Write-Host "QR Code (PIN) authentication method enabled for group ID $groupId"
