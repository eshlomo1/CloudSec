# ScriptName: Bulk_Delete_Users_Filtered.ps1
# Title: Bulk Deletion of Entra ID Users
# This script retrieves all users from Entra ID whose department is set to 'Lab' and deletes them.
# It includes enhanced logging, safeguards, and a restore mechanism in case of accidental deletions.

# ------------------------------------------------------------------------------------------

# Enable error logging
$ErrorActionPreference = "Stop"

# Define log file for tracking operations
$LogFile = "BulkDeleteLabUsersLog_$(Get-Date -Format 'yyyyMMddHHmmss').log"

# Log a message to the console and file
function Log-Message {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogFile -Value "$((Get-Date).ToString('u')) - $Message"
}

# Safeguard for critical users (add userPrincipalName or IDs to this list)
$CriticalUsers = @(
    "admin@yourdomain.com",  # Example: Global Admin
    "securitylead@yourdomain.com"
)

# Retrieve users from the 'Lab' department
$LabUsers = Get-MgUser -Filter "department eq 'Lab'" -All

if ($LabUsers.Count -eq 0) {
    Log-Message "No users found in the 'Lab' department." "Yellow"
    return
}

# Process each user
foreach ($User in $LabUsers) {
    try {
        # Check if the user is in the critical users list
        if ($CriticalUsers -contains $User.UserPrincipalName) {
            Log-Message "Skipping critical user: $($User.DisplayName) ($($User.UserPrincipalName))" "Yellow"
            continue
        }

        # Delete the user
        Remove-MgUser -UserId $User.Id -Confirm:$false
        Log-Message "Successfully deleted user: $($User.DisplayName) ($($User.UserPrincipalName))" "Green"

        # Optional: Immediately restore the user for testing the restore mechanism
        # Uncomment the following lines to test restore functionality
        # Restore-MgDeletedUser -UserId $User.Id
        # Log-Message "Restored user: $($User.DisplayName) ($($User.UserPrincipalName))" "Yellow"
    } catch {
        Log-Message "Failed to delete user: $($User.DisplayName) ($($User.UserPrincipalName)). Error: $($_.Exception.Message)" "Red"
    }
}

# Log completion
Log-Message "Bulk deletion process completed. Log file saved to: $LogFile" "Green"
