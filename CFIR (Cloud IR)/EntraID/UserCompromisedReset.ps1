# Entra ID User Compromised Reset Script via Microsoft.Graph PowerShell
# Use-Case: Entra IDP User Compromised must be reset with the following compenents:
# 1. User Password Reset
# 2. User MFA Reset
# 3. User Session (Token) Reset
# 4. User Sign-Out
# 5. User Risky Sign-In Reset
# 6. User Risky Sign-In Dismiss
# 7. User Risky Sign-In Confirm Compromised

# Note: Add Gui prompt screen to this powershell script to make it more user friendly 

# Install Microsoft.Graph and Beta modules 
# Add GUI progress installation to each module
Install-Module PowerShellGet -Force -AllowClobber
Install-Module -Name "Microsoft.Graph" -Force -AllowClobber
Install-Module -Name "Microsoft.Graph.Beta" -Force -AllowClobber
#Install-Module -Name "Microsoft.Graph.Authentication" -Force -AllowClobber


# Import Microsoft.Graph Modules
Import-Module Microsoft.Graph

# Import Microsoft.Graph.Beta Modules
Import-Module Microsoft.Graph.Beta

# Connect to Microsoft.Graph
Connect-MgGraph -Scopes "User.Read.All", "User.ReadWrite.All", "Directory.ReadWrite.All", "Directory.AccessAsUser.All", "UserAuthenticationMethod.ReadWrite.All", "UserAuthenticationMethod.Read" 
Connect-MgBeta -Scopes "User.Read.All", "User.ReadWrite.All", "Directory.ReadWrite.All", "Directory.AccessAsUser.All", "UserAuthenticationMethod.ReadWrite.All", "UserAuthenticationMethod.Read"

# Get User Object Name via prompt GUI
$UserId = Read-Host -Prompt "Enter User ID"

# Reset User Password with GUI Prompt Screen
$User = Get-MgUser -UserId $UserId
$NewPassword = Read-Host -Prompt "Enter New Password" -AsSecureString
 
# Reset User MFA with GUI Prompt Screen and Reset-MgUserAuthenticationMethodPassword
$MfaMethods = Get-MgUserAuthenticationMethod -UserId $User.Id

foreach ($MfaMethod in $MfaMethods) {
    if ($MfaMethod.Type -eq "phone") {
        $Phone = $MfaMethod
    }
    elseif ($MfaMethod.Type -eq "email") {
        $Email = $MfaMethod
    }
}
 

# Reset User Session (Token)
Remove-MgUserSession -UserId $User.Id

# Sign-Out User
Invoke-MgUserSignOut -UserId $User.Id

# Get User Risky Sign-Ins
$RiskySignIns = Get-MgUserRiskySignIn -UserId $User.Id

# Reset User Risky Sign-In
foreach ($RiskySignIn in $RiskySignIns) {
    Reset-MgUserRiskySignIn -UserId $User.Id -RiskySignInId $RiskySignIn.Id
}

# Dismiss User Risky Sign-In
foreach ($RiskySignIn in $RiskySignIns) {
    Dismiss-MgUserRiskySignIn -UserId $User.Id -RiskySignInId $RiskySignIn.Id
}

# Confirm User Risky Sign-In Compromised
foreach ($RiskySignIn in $RiskySignIns) {
    Confirm-MgUserRiskySignInCompromised -UserId $User.Id -RiskySignInId $RiskySignIn.Id
}



