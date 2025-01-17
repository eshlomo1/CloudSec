# BulkCreateEntraIDUsers.ps1
# Title: Bulk create users in Microsoft Graph using PowerShell
# Description: This script demonstrates how to bulk create users in Microsoft Graph using PowerShell. The script creates 10 users with a display name, user principal name, mail nickname, account enabled status, and password profile settings.
# Import the Microsoft Graph Users module
Import-Module Microsoft.Graph.Users

# Connect to Microsoft Graph with the required permission
Connect-MgGraph -Scope User.ReadWrite.All

# Define the password profile settings
$PasswordProfile = @{
    Password = "SecurePass123!"
    ForceChangePasswordNextSignIn = $true
}

# Bulk create 10 users using a loop
1..10 | ForEach-Object {
    $Index = $_
    $UserParams = @{
        DisplayName       = "User$Index"
        UserPrincipalName = "user$Index@PurpleXlab.onmicrosoft.com"
        MailNickname      = "user$Index"
        AccountEnabled    = $true
        PasswordProfile   = @{
            Password = "SecurePass123!"
            ForceChangePasswordNextSignIn = $true
        }
    }
    New-MgUser -BodyParameter $UserParams
}
