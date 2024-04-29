# Define parameters
$StartDate = (Get-Date).AddDays(-30)  # Adjust this as needed
$EndDate = Get-Date
$OutputFilePath = "/Users/ellishlomo/Downloads/UserloginHistory.csv"

# Connect to Exchange Online (if not already connected)
# Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com -ShowProgress $true

# Search for user login events
$UserLogins = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -Operations UserLoggedIn -ResultSize 5000

# Filter out only required data and events with non-empty client IP
$FilteredLogins = $UserLogins | Where-Object { $_.ClientIP -ne $null -and $_.ClientIP -ne "" } | Select-Object -Property CreationDate, UserIds, Operations, UserType, ClientIP, ClientInfo

# Export the filtered data to a CSV file
$FilteredLogins | Export-Csv -Path $OutputFilePath -NoTypeInformation

Write-Host "User login history exported to: $OutputFilePath"
