# Title: Retrieve App Registrations with 'User.DeleteRestore.All' Permissions
# Description: This script retrieves all App Registrations that have requested the 'User.DeleteRestore.All' permission. This permission allows the app to delete and restore users in the directory. The script uses the Microsoft Graph PowerShell module to connect to Microsoft Graph and retrieve the required information.
# Author: Elli Shlomo 

# --------------------------------------------------------------------------------

# Ensure the required module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -Confirm:$false
}

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All" 

# Retrieve all App Registrations
$appRegistrations = Get-MgApplication -All

# Array to store results
$results = @()

# Iterate over each App Registration
foreach ($app in $appRegistrations) {
    # Check Required Resource Access (permissions requested by the app)
    if ($app.RequiredResourceAccess) {
        foreach ($resourceAccess in $app.RequiredResourceAccess) {
            # Get the corresponding Service Principal for the resource
            $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($resourceAccess.ResourceAppId)'"
            if ($servicePrincipal) {
                foreach ($access in $resourceAccess.ResourceAccess) {
                    # Check for both Application and Delegated Permissions
                    if ($access.Type -eq "Role" -or $access.Type -eq "Scope") {
                        # Retrieve permission details (AppRole or OAuth2Permission)
                        $permissionDetails = if ($access.Type -eq "Role") {
                            $servicePrincipal.AppRoles | Where-Object { $_.Id -eq $access.Id -and $_.Value -eq "User.DeleteRestore.All" }
                        } else {
                            $servicePrincipal.Oauth2PermissionScopes | Where-Object { $_.Id -eq $access.Id -and $_.Value -eq "User.DeleteRestore.All" }
                        }

                        if ($permissionDetails) {
                            $results += [PSCustomObject]@{
                                AppDisplayName   = $app.DisplayName
                                AppId            = $app.AppId
                                PermissionType   = if ($access.Type -eq "Role") { "Application" } else { "Delegated" }
                                PermissionName   = $permissionDetails.Value
                                ResourceName     = $servicePrincipal.DisplayName
                                ResourceAppId    = $resourceAccess.ResourceAppId
                                PermissionId     = $permissionDetails.Id
                            }
                        }
                    }
                }
            }
        }
    }
}

# Display the results
if ($results) {
    $results | Format-Table -AutoSize
} else {
    Write-Host "No App Registrations with 'User.DeleteRestore.All' permissions found." -ForegroundColor Green
}
