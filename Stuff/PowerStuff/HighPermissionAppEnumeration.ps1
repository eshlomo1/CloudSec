# Script Name: HighPermissionAppEnumeration.ps1
# Title: Enumerate Applications with High and Excessive Permissions in Azure AD
# Description: This script identifies applications assets (App Registrations, OAuth Apps, Enterprise Applications, and Managed Identities)
#              with high-value or excessive permissions in Entra ID.
#              It scans for delegated and application permissions that could pose a security risk if misused.

# ---------------------------------------------------

# Define High-Value and Excessive Permissions
$HighValuePermissions = @(
    # Directory and User Permissions
    "Directory.ReadWrite.All",
    "Directory.AccessAsUser.All",
    "User.ReadWrite.All",
    "RoleManagement.ReadWrite.Directory",

    # File and Mail Permissions
    "Files.ReadWrite.All",
    "Files.ReadWrite",
    "Mail.ReadWrite",
    "MailboxSettings.ReadWrite",

    # Group and Team Permissions
    "Group.ReadWrite.All",
    "TeamSettings.ReadWrite.All",

    # Security and Privileged Operations
    "SecurityEvents.ReadWrite.All",
    "IdentityRiskEvent.ReadWrite.All",
    "AuditLog.ReadWrite.All"
)

# Output Header
Write-Output "=== Enumerating Applications with High and Excessive Permissions ===`n"

# Initialize Results Array
$Results = @()

# Step 1: Retrieve All Service Principals (Enterprise Applications)
Write-Output "Retrieving all service principals..."
$ServicePrincipals = Get-MgServicePrincipal -All

# Step 2: Enumerate OAuth2PermissionGrants (Delegated Permissions)
Write-Output "Processing OAuth2PermissionGrants..."
$OAuthGrants = Get-MgOauth2PermissionGrant -All
foreach ($Grant in $OAuthGrants) {
    if ($HighValuePermissions -contains $Grant.Scope) {
        $AppDetails = $ServicePrincipals | Where-Object { $_.Id -eq $Grant.ClientId }
        if ($AppDetails) {
            $Results += [pscustomobject]@{
                AppName        = $AppDetails.DisplayName
                AppId          = $AppDetails.AppId
                AppType        = "OAuth App"
                Permissions    = $Grant.Scope
            }
        }
    }
}

# Step 3: Enumerate App Registrations for Required Resource Access
Write-Output "Processing App Registrations..."
$Applications = Get-MgApplication -All
foreach ($App in $Applications) {
    $AppPermissions = $App.RequiredResourceAccess | ForEach-Object {
        $_.ResourceAccess | Where-Object { $HighValuePermissions -contains $_.Id }
    }

    if ($AppPermissions) {
        $Results += [pscustomobject]@{
            AppName        = $App.DisplayName
            AppId          = $App.AppId
            AppType        = "App Registration"
            Permissions    = ($AppPermissions | ForEach-Object { $_.Type }) -join ", "
        }
    }
}

# Step 4: Identify Managed Identities (Service Principals)
Write-Output "Processing Managed Identities..."
$ManagedIdentities = $ServicePrincipals | Where-Object { $_.ServicePrincipalType -eq "ManagedIdentity" }
foreach ($Identity in $ManagedIdentities) {
    $Permissions = $Identity.AppRoles | Where-Object { $HighValuePermissions -contains $_.Value }
    if ($Permissions) {
        $Results += [pscustomobject]@{
            AppName        = $Identity.DisplayName
            AppId          = $Identity.AppId
            AppType        = "Managed Identity"
            Permissions    = ($Permissions | ForEach-Object { $_.Value }) -join ", "
        }
    }
}

# Step 5: Identify Service Principals with Excessive Permissions
Write-Output "Checking Service Principals for excessive permissions..."
foreach ($SP in $ServicePrincipals) {
    $AssignedPermissions = $SP.AppRoles | Where-Object { $HighValuePermissions -contains $_.Value }
    if ($AssignedPermissions) {
        $Results += [pscustomobject]@{
            AppName        = $SP.DisplayName
            AppId          = $SP.AppId
            AppType        = "Enterprise Application"
            Permissions    = ($AssignedPermissions | ForEach-Object { $_.Value }) -join ", "
        }
    }
}

# Step 6: Output Results
Write-Output "=== High-Permission Applications ===`n"
$Results | Format-Table -AutoSize

# Optional: Export Results to CSV
$ExportPath = "HighPermissionApps_$(Get-Date -Format 'yyyyMMddHHmmss').csv"
$Results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
Write-Output "Results exported to: $ExportPath"
