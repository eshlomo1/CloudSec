# Title: Deleted Accounts Report
# Description: This script retrieves deleted user accounts from Microsoft Entra ID using Microsoft Graph PowerShell. 
# It generates a detailed report containing information about the deleted accounts, including the number of days since deletion, license status, and user type.
# If no deleted accounts are found, a message is displayed. Otherwise, a formatted table of the deleted accounts is presented.

# ----------------------------------------------------------------------------------------------

$DeletedItems = Get-MgDirectoryDeletedItemAsUser -All -Property 'Id', 'userPrincipalName', 'displayName', 'isLicensed', 'deletedDateTime', 'userType'

# Check if there are no deleted accounts
if ($DeletedItems.Count -eq 0) {
    Write-Host "No deleted accounts found in the recycle bin." -ForegroundColor Cyan
} else {
    # Create a List to store the report
    $DeletedUserReport = [System.Collections.Generic.List[Object]]::new()

    # Loop through the deleted items
    foreach ($DeletedUser in $DeletedItems) {
        $DeletedDate = Get-Date($DeletedUser.DeletedDateTime)
        $DaysSinceDeletion = (New-TimeSpan $DeletedDate).Days

        # Create a custom object for each item
        $ReportLine = [PSCustomObject]@{
            Id                    = $DeletedUser.Id
            UserPrincipalName     = $DeletedUser.UserPrincipalName
            'Display Name'        = $DeletedUser.DisplayName
            Deleted               = $DeletedDate
            'Days Since Deletion' = $DaysSinceDeletion
            'Is Licensed'         = $DeletedUser.IsLicensed
            Type                  = $DeletedUser.UserType
        }
        # Add the report line to the List
        $DeletedUserReport.Add($ReportLine)
    }

    # Display the report in a table
    Write-Host "`nDeleted Accounts Report:" -ForegroundColor Yellow
    $DeletedUserReport | Sort-Object 'Display Name' | Format-Table -AutoSize
}
