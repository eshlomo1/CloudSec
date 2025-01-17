# BulkCreateEntraIDUsers.ps1
# Title: Bulk create users in Microsoft Graph using PowerShell

# ------------------------------------------------------------------

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
        UserPrincipalName = "user$Index@your_domain.com"
        MailNickname      = "user$Index"
        AccountEnabled    = $true
        PasswordProfile   = @{
            Password = "Your_Password"
            ForceChangePasswordNextSignIn = $true
        }
    }
    New-MgUser -BodyParameter $UserParams
}
