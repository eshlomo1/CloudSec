# Reset Microsoft Grpah Application on Entra ID Entrprise Applications
# Use the Microsoft.Graph or Microsoft.Graph.Beta PowerShell Modules

# Install Microsoft.Graph and Beta modules 
Install-Module Microsoft.Graph -Force 
Install-Module Microsoft.Graph.Beta -AllowClobber -Force

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Organization.ReadWrite.All"

# Get all Enterprise Applications
# Get-MgServicePrincipal -All
# Get-MgServicePrincipal -All | Select-Object -Property DisplayName,Id
# Get-MgServicePrincipal -All | Select-Object -Property DisplayName,Id | Where-Object {$_.DisplayName -eq "Entra ID"}

# Reset Microsoft Graph Enterprise Application
$servicePrincipalId = "00000000-0000-0000-0000-000000000000"
$servicePrincipal = Get-MgServicePrincipal -Id $servicePrincipalId
$servicePrincipal | Reset-MgServicePrincipalCredential -ForceChangePasswordNextSignIn $true
$servicePrincipal | Reset-MgServicePrincipalCredential -ForceChangePasswordNextSignIn $true -ForceRevokeRefreshTokens $true
$servicePrincipal | Reset-MgServicePrincipalCredential -ForceChangePasswordNextSignIn $true -ForceRevokeRefreshTokens $true -ForceRevokeSessions $true


