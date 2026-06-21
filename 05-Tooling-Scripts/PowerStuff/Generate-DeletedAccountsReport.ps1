# Title: Deleted Accounts Report
# Description: This script retrieves deleted user accounts from Microsoft Entra ID using Microsoft Graph PowerShell. 
# It generates a detailed report containing information about the deleted accounts, including the number of days since deletion, license status, and user type.
# If no deleted accounts are found, a message is displayed. Otherwise, a formatted table of the deleted accounts is presented.

# ----------------------------------------------------------------------------------------------

# Retrieve Deleted Users from AAD Recycle Bin
$DeletedUsers = Get-MgDirectoryDeletedItemAsUser -All -Property 'Id', 'userPrincipalName', 'displayName', 'isLicensed', 'deletedDateTime', 'userType'

# Check if the Recycle Bin is Empty
if ($DeletedUsers.Count -eq 0) {
    Write-Host "No deleted user accounts found in the AAD recycle bin." -ForegroundColor Cyan
} else {
    # Initialize a List for Deleted Users Report
    $DeletedUsersReport = [System.Collections.Generic.List[Object]]::new()

    # Process Each Deleted User
    foreach ($User in $DeletedUsers) {
        $DeletionDate = Get-Date($User.DeletedDateTime)
        $DaysSinceRemoval = (New-TimeSpan $DeletionDate).Days

        # Create a Custom Object for the Report
        $UserReportEntry = [PSCustomObject]@{
            'User ID'             = $User.Id
            'Principal Name'      = $User.UserPrincipalName
            'Full Name'           = $User.DisplayName
            'Deleted Date'        = $DeletionDate
            'Days Since Removal'  = $DaysSinceRemoval
            'License Status'      = $User.IsLicensed
            'Account Type'        = $User.UserType
        }

        # Add the Entry to the Report
        $DeletedUsersReport.Add($UserReportEntry)
    }

    # Display the Deleted Users Report
    Write-Host "`nActive Directory Deleted Users Report:" -ForegroundColor Yellow
    $DeletedUsersReport | Sort-Object 'Full Name' | Format-Table -AutoSize
}
