# Bulk_Delete_LabUsers.ps1
# Bulk Deletion of Entra ID Users in the 'Lab' Department
# This PowerShell script retrieves all users from the Entra ID whose department is set to 'Lab' and deletes them. 

# ----------------------------------------------------

Get-MgUser -Filter "department eq 'Lab'" | ForEach-Object {
    try {
        Remove-MgUser -UserId $_.Id -Confirm:$false -ErrorAction Stop
        Write-Host "Successfully deleted user: $($_.DisplayName)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to delete user: $($_.DisplayName). Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} -Verbose
