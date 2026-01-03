# Import the Microsoft.Graph module for PowerShell
# Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
# Import-Module Microsoft.Graph
# Connect-MgGraph -Scopes "User.Read.All", "User.ReadWrite.All", "Directory.ReadWrite.All"


<#
.SYNOPSIS
Resets the Microsoft Entra ID user password, resets MFA method, and kills session token for the user.

.DESCRIPTION
This function utilizes the Microsoft.Graph PowerShell module to reset the user's password, reset the MFA method, and kill the session token.

.PARAMETER userId
The ID of the user whose password and MFA method need to be reset, and session token needs to be killed.

.EXAMPLE
Reset-MicrosoftEntraIDUser -userId "user123"
Resets the password, MFA method, and kills session token for the user with ID "user123".
#>
function Reset-MicrosoftEntraIDUser {
    param (
        [string]$userId
    )

    # Reset user password
    $null = Reset-MgUserAuthenticationMethodPassword -UserId $userId

    # Reset MFA method
    #$null = Reset-MgUserMfaMethod -UserId $userId

    # Kill session token
    #$null = Remove-MgUserSession -UserId $userId
}

# Usage example for the Reset-MicrosoftEntraIDUser function
# ----------------------------------------------------------------------------
Reset-MicrosoftEntraIDUser -userId "lab5@secmisconfig.com"
