<#
.SYNOPSIS
    Automated Creation of 100 Random Users in Microsoft Graph.

.DESCRIPTION
    This script connects to Microsoft Graph using `User.ReadWrite.All` permissions and creates 100 users.
    Each user has a randomly generated display name and password. Success and failure are logged with colored output.
#>

# Connect to Microsoft Graph
# Connect-MgGraph -Scopes "User.ReadWrite.All"

# Function to generate random passwords
function Generate-RandomPassword {
    param (
        [int]$length = 12 # Default password length is 12
    )
    $allowedChars = 'abCDNFK6789!@#$%^&*()'
    $password = -join ((1..$length) | ForEach-Object { $allowedChars | Get-Random })
    return $password
}

# Function to generate random names
function Generate-RandomName {
    $firstNames = @("Alex", "Jordan", "Taylor", "Morgan", "Casey", "Jamie", "Riley", "Avery", "Peyton", "Quinn")
    $lastNames = @("Smith", "Johnson", "Brown", "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin")
    $firstName = $firstNames | Get-Random
    $lastName = $lastNames | Get-Random
    return "$firstName $lastName"
}

# Create 100 users
for ($i = 1; $i -le 100; $i++) {
    $displayName = Generate-RandomName
    $mailNickname = $displayName -replace ' ', '.' -replace '[^a-zA-Z.]', ''
    $userPrincipalName = "$mailNickname$i@PurpleXlab.onmicrosoft.com"
    $password = Generate-RandomPassword -length 12 # Adjust the password length if needed

    $params = @{
        "accountEnabled"    = $true
        "displayName"       = $displayName
        "mailNickname"      = $mailNickname
        "userPrincipalName" = $userPrincipalName
        "passwordProfile"   = @{
            "forceChangePasswordNextSignIn" = $false
            "password"                      = $password
        }
    }

    try {
        # Create the user
        New-MgUser -BodyParameter $params
        Write-Host "`e[32m[Success] Created user:`e[0m $displayName (`e[1;34m$userPrincipalName`e[0m) with Password: `e[1;36m$password`e[0m"
    } catch {
        Write-Host "`e[31m[Error] Failed to create user $displayName. Error:`e[0m $_" -ForegroundColor Red
    }
}
