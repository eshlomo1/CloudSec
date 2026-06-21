# Create_New_EntraID_User.ps1
# Title: This script create a New Entra ID user with specific attributes
# Description: This PowerShell script leverages the Microsoft Graph module to create a new user in Entra ID. 
#   It specifies key attributes such as display name, email alias, user principal name, and password profile. 
#   The script also enforces secure sign-in practices by requiring password changes and MFA during the first login.

# --------------------------------------------------------------------------------

New-MgUser -DisplayName "Backdoor" `
    -MailNickname "Backdoor" `
    -UserPrincipalName "Backdoor@domain.com" `
    #-AccountEnabled $true `
    -PasswordProfile @{
        Password = "Secure789!@#"
        ForceChangePasswordNextSignIn = $true
        ForceChangePasswordNextSignInWithMfa = $true
    }

