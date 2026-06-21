<#
.SYNOPSIS
    This script connects to Microsoft Graph and creates service principals for Microsoft Copilot services.

.DESCRIPTION
    This PowerShell script authenticates to Microsoft Graph using the required permissions
    and creates service principals for Enterprise Copilot Platform (Microsoft 365 Copilot) and Security Copilot (Microsoft Security Copilot).
  
.CAUTIONS
    - Ensure that you have the necessary administrative privileges to create service principals.
    - The script requires the "Application.ReadWrite.All" permission scope, which allows modification of application objects.
    - Running this script will create service principal objects in your Microsoft Entra ID (formerly Azure AD), which may impact your security policies.
    - If an authentication session expires, manual re-authentication may be required.

.NOTES
    Author: Elli Shlomo
    Version: 1.1
    Requires: Microsoft Graph PowerShell SDK
    The permissions are based on the Microsoft Document https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-copilot-ai-security#create-targetable-service-principals-using-powershell
#>

# Connect to Microsoft Graph with required permissions
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Application.ReadWrite.All"
Write-Host "Connected to Microsoft Graph successfully." -ForegroundColor Green

# Define service principals to create
$servicePrincipals = @(
    @{ Name = "Enterprise Copilot Platform (Microsoft 365 Copilot)"; AppId = "fb8d773d-7ef8-4ec0-a117-179f88add510" },
    @{ Name = "Security Copilot (Microsoft Security Copilot)"; AppId = "bb5ffd56-39eb-458c-a53a-775ba21277da" }
)

# Loop through and create service principals
foreach ($sp in $servicePrincipals) {
    Write-Host "Attempting to create service principal for: $($sp.Name)" -ForegroundColor Yellow
    try {
        $result = New-MgServicePrincipal -AppId $sp.AppId
        if ($result) {
            Write-Host "Successfully created: $($sp.Name)" -ForegroundColor Green
        } else {
            Write-Host "Service principal creation returned no result: $($sp.Name)" -ForegroundColor DarkYellow
        }
    } catch {
        Write-Host "Failed to create service principal for: $($sp.Name)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
    }
}

Write-Host "Script execution completed." -ForegroundColor Cyan

