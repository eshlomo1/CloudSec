# BulkCreateUniqueEntraIDUsers.ps1
# Title: Bulk Create Unique Users in Azure AD with Microsoft Graph
# Description: This PowerShell script automates the creation of multiple Entra ID 
#   users using the Microsoft Graph API. It ensures unique UserPrincipalName and MailNickname 
#   values by appending randomized suffixes. The script enforces secure password policies, requiring

# ------------------------------------------------------------------

# Bulk create 10 users using a loop
1..10 | ForEach-Object {
    $Index = $_

    # Define the password profile settings
    $PassProfile = @{
        Password = "SecPass789!@#"
        ForceChangePasswordNextSignIn = $true
    }

    # Generate a random suffix for uniqueness
    $RandomSuffix = Get-Random -Minimum 1000 -Maximum 9999

    # Define user parameters
    $UserParams = @{
        DisplayName       = "User$Index"
        UserPrincipalName = "user$Index$RandomSuffix@domain.com"
        MailNickname      = "user$Index$RandomSuffix"
        AccountEnabled    = $true
        PasswordProfile   = $PassProfile
    }

    # Create the user
    New-MgUser -BodyParameter $UserParams
}
