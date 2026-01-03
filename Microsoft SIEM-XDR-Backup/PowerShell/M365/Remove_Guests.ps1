# add synopsys below here
<#
.SYNOPSIS
    Remove guest users who haven't signed in for more than 90 days. 
.DESCRIPTION
    This script retrieves a list of guest users in the tenant and removes them if they haven't signed in for more than 90 days.
    The script uses the Entra API to interact with the Microsoft Graph API.
.NOTES
    File Name      : Remove_Guests.ps1
    Author         : Entra
    Prerequisite   : PowerShell V2
#>
# --------------------------------------------------------------------------- 
$guestUsers = Get-EntraUser -Filter "userType eq 'Guest'"

# Current date for comparison
$currentDate = Get-Date

# Filter guest users who haven't signed in for more than 90 days and remove them
$guestUsers | Where-Object {
    # Parse lastSignInDateTime to DateTime object
    $lastSignIn = $_.signInActivity.lastSignInDateTime
    $lastSignInDate = [DateTime]::Parse($lastSignIn)

    # Calculate the difference in days
    $daysDifference = ($currentDate - $lastSignInDate).Days

    # Check if difference is greater than 90 days
    return $daysDifference -gt 90
} | ForEach-Object {
    Remove-EntraUser -ObjectId $_.ObjectId -Force
}