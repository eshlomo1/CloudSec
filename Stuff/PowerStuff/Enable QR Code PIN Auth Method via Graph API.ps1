<#
.SYNOPSIS
Enable QR Code PIN auth method for a specific Entra ID group by verified display name and ID.

.DESCRIPTION
- Resolves all groups with display name 'QRCode_Groups'
- Ensures the resolved group ID matches the expected target
- Applies QR Code PIN policy only if validation passes

.NOTES
Author: Elli Shlomo
Version: 1.8
#>

# Import and connect
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph

Connect-MgGraph -Scopes @(
    "Policy.ReadWrite.AuthenticationMethod",
    "Directory.Read.All"
)

# Define your known target
$groupName = "QRCode_Groups"
$expectedGroupId = "586216f8-5c95-4ee2-a405-0e1691193cd6"

# Resolve all groups with that display name
Write-Host "Searching for all groups named '$groupName'..."
$groups = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups`?$filter=displayName eq '$groupName'"

if (-not $groups.value) {
    Write-Error "No group found with name '$groupName'."
    return
}

# Check for a matching group ID
$matchingGroup = $groups.value | Where-Object { $_.id -eq $expectedGroupId }

if (-not $matchingGroup) {
    Write-Error "Group '$groupName' found, but expected ID '$expectedGroupId' was not matched. Aborting."
    return
}

Write-Host " Found correct group '$groupName' with ID: $expectedGroupId"

# Prepare PATCH body
$patchBody = @{
    "@odata.type" = "microsoft.graph.qrCodePinAuthenticationMethodConfiguration"
    id = "qrCodePin"
    state = "enabled"
    includeTargets = @(
        @{
            targetType = "group"
            id = $expectedGroupId
        }
    )
    excludeTargets = @()
    standardQRCodeLifetimeInDays = 395
    pinLength = 10
} | ConvertTo-Json -Depth 10

# Apply the policy
$policyUri = "https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/qrCodePin"
Invoke-MgGraphRequest -Method PATCH -Uri $policyUri -Body $patchBody -ContentType "application/json"
Write-Host "Policy updated. Validating..."

Start-Sleep -Seconds 5

# Validation
$verify = Invoke-MgGraphRequest -Method GET -Uri $policyUri
$includedIds = $verify.includeTargets | ForEach-Object { $_.id }

if ($verify.state -eq "enabled" -and ($includedIds -contains $expectedGroupId)) {
    Write-Host "`n Validation passed. Policy is enabled and group is targeted."
} else {
    Write-Warning "`n⚠ Validation failed: Policy not enabled or group ID not present."
}
