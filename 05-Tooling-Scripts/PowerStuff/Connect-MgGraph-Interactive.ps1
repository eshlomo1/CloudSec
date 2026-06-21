# Connect-MgGraph-Interactive.ps1
# Description: This script demonstrates how to connect to Microsoft Graph using the Microsoft Graph PowerShell SDK with interactive prompts for the Application (Client) ID, Secret, and Tenant ID. 

# ------------------------------------------------------------------

# Prompt the user for Application (Client) ID, Secret, and Tenant ID using Read-Host
$ApplicationClientId = Read-Host "Enter the Application (Client) ID"
$ApplicationClientSecret = Read-Host "Enter the Application Secret Value"
$TenantId = Read-Host "Enter the Tenant ID"

# Validate input values to ensure required information is provided
if (-not $ApplicationClientId -or -not $ApplicationClientSecret -or -not $TenantId) {
    Write-Host "All parameters (Client ID, Client Secret, and Tenant ID) must be specified." -ForegroundColor Red
    return
}

# Convert the Application Secret to a Secure String
try {
    $SecureClientSecret = ConvertTo-SecureString -String $ApplicationClientSecret -AsPlainText -Force
} catch {
    Write-Host "Failed to convert Client Secret to a secure string. Please check the input." -ForegroundColor Red
    return
}

# Create a PSCredential object using the Application Client ID and Secure Client Secret
try {
    $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationClientId, $SecureClientSecret
} catch {
    Write-Host "Failed to create the PSCredential object. Please check the input values." -ForegroundColor Red
    return
}

# Connect to Microsoft Graph using the provided credentials
try {
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Please verify your Tenant ID and credentials." -ForegroundColor Red
}
