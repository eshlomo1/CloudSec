# Bulk_Delete_LabUsers.ps1
# Title: Bulk Deletion of Entra ID Users in the 'Lab' Department
# Description: This PowerShell script retrieves all users from the Entra ID whose department is set to 'Lab'
# and deletes them. The script includes detailed reporting on successfully deleted and failed users.

# ----------------------------------------------------

# Initialize counters for reporting
$SuccessCount = 0
$FailureCount = 0
$DeletedUsers = @()
$FailedUsers = @()

# Retrieve and delete users in the 'Lab' department
Get-MgUser -Filter "department eq 'Lab'" | ForEach-Object {
    try {
        # Attempt to delete the user
        Remove-MgUser -UserId $_.Id -Confirm:$false -ErrorAction Stop
        Write-Host "Successfully deleted user: $($_.DisplayName)" -ForegroundColor Green

        # Add to the success report
        $DeletedUsers += $_.DisplayName
        $SuccessCount++
    } catch {
        # Handle errors and log failures
        Write-Host "Failed to delete user: $($_.DisplayName). Error: $($_.Exception.Message)" -ForegroundColor Red

        # Add to the failure report
        $FailedUsers += @{
            DisplayName = $_.DisplayName
            Error       = $_.Exception.Message
        }
        $FailureCount++
    }
} -Verbose

# Final report summary
Write-Host "`n------------------------------------" -ForegroundColor Yellow
Write-Host "Bulk Deletion Report" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow
Write-Host "Total Users Found in 'Lab' Department: $($SuccessCount + $FailureCount)" -ForegroundColor Cyan
Write-Host "Successfully Deleted Users: $SuccessCount" -ForegroundColor Green
Write-Host "Failed Deletions: $FailureCount" -ForegroundColor Red

# Detailed logs
if ($DeletedUsers.Count -gt 0) {
    Write-Host "`nSuccessfully Deleted Users:" -ForegroundColor Green
    $DeletedUsers | ForEach-Object { Write-Host "- $_" -ForegroundColor Green }
}

if ($FailedUsers.Count -gt 0) {
    Write-Host "`nFailed to Delete Users:" -ForegroundColor Red
    $FailedUsers | ForEach-Object {
        Write-Host "- $($_.DisplayName): $($_.Error)" -ForegroundColor Red
    }
}
